// Every fact about one vehicle, while it is being edited.
//
// SPEC.md §8's `vehicle.edit`. A draft rather than a modified `Vehicle`, and
// the reason is one Dart cannot express well: a `copyWith` across twenty-odd
// nullable fields cannot say "clear the plate" — passing null means "leave it
// alone", so the one operation the user most obviously has (delete what is in
// the box) becomes the one the API refuses. The draft holds the editable fields
// outright and builds a `Vehicle` from them.
//
// The ODOMETER is not here. §8: "in create mode it is an input; in edit mode a
// row showing the latest reading and its age, tapping into `log.odometer`. A
// facts form is the wrong place to write a dated reading — someone correcting
// the plate would stamp today's date on a number they last checked in March,
// and that corrupts the series the whole app depends on."
//
// Pure Dart, no Flutter import.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/vehicles/vehicle_colour.dart';

/// The earliest model year the form accepts. SPEC.md §8.
const int kEarliestVehicleYear = 1900;

/// How many characters a VIN usually has. A NOTE, never a rule.
const int kVinLength = 17;

/// One vehicle's editable facts.
@immutable
class VehicleEditDraft {
  /// Creates a draft.
  const VehicleEditDraft({
    required this.original,
    required this.name,
    required this.vehicleType,
    required this.fuelKindDefault,
    this.make,
    this.model,
    this.year,
    this.plate,
    this.vin,
    this.colour,
    this.notes,
    this.isBusiness = false,
    this.notificationsMuted = false,
    this.purchaseDate,
    this.purchaseOdometer,
    this.purchasePrice,
    this.currency,
    this.distanceUnit,
    this.volumeUnit,
    this.consumptionUnit,
    this.noticeDistance,
    this.noticeDays,
  });

  /// A draft that starts as [vehicle] is.
  factory VehicleEditDraft.of(Vehicle vehicle) => VehicleEditDraft(
    original: vehicle,
    name: vehicle.name,
    vehicleType: vehicle.vehicleType,
    fuelKindDefault: vehicle.fuelKindDefault,
    make: vehicle.make,
    model: vehicle.model,
    year: vehicle.year,
    plate: vehicle.plate,
    vin: vehicle.vin,
    // An unrecognised stored value reads as NO selection rather than as the
    // nearest swatch — a backup from a future version must not repaint the car.
    colour: VehicleColour.tryParse(vehicle.colour),
    notes: vehicle.notes,
    isBusiness: vehicle.isBusiness,
    notificationsMuted: vehicle.notificationsMuted,
    purchaseDate: vehicle.purchaseDate,
    purchaseOdometer: vehicle.purchaseOdometer,
    purchasePrice: vehicle.purchasePrice,
    currency: vehicle.currency,
    distanceUnit: vehicle.distanceUnit,
    volumeUnit: vehicle.volumeUnit,
    consumptionUnit: vehicle.consumptionUnit,
    noticeDistance: vehicle.noticeDistance,
    noticeDays: vehicle.noticeDays,
  );

  /// A draft for a vehicle that does not exist yet — SPEC.md §8's create mode.
  ///
  /// [original] is a PROVISIONAL row, never written and never read back: it is
  /// what [isDirty] compares against, so an untouched create form is clean and
  /// its first ✕ dismisses silently rather than opening the discard dialog.
  /// The repository mints the real id, status and timestamps
  /// (`VehicleRepository.createVehicle` names the four it ignores), so the
  /// values here exist only to make a complete `Vehicle`.
  factory VehicleEditDraft.blank() {
    const provisional = Vehicle(
      id: kUnsavedVehicleId,
      name: '',
      vehicleType: VehicleType.car,
      fuelKindDefault: FuelKind.petrol,
      status: VehicleStatus.active,
      createdAtUtcMs: 0,
      updatedAtUtcMs: 0,
    );
    return VehicleEditDraft.of(provisional);
  }

  /// The row as it stands on disk. What [isDirty] compares against.
  final Vehicle original;

  /// What the user calls it. Required, and duplicates are allowed.
  final String name;

  /// Which of the four segments.
  final VehicleType vehicleType;

  /// What it burns.
  final FuelKind fuelKindDefault;

  /// Manufacturer.
  final String? make;

