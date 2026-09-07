// `costs.fuel`'s state, and the three ways it used to stick.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/fuel/fuel_insights.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/features/fuel/application/fuel_notifier.dart';

final Currency _eur = Currency.tryParse('EUR')!;
final Currency _gbp = Currency.tryParse('GBP')!;

InsightFill _fill(
  String id, {
  required int km,
  required String kind,
  Currency? currency,
}) => (
  id: id,
  occurredOn: '2026-0${id.length}-01',
  createdAtUtcMs: id.length,
  fuelKind: kind,
  cumulativeM: km * 1000,
  quantity: const LiquidVolume(Volume(40_000)),
  isFullTank: true,
  chainBroken: false,
  tankCapacityMl: 60000,
  cost: Money(7420, currency ?? _eur),
);

class _FakeFuelRepository implements FuelRepository {
  _FakeFuelRepository(this._byVehicle);

  final Map<String, List<InsightFill>> _byVehicle;
  final List<String> reads = <String>[];

  @override
  Future<List<InsightFill>> read(String vehicleId) async {
    reads.add(vehicleId);
    return _byVehicle[vehicleId] ?? const [];
  }
}

class _ThrowingRepository implements FuelRepository {
  int calls = 0;

  @override
  Future<List<InsightFill>> read(String vehicleId) async {
    calls++;
    throw StateError('disk');
  }
}

ProviderContainer _container(FuelRepository repository) {
  final container = ProviderContainer(
    overrides: [fuelRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('switching the vehicle reloads; the same one does not', () async {
    // `CostsNotifier` had this defect and documents fixing it. Without a key,
    // `ensureLoaded` ran once for the app's lifetime and a vehicle switch left
    // the first car's consumption under the second car's name.
    final repository = _FakeFuelRepository({
      'veh_a': [
        _fill('a', km: 100_000, kind: 'diesel'),
        _fill('bb', km: 100_500, kind: 'diesel'),
      ],
      'veh_b': [_fill('c', km: 5000, kind: 'diesel')],
    });
    final notifier = _container(repository).read(fuelProvider.notifier)
      ..ensureLoaded('veh_a', currency: _eur);
    await _settle();

    notifier.ensureLoaded('veh_a', currency: _eur);
    await _settle();
    expect(repository.reads, ['veh_a']);

    notifier.ensureLoaded('veh_b', currency: _eur);
    await _settle();
    expect(repository.reads, ['veh_a', 'veh_b']);
  });

  test('a currency change reloads too', () async {
    // `byFuelKind` EXCLUDES every fill in another currency, so a first build
    // before settings resolve captures the EUR fallback and a household in
    // pounds sees an empty screen for the rest of the session.
    final repository = _FakeFuelRepository({
      'veh_a': [_fill('a', km: 100_000, kind: 'diesel', currency: _gbp)],
    });
    final notifier = _container(repository).read(fuelProvider.notifier)
      ..ensureLoaded('veh_a', currency: _eur);
    await _settle();

    notifier.ensureLoaded('veh_a', currency: _gbp);
    await _settle();

    expect(repository.reads, ['veh_a', 'veh_a']);
  });

  test('one failed read does not wedge the screen for ever', () async {
    // `_loading` was cleared only on the success path, so a single throw left
    // it true and `isLoaded` false for the life of the provider — the empty
    // state, permanently, with no way back.
    final repository = _ThrowingRepository();
    final notifier = _container(repository).read(fuelProvider.notifier)
      ..ensureLoaded('veh_a', currency: _eur);
    await _settle();

    notifier.ensureLoaded('veh_a', currency: _eur);
    await _settle();

    expect(repository.calls, 2, reason: 'a retry must actually retry');
  });

  test('the default kind is the one with the most data, not the oldest', () {
    // `byKind.keys.first` is whichever kind the OLDEST fill used, so a bi-fuel
    // car whose first tank was LPG opened on LPG for good.
    final state = FuelState(
      byKind: FuelInsights.byFuelKind([
        _fill('a', km: 100_000, kind: 'lpg'),
        _fill('bb', km: 100_400, kind: 'lpg'),
        _fill('ccc', km: 100_800, kind: 'diesel'),
        _fill('dddd', km: 101_200, kind: 'diesel'),
        _fill('eeeee', km: 101_600, kind: 'diesel'),
      ], currency: _eur),
      isLoaded: true,
    );

    expect(state.primaryKind, 'diesel');
  });
}
