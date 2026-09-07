// The whole file, end to end — SPEC.md §6 §2 and §7.
//
// Every assertion here is about a property of the DOCUMENT rather than of one
// projection, because that is where §6's promises live: byte-determinism,
// ASCII digits, no bidi controls, and a hash over the bytes as written.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/store_snapshot.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/features/backup/domain/backup_format.dart';
import 'package:odova/features/backup/domain/backup_writer.dart';
import 'package:odova/features/backup/domain/content_hash.dart';
import 'package:test/test.dart';

final Currency _eur = Currency.tryParse('EUR')!;
final Currency _irr = Currency.tryParse('IRR')!;
final VehicleId _veh = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD')!;
final VehicleId _veh2 = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVE')!;

// A pinned instant and a pinned zone, so `exported_at` is an assertion and not
// a wildcard. 2026-09-07T08:30:00Z is 10:30 in Berlin.
const int _exportedAtMs = 1788769800000;

BackupWriter _writer({Duration offset = const Duration(hours: 2)}) =>
    BackupWriter(
      nowUtcMs: _exportedAtMs,
      localOffset: offset,
      appVersion: '1.0.0',
      appBuild: '42',
      platform: 'android',
    );

StoreSnapshot _store({
  Currency? currency,
  String display = 'none',
  List<Vehicle> vehicles = const [],
  List<ServiceItem> reminders = const [],
  List<ServiceRecord> services = const [],
  List<FillUp> fillUps = const [],
  List<Expense> expenses = const [],
  List<Trip> trips = const [],
  List<OdometerReading> readings = const [],
}) => StoreSnapshot(
  settings: AppSettings(
    schemaVersion: 1,
    currencyDefault: currency ?? _eur,
    currencyDisplay: display,
    createdAtUtcMs: 0,
    updatedAtUtcMs: 0,
  ),
  vehicles: vehicles,
  reminders: reminders,
  services: services,
  fillUps: fillUps,
  expenses: expenses,
  trips: trips,
  odometerReadings: readings,
);

Vehicle _vehicle({
  VehicleId? id,
  String name = 'Golf',
  VehicleStatus status = VehicleStatus.active,
  String? notes,
}) => Vehicle(
  id: id ?? _veh,
  name: name,
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: status,
  notes: notes,
  createdAtUtcMs: 0,
  updatedAtUtcMs: 0,
);

FillUp _fill(String id, {Money? cost}) => FillUp(
  id: FillUpId.tryParse(id)!,
  vehicleId: _veh,
  occurredOn: '2026-07-29',
  odometerUnit: DistanceUnit.km,
  fuelKind: FuelKind.diesel,
  quantity: const LiquidVolume(Volume(44_020)),
  quantityUnit: VolumeUnit.l,
  totalCost: cost ?? Money(7351, _eur),
  createdAtUtcMs: 0,
  updatedAtUtcMs: 0,
);

/// Writes to a temp file and returns its raw bytes, hash-stamped.
Future<(File, List<int>)> _export(
  BackupWriter writer,
  StoreSnapshot store,
) async {
  final dir = await Directory.systemTemp.createTemp('odova_backup_test');
  addTearDown(() => dir.delete(recursive: true));
  final file = File('${dir.path}/backup.json');
  await writer.writeToFile(file, store);
  return (file, file.readAsBytesSync());
}

Future<Map<String, Object?>> _exportJson(
  BackupWriter writer,
  StoreSnapshot store,
) async {
  final (file, _) = await _export(writer, store);
  return json.decode(file.readAsStringSync()) as Map<String, Object?>;
}

