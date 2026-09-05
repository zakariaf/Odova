/// The vehicles, items and snapshots every Home test is built from.
///
/// **No database.** `home` reads six streams and every one of them is a drift
/// stream, which never delivers inside a widget test's fake async — the run
/// hangs and then leaves a timer that fails the NEXT test. Supplying the
/// snapshot outright also makes these tests about the SCREEN: what the due
/// engine concludes is `due_matrix_test.dart`'s question and it is asked there
/// against real rows.
///
/// Shared with `test/parity/home_parity_test.dart` on purpose. The parity
/// capture and the behaviour test have to be looking at the same screen, and
/// two fixtures that drift are two screens with one name.
library;

import 'dart:math';

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/launch_gate.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/clock_suspicion.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/due/resolve_anchor.dart';
import 'package:odova/core/due/vehicle_due_snapshot.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/ids/ulid.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/due_snapshot_provider.dart';
import 'package:odova/data/repositories/odometer_repository.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/data/repositories/service_repository.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';
import 'package:odova/data/ui_state/ui_state_provider.dart';
import 'package:odova/data/ui_state/ui_state_store.dart';
import 'package:odova/l10n/locale_controller.dart';

import '../../app/routing/shell_harness.dart';

/// The day every Home fixture is "today".
final CivilDate homeToday = CivilDate.tryParse('2026-09-05')!;

/// The active vehicle.
final VehicleId golfId = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA')!;

/// A second vehicle, for the switcher and the other-vehicles row.
final VehicleId vanId = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVB')!;

