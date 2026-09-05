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
import 'package:odova/l10n/gen/app_localizations.dart';

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
