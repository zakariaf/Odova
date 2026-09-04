/// One due-matrix fixture row, decoded and run through the engine.
///
/// **Shared by the test and the CI gate on purpose.** `due_matrix_test.dart`
/// asserts the fixture and `tool/regenerate_due_vectors.dart` diffs it, and
/// they used to construct the scenario separately — the same `ServiceItem`, the
/// same readings, the same vehicle and settings, and an inverse pair of
/// snake/camel name mappers, written twice.
///
/// That is worse than ordinary duplication because one of the two is a GATE:
/// if the constructions drift, the gate green-lights a different scenario from
/// the one the test asserts, and neither goes red. They had already drifted —
/// the test honoured `is_active` and the tool did not, so giving any paused row
/// an `expect` block would have had the tool computing it against the wrong
/// item.
///
/// **Flutter-free**, like the rest of `test/support` that `test/core` touches:
/// `dart test test/core` runs on the plain VM, and `structure_test.dart` walks
/// the imports transitively.
library;

import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/due/notice_window.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/due/resolve_anchor.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';

/// The ULID body every due fixture builds its ids from.
const dueFixtureId = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';

/// The vehicle every matrix row runs against.
final Vehicle dueFixtureVehicle = Vehicle(
  id: VehicleId.tryParse('veh_$dueFixtureId')!,
  name: 'Fixture',
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// Settings with no notice overrides, so the computed defaults apply.
final AppSettings dueFixtureSettings = AppSettings(
  schemaVersion: 1,
  currencyDefault: Currency.tryParse('EUR')!,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// The `ServiceItem` a fixture row describes.
ServiceItem itemOf(Map<String, dynamic> fixture) {
  final spec = fixture['item']! as Map<String, dynamic>;
  return ServiceItem(
    id: ServiceItemId.tryParse('rem_$dueFixtureId')!,
    vehicleId: VehicleId.tryParse('veh_$dueFixtureId')!,
    kind: ServiceKind.oilAndFilter,
    intervalDistance: spec['interval_m'] == null
        ? null
        : Distance(spec['interval_m']! as int),
    intervalMonths: spec['interval_months'] as int?,
    // `isTracked` defaults to FALSE on the model, so every fixture has to say
    // so — a row that forgot it would assert `unknown` for the wrong reason.
    isTracked: true,
    isActive: (fixture['is_active'] as bool?) ?? true,
    priority: ServicePriority.normal,
    rollover: ServiceRollover.fromActual,
    createdAtUtcMs: 1000,
    updatedAtUtcMs: 1000,
  );
}

/// The reading series a fixture row describes.
ReadingSeries seriesOf(Map<String, dynamic> fixture) {
  final rows = (fixture['readings']! as List).cast<Map<String, dynamic>>();
  return ReadingSeries.from([
    for (var i = 0; i < rows.length; i++)
      OdometerReading(
        id: OdometerReadingId.tryParse(
          'odo_${dueFixtureId.substring(0, 25)}$i',
        )!,
        vehicleId: VehicleId.tryParse('veh_$dueFixtureId')!,
        occurredOn: rows[i]['date']! as String,
        odometer: Distance(rows[i]['odometer_m']! as int),
        odometerUnit: DistanceUnit.km,
        source: OdometerSource.manual,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
  ], const []);
}

/// The engine's answer for one fixture row, in the fixture's own vocabulary.
///
/// Returns null for a row whose item is not eligible — a paused item is
/// filtered BEFORE the engine and has no due state, which is what
/// `expect: null` in the fixture means.
Map<String, Object?>? runDueCase(Map<String, dynamic> fixture) {
  final item = itemOf(fixture);
  if (!isEligible(item)) return null;

  final today = CivilDate.tryParse(fixture['today']! as String)!;
  final series = seriesOf(fixture);
  final anchorSpec = fixture['anchor']! as Map<String, dynamic>;

  final rate = dailyDistance(series, expectedAnnualMetres: null, today: today);
  final assessment = computeDueState(
    item,
    DueAnchor(
      date: CivilDate.tryParseOrNull(anchorSpec['date'] as String?),
      odometerMetres: anchorSpec['odometer_m'] as int?,
    ),
    estimateOdometer(series, rate, today: today),
    noticeWindow(
      item: item,
      vehicle: dueFixtureVehicle,
      settings: dueFixtureSettings,
    ),
    today: today,
    rate: rate,
    series: series,
  );

  return {
    'status': specStateName(assessment.state),
    'driver': assessment.driver.name,
    'remaining_m': assessment.remainingMetres,
    'remaining_days': assessment.remainingDays,
    'due_at_odometer_m': assessment.dueAtOdometerMetres,
    'due_on': assessment.dueOn?.toString(),
    'projected_due_date': assessment.projectedDueDate?.toString(),
    'confidence': assessment.confidence.wire,
    'progress': double.parse(assessment.progress.toStringAsFixed(6)),
  };
}

/// SPEC.md writes the states in snake_case; Dart names them in camelCase.
///
/// One direction, in one place. The two files used to carry inverse copies of
/// this two-entry table.
String specStateName(DueState state) => switch (state) {
  DueState.dueSoon => 'due_soon',
  DueState.needsOdometer => 'needs_odometer',
  _ => state.name,
};
