// `vehicles` — the garage.
//
// SPEC.md §8: "Management only — *not* where you switch cars." The status
// DECISION is `garage_status_test.dart`; this is what the screen draws.
//
// **No database.** `vehiclesProvider` and `vehicleDueSnapshotProvider` are
// supplied outright, because a drift stream never delivers inside a widget
// test's fake async — `pumpAndSettle` waits for a frame that never comes and
// the run hangs for ten minutes with no output. `provider_harness.dart` says
// so; this file learned it the expensive way and says so here too. Supplying
// them also makes this a test about the SCREEN rather than about drift.
//
// **One pump per test, never two.** Riverpod asserts the number of overrides is
// constant across a rebuild, so a test that pumps one vehicle and then two
// dies inside `ProviderScope.updateOverrides` rather than in an expectation.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/clock_suspicion.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/due/vehicle_due_snapshot.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/due_snapshot_provider.dart';
import 'package:odova/features/vehicles/presentation/vehicles_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';

import '../../../parity/support/parity_capture.dart'
    show kReferenceDpr, kReferencePhysical;
import '../../../support/pump_app.dart';

final VehicleId _golf = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA')!;
final VehicleId _polo = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVB')!;

Vehicle _vehicle(
  VehicleId id,
  String name, {
  VehicleStatus status = VehicleStatus.active,
  String? colour,
}) => Vehicle(
  id: id,
  name: name,
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: status,
  colour: colour,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// A snapshot whose worst item is in [worst], or one that tracks nothing.
VehicleDueSnapshot _snapshot(DueState? worst) => VehicleDueSnapshot(
  assessments: const [],
  summary: DueSummary(
    counts: worst == null ? const {} : {worst: 1},
    // NULL means the engine ran and found nothing to report — SPEC.md §8's
    // "No reminders yet". That is a different sentence from a null SNAPSHOT,
    // which means it could not run at all.
    worst: worst == null
        ? null
        : DueAssessment(
            state: worst,
            driver: DueDriver.distance,
            confidence: RateConfidence.measured,
            progress: 0.5,
          ),
  ),
  rate: const DailyDistance(
    metresPerDay: 40000,
    confidence: RateConfidence.measured,
  ),
  clock: ClockSuspicion(
    isSuspect: false,
    observedToday: CivilDate.tryParse('2026-11-20')!,
  ),
);

/// Pumps the garage with [vehicles].
///
/// A vehicle PRESENT in [due] has a snapshot; its value is that snapshot's
/// worst state, and null there means "ran, found nothing". A vehicle ABSENT
/// from [due] has no snapshot at all — the engine could not answer.
Future<void> _pump(
  WidgetTester tester, {
  required List<Vehicle> vehicles,
  Map<VehicleId, DueState?> due = const {},
}) async {
  tester.view.physicalSize = kReferencePhysical;
  tester.view.devicePixelRatio = kReferenceDpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await pumpApp(
    tester,
    const VehiclesScreen(),
    overrides: <Override>[
      vehiclesProvider.overrideWith((ref) => Stream.value(vehicles)),
      for (final v in vehicles)
        vehicleDueSnapshotProvider(v.id).overrideWithValue(
          due.containsKey(v.id) ? _snapshot(due[v.id]) : null,
        ),
    ],
  );
  await tester.pumpAndSettle();
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(VehiclesScreen)));

String? _line(WidgetTester tester, String name) => tester
    .widgetList<CalmListRow>(find.byType(CalmListRow))
    .firstWhere((r) => r.title == name)
    .subtitle;

