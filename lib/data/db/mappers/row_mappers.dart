// Drift rows in, domain models out. The boundary, and the only place that
// crosses it.
//
// `tools/check_drift_confinement.sh` proves no Drift symbol escapes
// `lib/data/`, and these functions are why that is possible: everything above
// the data layer sees `Vehicle` and `FillUp`, never `VehicleRow`. A repository
// that returned a generated row would make every screen and every test above
// it need a database.
//
// All NINE row mappers live here. Six of them used to be private methods on
// the repositories that happened to grow first — `_expenseFromRow` beside a
// public `fillUpFromRow` of exactly the same shape, in a different file, for no
// reason anybody chose. That split had a cost:
// `test/data/db/mappers/value_object_mapping_test.dart` exists because a
// hardcoded currency in a mapper passed 2,304 tests, and the six on the other
// side of the split were unreachable from it — including the one that carries a
// service line's price.
//
// None of them touched `this`. A repository owns queries, transactions and
// rules; a mapper owns the two shapes.
//
// This is ALSO the only layer that knows a fill-up has three quantity columns
// and a price has two. Above here it is one `FuelQuantity` and one `Money`;
// below here it is the schema EPIC-05 built, unchanged. EPIC-06's swap
// happened at this boundary and nowhere else, which is why the columns did not
// move.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
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

/// An expense row as an [Expense].
Expense expenseFromRow(ExpenseRow row) {
  final times = repairAuditTimes(
    createdAtUtcMs: row.createdAtUtcMs,
    updatedAtUtcMs: row.updatedAtUtcMs,
  );

  return Expense(
    id: idFromStored(ExpenseId.tryParse, row.id),
    vehicleId: idFromStored(VehicleId.tryParse, row.vehicleId),
    tripId: row.tripId == null
        ? null
        : idFromStored(TripId.tryParse, row.tripId!),
    occurredOn: row.occurredOn,
    category: enumFromWire(
      ExpenseCategory.values,
      (v) => v.wire,
      row.category,
    ),
    label: row.label,
    amount: moneyOf(row.amountMinor, row.currency),
    coversFrom: row.coversFrom,
    coversTo: row.coversTo,
    odometer: distanceOrNull(row.odometerM),
    odometerUnit: enumFromWire(
      DistanceUnit.values,
      (v) => v.wire,
      row.odometerUnit,
    ),
    vendor: row.vendor,
    notes: row.notes,
    createdAtUtcMs: times.createdAtUtcMs,
    updatedAtUtcMs: times.updatedAtUtcMs,
  );
}

/// A trip row as a [Trip].
Trip tripFromRow(TripRow row) {
  final times = repairAuditTimes(
    createdAtUtcMs: row.createdAtUtcMs,
    updatedAtUtcMs: row.updatedAtUtcMs,
  );

  return Trip(
    id: idFromStored(TripId.tryParse, row.id),
    vehicleId: idFromStored(VehicleId.tryParse, row.vehicleId),
    title: row.title,
    purpose: enumFromWire(TripPurpose.values, (v) => v.wire, row.purpose),
    startedOn: row.startedOn,
    endedOn: row.endedOn,
    startOdometer: distanceOrNull(row.startOdometerM),
    endOdometer: distanceOrNull(row.endOdometerM),
    manualDistance: distanceOrNull(row.manualDistanceM),
    odometerUnit: enumFromWire(
      DistanceUnit.values,
      (v) => v.wire,
      row.odometerUnit,
    ),
    notes: row.notes,
    createdAtUtcMs: times.createdAtUtcMs,
    updatedAtUtcMs: times.updatedAtUtcMs,
  );
}

/// One record and the lines already fetched for it.
/// A service record row and its [lines] as a [ServiceRecord].
ServiceRecord serviceRecordFromRow(
  ServiceRecordRow row,
  List<ServiceLineRow> lines,
) {
  final times = repairAuditTimes(
    createdAtUtcMs: row.createdAtUtcMs,
    updatedAtUtcMs: row.updatedAtUtcMs,
  );

  return ServiceRecord(
    id: idFromStored(ServiceRecordId.tryParse, row.id),
    vehicleId: idFromStored(VehicleId.tryParse, row.vehicleId),
    occurredOn: row.occurredOn,
    odometer: distanceOrNull(row.odometerM),
    odometerUnit: enumFromWire(
      DistanceUnit.values,
      (v) => v.wire,
      row.odometerUnit,
    ),
    odometerEstimated: row.odometerEstimated,
    costEstimated: row.costEstimated,
    vendor: row.vendor,
    invoiceRef: row.invoiceRef,
    warrantyUntil: row.warrantyUntil,
    notes: row.notes,
    lines: lines.map(serviceLineFromRow).toList(),
    createdAtUtcMs: times.createdAtUtcMs,
    updatedAtUtcMs: times.updatedAtUtcMs,
  );
}

/// A service line row as a [ServiceLine].
ServiceLine serviceLineFromRow(ServiceLineRow row) => ServiceLine(
  id: idFromStored(ServiceLineId.tryParse, row.id),
  serviceRecordId: idFromStored(
    ServiceRecordId.tryParse,
    row.serviceRecordId,
  ),
  serviceItemId: row.serviceItemId == null
      ? null
      : idFromStored(ServiceItemId.tryParse, row.serviceItemId!),
  label: row.label,
  amount: moneyOf(row.amountMinor, row.currency),
  partNumber: row.partNumber,
  notes: row.notes,
);

