// The vehicle, as everything above the data layer sees it.
//
// Value objects, not raw integers — `Distance purchaseOdometer`, not
// `int purchaseOdometerM`, and one `Money purchasePrice` rather than a minor
// amount beside a currency code that a caller could read without. See the
// header of `records.dart`: the columns are unchanged and the mappers are the
// only layer that knows both shapes.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
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
    this.purchaseOdometer,
    this.purchasePrice,
    this.soldOn,
    this.soldPrice,
    this.expectedAnnual,
    this.colour,
    this.notes,
    this.sortOrder = 0,
    this.notificationsMuted = false,
    this.currency,
    this.distanceUnit,
    this.volumeUnit,
    this.consumptionUnit,
    this.noticeDistance,
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

  /// The odometer at purchase.
  final Distance? purchaseOdometer;

  /// What it cost.
  final Money? purchasePrice;

  /// Where it is in its life with the user.
  final VehicleStatus status;

  /// When it was sold, `YYYY-MM-DD`.
  final String? soldOn;

  /// What it sold for.
  final Money? soldPrice;

  /// Expected annual distance. Feeds the rate fallback.
  final Distance? expectedAnnual;

  /// A swatch key.
  final String? colour;

  /// Free text.
  final String? notes;

  /// Where it sits in the garage list.
  final int sortOrder;

  /// Whether this vehicle's reminders are silenced.
  final bool notificationsMuted;

  /// Overrides `Settings.currencyDefault`. **Null means inherit.**
  final Currency? currency;

  /// Overrides `Settings.distanceUnit`. Null means inherit.
  final DistanceUnit? distanceUnit;

  /// Overrides `Settings.volumeUnit`. Null means inherit.
  final VolumeUnit? volumeUnit;

  /// Overrides `Settings.consumptionUnit`. Null means inherit.
  final ConsumptionUnit? consumptionUnit;

  /// Overrides the computed distance notice window.
  final Distance? noticeDistance;

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
    purchaseOdometer,
    purchasePrice,
    status,
    soldOn,
    soldPrice,
    expectedAnnual,
    colour,
    notes,
    sortOrder,
    notificationsMuted,
    currency,
    distanceUnit,
    volumeUnit,
    consumptionUnit,
    noticeDistance,
    noticeDays,
    createdAtUtcMs,
    updatedAtUtcMs,
  ];

  @override
  String toString() => 'Vehicle($id, $name)';
}