void main() {
  group('the envelope', () {
    test("carries §6 §2.2's eleven keys, in that order", () async {
      final doc = await _exportJson(_writer(), _store());

      expect(doc.keys.take(kEnvelopeKeys.length).toList(), kEnvelopeKeys);
    });

    test('format is exactly odova.backup and format_version is 1', () async {
      final doc = await _exportJson(_writer(), _store());

      // The two fields a reader checks before parsing a single record, which
      // is what makes a 12,000-record file cheap to REFUSE.
      expect(doc['format'], 'odova.backup');
      expect(doc['format_version'], 1);
    });

    test('exported_at is UTC with Z and the local one carries the '
        'offset for the same instant', () async {
      final doc = await _exportJson(_writer(), _store());

      expect(doc['exported_at'], '2026-09-07T08:30:00Z');
      expect(doc['exported_at_local'], '2026-09-07T10:30:00+02:00');
    });

    test('a negative offset writes a minus, not a wrapped hour', () async {
      // Tehran is +03:30 and Newfoundland is -03:30; a half-hour zone with a
      // sign is the shape that a naive `hh:mm` formatter gets wrong.
      final doc = await _exportJson(
        _writer(offset: const Duration(hours: -3, minutes: -30)),
        _store(),
      );

      expect(doc['exported_at_local'], '2026-09-07T05:00:00-03:30');
    });

    test('record_counts matches the arrays and includes a total', () async {
      final doc = await _exportJson(
        _writer(),
        _store(
          vehicles: [_vehicle()],
          fillUps: [
            _fill('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH'),
            _fill('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GJ'),
          ],
        ),
      );

      final counts = doc['record_counts']! as Map<String, Object?>;
      expect(counts['vehicles'], 1);
      expect(counts['fillups'], 2);
      expect(counts['services'], 0);
      // Settings is one row and not a record; the total is over the arrays.
      expect(counts['total'], 3);
    });

    test('units and derived_fields are declared', () async {
      final doc = await _exportJson(_writer(), _store());

      expect(doc['units'], kBackupUnits);
      // §6: a reader must know which fields to RECOMPUTE rather than trust.
      expect(doc['derived_fields'], kDerivedFields);
      expect(
        doc['derived_fields'],
        containsAll(<String>[
          'reminders.last_done_date',
          'reminders.last_done_odometer_m',
          'reminders.last_done_service_id',
        ]),
      );
    });
  });

  group('the arrays', () {
    test('are settings, then parents before children', () async {
      final doc = await _exportJson(_writer(), _store());

      expect(doc.keys.skip(kEnvelopeKeys.length).toList(), [
        'settings',
        ...kBackupArrays,
      ]);
    });

    test('sort records by id, which for a ULID is creation order', () async {
      // Written out of order on purpose: the writer sorts, the caller does
      // not have to, and an importer reading in file order rebuilds the same
      // sequence on the other phone.
      final doc = await _exportJson(
        _writer(),
        _store(
          fillUps: [
            _fill('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GJ'),
            _fill('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH'),
          ],
        ),
      );

      expect(
        [for (final f in doc['fillups']! as List) (f as Map)['id']],
        [
          'fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH',
          'fil_01K1Y4T8R2E6W0Q3A7S1D5F9GJ',
        ],
      );
    });
  });

  group('determinism and the hash', () {
    test('two exports of unchanged data are byte-identical '
        'below settings', () async {
      final store = _store(
        vehicles: [
          _vehicle(),
          _vehicle(id: _veh2, name: 'Caddy'),
        ],
        fillUps: [_fill('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH')],
      );
      // Two DIFFERENT instants, so only the envelope can differ.
      final (_, first) = await _export(_writer(), store);
      final (_, second) = await _export(
        const BackupWriter(
          nowUtcMs: _exportedAtMs + 86_400_000,
          localOffset: Duration(hours: 2),
          appVersion: '1.0.0',
          appBuild: '42',
          platform: 'android',
        ),
        store,
      );

      String body(List<int> bytes) {
        final text = utf8.decode(bytes);
        return text.substring(text.indexOf('"settings"'));
      }

      expect(body(second), body(first));
    });

    test('content_hash is sha256 over the document with the field '
        'zeroed, and a verifier recomputes it', () async {
      final (file, bytes) = await _export(_writer(), _store());
      final text = utf8.decode(bytes);
      final doc = json.decode(text) as Map<String, Object?>;

      final hash = doc['content_hash']! as String;
      expect(hash, hasLength(kContentHashPlaceholder.length));
      expect(hash, isNot(kContentHashPlaceholder));
      expect(hash, matches(RegExp(r'^sha256:[0-9a-f]{64}$')));
      // The length is unchanged, so overwriting in place shifted no offsets:
      // a hash written as a shorter string would move every byte after it and
      // the document it certifies would not be the document on disk.
      expect(contentHashMatches(text), isTrue);
      expect(file.lengthSync(), bytes.length);
    });

    test('one changed byte in the body fails the check', () async {
      final (_, bytes) = await _export(
        _writer(),
        _store(vehicles: [_vehicle()]),
      );

      final tampered = utf8.decode(bytes).replaceFirst('"Golf"', '"Polo"');

      expect(contentHashMatches(tampered), isFalse);
    });
  });

  group('the bytes themselves', () {
    test('are UTF-8 with no BOM and real characters, not escapes', () async {
      final (_, bytes) = await _export(
        _writer(),
        _store(
          vehicles: [
            _vehicle(notes: 'Zahnriemen laut Werkstatt — یادداشت فارسی 🚗'),
          ],
        ),
      );

      expect(bytes.take(3), isNot([0xEF, 0xBB, 0xBF]));
      final text = utf8.decode(bytes);
      expect(text, contains('Zahnriemen laut Werkstatt'));
      expect(text, contains('یادداشت فارسی'));
      expect(text, contains('🚗'));
      expect(text, isNot(contains(r'\u')));
    });

    test('every digit is ASCII 0-9 even from a Persian, '
        'Jalali, toman store', () async {
      final (_, bytes) = await _export(
        _writer(),
        _store(
          currency: _irr,
          display: 'toman',
          vehicles: [_vehicle(notes: 'روغن موتور عوض شد')],
          fillUps: [
            _fill(
              'fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH',
              cost: Money(1_250_000, _irr),
            ),
          ],
        ),
      );

      final text = utf8.decode(bytes);
      // U+06F0–U+06F9 (extended Arabic-Indic) and U+0660–U+0669 (Arabic-Indic).
      expect(
        text,
        isNot(matches(RegExp('[۰-۹٠-٩]'))),
        reason: 'the writer must not reach for the display formatter',
      );
      expect(text, contains('1250000'));
    });

    test('every currency code in the file is the stored one, '
        'even under a toman display', () async {
      final (_, bytes) = await _export(
        _writer(),
        _store(
          currency: _irr,
          display: 'toman',
          fillUps: [
            _fill(
              'fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH',
              cost: Money(1_250_000, _irr),
            ),
          ],
        ),
      );

      final text = utf8.decode(bytes);
      // Toman is a LABEL over a rial amount. A file carrying the toman code
      // would be a file no ISO 4217 reader can price, and dividing by ten to
      // make it true would lose a digit of every Iranian amount ever recorded.
      //
      // The SET of codes is asserted rather than the absence of one string,
      // because `no_currency_conversion_test` greps the tree for that string
      // and would count this test's own assertion as the violation.
      final codes = RegExp(
        '"currency":"([A-Z]{3})"',
      ).allMatches(text).map((m) => m.group(1)).toSet();
      expect(codes, {'IRR'});
    });

    test('no bidi control character reaches the file', () async {
      // A note pasted out of the app carries the isolates the formatter put
      // round a number. In a backup they break search, sorting and the
      // read-it-in-a-text-editor property that is the whole point of §6.
      final (_, bytes) = await _export(
        _writer(),
        _store(
          vehicles: [
            _vehicle(
              name: '\u2068Golf\u2069',
              notes: '\u200f\u06f2 \u0644\u06cc\u062a\u0631',
            ),
          ],
        ),
      );

      final text = utf8.decode(bytes);
      expect(
        text,
        isNot(
          matches(
            RegExp('[\u200e\u200f\u061c\u202a-\u202e\u2066-\u2069]'),
          ),
        ),
      );
      expect(text, contains('Golf'));
    });
  });

  group('what never reaches the file', () {
    test(
      'deleted_at is null on every record and no row is a tombstone',
      () async {
        final (_, bytes) = await _export(
          _writer(),
          _store(
            vehicles: [_vehicle()],
            fillUps: [_fill('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH')],
          ),
        );

        final text = utf8.decode(bytes);
        expect(text, contains('"deleted_at":null'));
        expect(text, isNot(contains('"deleted_at":"')));
      },
    );

    test('photo_id, attachment_ids and last_backup_reminder_at '
        'are absent', () async {
      final (_, bytes) = await _export(
        _writer(),
        _store(
          vehicles: [_vehicle()],
          fillUps: [_fill('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH')],
        ),
      );

      final text = utf8.decode(bytes);
      for (final absent in [
        'photo_id',
        'attachment_ids',
        'last_backup_reminder_at',
      ]) {
        expect(text, isNot(contains(absent)), reason: absent);
      }
    });

    test(
      'there is no rule, no mode, no stored next-due and no total',
      () async {
        final (_, bytes) = await _export(
          _writer(),
          _store(
            vehicles: [_vehicle()],
            reminders: [
              ServiceItem(
                id: ServiceItemId.tryParse('rem_01JV7B5X4G2K9M6P0S3D8FNRTC')!,
                vehicleId: _veh,
                kind: ServiceKind.oilAndFilter,
                priority: ServicePriority.normal,
                rollover: ServiceRollover.fromActual,
                createdAtUtcMs: 0,
                updatedAtUtcMs: 0,
              ),
            ],
          ),
        );

        final text = utf8.decode(bytes);
        for (final absent in [
          '"rule"',
          '"mode"',
          'next_due_date',
          'next_due_odometer_m',
          'total_cost',
          'parts_cost',
          'labour_cost',
        ]) {
          expect(text, isNot(contains(absent)), reason: absent);
        }
      },
    );

    test('a reminder completed by a service carries all three '
        'last_done fields', () async {
      final item = ServiceItem(
        id: ServiceItemId.tryParse('rem_01JV7B5X4G2K9M6P0S3D8FNRTC')!,
        vehicleId: _veh,
        kind: ServiceKind.oilAndFilter,
        priority: ServicePriority.normal,
        rollover: ServiceRollover.fromActual,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      );
      final record = ServiceRecord(
        id: ServiceRecordId.tryParse('srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX')!,
        vehicleId: _veh,
        occurredOn: '2026-05-22',
        odometer: const Distance(212_000_000),
        odometerUnit: DistanceUnit.km,
        lines: [
          ServiceLine(
            id: ServiceLineId.tryParse('lin_01K0C4V2H9B8N3Q7ZE5RY6TMX1')!,
            serviceRecordId: ServiceRecordId.tryParse(
              'srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX',
            )!,
            serviceItemId: item.id,
            label: 'Ölwechsel',
            amount: Money(9820, _eur),
          ),
        ],
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      );

      final doc = await _exportJson(
        _writer(),
        _store(
          vehicles: [_vehicle()],
          reminders: [item],
          services: [record],
        ),
      );

      final reminder = (doc['reminders']! as List).single as Map;
      expect(reminder['last_done_date'], '2026-05-22');
      expect(reminder['last_done_odometer_m'], 212_000_000);
      expect(reminder['last_done_service_id'], record.id.toString());
    });

    test('a reminder nothing has completed says null, never a guess', () async {
      final doc = await _exportJson(
        _writer(),
        _store(
          vehicles: [_vehicle()],
          reminders: [
            ServiceItem(
              id: ServiceItemId.tryParse('rem_01JV7B5X4G2K9M6P0S3D8FNRTC')!,
              vehicleId: _veh,
              kind: ServiceKind.brakeFluid,
              priority: ServicePriority.safety,
              rollover: ServiceRollover.fromActual,
              createdAtUtcMs: 0,
              updatedAtUtcMs: 0,
            ),
          ],
        ),
      );

      final reminder = (doc['reminders']! as List).single as Map;
      expect(reminder['last_done_date'], isNull);
      expect(reminder['last_done_odometer_m'], isNull);
      expect(reminder['last_done_service_id'], isNull);
    });
  });

  test('5,000 records serialise, hash and write in under 3 s', () async {
    // A soft floor on the TEST host, not the device target. It exists to catch
    // an accidental O(n²) — a `String +=` per record, or a re-sort inside the
    // loop — which is the only kind of slowness that turns a 12,000-record
    // store into a hang rather than a wait.
    final fills = [
      for (var i = 0; i < 5000; i++)
        _fill('fil_01K1Y4T8R2E6W0Q3A7S1D5F${_suffix(i)}'),
    ];

    final started = DateTime.now();
    final (file, _) = await _export(
      _writer(),
      _store(vehicles: [_vehicle()], fillUps: fills),
    );
    final elapsed = DateTime.now().difference(started);

    expect(elapsed, lessThan(const Duration(seconds: 3)));
    expect(file.lengthSync(), greaterThan(100_000));
  });
}

/// Two Crockford base32 characters from [i]. No I, L, O or U.
String _suffix(int i) {
  const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  return '${alphabet[i ~/ 32 % 32]}${alphabet[i % 32]}'
      '${alphabet[i ~/ 1024 % 32]}';
}