  /// Model.
  final String? model;

  /// Model year.
  final int? year;

  /// Registration plate, verbatim.
  final String? plate;

  /// Vehicle identification number.
  final String? vin;

  /// Which swatch, or none.
  final VehicleColour? colour;

  /// Free text.
  final String? notes;

  /// Whether it splits to the business side of the cost report.
  final bool isBusiness;

  /// Whether its reminders are silenced.
  final bool notificationsMuted;

  /// `YYYY-MM-DD`.
  final String? purchaseDate;

  /// The reading at purchase.
  ///
  /// A vehicle FACT and not an observation: it emits no odometer reading,
  /// because the series is a record of what was seen on a date, and "what it
  /// read when I bought it in 2019" is not something seen today.
  final Distance? purchaseOdometer;

  /// What it cost.
  final Money? purchasePrice;

  /// The six per-vehicle overrides. Null is **Automatic**, which is not the
  /// same as a value that happens to match the global — it is an instruction to
  /// keep following it.
  final Currency? currency;

  /// See [currency].
  final DistanceUnit? distanceUnit;

  /// See [currency].
  final VolumeUnit? volumeUnit;

  /// See [currency].
  final ConsumptionUnit? consumptionUnit;

  /// See [currency].
  final Distance? noticeDistance;

  /// See [currency].
  final int? noticeDays;

  /// Whether anything has changed since the form opened.
  ///
  /// Compared as `Vehicle`s rather than field by field, so a field added later
  /// is dirty-tracked the day it is added rather than the day somebody
  /// remembers to add it here. `Vehicle` carries `ValueEquality`.
  bool get isDirty => toVehicle(original.updatedAtUtcMs) != original;

  /// Whether Save may be pressed. The name is the only required field.
  bool get canSave => name.trim().isNotEmpty;

  /// Whether [year] is outside SPEC.md §8's range, given [currentYear].
  ///
  /// Takes the year rather than reading a clock: the upper bound is "next
  /// year's models are on sale this year", which is a fact about the calendar
  /// and therefore an argument.
  bool yearOutOfRange(int currentYear) =>
      year != null && (year! < kEarliestVehicleYear || year! > currentYear + 1);

  /// Whether the VIN is an unusual length. A NOTE, never a refusal.
  ///
  /// Some pre-1981 and non-road vehicles have shorter numbers, and refusing
  /// theirs would mean refusing the vehicle.
  bool get vinLengthUnusual =>
      vin != null && vin!.trim().isNotEmpty && vin!.trim().length != kVinLength;

  /// This draft as a row, stamped [nowUtcMs].
  Vehicle toVehicle(int nowUtcMs) => Vehicle(
    id: original.id,
    name: name.trim(),
    vehicleType: vehicleType,
    fuelKindDefault: fuelKindDefault,
    status: original.status,
    make: _blankToNull(make),
    model: _blankToNull(model),
    year: year,
    plate: _blankToNull(plate),
    vin: _blankToNull(vin),
    colour: colour?.wire,
    notes: _blankToNull(notes),
    isBusiness: isBusiness,
    notificationsMuted: notificationsMuted,
    purchaseDate: purchaseDate,
    purchaseOdometer: purchaseOdometer,
    purchasePrice: purchasePrice,
    soldOn: original.soldOn,
    soldPrice: original.soldPrice,
    expectedAnnual: original.expectedAnnual,
    tankCapacityMl: original.tankCapacityMl,
    sortOrder: original.sortOrder,
    currency: currency,
    distanceUnit: distanceUnit,
    volumeUnit: volumeUnit,
    consumptionUnit: consumptionUnit,
    noticeDistance: noticeDistance,
    noticeDays: noticeDays,
    createdAtUtcMs: original.createdAtUtcMs,
    updatedAtUtcMs: nowUtcMs,
  );

