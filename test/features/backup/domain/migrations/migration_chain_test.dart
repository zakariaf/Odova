// SPEC.md §6 §3.1's chain, and the defaults it mostly consists of.
//
// The chain is PURE `json → json`, applied in memory before anything touches
// the database. That is not an optimisation: a migration that could write would
// be a migration that can half-write, and a half-migrated import is the exact
// failure §2 says is the worst bug this app can have.
//
// v1 is the only real version today, so the loop itself is tested with two
// synthetic migrations registered by the test. Without that, `runMigrations`
// would be a `while` loop nobody had ever seen iterate.
@TestOn('vm')
library;

import 'dart:io';

import 'package:odova/features/backup/domain/backup_format.dart';
import 'package:odova/features/backup/domain/migrations/migrations.dart';
import 'package:odova/features/backup/domain/migrations/v0_defaults.dart';
import 'package:test/test.dart';

Map<String, Object?> _doc({
  int version = 1,
  Map<String, Object?> overrides = const {},
}) => {
  'format': 'odova.backup',
  'format_version': version,
  'settings': const <String, Object?>{},
  'vehicles': const <Object?>[],
  'reminders': const <Object?>[],
  'services': const <Object?>[],
  ...overrides,
};

Map<String, Object?> _first(Map<String, Object?> doc, String array) =>
    (doc[array]! as List).first as Map<String, Object?>;

