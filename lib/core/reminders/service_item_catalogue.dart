// What a new vehicle arrives with.
//
// SPEC.md §4.8, transcribed. Round numbers approximately right for a lot of
// cars, which is a different claim from manufacturer advice —
// `reminders.list` says so in its header and this file must never imply
// otherwise.
//
// **A seed, not a live reference.** `VehicleRepository.create` copies the
// result into real `ServiceItem` rows and nothing reads this table again. So
// changing a number here changes what the NEXT vehicle is created with and
// never touches a vehicle that already exists — which is the only way an app
// update can be safe to ship: a user who corrected their oil interval to their
// handbook's 15,000 km does not get it silently moved back.
//
// Pure Dart, no Flutter import: `dart test` runs it headlessly in milliseconds.

import 'package:meta/meta.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/units/distance.dart';

/// One row of the catalogue, ready to become a `ServiceItem`.
@immutable
class ServiceItemSeed {
  /// Creates a seed.
  const ServiceItemSeed({
    required this.kind,
    required this.isTracked,
    required this.priority,
    this.intervalDistanceM,
    this.intervalMonths,
    this.rollover = ServiceRollover.fromActual,
  });

  /// Which job this is.
  final ServiceKind kind;

  /// Whether the due engine can see it.
  ///
  /// False is SPEC.md §4.8.2's "seeded off": the row exists, reads greyed on
  /// `reminders.list`, and is invisible until the user enables it. Created
  /// rather than omitted because a timing belt is the most expensive thing to
  /// miss, and a disabled row with an honest note gets a user to look it up —
  /// while enabling it on a chain-driven car would teach them the app makes
  /// things up.
  final bool isTracked;

  /// How urgent it reads on Home.
  final ServicePriority priority;

  /// Metres between services, or null when the job is a date.
  final int? intervalDistanceM;

  /// Months between services, or null when the job is a distance.
  final int? intervalMonths;

  /// Whether the next due date is measured from the DUE date or the actual one.
  ///
  /// An inspection due in March that is done in April is next due the following
  /// MARCH: the schedule belongs to the authority, not to when the user got
  /// round to it. Everything else rolls from what actually happened.
  final ServiceRollover rollover;

  /// The label, which is always null for a seed.
  ///
  /// Rendered FROM [kind], so a vehicle seeded in English reads correctly in
  /// all six languages with no migration. A stored English string would need
  /// one.
  String? get label => null;

  /// This seed with [intervalDistanceM] and [intervalMonths] replaced.
  ServiceItemSeed copyWith({
    bool? isTracked,
    int? intervalDistanceM,
    int? intervalMonths,
  }) => ServiceItemSeed(
    kind: kind,
    isTracked: isTracked ?? this.isTracked,
    priority: priority,
    intervalDistanceM: intervalDistanceM ?? this.intervalDistanceM,
    intervalMonths: intervalMonths ?? this.intervalMonths,
    rollover: rollover,
  );
}

/// A distance interval, stated in BOTH unit systems.
///
/// SPEC.md §4.8: "Defaults are defined per unit system, not converted — a miles
/// user gets 6,000 mi, not 9,656 km rendered as 6,000." So the table carries
/// the two round numbers and `seedFor` picks one; deriving the second by
/// conversion is what produces an oil change every 6,213.7 miles, which reads
/// as a machine talking.
@immutable
class _Interval {
  const _Interval(this.km, this.mi);

  final int km;
  final int mi;

  int metresFor(DistanceUnit unit) =>
      unit == DistanceUnit.mi ? _milesToMetres(mi) : km * 1000;
}

/// Miles to metres, exactly.
///
/// 1609.344 m is the international mile by definition, and the multiplication
/// is integer so the stored value is exact rather than a rounded double.
int _milesToMetres(int miles) => Distance.fromMiles(miles).metres;

