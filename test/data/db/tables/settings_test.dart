// One settings row, and every enum on it checked.
//
// SPEC.md §3 Entities (`Settings`), §3 Scope. A second row would give the app
// two answers about which vehicle is active, and nothing above the database
// would notice which one it read.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/data/db/app_database.dart';

import '../../support/rows.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('there is exactly one settings row', () async {
    await expectLater(insertSettings(db), completes);

    // A second row with the same id fails the primary key; a second row with
    // any OTHER id fails the CHECK. Both, because a repository that generated
    // a fresh id would hit the second and not the first.
    await expectLater(insertSettings(db), throwsA(isA<SqliteException>()));
    await expectLater(
      insertSettings(db, id: 'settings_2'),
      throwsA(isA<SqliteException>()),
    );
  });

  test('every settings enum is checked', () async {
    final cases = <String, (String good, String bad)>{
      'language': ('fa', 'kl'),
      'calendar': ('persian', 'hijri'),
      'numerals': ('extended_arabic_indic', 'persian'),
      'theme': ('dark', 'oled'),
      'currency_display': ('toman', 'rial'),
      'distance_unit': ('mi', 'furlong'),
      'volume_unit': ('gal_uk', 'pint'),
      'consumption_unit': ('kwh_100km', 'l_per_mile'),
    };

    for (final MapEntry(key: column, value: (good, bad)) in cases.entries) {
      await db.customStatement('DELETE FROM settings;');
      await expectLater(
        _insert(db, column, good),
        completes,
        reason: '$column = $good should be accepted',
      );

      await db.customStatement('DELETE FROM settings;');
      await expectLater(
        _insert(db, column, bad),
        throwsA(isA<SqliteException>()),
        reason: '$column = $bad should be rejected',
      );
    }
  });

  test(
    'consumption_unit accepts all six, including the two electric ones',
    () async {
      // `kwh_100km` and `mi_kwh` are the two a petrol-only reading of the spec
      // drops, and an EV owner is exactly the user who notices.
      for (final unit in ConsumptionUnit.values) {
        await db.customStatement('DELETE FROM settings;');
        await expectLater(
          insertSettings(db, consumptionUnit: unit.wire),
          completes,
          reason: unit.wire,
        );
      }
    },
  );

  test('a currency code is three characters', () async {
    await expectLater(
      insertSettings(db, currencyDefault: 'EU'),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      insertSettings(db, currencyDefault: 'EURO'),
      throwsA(isA<SqliteException>()),
    );
  });

  test('a time of day is minutes, and is bounded to a day', () async {
    // Minutes after local midnight, not a DateTime: it is a LOCAL time of day
    // and not an instant, so storing it as one would move it when the user
    // crosses a zone. 09:00 stays 09:00 in Tehran and in Toronto.
    await insertSettings(db);
    await expectLater(
      db.customStatement(
        'UPDATE settings SET notification_time_minutes = 1440 '
        "WHERE id = 'settings';",
      ),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      db.customStatement(
        'UPDATE settings SET notification_time_minutes = 1439 '
        "WHERE id = 'settings';",
      ),
      completes,
    );
  });
}

/// Inserts a settings row with one column overridden.
Future<void> _insert(AppDatabase db, String column, String value) =>
    switch (column) {
      'language' => insertSettings(db, language: value),
      'calendar' => insertSettings(db, calendar: value),
      'numerals' => insertSettings(db, numerals: value),
      'theme' => insertSettings(db, theme: value),
      'currency_display' => insertSettings(db, currencyDisplay: value),
      'distance_unit' => insertSettings(db, distanceUnit: value),
      'volume_unit' => insertSettings(db, volumeUnit: value),
      'consumption_unit' => insertSettings(db, consumptionUnit: value),
      _ => throw ArgumentError.value(column, 'column', 'not in the matrix'),
    };
