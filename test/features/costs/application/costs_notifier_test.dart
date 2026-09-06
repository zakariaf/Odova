// SPEC.md §12's tab-3 state.
//
// Both pieces of it are per-tab-stack and neither is persisted: §12 opens with
// "They write nothing but per-stack UI state — range, fuel kind — which dies
// with the tab-stack reset." A remembered range would greet a user months
// later with a figure whose window they have no reason to remember.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/costs/cost_aggregates.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/features/costs/application/costs_notifier.dart';

import '../../../support/costs_fake_repository.dart';

final CivilDate _today = CivilDate.tryParse('2026-09-02')!;

ProviderContainer _container({FakeCostsRepository? repository}) {
  final container = ProviderContainer(
    overrides: [
      costsRepositoryProvider.overrideWithValue(
        repository ?? FakeCostsRepository(),
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
}