/// §4.8.1 and §4.8.2: the car set, which `truck` and `other` take unchanged.
const _carSet =
    <ServiceKind, (_Interval?, int?, bool, ServicePriority, ServiceRollover)>{
      // Kind: (distance, months, tracked, priority, rollover)
      ServiceKind.oilAndFilter: (
        _Interval(10000, 6000),
        12,
        true,
        ServicePriority.safety,
        ServiceRollover.fromActual,
      ),
      ServiceKind.brakePadsCheck: (
        _Interval(20000, 12000),
        12,
        true,
        ServicePriority.safety,
        ServiceRollover.fromActual,
      ),
      ServiceKind.tyreReplace: (
        _Interval(50000, 30000),
        72,
        true,
        ServicePriority.safety,
        ServiceRollover.fromActual,
      ),
      ServiceKind.airFilter: (
        _Interval(20000, 12000),
        24,
        true,
        ServicePriority.normal,
        ServiceRollover.fromActual,
      ),
      ServiceKind.coolant: (
        _Interval(60000, 36000),
        48,
        true,
        ServicePriority.normal,
        ServiceRollover.fromActual,
      ),
      ServiceKind.inspection: (
        null,
        12,
        true,
        ServicePriority.safety,
        ServiceRollover.fromDue,
      ),
      ServiceKind.insuranceRenewal: (
        null,
        12,
        true,
        ServicePriority.normal,
        ServiceRollover.fromDue,
      ),
      ServiceKind.timingBelt: (
        _Interval(100000, 60000),
        96,
        false,
        ServicePriority.safety,
        ServiceRollover.fromActual,
      ),
      ServiceKind.tyreRotate: (
        _Interval(10000, 6000),
        12,
        false,
        ServicePriority.normal,
        ServiceRollover.fromActual,
      ),
      ServiceKind.cabinFilter: (
        _Interval(20000, 12000),
        12,
        false,
        ServicePriority.low,
        ServiceRollover.fromActual,
      ),
      ServiceKind.brakeFluid: (
        _Interval(60000, 36000),
        24,
        false,
        ServicePriority.safety,
        ServiceRollover.fromActual,
      ),
      ServiceKind.sparkPlugs: (
        _Interval(40000, 24000),
        48,
        false,
        ServicePriority.normal,
        ServiceRollover.fromActual,
      ),
      ServiceKind.transmissionFluid: (
        _Interval(60000, 36000),
        60,
        false,
        ServicePriority.normal,
        ServiceRollover.fromActual,
      ),
      ServiceKind.battery: (
        null,
        48,
        false,
        ServicePriority.normal,
        ServiceRollover.fromActual,
      ),
      ServiceKind.wipers: (
        null,
        12,
        false,
        ServicePriority.low,
        ServiceRollover.fromActual,
      ),
      ServiceKind.registration: (
        null,
        12,
        false,
        ServicePriority.normal,
        ServiceRollover.fromDue,
      ),
    };

/// §4.8.3's motorcycle additions.
const _motorcycleExtras =
    <ServiceKind, (_Interval?, int?, bool, ServicePriority)>{
      ServiceKind.chainLube: (
        _Interval(800, 500),
        null,
        true,
        ServicePriority.low,
      ),
      ServiceKind.chainAndSprockets: (
        _Interval(25000, 15000),
        null,
        false,
        ServicePriority.normal,
      ),
      ServiceKind.valveClearance: (
        _Interval(25000, 15000),
        null,
        false,
        ServicePriority.normal,
      ),
      ServiceKind.forkOil: (
        _Interval(30000, 18000),
        null,
        false,
        ServicePriority.normal,
      ),
    };

/// §4.8.3's electric additions.
const _electricExtras =
    <ServiceKind, (_Interval?, int?, bool, ServicePriority)>{
      ServiceKind.reductionGearboxOil: (
        _Interval(100000, 60000),
        null,
        false,
        ServicePriority.normal,
      ),
      ServiceKind.battery12v: (null, 48, false, ServicePriority.normal),
    };

/// The kinds §4.8.5 says are seeded on no vehicle at all.
///
/// They ship in the catalogue picker for every vehicle type, so a user can add
/// one in a tap — but a wrong default here is worse than no default, and
/// `fuel_filter` varies by an order of magnitude between petrol and diesel.
const neverSeeded = <ServiceKind>{
  ServiceKind.fuelFilter,
  ServiceKind.wheelAlignment,
  ServiceKind.acService,
  ServiceKind.brakePadsFront,
  ServiceKind.brakePadsRear,
  ServiceKind.custom,
};

/// The set a new vehicle is created with.
///
/// [liquidCooled] only affects a motorcycle: §4.8.3 seeds `coolant` on a
/// liquid-cooled one and never on an air-cooled one, and Odova stores no
/// cooling field — first run asks, and the answer travels here rather than
/// being guessed from the fuel kind.
List<ServiceItemSeed> seedFor({
  required VehicleType type,
  required FuelKind fuel,
  required bool isBusiness,
  required DistanceUnit unit,
  bool liquidCooled = false,
}) {
  final seeds = <ServiceKind, ServiceItemSeed>{};

  for (final entry in _carSet.entries) {
    final (interval, months, tracked, priority, rollover) = entry.value;
    seeds[entry.key] = ServiceItemSeed(
      kind: entry.key,
      isTracked: tracked,
      priority: priority,
      intervalDistanceM: interval?.metresFor(unit),
      intervalMonths: months,
      rollover: rollover,
    );
  }

  // The two filters COMPOSE, and in this order. §4.8.3: electric is a fuel
  // kind, not a vehicle type, so an electric motorcycle takes the motorcycle
  // deltas and then the electric ones — which is why the motorcycle pass drops
  // `battery_12v` and the electric pass must not add it back.
  if (type == VehicleType.motorcycle) {
    _applyMotorcycle(seeds, unit: unit, liquidCooled: liquidCooled);
  }
  if (type == VehicleType.van) {
    _applyVan(seeds, unit: unit);
  }
  if (fuel == FuelKind.electric) {
    _applyElectric(
      seeds,
      unit: unit,
      isMotorcycle: type == VehicleType.motorcycle,
    );
  }
  if (fuel != FuelKind.petrol &&
      fuel != FuelKind.lpg &&
      fuel != FuelKind.cng &&
      fuel != FuelKind.hybrid) {
    // §4.8.2: spark plugs are petrol, LPG, CNG and hybrid only. A diesel has
    // none, and a row for one is a row the user has to work out is irrelevant.
    seeds.remove(ServiceKind.sparkPlugs);
  }
  if (isBusiness) {
    _applyBusiness(seeds, unit: unit);
  }

  return seeds.values.toList();
}

