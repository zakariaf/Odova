// The four things a driver actually logs.
//
// SPEC.md §3 Entities (`ServiceRecord`, `ServiceLine`, `FillUp`, `Expense`,
// `Trip`), §3 Invariants and validation. Every rejection here comes back as a
// SQLite constraint error, because an invariant in Dart is one an import or a
// migration walks past.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/data/db/app_database.dart';

import '../../support/rows.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await insertVehicle(db);
  });
  tearDown(() => db.close());

  group('service records and lines', () {
    test('a record has no total column anywhere', () async {
      // Cost is ALWAYS the sum of the lines. A stored total drifts the first
      // time a line is edited, and then the history screen and the cost
      // dashboard disagree about what a service cost with no way to tell
      // which one is the receipt.
      final columns = await db
          .customSelect('PRAGMA table_info(service_records);')
          .get();
      final names = columns.map((c) => c.read<String>('name')).toList();

      for (final banned in [
        'total',
        'total_minor',
        'total_cost_minor',
        'amount_minor',
      ]) {
        expect(names, isNot(contains(banned)), reason: banned);
      }
    });

    test('a line amount below zero is rejected; zero is accepted', () async {
      // A warranty job is 0 — the model requires at least one line, so zero is
      // the only representable "not recorded". A refund is an Expense.
      await insertServiceRecord(db);
      await expectLater(
        insertServiceLine(db, amountMinor: -1),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(insertServiceLine(db, amountMinor: 0), completes);
    });

    test('deleting a record takes its lines with it', () async {
      await insertServiceRecord(db);
      await insertServiceLine(db);
      await db.customStatement('DELETE FROM service_records;');

      final lines = await db.customSelect('SELECT * FROM service_lines;').get();
      expect(lines, isEmpty);
    });

    test(
      'deleting a service item sets its lines to null, keeping them',
      () async {
        // SPEC.md §3: deleting a ServiceItem never touches history. Every
        // referencing line is rewritten to null and KEEPS its label and amount.
        // A cascade here would delete the record of work that was actually done
        // because the user tidied up a reminder.
        await insertServiceItem(db);
        await insertServiceRecord(db);
        await insertServiceLine(
          db,
          serviceItemId: 'rem_01JV7B5X4G2K9M6P0S3D8FNRTC',
        );

        await db.customStatement('DELETE FROM service_items;');

        final line = await db
            .customSelect('SELECT * FROM service_lines;')
            .getSingle();
        expect(line.data['service_item_id'], isNull);
        expect(line.read<String>('label'), 'Oil and filter');
        expect(line.read<int>('amount_minor'), 8900);
      },
    );
  });

  group('fill-ups', () {
    test('carries exactly one quantity', () async {
      // Two is a row that means two things; none is a fill-up with no fuel in
      // it. Both break the consumption maths silently rather than loudly.
      await expectLater(insertFillUp(db), completes);

      await expectLater(
        insertFillUp(db, id: 'fil_none', quantityMl: null),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        insertFillUp(db, id: 'fil_two', quantityG: 12000),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        insertFillUp(
          db,
          id: 'fil_g',
          fuelKind: 'cng',
          quantityMl: null,
          quantityG: 12000,
        ),
        completes,
      );
      await expectLater(
        insertFillUp(
          db,
          id: 'fil_wh',
          fuelKind: 'electric',
          quantityMl: null,
          energyWh: 52000,
        ),
        completes,
      );
    });

    test('the quantity matches the fuel kind', () async {
      // CNG is sold by mass and electricity by energy. Without this an
      // electric fill-up could carry millilitres, and consumption would come
      // out as litres per 100 km for a car with no tank.
      await expectLater(
        insertFillUp(db, id: 'fil_ev_ml', fuelKind: 'electric'),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        insertFillUp(db, id: 'fil_cng_ml', fuelKind: 'cng'),
        throwsA(isA<SqliteException>()),
      );
    });

    test('total_cost below zero is rejected; zero is accepted', () async {
      await expectLater(
        insertFillUp(db, totalCostMinor: -1),
        throwsA(isA<SqliteException>()),
      );
      // A free fill is a fact. A loyalty voucher, a company card, a friend.
      await expectLater(
        insertFillUp(db, id: 'fil_free', totalCostMinor: 0),
        completes,
      );
    });

    test('a quantity of zero is rejected', () async {
      // Zero litres is not a fill-up, and it divides into the consumption
      // maths.
      await expectLater(
        insertFillUp(db, quantityMl: 0),
        throwsA(isA<SqliteException>()),
      );
    });

    test('there is no unit-price column', () async {
      // The form takes any two of {total, quantity, price per unit} and
      // computes the third; only total and quantity persist. Store all three
      // and they will one day disagree, and then nobody knows which is the
      // receipt.
      final columns = await db
          .customSelect('PRAGMA table_info(fill_ups);')
          .get();
      final names = columns.map((c) => c.read<String>('name')).toList();

      for (final banned in [
        'unit_price',
        'unit_price_minor',
        'price_per_unit',
        'price_per_litre_minor',
      ]) {
        expect(names, isNot(contains(banned)), reason: banned);
      }
    });

    test('carries vehicle_id even when it carries trip_id', () async {
      // Denormalised on purpose: every non-global entity carries vehicle_id
      // directly, so orphan detection on import is one pass (SPEC.md §3).
      await insertTrip(db);
      await expectLater(
        insertFillUp(db, tripId: 'trp_01K4C4V2H9B8N3Q7ZE5RY6TMWX'),
        completes,
      );

      final row = await db.customSelect('SELECT * FROM fill_ups;').getSingle();
      expect(row.read<String>('vehicle_id'), isNotEmpty);
      expect(row.read<String>('trip_id'), isNotEmpty);
    });

    test('every FuelKind spelling is accepted with its own quantity', () async {
      for (final kind in FuelKind.values) {
        await expectLater(
          insertFillUp(
            db,
            id: 'fil_${kind.name}',
            fuelKind: kind.wire,
            quantityMl: switch (kind) {
              FuelKind.electric || FuelKind.cng => null,
              _ => 45200,
            },
            quantityG: kind == FuelKind.cng ? 12000 : null,
            energyWh: kind == FuelKind.electric ? 52000 : null,
          ),
          completes,
          reason: kind.wire,
        );
      }
    });
  });

  group('expenses', () {
    test('an amount may be negative, and that is deliberate', () async {
      // The ONE money column in the schema with no `>= 0` check. A refund, a
      // warranty reimbursement or an insurance payout is money coming back,
      // and this row is the only way to say so. The test exists so nobody
      // later "fixes" the missing check.
      await expectLater(
        insertExpense(db, amountMinor: -12500),
        completes,
      );

      final row = await db.customSelect('SELECT * FROM expenses;').getSingle();
      expect(row.read<int>('amount_minor'), -12500);
    });

    test('category other without a label is rejected', () async {
      await expectLater(
        insertExpense(db, category: 'other'),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        insertExpense(
          db,
          id: 'exp_ok',
          category: 'other',
          label: 'Roof box hire',
        ),
        completes,
      );
    });

    test('covers_to before covers_from is rejected', () async {
      await expectLater(
        insertExpense(db, coversFrom: '2026-01-01', coversTo: '2025-12-31'),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        insertExpense(
          db,
          id: 'exp_win',
          coversFrom: '2026-01-01',
          coversTo: '2026-12-31',
        ),
        completes,
      );
    });

    test('every ExpenseCategory spelling is accepted', () async {
      for (final category in ExpenseCategory.values) {
        await expectLater(
          insertExpense(
            db,
            id: 'exp_${category.name}',
            category: category.wire,
            label: category == ExpenseCategory.other ? 'Named' : null,
          ),
          completes,
          reason: category.wire,
        );
      }
    });
  });

  group('trips', () {
    test('a trip ending before it started is rejected', () async {
      await expectLater(
        insertTrip(db, startedOn: '2026-09-03', endedOn: '2026-09-01'),
        throwsA(isA<SqliteException>()),
      );
      // An open trip has no end at all, and that is not a violation.
      await expectLater(
        insertTrip(db, id: 'trp_open', endedOn: null),
        completes,
      );
    });

    test('an end odometer below the start is rejected', () async {
      // Both endpoints are on the same cluster and the same scale, so this is
      // arithmetic. A genuine cluster change mid-trip is an
      // OdometerCorrection, not a backwards trip.
      await expectLater(
        insertTrip(db, startOdometerM: 186512000, endOdometerM: 186000000),
        throwsA(isA<SqliteException>()),
      );
    });

    test('every TripPurpose spelling is accepted', () async {
      for (final purpose in TripPurpose.values) {
        await expectLater(
          insertTrip(db, id: 'trp_${purpose.name}', purpose: purpose.wire),
          completes,
          reason: purpose.wire,
        );
      }
    });
  });
}
