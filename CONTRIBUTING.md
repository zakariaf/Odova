# Contributing to Odova

Thank you for looking. This document is short because most of the real answers
live in [`SPEC.md`](SPEC.md), which is the source of truth for what Odova does.

## Before you write code

**Read the spec section you are about to implement.** If the code and the spec
disagree, the spec is right until a PR changes it — and changing it is a normal,
welcome kind of PR. What is not welcome is code that quietly diverges.

**Check `SPEC.md` §15 Explicitly out of v1** before proposing a feature. Cloud
sync, accounts, OBD/Bluetooth, receipt OCR, fuel-price lookup, a VIN or
manufacturer service database, and anything else needing a network call are
settled decisions, not oversights.

## The four rules that outrank everything

1. **No network. At all.** No HTTP client, no analytics SDK, no crash reporter,
   no font CDN, no dependency that transitively opens a socket. The store
   listing will claim zero network calls and that claim has to be true by
   construction, not by policy. A dependency that pulls `package:http` into the
   binary is refused however convenient it is.
2. **No account, no server, no sync.** The user's data lives on their phone and
   in the backup file they keep themselves.
3. **Six locales or none.** Every user-visible string lands in all six ARB files
   in the same commit: `en`, `de`, `fr`, `fa`, `ar`, `ckb`. Three are
   right-to-left. No concatenated sentences, no `if (n == 1)` — ICU messages
   with real CLDR plural categories, because Arabic needs all six of them.
   No layout code uses `left` or `right`; it is `start` and `end`.
4. **Data survives.** Losing someone's eight-year service history is the worst
   bug this app can have, and it outranks every feature. Any change touching
   persistence has to survive export → wipe → import with a byte-identical
   result.

## Working on it

```bash
flutter --version                      # must equal .flutter-version
flutter pub get --enforce-lockfile     # the committed lock IS the pin
dart format .
flutter analyze --fatal-infos --fatal-warnings
flutter test
```

Before pushing, run the gates CI will run:

```bash
bash tools/check_gates_selftest.sh
bash tools/check_release_hygiene.sh
python3 tools/check_spec_examples.py
```

`tools/` holds repo gates and the app-name checker. Scripts there are Bash or
Python and need no Flutter toolchain, so they run in a fresh clone.

## Tests

Domain logic — the due engine, the fuel maths, unit conversion, the projection —
is pure Dart with no Flutter import, so it tests in milliseconds without a widget
harness. That is the point of the layering, and a PR that puts domain logic
behind a `BuildContext` will be asked to move it.

Every gate must have been **seen to fail**. A gate that has only ever been green
is a comment; `tools/check_gates_selftest.sh` plants a real violation for each
one and asserts both arms. New gate, new self-test.

## Localisation

`en` is the template and the source of truth. Every key carries a description
and typed placeholders — nobody can tell whether "Due" is a noun or an adjective
from the key alone.

If you are a native speaker of Persian, Arabic or Kurdish Sorani, the most
valuable thing you can do is read `SPEC.md` §18 and settle one of the open
questions. Several cannot be answered by anyone else — whether `ckb-IR` should
default to the Jalali calendar, whether Sorani should ship Persian or Arabic
digits, and whether a toman-labelled amount reads correctly for both a fuel fill
and a service bill.

## Pull requests

Fill in the template. It asks what changed, which spec section it implements,
whether all six locales were updated, and what was deliberately left undone.
"Deferred" is a real answer and a good one.

Commits: a short imperative subject (`add the fuel segment builder`), and a body
explaining *why* when the why is not obvious. Reference `EPIC-NN` where one
applies.

## Reporting a bug

Odova has no server, so there are no logs to check — your report is all anyone
will have. **Never attach a real backup file:** it is your whole history in plain
text, including where you fill up and what you spend. Trim it to the few records
that reproduce the problem.

## Licence

By contributing you agree your work is licensed under [Apache 2.0](LICENSE).
