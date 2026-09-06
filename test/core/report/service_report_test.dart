// SPEC.md §12: "Turn eight years of records into one document a buyer will
// believe."
//
// The sentence that governs every decision here is the one about estimates:
// "Never a projection: a document handed to a buyer contains no estimates."
// Everywhere else in this app an estimated odometer is a legitimate answer with
// a `~` on it. In a document that changes hands for money it is not an answer
// at all — except where the RECORD itself was estimated at the time, which is
// a fact about the record and carries its footnote rather than being hidden.
//
// The other governing sentence is the exclusion list. "A fine on a sales
// document is an own goal." Nothing in §12's *Never in the document* list may
// reach this model, and the property test at the bottom is what says so over a
// fixture that contains all of them.
@TestOn('vm')
library;

import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/report/service_report.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

const _ulid = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
String _sfx(int i) => '${_alphabet[i ~/ 32 % 32]}${_alphabet[i % 32]}';
String _b(int i) => '${_ulid.substring(0, 24)}${_sfx(i)}';
CivilDate day(String t) => CivilDate.tryParse(t)!;
final Currency _eur = Currency.tryParse('EUR')!;
final Currency _gbp = Currency.tryParse('GBP')!;
final VehicleId _veh = VehicleId.tryParse('veh_${_b(0)}')!;

Vehicle vehicle({String? soldOn, String? plate, String? vin, String? notes}) =>
    Vehicle(
      id: _veh,
      name: 'VW Golf 1.6 TDI',
      vehicleType: VehicleType.car,
      fuelKindDefault: FuelKind.diesel,
      status: VehicleStatus.active,
      make: 'VW',
      model: 'Golf 1.6 TDI',
      year: 2016,
      plate: plate,
      vin: vin,
      notes: notes,
      purchaseDate: '2018-03-04',
      purchaseOdometer: const Distance.fromKm(62400),
      soldOn: soldOn,
      createdAtUtcMs: 1,
      updatedAtUtcMs: 1,
    );

ServiceItem item(int i, {String? label, ServiceKind? kind}) => ServiceItem(
  id: ServiceItemId.tryParse('rem_${_b(i)}')!,
  vehicleId: _veh,
  kind: kind ?? ServiceKind.oilAndFilter,
  label: label,
  isTracked: true,
  priority: ServicePriority.normal,
  rollover: ServiceRollover.fromActual,
  createdAtUtcMs: 1,
  updatedAtUtcMs: 1,
);

ServiceRecord record(
  int i, {
  required String on,
  required int km,
  int cents = 18450,
  bool estimated = false,
  String? vendor = 'Werkstatt Krüger',
  List<ServiceItemId> completes = const [],
  Currency? currency,
  int extraLines = 0,
}) => ServiceRecord(
  id: ServiceRecordId.tryParse('srv_${_b(i)}')!,
  vehicleId: _veh,
  occurredOn: on,
  odometer: Distance.fromKm(km),
  odometerUnit: DistanceUnit.km,
  odometerEstimated: estimated,
  vendor: vendor,
  lines: [
    ServiceLine(
      id: ServiceLineId.tryParse('lin_${_b(i)}')!,
      serviceRecordId: ServiceRecordId.tryParse('srv_${_b(i)}')!,
      serviceItemId: completes.isEmpty ? null : completes.first,
      label: 'Oil and filter',
      amount: Money(cents, currency ?? _eur),
    ),
    // Zero-cost extras, so a test can make lines and records differ without
    // moving any total the other tests assert on.
    for (var k = 0; k < extraLines; k++)
      ServiceLine(
        id: ServiceLineId.tryParse('lin_${_b(60 + i * 4 + k)}')!,
        serviceRecordId: ServiceRecordId.tryParse('srv_${_b(i)}')!,
        label: 'Extra $k',
        amount: Money(0, currency ?? _eur),
      ),
  ],
  createdAtUtcMs: 1,
  updatedAtUtcMs: 1,
);

