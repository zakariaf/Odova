- 5.1 Drift wired, four pragmas asserted on a reopened database, confinement gate seen to fail both ways. Dependencies audited: no socket path from drift/sqlite3/path_provider.
- 5.2 RecordId (nine prefixes) and the ULID. **Epic correction:** the "Where we are
  now" section claims a `Result`/`Failure` spine is already in use. There was none —
  `lib/core/` held only `money.dart`, `due/` and `l10n/`. Built here, because 5.2's
  `parse` and 5.7's repositories both return one and a second vocabulary would mean
  converting between them forever.
