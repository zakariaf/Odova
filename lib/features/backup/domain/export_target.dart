// Which vehicle an export is about — SPEC.md §6 §8.1 and §13's export flow.
//
// Three of the four outputs are per-vehicle and one of them additionally
// offers "All vehicles". That asymmetry is not an oversight and it is worth
// stating: the all-costs CSV is "the file someone opens to build a pivot
// table" (§8.1), and a pivot over a household is the thing a household wants.
// A fill-ups CSV across two vehicles would put a van's litres and a bike's
// litres in one column with nothing but a name to tell them apart, and the
// service-history PDF is a document about ONE car that a buyer reads.
import 'package:meta/meta.dart';
import 'package:odova/core/ids/record_id.dart';

/// The four things the Export screen can produce.
///
/// §6 §8 lists five exports and one of them — the `.ics` snapshot — lives on
/// `settings.notifications`. It is absent here on purpose: an export screen
/// that offered a calendar file would be a second place to look for it.
enum ExportKind {
  /// The JSON backup. The whole store; no picker at all.
  backup,

  /// §8.1's fill-ups CSV. Per-vehicle.
  fillUpsCsv,

  /// §8.1's all-costs CSV. Per-vehicle, or all of them.
  costsCsv,

  /// §8.2's service history. Per-vehicle, and about one car by definition.
  serviceHistoryPdf;

  /// Whether this export asks which vehicle.
  ///
  /// The backup never does: it is the whole store, and a per-vehicle backup
  /// would be a file that cannot restore the phone it came from.
  bool get needsVehicle => this != ExportKind.backup;

  /// Whether "All vehicles" is one of the answers.
  bool get offersAllVehicles => this == ExportKind.costsCsv;
}

/// What the user chose.
@immutable
sealed class ExportTarget {
  const ExportTarget();
}

/// One vehicle.
final class SingleVehicleTarget extends ExportTarget {
  /// Creates the target.
  const SingleVehicleTarget(this.vehicleId, {required this.positionalIndex});

  /// Which one.
  final VehicleId vehicleId;

  /// Its ONE-BASED place in the garage, for the filename fallback.
  ///
  /// A name written only in Arabic script transliterates to nothing, and
  /// `vehicleFileSlug` needs a number the user can match to a row in their
  /// garage — which means the position has to travel with the choice rather
  /// than being recomputed by whoever builds the filename.
  final int positionalIndex;
}

/// Every vehicle. Only the costs CSV offers it.
final class AllVehiclesTarget extends ExportTarget {
  /// Creates the target.
  const AllVehiclesTarget();
}

/// Whether [kind] should open the picker for a garage of [vehicleCount].
///
/// One vehicle goes straight through. A sheet that asks a question with one
/// answer is a tap the user has to make to tell the app something it already
/// knows — and this app's whole promise is under a minute a month.
bool needsVehiclePicker(ExportKind kind, {required int vehicleCount}) =>
    kind.needsVehicle && vehicleCount > 1;