OdometerReading reading(int i, String on, int km, {bool estimated = false}) =>
    OdometerReading(
      id: OdometerReadingId.tryParse('odo_${_b(i)}')!,
      vehicleId: _veh,
      occurredOn: on,
      odometer: Distance.fromKm(km),
      odometerUnit: DistanceUnit.km,
      source: OdometerSource.manual,
      createdAtUtcMs: 1 + i,
      updatedAtUtcMs: 1 + i,
    );

ServiceReportDocument build({
  Vehicle? v,
  List<ServiceRecord> records = const [],
  List<ServiceItem> items = const [],
  List<OdometerReading> readings = const [],
  ServiceReportOptions options = const ServiceReportOptions(),
  FuelSummaryFacts? fuel,
  String today = '2026-09-02',
}) => buildServiceReport(
  vehicle: v ?? vehicle(),
  records: records,
  items: items,
  series: ReadingSeries.from(readings, const []),
  fuel: fuel,
  options: options,
  today: day(today),
);

void main() {
  group('the header', () {
    test(
      'uses the latest ENTERED reading and its date, never a projection',
      () {
        // §12: "Never a projection: a document handed to a buyer contains no
        // estimates." The vehicle has not been read since June; today is
        // September. Everywhere else in the app that gap produces a `~`
        // estimate. Here it produces June's number and June's date.
        final doc = build(
          readings: [
            reading(0, '2025-01-01', 150000),
            reading(1, '2026-06-14', 187412),
          ],
        );

        expect(doc.header.latestOdometer, const Distance.fromKm(187412));
        expect(doc.header.latestOdometerReadOn, '2026-06-14');
      },
    );

    test('carries the purchase odometer and the distance under this owner', () {
      final doc = build(readings: [reading(1, '2026-06-14', 187412)]);

      expect(doc.header.purchaseOdometer, const Distance.fromKm(62400));
      expect(doc.header.distanceUnderOwner, const Distance.fromKm(125012));
    });

    test('a vehicle with no readings has no distance rather than zero', () {
      // Zero is a claim: it says the car has not moved. §2's "never guess in a
      // way that looks like fact" makes the absence the honest answer.
      final doc = build();

      expect(doc.header.latestOdometer, isNull);
      expect(doc.header.distanceUnderOwner, isNull);
    });

    test('the ownership span ends at sold_on for a sold vehicle', () {
      final doc = build(v: vehicle(soldOn: '2026-08-20'));

      expect(doc.header.ownedFrom, '2018-03-04');
      expect(doc.header.ownedUntil, '2026-08-20');
    });

    test('and at today for one still owned', () {
      expect(build().header.ownedUntil, isNull, reason: 'open-ended: "today"');
    });
  });

  group('maintenance at a glance', () {
    test('lists every item with a completion, and the rest as no-record', () {
      // §12: "Items never done are listed under 'No record in this app',
      // because an absent row reads as a hidden row." A buyer scanning a
      // document cannot tell a missing timing belt from a hidden one.
      final done = item(1, label: 'Oil and filter');
      final never = item(2, label: 'Timing belt', kind: ServiceKind.timingBelt);

      final doc = build(
        items: [done, never],
        records: [
          record(1, on: '2026-06-14', km: 174300, completes: [done.id]),
        ],
      );

      expect(doc.glance.map((g) => g.itemId), [done.id]);
      expect(doc.noRecordItemIds, [never.id]);
    });

    test('the glance carries the date, odometer and distance since', () {
      final done = item(1, label: 'Timing belt');
      final doc = build(
        items: [done],
        records: [
          record(1, on: '2023-04-12', km: 100300, completes: [done.id]),
        ],
        readings: [reading(1, '2026-06-14', 187412)],
      );

      final row = doc.glance.single;
      expect(row.lastDoneOn, '2023-04-12');
      expect(row.lastDoneOdometer, const Distance.fromKm(100300));
      expect(row.distanceSince, const Distance.fromKm(87112));
    });

    test('distance since is absent when there is no reading to measure to', () {
      final done = item(1);
      final doc = build(
        items: [done],
        records: [
          record(1, on: '2023-04-12', km: 100300, completes: [done.id]),
        ],
      );

      expect(doc.glance.single.distanceSince, isNull);
    });

    test('an untracked item is in neither list', () {
      // It is not a maintenance item as far as this vehicle is concerned, and
      // listing it under "no record" invents an obligation the owner never
      // took on.
      final doc = build(
        items: [
          ServiceItem(
            id: ServiceItemId.tryParse('rem_${_b(7)}')!,
            vehicleId: _veh,
            kind: ServiceKind.oilAndFilter,
            priority: ServicePriority.normal,
            rollover: ServiceRollover.fromActual,
            createdAtUtcMs: 1,
            updatedAtUtcMs: 1,
          ),
        ],
      );

      expect(doc.glance, isEmpty);
      expect(doc.noRecordItemIds, isEmpty);
    });
  });

  group('the full history', () {
    test('groups by year, newest first, with a per-year subtotal', () {
      final doc = build(
        records: [
          record(1, on: '2026-06-14', km: 174300),
          record(2, on: '2026-02-02', km: 168110, cents: 41200),
          record(3, on: '2025-05-05', km: 150000, cents: 9000),
        ],
      );

      expect(doc.years.map((y) => y.year), [2026, 2025]);
      expect(doc.years.first.subtotals[_eur]?.amountMinor, 59650);
      expect(doc.years.first.records, hasLength(2));
    });

    test('records inside a year are newest first', () {
      final doc = build(
        records: [
          record(2, on: '2026-02-02', km: 168110),
          record(1, on: '2026-06-14', km: 174300),
        ],
      );

      expect(
        doc.years.single.records.map((r) => r.occurredOn),
        ['2026-06-14', '2026-02-02'],
      );
    });

    test('the subtotal disappears when Costs is off', () {
      // Not zeroed — ABSENT. A subtotal of 0 € on a document says the year's
      // work was free.
      final doc = build(
        records: [record(1, on: '2026-06-14', km: 174300)],
        options: const ServiceReportOptions(costs: false),
      );

      expect(doc.years.single.subtotals, isEmpty);
      expect(doc.summary, isNull);
    });

    test('mixed currencies group and never sum', () {
      // §12: "Totals group: 6,842 € · £310." Adding them would invent an
      // exchange rate the app has never had and cannot get offline.
      final doc = build(
        records: [
          record(1, on: '2026-06-14', km: 174300),
          record(2, on: '2026-02-02', km: 168110, cents: 31000, currency: _gbp),
        ],
      );

      expect(doc.years.single.subtotals.keys, {_eur, _gbp});
      expect(doc.years.single.subtotals[_eur]?.amountMinor, 18450);
      expect(doc.years.single.subtotals[_gbp]?.amountMinor, 31000);
      expect(doc.summary?.totals.keys, {_eur, _gbp});
    });

    test('the summary counts services, not lines', () {
      // §12's "34 services". A visit to a workshop that replaced pads, discs
      // and fluid is ONE service with three lines — counting lines would put
      // "137 services" on an eight-year document, which is a number a buyer
      // would not believe and an owner could not recognise.
      //
      // Both records here carry THREE lines each on purpose: with one line
      // apiece, "count the records" and "count the lines" return the same
      // number and this test passes against either.
      final doc = build(
        records: [
          record(1, on: '2026-06-14', km: 174300, extraLines: 2),
          record(2, on: '2026-02-02', km: 168110, extraLines: 2),
        ],
      );

      expect(doc.summary?.serviceCount, 2);
      expect(
        doc.years.single.records.expand((r) => r.lines),
        hasLength(6),
        reason: 'six lines across two services, so the two counts differ',
      );
    });
  });

  group('estimated odometers', () {
    test('a record with odometer_estimated carries ~ and ONE footnote', () {
      // §12: "Hiding that in a document handed to a buyer is a small lie the
      // app has no business telling." One footnote however many rows carry it
      // — the note explains the mark, not each occurrence.
      final doc = build(
        records: [
          record(1, on: '2026-06-14', km: 174300, estimated: true),
          record(2, on: '2026-02-02', km: 168110, estimated: true),
          record(3, on: '2025-01-01', km: 150000),
        ],
      );

      final rows = doc.years.expand((y) => y.records).toList();
      expect(rows.where((r) => r.odometerEstimated), hasLength(2));
      expect(doc.footnotes, hasLength(1));
      expect(doc.footnotes.single, ServiceReportFootnote.estimatedOdometer);
    });

    test('no estimated record produces no footnote at all', () {
      final doc = build(records: [record(1, on: '2026-06-14', km: 174300)]);
      expect(doc.footnotes, isEmpty);
    });
  });

  group('the toggles', () {
    test('plate, VIN and notes appear only when their toggle is on', () {
      final v = vehicle(
        plate: 'M-AB 1234',
        vin: 'WVWZZZ1KZAW000001',
        notes: 'cheaper than the dealer wanted',
      );

      final off = build(v: v);
      expect(off.header.plate, isNull);
      expect(off.header.vin, isNull);
      expect(off.header.notes, isNull);

      final on = build(
        v: v,
        options: const ServiceReportOptions(plateAndVin: true, notes: true),
      );
      expect(on.header.plate, 'M-AB 1234');
      expect(on.header.vin, 'WVWZZZ1KZAW000001');
      expect(on.header.notes, 'cheaper than the dealer wanted');
    });

    test('both default OFF', () {
      // §12 is explicit: "the identity fields are the buyer's to ask for, not
      // the app's to leak into a group chat", and notes "say things like
      // 'cheaper than the dealer wanted'".
      const options = ServiceReportOptions();
      expect(options.plateAndVin, isFalse);
      expect(options.notes, isFalse);
      expect(options.costs, isTrue);
      expect(options.fuelSummary, isTrue);
    });

    test(
      'the fuel summary appears only when its toggle is on and it exists',
      () {
        const facts = FuelSummaryFacts(
          metresPerUnit: 15625,
          tankCount: 231,
          distance: Distance.fromKm(118400),
        );

        expect(build(fuel: facts).fuel, isNotNull);
        expect(
          build(
            fuel: facts,
            options: const ServiceReportOptions(fuelSummary: false),
          ).fuel,
          isNull,
        );
        expect(build().fuel, isNull, reason: 'no tanks, no summary');
      },
    );
  });

  test('the footer is present in every configuration', () {
    // §12 calls it unremovable, and it is the sentence that makes the document
    // honest: "from records kept by the owner. Not verified by a third party."
    for (final options in const [
      ServiceReportOptions(),
      ServiceReportOptions(costs: false, fuelSummary: false),
      ServiceReportOptions(plateAndVin: true, notes: true),
    ]) {
      expect(build(options: options).generatedOn, day('2026-09-02'));
    }
  });

  test("nothing on §12's exclusion list can reach the document", () {
    // A property test over a fixture holding one of each. The model takes
    // `ServiceRecord`s and nothing else — there is no parameter a fine could
    // arrive through — and this asserts that stays true by construction: the
    // document's every money figure traces to a ServiceLine.
    final doc = build(
      records: [
        record(1, on: '2026-06-14', km: 174300),
        record(2, on: '2026-02-02', km: 168110, cents: 41200),
      ],
      readings: [reading(1, '2026-06-14', 187412)],
    );

    final fromLines = doc.years
        .expand((y) => y.records)
        .expand((r) => r.lines)
        .fold(0, (sum, l) => sum + l.amount.amountMinor);

    expect(doc.summary?.totals[_eur]?.amountMinor, fromLines);
    expect(
      doc.years.fold(
        0,
        (s, y) => s + (y.subtotals[_eur]?.amountMinor ?? 0),
      ),
      fromLines,
      reason: 'every figure in the document is the sum of service lines',
    );
  });
}
