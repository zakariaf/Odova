// SPEC.md §12's `costs.fuel` state.
//
// Read-only, per tab stack, nothing persisted — the same contract tab 3 has.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:odova/core/fuel/fuel_insights.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/fuel/data/fuel_source.dart';

/// What `costs.fuel` renders.
@immutable
class FuelState {
  /// Creates the state.
  const FuelState({this.byKind = const {}, this.isLoaded = false});

  /// One set of figures per fuel kind. §12: a bi-fuel car has two averages,
  /// and merging them produces a figure for a fuel it does not burn.
  final Map<String, FuelInsights> byKind;

  /// Whether the first read has landed.
  final bool isLoaded;

  /// The kind shown by default: the one with the most data.
  ///
  /// Measured, not insertion order. `byKind.keys.first` is whichever fuel kind
  /// the OLDEST fill happened to use, so a bi-fuel car whose first tank was
  /// LPG opened on LPG for good. Ties break on the kind's name, so two kinds
  /// with equal history do not swap between builds.
  String? get primaryKind {
    if (byKind.isEmpty) return null;
    final ranked = byKind.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.chartPoints.length.compareTo(
          a.value.chartPoints.length,
        );
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return ranked.first.key;
  }

  /// Whether §12's empty state applies. Loaded AND nothing — an eager empty
  /// would flash "No fill-ups yet" at somebody with eight years of them.
  bool get isEmpty => isLoaded && byKind.isEmpty;
}

/// Reads one vehicle's fills.
// ignore: one_member_abstracts
abstract interface class FuelRepository {
  /// Every fill in range, with what it cost.
  Future<List<InsightFill>> read(String vehicleId);
}

/// `costs.fuel`'s state.
class FuelNotifier extends Notifier<FuelState> {
  var _loading = false;

  /// Which vehicle and currency the current state describes.
  ///
  /// `CostsNotifier` had exactly this defect and documents fixing it: without
  /// a key, `ensureLoaded` ran once for the app's lifetime and a vehicle
  /// switch left the first car's consumption under the second car's name — a
  /// plausible wrong number, which is worse than none. The CURRENCY is part of
  /// the key too, because `byFuelKind` excludes every fill in another one: a
  /// first build before `settingsProvider` has resolved captures the EUR
  /// fallback, and a household in pounds then sees an empty screen for the
  /// rest of the session.
  ({String vehicleId, Currency currency})? _loadedFor;

  @override
  FuelState build() => const FuelState();

  /// Loads for [vehicleId], and reloads when the vehicle or currency changes.
  void ensureLoaded(String vehicleId, {required Currency currency}) {
    if (_loading) return;
    final key = (vehicleId: vehicleId, currency: currency);
    if (state.isLoaded && _loadedFor == key) return;
    _loading = true;
    _loadedFor = key;
    unawaited(
      Future.microtask(() async {
        try {
          final fills = await ref.read(fuelRepositoryProvider).read(vehicleId);
          state = FuelState(
            byKind: FuelInsights.byFuelKind(fills, currency: currency),
            isLoaded: true,
          );
        } on Object {
          // CAUGHT, and `isLoaded` deliberately left false. The read threw, so
          // the app does not know whether this car has fills — and §1 forbids
          // saying something that looks like a fact, which "No fill-ups yet"
          // would be. `isLoaded: false` renders neither the figures nor the
          // empty state, and the next build retries.
          //
          // Uncaught, this reached the zone as an unhandled async error while
          // the screen sat on its empty state for the life of the provider,
          // because `_loading` was cleared only on the success path.
          _loadedFor = null;
        } finally {
          _loading = false;
        }
      }),
    );
  }
}

/// `costs.fuel`'s provider.
final NotifierProvider<FuelNotifier, FuelState> fuelProvider =
    NotifierProvider<FuelNotifier, FuelState>(FuelNotifier.new);

/// The store it reads through. Overridden in tests.
final Provider<FuelRepository> fuelRepositoryProvider =
    Provider<FuelRepository>(
      (ref) => FuelSource(
        ref.watch(fillUpRepositoryProvider),
        ref.watch(odometerRepositoryProvider),
      ),
    );
