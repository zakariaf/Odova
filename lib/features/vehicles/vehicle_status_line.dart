// The line the garage and the switcher BOTH draw.
//
// EPIC-09 task 9.7: "The odometer-with-status row is the same widget `vehicles`
// uses, parameterised, not a second copy." Two copies is two answers to "what
// does this car need", and the second one is the one nobody updates — the
// artboards draw the identical string in both screens, so the app has to
// compute it once.
//
// `vehicles` puts it on the third line, under the make and model.
// `vehicle.switcher` puts it on the second, because a sheet has no room for a
// line that only tells two silver hatchbacks apart.
import 'package:flutter/material.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/due/vehicle_due_snapshot.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/l10n/relative_past.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/estimate_rounding.dart';
import 'package:odova/core/vehicles/garage_status.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';

/// What joins the facts on a vehicle row.
///
/// A middle dot with a space either side, as the artboards draw it. Not a
/// translated string: it is punctuation between isolated runs, and a locale
/// that wanted a different mark would want a different LINE, not a different
/// glyph in the same one.
const kFactSeparator = ' · ';

/// `~187,400 km · Odometer last updated 4 months ago`, or the status alone.
///
/// Three SPEC.md rules meet on this line and each one is a way of not lying.
/// A PROJECTED figure is prefixed `~` and rounded to the nearest 100 km /
/// 50 mi (§1.4), so it cannot read like a measurement. An EXPIRED one is the
/// entered reading, exact and unrounded with its own date, because rounding a
/// fact would make it look like an estimate — the opposite error, same rule.
/// And the age is bucketed rather than counted (§5): "4 months ago", never
/// the 122 days that would look like precision about a guess.
String vehicleOdometerAndStatus({
  required AppLocalizations l10n,
  required String tag,
  required Vehicle vehicle,
  required VehicleDueSnapshot? snapshot,
  required GarageStatus status,
  required DistanceUnit globalUnit,
}) {
  final estimate = snapshot?.estimate;
  final words = switch (estimate?.projection) {
    // SOLD outranks both odometer branches below, the same way `garageStatusOf`
    // checks sold before it computes anything. A car nobody drives has a stale
    // odometer by definition, so "Odometer last updated 8 months ago" on one is
    // true and beside the point — and it displaced the em dash on every sold
    // row in the switcher, which is to say on all of them.
    _ when status == GarageStatus.sold => _statusLine(
      l10n,
      tag,
      status,
      null,
      null,
    ),
    // Past 180 days Odova stops guessing and quotes the reading's own date.
    OdometerProjection.expired => l10n.vehicleOdometerLastEntered(
      formatLongDate(estimate!.asOf.toString(), tag),
    ),
    _ when (estimate?.staleDays ?? 0) > kStaleOdometerDays =>
      l10n.vehicleOdometerStale(formatDaysAgo(l10n, tag, estimate!.staleDays)),
    _ => _statusLine(
      l10n,
      tag,
      status,
      snapshot?.summary.worstItem,
      snapshot?.summary.worst?.remainingDays,
    ),
  };
  if (estimate == null) return words;

  final projected = estimate.projection == OdometerProjection.projected;
  // The vehicle's own override, then the GLOBAL — never a constant. SPEC.md
  // §8's switcher exists to show "each vehicle's odometer in that vehicle's own
  // `distance_unit`, not the active one's", and a hard-coded `km` here made a
  // miles user's un-overridden vehicle read in kilometres on the one screen
  // whose whole point is the unit.
  final unit = vehicle.distanceUnit ?? globalUnit;
  final shown = projected
      ? roundEstimateForDisplay(Distance(estimate.metres), unit)
      : Distance(estimate.metres);
  // Through `formatDistanceFigure`, which is the one place the estimate mark
  // is applied. This used to concatenate `'~'` in Dart — same rendering in
  // English, but it took the mark's SIDE away from the translator, and
  // `check_status_encoding.sh` greps for a spelling this one did not use.
  final figure = formatDistanceFigure(
    l10n,
    tag,
    shown,
    unit,
    estimated: projected,
  );
  return '$figure$kFactSeparator$words';
}

/// "4 months ago", bucketed and SHAPED.
///
/// Public because `vehicle.edit`'s odometer row says the same thing about the
/// same reading, and its own copy forced `'en'` with Latin numerals — so one
/// reading read "۴ ماه پیش" in the garage and "4 months ago" one tap away.
/// SPEC.md §5 has one numbering system active app-wide.
String formatDaysAgo(AppLocalizations l10n, String tag, int staleDays) {
  final past = bucketDaysAgo(staleDays);
  String n() => formatForDisplay(
    past.count,
    tag,
    numerals: CalmNumerals.auto,
    decimalDigits: 0,
  );
  return switch (past.bucket) {
    PastDateBucket.today => l10n.dateToday,
    PastDateBucket.yesterday => l10n.dateYesterday,
    PastDateBucket.daysAgo => l10n.dateDaysAgo(past.count, n()),
    PastDateBucket.aboutWeeksAgo => l10n.dateAboutWeeksAgo(past.count, n()),
    PastDateBucket.aboutMonthsAgo => l10n.dateAboutMonthsAgo(past.count, n()),
  };
}

