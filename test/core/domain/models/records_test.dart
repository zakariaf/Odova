// The derived getters on the domain models.
//
// Every one of these is a value SPEC.md §2 forbids storing, so each is a
// function here and a column nowhere. The tests are about the answers, not the
// plumbing: a wrong total or a wrong axis reads perfectly and is simply wrong.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:test/test.dart';

const _id = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';

VehicleId get _vehicle => VehicleId.tryParse('veh_$_id')!;
ServiceRecordId get _record => ServiceRecordId.tryParse('srv_$_id')!;

ServiceLine _line(String suffix, int amountMinor) => ServiceLine(
  id: ServiceLineId.tryParse('lin_${_id.substring(0, 25)}$suffix')!,
  serviceRecordId: _record,
  label: 'Line $suffix',
  amountMinor: amountMinor,
  currency: 'EUR',
);

ServiceItem _item({
  int? intervalDistanceM,
  int? intervalMonths,
  int? targetOdometerM,
  String? targetDate,
}) => ServiceItem(
  id: ServiceItemId.tryParse('rem_$_id')!,
  vehicleId: _vehicle,
  kind: ServiceKind.oilAndFilter,
  priority: ServicePriority.normal,
  rollover: ServiceRollover.fromActual,
  createdAtUtcMs: 0,
  updatedAtUtcMs: 0,
  intervalDistanceM: intervalDistanceM,
  intervalMonths: intervalMonths,
  targetOdometerM: targetOdometerM,
  targetDate: targetDate,
);

void main() {
  group('a service record has no total, it has lines', () {
    test('the total is the sum of them', () {
      final record = ServiceRecord(
        id: _record,
        vehicleId: _vehicle,
        occurredOn: '2026-09-03',
        odometerUnit: DistanceUnit.km,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
        lines: [_line('A', 8900), _line('B', 4250), _line('C', 0)],
      );

      expect(record.totalMinor, 13150);
    });

    test('a warranty job of one zero line totals zero, not nothing', () {
      // The model requires at least one line, so zero is the only
      // representable "not recorded" — and it has to come out as 0 rather
      // than as a null the cost dashboard has to special-case.
      final record = ServiceRecord(
        id: _record,
        vehicleId: _vehicle,
        occurredOn: '2026-09-03',
        odometerUnit: DistanceUnit.km,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
        lines: [_line('A', 0)],
      );

      expect(record.totalMinor, 0);
    });

    test('two records differing only in a line are not equal', () {
      // The lines are spread into `props` for this reason: a watched stream
      // that compared only the record's own fields would skip the rebuild
      // after a line was edited, and the screen would show yesterday's total.
      ServiceRecord withLines(List<ServiceLine> lines) => ServiceRecord(
        id: _record,
        vehicleId: _vehicle,
        occurredOn: '2026-09-03',
        odometerUnit: DistanceUnit.km,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
        lines: lines,
      );

      expect(withLines([_line('A', 100)]), withLines([_line('A', 100)]));
      expect(
        withLines([_line('A', 100)]),
        isNot(withLines([_line('A', 200)])),
      );
    });
  });

  group('which axes a service item has is derived, never stored', () {
    test('an interval or a target turns its axis on', () {
      expect(_item(intervalDistanceM: 15000000).hasDistanceAxis, isTrue);
      expect(_item(intervalDistanceM: 15000000).hasTimeAxis, isFalse);

      expect(_item(intervalMonths: 12).hasTimeAxis, isTrue);
      expect(_item(intervalMonths: 12).hasDistanceAxis, isFalse);

      // A one-off carries a target instead of an interval, and it is still
      // that axis.
      expect(_item(targetOdometerM: 120000000).hasDistanceAxis, isTrue);
      expect(_item(targetDate: '2027-04-01').hasTimeAxis, isTrue);
    });

    test('both axes at once is whichever-comes-first, not a third mode', () {
      final both = _item(intervalDistanceM: 15000000, intervalMonths: 12);
      expect(both.hasDistanceAxis, isTrue);
      expect(both.hasTimeAxis, isTrue);
    });
  });

  group('a trip distance prefers the odometer', () {
    Trip trip({int? start, int? end, int? manual}) => Trip(
      id: TripId.tryParse('trp_$_id')!,
      vehicleId: _vehicle,
      purpose: TripPurpose.business,
      startedOn: '2026-09-01',
      odometerUnit: DistanceUnit.km,
      createdAtUtcMs: 0,
      updatedAtUtcMs: 0,
      startOdometerM: start,
      endOdometerM: end,
      manualDistanceM: manual,
    );

    test('the endpoints win when both are present', () {
      expect(trip(start: 186000000, end: 186512000).distanceM, 512000);
    });

    test('the manual figure is used ONLY when both endpoints are absent', () {
      // SPEC.md §3: a trip is never the source of truth for total distance,
      // because people log some trips and not all. Preferring a typed number
      // over two real readings would make it one.
      expect(
        trip(start: 186000000, end: 186512000, manual: 999).distanceM,
        512000,
      );
      expect(trip(manual: 40000).distanceM, 40000);
      expect(trip(start: 186000000, manual: 40000).distanceM, 40000);
    });

    test('an open trip with nothing to go on has no distance', () {
      expect(trip().distanceM, isNull);
    });
  });

  group('an odometer reading knows whether it is derived', () {
    OdometerReading reading(OdometerSource source) => OdometerReading(
      id: OdometerReadingId.tryParse('odo_$_id')!,
      vehicleId: _vehicle,
      occurredOn: '2026-09-03',
      odometerM: 186512000,
      odometerUnit: DistanceUnit.km,
      source: source,
      createdAtUtcMs: 0,
      updatedAtUtcMs: 0,
    );

    test('manual is the only one that is not', () {
      // A derived reading follows its parent and is not directly editable:
      // editing it would leave the reading and the record that produced it
      // disagreeing, with nothing to say which is right.
      expect(reading(OdometerSource.manual).isDerived, isFalse);
      for (final source in OdometerSource.values) {
        if (source == OdometerSource.manual) continue;
        expect(reading(source).isDerived, isTrue, reason: source.wire);
      }
    });
  });

  test('a correction offset is previous minus new', () {
    // The cluster-swap case: 187,412 km replaced by one reading 0 gives
    // +187,412 km carried forward.
    final correction = OdometerCorrection(
      id: OdometerCorrectionId.tryParse('cor_$_id')!,
      vehicleId: _vehicle,
      fromReadingId: OdometerReadingId.tryParse('odo_$_id')!,
      previousM: 187412000,
      newM: 0,
      odometerUnit: DistanceUnit.km,
      reason: OdometerCorrectionReason.clusterReplaced,
      createdAtUtcMs: 0,
      updatedAtUtcMs: 0,
    );

    expect(correction.offsetM, 187412000);
  });
}
