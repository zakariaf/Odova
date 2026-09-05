// Home's one provider, composing what the earlier epics already compute.
//
// A `Provider`, not a `Notifier`: every input is already a stream and every
// output is derived, so there is no state of its own to hold. SPEC.md §2 —
// nothing derived is persisted, and Home is the screen that would be most
// tempting to cache.
//
// The recompute triggers §9 lists (a write to the vehicle, a switch, a locale
// change) arrive for free through those streams; the ones that do not —
// midnight and app resume — are task 10.9's.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/active_vehicle.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/data/repositories/due_snapshot_provider.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/home/application/home_state.dart';
import 'package:odova/features/home/domain/home_view_model.dart';

/// §9 rule 5: pinned "for that one appearance of Home".
///
/// A notifier rather than a mutable provider so that CLEARING it is a named
/// call somebody has to make — the pin is meant to survive exactly one
/// appearance, and a value nobody clears would quietly outlive its deep link.
class PinnedHomeItem extends Notifier<ServiceItemId?> {
  @override
  ServiceItemId? build() => null;

  /// Pins [id] to the primary slot.
  ///
  /// A method rather than a setter, deliberately: it pairs with [clear], and a
  /// setter beside a method reads as two different kinds of thing.
  // ignore: use_setters_to_change_properties
  void pin(ServiceItemId id) => state = id;

  /// Releases the pin. Task 10.9 calls this when Home has been shown.
  void clear() => state = null;
}

/// The item pinned by a notification tap, if any.
final NotifierProvider<PinnedHomeItem, ServiceItemId?> pinnedHomeItemProvider =
    NotifierProvider<PinnedHomeItem, ServiceItemId?>(PinnedHomeItem.new);

/// Everything Home draws, or null while the first read is in flight.
final Provider<HomeState?>
homeStateProvider = Provider.autoDispose<HomeState?>((ref) {
  final activeId = ref.watch(activeVehicleIdProvider);
  final vehicles = ref.watch(vehiclesProvider).value;
  if (activeId == null || vehicles == null) return null;

  final vehicle = vehicles.where((v) => v.id == activeId).firstOrNull;
  if (vehicle == null) return null;

  final snapshot = ref.watch(vehicleDueSnapshotProvider(vehicle.id));
  final fillUps = ref.watch(fillUpsProvider(vehicle.id)).value ?? const [];
  final today = CivilDate.fromDateTime(ref.watch(clockProvider).now());

  return HomeState(
    vehicle: vehicle,
    estimate: snapshot?.estimate,
    stack: buildHomeStack(
      items: snapshot?.assessments ?? const [],
      today: today ?? CivilDate.fromDateTime(DateTime(1970))!,
      pinnedItemId: ref.watch(pinnedHomeItemProvider),
    ),
    // §9: the switcher "exists only with ≥ 2 vehicles", and the rule lives in
    // `LaunchFacts` so the redirect and the chevron cannot disagree. This reads
    // the same count rather than a second opinion about it.
    showsSwitcher: vehicles.length >= 2,
    lastFillUp: fillUps.isEmpty ? null : fillUps.last,
    otherVehicleNeedingAttention: _otherNeedingAttention(
      ref,
      vehicles,
      vehicle,
    ),
  );
});

/// The first OTHER vehicle with a due or overdue item, in garage order.
///
/// §9 draws one line and names the vehicle, not the job: "Home shows *whose*
/// problem it is, not *what* it is." A second due card for a car the user is
/// not looking at is the screen this one exists to avoid.
///
/// The COUNT and the word come out with it. The row reads `Van · 1 overdue`,
/// and "overdue" is not a synonym for "due" — recovering either at the widget
/// would mean the widget reading a second vehicle's snapshot for itself.
OtherVehicleAttention? _otherNeedingAttention(
  Ref ref,
  List<Vehicle> vehicles,
  Vehicle active,
) {
  for (final other in vehicles) {
    if (other.id == active.id) continue;
    // A sold or archived vehicle never notifies and never nudges (§8), so it
    // never earns this row either.
    if (other.status != VehicleStatus.active) continue;
    final summary = ref.watch(vehicleDueSnapshotProvider(other.id))?.summary;
    final counts = summary?.counts ?? const <DueState, int>{};
    final overdue = counts[DueState.overdue] ?? 0;
    final due = counts[DueState.due] ?? 0;
    if (overdue + due == 0) continue;
    // The OVERDUE count when there is one, not the sum: "Van · 3 overdue" on a
    // van with one overdue item and two merely due is the accusation §9 is
    // careful not to make.
    return (
      vehicle: other,
      count: overdue > 0 ? overdue : due,
      overdue: overdue > 0,
    );
  }
  return null;
}
