// The whole store as one plain JSON document — SPEC.md §6 §2.
//
// Three properties drive every decision in this file, and each of them is the
// reason for something that would otherwise look like over-engineering.
//
// STREAMED, not assembled. `json.encode(wholeDocument)` builds the entire file
// in memory as one String, which for a 12,000-record store is tens of megabytes
// of UTF-16 on a phone that is already low on it — and the peak arrives at the
// exact moment the user is trying to rescue their data. Each record is encoded
// on its own and pushed to the sink, so the high-water mark is one record.
//
// DETERMINISTIC below the envelope. §6 §2.6 turns "two exports of unchanged
// data are byte-identical" into a CI assertion, which means no map iteration
// order may leak in and no list may arrive unsorted. Every projection is an
// ordered literal and every array is sorted by id here rather than at the
// caller, so a caller that forgot cannot make the file non-deterministic.
//
// ONE RECORD PER LINE. The envelope is a key per line and each record is a
// single compact line inside its array. That is not a compromise on the
// read-it-in-a-text-editor property, it is the thing that makes §2.6's promise
// useful: `diff` past the envelope shows the records that changed, one line
// each, instead of a thousand-line reflow because a field moved.
//
// HASHED OVER THE BYTES AS WRITTEN. The hash is computed while streaming, with
// the placeholder in place, and then overwritten in the file at a byte offset
// this writer recorded. That is why the placeholder is exactly 64 zeros: a
// shorter or longer replacement would shift every byte after it, and the
// document the hash certifies would no longer be the document on disk.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/store_snapshot.dart';
import 'package:odova/core/due/resolve_anchor.dart';
import 'package:odova/features/backup/domain/backup_format.dart';
import 'package:odova/features/backup/domain/mapping/backup_values.dart';
import 'package:odova/features/backup/domain/mapping/record_backup.dart';
import 'package:odova/features/backup/domain/mapping/settings_backup.dart';
import 'package:odova/features/backup/domain/mapping/vehicle_backup.dart';

/// Writes a [StoreSnapshot] out as §6's backup document.
///
/// Everything that varies between two otherwise identical exports is a
/// constructor argument, so the writer itself has no clock, no package info and
/// no platform lookup. A test pins the instant; `bootstrap` supplies the real
/// values.
class BackupWriter {
  /// Creates a writer for one export.
  const BackupWriter({
    required this.nowUtcMs,
    required this.localOffset,
    required this.appVersion,
    required this.appBuild,
    required this.platform,
  });

  /// The instant of the export, in UTC milliseconds.
  final int nowUtcMs;

  /// The writer's own offset from UTC, for `exported_at_local`.
  ///
  /// Both fields name the SAME instant. The local one exists because a person
  /// scrolling a folder of backups recognises "10:30, the morning I sold the
  /// car" and does not recognise the same moment written in UTC.
  final Duration localOffset;

  /// The app version that wrote the file.
  final String appVersion;

  /// The build number that wrote the file.
  final String appBuild;

  /// `android` or `ios`.
  final String platform;

  /// Writes [store] to [file] and stamps the content hash in place.
  ///
  /// Returns the hash it wrote. The file is complete and verifiable when this
  /// resolves; there is no half-written state a caller has to clean up,
  /// because the caller writes to a temporary path and renames (task 15.5).
  Future<String> writeToFile(File file, StoreSnapshot store) async {
    final sink = file.openWrite();
    final Digest digest;
    final int offset;
    try {
      final receipt = await _write(sink, store);
      digest = receipt.digest;
      offset = receipt.hashOffset;
    } finally {
      await sink.close();
    }

    final hash = 'sha256:$digest';
    final handle = await file.open(mode: FileMode.append);
    try {
      await handle.setPosition(offset);
      await handle.writeFrom(utf8.encode(hash));
    } finally {
      await handle.close();
    }
    return hash;
  }

  Future<_Receipt> _write(IOSink sink, StoreSnapshot store) async {
    // Projected ONCE. The first version built `record_counts` by calling
    // `_rows` for all eight arrays to read their lengths, and then called it
    // again to write them — so every record's projection map was built twice,
    // every array was sorted twice, and `newestCompletingByItem` walked every
    // service line twice. At 12,000 records that is twelve thousand throwaway
    // maps and a second O(services × lines) pass, for nothing.
    //
    // The cost is that all eight arrays are now live at once rather than one
    // at a time. That is the projections, not the file: the JSON is still
    // encoded and pushed a record at a time, which is what the streaming
    // promise is about.
    final rows = <String, List<Map<String, Object?>>>{
      for (final array in kBackupArrays) array: _rows(array, store),
    };

    // The digest is fed the same bytes the sink is, in the same order. Two
    // encodes of the same text would be a chance for them to disagree, so
    // every write goes through `emit`.
    final digest = _DigestSink();
    final hasher = sha256.startChunkedConversion(digest);
    var written = 0;
    void emit(String text) {
      final bytes = utf8.encode(text);
      sink.add(bytes);
      hasher.add(bytes);
      written += bytes.length;
    }

    emit('{\n');
    var hashOffset = 0;
    for (final key in kEnvelopeKeys) {
      if (key == 'content_hash') {
        // Recorded BEFORE the placeholder so the offset points at its first
        // byte: `"content_hash": ` is 17 bytes of key plus the opening quote.
        emit('  "content_hash": "');
        hashOffset = written;
        emit('$kContentHashPlaceholder",\n');
        continue;
      }
      emit(
        '  ${json.encode(key)}: ${_encode(_envelopeValue(key, rows))},\n',
      );
    }

    emit(
      '  "settings": '
      '${_encode(settingsBackupJson(store.settings))},\n',
    );

    for (var i = 0; i < kBackupArrays.length; i++) {
      final array = rows[kBackupArrays[i]]!;
      emit('  ${json.encode(kBackupArrays[i])}: [');
      for (var r = 0; r < array.length; r++) {
        emit(r == 0 ? '\n    ' : ',\n    ');
        emit(_encode(array[r]));
      }
      emit(array.isEmpty ? ']' : '\n  ]');
      emit(i == kBackupArrays.length - 1 ? '\n' : ',\n');
    }
    emit('}\n');

    hasher.close();
    await sink.flush();
    return _Receipt(digest.value!, hashOffset);
  }

