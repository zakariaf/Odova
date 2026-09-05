// `vehicles`, in all four combinations.
//
// The artboard's own garage: three live vehicles in three different due states,
// one sold under its own tinted header, and the reorder hint beneath. Three
// states rather than three identical rows on purpose — the colour census can
// only see a status colour that is actually drawn, and a screen of "all good"
// would pass the check while the overdue ink was wrong.
@Tags(['parity'])
library;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/clock_suspicion.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/due/vehicle_due_snapshot.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/data/repositories/due_snapshot_provider.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/entry_counts_provider.dart';
import 'package:odova/features/vehicles/presentation/vehicles_screen.dart';
import 'package:odova/l10n/locale_controller.dart';

import '../support/due_case.dart';
import 'support/parity_capture.dart';

const _golf = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA';
const _transit = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVB';
const _cb500x = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVC';
const _yamaha = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD';

VehicleId _id(String raw) => VehicleId.tryParse(raw)!;

/// A snapshot in [worst], reading [km] as of today.
///
/// [label] is the worst item's own name. `ServiceItem.label` is what a CUSTOM
/// item carries and what the row prints when it has one, so the artboard's "oil
/// and filter" is the app doing its job rather than a string the capture
/// invented — and without it the row falls back to the generic noun, which in
/// Persian is long enough to wrap the line and shift every band below it.
VehicleDueSnapshot _snapshot({
  required DueState? worst,
  required int km,
  String? label,
}) => VehicleDueSnapshot(
  assessments: const [],
  summary: DueSummary(
    counts: worst == null ? const {} : {worst: 1},
    worstItem: label == null
        ? null
        : ServiceItem(
            id: ServiceItemId.tryParse(
              'rem_01JQ8ZK3M7F0R6XN2E9TB4HCVA',
            )!,
            vehicleId: _id(_golf),
            kind: ServiceKind.custom,
            label: label,
            priority: ServicePriority.safety,
            rollover: ServiceRollover.fromActual,
            createdAtUtcMs: 1000,
            updatedAtUtcMs: 1000,
          ),
    worst: worst == null
        ? null
        : DueAssessment(
            state: worst,
            driver: DueDriver.distance,
            confidence: RateConfidence.measured,
            progress: 0.9,
          ),
  ),
  rate: const DailyDistance(
    metresPerDay: 40000,
    confidence: RateConfidence.measured,
  ),
  // ENTERED, not projected: the artboard's figures carry no `~`, which is
  // the state a garage is in the day after somebody logs a fill-up.
  estimate: OdometerEstimate(
    metres: km * 1000,
    asOf: CivilDate.tryParse('2026-09-04')!,
    projection: OdometerProjection.entered,
    staleDays: 0,
  ),
  clock: ClockSuspicion(
    isSuspect: false,
    observedToday: CivilDate.tryParse('2026-09-04')!,
  ),
);

/// The artboard's garage, in the artboard's order.
///
/// The SOLD one is handed over FIRST, so the capture proves the screen sinks it
/// rather than proving the fixture was already sorted.
List<Vehicle> _garage({required bool rtl}) => [
  _vehicle(
    _yamaha,
    'Yamaha MT-07',
    type: VehicleType.motorcycle,
    fuel: FuelKind.petrol,
    status: VehicleStatus.sold,
    soldOn: '2024-03-12',
    sortOrder: 3,
  ),
  _vehicle(
    _golf,
    rtl ? 'گلف' : 'The Golf',
    make: rtl ? 'فولکس‌واگن' : 'VW',
    model: rtl ? 'گلف ۷' : 'Golf VII',
    year: 2016,
  ),
  _vehicle(
    _transit,
    rtl ? 'ترنزیت' : 'Transit',
    type: VehicleType.van,
    make: rtl ? 'فورد' : 'Ford',
    model: rtl ? 'ترنزیت' : 'Transit',
    year: 2019,
    business: true,
    sortOrder: 1,
  ),
  _vehicle(
    _cb500x,
    'CB500X',
    type: VehicleType.motorcycle,
    fuel: FuelKind.petrol,
    make: rtl ? 'هوندا' : 'Honda',
    year: 2021,
    sortOrder: 2,
  ),
];

