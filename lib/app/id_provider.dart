// The id factory, injected once at the composition root.
//
// A provider rather than a global so a test can fix both the clock and the
// randomness and get the same id twice. `seeded-determinism-and-golden-vectors`
// names an ambient `Random()` on a generation path as the thing that turns a
// failing test into a story about a machine.
// **Not in `lib/core/`.** It is a Riverpod provider — dependency-injection
// wiring, which is what `lib/app/` is for. The FACTORY it wires is pure and
// stays in `lib/core/ids/`; only the wiring moved. A provider in the pure core
// means the core cannot be tested without a ProviderContainer, which is the
// opposite of the point.

import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/core/ids/ulid.dart';

/// Mints every id in the app.
///
/// The default reads the ambient `clock` — which `app-startup-and-bootstrap`
/// overrides once — and a `Random.secure()`. Overridden wholesale in a test
/// with a fixed clock and a seeded `Random`.
final ulidFactoryProvider = Provider<UlidFactory>(
  (ref) => UlidFactory(clock: clock, random: Random.secure()),
);
