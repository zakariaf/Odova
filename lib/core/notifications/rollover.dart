// The next interval is measured from what happened, not from what was planned.
//
// SPEC.md §4.7.4, and it is the arithmetic with the worst failure mode in this
// app. Oil due at 115,000 km and actually done at 118,400 rolls to 128,400, not
// to 125,000.
//
// Rolling from the DUE value creates a permanent debt. The user stays "3,400 km
// behind" forever, every later reminder fires while the oil is still fresh, and
// the app is wrong in the direction that teaches people to ignore it. Nothing
// on screen would show it — the due figure looks entirely plausible — so it is
// the kind of wrong that ships.
//
// The exception is the three ANCHORED kinds. An inspection is tied to a
// calendar anchor whatever week the paperwork happened in, so it rolls from the
// due date; rolling from actual would walk the renewal forward a few weeks a
// year until it had drifted a season.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/time/civil_date.dart';

/// Past this, a late anchored completion asks whether to re-anchor.
///
/// SPEC.md §4.7.4: "a genuinely lapsed registration does re-anchor." Inside 60
/// days it is paperwork done late and the anchor stands — asking then would be
/// a dialog every year for everybody.
const int kLateAnchorDays = 60;

/// The three kinds §8 marks `from_due`.
///
/// A function over the enum rather than a constant set, so `ServiceKind.values`
/// can be walked against it — a fourth kind added to the enum and quietly
/// anchored fails a test rather than passing one.
bool isAnchoredKind(ServiceKind kind) =>
    kind == ServiceKind.inspection ||
    kind == ServiceKind.insuranceRenewal ||
    kind == ServiceKind.registration;

/// The odometer the item is next due at, or null when it has no distance
/// interval.
///
/// ALWAYS from the actual odometer, including for an anchored item. `from_due`
/// is about a CALENDAR anchor; the distance half has no anchor to be tied to,
/// and a registration that somehow carries a distance interval still wears at
/// the rate the car is driven.
///
/// Null rather than an invented value when [intervalMetres] is absent — §4.7.4:
/// "If only the distance interval is set, only the distance rolls. Never invent
/// the missing dimension."
int? nextDistanceThreshold({
  required ServiceRollover rollover,
  required int dueAtMetres,
  required int doneAtMetres,
  required int? intervalMetres,
}) => intervalMetres == null ? null : doneAtMetres + intervalMetres;

/// The date the item is next due, or null when it has no time interval.
///
/// This is where [rollover] actually bites: `from_actual` measures from the day
/// it was done, `from_due` from the day it was due.
///
/// A back-dated completion can return a date already in the past, and that is
/// correct rather than a bug to clamp away. §4.7.4: reprojection may
/// immediately mark the item due again, and the confirmation says so rather
/// than silently producing a red item — clamping to "today plus interval" would
/// invent a service that never happened.
CivilDate? nextDueDate({
  required ServiceRollover rollover,
  required CivilDate dueOn,
  required CivilDate doneOn,
  required int? intervalMonths,
}) {
  if (intervalMonths == null) return null;
  final from = rollover == ServiceRollover.fromDue ? dueOn : doneOn;
  return from.addMonths(intervalMonths);
}

/// Whether to ask the user once whether a late anchored item re-anchors.
///
/// Only for an anchored kind, only when genuinely late, and never for something
/// done early. §4.7.4: "Never ask otherwise."
bool asksAboutLateAnchor({required ServiceKind kind, required int daysLate}) =>
    isAnchoredKind(kind) && daysLate > kLateAnchorDays;
