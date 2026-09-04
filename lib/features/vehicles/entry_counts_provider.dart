// How many entries hang off one vehicle.
//
// Two callers, both in SPEC.md §8. The garage's sold row reads
// "Sold 12 March 2024 · 1,204 entries", and `dialog.confirmDelete` states the
// total and the five per-type counts before it destroys them.
//
// A FUTURE rather than a stream. Five `COUNT(*)` queries do not belong on a
// watcher that re-runs every time any row in any of those five tables changes;
// the number is a headline on a row the user opens rarely, not a live figure.
// The cost of that choice is one frame with no count, and the row spends it
// saying nothing rather than saying zero — see `vehicleSoldSummary`'s `=0`
// case, which is a real zero and not an unknown one.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/ui/dialogs/confirm_delete_dialog.dart';

/// One vehicle's entry counts, or null when they could not be read.
///
/// Null rather than a thrown failure: a garage row whose count query failed
/// still has to draw, and SPEC.md §8's rule that "the row never disappears"
/// covers the count for the same reason it covers the due summary.
final FutureProviderFamily<DeleteCounts?, VehicleId>
vehicleEntryCountsProvider = FutureProvider.autoDispose.family((
  ref,
  vehicleId,
) async {
  final result = await ref
      .watch(vehicleRepositoryProvider)
      .entryCounts(vehicleId);
  return result.valueOrNull;
});
