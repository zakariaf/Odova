// Changing a unit preference changes no stored byte.
//
// SPEC.md §3 Canonical units: "Convert on read, never on write." EPIC-06 has a
// STRUCTURAL gate for this — `test/policy/no_conversion_on_write_test.dart`
// proves no file under `lib/data/` calls a conversion getter — and a structural
// gate proves nobody wrote the call it knows how to look for. It cannot prove
// the bytes hold still, because a conversion can arrive as arithmetic
// (`metres * 1609344 ~/ 1000` names no getter) or through a helper the regex
// does not recognise.
//
// This is the behavioural half, and it makes two separate claims, because one
// of them alone was not enough:
//
//   1. **The column holds the canonical value.** Every record here is entered
//      in MILES and in US GALLONS, and every stored column is asserted equal to
//      the metre and millilitre count that went in. This is what catches a
//      conversion written as arithmetic — `metres * 1000 ~/ 1609344` names no
//      getter and the structural gate cannot see it.
//   2. **Flipping the preference rewrites nothing.** SHA-256 over every row of
//      every table that holds a quantity, before and after every unit
//      preference the app has is changed, and changed back.
//
// Claim 2 alone does NOT imply claim 1: a conversion applied uniformly at write
// time is present in both digests and cancels. That was verified by planting
// one — storing miles in the metres column passed the digest test and the
// structural gate, and fails only the round-trip assertions below.
//
// The failure it prevents is silent and permanent: a fill-up stored in gallons
// because the form was in gallons reads back as litres for the next user, and
// eight years of consumption figures are wrong by a factor of 3.785 with
// nothing anywhere to say so. There is no server holding a correct copy.
@TestOn('vm')
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/log_repositories.dart';
import 'package:odova/data/repositories/odometer_repository.dart';
import 'package:odova/data/repositories/settings_repository.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';

import '../../support/values.dart';
import '../support/test_ids.dart';

const String _body = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
final VehicleId _vehicleId = VehicleId.tryParse('veh_$_body')!;

/// Every table that holds a quantity, a price or an odometer reading.
///
/// Named rather than discovered, so adding a table to the schema without
/// adding it here is a decision somebody has to make rather than a silent gap.
/// `settings` is deliberately absent: that IS where the preference lives, and
/// it is supposed to change.
const _quantityTables = [
  'vehicles',
  'fill_ups',
  'expenses',
  'trips',
  'odometer_readings',
  'odometer_corrections',
  'service_records',
  'service_lines',
  'service_items',
];

