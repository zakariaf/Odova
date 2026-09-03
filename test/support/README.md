# `test/support` — shared harness

`pump_app.dart` is the widget harness every later epic pumps through; it takes a
locale and a `ThemeMode` because the parity captures need all four
combinations, and it deliberately does **not** clamp the text scaler —
`SPEC.md` §17's accessibility gate needs 200% to be reachable.

`fakes.dart` is the barrel for fake repositories and services. A faked
`Notifier` never belongs here: a `Notifier` is the thing under test.
