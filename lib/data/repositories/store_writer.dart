// Every table, filled from one `StoreSnapshot`, in dependency order.
//
// The only place in the app that writes the WHOLE store. Every other write is
// one record through its own repository, because every other write is a person
// tapping Save; this one is SPEC.md §6 §4's import, which replaces everything.
//
// It writes into a database the caller opened, and it neither opens nor closes
// nor renames anything. That separation is what makes §4.1's atomic swap
// testable: the staging database is just a file this fills, and the publish is
// a rename somebody else performs after every handle is closed.
//
// One batch per table rather than one insert per record. A 12,000-record import
// through individual statements is 12,000 round trips through the drift
// executor, and §9's eight-second budget does not survive that.
import 'package:drift/drift.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/store_snapshot.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/mappers/row_mappers.dart';

/// Fills [db] from [store].
///
/// The database must be EMPTY. This is not a merge and it does not clear
/// anything first: §6 §4 makes import a replace, and the replace happens by
/// building a new file beside the old one rather than by deleting rows out of
/// the live one — a half-deleted live database is the state §4.1 exists to make
/// impossible.
///
/// Parents before children, so every foreign key resolves as it is inserted
/// rather than at the end of a transaction that would then have to roll back
/// the lot.
Future<void> writeStoreSnapshot(AppDatabase db, StoreSnapshot store) async {
  await db.transaction(() async {
    await db.into(db.settingsTable).insert(_settings(store.settings));
    await db.batch((batch) {
      batch
        ..insertAll(db.vehicles, store.vehicles.map(_vehicle))
        ..insertAll(db.serviceItems, store.reminders.map(_serviceItem))
        ..insertAll(db.trips, store.trips.map(_trip))
        ..insertAll(db.odometerReadings, store.odometerReadings.map(_reading))
        ..insertAll(db.serviceRecords, store.services.map(_serviceRecord))
        ..insertAll(db.fillUps, store.fillUps.map(_fillUp))
        ..insertAll(db.expenses, store.expenses.map(_expense))
        ..insertAll(
          db.serviceLines,
          store.services.expand((s) => s.lines).map(_serviceLine),
        )
        // Corrections last: each names a reading, and the readings have to be
        // in before the foreign key can hold.
        ..insertAll(
          db.odometerCorrections,
          store.odometerCorrections.map(_correction),
        );
    });
  });
}

SettingsTableCompanion _settings(AppSettings s) =>
    SettingsTableCompanion.insert(
      id: 'settings',
      createdAtUtcMs: s.createdAtUtcMs,
      updatedAtUtcMs: s.updatedAtUtcMs,
      schemaVersion: s.schemaVersion,
      language: s.language,
      calendar: s.calendar,
      numerals: s.numerals,
      firstDayOfWeek: s.firstDayOfWeek,
      theme: s.theme,
      currencyDefault: currencyColumn(Money(0, s.currencyDefault)),
      currencyDisplay: s.currencyDisplay,
      distanceUnit: s.distanceUnit.wire,
      volumeUnit: s.volumeUnit.wire,
      consumptionUnit: s.consumptionUnit.wire,
      noticeDistanceM: Value(metresColumnOrNull(s.noticeDistance)),
      noticeDays: Value(s.noticeDays),
      notificationTimeMinutes: s.notificationTimeMinutes,
      quietHoursFromMinutes: s.quietHoursFromMinutes,
      quietHoursToMinutes: s.quietHoursToMinutes,
      weekdaysOnly: Value(s.weekdaysOnly),
      notifyService: Value(s.notifyService),
      notifyOdometer: Value(s.notifyOdometer),
      notifyBackup: Value(s.notifyBackup),
      activeVehicleId: Value(s.activeVehicleId?.toString()),
      onboardingDone: Value(s.onboardingDone),
      lastBackupAtUtcMs: Value(s.lastBackupAtUtcMs),
      lastBackupReminderAtUtcMs: Value(s.lastBackupReminderAtUtcMs),
    );

