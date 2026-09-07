// SPEC.md §6 §3.1's chain, written as the spec writes it.
//
// A chain of pure `json → json` functions applied IN MEMORY, before anything
// touches the database. That is not an optimisation. A migration that could
// write would be a migration that can half-write, and a half-migrated import is
// the failure §2 calls the worst bug this app can have: eight years of service
// history in a state no version of the app understands.
//
// There is no special case for "an old file". There is only the chain: a v1
// file opened by a v4 app runs 1→2→3→4 and then follows the ordinary import
// path, so the old-file route and the current-file route are the same route and
// cannot rot apart.
import 'package:odova/features/backup/domain/backup_format.dart';
import 'package:odova/features/backup/domain/migrations/v0_defaults.dart';

/// One step of the chain: a whole document in, a whole document out.
///
/// A function and not a class, because a migration has no state and the one
/// thing it must not have is a dependency it could do I/O through.
typedef JsonMigration =
    Map<String, Object?> Function(Map<String, Object?> document);

/// The real chain, keyed by the version each step migrates FROM.
///
/// Empty at version 1, which is the only version that has shipped. It is
/// declared anyway so the first bump is an entry in a map rather than an
/// architecture, and `migration_chain_test` asserts every step up to
/// [kSupportedFormatVersion] exists — so bumping the constant without writing
/// the migration is a red test rather than a silently mis-read file.
const Map<int, JsonMigration> kMigrations = {};

/// Runs [document] up to [to], stamping `format_version` at each step.
///
/// [migrations] is a parameter so the loop can be tested with synthetic steps.
/// At version 1 the real map is empty, and a `while` nobody has ever watched
/// iterate is a `while` that might as well be an `if`.
Map<String, Object?> runMigrations(
  Map<String, Object?> document, {
  int to = kSupportedFormatVersion,
  Map<int, JsonMigration> migrations = kMigrations,
}) {
  var current = document;
  var version = current['format_version'];
  while (version is int && version < to) {
    final step = migrations[version];
    if (step == null) {
      // A gap means a version shipped and its migration was forgotten, which
      // would otherwise present as a v2 file quietly imported as a v3 one.
      // That is a programmer error, so it throws — rule 8 of
      // `error-handling-typed-results`.
      throw StateError(
        'no migration from format_version $version — the chain to $to is '
        'incomplete, and importing without it would read the file as '
        'something it is not',
      );
    }
    current = {...step(current), 'format_version': version + 1};
    version = version + 1;
  }
  return current;
}

/// The chain plus §6 §3.1's fill-in table, which is what import actually runs.
///
/// The defaults are applied AFTER the version steps and unconditionally, not
/// only for old files: §3.1's table is about absent fields, and a field can be
/// absent from a current-version file that was hand-edited or written by a
/// build that had a bug. A default applied twice is the same default.
Map<String, Object?> migrateForImport(Map<String, Object?> document) =>
    fillDefaults(runMigrations(document));
