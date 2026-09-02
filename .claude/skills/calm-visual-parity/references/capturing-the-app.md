# Capturing the built screen so it is comparable

The reference is 390×844 logical at devicePixelRatio 2 → **780×1688 px**. Capture at the same
size or the band check compares different geometry. The tool resizes what you give it, so a
1×capture still works, but a capture at a different *aspect* silently distorts and will fail
the band check for a reason that is not the screen's fault.

## In a widget test — the one to use in CI

`widget-golden-and-a11y-testing` owns the `pumpApp` harness; parity reuses it and pins three
extra things. All three matter:

```dart
tester.view.physicalSize = const Size(780, 1688);
tester.view.devicePixelRatio = 2.0;
addTearDown(tester.view.reset);          // else the next test inherits the phone
```

- **Pin `ThemeMode` explicitly.** Do not rely on the platform brightness: the wrong-theme
  failure is the single most common parity red, and it is almost always the harness rather
  than the screen.
- **Pin the locale and the directionality.** `Locale('fa')` with `TextDirection.rtl` for the
  RTL captures. The app resolves numerals and calendar from the locale, so a capture with the
  wrong locale is comparing against the wrong reference.
- **Pin `textScaler` to 1.0.** The references were shot at default scale. Text-scale
  behaviour is a separate gate that `widget-golden-and-a11y-testing` owns.
- **Freeze motion.** Set the reduce-motion flag rather than calling `pumpAndSettle()`, which
  asserts nothing once animations collapse to zero (`calm-layout-and-motion`).

Full worked file: `examples/parity_golden_test.dart`.

## On a device, for the human pass

```bash
flutter run --release
# iOS Simulator: iPhone 14 (390x844 @2x) — Cmd-S saves to the Desktop
# Android: adb exec-out screencap -p > home-light-ltr.png
```

An emulator screenshot includes the OS status bar and the gesture bar; the references draw
their own. Crop to the app's own bounds, or expect the band check to complain about the top
and bottom ~50px.

## Naming what you capture

`compare_to_reference.mjs` takes the screen id as an argument, so the filename is yours to
choose — but naming captures the same way as the references makes the loop scriptable:

```
build/parity/<screen>-<theme>-<direction>.png
```

`scripts/check_parity.sh` assumes exactly that and walks the directory.

## The four captures a screen needs

| Capture | Locale | Direction | Theme |
|---|---|---|---|
| `<screen>-light-ltr.png` | `en` | ltr | light |
| `<screen>-dark-ltr.png` | `en` | ltr | dark |
| `<screen>-light-rtl.png` | `fa` | rtl | light |
| `<screen>-dark-rtl.png` | `fa` | rtl | dark |

Four, not one. A screen that has only been checked in light LTR has been checked in the one
configuration least likely to be broken.
