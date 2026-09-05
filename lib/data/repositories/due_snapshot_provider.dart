// One vehicle's due state, composed from the four streams it needs.
//
// `recomputeVehicle` is a pure function taking a vehicle, its items, its
// records, its reading series and the settings. This is the wiring.
//
// **Wanted by more than the garage.** It was written beside the garage that
// first needed it, in `lib/features/vehicles/`. EPIC-10's `home` needs the same
// snapshot for the active vehicle, `vehicle.switcher` needs it for every
// vehicle in the sheet, and `structure_test.dart` refuses one feature importing
// another — "two features share code by lifting it down to core/ or data/, or
// they meet via a route". Every input is a repository stream and the output is
// a pure-domain value, so this is the composition seam between the data layer
// and any screen that needs a due state. Composing it once is the difference
// between one answer and three that drift.
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
/// has to decide twice, and `garageStatusOf` already takes a nullable summary
/// for the same reason.
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

  // `CivilDate.fromDateTime`, not a string built here and parsed back. The
  // guard stays: a device clock reading year 275760 has no four-digit year, and
  // SPEC.md §3's clock-suspicion check exists because such clocks are real.
  final today = CivilDate.fromDateTime(ref.watch(clockProvider).now());
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
