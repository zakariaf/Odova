// The one active vehicle, and the reason a one-car user never sees a fleet.
//
// SPEC.md §7 *Active vehicle*. Three tabs are scoped by it, one persisted field
// holds it, and the multi-vehicle interface does not exist until a second
// vehicle does. That last rule is the expensive one to get wrong: a plumber
// with two vans and a commuter with one car are the same app, and every pixel
// of fleet management shown to the commuter is a tax on the person this app was
// written for.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/tab_stack_reset.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/repositories/providers.dart';

/// The vehicle every scoped screen is about.
///
/// Read from `Settings.active_vehicle_id` and never re-derived. "The only
/// vehicle" or "the most recently used" would both be plausible and both would
/// disagree with the file a user restores from — and SPEC.md §2 says the backup
/// is the record, not a hint.
///
/// Null before first run has written a settings row, which is what routes a
/// fresh install into onboarding rather than into an empty Home.
final activeVehicleIdProvider = Provider<VehicleId?>(
  (ref) => ref.watch(settingsProvider).value?.activeVehicleId,
);

/// How many live vehicles there are.
///
/// Over `vehiclesProvider`, which already filters soft-deleted rows and is
/// already alive for the whole session. A second query would be a second answer
/// — and it would be the wrong one the moment a user deleted a car, because a
/// count that includes tombstones keeps a switcher that offers one choice.
final liveVehicleCountProvider = Provider<int>(
  (ref) => ref.watch(vehiclesProvider).value?.length ?? 0,
);

/// Whether the multi-vehicle interface exists at all.
///
/// SPEC.md §7: with one vehicle the app-bar title is plain text — no chevron,
/// no tap target, no "1 of 1" — and `vehicle.switcher` is unreachable.
final showsVehicleSwitcherProvider = Provider<bool>(
  (ref) => ref.watch(liveVehicleCountProvider) >= 2,
);

/// Whether the Costs tab is showing every vehicle.
///
/// SPEC.md §7's one exception to "the active vehicle scopes everything". It is
/// a VIEW flag on one tab, not a change of active vehicle, and it is
/// deliberately not persisted into `Settings`: a user who looked at the whole
/// fleet's costs once on a Sunday has not asked for that to be the answer every
/// time they open the app. Declared here rather than in EPIC-13 so the decision
/// is inherited rather than made again over a half-built screen.
class CostsAllVehicles extends Notifier<bool> {
  @override
  bool build() => false;

  /// Flips the view.
  void toggle() => state = !state;
}

/// The Costs tab's All-vehicles flag.
final costsAllVehiclesProvider = NotifierProvider<CostsAllVehicles, bool>(
  CostsAllVehicles.new,
);

/// Makes [id] the active vehicle.
///
/// Two effects and no third: it writes one `Settings` field, and it asks task
/// 8.3 to reset every tab stack — because every scoped screen in every stack is
/// now showing the wrong car's data. `selectHome: false`, per SPEC.md §7:
/// switching vehicles changes WHAT is shown, not where the user was looking.
///
/// Takes a [ProviderContainer] rather than a `Ref`. Both callers SPEC.md §7
/// allows — the switcher sheet and the deep-link handler — have one, and a
/// function this important should be callable from a test without a widget
/// tree.
Future<void> setActiveVehicle(ProviderContainer ref, VehicleId id) async {
  // A targeted UPDATE, not a read-modify-write: `SettingsRepository` explains
  // why the difference matters, and it is the difference between "writes one
  // field" being a promise and being an accident.
  final written = await ref
      .read(settingsRepositoryProvider)
      .setActiveVehicle(
        id,
        updatedAtUtcMs: ref.read(clockProvider).now().millisecondsSinceEpoch,
      );

  // No settings row means first run has not finished, and there is nothing to
  // scope or to reset. Silent because nothing has asked for this yet — there
  // is no screen to tell.
  if (written is! Ok) return;

  ref.read(tabStackResetProvider.notifier).resetAllTabStacks(selectHome: false);
}
