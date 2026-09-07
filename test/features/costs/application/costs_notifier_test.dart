// SPEC.md §12's tab-3 state.
//
// Both pieces of it are per-tab-stack and neither is persisted: §12 opens with
// "They write nothing but per-stack UI state — range, fuel kind — which dies
// with the tab-stack reset." A remembered range would greet a user months
// later with a figure whose window they have no reason to remember.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/active_vehicle.dart';
import 'package:odova/core/costs/cost_aggregates.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/costs/application/costs_notifier.dart';

import '../../../support/costs_fake_repository.dart';
import '../../home/home_fixture.dart';

final CivilDate _today = CivilDate.tryParse('2026-09-02')!;

ProviderContainer _container({FakeCostsRepository? repository}) {
  final container = ProviderContainer(
    overrides: [
      costsRepositoryProvider.overrideWithValue(
        repository ?? FakeCostsRepository(),
      ),
      // The active-vehicle provider derives from settings, and settings opens
      // the database. Overridden so the guarantee below tests the TOGGLE
      // rather than the platform channels underneath it.
      settingsProvider.overrideWith(
        (ref) => Stream.value(homeSettings(golfId)),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<CostsNotifier> _loaded(ProviderContainer c) async {
  final n = c.read(costsProvider.notifier)
    ..ensureLoaded('veh_1', today: _today);
  await Future<void>.delayed(Duration.zero);
  return n;
}

void main() {
  // The active-vehicle provider reads settings, which reaches the platform
  // bindings through the settings stream.
  TestWidgetsFlutterBinding.ensureInitialized();

  //  reads settings, which reaches the platform
  // bindings through the settings stream.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('twelve months is the default, per §12', () {
    expect(
      _container().read(costsProvider).choice,
      CostsRangeChoice.twelveMonths,
    );
  });

  test('nothing is computed before the read lands', () {
    // An empty state rendered eagerly would flash "No costs yet" at a user
    // with eight years of them.
    final state = _container().read(costsProvider);

    expect(state.isLoaded, isFalse);
    expect(state.isEmpty, isFalse, reason: 'not empty — not yet known');
  });

  test('loading computes a total, categories and both figures', () async {
    final container = _container();
    await _loaded(container);
    final state = container.read(costsProvider);

    expect(state.total?.byCurrency, isNotEmpty);
    expect(state.categories, hasLength(3));
    expect(state.perMonth, isA<CostExact>());
    expect(state.perDistance, isNotNull);
  });

  test('choosing a range recomputes against the new window', () async {
    final container = _container();
    final notifier = await _loaded(container);
    final twelve = container.read(costsProvider).range;

    await notifier.choose(
      CostsRangeChoice.threeMonths,
      'veh_1',
      today: _today,
    );
    final three = container.read(costsProvider).range;

    expect(three!.from, isNot(twelve!.from));
    expect(three.completedMonths, 3);
  });

  test('`This year` in January has no range at all', () async {
    // §12 hides the chip then, and this is the other half of that: the state
    // must be able to say "this choice has no window" rather than inventing
    // an empty one.
    final container = _container();
    final notifier = await _loaded(container);

    await notifier.choose(
      CostsRangeChoice.thisYear,
      'veh_1',
      today: CivilDate.tryParse('2026-01-15')!,
    );

    expect(container.read(costsProvider).range, isNull);
  });

  test('`All` needs a first record to start from', () async {
    final container = _container(
      repository: FakeCostsRepository(firstRecordOn: null),
    );
    final notifier = await _loaded(container);

    await notifier.choose(CostsRangeChoice.all, 'veh_1', today: _today);

    expect(container.read(costsProvider).range, isNull);
  });

  test('a vehicle with no amounts is empty once loaded', () async {
    final container = _container(
      repository: FakeCostsRepository(
        fuelMinor: 0,
        serviceMinor: 0,
        insuranceMinor: 0,
      ),
    );
    await _loaded(container);

    expect(container.read(costsProvider).isEmpty, isTrue);
  });

  test('ensureLoaded is idempotent', () async {
    // It is called from `build`, which runs on every rebuild.
    final repository = FakeCostsRepository();
    final container = _container(repository: repository);
    final notifier = await _loaded(container);
    final reads = repository.reads;

    notifier
      ..ensureLoaded('veh_1', today: _today)
      ..ensureLoaded('veh_1', today: _today);
    await Future<void>.delayed(Duration.zero);

    expect(repository.reads, reads);
  });

  group('§7s one exception', () {
    test('the household toggle never touches activeVehicleId', () async {
      // §7 gives the app ONE active vehicle and every screen reads it. §12's
      // all-vehicles toggle is the single documented exception, and it is
      // scoped to tab 3: it changes what tab 3 SHOWS.
      //
      // Watched rather than asserted by comment. A toggle that wrote to the
      // vehicle scope would silently change Home, History and every log form
      // — from a glance at a comparison.
      final container = _container();
      final before = container.read(activeVehicleIdProvider);
      final notifier = await _loaded(container);

      notifier.setIncludeInactive(include: true);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(activeVehicleIdProvider),
        before,
        reason: 'the active vehicle is exactly where it was',
      );
      expect(container.read(costsProvider).includeInactive, isTrue);
    });

    test('and the range survives the toggle', () async {
      // §12: "the range is preserved across the toggle." Resetting it would
      // make a household comparison silently answer a different question from
      // the one on screen a moment earlier.
      final container = _container();
      final notifier = await _loaded(container);
      await notifier.choose(
        CostsRangeChoice.threeMonths,
        'veh_1',
        today: _today,
      );

      notifier.setIncludeInactive(include: true);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(costsProvider).choice,
        CostsRangeChoice.threeMonths,
      );
    });
  });

  test('switching the vehicle reloads; the same vehicle does not', () async {
    // `_loading` was set true on the first call and never reset, so
    // `ensureLoaded` ran exactly ONCE for the app's lifetime — and switching
    // the active vehicle left tab 3 showing the first car's costs under the
    // second car's name. A plausible wrong number is worse than none.
    final repository = FakeCostsRepository();
    final container = _container(repository: repository);
    final notifier = await _loaded(container);
    final afterFirst = repository.reads;

    notifier.ensureLoaded('veh_1', today: _today);
    await Future<void>.delayed(Duration.zero);
    expect(repository.reads, afterFirst, reason: 'same vehicle, no reload');

    notifier.ensureLoaded('veh_2', today: _today);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(
      repository.reads,
      greaterThan(afterFirst),
      reason: 'a different vehicle must reload',
    );
  });

  test('a load reads the record set once, not twice', () async {
    // The first version read with a null range to learn `firstRecordOn`, then
    // again with the range that came out of it — two whole-history queries
    // fetching identical rows, and a write landing between them would have
    // been counted by one and not the other.
    final repository = FakeCostsRepository();
    final container = _container(repository: repository);
    await _loaded(container);

    expect(repository.reads, 1);
  });
}
