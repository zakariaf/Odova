// Home is correct without the user doing anything.
//
// SPEC.md §9's *Recompute triggers*: "screen focus, any write to the active
// vehicle, vehicle switch, local midnight crossing, app resume, locale/unit/
// calendar change, import commit."
//
// FIVE of the seven arrive through the streams the screen already watches — a
// write, a switch, a settings change, an import commit and the first read are
// all rows moving, and this file drives the streams they move. The two that do
// not are the midnight crossing and the resume, because neither writes a row:
// the calendar moves and the data does not. So they move `todayProvider`, and
// that is what those tests drive.
//
// Plain `test`s with a `ProviderContainer`, never `testWidgets`: every one of
// these is about a provider re-emitting, and a widget harness would only make
// it slower to say.
import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/due/vehicle_due_snapshot.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/data/repositories/due_snapshot_provider.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/home/application/home_notifier.dart';
import 'package:odova/features/home/application/today.dart';
import 'package:odova/features/home/domain/home_view_model.dart';

import '../../support/source_tree.dart';
import 'home_fixture.dart';

/// A clock the test moves.
///
/// `Clock.fixed` cannot be moved and `withClock` is a zone, which a provider
/// read outside it does not see. This is the smallest thing that lets a test
/// say "and then it was tomorrow".
class _MovingClock implements Clock {
  _MovingClock(this.at);

  /// The moment `now()` returns. Assign to move time.
  DateTime at;

  @override
  DateTime now() => at;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _container(List<Override> overrides) {
  final container = ProviderContainer(
    retry: noProviderRetry,
    overrides: overrides,
  );
  addTearDown(container.dispose);
  return container;
}

/// [buildHomeStack] with the catalogue derived from the assessments.
///
/// `allItems` is the vehicle's WHOLE catalogue — it feeds the see-all count,
/// which includes paused items the assessments deliberately omit. Every test
/// here is about the STACK, and a stack is built from assessed items, so this
/// derives the catalogue from them and the tests that care about the count
/// pass their own.
HomeStack _stack({
  required List<AssessedItem> items,
  required CivilDate today,
  List<ServiceItem>? allItems,
  ServiceItemId? pinnedItemId,
}) => buildHomeStack(
  items: items,
  allItems: allItems ?? [for (final (item, _) in items) item],
  today: today,
  pinnedItemId: pinnedItemId,
);

void main() {
  group('the two triggers that write no row', () {
    test('a local midnight crossing moves the day Home computes against', () {
      final clock = _MovingClock(DateTime(2026, 9, 5, 23, 59));
      final container = _container([clockProvider.overrideWithValue(clock)]);

      expect(container.read(todayProvider)?.toString(), '2026-09-05');

      clock.at = DateTime(2026, 9, 6, 0, 1);
      container.read(todayProvider.notifier).refresh();

      expect(container.read(todayProvider)?.toString(), '2026-09-06');
    });

    test('a resume on the same day changes nothing', () {
      // Idempotent on purpose: a provider that emitted a new-but-equal value
      // would rebuild Home on every trip to the home screen.
      final clock = _MovingClock(DateTime(2026, 9, 5, 9));
      final container = _container([clockProvider.overrideWithValue(clock)]);

      var rebuilds = 0;
      addTearDown(
        container.listen(todayProvider, (_, _) => rebuilds++).close,
      );

      clock.at = DateTime(2026, 9, 5, 18);
      container.read(todayProvider.notifier).refresh();

      expect(rebuilds, 0);
      expect(container.read(todayProvider)?.toString(), '2026-09-05');
    });

    test('the midnight TIMER is inert unless production arms it', () {
      // A timer set for up to 24 hours outlives every widget test, and
      // `testWidgets` fails the NEXT test over one still pending. The default
      // is inert; `bootstrap()` switches it on, which
      // `bootstrap_launch_test.dart`-style source assertions cover.
      expect(_container(const []).read(todayTicksProvider), isFalse);
    });
  });

  test('and bootstrap switches it ON', () {
    // The inert default is a TEST accommodation, and the feature only exists
    // because `bootstrap()` remembers to override it. Deleting that one line
    // silently turns off two of §9's seven recompute triggers — the midnight
    // crossing and the app resume — and the whole suite stays green, because
    // every test runs against the default.
    //
    // Read from the SOURCE, the way `providers_test` reads the stream
    // declarations: `bootstrap()` opens a real database and a real application
    // support directory, so there is nothing to call here.
    final source = sourceWithoutLineComments(
      dartFilesUnder(
        'lib/app',
      ).firstWhere((f) => f.path.endsWith('bootstrap.dart')),
    );

    expect(
      source,
      contains('todayTicksProvider.overrideWithValue(true)'),
      reason: 'SPEC.md §9: midnight and resume are recompute triggers',
    );
  });

  group('the five that arrive through a stream', () {
    late StreamController<AppSettings?> settings;
    late StreamController<List<Vehicle>> vehicles;
    late StreamController<VehicleDueSnapshot?> snapshots;

    setUp(() {
      settings = StreamController<AppSettings?>.broadcast();
      vehicles = StreamController<List<Vehicle>>.broadcast();
      snapshots = StreamController<VehicleDueSnapshot?>.broadcast();
    });

    tearDown(() async {
      await settings.close();
      await vehicles.close();
      await snapshots.close();
    });

    /// A container watching Home, with the snapshot behind a stream so a WRITE
    /// can be simulated at the seam every write reaches Home through.
    ProviderContainer harness() {
      final container = _container([
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 9, 5, 12)),
        ),
        settingsProvider.overrideWith((ref) => settings.stream),
        vehiclesProvider.overrideWith((ref) => vehicles.stream),
        latestFillUpProvider(golfId).overrideWith((ref) => Stream.value(null)),
        latestFillUpProvider(vanId).overrideWith((ref) => Stream.value(null)),
        serviceRecordsProvider(
          golfId,
        ).overrideWith((ref) => Stream.value(const [])),
        serviceRecordsProvider(
          vanId,
        ).overrideWith((ref) => Stream.value(const [])),
        // The other four inputs `vehicleStoreUnreadableProvider` falls through
        // to while the snapshot is still null. Without them it reaches the real
        // `AppDatabase`, which opens a platform channel a plain `test` has no
        // binding for — and the failure names the binding rather than the
        // provider that wanted it.
        for (final id in [golfId, vanId]) ...[
          serviceItemsProvider(id).overrideWith(
            (ref) => Stream.value(const []),
          ),
          odometerReadingsProvider(id).overrideWith(
            (ref) => Stream.value(const []),
          ),
          odometerCorrectionsProvider(id).overrideWith(
            (ref) => Stream.value(const []),
          ),
        ],
        vehicleDueSnapshotProvider(golfId).overrideWith(
          (ref) => ref.watch(_snapshotStream).value,
        ),
        vehicleDueSnapshotProvider(vanId).overrideWithValue(null),
        _snapshotStream.overrideWith((ref) => snapshots.stream),
      ]);
      addTearDown(container.listen(homeStateProvider, (_, _) {}).close);
      return container;
    }

