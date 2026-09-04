// SPEC.md §3's enums, spelled exactly as the spec spells them.
//
// "These spellings are canonical everywhere: database, export, CSV headers,
// notification payloads." So the wire value is the contract, and the Dart name
// is free to be idiomatic — `lPer100km` in code, `l_100km` on the wire. A
// renamed wire value is a backup file that no longer imports.
//
// Flutter-free, in lib/core/, because the due engine and the fuel maths switch
// on these and neither has a BuildContext.
//
// `DistanceUnit`, `VolumeUnit` and `ConsumptionUnit` are NOT declared here.
// They belong with the quantities they measure — a unit and its conversions are
// one idea — so they live in `lib/core/units/` and are re-exported from here,
// which keeps this file the single import for a domain enum while there is one
// definition of each. Declaring them twice compiled until the day a file needed
// both, and then every reference was ambiguous.
export 'package:odova/core/units/consumption.dart' show ConsumptionUnit;
export 'package:odova/core/units/distance.dart' show DistanceUnit;
export 'package:odova/core/units/volume.dart' show VolumeUnit;

/// What a vehicle burns.
///
/// Decides which of a fill-up's three quantity columns is the non-null one:
/// millilitres for a liquid, grams for CNG, watt-hours for electricity.
enum FuelKind {
  /// Petrol / gasoline.
  petrol('petrol'),

  /// Diesel.
  diesel('diesel'),

  /// Liquefied petroleum gas.
  lpg('lpg'),

  /// Compressed natural gas — sold by MASS, hence `quantity_g`.
  cng('cng'),

  /// Electric — sold by ENERGY, hence `energy_wh`.
  electric('electric'),

  /// Hybrid.
  hybrid('hybrid'),

  /// Anything else.
  other('other');

  const FuelKind(this.wire);

  /// The value as stored and exported.
  final String wire;
}

/// What kind of vehicle. Drives the icon and which catalogue items seed.
enum VehicleType {
  /// A car.
  car('car'),

  /// A van.
  van('van'),

  /// A motorcycle.
  motorcycle('motorcycle'),

  /// A truck.
  truck('truck'),

  /// Anything else.
  other('other');

  const VehicleType(this.wire);

  /// The value as stored and exported.
  final String wire;
}

/// Where a vehicle is in its life with the user.
enum VehicleStatus {
  /// In use.
  active('active'),

  /// Kept, but not driven — off the home screen and off notifications.
  archived('archived'),

  /// Gone. History is kept, because it is what the next owner asks for.
  sold('sold');

  const VehicleStatus(this.wire);

  /// The value as stored and exported.
  final String wire;
}

/// How urgent a service item is when several are due at once.
enum ServicePriority {
  /// Brakes, tyres, timing belt. Sorts above everything.
  safety('safety'),

  /// The default.
  normal('normal'),

  /// Wipers, wash. Sorts last.
  low('low');

  const ServicePriority(this.wire);

  /// The value as stored and exported.
  final String wire;
}

/// What the next due date is measured FROM when an item completes late.
enum ServiceRollover {
  /// From the day it was actually done. The default, and what most people
  /// mean: an oil change done 2,000 km late resets the clock from there.
  fromActual('from_actual'),

  /// From the day it was due. For anything on a fixed calendar — an
  /// inspection due every April stays in April however late it was done.
  fromDue('from_due');

  const ServiceRollover(this.wire);

  /// The value as stored and exported.
  final String wire;
}

/// What a paid expense was for. Ten values, no more (SPEC.md §3 Enums).
enum ExpenseCategory {
  /// Insurance premium.
  insurance('insurance'),

  /// Tax or registration.
  taxRegistration('tax_registration'),

  /// Parking.
  parking('parking'),

  /// Road toll.
  toll('toll'),

  /// A fine.
  fine('fine'),

  /// A wash.
  wash('wash'),

  /// Seasonal tyre storage.
  tyreStorage('tyre_storage'),

  /// Accessories.
  accessories('accessories'),

  /// A finance or lease payment.
  finance('finance'),

  /// Anything else. Requires a label.
  other('other');

  const ExpenseCategory(this.wire);

  /// The value as stored and exported.
  final String wire;
}

/// Why a trip was taken. Drives the business/personal cost split.
enum TripPurpose {
  /// Business.
  business('business'),

