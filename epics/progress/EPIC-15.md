# EPIC-15 — Backup, export and import

**Baseline at branch point** — `main` at `f16c158` (EPIC-14 merged), analyzer
clean, 4,347 tests green, every gate green.

**Carried in from EPIC-14**, both recorded there and repeated because this epic
is where one of them lands:

- **`kSupportedFormatVersion` now lives in `lib/backup/backup_format.dart`.**
  EPIC-14 declared it in `lib/app/app_version.dart` because this epic had not
  landed, with a doc saying task 15.1 takes ownership. It has.
- **The Numerals control is stored and read by one card** — 82 call sites pass
  `CalmNumerals.auto` literally. Recorded for EPIC-17; it matters here only as
  the reason §6's "every digit ASCII" rule needs its own test rather than
  relying on the app's numeral setting being off.

## Task 15.1 — the envelope, the hash and the value projections

Built `backup_format.dart`, `content_hash.dart` and
`mapping/backup_values.dart` — under **`lib/features/backup/domain/`**, not the
`lib/backup/` the epic's plan names.

`structure_test.dart` allows seven top-level directories and this would have
been an eighth. Two homes were considered and rejected: `lib/data/backup/`
fights two gates the moment the writer unwraps a value —
`no_conversion_on_write_test` reserves `.metres` and `.amountMinor` for
`lib/data/db/mappers/`, and `no_drift_in_signatures_test` reads every public
signature there — which is the same collision EPIC-13 hit with
`costs_source.dart`. And widening the seven-directory list is a decision the
gate exists to make visible, for a feature that already has two screens
(`settings.backup`, `settings.import`) and therefore a feature folder. This is
the third time an epic's plan has named a directory the repo's own rule
refuses; the pattern is recorded here rather than argued again next time.

**`crypto` added as a direct dependency**, with the audit run. It was already
present transitively through `drift_dev`; declaring it makes the use owned
rather than borrowed, which is what `depend_on_referenced_packages` is for.
Pure Dart, no plugin, no platform channel — `tools/audit_deps.sh` walks the
resolved tree and finds no socket.

**The hash trick is the placeholder's LENGTH.** Write `sha256:` and 64 zeros,
hash the document that contains them, overwrite in place. No byte offset
moves, so the digest describes exactly the file on disk rather than a shorter
one that never existed — and the verifier puts the placeholder back to check,
because that is the only way to hash the same bytes the writer hashed. An
assertion pins the two lengths together so the invariant cannot be broken
silently.

It is an INTEGRITY check and not a signature: §2 has no server and no key, so
anybody can recompute it after editing the file. What it catches is a
truncated download or a half-written file, which is the failure that actually
happens to a backup.

Timestamps drop Dart's `.000` sub-second suffix — three characters of nothing
in every row of a 12,000-record file, and a difference from §6 §2.5's worked
example that the byte-comparison test would report as a format mismatch.