void _applyMotorcycle(
  Map<ServiceKind, ServiceItemSeed> seeds, {
  required DistanceUnit unit,
  required bool liquidCooled,
}) {
  seeds[ServiceKind.oilAndFilter] = seeds[ServiceKind.oilAndFilter]!.copyWith(
    intervalDistanceM: const _Interval(6000, 3600).metresFor(unit),
  );
  const [
    ServiceKind.cabinFilter,
    ServiceKind.tyreRotate,
    ServiceKind.wipers,
    ServiceKind.transmissionFluid,
    ServiceKind.timingBelt,
    ServiceKind.battery,
    ServiceKind.battery12v,
  ].forEach(seeds.remove);
  if (!liquidCooled) seeds.remove(ServiceKind.coolant);

  for (final entry in _motorcycleExtras.entries) {
    final (interval, months, tracked, priority) = entry.value;
    seeds[entry.key] = ServiceItemSeed(
      kind: entry.key,
      isTracked: tracked,
      priority: priority,
      intervalDistanceM: interval?.metresFor(unit),
      intervalMonths: months,
    );
  }
}

void _applyVan(
  Map<ServiceKind, ServiceItemSeed> seeds, {
  required DistanceUnit unit,
}) {
  // Vans are usually diesel with a longer interval.
  seeds[ServiceKind.oilAndFilter] = seeds[ServiceKind.oilAndFilter]!.copyWith(
    intervalDistanceM: const _Interval(15000, 9000).metresFor(unit),
  );
  seeds[ServiceKind.tyreReplace] = seeds[ServiceKind.tyreReplace]!.copyWith(
    intervalDistanceM: const _Interval(40000, 24000).metresFor(unit),
  );
}

void _applyElectric(
  Map<ServiceKind, ServiceItemSeed> seeds, {
  required DistanceUnit unit,
  required bool isMotorcycle,
}) {
  // `battery` never joins `battery_12v`; it is REPLACED by it. On an electric
  // vehicle "the battery" otherwise reads as the traction pack, which Odova
  // does not track.
  const [
    ServiceKind.oilAndFilter,
    ServiceKind.airFilter,
    ServiceKind.sparkPlugs,
    ServiceKind.transmissionFluid,
    ServiceKind.timingBelt,
    ServiceKind.coolant,
    ServiceKind.battery,
  ].forEach(seeds.remove);

  for (final kind in [ServiceKind.brakeFluid, ServiceKind.cabinFilter]) {
    // Dropped by the motorcycle pass on an electric motorcycle; the electric
    // pass must not add it back.
    final existing = seeds[kind];
    if (existing == null) continue;
    seeds[kind] = existing.copyWith(isTracked: true);
  }

  for (final entry in _electricExtras.entries) {
    // `battery_12v` on an electric MOTORCYCLE: §4.8.3 says a motorcycle seeds
    // neither battery kind, and the motorcycle pass has already dropped it.
    if (isMotorcycle && entry.key == ServiceKind.battery12v) continue;
    final (interval, months, tracked, priority) = entry.value;
    seeds[entry.key] = ServiceItemSeed(
      kind: entry.key,
      isTracked: tracked,
      priority: priority,
      intervalDistanceM: interval?.metresFor(unit),
      intervalMonths: months,
    );
  }
}

void _applyBusiness(
  Map<ServiceKind, ServiceItemSeed> seeds, {
  required DistanceUnit unit,
}) {
  // §4.8.4: the shape of a severe-service schedule. The multipliers are this
  // product's judgement, not a manufacturer table, and §4.8's disclaimer covers
  // it.
  final oil = seeds[ServiceKind.oilAndFilter];
  if (oil != null) {
    seeds[ServiceKind.oilAndFilter] = oil.copyWith(
      intervalDistanceM: const _Interval(7500, 4500).metresFor(unit),
      intervalMonths: 6,
    );
  }
  final air = seeds[ServiceKind.airFilter];
  if (air != null) {
    seeds[ServiceKind.airFilter] = air.copyWith(
      intervalDistanceM: const _Interval(15000, 9000).metresFor(unit),
    );
  }
  final rotate = seeds[ServiceKind.tyreRotate];
  if (rotate != null) {
    seeds[ServiceKind.tyreRotate] = rotate.copyWith(isTracked: true);
  }
}
