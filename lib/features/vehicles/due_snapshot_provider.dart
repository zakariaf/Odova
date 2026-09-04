// One vehicle's due state, composed from the four streams it needs.
//
// `recomputeVehicle` is a pure function taking a vehicle, its items, its
// records, its reading series and the settings. This is the wiring — and it is
// in `lib/features/vehicles/` rather than in `lib/data/` because it computes
// rather than persists, and `lib/data/repositories/providers.dart` is a list of
// things that read rows.
//
// **Wanted by more than the garage.** EPIC-10's `home` needs the same snapshot
// for the active vehicle, and `vehicle.switcher` needs it for every vehicle in
// the sheet. Composing it once here is the difference between one answer and
// three that drift.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;
import 'package:odova/app/providers.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/due/vehicle_due_snapshot.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/data/repositories/providers.dart';

/// The date the app was built, for SPEC.md §3's clock-suspicion check.
///
/// A phone whose clock reads 1970 or 2050 must not have its due dates believed,
/// and "before this build existed" is the only fact the app has to check
/// against. Overridden in tests; the default is deliberately the epoch of this
/// work rather than `DateTime.now()`, which would validate a clock against
/// itself and always agree.
final buildDateProvider = Provider<CivilDate>(
  (ref) => CivilDate.tryParse('2026-09-01')!,
);

/// One vehicle's due snapshot, or null while its inputs are still loading.
///
/// Null rather than an `AsyncValue`, because every caller draws the same thing
/// for "loading" and for "the engine could not answer" — SPEC.md §8's hollow
/// dot and "Couldn't work out what's due". Collapsing them here means no screen
/// has
/// to decide twice, and `garageStatusOf` already takes a nullable summary for
/// the same reason.
final ProviderFamily<VehicleDueSnapshot?, VehicleId>
vehicleDueSnapshotProvider = Provider.autoDispose.family((ref, vehicleId) {
  final vehicles = ref.watch(vehiclesProvider).value;
  final items = ref.watch(serviceItemsProvider(vehicleId)).value;
  final records = ref.watch(serviceRecordsProvider(vehicleId)).value;
  final readings = ref.watch(odometerReadingsProvider(vehicleId)).value;
  final corrections = ref
      .watch(
        odometerCorrectionsProvider(vehicleId),
      )
      .value;
  final settings = ref.watch(settingsProvider).value;

  if (vehicles == null ||
      items == null ||
      records == null ||
      readings == null ||
      corrections == null ||
      settings == null) {
    return null;
  }

  final vehicle = vehicles.where((v) => v.id == vehicleId).firstOrNull;
  if (vehicle == null) return null;

  final now = ref.watch(clockProvider).now();
  final today = CivilDate.tryParse(
    '${now.year.toString().padLeft(4, '0')}-'
    '${now.month.toString().padLeft(2, '0')}-'
    '${now.day.toString().padLeft(2, '0')}',
  );
  if (today == null) return null;

  return recomputeVehicle(
    vehicle,
    items,
    records,
    ReadingSeries.from(readings, corrections),
    settings,
    today: today,
    buildDate: ref.watch(buildDateProvider),
  );
});