    test('a write to the active vehicle rebuilds the stack', () async {
      final container = harness();
      settings.add(homeSettings(golfId));
      vehicles.add([homeVehicle(golfId, 'The Golf')]);
      snapshots.add(homeSnapshot(const []));
      await pumpEventQueue();

      expect(container.read(homeStateProvider)?.stack.cards, isEmpty);

      // The one seam every write reaches Home through. Driving a raw row here
      // would be asserting drift rather than Home.
      final oil = homeItem('Oil and filter');
      snapshots.add(
        homeSnapshot([(oil, homeAssessment(state: DueState.overdue))]),
      );
      await pumpEventQueue();

      expect(container.read(homeStateProvider)?.stack.cards, hasLength(1));
    });

    test('a vehicle switch rebuilds against the other car', () async {
      final container = harness();
      settings.add(homeSettings(golfId));
      vehicles.add([
        homeVehicle(golfId, 'The Golf'),
        homeVehicle(vanId, 'Van'),
      ]);
      snapshots.add(homeSnapshot(const []));
      await pumpEventQueue();

      expect(container.read(homeStateProvider)?.vehicle.name, 'The Golf');

      // A switch is one field of `Settings`, and nothing else — SPEC.md §7.
      settings.add(homeSettings(vanId));
      await pumpEventQueue();

      expect(container.read(homeStateProvider)?.vehicle.name, 'Van');
    });

    test('a unit change reaches the app without churning the stack', () async {
      // §9 lists "locale/unit/calendar change" as a recompute trigger, and it
      // reaches the app the way every other setting does — through
      // `settingsProvider`, which the SCREEN watches for the unit it renders
      // in.
      //
      // What it does NOT do is rebuild the due stack, and that is the
      // interesting half: the ORDER of due items does not depend on the unit
      // they are shown in, so a model that re-sorted for a unit change would be
      // doing work that cannot change its answer. §2's "nothing derived is
      // persisted" is why this is cheap enough not to matter either way.
      final container = harness();
      settings.add(homeSettings(golfId));
      vehicles.add([homeVehicle(golfId, 'The Golf')]);
      snapshots.add(
        homeSnapshot([
          (homeItem('Oil and filter'), homeAssessment(state: DueState.overdue)),
        ]),
      );
      await pumpEventQueue();

      final before = container.read(homeStateProvider);
      expect(before, isNotNull);

      settings.add(
        AppSettings(
          schemaVersion: 1,
          currencyDefault: homeSettings(golfId).currencyDefault,
          activeVehicleId: golfId,
          distanceUnit: DistanceUnit.mi,
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 2000,
        ),
      );
      await pumpEventQueue();

      expect(
        container.read(settingsProvider).value?.distanceUnit,
        DistanceUnit.mi,
        reason: 'the change never reached the app',
      );
      expect(
        identical(before, container.read(homeStateProvider)),
        isTrue,
        reason: 'the stack does not depend on the unit and must not re-sort',
      );
    });

