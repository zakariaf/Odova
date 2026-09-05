// Domain enums, in the user's language.
//
// Neither a feature nor `lib/core/`. `first_run` and `vehicles` both name a
// fuel kind and a vehicle type, and `test/policy/structure_test.dart` is
// explicit that "two features share code by lifting it down to core/ or data/,
// or they meet via a route — never by importing each other". `lib/core/` cannot
// hold these: they take `AppLocalizations`, which is generated Flutter code and
// core is Flutter-free.
//
// So they live beside the other l10n helpers, which is what they are — a table
// from a domain value to an ARB key, with no logic in between. Three copies of
// the fuel switch and two of the type switch shipped in EPIC-09 before this
// file existed.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/unit_format.dart';

/// What a [FuelKind] is called.
String vehicleFuelLabel(AppLocalizations l10n, FuelKind kind) => switch (kind) {
  FuelKind.petrol => l10n.fuelPetrol,
  FuelKind.diesel => l10n.fuelDiesel,
  FuelKind.electric => l10n.fuelElectric,
  FuelKind.lpg => l10n.fuelLpg,
  FuelKind.cng => l10n.fuelCng,
  FuelKind.hybrid => l10n.fuelHybrid,
  FuelKind.other => l10n.fuelOther,
};

/// What a [VehicleType] is called.
///
/// `truck` reads as a van and an unknown type as a car — the same pairing
/// `vehicleSilhouette` draws, so the word and the picture never disagree.
/// SPEC.md §8 offers only three tiles on first run and the full set on
/// `vehicle.edit`, which is why one table serves both.
String vehicleTypeLabel(AppLocalizations l10n, VehicleType type) =>
    switch (type) {
      VehicleType.van || VehicleType.truck => l10n.vehicleTypeVan,
      VehicleType.motorcycle => l10n.vehicleTypeMotorcycle,
      VehicleType.other => l10n.vehicleTypeOther,
      VehicleType.car => l10n.vehicleTypeCar,
    };

/// `km` or `mi`.
///
/// A one-line ternary that was written FIVE times: SPEC.md §5 gives the app
/// two distance units and every screen that shows a distance needs the word.
/// `firstrun.vehicle` and `vehicle.edit` each grew a private `_unitLabel`
/// after this existed, which is what a shared helper looks like when nobody
/// greps for it first.
String distanceUnitLabel(AppLocalizations l10n, DistanceUnit unit) =>
    unit == DistanceUnit.mi ? l10n.unitDistanceMi : l10n.unitDistanceKm;

/// A distance with its unit, marked `~` when it is an estimate.
///
/// **The one place the estimate mark is applied.** SPEC.md §1 forbids guessing
/// in a way that looks like fact, and §9 puts the mark "inside the isolated
/// numeric run so it hugs the number in both directions" — three rules that
/// have to be got right together and were being got right twice, separately:
///
///   * The mark goes INSIDE the isolate. Prefixing `~` to an already-isolated
///     string puts it in front of the FSI, where Arabic renders it at the far
///     end of the line. That version reads correctly in English, which is how
///     it survives review.
///   * The mark comes from an ARB key, not from a Dart `'~'`. Which SIDE of the
///     figure it sits on is a translation decision, and a concatenation takes
///     it away from the translator.
///   * The number and the unit share ONE isolate, so `۱۸۷٬۴۱۲ کیلومتر` never
///     splits.
///
/// `check_status_encoding.sh` greps for a Dart-side `'~'`, so the second rule
/// is gated — but only for the spelling it knows. One function is what makes
/// the gate's coverage total rather than approximate.
String formatDistanceFigure(
  AppLocalizations l10n,
  String formatsTag,
  Distance distance,
  DistanceUnit unit, {
  required bool estimated,
}) {
  final body = withUnitUnisolated(
    distance.inUnit(unit),
    distanceUnitLabel(l10n, unit),
    formatsTag,
    numerals: CalmNumerals.auto,
    decimalDigits: 0,
  );
  return isolate(estimated ? l10n.commonEstimatedValue(body) : body);
}

/// The unit a vehicle's distances are shown in.
///
/// The VEHICLE's override where it has one, then the app's setting, then
/// kilometres — SPEC.md §5's precedence, written out at four new call sites in
/// EPIC-10 alone before it was one function. A car set to miles that reads in
/// kilometres on one screen is the bug this prevents, and it is the kind that
/// ships because each site is obviously correct on its own.
DistanceUnit effectiveDistanceUnit(Vehicle? vehicle, AppSettings? settings) =>
    vehicle?.distanceUnit ?? settings?.distanceUnit ?? DistanceUnit.km;
