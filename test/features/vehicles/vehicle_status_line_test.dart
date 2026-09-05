// The one line the garage and the switcher both draw.
//
// EPIC-09 task 9.7: "the odometer-with-status row is the same widget `vehicles`
// uses, parameterised, not a second copy." These are the decisions inside it,
// asserted once rather than twice through two screens.
//
// SPEC.md §8's switcher: "Each vehicle's odometer renders in that vehicle's own
// `distance_unit`, not the active one's" — a household with a van in miles and
// a bike in kilometres.
@TestOn('vm')
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/clock_suspicion.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/due/vehicle_due_snapshot.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/vehicles/garage_status.dart';
import 'package:odova/features/vehicles/vehicle_status_line.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

Vehicle _vehicle({DistanceUnit? unit}) => Vehicle(
  id: VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA')!,
  name: 'The Golf',
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  distanceUnit: unit,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// A snapshot whose worst item is due in [days].
VehicleDueSnapshot _dueIn(int days) => VehicleDueSnapshot(
  assessments: const [],
  summary: DueSummary(
    counts: const {DueState.due: 1},
    worst: DueAssessment(
      state: DueState.due,
      driver: DueDriver.distance,
      confidence: RateConfidence.measured,
      progress: 0.9,
      remainingDays: days,
    ),
  ),
  rate: const DailyDistance(
    metresPerDay: 40000,
    confidence: RateConfidence.measured,
  ),
  estimate: OdometerEstimate(
    metres: 187412000,
    asOf: CivilDate.tryParse('2026-09-04')!,
    projection: OdometerProjection.entered,
    staleDays: 0,
  ),
  clock: ClockSuspicion(
    isSuspect: false,
    observedToday: CivilDate.tryParse('2026-09-04')!,
  ),
);

VehicleDueSnapshot _snapshot({
  required int metres,
  OdometerProjection projection = OdometerProjection.entered,
  int staleDays = 0,
}) => VehicleDueSnapshot(
  assessments: const [],
  summary: const DueSummary(
    counts: {DueState.ok: 1},
    worst: DueAssessment(
      state: DueState.ok,
      driver: DueDriver.distance,
      confidence: RateConfidence.measured,
      progress: 0.5,
    ),
  ),
  rate: const DailyDistance(
    metresPerDay: 40000,
    confidence: RateConfidence.measured,
  ),
  estimate: OdometerEstimate(
    metres: metres,
    asOf: CivilDate.tryParse('2026-09-04')!.addDays(-staleDays),
    projection: projection,
    staleDays: staleDays,
  ),
  clock: ClockSuspicion(
    isSuspect: false,
    observedToday: CivilDate.tryParse('2026-09-04')!,
  ),
);

String _line(
  AppLocalizations l10n, {
  required DistanceUnit globalUnit,
  DistanceUnit? vehicleUnit,
  int metres = 187412000,
  OdometerProjection projection = OdometerProjection.entered,
  int staleDays = 0,
  GarageStatus status = GarageStatus.allGood,
}) => stripBidi(
  vehicleOdometerAndStatus(
    l10n: l10n,
    tag: 'en-GB',
    vehicle: _vehicle(unit: vehicleUnit),
    snapshot: _snapshot(
      metres: metres,
      projection: projection,
      staleDays: staleDays,
    ),
    status: status,
    globalUnit: globalUnit,
  ),
);

void main() {
  late AppLocalizations l10n;
  late AppLocalizations l10nFa;

  setUpAll(() async {
    // What `bootstrap()` does on the cold-launch path. The EXPIRED branch
    // quotes the reading's own date, and `DateFormat.yMMMMd` throws until
    // ICU's date symbols are loaded.
    await initializeDateFormatting();
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
    l10nFa = await AppLocalizations.delegate.load(const Locale('fa'));
  });

  test('a sold vehicle says the em dash, however old its reading is', () {
    // SPEC.md §8: "a sold vehicle computes no reminders and its card shows —".
    // `garageStatusOf` checks sold FIRST, before anything is computed, and
    // this line did not: the two branches above the status — the expired
    // reading and the stale one — answered first. So every sold vehicle in the
    // switcher read "Odometer last updated 8 months ago", which is both true
    // and beside the point. A car nobody drives has a stale odometer by
    // definition; that is not news about it.
    for (final (projection, staleDays) in [
      (OdometerProjection.entered, 0),
      (OdometerProjection.projected, 400),
      (OdometerProjection.expired, 400),
    ]) {
      expect(
        _line(
          l10n,
          globalUnit: DistanceUnit.km,
          projection: projection,
          staleDays: staleDays,
          status: GarageStatus.sold,
        ),
        endsWith('· —'),
        reason: '$projection after $staleDays days',
      );
    }
  });

  test("a vehicle's own unit wins over the global one", () {
    // The van in miles and the bike in kilometres, in one garage. SPEC.md §8
    // says the switcher shows each in its own, and `Vehicle.distance_unit` is
    // the per-vehicle override §8's `vehicle.edit` writes.
    expect(
      _line(l10n, vehicleUnit: DistanceUnit.mi, globalUnit: DistanceUnit.km),
      startsWith('116,452 mi'),
    );
    expect(
      _line(l10n, vehicleUnit: DistanceUnit.km, globalUnit: DistanceUnit.mi),
      startsWith('187,412 km'),
    );
  });

  test('a vehicle with no override follows the GLOBAL, never a constant', () {
    // The bug this replaced: the fallback was a hard-coded `DistanceUnit.km`,
    // so a miles user's vehicle with no override read in kilometres — on the
    // one screen whose whole point is that each row uses the right unit.
    expect(
      _line(l10n, globalUnit: DistanceUnit.mi),
      startsWith('116,452 mi'),
    );
    expect(
      _line(l10n, globalUnit: DistanceUnit.km),
      startsWith('187,412 km'),
    );
  });

  test('the estimate rounds in the unit it is READ in, not stored in', () {
    // 100 km and 50 mi are different distances. A projection rounded to 100 km
    // and then converted moves in 62-mile steps on a screen showing miles.
    final miles = _line(
      l10n,
      globalUnit: DistanceUnit.mi,
      projection: OdometerProjection.projected,
      staleDays: 122,
    );
    expect(miles, startsWith('~116,450 mi'));
    expect(
      _line(
        l10n,
        globalUnit: DistanceUnit.km,
        projection: OdometerProjection.projected,
        staleDays: 122,
      ),
      startsWith('~187,400 km'),
    );
  });

  test('an EXPIRED reading is exact in either unit — it is not a guess', () {
    expect(
      _line(
        l10n,
        globalUnit: DistanceUnit.mi,
        projection: OdometerProjection.expired,
        staleDays: 400,
      ),
      startsWith('116,452 mi'),
    );
  });

  test('a day count is shaped, never a raw Dart string', () {
    // SPEC.md §5: one numbering system, app-wide. The count went through
    // `'${days ?? 0}'`, which renders Latin digits beside a Persian odometer on
    // the SAME LINE — `187,412 كيلومتر · Service due in 3 days`.
    final line = stripBidi(
      vehicleOdometerAndStatus(
        l10n: l10nFa,
        tag: 'fa-IR',
        vehicle: _vehicle(),
        snapshot: _dueIn(3),
        status: GarageStatus.dueInDays,
        globalUnit: DistanceUnit.km,
      ),
    );
    expect(line, contains('۳'));
    expect(line, isNot(matches(RegExp('[0-9]'))));
  });

  test('an age is shaped in the SAME system as everything beside it', () {
    // `vehicle.edit`'s odometer row forced `'en'` and Latin numerals while the
    // garage's row shaped its own, so one reading read "۴ ماه پیش" on one
    // screen and "4 months ago" on the other. One function now.
    final fa = formatDaysAgo(l10nFa, 'fa-IR', 122);
    expect(fa, contains('۴'));
    expect(fa, isNot(matches(RegExp('[0-9]'))));
    expect(formatDaysAgo(l10n, 'en-GB', 122), contains('4'));
  });
}
