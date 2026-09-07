// SPEC.md §6 §5.1's thirteen rungs, in order, writing nothing.
//
// The ORDER is the design, not an implementation detail. Size before bytes
// before parse before magic means a 203 MB video the user picked by accident is
// refused without being read, and a corrupt 4 MB file is diagnosed by the
// cheapest check that can explain it. Every rung above the one that fires is a
// question already answered.
//
// Two kinds of outcome, and the line between them is §5.3's never-silently-drop
// rule. A DOCUMENT-level problem aborts with a typed `ImportFailure`, the file
// byte-unchanged and the phone untouched — which is what lets §5.2's messages
// say "Nothing on your phone has changed" out loud. A RECORD-level problem
// produces a warning and the import continues, because losing eight years of
// service history is the worst bug this app can have and a category it does not
// recognise is not a reason to risk it.
import 'dart:convert';
import 'dart:io';

import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/store_snapshot.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/result.dart';
import 'package:odova/features/backup/domain/backup_format.dart';
import 'package:odova/features/backup/domain/content_hash.dart';
import 'package:odova/features/backup/domain/import_failure.dart';
import 'package:odova/features/backup/domain/import_plan.dart';
import 'package:odova/features/backup/domain/import_warning.dart';
import 'package:odova/features/backup/domain/mapping/record_restore.dart';

/// §9's ceiling. A ten-year backup is around 4 MB.
const int kMaxBackupBytes = 64 * 1024 * 1024;

/// §5.4's nesting cap. The real format uses 4.
const int kMaxNestingDepth = 32;

/// §5.4's string cap.
const int kMaxStringLength = 1024 * 1024;

/// §5.1 rung 13 — the share of unreadable records that refuses the import.
const double kMaxDamagedFraction = 0.05;

/// §5.1 rung 13 — the absolute count that refuses it.
const int kMaxDamagedRecords = 50;

/// Rung 10's floor. A record before this is warned about, never dropped.
const int kEarliestPlausibleYear = 1990;

/// Rung 10's ceiling, in years after `exported_at`.
const int kLatestPlausibleYearsAhead = 2;

/// Reads a picked file and decides what it would do, without doing it.
class BackupReader {
  /// Creates a reader.
  const BackupReader({
    this.maxBytes = kMaxBackupBytes,
    this.fallbackCurrency,
    this.nowUtcMs = 0,
  });

  /// The size ceiling. A parameter so a test can reach rung 1 without writing
  /// 64 MB.
  final int maxBytes;

  /// The currency a `settings` block with no readable one falls back to.
  ///
  /// Nullable so the constructor stays `const`: `Currency` is validated on
  /// construction and there is no const path to one.
  final Currency? fallbackCurrency;

  /// The instant the import is being planned, for the restored settings' audit
  /// columns. The file's own timestamps are not reused: they describe when the
  /// OTHER phone last wrote its settings.
  final int nowUtcMs;