VehiclesCompanion _vehicle(Vehicle v) => VehiclesCompanion.insert(
  id: v.id.toString(),
  createdAtUtcMs: v.createdAtUtcMs,
  updatedAtUtcMs: v.updatedAtUtcMs,
  name: v.name,
  make: Value(v.make),
  model: Value(v.model),
  year: Value(v.year),
  plate: Value(v.plate),
  vin: Value(v.vin),
  vehicleType: v.vehicleType.wire,
  isBusiness: Value(v.isBusiness),
  fuelKindDefault: v.fuelKindDefault.wire,
  tankCapacityMl: Value(v.tankCapacityMl),
  purchaseDate: Value(v.purchaseDate),
  purchaseOdometerM: Value(metresColumnOrNull(v.purchaseOdometer)),
  purchasePriceMinor: Value(amountMinorColumnOrNull(v.purchasePrice)),
  purchasePriceCurrency: Value(currencyColumnOrNull(v.purchasePrice)),
  status: v.status.wire,
  soldOn: Value(v.soldOn),
  soldPriceMinor: Value(amountMinorColumnOrNull(v.soldPrice)),
  soldPriceCurrency: Value(currencyColumnOrNull(v.soldPrice)),
  expectedAnnualM: Value(metresColumnOrNull(v.expectedAnnual)),
  colour: Value(v.colour),
  notes: Value(v.notes),
  sortOrder: Value(v.sortOrder),
  notificationsMuted: Value(v.notificationsMuted),
  // Null when INHERITED, and never materialised: writing the app defaults in
  // would pin every vehicle to whatever this phone happened to be set to, and
  // a later change to the default would silently stop reaching them.
  currency: Value(
    v.currency == null ? null : currencyColumn(Money(0, v.currency!)),
  ),
  distanceUnit: Value(v.distanceUnit?.wire),
  volumeUnit: Value(v.volumeUnit?.wire),
  consumptionUnit: Value(v.consumptionUnit?.wire),
  noticeDistanceM: Value(metresColumnOrNull(v.noticeDistance)),
  noticeDays: Value(v.noticeDays),
);

ServiceItemsCompanion _serviceItem(ServiceItem i) =>
    ServiceItemsCompanion.insert(
      id: i.id.toString(),
      createdAtUtcMs: i.createdAtUtcMs,
      updatedAtUtcMs: i.updatedAtUtcMs,
      vehicleId: i.vehicleId.toString(),
      kind: i.kind.wire,
      label: Value(i.label),
      intervalDistanceM: Value(metresColumnOrNull(i.intervalDistance)),
      intervalDistanceUnit: Value(i.intervalDistanceUnit?.wire),
      intervalMonths: Value(i.intervalMonths),
      targetOdometerM: Value(metresColumnOrNull(i.targetOdometer)),
      targetDate: Value(i.targetDate),
      baselineDate: Value(i.baselineDate),
      baselineOdometerM: Value(metresColumnOrNull(i.baselineOdometer)),
      noticeDistanceM: Value(metresColumnOrNull(i.noticeDistance)),
      noticeDays: Value(i.noticeDays),
      isTracked: Value(i.isTracked),
      isActive: Value(i.isActive),
      notify: Value(i.notify),
      priority: i.priority.wire,
      rollover: i.rollover.wire,
      repeats: Value(i.repeats),
      snoozedUntil: Value(i.snoozedUntil),
      snoozeUntilOdometerM: Value(metresColumnOrNull(i.snoozeUntilOdometer)),
      snoozeCount: Value(i.snoozeCount),
      notes: Value(i.notes),
    );

TripsCompanion _trip(Trip t) => TripsCompanion.insert(
  id: t.id.toString(),
  createdAtUtcMs: t.createdAtUtcMs,
  updatedAtUtcMs: t.updatedAtUtcMs,
  vehicleId: t.vehicleId.toString(),
  title: Value(t.title),
  purpose: t.purpose.wire,
  startedOn: t.startedOn,
  endedOn: Value(t.endedOn),
  startOdometerM: Value(metresColumnOrNull(t.startOdometer)),
  endOdometerM: Value(metresColumnOrNull(t.endOdometer)),
  manualDistanceM: Value(metresColumnOrNull(t.manualDistance)),
  odometerUnit: t.odometerUnit.wire,
  notes: Value(t.notes),
);