  /// Commuting.
  commute('commute'),

  /// Personal.
  personal('personal'),

  /// Anything else.
  other('other');

  const TripPurpose(this.wire);

  /// The value as stored and exported.
  final String wire;
}

/// Which record produced an odometer reading.
///
/// Every record carrying an odometer emits one, so ONE table computes distance
/// history and enforces monotonicity. A derived reading follows its parent and
/// is not directly editable.
enum OdometerSource {
  /// Typed straight into the odometer log.
  manual('manual'),

  /// Emitted by a fill-up.
  fillUp('fillup'),

  /// Emitted by a service record.
  service('service'),

  /// Emitted by an expense.
  expense('expense'),

  /// Emitted by a trip's start.
  tripStart('trip_start'),

  /// Emitted by a trip's end.
  tripEnd('trip_end'),

  /// Came in with a backup file.
  import('import');

  const OdometerSource(this.wire);

  /// The value as stored and exported.
  final String wire;
}

/// Why the dash number jumped. Three reasons, not four.
///
/// SPEC.md contradicted itself here: §3's enum listed a fourth, `unit_mixup`,
/// and §14 *Edge cases* said "unit_mixup is removed as a correction reason".
/// §14 is right and is the narrower, explicitly-decided statement — storage is
/// canonical metres and the odometer unit is a per-record fact, so a km
/// cluster fitted to a miles car needs no offset at all: the reading is
/// entered in the unit the new cluster shows and the conversion happens on
/// the way in. The `CHECK` was NOT widened to admit both; §3 was fixed in the
/// same PR that added this table.
enum OdometerCorrectionReason {
  /// A new instrument cluster showing a different number.
  clusterReplaced('cluster_replaced'),

  /// The counter wrapped past 999,999.
  rollover('rollover'),

  /// A digit was entered wrong and the correction is bookkeeping.
  typoFix('typo_fix');

  const OdometerCorrectionReason(this.wire);

  /// The value as stored and exported.
  final String wire;
}

/// The catalogue of things that come due. 28 values.
///
/// Registration and insurance are SERVICE ITEMS and not expenses, because the
/// user thinks of them as things that come due; paying one is a separate
/// `Expense` row.
enum ServiceKind {
  /// Oil and filter.
  oilAndFilter('oil_and_filter'),

  /// Engine air filter.
  airFilter('air_filter'),

  /// Cabin filter.
  cabinFilter('cabin_filter'),

  /// Fuel filter.
  fuelFilter('fuel_filter'),

  /// Spark plugs.
  sparkPlugs('spark_plugs'),

  /// Timing belt.
  timingBelt('timing_belt'),

  /// A brake pad inspection.
  brakePadsCheck('brake_pads_check'),

  /// Front brake pads.
  brakePadsFront('brake_pads_front'),

  /// Rear brake pads.
  brakePadsRear('brake_pads_rear'),

  /// Brake fluid.
  brakeFluid('brake_fluid'),

  /// Coolant.
  coolant('coolant'),

  /// Transmission fluid.
  transmissionFluid('transmission_fluid'),

  /// Wheel alignment.
  wheelAlignment('wheel_alignment'),

  /// Tyre rotation.
  tyreRotate('tyre_rotate'),

  /// Tyre replacement.
  tyreReplace('tyre_replace'),

  /// Battery.
  battery('battery'),

  /// Wipers.
  wipers('wipers'),

  /// Roadworthiness inspection.
  inspection('inspection'),

  /// Registration renewal.
  registration('registration'),

  /// Insurance renewal.
  insuranceRenewal('insurance_renewal'),

  /// Air-conditioning service.
  acService('ac_service'),

  /// Chain lubrication — motorcycle.
  chainLube('chain_lube'),

  /// Chain and sprockets — motorcycle.
  chainAndSprockets('chain_and_sprockets'),

  /// Valve clearance — motorcycle.
  valveClearance('valve_clearance'),

  /// Fork oil — motorcycle.
  forkOil('fork_oil'),

  /// Reduction gearbox oil — electric.
  reductionGearboxOil('reduction_gearbox_oil'),

  /// The 12 V auxiliary battery — electric.
  battery12v('battery_12v'),

  /// Anything the user names. Requires a label.
  custom('custom');

  const ServiceKind(this.wire);

  /// The value as stored and exported.
  final String wire;
}