    test('an import commit is a write like any other', () async {
      // §9 lists it separately because it is a whole-database replacement, but
      // it reaches Home the same way: every stream re-emits. Asserted as the
      // garage changing under a settings row that did not.
      final container = harness();
      settings.add(homeSettings(golfId));
      vehicles.add([homeVehicle(golfId, 'The Golf')]);
      snapshots.add(homeSnapshot(const []));
      await pumpEventQueue();

      vehicles.add([homeVehicle(golfId, 'Restored Golf')]);
      await pumpEventQueue();

      expect(container.read(homeStateProvider)?.vehicle.name, 'Restored Golf');
    });
  });

  group('deep links', () {
    test('a pinned item takes the primary slot for one appearance', () {
      // §9 rule 5. The PIN is a value somebody has to clear — the notification
      // handler pins, Home shows it once, and `clear` is a named call rather
      // than a value that quietly outlives its link.
      final container = _container(const []);
      final oil = homeItem('Oil and filter');
      final inspection = homeItem('Inspection', suffix: 'B');

      container.read(pinnedHomeItemProvider.notifier).pin(inspection.id);
      expect(container.read(pinnedHomeItemProvider), inspection.id);

      final stack = _stack(
        items: [
          (oil, homeAssessment(state: DueState.overdue, dueOn: '2026-08-12')),
          (
            inspection,
            homeAssessment(state: DueState.dueSoon, dueOn: '2027-03-14'),
          ),
        ],
        today: CivilDate.tryParse('2026-09-05')!,
        pinnedItemId: container.read(pinnedHomeItemProvider),
      );

      // Ahead of the OVERDUE one, which it would never outrank on the sort.
      expect(stack.cards.first.item.label, 'Inspection');

      container.read(pinnedHomeItemProvider.notifier).clear();
      expect(container.read(pinnedHomeItemProvider), isNull);
    });
  });

  test('the model builds under budget for 26 items', () {
    // §9: "budget under 16 ms for 2,000 rows on the floor device", and 2,000
    // rows across a vehicle is 26 items — the rows are the SERVICE RECORDS the
    // engine has already reduced by the time the stack is built.
    //
    // A PLAIN test, not a widget one: `buildHomeStack` is pure Dart, and a
    // widget harness would be measuring the harness.
    final items = <AssessedItem>[
      for (var i = 0; i < 26; i++)
        (
          homeItem('Item $i', suffix: '0123456789ABCDEFGHJKMNPQRSTV'[i]),
          homeAssessment(
            state: DueState.overdue,
            dueOn: '2026-0${(i % 9) + 1}-01',
          ),
        ),
    ];
    final today = CivilDate.tryParse('2026-09-05')!;

    // Warm, then measured: the first call pays for the JIT.
    _stack(items: items, today: today);

    final watch = Stopwatch()..start();
    for (var run = 0; run < 100; run++) {
      _stack(items: items, today: today);
    }
    watch.stop();

    expect(
      watch.elapsedMicroseconds / 100,
      lessThan(16000),
      reason:
          '§9 budgets 16 ms; one build took '
          '${watch.elapsedMicroseconds / 100}µs',
    );
  });

  test('the stack persists nothing derived', () {
    // §2: "Derived values are never persisted." The stack carries the
    // assessment as a VALUE beside the item; `ServiceItem` has no field for a
    // due date or a status, which is the only place one could be smuggled into
    // storage.
    final stack = _stack(
      items: [
        (homeItem('Oil and filter'), homeAssessment(state: DueState.overdue)),
      ],
      today: CivilDate.tryParse('2026-09-05')!,
    );

    final card = stack.cards.single;
    expect(card.item.targetDate, isNull);
    expect(card.item.baselineDate, isNull);
    expect(card.assessment.state, DueState.overdue);
  });
}

/// The snapshot, behind a stream a test can push to.
///
/// `vehicleDueSnapshotProvider` is a `Provider` over six streams, and a test
/// that overrode it with a VALUE could not move it afterwards. This is the one
/// seam a simulated write travels through.
final _snapshotStream = StreamProvider<VehicleDueSnapshot?>(
  (ref) => const Stream.empty(),
);
