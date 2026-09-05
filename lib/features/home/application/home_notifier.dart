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
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/due/vehicle_due_snapshot.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/data/repositories/due_snapshot_provider.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/data/ui_state/ui_state_provider.dart';
import 'package:odova/data/ui_state/ui_state_store.dart';
import 'package:odova/features/home/application/home_state.dart';
import 'package:odova/features/home/application/today.dart';
import 'package:odova/features/home/domain/home_strips.dart';
import 'package:odova/features/home/domain/home_view_model.dart';
import 'package:odova/l10n/vehicle_labels.dart';

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
  final lastFillUp = ref.watch(latestFillUpProvider(vehicle.id)).value;
  // WATCHED, not read from the clock. §9's *Recompute triggers* include the
  // local midnight crossing and the app resuming, and neither writes a row —
  // the calendar moves and the data does not. `todayProvider` is the value
  // those two move, so watching it is what makes them triggers.
  final today = ref.watch(todayProvider);

  final assessments = snapshot?.assessments ?? const <AssessedItem>[];
  final stack = buildHomeStack(
    items: assessments,
    // The vehicle's WHOLE catalogue, for the see-all count. Already open —
    // `vehicleDueSnapshotProvider` watches this same family — so the extra
    // subscription is a memoised read, not a second query.
    allItems: ref.watch(serviceItemsProvider(vehicle.id)).value ?? const [],
    today: today ?? CivilDate.epoch,
    pinnedItemId: ref.watch(pinnedHomeItemProvider),
  );

  return HomeState(
    vehicle: vehicle,
    estimate: snapshot?.estimate,
    strips: _strips(ref, vehicle, snapshot, today),
    storeUnreadable: ref.watch(vehicleStoreUnreadableProvider(vehicle.id)),
    // §9 makes the two exclusive: the all-clear REPLACES the stack rather than
    // sitting under it. So it is computed only when there is nothing to draw —
    // which includes the unknown-anchor case, because that card is a stack
    // entry and not an absence of one.
    allClear: stack.cards.isEmpty && stack.unknown == null
        ? _allClear(ref, vehicle, snapshot, assessments, today)
        : null,
    stack: stack,
    // §9: the switcher "exists only with ≥ 2 vehicles", and the rule lives in
    // `LaunchFacts` so the redirect and the chevron cannot disagree. This reads
    // the same count rather than a second opinion about it.
    showsSwitcher: vehicles.length >= 2,
    lastFillUp: lastFillUp,
    otherVehicleNeedingAttention: _otherNeedingAttention(
      ref,
      vehicles,
      vehicle,
    ),
  );
});

/// The all-clear's facts: what is next, and what was last done.
///
/// §9's *Nothing due*: "the next item with its date, plus a since-last-service
/// line (distance and time since the most recent `ServiceRecord`, whatever it
/// was)". Raw values only — the sentences are `home_states.dart`'s, because a
/// locale is a presentation input.
/// [snapshot] is PASSED, not re-watched. Its caller already holds it and
/// `_strips` two functions up already takes it as a parameter — one of the two
/// reaching for the provider again was an inconsistency that made the second
/// subscription easy to miss.
HomeAllClear _allClear(
  Ref ref,
  Vehicle vehicle,
  VehicleDueSnapshot? snapshot,
  List<AssessedItem> items,
  CivilDate? today,
) {
  // The soonest TRACKED, ACTIVE item by projected date, whatever its state.
  // `ok` is what everything is here — that is the definition of this state —
  // so the sort cannot use severity and the date is the only key there is.
  AssessedItem? next;
  for (final candidate in items) {
    if (!candidate.$1.isTracked || !candidate.$1.isActive) continue;
    final on = candidate.$2.projectedDueDate;
    if (on == null) continue;
    final best = next?.$2.projectedDueDate;
    if (best == null || on.compareTo(best) < 0) next = candidate;
  }

  final records = ref.watch(serviceRecordsProvider(vehicle.id)).value;
  ServiceRecord? last;
  for (final record in records ?? const <ServiceRecord>[]) {
    if (last == null || record.occurredOn.compareTo(last.occurredOn) > 0) {
      last = record;
    }
  }

  final estimate = snapshot?.estimate;
  final since = last?.odometer;
  final on = last == null ? null : CivilDate.tryParse(last.occurredOn);

  return (
    next: next,
    lastService: last,
    // Null rather than zero when either end is unknown. A receipt that reads
    // "0 km" for a service whose odometer nobody entered is a measurement the
    // app did not make.
    sinceMetres: estimate == null || since == null
        ? null
        : estimate.metres - since.metres,
    sinceDays: on == null || today == null ? null : on.daysUntil(today),
  );
}

/// Which conditional strips are eligible, capped and ordered by §9's priority.
///
/// **Two of the three cannot fire yet.** The done-from-notification
/// confirmation is written by a notification ACTION and the away digest needs
/// the notification permission state and a last-opened timestamp — all three
/// arrive with EPIC-16. Their widgets are built and tested; what is missing is
/// the trigger, and inventing one here would mean a strip that fires on a fact
/// nobody records.
List<HomeStripKind> _strips(
  Ref ref,
  Vehicle vehicle,
  VehicleDueSnapshot? snapshot,
  CivilDate? today,
) {
  final estimate = snapshot?.estimate;
  if (estimate == null || today == null) return const [];

  final unit = effectiveDistanceUnit(
    vehicle,
    ref.watch(settingsProvider).value,
  );

  // The drift is the RATE times the staleness, which is what "projected drift"
  // means: how far the app believes the car has gone since anybody looked. A
  // vehicle that has not moved has no drift and earns no strip at thirty days,
  // which is the whole point of §9's second threshold.
  final drift = snapshot!.rate.metresPerDay * estimate.staleDays;
  final stale =
      isOdometerStale(
        staleDays: estimate.staleDays,
        driftMetres: drift,
        unit: unit,
      ) &&
      !isStalenessDismissed(
        ref.watch(uiStateProvider)[uiKeyStalenessDismissedUntil(
          vehicle.id.toString(),
        )],
        today,
      );

  return homeStripQueue({if (stale) HomeStripKind.staleOdometer});
}

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
