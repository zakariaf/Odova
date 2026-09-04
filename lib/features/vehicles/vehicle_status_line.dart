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
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/due/vehicle_due_snapshot.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/l10n/relative_past.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/estimate_rounding.dart';
import 'package:odova/features/vehicles/garage_status.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';

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
    // Past 180 days Odova stops guessing and quotes the reading's own date.
    OdometerProjection.expired => l10n.vehicleOdometerLastEntered(
      formatLongDate(estimate!.asOf.toString(), tag),
    ),
    _ when (estimate?.staleDays ?? 0) > kStaleOdometerDays =>
      l10n.vehicleOdometerStale(_age(l10n, tag, estimate!.staleDays)),
    _ => _statusLine(
      l10n,
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
  final digits = formatForDisplay(
    shown.inUnit(unit),
    tag,
    numerals: CalmNumerals.auto,
    decimalDigits: 0,
  );
  final label = unit == DistanceUnit.mi
      ? l10n.unitDistanceMi
      : l10n.unitDistanceKm;
  // ONE isolate around marker, number and unit together — not
  // `formatWithUnit` with a `~` isolated on top of it, which nests two and
  // says nothing the outer one does not. SPEC.md §8's RTL note makes the run
  // atomic: `۱۸۷٬۴۱۲ کیلومتر` never splits, and the marker is `~` in every
  // locale (§1.4) sitting on the figure's leading edge in both directions.
  final figure = isolate('${projected ? '~' : ''}$digits $label');
  return '$figure$kFactSeparator$words';
}

/// "4 months ago", bucketed.
String _age(AppLocalizations l10n, String tag, int staleDays) {
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

/// What a [FuelKind] is called on a vehicle row.
String vehicleFuelLabel(AppLocalizations l10n, FuelKind kind) => switch (kind) {
  FuelKind.petrol => l10n.fuelPetrol,
  FuelKind.diesel => l10n.fuelDiesel,
  FuelKind.electric => l10n.fuelElectric,
  FuelKind.lpg => l10n.fuelLpg,
  FuelKind.cng => l10n.fuelCng,
  FuelKind.hybrid => l10n.fuelHybrid,
  FuelKind.other => l10n.fuelOther,
};

/// Which state the dot draws.
///
/// A sold vehicle takes `unknown`'s hollow ring: it is not OK and it is not
/// overdue, it is simply not being watched, and the hollow ring is the shape
/// Calm already uses for "no answer".

DueState vehicleDotState(GarageStatus status) => switch (status) {
  GarageStatus.overdue => DueState.overdue,
  GarageStatus.dueInDays => DueState.due,
  GarageStatus.allGood => DueState.ok,
  GarageStatus.needsOdometer => DueState.needsOdometer,
  GarageStatus.noReminders ||
  GarageStatus.unknown ||
  GarageStatus.sold => DueState.unknown,
};

String _statusLine(
  AppLocalizations l10n,
  GarageStatus status,
  ServiceItem? worst,
  int? days,
) => switch (status) {
  // The em dash, alone. §8: "a sold vehicle computes no reminders and its
  // card shows —".
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
  GarageStatus.dueInDays => l10n.vehicleStatusDueInDays(
    days ?? 0,
    worst?.label ?? l10n.vehicleStatusItemGeneric,
    '${days ?? 0}',
  ),
};