/// A service item row as a [ServiceItem].
ServiceItem serviceItemFromRow(ServiceItemRow row) {
  final times = repairAuditTimes(
    createdAtUtcMs: row.createdAtUtcMs,
    updatedAtUtcMs: row.updatedAtUtcMs,
  );

  return ServiceItem(
    id: idFromStored(ServiceItemId.tryParse, row.id),
    vehicleId: idFromStored(VehicleId.tryParse, row.vehicleId),
    kind: enumFromWire(ServiceKind.values, (v) => v.wire, row.kind),
    label: row.label,
    intervalDistance: distanceOrNull(row.intervalDistanceM),
    intervalDistanceUnit: optionalEnumFromWire(
      DistanceUnit.values,
      (v) => v.wire,
      row.intervalDistanceUnit,
    ),
    intervalMonths: row.intervalMonths,
    targetOdometer: distanceOrNull(row.targetOdometerM),
    targetDate: row.targetDate,
    baselineDate: row.baselineDate,
    baselineOdometer: distanceOrNull(row.baselineOdometerM),
    noticeDistance: distanceOrNull(row.noticeDistanceM),
    noticeDays: row.noticeDays,
    isTracked: row.isTracked,
    isActive: row.isActive,
    notify: row.notify,
    priority: enumFromWire(
      ServicePriority.values,
      (v) => v.wire,
      row.priority,
    ),
    rollover: enumFromWire(
      ServiceRollover.values,
      (v) => v.wire,
      row.rollover,
    ),
    repeats: row.repeats,
    snoozedUntil: row.snoozedUntil,
    snoozeUntilOdometer: distanceOrNull(row.snoozeUntilOdometerM),
    snoozeCount: row.snoozeCount,
    notes: row.notes,
    createdAtUtcMs: times.createdAtUtcMs,
    updatedAtUtcMs: times.updatedAtUtcMs,
  );
}

/// The settings row as an [AppSettings].
AppSettings settingsFromRow(SettingsRow row) {
  final times = repairAuditTimes(
    createdAtUtcMs: row.createdAtUtcMs,
    updatedAtUtcMs: row.updatedAtUtcMs,
  );

  return AppSettings(
    schemaVersion: row.schemaVersion,
    language: row.language,
    calendar: row.calendar,
    numerals: row.numerals,
    firstDayOfWeek: row.firstDayOfWeek,
    theme: row.theme,
    currencyDefault: currencyOf(row.currencyDefault),
    currencyDisplay: row.currencyDisplay,
    distanceUnit: enumFromWire(
      DistanceUnit.values,
      (v) => v.wire,
      row.distanceUnit,
    ),
    volumeUnit: enumFromWire(
      VolumeUnit.values,
      (v) => v.wire,
      row.volumeUnit,
    ),
    consumptionUnit: enumFromWire(
      ConsumptionUnit.values,
      (v) => v.wire,
      row.consumptionUnit,
    ),
    noticeDistance: distanceOrNull(row.noticeDistanceM),
    noticeDays: row.noticeDays,
    notificationTimeMinutes: row.notificationTimeMinutes,
    quietHoursFromMinutes: row.quietHoursFromMinutes,
    quietHoursToMinutes: row.quietHoursToMinutes,
    weekdaysOnly: row.weekdaysOnly,
    notifyService: row.notifyService,
    notifyOdometer: row.notifyOdometer,
    notifyBackup: row.notifyBackup,
    activeVehicleId: row.activeVehicleId == null
        ? null
        : idFromStored(VehicleId.tryParse, row.activeVehicleId!),
    onboardingDone: row.onboardingDone,
    lastBackupAtUtcMs: row.lastBackupAtUtcMs,
    lastBackupReminderAtUtcMs: row.lastBackupReminderAtUtcMs,
    createdAtUtcMs: times.createdAtUtcMs,
    updatedAtUtcMs: times.updatedAtUtcMs,
  );
}

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

/// [money]'s amount column.
///
/// **The write direction, and it exists because the read direction's invariant
/// had nothing enforcing it here.** `moneyOrNull` refuses to build half a price
/// — an amount without its currency is not a smaller amount, it is an unknown
/// one — and then forty call sites across five repositories unwrapped
/// `.amountMinor` and `.currency.code` straight into companions, where writing
/// one without the other compiles.
///
/// Two functions rather than one returning a record, for the same reason the
/// three quantity writers are three: a drift companion sets independent
/// `Value`s, and a record would be destructured back into two at every call
/// site. What they buy is that they are always written as a pair, and a
/// reviewer can see it.
/// Nullable and non-nullable in pairs, mirroring [moneyOf]/[moneyOrNull] on
/// the way in — a `NOT NULL` column and a nullable one are different columns
/// and the type says which.
int amountMinorColumn(Money money) => money.amountMinor;

/// [money]'s currency column. Always written beside [amountMinorColumn].
String currencyColumn(Money money) => money.currency.code;

/// [money]'s amount column, or null.
int? amountMinorColumnOrNull(Money? money) => money?.amountMinor;

/// [money]'s currency column, or null. Always beside
/// [amountMinorColumnOrNull].
String? currencyColumnOrNull(Money? money) => money?.currency.code;

/// [distance]'s metre column.
///
/// The inverse of [distanceOrNull]. Named rather than inlined as `.metres` so
/// that a grep for a converted value reaching a column has one shape to look
/// for rather than forty.
int metresColumn(Distance distance) => distance.metres;

/// [distance]'s metre column, or null.
int? metresColumnOrNull(Distance? distance) => distance?.metres;

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
