// A store written and read back is the same store.
//
// `store_writer.dart` is the import's write side: it maps every domain model
// onto forty columns across nine tables, and every one of those mappings is a
// place a value can land in the wrong column. Nothing about that fails loudly
// — a `station` written into `grade` produces a perfectly valid database, an
// import that reports success, and a user whose fuel history is subtly wrong.
//
// So this writes a snapshot with every optional field filled and reads it back
// through `readStoreSnapshot`, which is the same path an export takes. The two
// are independent: the writer builds companions, the reader maps rows.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/store_snapshot.dart';
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
import 'package:odova/data/db/connection.dart';
import 'package:odova/data/repositories/store_reader.dart';
import 'package:odova/data/repositories/store_writer.dart';

final Currency _eur = Currency.tryParse('EUR')!;
final Currency _gbp = Currency.tryParse('GBP')!;
final VehicleId _veh = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD')!;
final TripId _trip = TripId.tryParse('trp_01K2P0M4A7C1V9X6H2P5S8GQZR')!;
final ServiceItemId _item = ServiceItemId.tryParse(
  'rem_01JV7B5X4G2K9M6P0S3D8FNRTC',
)!;
final ServiceRecordId _service = ServiceRecordId.tryParse(
  'srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX',
)!;
final OdometerReadingId _reading = OdometerReadingId.tryParse(
  'odo_01K2S1D9F4H7J0P3N6Q9T2W5YB',
)!;

