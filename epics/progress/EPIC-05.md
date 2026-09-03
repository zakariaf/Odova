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
- 5.5 The four event tables. Six constraints mutated and each seen to turn the suite
  red; the tests were written after the tables here and the mutation sweep stands in
  for the red I did not watch.
- 5.6 Odometer readings, corrections, cumulative fold, monotonicity guard, four
  indexes. **SPEC.md edited:** §3's `OdometerCorrection.reason` enum listed
  `unit_mixup` and §14 said it was removed. §14 wins — storage is metres and the unit
  is a per-record fact, so a km cluster on a miles car needs no offset — and §3 was
  fixed rather than the CHECK widened. Recorded for the PR's **Spec** heading.
  The index tests use `EXPLAIN QUERY PLAN`: reordering an index's columns leaves it
  existing *and used* while adding a sort step, which only the `TEMP B-TREE`
  assertion catches.