  Object? _envelopeValue(
    String key,
    Map<String, List<Map<String, Object?>>> rows,
  ) => switch (key) {
    'format' => kBackupFormat,
    'format_version' => kSupportedFormatVersion,
    'app_version' => appVersion,
    'app_build' => appBuild,
    'platform' => platform,
    'exported_at' => rfc3339(nowUtcMs),
    'exported_at_local' => rfc3339Local(nowUtcMs, localOffset),
    'units' => kBackupUnits,
    'derived_fields' => kDerivedFields,
    'record_counts' => _counts(rows),
    // Not reachable: `kEnvelopeKeys` is asserted against SPEC.md §6 §2.5 by
    // `spec_key_order_test`, so a key arriving here that this switch does not
    // name means the spec grew a field and nobody taught the writer about it.
    _ => throw StateError('no envelope value for "$key"'),
  };

  Map<String, int> _counts(Map<String, List<Map<String, Object?>>> rows) {
    final counts = <String, int>{
      for (final array in kBackupArrays) array: rows[array]!.length,
    };
    // Settings is one row and not a record, so it is outside the total. A
    // reader comparing `total` against what it parsed would otherwise be off
    // by one on every file.
    return {
      ...counts,
      'total': counts.values.fold(0, (sum, n) => sum + n),
    };
  }

  List<Map<String, Object?>> _rows(String array, StoreSnapshot store) =>
      switch (array) {
        'vehicles' => _sorted(
          store.vehicles,
          (v) => v.id.toString(),
        ).map(vehicleBackupJson).toList(),
        'reminders' => _reminders(store),
        'odometer_readings' => _sorted(
          store.odometerReadings,
          (r) => r.id.toString(),
        ).map(odometerReadingBackupJson).toList(),
        'odometer_corrections' => _sorted(
          store.odometerCorrections,
          (c) => c.id.toString(),
        ).map(odometerCorrectionBackupJson).toList(),
        'fillups' => _sorted(
          store.fillUps,
          (f) => f.id.toString(),
        ).map(fillUpBackupJson).toList(),
        'services' => _sorted(
          store.services,
          (s) => s.id.toString(),
        ).map(serviceBackupJson).toList(),
        'expenses' => _sorted(
          store.expenses,
          (e) => e.id.toString(),
        ).map(expenseBackupJson).toList(),
        'trips' => _sorted(
          store.trips,
          (t) => t.id.toString(),
        ).map(tripBackupJson).toList(),
        _ => throw StateError('no rows for "$array"'),
      };

  /// The three derived `last_done` fields, from the newest completing record.
  ///
  /// `newestCompletingByItem` is the due engine's own index rather than a
  /// second walk of the same rule: a brake job does not reset the inspection
  /// clock, and the line's `service_item_id` is the only thing that ties a
  /// record to an item. An export that disagreed with Home about what was last
  /// done would be a file that contradicts the screen it came from.
  List<Map<String, Object?>> _reminders(StoreSnapshot store) {
    final newest = newestCompletingByItem(store.services);
    return [
      for (final item in _sorted(store.reminders, (r) => r.id.toString()))
        reminderBackupJson(item, lastDone: _lastDone(newest[item.id])),
    ];
  }

  ({String? date, int? odometerM, String? serviceId}) _lastDone(
    ServiceRecord? record,
  ) => record == null
      ? (date: null, odometerM: null, serviceId: null)
      : (
          date: record.occurredOn,
          odometerM: metresOrNull(record.odometer),
          serviceId: record.id.toString(),
        );
}

/// [items] ordered by id, which for a ULID is creation order.
///
/// Sorted HERE and not at the caller: byte-determinism is a property of the
/// file, and a property the writer enforces cannot be lost by a caller that
/// passed a set, a map's values, or the result of a query whose `ORDER BY`
/// someone dropped.
List<T> _sorted<T>(List<T> items, String Function(T) id) {
  // Decorate, sort, undecorate. `RecordId.toString()` builds a fresh String
  // every call, so a comparator that called it saw ~2 × n × log n allocations
  // — 340,000 throwaway strings for a 12,000-record array, to sort 12,000
  // items.
  final keyed = [for (final item in items) (id(item), item)]
    ..sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final pair in keyed) pair.$2];
}

/// JSON for [value], with every string stripped of bidi controls.
String _encode(Object? value) => json.encode(sanitiseForBackup(value));

/// Catches the one digest `startChunkedConversion` emits on close.
///
/// Hand-rolled rather than `package:convert`'s `AccumulatorSink`, because that
/// would make `convert` a direct dependency of this app for four lines — and
/// every direct dependency has to be re-argued against the no-network rule.
class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}

class _Receipt {
  const _Receipt(this.digest, this.hashOffset);
  final Digest digest;
  final int hashOffset;
}