void main() {
  testWidgets(
    'the caption says where the switcher is, because this is not it',
    (
      tester,
    ) async {
      // SPEC.md §8: "Management only — *not* where you switch cars." A list of
      // cars is exactly where somebody looks for a switcher, so the screen says
      // where it lives rather than leaving them to hunt.
      await _pump(tester, vehicles: [_vehicle(_golf, 'The Golf')]);
      expect(find.text(_l10n(tester).vehiclesIntro), findsOneWidget);
    },
  );

  testWidgets("SPEC's status rows, each spelled out in words", (tester) async {
    // "Colour is never the only signal" — §8. The dot is the SECOND channel,
    // and this asserts the first one exists for every state. One vehicle every
    // time, so the override count never moves.
    for (final (state, expected)
        in <
          (
            DueState?,
            String Function(AppLocalizations),
          )
        >[
          (null, (l) => l.vehicleStatusNoReminders),
          (DueState.ok, (l) => l.vehicleStatusAllGood),
          (DueState.needsOdometer, (l) => l.vehicleStatusNeedsOdometer),
          (DueState.unknown, (l) => l.vehicleStatusUnknown),
        ]) {
      await _pump(
        tester,
        vehicles: [_vehicle(_golf, 'The Golf')],
        due: {_golf: state},
      );
      expect(
        _line(tester, 'The Golf'),
        expected(_l10n(tester)),
        reason: '$state',
      );
    }
  });

  testWidgets('"no reminders" and "could not answer" are different sentences', (
    tester,
  ) async {
    // The distinction the screen exists to keep: a vehicle whose engine RAN and
    // found nothing tracked says "No reminders yet", and one whose engine could
    // not run says so. Collapsing them would tell a user with no service items
    // that something went wrong, or a user whose data failed to load that
    // everything is simply untracked — SPEC.md §2, never guess in a way that
    // looks like fact.
    await _pump(
      tester,
      vehicles: [_vehicle(_golf, 'The Golf'), _vehicle(_polo, 'The Polo')],
      // The Polo is absent from the map: no snapshot at all.
      due: {_golf: null},
    );
    expect(_line(tester, 'The Golf'), _l10n(tester).vehicleStatusNoReminders);
    expect(_line(tester, 'The Polo'), _l10n(tester).vehicleStatusUnknown);
  });

  testWidgets('a sold vehicle shows a dash and computes nothing', (
    tester,
  ) async {
    // §8: "a sold vehicle computes no reminders and its card shows —". Not
    // "All good", which would claim an answer about a car the user sold — and
    // the snapshot here says `ok`, so a screen that ignored the status would
    // print exactly that.
    await _pump(
      tester,
      vehicles: [
        _vehicle(_golf, 'The Golf'),
        _vehicle(_polo, 'The Polo', status: VehicleStatus.sold),
      ],
      due: {_golf: DueState.ok, _polo: DueState.ok},
    );
    expect(_line(tester, 'The Polo'), '—');
    expect(_line(tester, 'The Golf'), _l10n(tester).vehicleStatusAllGood);
  });

  testWidgets('sold and archived sit under their own header', (tester) async {
    // §8: they sink to the bottom REGARDLESS of `sort_order`. A user who sold a
    // car and never reordered would otherwise find it above the one they drive
    // — so the sold Polo is handed to the screen FIRST here.
    await _pump(
      tester,
      vehicles: [
        _vehicle(_polo, 'The Polo', status: VehicleStatus.sold),
        _vehicle(_golf, 'The Golf'),
      ],
    );
    final groups = tester.widgetList<CalmRowGroup>(find.byType(CalmRowGroup));
    expect(groups, hasLength(2));
    expect(groups.first.header, isNull);
    expect(groups.last.header, _l10n(tester).vehiclesSoldArchived);
    for (final (group, name) in [
      (groups.first, 'The Golf'),
      (groups.last, 'The Polo'),
    ]) {
      expect(
        find.descendant(
          of: find.byWidget(group),
          matching: find.text(name),
        ),
        findsOneWidget,
        reason: name,
      );
    }
  });

  testWidgets('the reorder hint is hidden for a single vehicle', (
    tester,
  ) async {
    // Neither gesture applies to a list of one, and a hint for something
    // impossible is noise.
    await _pump(tester, vehicles: [_vehicle(_golf, 'The Golf')]);
    expect(find.text(_l10n(tester).vehiclesReorderHint), findsNothing);
  });

  testWidgets('the reorder hint counts LIVE vehicles, not rows', (
    tester,
  ) async {
    // Two rows where one is sold is still a list of one: sold vehicles are not
    // reorderable, so a hint about dragging them is a hint about nothing.
    await _pump(
      tester,
      vehicles: [
        _vehicle(_golf, 'The Golf'),
        _vehicle(_polo, 'The Polo', status: VehicleStatus.sold),
      ],
    );
    expect(find.text(_l10n(tester).vehiclesReorderHint), findsNothing);
  });

  testWidgets('the reorder hint appears with two live vehicles', (
    tester,
  ) async {
    await _pump(
      tester,
      vehicles: [_vehicle(_golf, 'The Golf'), _vehicle(_polo, 'The Polo')],
    );
    expect(find.text(_l10n(tester).vehiclesReorderHint), findsOneWidget);
  });

  testWidgets('the row never disappears when the engine cannot answer', (
    tester,
  ) async {
    // §8: "a dueSummary that throws still renders the row with a hollow dot and
    // Couldn't work out what's due". The row is the user's way back to the
    // vehicle; losing it loses the car — which is why the screen draws from the
    // VEHICLE list and treats the snapshot as decoration on top.
    await _pump(tester, vehicles: [_vehicle(_golf, 'The Golf')]);
    expect(find.text('The Golf'), findsOneWidget);
    expect(_line(tester, 'The Golf'), _l10n(tester).vehicleStatusUnknown);
  });

  testWidgets('there is no empty state, because the screen needs a vehicle', (
    tester,
  ) async {
    // §8: `vehicles` is unreachable without one — first run guarantees it. An
    // empty state here would be dead code nobody could ever see, and dead UI is
    // UI nobody maintains.
    await _pump(tester, vehicles: [_vehicle(_golf, 'The Golf')]);
    for (final label in ['No vehicles', 'Add your first', 'Nothing here']) {
      expect(find.text(label), findsNothing, reason: label);
    }
  });
}
