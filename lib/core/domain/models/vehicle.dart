// The vehicle, as everything above the data layer sees it.
//
// Canonical integers with the unit in the NAME — `purchaseOdometerM`, not
// `purchaseOdometer`. EPIC-06 swaps these for `Distance` and `Money` value
// objects at the repository boundary in one pass; until then the name is what
// stops a metre being added to a mile, and it is the only thing that does.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/value_equality.dart';

/// A vehicle.
class Vehicle with ValueEquality {
  /// Creates a vehicle.
  const Vehicle({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.fuelKindDefault,
    required this.status,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    this.make,
    this.model,
    this.year,
    this.plate,
    this.vin,
    this.isBusiness = false,
    this.tankCapacityMl,
    this.purchaseDate,
    this.purchaseOdometerM,
    this.purchasePriceMinor,
    this.purchasePriceCurrency,
    this.soldOn,
    this.soldPriceMinor,
    this.soldPriceCurrency,
    this.expectedAnnualM,
    this.colour,
    this.notes,
    this.sortOrder = 0,
    this.notificationsMuted = false,
    this.currency,
    this.distanceUnit,
    this.volumeUnit,
    this.consumptionUnit,
    this.noticeDistanceM,
    this.noticeDays,
  });

  /// `veh_<ULID>`.
  final VehicleId id;

  /// What the user calls it.
  final String name;

  /// Manufacturer.
  final String? make;

  /// Model.
  final String? model;

  /// Model year.
  final int? year;

  /// Registration plate, verbatim as typed.
  final String? plate;

  /// Vehicle identification number.
  final String? vin;

  /// Drives the icon and which catalogue items seed.
  final VehicleType vehicleType;

  /// Drives the business/personal cost split.
  final bool isBusiness;

  /// What it burns.
  final FuelKind fuelKindDefault;

  /// Tank size in millilitres. A sanity check, never used in maths.
  final int? tankCapacityMl;

  /// When it was bought, `YYYY-MM-DD`.
  final String? purchaseDate;

  /// The odometer at purchase, in metres.
  final int? purchaseOdometerM;

  /// What it cost, in minor units.
  final int? purchasePriceMinor;

  /// The currency of [purchasePriceMinor].
  final String? purchasePriceCurrency;

  /// Where it is in its life with the user.
  final VehicleStatus status;

  /// When it was sold, `YYYY-MM-DD`.
  final String? soldOn;

  /// What it sold for, in minor units.
  final int? soldPriceMinor;

  /// The currency of [soldPriceMinor].
  final String? soldPriceCurrency;

  /// Expected annual distance in metres. Feeds the rate fallback.
  final int? expectedAnnualM;

  /// A swatch key.
  final String? colour;

  /// Free text.
  final String? notes;

  /// Where it sits in the garage list.
  final int sortOrder;

  /// Whether this vehicle's reminders are silenced.
  final bool notificationsMuted;

  /// Overrides `Settings.currencyDefault`. **Null means inherit.**
  final String? currency;

  /// Overrides `Settings.distanceUnit`. Null means inherit.
  final DistanceUnit? distanceUnit;

  /// Overrides `Settings.volumeUnit`. Null means inherit.
  final VolumeUnit? volumeUnit;

  /// Overrides `Settings.consumptionUnit`. Null means inherit.
  final ConsumptionUnit? consumptionUnit;

  /// Overrides the computed distance notice window, in metres.
  final int? noticeDistanceM;

  /// Overrides the computed time notice window, in days.
  final int? noticeDays;

  /// When the row was written. UTC epoch milliseconds.
  final int createdAtUtcMs;

  /// When it was last changed. UTC epoch milliseconds.
  final int updatedAtUtcMs;

  @override
  List<Object?> get props => [
    id,
    name,
    make,
    model,
    year,
    plate,
    vin,
    vehicleType,
    isBusiness,
    fuelKindDefault,
    tankCapacityMl,
    purchaseDate,
    purchaseOdometerM,
    purchasePriceMinor,
    purchasePriceCurrency,
    status,
    soldOn,
    soldPriceMinor,
    soldPriceCurrency,
    expectedAnnualM,
    colour,
    notes,
    sortOrder,
    notificationsMuted,
    currency,
    distanceUnit,
    volumeUnit,
    consumptionUnit,
    noticeDistanceM,
    noticeDays,
    createdAtUtcMs,
    updatedAtUtcMs,
  ];

  @override
  String toString() => 'Vehicle($id, $name)';
}
