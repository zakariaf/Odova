// SPEC.md §6 §8.1's two exports, against a real parser.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/features/backup/domain/csv/costs_csv.dart';
import 'package:odova/features/backup/domain/csv/csv_file.dart';
import 'package:odova/features/backup/domain/csv/csv_writer.dart';
import 'package:odova/features/backup/domain/csv/fillups_csv.dart';
import 'package:test/test.dart';

final Currency _eur = Currency.tryParse('EUR')!;
final Currency _gbp = Currency.tryParse('GBP')!;
final VehicleId _veh = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD')!;

const CsvUnits _metric = (
  distance: DistanceUnit.km,
  volume: VolumeUnit.l,
  consumption: ConsumptionUnit.lPer100km,
);
const CsvUnits _imperial = (
  distance: DistanceUnit.mi,
  volume: VolumeUnit.galUs,
  consumption: ConsumptionUnit.mpgUs,
);

Vehicle _vehicle({String name = 'Golf'}) => Vehicle(
  id: _veh,
  name: name,
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  tankCapacityMl: 55_000,
  createdAtUtcMs: 0,
  updatedAtUtcMs: 0,
);

/// Three Crockford base32 characters. No I, L, O or U.
String _suffix(int i) {
  const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  return '${alphabet[i ~/ 1024 % 32]}${alphabet[i ~/ 32 % 32]}'
      '${alphabet[i % 32]}';
}

FillUp _fill({
  required int index,
  required String occurredOn,
  int millilitres = 45_000,
  int minor = 7351,
  bool full = true,
  String? notes,
  String? station,
}) => FillUp(
  id: FillUpId.tryParse('fil_01K1Y4T8R2E6W0Q3A7S1D5F${_suffix(index)}')!,
  vehicleId: _veh,
  occurredOn: occurredOn,
  odometerUnit: DistanceUnit.km,
  fuelKind: FuelKind.diesel,
  quantity: LiquidVolume(Volume(millilitres)),
  quantityUnit: VolumeUnit.l,
  totalCost: Money(minor, _eur),
  isFullTank: full,
  station: station,
  notes: notes,
  createdAtUtcMs: index,
  updatedAtUtcMs: index,
);

List<List<dynamic>> _parse(String text) =>
    const CsvToListConverter(shouldParseNumbers: false).convert(text);

