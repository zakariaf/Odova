/// Rows for the timeline tests, seeded straight into the store.
///
/// SPEC.md §11's list is a UNION over five tables plus a divider, so a fixture
/// for it has to be able to put a row in any of them at a chosen date. Each
/// helper here seeds exactly the shape the test that calls it names, and
/// nothing else — a fixture that seeds "a typical vehicle" makes every
/// assertion depend on rows the test never mentions.
library;

import 'package:odova/data/db/app_database.dart';

import '../data/support/rows.dart';

/// The vehicle every helper here writes against.
const String historyVehicleId = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD';

/// A second vehicle, to prove a page never leaks across one.
const String otherVehicleId = 'veh_01JQ8ZK3M7F0R6XN2E9TOTHERX';

/// 26 Crockford characters minus the last, so a suffix completes a ULID.
const String _stem = '01K1C4V2H9B8N3Q7ZE5RY6TMW';
const String _crockford = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// The same stem one character shorter, for ids that vary in TWO places.
const String _stem24 = '01K1C4V2H9B8N3Q7ZE5RY6TM';

String _id(String prefix, int n) => '${prefix}_$_stem${_crockford[n % 32]}';

/// The vehicle the rest of the fixture hangs off.
Future<void> seedHistoryVehicle(AppDatabase db) => insertVehicle(db);

/// Two fills on one day, so the ULID tiebreak has something to break.
Future<void> seedSameDayFills(AppDatabase db) async {
  for (var i = 0; i < 3; i++) {
    await insertFillUp(
      db,
      id: _id('fil', i),
    );
  }
}

/// [count] fills on descending days, for the paging assertions.
Future<void> seedManyEntries(AppDatabase db, {required int count}) async {
  for (var i = 0; i < count; i++) {
    // Distinct DAYS, so the page boundary cannot be an artefact of a tie.
    final day = 1 + (i % 28);
    final month = 1 + (i ~/ 28);
    await insertFillUp(
      db,
      // A ULID is 26 Crockford characters. Two varying ones over a 24-char
      // stem gives 1,024 distinct ids — the first version appended two to a
      //25-char stem and truncated back to 26, which collapsed every id in a
      // block of 32 onto the same value.
      id: 'fil_$_stem24${_crockford[i ~/ 32]}${_crockford[i % 32]}',
      occurredOn:
          '2026-${month.toString().padLeft(2, '0')}-'
          '${day.toString().padLeft(2, '0')}',
    );
  }
}

/// A fill-up and the derived reading §3 says it emits.
Future<void> seedFillUpWithOdometer(AppDatabase db) async {
  await insertFillUp(db, id: _id('fil', 1));
  await insertReading(
    db,
    id: _id('odo', 1),
    source: 'fillup',
  );
}

/// A reading the user typed.
Future<void> seedManualReading(AppDatabase db) => insertReading(
  db,
  id: _id('odo', 2),
);

/// A fill-up that has been soft-deleted.
Future<void> seedDeletedFillUp(AppDatabase db) => insertFillUp(
  db,
  id: _id('fil', 3),
  deletedAtUtcMs: 2000,
);

/// A correction over a reading dated well before the correction itself.
Future<void> seedCorrectionOverReading(AppDatabase db) async {
  await insertReading(
    db,
    id: _id('odo', 4),
    occurredOn: '2026-03-12',
  );
  await db.customStatement(
    '''
      INSERT INTO odometer_corrections (
        id, vehicle_id, from_reading_id, previous_m, new_m, odometer_unit,
        reason, created_at_utc_ms, updated_at_utc_ms
      ) VALUES (?, ?, ?, 186000000, 187000000, 'km', 'cluster_replaced',
                9000, 9000);
    ''',
    [_id('cor', 5), historyVehicleId, _id('odo', 4)],
  );
  db.markTablesUpdated({db.odometerCorrections});
}

/// Rows on a second vehicle, which must never appear in the first's page.
Future<void> seedSecondVehicleEntries(AppDatabase db) async {
  await insertVehicle(db, id: otherVehicleId, name: 'The Other');
  await insertFillUp(db, id: _id('fil', 6));
  await insertFillUp(
    db,
    id: 'fil_${_stem24}OT',
    vehicleId: otherVehicleId,
  );
}

/// One fill in each of three months, for the month anchor.
Future<void> seedAcrossMonths(AppDatabase db) async {
  for (final (i, on) in ['2026-02-10', '2026-03-15', '2026-05-20'].indexed) {
    await insertFillUp(
      db,
      id: _id('fil', 10 + i),
      occurredOn: on,
    );
  }
}

/// One row of each kind, for the filter assertions.
Future<void> seedMixedKinds(AppDatabase db) async {
  await insertFillUp(db, id: _id('fil', 20));
  await insertExpense(db, id: _id('exp', 21));
  await insertReading(db, id: _id('odo', 22));
}
