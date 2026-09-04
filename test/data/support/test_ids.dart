/// A ULID factory with a fixed clock and a seeded random, for the data tests.
///
/// Both are injected rather than ambient so a failing test is reproducible —
/// `seeded-determinism-and-golden-vectors` names an ambient `Random()` on a
/// generation path as the thing that turns a failure into a story about a
/// machine.
library;

import 'dart:math';

import 'package:clock/clock.dart';
import 'package:odova/core/ids/ulid.dart';

/// A factory that mints the same ids every run.
UlidFactory testIds({int seed = 42}) => UlidFactory(
  clock: Clock.fixed(DateTime.utc(2026, 9, 3, 12)),
  random: Random(seed),
);
