// The schema version this build of the app expects.
//
// SPEC.md §6.3 Versioning and migration.
//
// Hand-written, because `drift_dev schema steps` does not emit one — it
// generates the ladder and leaves the number to the app. That makes it exactly
// the kind of constant that drifts: bumping `drift_schemas/` without bumping
// this means the migration never runs, and bumping this without a snapshot
// means `stepByStep` throws `Unknown migration from N` on a user's device.
//
// Both directions are gated. `test/migration/freshness_test.dart` derives the
// highest committed snapshot from `drift_schemas/odova/` and compares it, and
// `tools/check_schema_freshness.sh` does the same in CI without a Flutter
// toolchain.
//
// **The ritual when this changes**, in order:
//
//     dart run drift_dev make-migrations
//     dart run drift_dev schema steps drift_schemas/odova/ \
//         lib/data/schema_versions.dart
//     dart run drift_dev schema generate --data-classes --companions \
//         drift_schemas/odova/ test/drift/generated/
//     dart run build_runner build --delete-conflicting-outputs
//
// The two flags on the third command are load-bearing: without them only shape
// tests are possible, and a shape test reads zero rows — so it cannot tell a
// migration that copied every row from one that copied none.

/// The current schema version.
const kLatestSchemaVersion = 1;