void main() {
  group('the chain', () {
    test('runs 1→2→…→supported and stamps the version at each step', () {
      // Two synthetic migrations, so the LOOP is exercised while v1 is the
      // only version that exists. A chain nobody has watched iterate is a
      // `while` that might as well be an `if`.
      final seen = <int>[];
      final doc = runMigrations(
        _doc(),
        to: 3,
        migrations: {
          1: (json) {
            seen.add(json['format_version']! as int);
            return {...json, 'added_in_v2': true};
          },
          2: (json) {
            seen.add(json['format_version']! as int);
            return {...json, 'added_in_v3': true};
          },
        },
      );

      expect(seen, [1, 2]);
      expect(doc['format_version'], 3);
      expect(doc['added_in_v2'], isTrue);
      expect(doc['added_in_v3'], isTrue);
    });

    test('a document already at the supported version is untouched', () {
      final before = _doc();
      final after = runMigrations(before);

      expect(after, before);
    });

    test('a missing step is a programmer error, not a silent skip', () {
      // A gap in the map means a version was shipped and its migration was
      // forgotten — which would otherwise present as a v2 file quietly
      // imported as if it were v3.
      expect(
        () => runMigrations(
          _doc(),
          to: 3,
          migrations: {1: (json) => json},
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('no migration can perform I/O, by construction', () {
      // The epic asks for a fake filesystem that records zero opens. This is
      // the stronger form of the same assertion and the one that cannot be
      // fooled: a file that does not IMPORT `dart:io` has no filesystem to
      // touch, whatever a future migration's author intends.
      for (final path in [
        'lib/features/backup/domain/migrations/migrations.dart',
        'lib/features/backup/domain/migrations/v0_defaults.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(source, isNot(contains('dart:io')), reason: path);
        expect(source, isNot(contains('package:drift')), reason: path);
        expect(source, isNot(contains('package:flutter')), reason: path);
      }
    });

    test('the real chain is complete up to the supported version', () {
      // The one assertion that will fail on the day someone bumps
      // `kSupportedFormatVersion` without writing the migration.
      for (var v = 1; v < kSupportedFormatVersion; v++) {
        expect(kMigrations[v], isNotNull, reason: 'no migration for v$v');
      }
    });
  });

  group('§6 §3.1 rule 2 — never fail on missing data', () {
    test('a vehicle gets its status from the old archived boolean', () {
      // The boolean is READ and then dropped. A vehicle the user archived
      // years ago must not come back as active in their garage.
      Map<String, Object?> statusOf(Object? archived) => _first(
        fillDefaults(
          _doc(
            overrides: {
              'vehicles': [
                {
                  'id': 'v',
                  'name': 'Golf',
                  'archived': ?archived,
                },
              ],
            },
          ),
        ),
        'vehicles',
      );

      expect(statusOf(true)['status'], 'archived');
      expect(statusOf(false)['status'], 'active');
      expect(statusOf(null)['status'], 'active');
      expect(statusOf(true).containsKey('archived'), isFalse);
    });

    test('an explicit status is not overwritten by the boolean', () {
      // `sold` is a third value the boolean cannot express, and a file that
      // has it is newer than the boolean it also carries.
      final vehicle = _first(
        fillDefaults(
          _doc(
            overrides: {
              'vehicles': [
                {'id': 'v', 'name': 'Golf', 'status': 'sold', 'archived': true},
              ],
            },
          ),
        ),
        'vehicles',
      );

      expect(vehicle['status'], 'sold');
    });

    test('every vehicle default from §3.1 lands', () {
      final vehicle = _first(
        fillDefaults(
          _doc(
            overrides: {
              'vehicles': [
                {'id': 'v', 'name': 'Golf'},
              ],
            },
          ),
        ),
        'vehicles',
      );

      expect(vehicle['type'], 'car');
      expect(vehicle['is_business'], isFalse);
      expect(vehicle['notifications_muted'], isFalse);
    });

    test('every reminder default from §3.1 lands', () {
      final reminder = _first(
        fillDefaults(
          _doc(
            overrides: {
              'reminders': [
                {'id': 'r', 'vehicle_id': 'v'},
              ],
            },
          ),
        ),
        'reminders',
      );

      expect(reminder['notify'], isTrue);
      expect(reminder['repeats'], isTrue);
      expect(reminder['is_active'], isTrue);
      expect(reminder['is_tracked'], isTrue);
      expect(reminder['priority'], 'normal');
      expect(reminder['rollover'], 'from_actual');
      expect(reminder['snooze_count'], 0);
    });

    test('every service default from §3.1 lands', () {
      final service = _first(
        fillDefaults(
          _doc(
            overrides: {
              'services': [
                {'id': 's', 'vehicle_id': 'v'},
              ],
            },
          ),
        ),
        'services',
      );

      expect(service['odometer_estimated'], isFalse);
      expect(service['cost_estimated'], isFalse);
    });

    test('every settings default from §3.1 lands', () {
      final settings =
          fillDefaults(_doc())['settings']! as Map<String, Object?>;

      expect(settings['quiet_hours_from'], '21:00');
      expect(settings['quiet_hours_to'], '08:00');
      expect(settings['weekdays_only'], isFalse);
      expect(settings['notify_service'], isTrue);
      expect(settings['notify_odometer'], isTrue);
      expect(settings['notify_backup'], isTrue);
    });

    test('currency_display defaults to toman for a Persian file', () {
      // §5's one locale-dependent default. A file from a Persian phone with no
      // `currency_display` was written before the field existed, and on that
      // phone the amounts were being read as toman.
      Object? displayFor(String language) =>
          (fillDefaults(
                _doc(
                  overrides: {
                    'settings': {'language': language},
                  },
                ),
              )['settings']!
              as Map<String, Object?>)['currency_display'];

      expect(displayFor('fa'), 'toman');
      expect(displayFor('en'), 'none');
      expect(displayFor('ar'), 'none');
    });

    test('a value the file already carries is never overwritten', () {
      final settings =
          fillDefaults(
                _doc(
                  overrides: {
                    'settings': {
                      'quiet_hours_from': '23:30',
                      'notify_service': false,
                    },
                  },
                ),
              )['settings']!
              as Map<String, Object?>;

      expect(settings['quiet_hours_from'], '23:30');
      expect(settings['notify_service'], isFalse);
    });
  });

  group('§6 §3.1 — the retired rule field', () {
    test('distance_only clears the month interval', () {
      final reminder = _first(
        fillDefaults(
          _doc(
            overrides: {
              'reminders': [
                {
                  'id': 'r',
                  'rule': 'distance_only',
                  'interval_distance_m': 15_000_000,
                  'interval_months': 12,
                },
              ],
            },
          ),
        ),
        'reminders',
      );

      expect(reminder['interval_months'], isNull);
      expect(reminder['interval_distance_m'], 15_000_000);
      expect(reminder.containsKey('rule'), isFalse);
    });

    test('date_only clears the distance interval', () {
      final reminder = _first(
        fillDefaults(
          _doc(
            overrides: {
              'reminders': [
                {
                  'id': 'r',
                  'rule': 'date_only',
                  'interval_distance_m': 15_000_000,
                  'interval_months': 12,
                },
              ],
            },
          ),
        ),
        'reminders',
      );

      expect(reminder['interval_distance_m'], isNull);
      expect(reminder['interval_months'], 12);
    });

    test('whichever_last keeps both intervals and is counted', () {
      // It becomes an ordinary whichever-comes-FIRST reminder, which is a
      // behaviour change the user has to be told about — that is what the
      // count is for. Clearing an interval instead would be losing a value.
      final result = countDroppedRules(
        _doc(
          overrides: {
            'reminders': [
              {
                'id': 'a',
                'rule': 'whichever_last',
                'interval_distance_m': 15_000_000,
                'interval_months': 12,
              },
              {'id': 'b', 'rule': 'distance_only'},
              {'id': 'c'},
            ],
          },
        ),
      );

      expect(result, 1);
      final reminder = _first(
        fillDefaults(
          _doc(
            overrides: {
              'reminders': [
                {
                  'id': 'a',
                  'rule': 'whichever_last',
                  'interval_distance_m': 15_000_000,
                  'interval_months': 12,
                },
              ],
            },
          ),
        ),
        'reminders',
      );
      expect(reminder['interval_distance_m'], 15_000_000);
      expect(reminder['interval_months'], 12);
    });
  });

  test('§6 §3.1 rule 1 — no user string is lost', () {
    // A property over the shape rather than one field: every string the USER
    // typed that is in the document before the chain is in it afterwards.
    //
    // User-typed, not every string. `rule: "whichever_last"` is a value the
    // app wrote and §3.1 retires it on purpose — the rule §3.1 states is about
    // the user's content, and asserting over machine values would forbid the
    // migration the spec asks for.
    final before = _doc(
      overrides: {
        'vehicles': [
          {
            'id': 'v',
            'name': 'VW Käfer',
            'notes': 'Zahnriemen laut Werkstatt',
            'archived': true,
            'plate': 'M-AB 1234',
          },
        ],
        'reminders': [
          {'id': 'r', 'rule': 'whichever_last', 'notes': 'یادداشت فارسی'},
        ],
        'settings': const {'language': 'fa'},
      },
    );

    final after = fillDefaults(before);

    for (final text in _strings(before)) {
      expect(_strings(after), contains(text), reason: text);
    }
  });
}

/// Every string the user could have TYPED, anywhere in the node.
///
/// Free-text fields only. An id, an enum wire value and a date are the app's
/// own vocabulary; a name, a note and a plate are somebody's afternoon.
const Set<String> _userTextFields = {
  'name',
  'notes',
  'label',
  'plate',
  'vin',
  'colour',
  'make',
  'model',
  'vendor',
  'station',
  'grade',
  'title',
  'invoice_ref',
  'part_number',
};

Set<String> _strings(Object? node) => switch (node) {
  final Map<String, Object?> map => {
    for (final entry in map.entries)
      if (entry.value is String && _userTextFields.contains(entry.key))
        entry.value! as String
      else
        ..._strings(entry.value),
  },
  final List<Object?> list => {for (final item in list) ..._strings(item)},
  _ => const {},
};
