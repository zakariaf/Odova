// The service item's invariants, in the schema.
//
// SPEC.md §3 Entities (`ServiceItem`), §3 Invariants and validation. The two
// that matter most are structural rather than enum checks: an item with no
// interval and no target can never come due, and a custom item with no label
// has nothing to show on a card. Both are silent failures — the row exists, it
// appears in the list, it can be edited, and it simply never fires.
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

  test('an item with an interval is accepted', () async {
    await expectLater(insertServiceItem(db), completes);
  });

  test('an item with no interval and no target is rejected', () async {
    await expectLater(
      insertServiceItem(db, intervalDistanceM: null),
      throwsA(isA<SqliteException>()),
    );

    // Any ONE of the four is enough.
    await expectLater(
      insertServiceItem(
        db,
        id: 'rem_m',
        intervalDistanceM: null,
        intervalMonths: 12,
      ),
      completes,
    );
    await expectLater(
      insertServiceItem(
        db,
        id: 'rem_t',
        intervalDistanceM: null,
        targetOdometerM: 120000000,
      ),
      completes,
    );
    await expectLater(
      insertServiceItem(
        db,
        id: 'rem_d',
        intervalDistanceM: null,
        targetDate: '2027-04-01',
      ),
      completes,
    );
  });

  test('rejects interval_distance_m = 0 and interval_months = 0', () async {
    // Zero is not "no interval" — null is. A zero interval is due
    // continuously, from the moment it is saved.
    await expectLater(
      insertServiceItem(db, intervalDistanceM: 0),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      insertServiceItem(
        db,
        id: 'rem_zm',
        intervalDistanceM: null,
        intervalMonths: 0,
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('a custom item without a label is rejected', () async {
    await expectLater(
      insertServiceItem(db, kind: 'custom'),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      insertServiceItem(db, id: 'rem_c', kind: 'custom', label: 'Ceramic coat'),
      completes,
    );
  });

  test('rejects a kind outside the 28, and accepts all 28', () async {
    await expectLater(
      insertServiceItem(db, kind: 'exorcism'),
      throwsA(isA<SqliteException>()),
    );

    for (final kind in ServiceKind.values) {
      await expectLater(
        insertServiceItem(
          db,
          id: 'rem_${kind.name}',
          kind: kind.wire,
          label: kind == ServiceKind.custom ? 'Named' : null,
        ),
        completes,
        reason: kind.wire,
      );
    }
  });

  test('rejects a priority or rollover outside its enum', () async {
    await expectLater(
      insertServiceItem(db, priority: 'urgent'),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      insertServiceItem(db, id: 'rem_r', rollover: 'from_whenever'),
      throwsA(isA<SqliteException>()),
    );
  });

  test('an item belongs to a live vehicle', () async {
    // Needs `foreign_keys = ON`, which Task 5.1's `beforeOpen` re-asserts on
    // every executor — including the in-memory ones these tests use, where a
    // cascade that is not enforced makes a passing test a lie.
    await expectLater(
      insertServiceItem(db, vehicleId: 'veh_does_not_exist'),
      throwsA(isA<SqliteException>()),
    );
  });

  test('has no mode, no rule, no lead_* and no notice_months', () async {
    // SPEC.md §3 says so by name. Which axes apply is DERIVED from which
    // interval fields are non-null; a stored `mode` is a second answer to a
    // question the data already answers, and the day it disagrees the engine
    // reads one and the screen shows the other.
    final columns = await db
        .customSelect('PRAGMA table_info(service_items);')
        .get();
    final names = columns.map((c) => c.read<String>('name')).toList();

    for (final banned in [
      'mode',
      'rule',
      'lead_distance_m',
      'lead_days',
      'lead_months',
      'notice_months',
    ]) {
      expect(names, isNot(contains(banned)), reason: banned);
    }
    // And the two that ARE the lead override are present.
    expect(names, containsAll(<String>['notice_distance_m', 'notice_days']));
  });
}