/// Builds a vehicle.
Vehicle homeVehicle(
  VehicleId id,
  String name, {
  VehicleStatus status = VehicleStatus.active,
  String? soldOn,
}) => Vehicle(
  id: id,
  name: name,
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: status,
  soldOn: soldOn,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// Settings pointing at [active], in kilometres and euros.
AppSettings homeSettings(VehicleId? active) => AppSettings(
  schemaVersion: 1,
  currencyDefault: Currency.tryParse('EUR')!,
  activeVehicleId: active,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// A tracked, active item called [label].
ServiceItem homeItem(
  String label, {
  String suffix = 'A',
  bool isTracked = true,
  bool isActive = true,
  String? snoozedUntil,
}) => ServiceItem(
  // 26 Crockford characters, the last one varied so two items are two ids.
  id: ServiceItemId.tryParse('rem_01JQ8ZK3M7F0R6XN2E9TB4HCV$suffix')!,
  vehicleId: golfId,
  kind: ServiceKind.custom,
  label: label,
  priority: ServicePriority.normal,
  rollover: ServiceRollover.fromActual,
  // A SCHEDULE, because `service_items` has a CHECK that refuses an item with
  // no interval and no target: SPEC.md §3's invariant that an item which can
  // never come due is not a harmless empty row. The engine's answer is
  // supplied by the fixture's snapshot, so the value here only has to be
  // legal.
  intervalMonths: 12,
  isTracked: isTracked,
  isActive: isActive,
  snoozedUntil: snoozedUntil,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// An assessment in [state], due on [dueOn].
DueAssessment homeAssessment({
  DueState state = DueState.due,
  DueDriver driver = DueDriver.time,
  RateConfidence confidence = RateConfidence.measured,
  String dueOn = '2026-09-10',
  int? remainingMetres,
  int? remainingDays = 5,
  int? dueAtOdometerMetres,
  double progress = 0.7,
}) {
  final date = CivilDate.tryParse(dueOn);
  return DueAssessment(
    state: state,
    driver: driver,
    confidence: confidence,
    progress: progress,
    remainingMetres: remainingMetres,
    remainingDays: remainingDays,
    // The anchor line's two halves. §9's card table names an odometer for
    // every distance-driven state and a date for every time-driven one, and a
    // fixture that supplied neither photographed a card with no third line —
    // which reads as "the app does not print one" rather than "this fixture
    // did not say".
    dueAtOdometerMetres: dueAtOdometerMetres,
    dueOn: driver == DueDriver.distance ? null : date,
    projectedDueDate: date,
    anchor: DueAnchor(
      date: driver == DueDriver.distance ? null : date,
      dateRung: driver == DueDriver.distance ? null : AnchorRung.record,
      odometerRung: driver == DueDriver.time ? null : AnchorRung.record,
    ),
  );
}

/// A snapshot over [items], with a summary derived from them.
///
/// [metresPerDay] is the vehicle's rate. It matters for the staleness strip:
/// §9's second threshold is 30 days AND projected drift, and the drift is the
/// rate times the staleness — so a fixture that left the rate alone could not
/// express "thirty days and the car did not move".
VehicleDueSnapshot homeSnapshot(
  List<AssessedItem> items, {
  OdometerEstimate? estimate,
  int metresPerDay = 40000,
}) {
  final counts = <DueState, int>{};
  for (final (_, assessment) in items) {
    counts[assessment.state] = (counts[assessment.state] ?? 0) + 1;
  }
  return VehicleDueSnapshot(
    assessments: items,
    estimate: estimate,
    summary: DueSummary(
      counts: counts,
      worst: items.isEmpty ? null : items.first.$2,
      worstItem: items.isEmpty ? null : items.first.$1,
    ),
    rate: DailyDistance(
      metresPerDay: metresPerDay,
      confidence: RateConfidence.measured,
    ),
    clock: ClockSuspicion(isSuspect: false, observedToday: homeToday),
  );
}

/// An entered reading of [km], taken [staleDays] ago.
OdometerEstimate homeEstimate(int km, {int staleDays = 0}) => OdometerEstimate(
  metres: km * 1000,
  asOf: homeToday.addDays(-staleDays),
  projection: staleDays == 0
      ? OdometerProjection.entered
      : OdometerProjection.projected,
  staleDays: staleDays,
);

/// Puts one manual reading in [db], for the monotonicity case.
Future<void> seedReading(
  AppDatabase db, {
  required int metres,
  required String occurredOn,
  String suffix = 'A',
}) async {
  final saved = await OdometerRepository(db).saveReading(
    OdometerReading(
      id: OdometerReadingId.tryParse('odo_01JQ8ZK3M7F0R6XN2E9TB4HCV$suffix')!,
      vehicleId: golfId,
      occurredOn: occurredOn,
      odometer: Distance(metres),
      odometerUnit: DistanceUnit.km,
      source: OdometerSource.manual,
      createdAtUtcMs: 1000,
      updatedAtUtcMs: 1000,
    ),
    vehicleUnit: DistanceUnit.km,
  );
  expect(saved, isA<Ok<SavedReading, PersistFailure>>());
}

/// A fill-up of [litres] on [occurredOn] costing [cents].
FillUp homeFillUp({
  String occurredOn = '2026-09-02',
  double litres = 42.8,
  int cents = 7420,
  int odometerKm = 187412,
  String suffix = 'A',
}) => FillUp(
  id: FillUpId.tryParse('fil_01JQ8ZK3M7F0R6XN2E9TB4HCV$suffix')!,
  vehicleId: golfId,
  occurredOn: occurredOn,
  odometer: Distance(odometerKm * 1000),
  odometerUnit: DistanceUnit.km,
  fuelKind: FuelKind.diesel,
  quantity: LiquidVolume(Volume((litres * 1000).round())),
  quantityUnit: VolumeUnit.l,
  totalCost: Money(cents, Currency.tryParse('EUR')!),
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// A real, empty, in-memory database — for the WRITES only.
///
/// Home's reads are all supplied by [pumpHome], so nothing here subscribes to a
/// drift stream: a stream never delivers under `testWidgets` and leaves a timer
/// that fails the next test. A write is an ordinary Future and works fine, so a
/// test that asserts "this wrote `is_active = false`" can assert it against the
/// row rather than against a recording fake that only proves a method was
/// called.
AppDatabase homeDatabase() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

/// Puts a vehicle and the given items in a database, so a targeted UPDATE has
/// a row to find.
///
/// `setItemActive` writes two columns of an EXISTING row and answers
/// `NotFound` when there is none — the right behaviour, and why this exists: a
/// test that tapped "Turn this off" against an empty table would watch the
/// error path and call it a pass.
///
/// The VEHICLE goes in first, and every write is checked. `service_items` has a
/// foreign key to `vehicles`, so an item inserted on its own is refused —
/// `guardPersist` turns that into an `Err` the caller can ignore, and ignoring
/// it leaves the same empty table with no sign of why.
/// The id factory the fixtures write with.
///
/// Seeded, so two runs of a test mint the same ids and a failure names the
/// same row twice.
UlidFactory homeIds() => UlidFactory(clock: const Clock(), random: Random(7));

Future<void> seedItems(
  AppDatabase db,
  List<ServiceItem> items, {
  Vehicle? vehicle,
}) async {
  final ids = homeIds();
  final saved = await VehicleRepository(
    db,
    ids,
  ).save(vehicle ?? homeVehicle(golfId, 'The Golf'));
  expect(saved, isA<Ok<Vehicle, PersistFailure>>());

  final repository = ServiceRepository(db, ids);
  for (final item in items) {
    expect(
      await repository.saveItem(item),
      isA<Ok<ServiceItem, PersistFailure>>(),
      reason: item.label,
    );
  }
}

/// Mounts the app on `home` with everything the screen reads supplied.
///
/// [snapshots] is keyed by vehicle: a vehicle absent from it has no snapshot at
/// all, which is what "the engine could not answer" looks like — a different
/// thing from a snapshot with no items.
Future<ProviderContainer> pumpHome(
  WidgetTester tester, {
  List<Vehicle>? vehicles,
  Map<VehicleId, VehicleDueSnapshot?> snapshots = const {},
  List<FillUp> fillUps = const [],
  Locale? locale = const Locale('en'),
  TextScaler? textScaler,
  VehicleId? active,
  AppDatabase? database,
  Map<String, String> uiState = const {},
  List<ServiceRecord> records = const [],
  bool unreadable = false,
}) {
  final garage = vehicles ?? [homeVehicle(golfId, 'The Golf')];
  return pumpShell(
    tester,
    '/',
    locale: locale,
    settings: homeSettings(active ?? garage.first.id),
    vehicles: garage,
    facts: LaunchFacts(
      onboardingDone: true,
      liveVehicleCount: garage.length,
      migrationFailed: false,
    ),
    wrap: textScaler == null
        ? null
        : (app) => Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: app,
            ),
          ),
    overrides: <Override>[
      if (database != null) appDatabaseProvider.overrideWithValue(database),
      // In memory, seeded. The real one is a file `bootstrap()` opens, and a
      // widget test has neither a bootstrap nor an application support
      // directory.
      uiStateProviderStore.overrideWithValue(UiStateStore.inMemory(uiState)),
      // A phone whose REGION matches the artboard: dates read "14 March 2027"
      // and numbers group with commas, which is `en-GB`. SPEC.md §5 puts both
      // under the REGION rather than the language, so this has to be set even
      // when the language is English — `en-US` would draw "March 14, 2027" and
      // be equally correct for somebody else.
      deviceLocalesProvider.overrideWithValue([
        Locale(
          locale?.languageCode ?? 'en',
          (locale?.languageCode ?? 'en') == 'en' ? 'GB' : 'DE',
        ),
      ]),
      // Fixed, and at [homeToday]. Home reads the clock to build its stack, so
      // a suite run on a different day would order the same fixture
      // differently — the kind of test that passes for eleven months.
      clockProvider.overrideWithValue(
        Clock.fixed(DateTime.utc(2026, 9, 5, 12)),
      ),
      for (final v in garage)
        // An unreadable store has NO snapshot — that is what "could not be
        // read" means, and a fixture that supplied one alongside a failing
        // stream would be describing a state the app cannot be in.
        vehicleDueSnapshotProvider(
          v.id,
        ).overrideWithValue(unreadable ? null : snapshots[v.id]),
      // `fillUps` is given NEWEST FIRST, the order `latestFillUpProvider`'s
      // query produces, and the fixture takes the first of them. Which end of
      // that list is the newest is asserted where the query is —
      // `test/data/repositories/latest_fill_up_test.dart` — because a fixture
      // that decided it here would be checking its own arithmetic.
      for (final v in garage)
        latestFillUpProvider(v.id).overrideWith(
          (ref) => Stream.value(
            v.id == golfId ? fillUps.firstOrNull : null,
          ),
        ),
      // The all-clear's receipt reads the most recent record. Supplied like
      // everything else the screen reads, so no drift stream is subscribed.
      for (final v in garage)
        serviceRecordsProvider(v.id).overrideWith(
          (ref) => Stream.value(
            v.id == golfId ? records : const <ServiceRecord>[],
          ),
        ),
      // §9's *Error*: "the store cannot be read". One failing input is enough
      // — `vehicleStoreUnreadableProvider` watches all six and answers on any
      // of them, because a screen that only noticed a broken ITEMS query would
      // draw a confident all-clear over a broken readings one.
      if (unreadable)
        for (final v in garage)
          odometerReadingsProvider(v.id).overrideWith(
            (ref) => Stream<List<OdometerReading>>.error(
              StateError('the database is unreadable'),
            ),
          ),
    ],
  );
}
