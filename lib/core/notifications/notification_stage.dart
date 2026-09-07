// The four notifications an item wants, and the point at which it stops.
//
// SPEC.md §4.4.1. `early` at due−notice, `due` on the day, `overdue1` at +14
// and `overdue2` at +45 — and then nothing, ever. The spec's own words: "two
// overdue pings is the entire budget for being ignored". The item stays red at
// the top of the home screen indefinitely, which is a channel that costs the
// user nothing and cannot be turned off by an OS permission.
//
// The stage is not the payload kind and the difference is deliberate. `early`
// ships as `reminder.due` because it is a SCHEDULE stage: nothing outside this
// file needs to tell a warning from the thing it warns about, and giving it its
// own kind would mean a seventh value in §4.4.2's table that routing would
// handle identically.
import 'package:odova/core/notifications/notification_payload.dart';
import 'package:odova/core/time/civil_date.dart';

/// 120 days. SPEC.md §6.1.
///
/// This is what makes the pending cap a CONSEQUENCE rather than a mechanism:
/// 120 days at two a week is about 34 slots, whatever the household owns, so
/// five vehicles with twelve reminders each never approaches the 240 the naive
/// arithmetic suggests. A date eight months out will be recomputed dozens of
/// times before it arrives — scheduling it now spends budget on a body that
/// will be wrong.
const int kHorizonDays = 120;

/// 14 days past due. SPEC.md §4.4.1.
const int kOverdue1Days = 14;

/// 45 days past due.
const int kOverdue2Days = 45;

/// One notification an item or a vehicle wants.
enum NotificationStage {
  /// `projected_due_date − notice`, once.
  early,

  /// On the projected due date, once.
  due,

  /// Two weeks past, once.
  overdue1,

  /// Six and a half weeks past, once. The last one.
  overdue2,

  /// "What's the odometer?" — SPEC.md §4.3. Belongs to the vehicle rather than
  /// to any item, which is why it has no stage date of its own.
  nudge;

  /// Whether this stage is one of an ITEM's four.
  bool get isItemStage => this != nudge;

  /// SPEC.md §4.3 step 2's order, lowest first.
  ///
  /// `nudge` sits above `early`, and that is the one placement worth arguing
  /// about. Read as pure urgency a nudge sorts last — nothing is due. But
  /// asking for a reading FIXES every estimate on the vehicle, and an `early`
  /// warning built on a stale estimate may be warning about the wrong week.
  /// Repairing the input beats acting on a bad one.
  int get rank => switch (this) {
    NotificationStage.overdue2 => 0,
    NotificationStage.overdue1 => 1,
    NotificationStage.due => 2,
    NotificationStage.nudge => 3,
    NotificationStage.early => 4,
  };

  /// Whether this stage may take one of §4.3 step 4's two reserved slots.
  ///
  /// Two of the next four weeks' slots are held so that a queue full of `early`
  /// warnings can never starve an overdue safety item or a nudge.
  bool get claimsReservedSlot =>
      this == overdue1 || this == overdue2 || this == nudge;

  /// The `kind` this stage's payload carries — SPEC.md §4.4.2.
  DeepLinkKind get payloadKind => switch (this) {
    NotificationStage.early ||
    NotificationStage.due => DeepLinkKind.reminderDue,
    NotificationStage.overdue1 ||
    NotificationStage.overdue2 => DeepLinkKind.reminderOverdue,
    NotificationStage.nudge => DeepLinkKind.odometerNudge,
  };
}

/// The four stage dates for an item due on [due].
///
/// [noticeDays] is the due_soon window the due engine already computed —
/// `clamp(10% of the interval in days, 7, 30)`. It is passed in rather than
/// recomputed so that ONE window drives both the card colour and the `early`
/// notification; two computations of the same number is how a card goes amber
/// on a different day from the notification that explains it.
Map<NotificationStage, CivilDate> stageDatesFor({
  required CivilDate due,
  required int noticeDays,
}) => {
  NotificationStage.early: due.addDays(-noticeDays),
  NotificationStage.due: due,
  NotificationStage.overdue1: due.addDays(kOverdue1Days),
  NotificationStage.overdue2: due.addDays(kOverdue2Days),
};

/// Whether [stage] is close enough to schedule.
///
/// A stage in the PAST is within the horizon. §4.2.2 rule 3 sends a recomputed
/// past time to the next delivery slot rather than dropping it; refusing it
/// here would silently lose every stage belonging to a phone that spent a
/// fortnight switched off, which is the user this feature exists for.
bool withinHorizon({required CivilDate today, required CivilDate stage}) =>
    today.daysUntil(stage) <= kHorizonDays;
