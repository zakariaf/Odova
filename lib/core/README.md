# `lib/core` — the pure domain

**Owner:** the rules that are true whether or not there is a screen.
**Skills:** `dart3-idioms-and-coding-standards`, `value-objects-money-and-units`,
`error-handling-typed-results`, `seeded-determinism-and-golden-vectors`.

The due engine, the fuel maths, unit conversion, the projection, the value
objects and the typed failures. **No Flutter import, no `dart:ui`, no
`dart:io`** — `test/policy/structure_test.dart` enforces that, and it is what
lets this layer test in milliseconds without a widget harness.

`SPEC.md` §2: derived values are never persisted. Every one of them is a named
pure function that lives here.