Vehicle _vehicle(
  String id,
  String name, {
  VehicleType type = VehicleType.car,
  FuelKind fuel = FuelKind.diesel,
  VehicleStatus status = VehicleStatus.active,
  String? make,
  String? model,
  int? year,
  bool business = false,
  String? soldOn,
  int sortOrder = 0,
}) => Vehicle(
  id: _id(id),
  name: name,
  vehicleType: type,
  fuelKindDefault: fuel,
  status: status,
  make: make,
  model: model,
  year: year,
  isBusiness: business,
  soldOn: soldOn,
  sortOrder: sortOrder,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

void main() {
  setUpAll(loadParityFonts);

  for (final config in kParityCases) {
    testWidgets('vehicles ${config.theme}/${config.dir}', (tester) async {
      // The artboard translates the vehicle NAMES and the make and model. The
      // app never would — they are the user's own words — but the capture has
      // to compare like with like, so the fixture carries the artboard's text
      // in the direction the artboard drew it.
      final rtl = config.dir == 'rtl';
      // SUPPLIED, not a database. `vehiclesProvider` is a drift stream and a
      // drift stream never delivers inside a widget test's fake async — the
      // first version of this file used a real `NativeDatabase.memory()` and
      // hung for ten minutes with no output. The screen still does the work
      // this capture is about: it splits live from sold and sorts the sold to
      // the bottom regardless of the order it is handed.
      await captureParity(
        tester,
        screen: 'vehicles',
        config: config,
        // §7: `vehicles` opens from the Settings row, so the reference draws
        // the Settings tab active beneath it. A capture of the body alone is a
        // capture of a screen nobody sees, and the band profile reads the
        // bar's ten icons and labels as edges that are simply absent.
        tab: 3,
        child: ProviderScope(
          overrides: <Override>[
            vehiclesProvider.overrideWith(
              (ref) => Stream.value(_garage(rtl: rtl)),
            ),
            // The row reads `Settings.distance_unit` for a vehicle with no
            // override of its own, and `settingsProvider` is another drift
            // stream that will not deliver inside one captured frame.
            settingsProvider.overrideWith(
              (ref) => Stream.value(dueFixtureSettings),
            ),
            clockProvider.overrideWithValue(
              Clock.fixed(DateTime.utc(2026, 9, 4)),
            ),
            // A phone whose REGION matches the artboard. The dates there read
            // "12 March 2024" and the numbers group with commas, which is
            // `en-GB` — SPEC.md §5 puts both under the region, and `en-US`
            // would draw "March 12, 2024" and be equally correct for somebody
            // else. The non-Latin cases take a continental region for the same
            // reason `vehicle.edit`'s capture does.
            deviceLocalesProvider.overrideWithValue([
              Locale(
                config.locale.languageCode,
                config.locale.languageCode == 'en' ? 'GB' : 'DE',
              ),
            ]),
            // SUPPLIED, never computed. The due engine reads six drift streams
            // and none of them delivers inside a widget test's fake async —
            // the capture would shoot four rows saying "Couldn't work out
            // what's due", which is a real state and not this one.
            vehicleDueSnapshotProvider(_id(_golf)).overrideWithValue(
              _snapshot(
                worst: DueState.overdue,
                km: 187412,
                label: rtl ? 'روغن' : 'oil and filter',
              ),
            ),
            vehicleDueSnapshotProvider(_id(_transit)).overrideWithValue(
              _snapshot(worst: DueState.ok, km: 96400),
            ),
            vehicleDueSnapshotProvider(_id(_cb500x)).overrideWithValue(
              _snapshot(worst: null, km: 23905),
            ),
            vehicleDueSnapshotProvider(_id(_yamaha)).overrideWithValue(null),
            // SYNCHRONOUS values, not futures. `captureParity` takes a single
            // frame on purpose, and a `FutureProvider` is still loading in it —
            // the sold row would photograph with no sub-line at all, which is
            // its honest LOADING state and not the state the reference draws.
            for (final id in [_golf, _transit, _cb500x])
              vehicleEntryCountsProvider(_id(id)).overrideWithValue(
                const AsyncData(null),
              ),
            vehicleEntryCountsProvider(_id(_yamaha)).overrideWithValue(
              const AsyncData((
                fillUps: 900,
                services: 120,
                costs: 100,
                trips: 60,
                reminders: 24,
              )),
            ),
          ],
          child: const VehiclesScreen(),
        ),
      );
    });
  }
}
