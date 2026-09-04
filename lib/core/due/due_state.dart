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
///
/// This file also held a `DueConfidence` — `{ measured, assumed, defaulted }`,
/// written by EPIC-02 for the due card — until EPIC-07 wrote `RateConfidence`
/// with the same three members for the rate that confidence describes. The
/// value flows from one to the other, since the rate's confidence is exactly
/// what the card renders, so two types meant a conversion between two enums
/// that are supposed to be identical: a place they stop being identical.
///
/// `RateConfidence` won because it says what it is and because it is what the
/// epic's own signatures name. It is re-exported here so a caller reaching for
/// the due vocabulary still finds it in one place.
/// `test/policy/one_money_type_test.dart` now fails on any two enums that
/// share a member set.
library;

export 'package:odova/core/due/daily_distance.dart' show RateConfidence;

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

/// Severity for COMBINING two axes — "which axis is worse".
///
/// Deliberately different from `due_summary.dart`'s ranking, which answers
/// "which item do I name first". The two ties here are the difference:
///
///   * `needsOdometer` ties with `dueSoon`, because a distance axis that cannot
///     be placed must not outrank a time axis that can. §3: "if the time axis
///     independently reaches due or overdue, that wins and shows as itself".
///   * `ok` ties with `unknown`, because neither is a call to action and
///     `_driver` compares severities to decide `DueDriver.both`.
///
/// Naming them apart matters: EPIC-11's notification ranking and EPIC-12's home
/// sort are the next consumers of this idea, and each will reach for whichever
/// function is nearer its import.
int axisSeverity(DueState state) => switch (state) {
  DueState.ok => 0,
  DueState.unknown => 0,
  DueState.needsOdometer => 1,
  DueState.dueSoon => 1,
  DueState.due => 2,
  DueState.overdue => 3,
};

/// Ranking for choosing which item to NAME FIRST.
///
/// A total order over all six states, and deliberately not `axisSeverity` in
/// `due_engine.dart`, which answers a different question — "which axis is
/// worse" — and ties two pairs this one separates.
///
/// `needsOdometer` sits BELOW `due` and `overdue`, which is the rule
/// `calm-due-state-and-status` states: an accusation the app can support beats
/// one it cannot, and a hollow ring where a red dot belongs understates the
/// only item the user needs to act on today. `unknown` sits below `ok`, because
/// "nothing to do" is a better thing to lead with than "we cannot say".
int attentionRank(DueState state) => switch (state) {
  DueState.unknown => 0,
  DueState.ok => 1,
  DueState.dueSoon => 2,
  DueState.needsOdometer => 3,
  DueState.due => 4,
  DueState.overdue => 5,
};

/// The two states that mean "we do not know".
///
/// Neither may carry a figure and neither may borrow the ok or overdue palette
/// (SPEC.md §1) — which is why `CalmStatusStyle.isUncertain` in the theme reads
/// the same pair. It is here as well because the DOMAIN needs it too: on a
/// severity tie between the two axes, the axis that KNOWS wins.
bool isUncertainState(DueState state) =>
    state == DueState.unknown || state == DueState.needsOdometer;
