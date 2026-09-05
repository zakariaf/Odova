// Local UI state — the three things Home remembers that are not the user's
// history.
//
// SPEC.md §9: "`home.staleness_dismissed_until.<vehicle_id>`,
// `home.digest_shown_at`, `home.first_run_hint_dismissed` — lives in a
// key-value store that is **not** in the backup file. A restore should bring
// back the car's history, not the fact that someone dismissed a banner in
// 2024."
//
// **A FILE beside the database, not a table inside it.** Every backup and every
// migration safety copy is produced by reading the database, table by table
// from a declared list — so putting this outside the database makes "not in the
// backup" a property of the shape rather than of a list somebody maintains. It
// also needs no schema version, no migration ladder and no dependency: a
// dismissed banner is not worth a `stepByStep` rung that has to keep working
// for eight years.
//
// It is deliberately forgiving. This file is never the user's history; losing
// it costs a dismissed banner, and refusing to launch over it costs the app.
import 'dart:convert';
import 'dart:io';

/// The file, in the application SUPPORT directory beside `odova.sqlite`.
const String kUiStateFileName = 'odova-ui-state.json';

/// `home.digest_shown_at` — when the away digest was last shown.
const String kUiKeyDigestShownAt = 'home.digest_shown_at';

/// `home.first_run_hint_dismissed` — the one-line first-run hint under the
/// tiles.
const String kUiKeyFirstRunHintDismissed = 'home.first_run_hint_dismissed';

/// `home.staleness_dismissed_until.<vehicle_id>` — per vehicle, because §9's
/// `✕` "hides for 7 days, this vehicle".
String uiKeyStalenessDismissedUntil(String vehicleId) =>
    'home.staleness_dismissed_until.$vehicleId';

/// A tiny string-to-string store, read once and written through.
///
/// Read is SYNCHRONOUS and write is not. Home decides whether to draw a strip
/// while it builds, and a future there would mean a frame with the strip and a
/// frame without; a dismissal, by contrast, happens on a tap and can take a
/// disk write with it.
class UiStateStore {
  UiStateStore._(this._file, this._values);

  /// An in-memory store, for a test that wants no disk at all.
  factory UiStateStore.inMemory([Map<String, String> seed = const {}]) =>
      UiStateStore._(null, {...seed});

  /// Opens the store in [directory], creating nothing until something is
  /// written.
  ///
  /// Never throws. A missing file, an unparseable one, or JSON that is not a
  /// string map all produce an EMPTY store — see the file header for why that
  /// is the right answer for this file and the wrong one for the database.
  static Future<UiStateStore> open(Directory directory) async {
    final file = File('${directory.path}/$kUiStateFileName');
    return UiStateStore._(file, await _readOrEmpty(file));
  }

  final File? _file;
  final Map<String, String> _values;

  /// The value for [key], or null when it was never written.
  ///
  /// Null and not the empty string: "never dismissed" and "dismissed until
  /// nothing" are different facts and only the first may show a strip.
  String? read(String key) => _values[key];

  /// Everything, for a provider that wants to hand out an immutable view.
  Map<String, String> get snapshot => Map.unmodifiable(_values);

  /// Writes [key], replacing whatever was there.
  Future<void> write(String key, String value) {
    _values[key] = value;
    return _flush();
  }

  /// Removes [key].
  Future<void> remove(String key) {
    _values.remove(key);
    return _flush();
  }

  Future<void> _flush() async {
    final file = _file;
    if (file == null) return;
    try {
      await file.writeAsString(jsonEncode(_values), flush: true);
    } on FileSystemException {
      // A full disk. The value is already in memory, so this session behaves
      // correctly and the next one forgets — which for a dismissed banner is
      // the right failure. Nothing here is worth an error the user has to read.
    }
  }

  static Future<Map<String, String>> _readOrEmpty(File file) async {
    try {
      if (!file.existsSync()) return {};
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
      };
    } on FormatException {
      return {};
    } on FileSystemException {
      return {};
    }
  }
}