/// Every optional field filled, so a mapping that drops one is visible.
///
/// A snapshot of defaults would round-trip through a writer that ignored half
/// its arguments.
StoreSnapshot _full() => StoreSnapshot(
  settings: AppSettings(
    schemaVersion: 1,
    currencyDefault: _eur,
    createdAtUtcMs: 10,
    updatedAtUtcMs: 20,
    language: 'fa',
    calendar: 'persian',
    numerals: 'extended_arabic_indic',
    firstDayOfWeek: DateTime.saturday,
    theme: 'dark',
    currencyDisplay: 'toman',
    distanceUnit: DistanceUnit.mi,
    volumeUnit: VolumeUnit.galUk,
    consumptionUnit: ConsumptionUnit.mpgUk,
    noticeDistance: const Distance(500_000),
    noticeDays: 21,
    notificationTimeMinutes: 7 * 60 + 30,
    quietHoursFromMinutes: 22 * 60,
    quietHoursToMinutes: 6 * 60,
    weekdaysOnly: true,
    notifyService: false,
    notifyOdometer: false,
    notifyBackup: false,
    onboardingDone: true,
    lastBackupAtUtcMs: 999,
    lastBackupReminderAtUtcMs: 888,
  ),
  vehicles: [
    Vehicle(
      id: _veh,
      name: 'VW Käfer',
      vehicleType: VehicleType.motorcycle,
      fuelKindDefault: FuelKind.petrol,
      status: VehicleStatus.sold,
      make: 'VW',
      model: 'Käfer 1303',
      year: 1972,
      plate: 'M-AB 1234',
      vin: 'WVWZZZ1JZXW000001',
      isBusiness: true,
      tankCapacityMl: 40_000,
      purchaseDate: '2019-04-01',
      purchaseOdometer: const Distance(120_000_000),
      purchasePrice: Money(850_000, _eur),
      soldOn: '2026-08-01',
      soldPrice: Money(1_200_000, _gbp),
      expectedAnnual: const Distance(15_000_000),
      colour: 'Blue',
      notes: 'Zahnriemen laut Werkstatt',
      sortOrder: 3,
      notificationsMuted: true,
      currency: _gbp,
      distanceUnit: DistanceUnit.mi,
      volumeUnit: VolumeUnit.galUs,
      consumptionUnit: ConsumptionUnit.mpgUs,
      noticeDistance: const Distance(300_000),
      noticeDays: 14,
      createdAtUtcMs: 100,
      updatedAtUtcMs: 200,
    ),
  ],
  reminders: [
    ServiceItem(
      id: _item,
      vehicleId: _veh,
      kind: ServiceKind.custom,
      priority: ServicePriority.safety,
      rollover: ServiceRollover.fromDue,
      label: 'Ventilspiel',
      intervalDistance: const Distance(15_000_000),
      intervalDistanceUnit: DistanceUnit.km,
      intervalMonths: 12,
      targetOdometer: const Distance(200_000_000),
      targetDate: '2027-01-01',
      baselineDate: '2026-01-01',
      baselineOdometer: const Distance(180_000_000),
      noticeDistance: const Distance(200_000),
      noticeDays: 7,
      isActive: false,
      notify: false,
      repeats: false,
      snoozedUntil: '2026-12-01',
      snoozeUntilOdometer: const Distance(190_000_000),
      snoozeCount: 2,
      notes: 'یادداشت فارسی',
      createdAtUtcMs: 300,
      updatedAtUtcMs: 400,
    ),
  ],
  odometerReadings: [
    OdometerReading(
      id: _reading,
      vehicleId: _veh,
      occurredOn: '2026-08-01',
      odometer: const Distance(215_104_000),
      odometerUnit: DistanceUnit.mi,
      source: OdometerSource.manual,
      notes: 'dash',
      createdAtUtcMs: 500,
      updatedAtUtcMs: 600,
    ),
  ],
  odometerCorrections: [
    OdometerCorrection(
      id: OdometerCorrectionId.tryParse('cor_01K2S1D9F4H7J0P3N6Q9T2W5YB')!,
      vehicleId: _veh,
      fromReadingId: _reading,
      previous: const Distance(215_104_000),
      replacement: const Distance(15_104_000),
      odometerUnit: DistanceUnit.km,
      reason: OdometerCorrectionReason.clusterReplaced,
      notes: 'new cluster',
      createdAtUtcMs: 700,
      updatedAtUtcMs: 800,
    ),
  ],
  fillUps: [
    FillUp(
      id: FillUpId.tryParse('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH')!,
      vehicleId: _veh,
      occurredOn: '2026-07-29',
      odometer: const Distance(214_256_000),
      odometerUnit: DistanceUnit.mi,
      fuelKind: FuelKind.diesel,
      quantity: const LiquidVolume(Volume(44_020)),
      quantityUnit: VolumeUnit.galUs,
      totalCost: Money(7351, _eur),
      isFullTank: false,
      chainBroken: true,
      grade: 'Diesel B7',
      station: 'Shell Rosenheimer Str.',
      tripId: _trip,
      notes: 'voll',
      createdAtUtcMs: 900,
      updatedAtUtcMs: 1000,
    ),
    // The two non-litre forms, because one column each and the wrong one is a
    // silent unit swap.
    FillUp(
      id: FillUpId.tryParse('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GJ')!,
      vehicleId: _veh,
      occurredOn: '2026-07-30',
      odometerUnit: DistanceUnit.km,
      fuelKind: FuelKind.cng,
      quantity: const GasMass(Mass(4300)),
      quantityUnit: VolumeUnit.l,
      totalCost: Money(3900, _eur),
      createdAtUtcMs: 1100,
      updatedAtUtcMs: 1200,
    ),
    FillUp(
      id: FillUpId.tryParse('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GK')!,
      vehicleId: _veh,
      occurredOn: '2026-07-31',
      odometerUnit: DistanceUnit.km,
      fuelKind: FuelKind.electric,
      quantity: const ElectricEnergy(Energy(41_500)),
      quantityUnit: VolumeUnit.l,
      totalCost: Money(1290, _eur),
      createdAtUtcMs: 1300,
      updatedAtUtcMs: 1400,
    ),
  ],
  services: [
    ServiceRecord(
      id: _service,
      vehicleId: _veh,
      occurredOn: '2026-05-22',
      odometer: const Distance(208_940_000),
      odometerUnit: DistanceUnit.mi,
      odometerEstimated: true,
      costEstimated: true,
      lines: [
        ServiceLine(
          id: ServiceLineId.tryParse('lin_01K0C4V2H9B8N3Q7ZE5RY6TMX1')!,
          serviceRecordId: _service,
          serviceItemId: _item,
          label: 'Ölwechsel',
          amount: Money(9820, _eur),
          partNumber: 'A-123',
          notes: 'line note',
        ),
      ],
      vendor: 'Werkstatt Müller',
      invoiceRef: 'R-2026-0412',
      warrantyUntil: '2028-05-22',
      notes: 'service note',
      createdAtUtcMs: 1500,
      updatedAtUtcMs: 1600,
    ),
  ],
  expenses: [
    Expense(
      id: ExpenseId.tryParse('exp_01K1R9T6Y2W5Q8Z3E7B0N4MJDF')!,
      vehicleId: _veh,
      occurredOn: '2026-01-03',
      odometer: const Distance(200_000_000),
      odometerUnit: DistanceUnit.km,
      category: ExpenseCategory.insurance,
      label: 'Haftpflicht',
      // The one money field that may be NEGATIVE — §10's refund switch.
      amount: Money(-61_200, _eur),
      vendor: 'HUK',
      notes: 'expense note',
      coversFrom: '2026-01-01',
      coversTo: '2026-12-31',
      tripId: _trip,
      createdAtUtcMs: 1700,
      updatedAtUtcMs: 1800,
    ),
  ],
  trips: [
    Trip(
      id: _trip,
      vehicleId: _veh,
      title: 'München → Wien',
      purpose: TripPurpose.business,
      startedOn: '2026-08-21',
      endedOn: '2026-08-23',
      startOdometer: const Distance(214_000_000),
      endOdometer: const Distance(214_800_000),
      odometerUnit: DistanceUnit.km,
      notes: 'trip note',
      createdAtUtcMs: 1900,
      updatedAtUtcMs: 2000,
    ),
  ],
);

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory(setup: applyPragmas));
  });
  tearDown(() => db.close());

  test('every field survives a write and a read', () async {
    final before = _full();

    await writeStoreSnapshot(db, before);
    final after = await readStoreSnapshot(db);

    // Field by field rather than one `expect`, so a failure names the column.
    expect(after.settings, before.settings);
    expect(after.vehicles, before.vehicles);
    expect(after.reminders, before.reminders);
    expect(after.odometerReadings, before.odometerReadings);
    expect(after.odometerCorrections, before.odometerCorrections);
    expect(after.services, before.services);
    expect(after.expenses, before.expenses);
    expect(after.trips, before.trips);
  });

  test('the three fuel forms come back in their own units', () async {
    // One column each, and the wrong one is a silent unit swap: watt-hours
    // read back as millilitres are 41.5 litres of diesel, and nothing on the
    // screen would say so.
    await writeStoreSnapshot(db, _full());
    final after = await readStoreSnapshot(db);

    expect(
      after.fillUps.map((f) => f.quantity),
      [
        const LiquidVolume(Volume(44_020)),
        const GasMass(Mass(4300)),
        const ElectricEnergy(Energy(41_500)),
      ],
    );
  });

  test('a negative expense keeps its sign', () async {
    // §10's refund switch. A writer that stored the magnitude would turn every
    // refund into a charge, and the monthly total would be wrong by twice the
    // amount.
    await writeStoreSnapshot(db, _full());
    final after = await readStoreSnapshot(db);

    expect(after.expenses.single.amount.amountMinor, -61_200);
  });

  test(
    "a vehicle's inherited units stay null through the round trip",
    () async {
      // Null means INHERITED. A writer that materialised the app defaults would
      // pin every vehicle to whatever this phone happened to be set to, and a
      // later change to the default would silently stop reaching them.
      final store = _full();
      final plain = StoreSnapshot(
        settings: store.settings,
        vehicles: [
          Vehicle(
            id: _veh,
            name: 'Plain',
            vehicleType: VehicleType.car,
            fuelKindDefault: FuelKind.diesel,
            status: VehicleStatus.active,
            createdAtUtcMs: 1,
            updatedAtUtcMs: 1,
          ),
        ],
      );

      await writeStoreSnapshot(db, plain);
      final after = await readStoreSnapshot(db);

      final vehicle = after.vehicles.single;
      expect(vehicle.currency, isNull);
      expect(vehicle.distanceUnit, isNull);
      expect(vehicle.volumeUnit, isNull);
      expect(vehicle.consumptionUnit, isNull);
    },
  );

  test('a service keeps its lines, in order', () async {
    await writeStoreSnapshot(db, _full());
    final after = await readStoreSnapshot(db);

    expect(after.services.single.lines, hasLength(1));
    expect(after.services.single.lines.single.partNumber, 'A-123');
    expect(after.services.single.lines.single.serviceItemId, _item);
  });
}