OdometerReadingsCompanion _reading(OdometerReading r) =>
    OdometerReadingsCompanion.insert(
      id: r.id.toString(),
      createdAtUtcMs: r.createdAtUtcMs,
      updatedAtUtcMs: r.updatedAtUtcMs,
      vehicleId: r.vehicleId.toString(),
      occurredOn: r.occurredOn,
      odometerM: metresColumn(r.odometer),
      odometerUnit: r.odometerUnit.wire,
      source: r.source.wire,
      sourceId: Value(r.sourceId?.toString()),
      notes: Value(r.notes),
    );

ServiceRecordsCompanion _serviceRecord(ServiceRecord s) =>
    ServiceRecordsCompanion.insert(
      id: s.id.toString(),
      createdAtUtcMs: s.createdAtUtcMs,
      updatedAtUtcMs: s.updatedAtUtcMs,
      vehicleId: s.vehicleId.toString(),
      occurredOn: s.occurredOn,
      odometerM: Value(metresColumnOrNull(s.odometer)),
      odometerUnit: s.odometerUnit.wire,
      odometerEstimated: Value(s.odometerEstimated),
      costEstimated: Value(s.costEstimated),
      vendor: Value(s.vendor),
      invoiceRef: Value(s.invoiceRef),
      warrantyUntil: Value(s.warrantyUntil),
      notes: Value(s.notes),
    );

ServiceLinesCompanion _serviceLine(ServiceLine l) =>
    ServiceLinesCompanion.insert(
      id: l.id.toString(),
      serviceRecordId: l.serviceRecordId.toString(),
      serviceItemId: Value(l.serviceItemId?.toString()),
      label: l.label,
      amountMinor: amountMinorColumn(l.amount),
      currency: currencyColumn(l.amount),
      partNumber: Value(l.partNumber),
      notes: Value(l.notes),
    );

FillUpsCompanion _fillUp(FillUp f) => FillUpsCompanion.insert(
  id: f.id.toString(),
  createdAtUtcMs: f.createdAtUtcMs,
  updatedAtUtcMs: f.updatedAtUtcMs,
  vehicleId: f.vehicleId.toString(),
  occurredOn: f.occurredOn,
  odometerM: Value(metresColumnOrNull(f.odometer)),
  odometerUnit: f.odometerUnit.wire,
  fuelKind: f.fuelKind.wire,
  // Exactly one of the three is non-null, chosen by the quantity's own form.
  // These three helpers are the only place that decision is made, and they
  // are why an EV's watt-hours cannot land in the millilitre column.
  quantityMl: Value(millilitresColumn(f.quantity)),
  quantityG: Value(gramsColumn(f.quantity)),
  energyWh: Value(wattHoursColumn(f.quantity)),
  quantityUnit: f.quantityUnit.wire,
  totalCostMinor: amountMinorColumn(f.totalCost),
  currency: currencyColumn(f.totalCost),
  isFullTank: Value(f.isFullTank),
  chainBroken: Value(f.chainBroken),
  grade: Value(f.grade),
  station: Value(f.station),
  tripId: Value(f.tripId?.toString()),
  notes: Value(f.notes),
);

ExpensesCompanion _expense(Expense e) => ExpensesCompanion.insert(
  id: e.id.toString(),
  createdAtUtcMs: e.createdAtUtcMs,
  updatedAtUtcMs: e.updatedAtUtcMs,
  vehicleId: e.vehicleId.toString(),
  tripId: Value(e.tripId?.toString()),
  occurredOn: e.occurredOn,
  category: e.category.wire,
  label: Value(e.label),
  amountMinor: amountMinorColumn(e.amount),
  currency: currencyColumn(e.amount),
  coversFrom: Value(e.coversFrom),
  coversTo: Value(e.coversTo),
  odometerM: Value(metresColumnOrNull(e.odometer)),
  odometerUnit: e.odometerUnit.wire,
  vendor: Value(e.vendor),
  notes: Value(e.notes),
);

OdometerCorrectionsCompanion _correction(OdometerCorrection c) =>
    OdometerCorrectionsCompanion.insert(
      id: c.id.toString(),
      createdAtUtcMs: c.createdAtUtcMs,
      updatedAtUtcMs: c.updatedAtUtcMs,
      vehicleId: c.vehicleId.toString(),
      fromReadingId: c.fromReadingId.toString(),
      previousM: metresColumn(c.previous),
      newM: metresColumn(c.replacement),
      odometerUnit: c.odometerUnit.wire,
      reason: c.reason.wire,
      notes: Value(c.notes),
    );
