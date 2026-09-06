// The odometer field on the log forms sees the vehicle's real history.
//
// SPEC.md §10: "This one field feeds the due engine, so it behaves identically
// on `log.fillup`, `log.service` and `log.odometer`." It was handed
// `existing: const []` and `corrections: const []`, which made the whole rule
// engine inert — no helper line, no delta, no monotonicity check and no
// estimate chip — on every one of the three.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/ui/calm/calm_field.dart';

import '../../app/routing/shell_harness.dart';
import '../../support/device.dart';
import '../home/home_fixture.dart';

OdometerReading _reading(String on, int km) => OdometerReading(
  id: OdometerReadingId.tryParse('odo_01JQ8ZK3M7F0R6XN2E9TB4HCVA')!,
  vehicleId: golfId,
  occurredOn: on,
  odometer: Distance.fromKm(km),
  odometerUnit: DistanceUnit.km,
  source: OdometerSource.manual,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

Future<void> _pump(
  WidgetTester tester, {
  List<OdometerReading> readings = const [],
}) async {
  tester.useDevice(Device.tallForm);
  await pumpShell(
    tester,
    Routes.log(LogType.fillUp),
    settings: homeSettings(golfId),
    vehicles: [homeVehicle(golfId, 'The Golf')],
    overrides: <Override>[
      odometerReadingsProvider(golfId).overrideWith(
        (ref) => Stream.value(readings),
      ),
      odometerCorrectionsProvider(
        golfId,
      ).overrideWith((ref) => Stream.value(const [])),
    ],
  );
}

CalmField _odometer(WidgetTester tester) =>
    tester.widgetList<CalmField>(find.byType(CalmField)).first;

void main() {
  testWidgets('the helper line names the last entered reading', (tester) async {
    await _pump(tester, readings: [_reading('2026-08-12', 186743)]);

    expect(
      _odometer(tester).hint,
      isNotNull,
      reason:
          'with a history behind it the field says what was last entered; '
          'with `existing: const []` it never could',
    );
    expect(_odometer(tester).hint, contains('186,743'));
  });

  testWidgets('with no history there is no helper line', (tester) async {
    // A vehicle's FIRST reading has nothing behind it, and inventing a line
    // would be the app describing a reading that does not exist.
    await _pump(tester);

    expect(_odometer(tester).hint, isNull);
  });
}
