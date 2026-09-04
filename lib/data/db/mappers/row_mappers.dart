// Drift rows in, domain models out. The boundary, and the only place that
// crosses it.
//
// `tools/check_drift_confinement.sh` proves no Drift symbol escapes
// `lib/data/`, and these functions are why that is possible: everything above
// the data layer sees `Vehicle` and `FillUp`, never `VehicleRow`. A repository
// that returned a generated row would make every screen and every test above
// it need a database.
//
// This is ALSO the only layer that knows a fill-up has three quantity columns
// and a price has two. Above here it is one `FuelQuantity` and one `Money`;
// below here it is the schema EPIC-05 built, unchanged. EPIC-06's swap
// happened at this boundary and nowhere else, which is why the columns did not
// move.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/energy.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/mass.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/mappers/audit_mapper.dart';

/// Reads an enum from its stored wire value.
///
/// Throws for a value the enum does not have — which cannot happen, because
/// every one of these columns carries a `CHECK` listing exactly these values
/// and `test/data/db/tables/enum_checks_test.dart` keeps the two in step. A
/// throw here is a schema bug, not a runtime condition, so it is an error and
/// not a `Result`: `error-handling-typed-results` rule 8 says a bug is thrown
/// and a recoverable failure is returned.
T enumFromWire<T>(List<T> values, String Function(T) wire, String stored) =>
    values.firstWhere(
      (value) => wire(value) == stored,
      orElse: () => throw StateError(
        'stored value "$stored" is not one of ${values.map(wire).toList()} — '
        'the CHECK and the enum have drifted',
      ),
    );

/// Reads an id, throwing if the stored text is not one.
///
/// Same reasoning: the id was written by this app through `RecordId`, so a
/// malformed one is corruption rather than input. Import validates before it
/// writes and returns a typed failure there.
T idFromStored<T extends RecordId>(
  T? Function(String) tryParse,
  String stored,
) =>
    tryParse(stored) ??
    (throw StateError('stored id "$stored" is not a valid RecordId'));

/// A vehicle row as a [Vehicle].
Vehicle vehicleFromRow(VehicleRow row) {
  final times = repairAuditTimes(
    createdAtUtcMs: row.createdAtUtcMs,
    updatedAtUtcMs: row.updatedAtUtcMs,
  );

  return Vehicle(
    id: idFromStored(VehicleId.tryParse, row.id),
    name: row.name,
    make: row.make,
    model: row.model,
    year: row.year,
    plate: row.plate,
    vin: row.vin,
    vehicleType: enumFromWire(
      VehicleType.values,
      (v) => v.wire,
      row.vehicleType,
    ),
    isBusiness: row.isBusiness,
    fuelKindDefault: enumFromWire(
      FuelKind.values,
      (v) => v.wire,
      row.fuelKindDefault,
    ),
    tankCapacityMl: row.tankCapacityMl,
    purchaseDate: row.purchaseDate,
    purchaseOdometer: distanceOrNull(row.purchaseOdometerM),
    purchasePrice: moneyOrNull(
      row.purchasePriceMinor,
      row.purchasePriceCurrency,
    ),
    status: enumFromWire(VehicleStatus.values, (v) => v.wire, row.status),
    soldOn: row.soldOn,
    soldPrice: moneyOrNull(row.soldPriceMinor, row.soldPriceCurrency),
    expectedAnnual: distanceOrNull(row.expectedAnnualM),
    colour: row.colour,
    notes: row.notes,
    sortOrder: row.sortOrder,
    notificationsMuted: row.notificationsMuted,
    currency: row.currency == null ? null : currencyOf(row.currency!),
    distanceUnit: optionalEnumFromWire(
      DistanceUnit.values,
      (v) => v.wire,
      row.distanceUnit,
    ),
    volumeUnit: optionalEnumFromWire(
      VolumeUnit.values,
      (v) => v.wire,
      row.volumeUnit,
    ),
    consumptionUnit: optionalEnumFromWire(
      ConsumptionUnit.values,
      (v) => v.wire,
      row.consumptionUnit,
    ),
    noticeDistance: distanceOrNull(row.noticeDistanceM),
    noticeDays: row.noticeDays,
    createdAtUtcMs: times.createdAtUtcMs,
    updatedAtUtcMs: times.updatedAtUtcMs,
  );
}

/// A fill-up row as a [FillUp].
FillUp fillUpFromRow(FillUpRow row) {
  final times = repairAuditTimes(
    createdAtUtcMs: row.createdAtUtcMs,
    updatedAtUtcMs: row.updatedAtUtcMs,
  );

  return FillUp(
    id: idFromStored(FillUpId.tryParse, row.id),
    vehicleId: idFromStored(VehicleId.tryParse, row.vehicleId),
    occurredOn: row.occurredOn,
    odometer: distanceOrNull(row.odometerM),
    odometerUnit: enumFromWire(
      DistanceUnit.values,
      (v) => v.wire,
      row.odometerUnit,
    ),
    fuelKind: enumFromWire(FuelKind.values, (v) => v.wire, row.fuelKind),
    quantity: fuelQuantityOf(
      millilitres: row.quantityMl,
      grams: row.quantityG,
      wattHours: row.energyWh,
    ),
    quantityUnit: enumFromWire(
      VolumeUnit.values,
      (v) => v.wire,
      row.quantityUnit,
    ),
    totalCost: moneyOf(row.totalCostMinor, row.currency),
    isFullTank: row.isFullTank,
    chainBroken: row.chainBroken,
    grade: row.grade,
    station: row.station,
    tripId: row.tripId == null
        ? null
        : idFromStored(TripId.tryParse, row.tripId!),
    notes: row.notes,
    createdAtUtcMs: times.createdAtUtcMs,
    updatedAtUtcMs: times.updatedAtUtcMs,
  );
}

