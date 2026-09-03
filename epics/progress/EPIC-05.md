- 5.1 Drift wired, four pragmas asserted on a reopened database, confinement gate seen to fail both ways. Dependencies audited: no socket path from drift/sqlite3/path_provider.
- 5.2 RecordId (nine prefixes) and the ULID. **Epic correction:** the "Where we are
  now" section claims a `Result`/`Failure` spine is already in use. There was none —
  `lib/core/` held only `money.dart`, `due/` and `l10n/`. Built here, because 5.2's
  `parse` and 5.7's repositories both return one and a second vocabulary would mean
  converting between them forever.
- 5.3 Column contract: audit columns mixin, `repairAuditTimes` (clamp on read, per
  SPEC §3), and the schema-wide reflection tests. `column_types.dart` was written and
  then deleted — the constraint-template helpers had no caller, because drift's
  generator needs a literal it can read statically.
- 5.4 `Vehicles`, `ServiceItems`, `Settings`. **Two Drift APIs that look like schema
  constraints and are not:** `.references()` emitted no `REFERENCES` clause (so the
  cascade Undo depends on did not exist) and `.withLength()` is Dart-side only (so all
  four currency columns were unchecked). Both now gated by
  `test/data/db/schema_reality_test.dart`, which reads `sqlite_schema` and
  `PRAGMA foreign_key_list` rather than trusting the Dart.
