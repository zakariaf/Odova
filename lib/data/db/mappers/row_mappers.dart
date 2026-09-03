// Drift rows in, domain models out. The boundary, and the only place that
// crosses it.
//
// `tools/check_drift_confinement.sh` proves no Drift symbol escapes
// `lib/data/`, and these functions are why that is possible: everything above
// the data layer sees `Vehicle` and `FillUp`, never `VehicleRow`. A repository
// that returned a generated row would make every screen and every test above
// it need a database.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
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
    purchaseOdometerM: row.purchaseOdometerM,
    purchasePriceMinor: row.purchasePriceMinor,
    purchasePriceCurrency: row.purchasePriceCurrency,
    status: enumFromWire(VehicleStatus.values, (v) => v.wire, row.status),
    soldOn: row.soldOn,
    soldPriceMinor: row.soldPriceMinor,
    soldPriceCurrency: row.soldPriceCurrency,
    expectedAnnualM: row.expectedAnnualM,
    colour: row.colour,
    notes: row.notes,
    sortOrder: row.sortOrder,
    notificationsMuted: row.notificationsMuted,
    currency: row.currency,
    distanceUnit: _optionalEnum(
      DistanceUnit.values,
      (v) => v.wire,
      row.distanceUnit,
    ),
    volumeUnit: _optionalEnum(
      VolumeUnit.values,
      (v) => v.wire,
      row.volumeUnit,
    ),
    consumptionUnit: _optionalEnum(
      ConsumptionUnit.values,
      (v) => v.wire,
      row.consumptionUnit,
    ),
    noticeDistanceM: row.noticeDistanceM,
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
    odometerM: row.odometerM,
    odometerUnit: enumFromWire(
      DistanceUnit.values,
      (v) => v.wire,
      row.odometerUnit,
    ),
    fuelKind: enumFromWire(FuelKind.values, (v) => v.wire, row.fuelKind),
    quantityMl: row.quantityMl,
    quantityG: row.quantityG,
    energyWh: row.energyWh,
    quantityUnit: enumFromWire(
      VolumeUnit.values,
      (v) => v.wire,
      row.quantityUnit,
    ),
    totalCostMinor: row.totalCostMinor,
    currency: row.currency,
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
    odometerM: row.odometerM,
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
    previousM: row.previousM,
    newM: row.newM,
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
T? _optionalEnum<T extends Object>(
  List<T> values,
  String Function(T) wire,
  String? stored,
) => stored == null ? null : enumFromWire<T>(values, wire, stored);
