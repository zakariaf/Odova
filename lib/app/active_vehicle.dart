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
import 'package:odova/app/routing/launch_gate.dart';
import 'package:odova/app/routing/tab_stack_reset.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/failures/persist_failure.dart';
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
/// Through `launchFactsProvider`, which falls back to what `bootstrap()` read
/// before the first frame when the stream has no value yet. A bare
/// `vehiclesProvider.value?.length ?? 0` answered ZERO on every cold start
/// until the drift query landed — and zero is a fact SPEC.md §7 acts on, not a
/// placeholder.
final liveVehicleCountProvider = Provider<int>(
  (ref) => ref.watch(launchFactsProvider).liveVehicleCount,
);

/// Whether the multi-vehicle interface exists at all.
///
/// SPEC.md §7: with one vehicle the app-bar title is plain text — no chevron,
/// no tap target, no "1 of 1". The THRESHOLD lives on
/// `LaunchFacts.showsVehicleSwitcher` and is read from there, because the
/// launch gate uses the same rule to make
/// `vehicle.switcher` unreachable: two encodings of one product rule is one
/// that can be changed without effect.
final showsVehicleSwitcherProvider = Provider<bool>(
  (ref) => ref.watch(launchFactsProvider).showsVehicleSwitcher,
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
Future<Result<void, PersistFailure>> setActiveVehicle(
  ProviderContainer ref,
  VehicleId id,
) async {
  // A targeted UPDATE, not a read-modify-write: `SettingsRepository` explains
  // why the difference matters, and it is the difference between "writes one
  // field" being a promise and being an accident.
  final written = await ref
      .read(settingsRepositoryProvider)
      .setActiveVehicle(
        id,
        updatedAtUtcMs: ref.read(clockProvider).now().millisecondsSinceEpoch,
      );

  // The failure is RETURNED, not swallowed. `guardPersist` wraps a thrown
  // UPDATE as well as a missing row — a full disk, a locked database, a
  // degraded-mode refusal — and a silent one here closes the switcher on a
  // vehicle that did not change: the user believes they switched cars and logs
  // the next fill-up against the wrong one. EPIC-09's sheet is the screen that
  // has to say so.
  if (written is! Ok) return written;

  ref.read(tabStackResetProvider.notifier).resetAllTabStacks(selectHome: false);
  return const Ok(null);
}
