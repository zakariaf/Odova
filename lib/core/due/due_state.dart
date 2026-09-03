/// What Odova knows about a reminder, as three enums and nothing else.
///
/// **Pure Dart, deliberately.** EPIC-07's due engine lives in `lib/core/due/`
/// and may not import Flutter, so the enums it RETURNS cannot live in
/// `lib/theme/calm/calm_status.dart`, which needs `Color`. That file re-exports
/// these, so `import 'package:odova/theme/calm/calm_status.dart'` still yields
/// `DueState` and every epic that expects to find it there does.
///
/// The split is the layering, not a workaround: what a state IS belongs to the
/// domain, and what it LOOKS LIKE belongs to the theme.
library;

/// The product's due states. Exactly six, exactly these (SPEC.md §3).
///
/// `paused` is not here: it is `ServiceItem.is_active == false`, filtered
/// before the engine runs, so it has no card to style. `snoozed` is not here
/// either — a snoozed item keeps its real state and gains a fourth line.
enum DueState {
  /// Past the due point and past its grace window.
  overdue,

  /// At or past the due point, still inside grace.
  due,

  /// Inside the notice window, not yet due.
  dueSoon,

  /// Nothing to do.
  ok,

  /// No anchor on either axis: no service record, no baseline, no purchase
  /// fact, no reading. Odova cannot say when, and must never say `overdue`.
  unknown,

  /// There is an anchor, but the odometer is too stale to place the distance
  /// axis. Asks for a reading rather than guessing at one.
  needsOdometer,
}

/// Which axis produced the worst status. Selects the copy pattern, never the
/// colour.
enum DueDriver {
  /// The distance axis was worse.
  distance,

  /// The time axis was worse.
  time,

  /// Both axes reached the same severity.
  both,

  /// Neither axis could be assessed.
  none,
}

/// How much the projection engine actually knows about the daily rate.
///
/// `default` is a Dart reserved word, hence [defaulted]; it is SPEC.md §4.1's
/// `default` and serialises as `"default"` in any payload. Do not alias it
/// anywhere else.
enum DueConfidence {
  /// A two-endpoint slope over real readings.
  measured,

  /// The vehicle's `expected_annual_m`.
  assumed,

  /// 12,000 km a year, because there was nothing else.
  defaulted,
}