/// An odometer reading row as an [OdometerReading].
OdometerReading odometerReadingFromRow(OdometerReadingRow row) {
  final times = repairAuditTimes(
    createdAtUtcMs: row.createdAtUtcMs,
    updatedAtUtcMs: row.updatedAtUtcMs,
  );

  return OdometerReading(
    id: idFromStored(OdometerReadingId.tryParse, row.id),
    vehicleId: idFromStored(VehicleId.tryParse, row.vehicleId),
    occurredOn: row.occurredOn,
    odometer: Distance(row.odometerM),
    odometerUnit: enumFromWire(
      DistanceUnit.values,
      (v) => v.wire,
      row.odometerUnit,
    ),
    source: enumFromWire(OdometerSource.values, (v) => v.wire, row.source),
    sourceId: row.sourceId,
    notes: row.notes,
    createdAtUtcMs: times.createdAtUtcMs,
    updatedAtUtcMs: times.updatedAtUtcMs,
  );
}

/// An odometer correction row as an [OdometerCorrection].
OdometerCorrection odometerCorrectionFromRow(OdometerCorrectionRow row) {
  final times = repairAuditTimes(
    createdAtUtcMs: row.createdAtUtcMs,
    updatedAtUtcMs: row.updatedAtUtcMs,
  );

  return OdometerCorrection(
    id: idFromStored(OdometerCorrectionId.tryParse, row.id),
    vehicleId: idFromStored(VehicleId.tryParse, row.vehicleId),
    fromReadingId: idFromStored(OdometerReadingId.tryParse, row.fromReadingId),
    previous: Distance(row.previousM),
    replacement: Distance(row.newM),
    odometerUnit: enumFromWire(
      DistanceUnit.values,
      (v) => v.wire,
      row.odometerUnit,
    ),
    reason: enumFromWire(
      OdometerCorrectionReason.values,
      (v) => v.wire,
      row.reason,
    ),
    notes: row.notes,
    createdAtUtcMs: times.createdAtUtcMs,
    updatedAtUtcMs: times.updatedAtUtcMs,
  );
}

/// [enumFromWire] for a nullable column.
///
/// Takes the wire extractor like its non-null sibling rather than reaching for
/// `(value as dynamic).wire`, which compiles for any type and fails at runtime
/// on the first enum that does not have the field.
T? optionalEnumFromWire<T extends Object>(
  List<T> values,
  String Function(T) wire,
  String? stored,
) => stored == null ? null : enumFromWire<T>(values, wire, stored);

/// A stored currency code as a [Currency].
///
/// Throws for a code the schema should have refused — `length(currency) = 3` is
/// a CHECK on every currency column — so a failure here is corruption rather
/// than input, and `error-handling-typed-results` says a bug throws while a
/// foreseeable failure is typed.
Currency currencyOf(String code) =>
    Currency.tryParse(code) ??
    (throw StateError('stored currency "$code" is not an ISO 4217 code'));

/// A minor amount and its code as a [Money].
///
/// Every money column in the schema is a PAIR — `amount_minor` beside
/// `currency` — and reuniting them here is what stops a caller reading one
/// without the other. An amount without its currency is not a smaller amount,
/// it is an unknown one.
Money moneyOf(int amountMinor, String code) =>
    Money(amountMinor, currencyOf(code));

/// A nullable minor amount and code as a [Money].
Money? moneyOrNull(int? amountMinor, String? code) =>
    amountMinor == null || code == null ? null : moneyOf(amountMinor, code);

/// A nullable metre column as a [Distance].
Distance? distanceOrNull(int? metres) =>
    metres == null ? null : Distance(metres);

/// A fill-up's three quantity columns as one [FuelQuantity].
///
/// The schema guarantees exactly one is non-null — the
/// `(quantity_ml IS NOT NULL) + … = 1` CHECK — so this reads them in order and
/// returns null only when all three are, which the schema also forbids and an
/// unmigrated row could still produce.
FuelQuantity? fuelQuantityOf({
  required int? millilitres,
  required int? grams,
  required int? wattHours,
}) {
  if (millilitres != null) return LiquidVolume(Volume(millilitres));
  if (grams != null) return GasMass(Mass(grams));
  if (wattHours != null) return ElectricEnergy(Energy(wattHours));
  return null;
}

/// [quantity]'s millilitre column — null unless it is a liquid.
///
/// The three writers are separate functions rather than one returning a record,
/// because a companion sets three independent `Value`s and a record would be
/// destructured back into three at every call site. Together they are the
/// inverse of [fuelQuantityOf], and the schema's exactly-one CHECK is what
/// proves they agree: a fourth `FuelQuantity` subtype that nobody added a
/// writer for makes every insert fail rather than silently storing null.
int? millilitresColumn(FuelQuantity? quantity) =>
    quantity is LiquidVolume ? quantity.volume.millilitres : null;

/// [quantity]'s gram column — null unless it is a compressed gas.
int? gramsColumn(FuelQuantity? quantity) =>
    quantity is GasMass ? quantity.mass.grams : null;

/// [quantity]'s watt-hour column — null unless it is a charge.
int? wattHoursColumn(FuelQuantity? quantity) =>
    quantity is ElectricEnergy ? quantity.energy.wattHours : null;