  /// Reads [file] and returns the plan, or why there is none.
  Future<Result<ImportPlan, ImportFailure>> read(File file) async {
    // ---- Rung 1: size, before opening. -----------------------------------
    final int length;
    try {
      length = await file.length();
    } on FileSystemException {
      return const Err(CannotOpenFile());
    }
    if (length > maxBytes) {
      return Err(FileTooLarge(bytes: length, limitBytes: maxBytes));
    }

    final List<int> bytes;
    try {
      bytes = await file.readAsBytes();
    } on FileSystemException {
      return const Err(CannotOpenFile());
    }

    // ---- Rung 2: bytes. --------------------------------------------------
    if (_isCompressed(bytes)) return const Err(CompressedFile());
    final String text;
    try {
      text = utf8.decode(_withoutBom(bytes));
    } on FormatException {
      return const Err(NotUtf8());
    }

    // ---- Rung 3: JSON. ---------------------------------------------------
    final Object? decoded;
    try {
      decoded = json.decode(text);
    } on FormatException catch (error) {
      // A parse error at the very END almost always means the download or the
      // copy stopped, and "get the file again" fixes it. One in the middle
      // means the file was changed, and getting it again will not.
      return Err(
        _endsThere(error, text) ? const Truncated() : const NotValidJson(),
      );
    }
    if (decoded is! Map<String, Object?>) return const Err(NotOdova());

    // ---- Rung 4: magic. --------------------------------------------------
    if (decoded['format'] != kBackupFormat) {
      return const Err(NotMadeByOdova());
    }

    // ---- Rung 5: version. ------------------------------------------------
    final version = decoded['format_version'];
    if (version is! int || version < 1) return const Err(CorruptVersion());
    if (version > kSupportedFormatVersion) {
      return Err(
        TooNew(
          fileVersion: version,
          supportedVersion: kSupportedFormatVersion,
        ),
      );
    }

    // ---- §5.4: hostile shape, before anything walks the tree. ------------
    final log = RestoreLog();
    final Map<String, Object?> document;
    try {
      document = _guard(decoded, log)! as Map<String, Object?>;
    } on _TooDeepSignal catch (signal) {
      return Err(TooDeep(depth: signal.depth, limit: kMaxNestingDepth));
    }

    // ---- Rung 6: migrate. ------------------------------------------------
    // Identity at version 1, and the only version there is. EPIC-15 task 15.3
    // owns the chain; this is the seam it plugs into, named so the rung is
    // visibly present rather than visibly missing.
    final migrated = document;

    final warnings = <ImportWarning>[];
    if (log.truncatedStrings > 0) {
      warnings.add(TruncatedStrings(log.truncatedStrings));
    }

    // ---- Rung 7: shape. --------------------------------------------------
    final arrays = <String, List<Object?>>{};
    for (final name in kBackupArrays) {
      final raw = migrated[name];
      if (raw == null) {
        // A file that OMITS an array might be an older export. One that puts a
        // string where the records go was built by something that does not
        // understand the format at all, and reading on would be guessing.
        warnings.add(MissingArray(name));
        arrays[name] = const [];
        continue;
      }
      if (raw is! List<Object?>) return Err(MalformedArray(name));
      arrays[name] = raw;
    }

    // ---- Rung 8: hash and counts. ----------------------------------------
    if (!contentHashMatches(text)) warnings.add(const ContentHashMismatch());

    final found = arrays.values.fold(0, (sum, rows) => sum + rows.length);
    final counts = migrated['record_counts'];
    final declared = counts is Map<String, Object?> ? counts['total'] : null;
    if (declared is int && declared != found) {
      warnings.add(RecordCountMismatch(declared: declared, found: found));
    }

    // ---- Rungs 9 to 13. --------------------------------------------------
    return _restore(migrated, arrays, warnings, log, found);
  }