/// Which state the dot draws.
///
/// A sold vehicle takes `unknown`'s hollow ring: it is not OK and it is not
/// overdue, it is simply not being watched, and the hollow ring is the shape
/// Calm already uses for "no answer".

DueState vehicleDotState(GarageStatus status) => switch (status) {
  GarageStatus.overdue => DueState.overdue,
  GarageStatus.due || GarageStatus.dueInDays => DueState.due,
  GarageStatus.allGood => DueState.ok,
  GarageStatus.needsOdometer => DueState.needsOdometer,
  GarageStatus.noReminders ||
  GarageStatus.unknown ||
  GarageStatus.sold => DueState.unknown,
};

String _statusLine(
  AppLocalizations l10n,
  String tag,
  GarageStatus status,
  ServiceItem? worst,
  int? days,
) => switch (status) {
  // The em dash, alone.
  //
  // §8 says what the GARAGE's sold row reads — "Sold 12 March 2024 · 1,204
  // entries" — and says nothing about the switcher's, which is the only place
  // this line renders for a sold car. F-9.24 removed the sentence an earlier
  // version of this comment quoted, so the choice is ours and it is written
  // down: the switcher's line is "odometer · status", and for a car that
  // computes nothing the status IS nothing. An em dash says that. Repeating
  // the sale date here would do the garage's job on the screen whose only
  // purpose is switching, and it would say it twice to anyone who opens both.
  GarageStatus.sold => '—',
  GarageStatus.allGood => l10n.vehicleStatusAllGood,
  GarageStatus.noReminders => l10n.vehicleStatusNoReminders,
  GarageStatus.needsOdometer => l10n.vehicleStatusNeedsOdometer,
  GarageStatus.unknown => l10n.vehicleStatusUnknown,
  // A CUSTOM item carries its own label; a catalogue one's name is among the
  // 28 kind strings EPIC-10 owns. Until those exist the sentence takes a
  // generic noun rather than the state's own "Couldn't work out what's due",
  // which paired a red dot with an admission of ignorance — two
  // contradictory statements about the same row. Something tracked really is
  // overdue; only its name is missing, and a generic noun says exactly that
  // much and no more.
  GarageStatus.overdue => l10n.vehicleStatusOverdue(
    worst?.label ?? l10n.vehicleStatusItemGeneric,
  ),
  // Named, and no number — the engine gave none and this line invents nothing.
  GarageStatus.due => l10n.vehicleStatusDue(
    worst?.label ?? l10n.vehicleStatusItemGeneric,
  ),
  GarageStatus.dueInDays => l10n.vehicleStatusDueInDays(
    days ?? 0,
    worst?.label ?? l10n.vehicleStatusItemGeneric,
    // Through `formatForDisplay`, never `'\$days'`. SPEC.md §5: one numbering
    // system app-wide, and this count sits on the same LINE as the odometer —
    // "۱۸۷٬۴۱۲ کیلومتر · Service due in 3 days" is two systems in one sentence.
    formatForDisplay(
      days ?? 0,
      tag,
      numerals: CalmNumerals.auto,
      decimalDigits: 0,
    ),
  ),
};

/// The silhouette for a [VehicleType].
///
/// SPEC.md §8: "the avatar — a silhouette from `vehicle_type`". The TYPE, not
/// one car for everything: a motorbike drawn as a car is the app telling a
/// rider it does not know what they own, which is the same failure §8 names
/// about offering a motorbike a cabin filter.
///
/// Here rather than on either screen, because the garage and the switcher both
/// draw it and a motorbike that is a motorbike on one and a car on the other is
/// worse than being wrong twice.
///
/// `truck` takes the van's glyph — nearer its shape — and `other` the car's: a
/// vehicle of unknown type has no honest silhouette and still has to have one.
IconData vehicleSilhouette(VehicleType type) => switch (type) {
  VehicleType.car => Icons.directions_car_outlined,
  VehicleType.van => Icons.local_shipping_outlined,
  VehicleType.motorcycle => Icons.two_wheeler_outlined,
  VehicleType.truck => Icons.local_shipping_outlined,
  VehicleType.other => Icons.directions_car_outlined,
};