void main() {
  late AppDatabase db;
  late VehicleRepository vehicles;
  late FillUpRepository fillUps;
  late ExpenseRepository expenses;
  late TripRepository trips;
  late OdometerRepository odometers;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // ONE factory across all four, as `providers.dart` wires it. A separate
    // seeded `testIds()` per repository makes them all generate the same first
    // id, and the second derived odometer reading then collides on the primary
    // key — a failure that only appears when two kinds of record are written
    // in the same test, which is exactly what this one does.
    final ids = testIds();
    vehicles = VehicleRepository(db);
    fillUps = FillUpRepository(db, ids);
    expenses = ExpenseRepository(db, ids);
    trips = TripRepository(db, ids);
    odometers = OdometerRepository(db);
    settings = SettingsRepository(db);
  });

  tearDown(() => db.close());

  /// A digest over every row of every quantity-bearing table.
  ///
  /// Row VALUES, not the file: SQLite rewrites pages, moves free space and
  /// updates its change counter for reasons that have nothing to do with the
  /// data, so hashing the file would fail on a write that stored the same
  /// thing. Ordered by primary key so the digest does not depend on page
  /// layout either.
  Future<String> digestOfStoredData() async {
    final sink = <String>[];
    for (final table in _quantityTables) {
      final rows = await db
          .customSelect('SELECT * FROM $table ORDER BY id;')
          .get();
      for (final row in rows) {
        // The map's own key order comes from the column order in the schema,
        // which is stable; sorted anyway so a future column added in the
        // middle cannot change the digest without changing the data.
        final entries = row.data.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        sink.add(
          '$table{${entries.map((e) => '${e.key}=${e.value}').join(',')}}',
        );
      }
    }
    return sha256.convert(utf8.encode(sink.join('\n'))).toString();
  }

  /// Fails loudly on a refused write.
  ///
  /// A fixture that silently writes nothing makes every assertion below it
  /// vacuous, and `Result` makes that easy to do by accident — an `Err` is a
  /// value, not an exception, so an unchecked `await save(...)` looks like a
  /// successful write.
  Future<void> mustSave<T>(Future<Result<T, PersistFailure>> write) async {
    final result = await write;
    expect(result, isA<Ok<T, PersistFailure>>(), reason: '$result');
  }

  Future<void> writeAHistory() async {
    // A fresh database has no settings row — EPIC-05 leaves it to first run —
    // so the preference this test flips has to exist before it can be flipped.
    await mustSave(
      settings.save(
        AppSettings(
          schemaVersion: db.schemaVersion,
          currencyDefault: isoCurrency('EUR'),
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
      ),
    );

    await mustSave(
      vehicles.save(
        Vehicle(
          id: _vehicleId,
          name: 'The Golf',
          vehicleType: VehicleType.car,
          fuelKindDefault: FuelKind.diesel,
          status: VehicleStatus.active,
          // Entered in miles: the vehicle's own provenance unit, which is not
          // the display preference and must not follow it.
          distanceUnit: DistanceUnit.mi,
          purchaseOdometer: const Distance(120000000),
          purchasePrice: money(1850000, 'KWD'),
          tankCapacityMl: 55000,
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
      ),
    );

    await mustSave(
      fillUps.save(
        FillUp(
          id: FillUpId.tryParse('fil_$_body')!,
          vehicleId: _vehicleId,
          occurredOn: '2026-01-10',
          odometer: const Distance(186512000),
          odometerUnit: DistanceUnit.mi,
          fuelKind: FuelKind.diesel,
          quantity: const LiquidVolume(Volume(45200)),
          quantityUnit: VolumeUnit.galUs,
          totalCost: money(784500, 'JPY'),
          // The default, and named anyway: a segment closes on a full tank, and
          // this fill-up is the one the fuel engine would read.
          // ignore: avoid_redundant_argument_values
          isFullTank: true,
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
      ),
    );

    await mustSave(
      expenses.save(
        Expense(
          id: ExpenseId.tryParse('exp_$_body')!,
          vehicleId: _vehicleId,
          occurredOn: '2026-02-01',
          category: ExpenseCategory.insurance,
          amount: money(42000, 'ISK'),
          odometer: const Distance(187000000),
          odometerUnit: DistanceUnit.mi,
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
      ),
    );

    await mustSave(
      trips.save(
        Trip(
          id: TripId.tryParse('trp_$_body')!,
          vehicleId: _vehicleId,
          purpose: TripPurpose.business,
          startedOn: '2026-03-01',
          endedOn: '2026-03-05',
          startOdometer: const Distance(187100000),
          endOdometer: const Distance(187900000),
          odometerUnit: DistanceUnit.mi,
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
      ),
    );

    await mustSave(
      odometers.saveReading(
        OdometerReading(
          id: OdometerReadingId.tryParse('odo_$_body')!,
          vehicleId: _vehicleId,
          occurredOn: '2026-04-01',
          odometer: const Distance(188000000),
          odometerUnit: DistanceUnit.mi,
          source: OdometerSource.manual,
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
        vehicleUnit: DistanceUnit.mi,
      ),
    );
  }

  /// The current settings row, with the four unit preferences replaced.
  Future<AppSettings> settingsWith({
    required DistanceUnit distance,
    required VolumeUnit volume,
    required ConsumptionUnit consumption,
    required String currencyDisplay,
  }) async {
    final current =
        (await settings.read() as Ok<AppSettings, PersistFailure>).value;
    return AppSettings(
      schemaVersion: current.schemaVersion,
      currencyDefault: current.currencyDefault,
      createdAtUtcMs: current.createdAtUtcMs,
      updatedAtUtcMs: current.updatedAtUtcMs + 1,
      distanceUnit: distance,
      volumeUnit: volume,
      consumptionUnit: consumption,
      currencyDisplay: currencyDisplay,
    );
  }

  test('a column holds the canonical value, not the entry unit', () async {
    // Every record was entered in miles and US gallons. SPEC.md §3 stores
    // metres and millilitres, so the entry unit is PROVENANCE — kept in
    // `odometer_unit` and `quantity_unit` so the app can show the number the
    // user typed — and never a scale applied to the column.
    await writeAHistory();

    Future<Object?> cell(String table, String column, String id) async =>
        (await db
                .customSelect(
                  'SELECT $column FROM $table WHERE id = ?;',
                  variables: [Variable.withString(id)],
                )
                .getSingle())
            .data[column];

    expect(await cell('fill_ups', 'odometer_m', 'fil_$_body'), 186512000);
    expect(await cell('fill_ups', 'quantity_ml', 'fil_$_body'), 45200);
    expect(await cell('fill_ups', 'total_cost_minor', 'fil_$_body'), 784500);
    // The provenance survives beside it, which is the half that IS allowed to
    // say "miles".
    expect(await cell('fill_ups', 'odometer_unit', 'fil_$_body'), 'mi');
    expect(await cell('fill_ups', 'quantity_unit', 'fil_$_body'), 'gal_us');

    expect(await cell('expenses', 'odometer_m', 'exp_$_body'), 187000000);
    expect(await cell('expenses', 'amount_minor', 'exp_$_body'), 42000);
    expect(await cell('trips', 'start_odometer_m', 'trp_$_body'), 187100000);
    expect(await cell('trips', 'end_odometer_m', 'trp_$_body'), 187900000);
    expect(
      await cell('vehicles', 'purchase_odometer_m', 'veh_$_body'),
      120000000,
    );
    expect(
      await cell('vehicles', 'purchase_price_minor', 'veh_$_body'),
      1850000,
    );
    expect(
      await cell('odometer_readings', 'odometer_m', 'odo_$_body'),
      188000000,
    );
  });

  test('flipping every unit preference rewrites no stored quantity', () async {
    await writeAHistory();
    final before = await digestOfStoredData();

    // Kilometres to miles, litres to imperial gallons, L/100km to mpg (imp),
    // and rials to tomans. Four different KINDS of conversion: a distance
    // ratio, a volume ratio, an INVERTED ratio, and a divide-by-ten. If any of
    // them ran on the way to a column, this digest moves.
    final flipped = await settingsWith(
      distance: DistanceUnit.mi,
      volume: VolumeUnit.galUk,
      consumption: ConsumptionUnit.mpgUk,
      currencyDisplay: 'toman',
    );
    expect(
      await settings.save(flipped),
      isA<Ok<AppSettings, PersistFailure>>(),
    );

    expect(
      await digestOfStoredData(),
      before,
      reason:
          'a unit preference changed a stored quantity — SPEC.md §3 converts '
          'on READ, and a converted value in a column is wrong forever',
    );
  });

  test('and flipping them back is not a second conversion either', () async {
    // A round trip is the version of this bug that survives a spot check: one
    // conversion each way cancels on the number a test happens to look at, and
    // does not cancel on the rounding.
    await writeAHistory();
    final before = await digestOfStoredData();

    for (final (distance, volume, consumption, display) in const [
      (DistanceUnit.mi, VolumeUnit.galUs, ConsumptionUnit.mpgUs, 'toman'),
      (DistanceUnit.km, VolumeUnit.l, ConsumptionUnit.lPer100km, 'none'),
      (DistanceUnit.mi, VolumeUnit.galUk, ConsumptionUnit.kmPerL, 'none'),
      (DistanceUnit.km, VolumeUnit.l, ConsumptionUnit.lPer100km, 'none'),
    ]) {
      await mustSave(
        settings.save(
          await settingsWith(
            distance: distance,
            volume: volume,
            consumption: consumption,
            currencyDisplay: display,
          ),
        ),
      );
    }

    expect(await digestOfStoredData(), before);
  });

  test('the digest actually notices a changed quantity', () async {
    // Guard the guard. A digest computed over the wrong thing — an empty
    // table list, a query that returns nothing — is equal to itself and
    // reports every test above as passing.
    await writeAHistory();
    final before = await digestOfStoredData();

    await db.customStatement(
      'UPDATE fill_ups SET quantity_ml = 45201 WHERE id = ?;',
      [
        'fil_$_body',
      ],
    );

    expect(
      await digestOfStoredData(),
      isNot(before),
      reason: 'one millilitre must move the digest',
    );
  });

  test('the digest covers every table that holds a quantity', () async {
    // The table list is hand-written, so this asserts it against the schema:
    // any table with a metre, millilitre, gram, watt-hour or minor-unit
    // column must be in it. A new table added by a later epic fails here
    // rather than quietly falling outside the guarantee.
    final tables =
        (await db
                .customSelect(
                  "SELECT name FROM sqlite_schema WHERE type = 'table' "
                  "AND name NOT LIKE 'sqlite_%';",
                )
                .get())
            .map((r) => r.read<String>('name'))
            .toList();

    final missing = <String>[];
    for (final table in tables) {
      if (table == 'settings' || _quantityTables.contains(table)) continue;
      final columns =
          (await db.customSelect('PRAGMA table_info($table);').get())
              .map((r) => r.read<String>('name'))
              .toList();
      final quantityColumns = columns.where(
        (c) =>
            c.endsWith('_m') ||
            c.endsWith('_ml') ||
            c.endsWith('_g') ||
            c.endsWith('_wh') ||
            c.endsWith('_minor'),
      );
      if (quantityColumns.isNotEmpty) {
        missing.add('$table: ${quantityColumns.join(', ')}');
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          'these tables hold quantities and are outside the digest, so a '
          'conversion could rewrite them unnoticed',
    );
  });
}