  // Rungs 9 to 13, over the arrays that rung 7 accepted.
  //
  // Read in DEPENDENCY order rather than file order, because rung 11's links
  // are resolved as each record is built: a fill-up's `trip_id` can only be
  // checked once the trips are known, and a correction's `from_reading_id`
  // once the readings are. Resolving at construction is what lets the models
  // stay immutable and `copyWith`-free.
  Result<ImportPlan, ImportFailure> _restore(
    Map<String, Object?> document,
    Map<String, List<Object?>> arrays,
    List<ImportWarning> warnings,
    RestoreLog log,
    int found,
  ) {
    final skipped = <SkippedEntry>[];
    final seenIds = <String>{};
    var duplicates = 0;

    List<T> read<T extends Object>(
      String name,
      T? Function(Map<String, Object?>) restore,
      String Function(T) idOf,
    ) {
      final out = <T>[];
      for (final raw in arrays[name]!) {
        if (raw is! Map<String, Object?>) {
          skipped.add(SkippedEntry(array: name, reason: 'not_a_record'));
          continue;
        }
        log.rejection = null;
        final record = restore(raw);
        if (record == null) {
          skipped.add(
            SkippedEntry(
              array: name,
              reason: log.rejection ?? 'unreadable',
              occurredOn: raw['occurred_on'] is String
                  ? raw['occurred_on']! as String
                  : null,
            ),
          );
          continue;
        }
        // Rung 12 — the FIRST occurrence wins. First and not last, because a
        // file whose tail was appended twice is the common shape, and the
        // first copy is the one the rest of the document's links point at.
        if (!seenIds.add(idOf(record))) {
          duplicates++;
          continue;
        }
        out.add(record);
      }
      return out;
    }

    // The id sets are filled as each array is read, and `BackupLinks` holds
    // references to them — so a fill-up read after the trips sees the trips.
    final links = BackupLinks(
      vehicles: <VehicleId>{},
      trips: <TripId>{},
      items: <ServiceItemId>{},
      readings: <OdometerReadingId>{},
      orphanVehicleId: kRecoveredRecordsVehicleId,
    );

    final vehicles = read(
      'vehicles',
      (json) => vehicleFromBackup(json, log),
      (v) => v.id.toString(),
    );
    links.vehicles.addAll(vehicles.map((v) => v.id));

    final reminders = read(
      'reminders',
      (json) => reminderFromBackup(json, log, links),
      (r) => r.id.toString(),
    );
    links.items.addAll(reminders.map((r) => r.id));

    final readings = read(
      'odometer_readings',
      (json) => odometerReadingFromBackup(json, log, links),
      (r) => r.id.toString(),
    );
    links.readings.addAll(readings.map((r) => r.id));

    final trips = read(
      'trips',
      (json) => tripFromBackup(json, log, links),
      (t) => t.id.toString(),
    );
    links.trips.addAll(trips.map((t) => t.id));

    final unmatchedBefore = skipped.length;
    final corrections = read(
      'odometer_corrections',
      (json) => odometerCorrectionFromBackup(json, log, links),
      (c) => c.id.toString(),
    );
    final unmatched = skipped
        .skip(unmatchedBefore)
        .where((entry) => entry.reason == 'unmatched_correction')
        .length;

    final fillUps = read(
      'fillups',
      (json) => fillUpFromBackup(json, log, links),
      (f) => f.id.toString(),
    );
    final services = read(
      'services',
      (json) => serviceFromBackup(json, log, links),
      (s) => s.id.toString(),
    );
    final expenses = read(
      'expenses',
      (json) => expenseFromBackup(json, log, links),
      (e) => e.id.toString(),
    );

    final settingsJson = document['settings'];
    final settings = settingsFromBackup(
      settingsJson is Map<String, Object?> ? settingsJson : const {},
      log,
      schemaVersion: kSupportedFormatVersion,
      fallbackCurrency: fallbackCurrency ?? _euro,
      nowUtcMs: nowUtcMs,
    );

    // ---- Rung 10: dates. -------------------------------------------------
    final exportedAt = DateTime.tryParse(
      document['exported_at'] is String
          ? document['exported_at']! as String
          : '',
    );
    final outOfRange = _outOfRangeDates(
      exportedAt: exportedAt,
      dates: [
        ...readings.map((r) => r.occurredOn),
        ...fillUps.map((f) => f.occurredOn),
        ...services.map((s) => s.occurredOn),
        ...expenses.map((e) => e.occurredOn),
        ...trips.map((t) => t.startedOn),
      ],
    );

    if (skipped.isNotEmpty) warnings.add(SkippedRecords(skipped));
    if (log.coercedEnums > 0) warnings.add(CoercedEnums(log.coercedEnums));
    if (outOfRange > 0) warnings.add(OutOfRangeDates(outOfRange));
    if (links.orphans > 0) warnings.add(OrphanRecords(links.orphans));
    if (links.unresolved > 0) warnings.add(UnresolvedLinks(links.unresolved));
    if (unmatched > 0) warnings.add(UnmatchedCorrections(unmatched));
    if (duplicates > 0) warnings.add(DuplicateIds(duplicates));

    // ---- Rung 13: blast radius. ------------------------------------------
    final unreadable = skipped.length;
    final readable = found - unreadable;
    if (unreadable > kMaxDamagedRecords ||
        (found > 0 && unreadable > found * kMaxDamagedFraction)) {
      // Refused rather than partially imported. §2 makes import a REPLACE, so
      // a partial import is not "most of your history" — it is most of your
      // history standing where all of it used to be, with no way to tell which
      // parts are missing.
      return Err(TooDamaged(readable: readable, total: found));
    }

    return Ok(
      ImportPlan(
        store: StoreSnapshot(
          settings: settings,
          vehicles: [
            ...vehicles,
            if (links.orphans > 0) _recoveredRecordsVehicle(nowUtcMs),
          ],
          reminders: reminders,
          odometerReadings: readings,
          odometerCorrections: corrections,
          fillUps: fillUps,
          services: services,
          expenses: expenses,
          trips: trips,
        ),
        warnings: warnings,
        recordsRead: readable,
        recordsInFile: found,
        preferredActiveVehicleId: activeVehicleFromBackup(
          settingsJson is Map<String, Object?> ? settingsJson : const {},
        ),
      ),
    );
  }
}