  /// A copy with the given changes.
  ///
  /// Every nullable field takes a `clear` flag rather than relying on null,
  /// because null already means "leave it alone" — without them the user could
  /// set a plate and never remove one.
  VehicleEditDraft copyWith({
    String? name,
    VehicleType? vehicleType,
    FuelKind? fuelKindDefault,
    String? make,
    String? model,
    int? year,
    String? plate,
    String? vin,
    VehicleColour? colour,
    String? notes,
    bool? isBusiness,
    bool? notificationsMuted,
    String? purchaseDate,
    Distance? purchaseOdometer,
    Money? purchasePrice,
    Currency? currency,
    DistanceUnit? distanceUnit,
    VolumeUnit? volumeUnit,
    ConsumptionUnit? consumptionUnit,
    Distance? noticeDistance,
    int? noticeDays,
    Set<VehicleField> clear = const {},
  }) => VehicleEditDraft(
    original: original,
    name: name ?? this.name,
    vehicleType: vehicleType ?? this.vehicleType,
    fuelKindDefault: fuelKindDefault ?? this.fuelKindDefault,
    make: _pick(VehicleField.make, make, this.make, clear),
    model: _pick(VehicleField.model, model, this.model, clear),
    year: _pick(VehicleField.year, year, this.year, clear),
    plate: _pick(VehicleField.plate, plate, this.plate, clear),
    vin: _pick(VehicleField.vin, vin, this.vin, clear),
    colour: _pick(VehicleField.colour, colour, this.colour, clear),
    notes: _pick(VehicleField.notes, notes, this.notes, clear),
    isBusiness: isBusiness ?? this.isBusiness,
    notificationsMuted: notificationsMuted ?? this.notificationsMuted,
    purchaseDate: _pick(
      VehicleField.purchaseDate,
      purchaseDate,
      this.purchaseDate,
      clear,
    ),
    purchaseOdometer: _pick(
      VehicleField.purchaseOdometer,
      purchaseOdometer,
      this.purchaseOdometer,
      clear,
    ),
    purchasePrice: _pick(
      VehicleField.purchasePrice,
      purchasePrice,
      this.purchasePrice,
      clear,
    ),
    currency: _pick(VehicleField.currency, currency, this.currency, clear),
    distanceUnit: _pick(
      VehicleField.distanceUnit,
      distanceUnit,
      this.distanceUnit,
      clear,
    ),
    volumeUnit: _pick(
      VehicleField.volumeUnit,
      volumeUnit,
      this.volumeUnit,
      clear,
    ),
    consumptionUnit: _pick(
      VehicleField.consumptionUnit,
      consumptionUnit,
      this.consumptionUnit,
      clear,
    ),
    noticeDistance: _pick(
      VehicleField.noticeDistance,
      noticeDistance,
      this.noticeDistance,
      clear,
    ),
    noticeDays: _pick(
      VehicleField.noticeDays,
      noticeDays,
      this.noticeDays,
      clear,
    ),
  );

  static T? _pick<T>(
    VehicleField field,
    T? given,
    T? existing,
    Set<VehicleField> clear,
  ) => clear.contains(field) ? null : (given ?? existing);

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

/// The nullable fields, so [VehicleEditDraft.copyWith] can clear one.
///
/// An enum rather than a `clearPlate: true` flag per field, because twenty-odd
/// booleans on one signature is a signature nobody reads.
enum VehicleField {
  /// [VehicleEditDraft.make].
  make,

  /// [VehicleEditDraft.model].
  model,

  /// [VehicleEditDraft.year].
  year,

  /// [VehicleEditDraft.plate].
  plate,

  /// [VehicleEditDraft.vin].
  vin,

  /// [VehicleEditDraft.colour].
  colour,

  /// [VehicleEditDraft.notes].
  notes,

  /// [VehicleEditDraft.purchaseDate].
  purchaseDate,

  /// [VehicleEditDraft.purchaseOdometer].
  purchaseOdometer,

  /// [VehicleEditDraft.purchasePrice].
  purchasePrice,

  /// [VehicleEditDraft.currency] — cleared means **Automatic**.
  currency,

  /// [VehicleEditDraft.distanceUnit] — cleared means **Automatic**.
  distanceUnit,

  /// [VehicleEditDraft.volumeUnit] — cleared means **Automatic**.
  volumeUnit,

  /// [VehicleEditDraft.consumptionUnit] — cleared means **Automatic**.
  consumptionUnit,

  /// [VehicleEditDraft.noticeDistance] — cleared means **Automatic**.
  noticeDistance,

  /// [VehicleEditDraft.noticeDays] — cleared means **Automatic**.
  noticeDays,
}
