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
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:odova/core/result.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/vehicles/delete_counts.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/due_snapshot_provider.dart';
import 'package:odova/features/vehicles/entry_counts_provider.dart';
import 'package:odova/features/vehicles/presentation/vehicles_screen.dart';
import 'package:odova/features/vehicles/vehicles_notifier.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/ui/calm/calm_icon_tile.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_swipe_actions.dart';

import '../../../parity/support/parity_capture.dart'
    show kReferenceDpr, kReferencePhysical;
import '../../../support/due_case.dart';
import '../../../support/pump_app.dart';

final VehicleId _golf = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA')!;
final VehicleId _polo = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVB')!;
final VehicleId _transit = VehicleId.tryParse(
  'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVC',
)!;

Vehicle _vehicle(
  VehicleId id,
  String name, {
  VehicleStatus status = VehicleStatus.active,
  String? colour,
  String? make,
  String? model,
  int? year,
  bool business = false,
  String? soldOn,
  FuelKind fuel = FuelKind.diesel,
}) => Vehicle(
  id: id,
  name: name,
  vehicleType: VehicleType.car,
  fuelKindDefault: fuel,
  status: status,
  colour: colour,
  make: make,
  model: model,
  year: year,
  isBusiness: business,
  soldOn: soldOn,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// A snapshot whose worst item is in [worst], or one that tracks nothing.
VehicleDueSnapshot _snapshot(
  DueState? worst, {
  OdometerEstimate? estimate,
}) => VehicleDueSnapshot(
  estimate: estimate,
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

/// A reading taken [daysAgo], projecting to [metres] today.
OdometerEstimate _estimate({
  required int metres,
  required int daysAgo,
  required OdometerProjection projection,
}) => OdometerEstimate(
  metres: metres,
  asOf: CivilDate.tryParse('2026-11-20')!.addDays(-daysAgo),
  projection: projection,
  staleDays: daysAgo,
);

/// Pumps the garage with [vehicles].
///
/// A vehicle PRESENT in [due] has a snapshot; its value is that snapshot's
/// worst state, and null there means "ran, found nothing". A vehicle ABSENT
/// from [due] has no snapshot at all — the engine could not answer.
Future<void> _pump(
  WidgetTester tester, {
  required List<Vehicle> vehicles,
  Locale? locale,
  Map<VehicleId, DueState?> due = const {},
  Map<VehicleId, OdometerEstimate> estimates = const {},
  Map<VehicleId, DeleteCounts> counts = const {},
  void Function(List<VehicleId>)? onReorder,
}) async {
  tester.view.physicalSize = kReferencePhysical;
  tester.view.devicePixelRatio = kReferenceDpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await pumpApp(
    tester,
    const VehiclesScreen(),
    locale: locale,
    overrides: <Override>[
      // The FORMATS tag follows the device region, not the UI language —
      // SPEC.md §5, and the reason `pumpApp(locale:)` alone left the year in
      // Latin digits while the strings were Persian. Both have to move.
      if (locale != null) deviceLocalesProvider.overrideWithValue([locale]),
      vehiclesProvider.overrideWith((ref) => Stream.value(vehicles)),
      // A VALUE. The row reads `Settings.distance_unit` as the fallback for a
      // vehicle with no override, and `settingsProvider` is a drift stream —
      // which never delivers under `testWidgets` and leaves a timer pending
      // after the tree is gone.
      settingsProvider.overrideWith((ref) => Stream.value(dueFixtureSettings)),
      for (final v in vehicles)
        vehicleDueSnapshotProvider(v.id).overrideWithValue(
          due.containsKey(v.id)
              ? _snapshot(due[v.id], estimate: estimates[v.id])
              : null,
        ),
      for (final v in vehicles)
        vehicleEntryCountsProvider(
          v.id,
        ).overrideWith((ref) async => counts[v.id]),
      if (onReorder != null)
        vehiclesNotifierProvider.overrideWith(
          () => _RecordingReorder(onReorder),
        ),
    ],
  );
  await tester.pumpAndSettle();
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(VehiclesScreen)));

CalmListRow _row(WidgetTester tester, String name) => tester
    .widgetList<CalmListRow>(find.byType(CalmListRow))
    .firstWhere((r) => r.title == name);

/// The garage row's THIRD line — odometer and status, `.row__sub num`.
///
/// Bidi isolates STRIPPED. They are asserted on their own below, and leaving
/// them in every expectation would make each one a test of the isolate as well
/// as of the sentence, so a wrong word and a missing isolate would fail
/// identically.
String? _line(WidgetTester tester, String name) =>
    _strip(_row(tester, name).detail);

String? _strip(String? text) =>
    text?.replaceAll('\u2068', '').replaceAll('\u2069', '');

/// Records the ids the screen asks the repository to reorder.
class _RecordingReorder extends VehiclesNotifier {
  _RecordingReorder(this.onReorder);

  final void Function(List<VehicleId>) onReorder;

  @override
  Future<Result<void, PersistFailure>> reorder(List<VehicleId> ids) async {
    onReorder(ids);
    return const Ok(null);
  }
}

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
    // The head is a SIBLING of the tinted group, on the page above it — nine
    // artboards draw it that way and none draws a title inside a group.
    expect(
      tester.widget<CalmSectionHead>(find.byType(CalmSectionHead)).title,
      _l10n(tester).vehiclesSoldArchived,
    );
    expect(
      find.descendant(
        of: find.byType(CalmRowGroup),
        matching: find.byType(CalmSectionHead),
      ),
      findsNothing,
    );
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

  testWidgets('the second line names the vehicle, not its state', (
    tester,
  ) async {
    // The artboard's `VW Golf VII · 2016 · diesel`. Make, model, year and fuel
    // are what tell two silver hatchbacks apart in a garage of four, and none
    // of them is a status.
    await _pump(
      tester,
      vehicles: [
        _vehicle(_golf, 'The Golf', make: 'VW', model: 'Golf VII', year: 2016),
      ],
      due: {_golf: DueState.ok},
    );
    expect(
      _row(tester, 'The Golf').subtitle,
      'VW · Golf VII · 2016 · Diesel',
    );
  });

  testWidgets('a business vehicle says so where the fuel goes', (tester) async {
    // `Ford Transit · 2019 · business` in the artboard. It replaces the fuel
    // rather than joining it: SPEC.md §8 gives the line four slots and a fifth
    // would wrap on a German row.
    await _pump(
      tester,
      vehicles: [
        _vehicle(
          _polo,
          'Transit',
          make: 'Ford',
          model: 'Transit',
          year: 2019,
          business: true,
        ),
      ],
      due: {_polo: DueState.ok},
    );
    expect(
      _row(tester, 'Transit').subtitle,
      'Ford · Transit · 2019 · Business',
    );
  });

  testWidgets('a vehicle with no facts shows the one fact it must have', (
    tester,
  ) async {
    // Not an empty string and not a lone separator. SPEC.md §8: everything but
    // the name is nullable and asked later, so a vehicle added in thirty
    // seconds has only its fuel here — and `· · · Diesel` would be three
    // absences drawn as punctuation.
    //
    // `fuel_kind_default` is the one field on this line that cannot be null:
    // first run prefills it and the domain has no vehicle without one, which is
    // why the line never disappears entirely.
    await _pump(
      tester,
      vehicles: [_vehicle(_golf, 'The Golf')],
      due: {_golf: DueState.ok},
    );
    expect(_row(tester, 'The Golf').subtitle, 'Diesel');
  });

  testWidgets('the third line pairs the odometer with the status', (
    tester,
  ) async {
    // `187,412 km · all good` — SPEC.md §8: "Odometer and one-line status share
    // the third line because that is the pair people scan for."
    await _pump(
      tester,
      vehicles: [_vehicle(_golf, 'The Golf')],
      due: {_golf: DueState.ok},
      estimates: {
        _golf: _estimate(
          metres: 187412000,
          daysAgo: 0,
          projection: OdometerProjection.entered,
        ),
      },
    );
    expect(_line(tester, 'The Golf'), '187,412 km · All good');
  });

  testWidgets('a stale reading is approximate, rounded, and dated', (
    tester,
  ) async {
    // SPEC.md §8's stale row: `~187,400 km · Odometer last updated 4 months
    // ago`. Three separate rules meet here and each one is a way of not lying —
    // the `~` says it is a projection, the rounding to 100 km stops it reading
    // like a measurement, and the bucketed age says "4 months" rather than the
    // 122 days that would look like precision about a guess.
    await _pump(
      tester,
      vehicles: [_vehicle(_golf, 'The Golf')],
      due: {_golf: DueState.ok},
      estimates: {
        _golf: _estimate(
          metres: 187412000,
          daysAgo: 122,
          projection: OdometerProjection.projected,
        ),
      },
    );
    final line = _line(tester, 'The Golf')!;
    expect(line, startsWith('~187,400 km · '));
    expect(line, contains('about 4 months ago'), reason: 'bucketed');
    expect(line, isNot(contains('122')), reason: 'never a day count');
  });

  testWidgets('an expired reading is the entered figure, with no ~', (
    tester,
  ) async {
    // Past 180 days Odova stops guessing entirely: `187,412 km · last entered
    // 12 Jul 2025`. The figure is EXACT because it is a reading rather than a
    // projection, and rounding it would make a fact look like an estimate — the
    // opposite error from the stale row above, and the same rule.
    await _pump(
      tester,
      vehicles: [_vehicle(_golf, 'The Golf')],
      due: {_golf: DueState.needsOdometer},
      estimates: {
        _golf: _estimate(
          metres: 187412000,
          daysAgo: 400,
          projection: OdometerProjection.expired,
        ),
      },
    );
    final line = _line(tester, 'The Golf')!;
    expect(line, startsWith('187,412 km · '));
    expect(line, isNot(contains('~')), reason: 'a reading, not a projection');
    expect(line, contains('2025'), reason: 'a date, not an age');
    expect(line, isNot(contains('ago')));
  });

  testWidgets('a vehicle with no reading shows the status alone', (
    tester,
  ) async {
    // No odometer half, and no placeholder standing in for one. A `— km` would
    // be a unit attached to nothing.
    await _pump(
      tester,
      vehicles: [_vehicle(_golf, 'The Golf')],
      due: {_golf: DueState.ok},
    );
    expect(_line(tester, 'The Golf'), 'All good');
  });

  testWidgets('an overdue third line carries the overdue ink', (tester) async {
    // The artboard sets `color: var(--color-overdue-ink)` on that line alone.
    // It is the SECOND channel after the words, never the first — the line
    // already says "overdue" before any colour is applied.
    await _pump(
      tester,
      vehicles: [_vehicle(_golf, 'The Golf')],
      due: {_golf: DueState.overdue},
    );
    expect(_row(tester, 'The Golf').detailState, DueState.overdue);
  });

  testWidgets('a sold row is compact, chevroned, and says what it is', (
    tester,
  ) async {
    // SPEC.md §8, as the artboard draws it: a sold vehicle's row says what it
    // IS rather than what is due. No status dot — there is no status — and the
    // chevron in its place, because the row still opens the vehicle.
    await _pump(
      tester,
      vehicles: [
        _vehicle(_golf, 'The Golf'),
        _vehicle(
          _polo,
          'Yamaha MT-07',
          status: VehicleStatus.sold,
          soldOn: '2024-03-12',
        ),
      ],
      counts: {
        _polo: (
          fillUps: 1000,
          services: 100,
          costs: 50,
          trips: 34,
          reminders: 20,
        ),
      },
    );
    final sold = _row(tester, 'Yamaha MT-07');
    expect(sold.size, CalmRowSize.compact);
    expect(sold.showChevron, isTrue);
    expect(sold.end, isNull, reason: 'no status dot on a car that is gone');
    expect(sold.detail, isNull, reason: 'one sub-line, not two');
    expect(sold.subtitle, contains('1,204'));
    expect(sold.subtitle, contains('12'), reason: 'the sale date');
    // The live row still has both its lines and its dot.
    expect(_row(tester, 'The Golf').showChevron, isFalse);
    expect(_row(tester, 'The Golf').end, isNotNull);
  });

  testWidgets('the sold group is tinted and its header carries a count', (
    tester,
  ) async {
    // `.rowgroup--tinted` and `.section__hint`. The count is a hint beside the
    // title rather than "(1)" inside it, because it is a number and the title
    // is a heading — and above five SPEC.md §8 collapses the group to exactly
    // this header.
    await _pump(
      tester,
      vehicles: [
        _vehicle(_golf, 'The Golf'),
        _vehicle(_polo, 'Yamaha MT-07', status: VehicleStatus.sold),
      ],
    );
    final groups = tester.widgetList<CalmRowGroup>(find.byType(CalmRowGroup));
    expect(groups.last.tinted, isTrue);
    expect(groups.first.tinted, isFalse);
    expect(
      tester.widget<CalmSectionHead>(find.byType(CalmSectionHead)).hint,
      '1',
    );
  });

  testWidgets('the sold line waits for the count rather than claiming zero', (
    tester,
  ) async {
    // The counts come from a query, and a row that rendered its `=0` case while
    // that query was in flight would tell the user a car with eight years of
    // history has no entries. SPEC.md §2: never guess in a way that looks like
    // fact. Saying nothing for a frame is the honest version.
    await _pump(
      tester,
      vehicles: [
        _vehicle(_golf, 'The Golf'),
        _vehicle(
          _polo,
          'Yamaha MT-07',
          status: VehicleStatus.sold,
          soldOn: '2024-03-12',
        ),
      ],
    );
    expect(_row(tester, 'Yamaha MT-07').subtitle, isNull);
  });

  testWidgets('the odometer run is one isolate, marker and unit inside', (
    tester,
  ) async {
    // SPEC.md §8's RTL note: "Odometer and unit are one atomic run at the end
    // of the third line ... the approximation marker is `~` in every locale and
    // sits inside that run." Half the shipped locales are right-to-left, and an
    // un-isolated `187,412 km` next to Arabic text puts the unit on the wrong
    // side of the digits.
    //
    // ONE isolate, not two. `formatWithUnit` isolates already, so a `~`
    // isolated on top of it nests a second pair that says nothing the outer one
    // does not.
    await _pump(
      tester,
      vehicles: [_vehicle(_golf, 'The Golf')],
      due: {_golf: DueState.ok},
      estimates: {
        _golf: _estimate(
          metres: 187412000,
          daysAgo: 122,
          projection: OdometerProjection.projected,
        ),
      },
    );
    final raw = _row(tester, 'The Golf').detail!;
    expect(
      raw,
      startsWith('\u2068~187,400 km\u2069'),
      reason: 'one FSI, the ~ and the unit inside it, one PDI',
    );
    expect('\u2068'.allMatches(raw).length, 1);
    expect('\u2069'.allMatches(raw).length, 1);
    // The STATUS half is not isolated: it is ordinary prose in the UI language
    // and isolating it would cut it off from the sentence it belongs to.
    expect(raw.split('\u2069').last, startsWith(' · '));
  });

  group('the swipe actions', () {
    // SPEC.md §8's interaction table. The hint at the bottom of the screen
    // promises both of these in words, so a row that did not carry them would
    // make the screen lie about itself.
    testWidgets('a LIVE row carries Mark as sold and Delete', (tester) async {
      await _pump(
        tester,
        vehicles: [_vehicle(_golf, 'The Golf')],
        due: {_golf: DueState.ok},
      );
      final swipe = tester.widget<CalmSwipeActions>(
        find.byType(CalmSwipeActions),
      );
      expect(
        [for (final a in swipe.endActions) a.label],
        [
          _l10n(tester).vehicleMarkAsSold,
          _l10n(tester).commonDelete,
        ],
        reason: 'Mark as sold FIRST — §8 offers it before Delete everywhere',
      );
      expect(swipe.endActions.last.tone, CalmSwipeTone.danger);
      expect(swipe.endActions.first.tone, CalmSwipeTone.caution);
    });

    testWidgets('a SOLD row offers no sale, only a delete', (tester) async {
      // Offering "Mark as sold" on a car that is already sold is an action
      // whose only outcome is overwriting a sale date the user entered.
      await _pump(
        tester,
        vehicles: [
          _vehicle(_golf, 'The Golf'),
          _vehicle(
            _polo,
            'Yamaha MT-07',
            status: VehicleStatus.sold,
            soldOn: '2024-03-12',
          ),
        ],
      );
      final swipes = tester.widgetList<CalmSwipeActions>(
        find.byType(CalmSwipeActions),
      );
      expect(swipes, hasLength(2));
      expect(
        [for (final a in swipes.last.endActions) a.label],
        [_l10n(tester).commonDelete],
      );
    });
  });

  testWidgets('the year is shaped like every other number on the row', (
    tester,
  ) async {
    // SPEC.md §5: one numbering system, app-wide. `year.toString()` is a raw
    // Dart string and it rendered "2016" in Latin digits beside a Persian
    // odometer — the parity capture is what showed it, because the number is
    // right and only its digits are wrong.
    //
    // UNGROUPED, for the same reason `formatLongDate` is: "۱٬۹۰۰" is a
    // thousand nine hundred, which is not a year anybody has driven a car in.
    await _pump(
      tester,
      locale: const Locale('fa'),
      vehicles: [_vehicle(_golf, 'گلف', year: 2016)],
      due: {_golf: DueState.ok},
    );
    final facts = _row(tester, 'گلف').subtitle!;
    expect(facts, contains('۲۰۱۶'));
    expect(facts, isNot(contains('2016')));
    expect(facts, isNot(contains('۲٬۰۱۶')), reason: 'a year is not grouped');
  });

  group('long-press drag', () {
    // SPEC.md §8: "Long-press drag — Reorders, writes `sort_order`. Sold and
    // archived sort to the bottom regardless."
    testWidgets('the LIVE group is reorderable and the sold one is not', (
      tester,
    ) async {
      // Sold vehicles have no `sort_order` that means anything: §8 sinks them
      // regardless of it, so a drag there would write a number the screen then
      // ignores — a gesture that appears to work and does nothing.
      await _pump(
        tester,
        vehicles: [
          _vehicle(_golf, 'The Golf'),
          _vehicle(_polo, 'The Polo'),
          _vehicle(
            _transit,
            'Yamaha MT-07',
            status: VehicleStatus.sold,
            soldOn: '2024-03-12',
          ),
        ],
      );
      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ReorderableListView),
          matching: find.text('Yamaha MT-07'),
        ),
        findsNothing,
      );
    });

    testWidgets('one live vehicle gets no reorderable list at all', (
      tester,
    ) async {
      // Neither the gesture nor the hint applies to a list of one, and a
      // reorderable list of one is a long-press that lifts a row and puts it
      // back.
      await _pump(tester, vehicles: [_vehicle(_golf, 'The Golf')]);
      expect(find.byType(ReorderableListView), findsNothing);
      expect(find.text('The Golf'), findsOneWidget);
    });

    testWidgets('a drag writes the new order, ids in their new positions', (
      tester,
    ) async {
      // The repository takes the ids in order and writes each one's index. The
      // screen's job is to hand it the LIVE list in its new order — not the
      // whole garage, whose sold rows are not in this list and whose
      // `sort_order` §8 ignores.
      final reordered = <List<VehicleId>>[];
      await _pump(
        tester,
        vehicles: [
          _vehicle(_golf, 'The Golf'),
          _vehicle(_polo, 'The Polo'),
          // A SOLD vehicle in the garage, so "the live list" and "the whole
          // list" are different things. Without it the two are identical and a
          // reorder that sent every vehicle to the repository passed.
          _vehicle(
            _transit,
            'Yamaha MT-07',
            status: VehicleStatus.sold,
            soldOn: '2024-03-12',
          ),
        ],
        onReorder: reordered.add,
      );

      // A LONG PRESS, then the move. `timedDrag` starts moving immediately and
      // `ReorderableDelayedDragStartListener` never arms — the row does not
      // lift and the test reads as "nothing was reordered", which is also what
      // a broken `onReorder` looks like.
      final drag = await tester.startGesture(
        tester.getCenter(find.text('The Golf')),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      // In STEPS, with a pump between them. `ReorderableListView` recomputes
      // the drop index as the pointer moves, and one jump to the destination
      // leaves it reporting a half-travelled index — which comes back as "the
      // order did not change" and reads exactly like a broken callback.
      for (var i = 0; i < 8; i++) {
        await drag.moveBy(const Offset(0, 30));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await drag.up();
      await tester.pumpAndSettle();

      expect(reordered, hasLength(1));
      expect(
        reordered.single,
        [_polo, _golf],
        reason: 'the LIVE list, in its new order — the sold one is not in it',
      );
    });

    testWidgets('a drag with no long press reorders nothing', (tester) async {
      // §8 says LONG-PRESS drag, and the row already has a horizontal swipe on
      // it. A plain drag listener would let a scroll that starts on a row pick
      // the row up instead — and the delayed listener is the only thing
      // between the two gestures.
      final reordered = <List<VehicleId>>[];
      await _pump(
        tester,
        vehicles: [_vehicle(_golf, 'The Golf'), _vehicle(_polo, 'The Polo')],
        onReorder: reordered.add,
      );

      final drag = await tester.startGesture(
        tester.getCenter(find.text('The Golf')),
      );
      for (var i = 0; i < 8; i++) {
        await drag.moveBy(const Offset(0, 30));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await drag.up();
      await tester.pumpAndSettle();

      expect(reordered, isEmpty);
    });
  });

  testWidgets('a business vehicle with no PAINT still reads as one', (
    tester,
  ) async {
    // `VehicleColour.other` has no swatch by design (F-9.18) — the app does not
    // invent a colour it was not given. So a business van saved as `other` has
    // no paint, and the business tint is what is left to say it is a work
    // vehicle. Keying the fallback off the COLOUR rather than the resolved
    // PAINT lost that: `other` is a colour, so the tint never applied.
    await _pump(
      tester,
      vehicles: [
        _vehicle(_golf, 'Transit', colour: 'other', business: true),
      ],
      due: {_golf: DueState.ok},
    );
    final tile = tester.widget<CalmIconTile>(find.byType(CalmIconTile).first);
    expect(tile.paint, isNull, reason: 'other has no swatch');
    expect(tile.business, isTrue);
  });
}