/// The placeholder §5.3's orphans are attached to.
///
/// Its NAME is a message key, resolved at the presentation edge: three of the
/// six locales are right-to-left, and a vehicle called "Recovered records" in
/// an Arabic garage would be the one row in English.
Vehicle _recoveredRecordsVehicle(int nowUtcMs) => Vehicle(
  id: kRecoveredRecordsVehicleId,
  name: kRecoveredVehicleNameKey,
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.petrol,
  status: VehicleStatus.active,
  createdAtUtcMs: nowUtcMs,
  updatedAtUtcMs: nowUtcMs,
);

/// The ARB key the placeholder vehicle's name resolves through.
const String kRecoveredVehicleNameKey = 'import.recoveredVehicleName';

final Currency _euro = Currency.tryParse('EUR')!;

/// The vehicle §5.3's orphans are attached to.
///
/// A fixed id so a second import of the same damaged file lands on the same
/// vehicle instead of creating a second one beside it.
final VehicleId kRecoveredRecordsVehicleId = VehicleId.tryParse(
  'veh_00000000000000000000000000',
)!;

int _outOfRangeDates({
  required DateTime? exportedAt,
  required List<String> dates,
}) {
  final ceiling = (exportedAt ?? DateTime.utc(9999)).add(
    const Duration(days: 365 * kLatestPlausibleYearsAhead),
  );
  var count = 0;
  for (final date in dates) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) continue;
    // Imported either way, then flagged. A phone whose clock was wrong is
    // still the user's history, and they are the only one who can say which
    // date was meant.
    if (parsed.year < kEarliestPlausibleYear || parsed.isAfter(ceiling)) {
      count++;
    }
  }
  return count;
}

bool _isCompressed(List<int> bytes) {
  if (bytes.length < 4) return false;
  final gzip = bytes[0] == 0x1f && bytes[1] == 0x8b;
  final zip =
      bytes[0] == 0x50 &&
      bytes[1] == 0x4b &&
      (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07);
  return gzip || zip;
}

/// [bytes] without a leading UTF-8 BOM.
///
/// Stripped SILENTLY: a BOM is something a text editor added, not something
/// the user did, and there is nothing for them to act on.
List<int> _withoutBom(List<int> bytes) =>
    bytes.length >= 3 &&
        bytes[0] == 0xef &&
        bytes[1] == 0xbb &&
        bytes[2] == 0xbf
    ? bytes.sublist(3)
    : bytes;

/// Whether [error] died at the end of [text] rather than in the middle.
///
/// "The end" is generous — trailing whitespace, and the closing braces a
/// truncated file is missing — because the distinction it decides is which of
/// two sentences the user reads, and being one byte pedantic about it would
/// send someone to re-download a file that was genuinely edited.
bool _endsThere(FormatException error, String text) {
  final offset = error.offset;
  if (offset == null) return false;
  return text.substring(offset).trim().isEmpty;
}

/// Walks [node], truncating over-long strings and refusing over-deep nesting.
///
/// One pass rather than two, and iterative rather than recursive on the way in:
/// a document deep enough to matter is one that would blow the stack of the
/// check meant to catch it.
Object? _guard(Object? node, RestoreLog log, [int depth = 0]) {
  if (depth > kMaxNestingDepth) throw _TooDeepSignal(depth);
  return switch (node) {
    final String text when text.length > kMaxStringLength => _truncate(
      text,
      log,
    ),
    final Map<String, Object?> map => {
      for (final entry in map.entries)
        entry.key: _guard(entry.value, log, depth + 1),
    },
    final List<Object?> list => [
      for (final item in list) _guard(item, log, depth + 1),
    ],
    _ => node,
  };
}

String _truncate(String text, RestoreLog log) {
  log.truncatedStrings++;
  return text.substring(0, kMaxStringLength);
}

class _TooDeepSignal implements Exception {
  const _TooDeepSignal(this.depth);
  final int depth;
}