void main() {
  test("the fill-ups header is §8.1's, exactly", () {
    expect(kFillUpsCsvHeader, [
      'date',
      'vehicle',
      'odometer',
      'odometer_unit',
      'quantity',
      'quantity_unit',
      'price_per_unit',
      'total_cost',
      'currency',
      'is_full_tank',
      'chain_broken',
      'grade',
      'distance_since_last',
      'consumption',
      'consumption_unit',
      'station',
      'notes',
    ]);
  });

  test("the all-costs header is §8.1's, exactly", () {
    expect(kCostsCsvHeader, [
      'date',
      'vehicle',
      'type',
      'category',
      'label',
      'vendor',
      'odometer',
      'odometer_unit',
      'amount',
      'currency',
      'notes',
    ]);
  });

  test('every fill-up row has exactly as many cells as the header', () {
    // A row with the wrong count puts every value after the gap under the
    // wrong header, and a CSV has no way to notice.
    final rows = fillUpCsvRows(
      vehicle: _vehicle(),
      fillUps: [
        _fill(index: 0, occurredOn: '2026-01-01'),
        _fill(index: 1, occurredOn: '2026-02-01', full: false),
      ],
      cumulativeMetres: const {},
      units: _metric,
    );

    for (final row in rows) {
      expect(row, hasLength(kFillUpsCsvHeader.length));
    }
  });

  test("the derived columns are computed, in the user's own units", () {
    // §8.1: "the point of a CSV is having the numbers without rewriting the
    // formula". A miles-and-gallons user gets miles and MPG US, not a
    // converted metre value.
    final fills = [
      _fill(index: 0, occurredOn: '2026-01-01'),
      _fill(index: 1, occurredOn: '2026-02-01'),
    ];
    final cumulative = {
      fills[0].id.toString(): 100_000_000,
      fills[1].id.toString(): 100_500_000,
    };

    final metric = fillUpCsvRows(
      vehicle: _vehicle(),
      fillUps: fills,
      cumulativeMetres: cumulative,
      units: _metric,
    );
    final imperial = fillUpCsvRows(
      vehicle: _vehicle(),
      fillUps: fills,
      cumulativeMetres: cumulative,
      units: _imperial,
    );

    const distanceColumn = 12;
    const consumptionColumn = 13;
    const consumptionUnitColumn = 14;

    // 500 km between the two fills.
    expect(metric[1][distanceColumn], '500.0');
    // The same distance in miles.
    expect(double.parse(imperial[1][distanceColumn]), closeTo(310.7, 0.1));
    // 45 L over 500 km is 9.00 L/100 km.
    expect(metric[1][consumptionColumn], '9.00');
    expect(metric[1][consumptionUnitColumn], 'l_100km');
    // The same segment as MPG US is about 26.1.
    expect(double.parse(imperial[1][consumptionColumn]), closeTo(26.1, 0.2));
    expect(imperial[1][consumptionUnitColumn], 'mpg_us');
  });

  test('the first fill has no distance since last, and no consumption', () {
    // §1 forbids guessing in a way that looks like fact. An empty cell is a
    // fact; a zero is a claim.
    final rows = fillUpCsvRows(
      vehicle: _vehicle(),
      fillUps: [_fill(index: 0, occurredOn: '2026-01-01')],
      cumulativeMetres: const {},
      units: _metric,
    );

    expect(rows.single[12], '');
    expect(rows.single[13], '');
  });

  test('a partial fill measures no consumption', () {
    // §3 measures only full-to-full. A row whose tank was not full at both
    // ends leaves the column empty rather than printing an estimate dressed
    // as a measurement.
    final fills = [
      _fill(index: 0, occurredOn: '2026-01-01'),
      _fill(index: 1, occurredOn: '2026-02-01', full: false),
    ];

    final rows = fillUpCsvRows(
      vehicle: _vehicle(),
      fillUps: fills,
      cumulativeMetres: {
        fills[0].id.toString(): 100_000_000,
        fills[1].id.toString(): 100_500_000,
      },
      units: _metric,
    );

    expect(rows[1][13], '');
  });

  test('all-costs unions the three sources without double-counting', () {
    // A fill is a `fuel` row and a service is a `service` row, and NEITHER
    // also appears as an expense. A record counted twice makes every total in
    // the user's pivot table wrong by exactly the amount they were checking.
    final rows = costCsvRows(
      vehiclesById: {_veh.toString(): _vehicle()},
      fillUps: [_fill(index: 0, occurredOn: '2026-03-01')],
      services: [
        ServiceRecord(
          id: ServiceRecordId.tryParse('srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX')!,
          vehicleId: _veh,
          occurredOn: '2026-02-01',
          odometerUnit: DistanceUnit.km,
          lines: [
            ServiceLine(
              id: ServiceLineId.tryParse('lin_01K0C4V2H9B8N3Q7ZE5RY6TMX1')!,
              serviceRecordId: ServiceRecordId.tryParse(
                'srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX',
              )!,
              label: 'Ölwechsel',
              amount: Money(9820, _eur),
            ),
          ],
          createdAtUtcMs: 0,
          updatedAtUtcMs: 0,
        ),
      ],
      expenses: [
        Expense(
          id: ExpenseId.tryParse('exp_01K1R9T6Y2W5Q8Z3E7B0N4MJDF')!,
          vehicleId: _veh,
          occurredOn: '2026-01-01',
          category: ExpenseCategory.insurance,
          amount: Money(61_200, _eur),
          odometerUnit: DistanceUnit.km,
          createdAtUtcMs: 0,
          updatedAtUtcMs: 0,
        ),
      ],
      unitsFor: (_) => _metric,
    );

    // Sorted by date: expense, service, fuel.
    expect(rows.map((r) => r[2]), ['expense', 'service', 'fuel']);
    expect(rows, hasLength(3));
    // And exactly one row per event.
    expect(rows.where((r) => r[2] == 'fuel'), hasLength(1));
  });

  test('a service costs the SUM OF LINES, never a stored total', () {
    final rows = costCsvRows(
      vehiclesById: {_veh.toString(): _vehicle()},
      fillUps: const [],
      services: [
        ServiceRecord(
          id: ServiceRecordId.tryParse('srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX')!,
          vehicleId: _veh,
          occurredOn: '2026-02-01',
          odometerUnit: DistanceUnit.km,
          lines: [
            for (final (id, minor) in [
              ('lin_01K0C4V2H9B8N3Q7ZE5RY6TMX1', 9820),
              ('lin_01K0C4V2H9B8N3Q7ZE5RY6TMX2', 4500),
            ])
              ServiceLine(
                id: ServiceLineId.tryParse(id)!,
                serviceRecordId: ServiceRecordId.tryParse(
                  'srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX',
                )!,
                label: 'line',
                amount: Money(minor, _eur),
              ),
          ],
          createdAtUtcMs: 0,
          updatedAtUtcMs: 0,
        ),
      ],
      expenses: const [],
      unitsFor: (_) => _metric,
    );

    expect(rows.single[8], '143.20');
    expect(rows.single[9], 'EUR');
  });

  test('a service with two currencies produces no amount at all', () {
    // §2 forbids summing across currencies, and a cell that picked one would
    // be a number the user's pivot table adds to a different column.
    final rows = costCsvRows(
      vehiclesById: {_veh.toString(): _vehicle()},
      fillUps: const [],
      services: [
        ServiceRecord(
          id: ServiceRecordId.tryParse('srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX')!,
          vehicleId: _veh,
          occurredOn: '2026-02-01',
          odometerUnit: DistanceUnit.km,
          lines: [
            ServiceLine(
              id: ServiceLineId.tryParse('lin_01K0C4V2H9B8N3Q7ZE5RY6TMX1')!,
              serviceRecordId: ServiceRecordId.tryParse(
                'srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX',
              )!,
              label: 'parts',
              amount: Money(9820, _eur),
            ),
            ServiceLine(
              id: ServiceLineId.tryParse('lin_01K0C4V2H9B8N3Q7ZE5RY6TMX2')!,
              serviceRecordId: ServiceRecordId.tryParse(
                'srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX',
              )!,
              label: 'labour',
              amount: Money(4500, _gbp),
            ),
          ],
          createdAtUtcMs: 0,
          updatedAtUtcMs: 0,
        ),
      ],
      expenses: const [],
      unitsFor: (_) => _metric,
    );

    expect(rows.single[8], '');
    expect(rows.single[9], '');
  });

  group('the file itself', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('odova_csv'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('is UTF-8 with a BOM, CRLF, and parses as one table', () async {
      final file = File('${dir.path}/odova-fillups-golf-2026-09-02.csv');
      final rows = fillUpCsvRows(
        vehicle: _vehicle(),
        fillUps: [
          _fill(
            index: 0,
            occurredOn: '2026-01-01',
            notes: 'a,b"c\nd',
            station: 'Aral A8',
          ),
        ],
        cumulativeMetres: const {},
        units: _metric,
      );

      await writeCsvFile(file, kFillUpsCsvHeader, rows);

      final bytes = file.readAsBytesSync();
      expect(bytes.take(3), kUtf8Bom);

      final text = utf8.decode(bytes.skip(3).toList());
      final parsed = _parse(text);
      expect(parsed.first, kFillUpsCsvHeader);
      expect(parsed, hasLength(2));
      // The hostile cell, through a real parser.
      expect(parsed[1].last, 'a,b"c\nd');
    });

    test('a formula cell arrives as text', () async {
      // A vehicle somebody named `=cmd()` is a vehicle whose CSV runs
      // something on another machine.
      final file = File('${dir.path}/costs.csv');

      await writeCsvFile(file, kCostsCsvHeader, [
        [
          '2026-01-01',
          '=cmd()',
          'expense',
          'other',
          '',
          '',
          '',
          'km',
          '10.00',
          'EUR',
          '',
        ],
      ]);

      final parsed = _parse(
        utf8.decode(file.readAsBytesSync().skip(3).toList()),
      );
      expect(parsed[1][1], "'=cmd()");
    });

    test('a row with the wrong number of cells is refused, loudly', () async {
      final file = File('${dir.path}/broken.csv');

      await expectLater(
        writeCsvFile(file, kCostsCsvHeader, [
          const ['too', 'few'],
        ]),
        throwsA(isA<StateError>()),
      );
      // And nothing is published under the name.
      expect(file.existsSync(), isFalse);
    });

    test(
      'twelve thousand rows stream without assembling in a String',
      () async {
        // The property is structural: `writeCsvFile` takes an `Iterable` and
        // holds one row. What this asserts is that it WORKS at that size, in a
        // time that rules out anything quadratic.
        final file = File('${dir.path}/big.csv');
        final rows = Iterable<List<String>>.generate(
          12000,
          (i) => [
            '2026-01-01',
            'Golf',
            'fuel',
            'diesel',
            '',
            'Aral',
            '$i',
            'km',
            '73.51',
            'EUR',
            '',
          ],
        );

        final started = DateTime.now();
        await writeCsvFile(file, kCostsCsvHeader, rows);
        final elapsed = DateTime.now().difference(started);

        expect(elapsed, lessThan(const Duration(seconds: 5)));
        expect(file.lengthSync(), greaterThan(400_000));
      },
    );
  });
}
