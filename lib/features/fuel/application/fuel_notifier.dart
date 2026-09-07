// SPEC.md §12's `costs.fuel` state.
//
// Read-only, per tab stack, nothing persisted — the same contract tab 3 has.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:odova/core/fuel/fuel_insights.dart';
import 'package:odova/core/money/currency.dart';

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
  String? get primaryKind => byKind.keys.isEmpty ? null : byKind.keys.first;

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

  @override
  FuelState build() => const FuelState();

  /// Loads once.
  void ensureLoaded(String vehicleId, {required Currency currency}) {
    if (_loading || state.isLoaded) return;
    _loading = true;
    unawaited(
      Future.microtask(() async {
        final fills = await ref.read(fuelRepositoryProvider).read(vehicleId);
        state = FuelState(
          byKind: FuelInsights.byFuelKind(fills, currency: currency),
          isLoaded: true,
        );
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
      (ref) => throw UnimplementedError(
        'fuelRepositoryProvider must be overridden until EPIC-13 wires the '
        'fill read.',
      ),
    );
