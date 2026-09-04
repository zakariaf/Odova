// Diffs `test/core/due/fixtures/due_matrix.json` against current behaviour.
//
// **It does not regenerate what it checks.** Without `--bless` it computes the
// engine's answer for every fixture and reports the rows that differ, exiting
// non-zero; CI runs it that way. `--bless` is the only path that writes, and it
// exists for a DELIBERATE behaviour change, made by a person who then says in
// the PR what changed and why.
//
// `seeded-determinism-and-golden-vectors`: a gate never regenerates what it
// checks. A tool that rewrites the file on every run turns a golden file into a
// transcript of whatever the code does today, which is worse than no golden
// file, because it carries the authority of one.
//
// The fixture itself was hand-authored from SPEC.md §3 and §4.1 through an
// independent implementation of the prose. This tool has never written it.
import 'dart:convert';
import 'dart:io';

import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/due/notice_window.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/due/resolve_anchor.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';

const _path = 'test/core/due/fixtures/due_matrix.json';
const _id = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';

void main(List<String> args) {
  final bless = args.contains('--bless');
  final file = File(_path);
  final doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final cases = (doc['cases']! as List).cast<Map<String, dynamic>>();

  final drifted = <String>[];
  for (final fixture in cases) {
    final expected = fixture['expect'] as Map<String, dynamic>?;
    if (expected == null) continue; // an absence row; nothing to compute

    final actual = _compute(fixture);
    for (final key in expected.keys) {
      final want = expected[key];
      final got = actual[key];
      final same = want is num && got is num
          ? (want - got).abs() < 1e-6
          : want == got;
      if (!same) {
        drifted.add('${fixture['name']}: $key want $want, got $got');
      }
    }
    if (bless) fixture['expect'] = actual;
  }

  if (bless) {
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(doc)}\n',
    );
    stdout.writeln('blessed $_path (${drifted.length} rows changed)');
    return;
  }

  if (drifted.isEmpty) {
    stdout.writeln('ok    $_path matches the engine (${cases.length} rows)');
    return;
  }

  stdout
    ..writeln('FAIL  $_path disagrees with the engine:')
    ..writeAll(drifted.map((d) => '        $d\n'))
    ..writeln()
    ..writeln('      The fixture is hand-authored from SPEC.md. If the ENGINE')
    ..writeln('      is right, this is a deliberate behaviour change: run with')
    ..writeln('      --bless and say in the PR what changed and why. If the')
    ..writeln('      FIXTURE is right, the engine has a bug.');
  exitCode = 1;
}

Map<String, Object?> _compute(Map<String, dynamic> fixture) {
  final today = CivilDate.tryParse(fixture['today']! as String)!;
  final itemSpec = fixture['item']! as Map<String, dynamic>;
  final anchorSpec = fixture['anchor']! as Map<String, dynamic>;

  final item = ServiceItem(
    id: ServiceItemId.tryParse('rem_$_id')!,
    vehicleId: VehicleId.tryParse('veh_$_id')!,
    kind: ServiceKind.oilAndFilter,
    intervalDistance: itemSpec['interval_m'] == null
        ? null
        : Distance(itemSpec['interval_m']! as int),
    intervalMonths: itemSpec['interval_months'] as int?,
    isTracked: true,
    priority: ServicePriority.normal,
    rollover: ServiceRollover.fromActual,
    createdAtUtcMs: 1000,
    updatedAtUtcMs: 1000,
  );

  final rows = (fixture['readings']! as List).cast<Map<String, dynamic>>();
  final readings = [
    for (var i = 0; i < rows.length; i++)
      OdometerReading(
        id: OdometerReadingId.tryParse('odo_${_id.substring(0, 25)}$i')!,
        vehicleId: VehicleId.tryParse('veh_$_id')!,
        occurredOn: rows[i]['date']! as String,
        odometer: Distance(rows[i]['odometer_m']! as int),
        odometerUnit: DistanceUnit.km,
        source: OdometerSource.manual,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
  ];

  final series = ReadingSeries.from(readings, const []);
  final rate = dailyDistance(series, expectedAnnualMetres: null, today: today);
  final assessment = computeDueState(
    item,
    DueAnchor(
      date: anchorSpec['date'] == null
          ? null
          : CivilDate.tryParse(anchorSpec['date']! as String),
      odometerMetres: anchorSpec['odometer_m'] as int?,
    ),
    estimateOdometer(series, rate, today: today),
    noticeWindow(item: item, vehicle: _vehicle, settings: _settings),
    today: today,
    rate: rate,
    series: series,
  );

  return {
    'status': _specName(assessment.state.name),
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

String _specName(String dartName) => switch (dartName) {
  'dueSoon' => 'due_soon',
  'needsOdometer' => 'needs_odometer',
  _ => dartName,
};

final _vehicle = Vehicle(
  id: VehicleId.tryParse('veh_$_id')!,
  name: 'Fixture',
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

final _settings = AppSettings(
  schemaVersion: 1,
  currencyDefault: Currency.tryParse('EUR')!,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);
