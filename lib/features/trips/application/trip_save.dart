// The one way a trip is written.
//
// SPEC.md §10 `trips.edit`: "one `Trip`, plus up to two `OdometerReading`
// rows, one per endpoint entered." Both halves are `TripRepository.save`'s
// job, in one transaction, and this file's only work is turning a
// [TripDraft] into the record it writes — which is where the distance rule
// gets applied for the last time.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:odova/app/id_provider.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/trips/trip_draft.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';

/// What came of a trip save.
@immutable
sealed class TripSaveOutcome {
  /// Creates an outcome.
  const TripSaveOutcome();
}

/// The row is on disk.
final class TripSaved extends TripSaveOutcome {
  /// Creates the outcome.
  const TripSaved(this.trip);

  /// What was written — held so the Undo can take it back.
  final Trip trip;
}

/// Nothing was written.
final class TripSaveFailed extends TripSaveOutcome {
  /// Creates the outcome.
  const TripSaveFailed(this.failure);

  /// A full disk, a degraded-mode refusal, a reading that went backwards.
  final PersistFailure failure;
}

/// Writes a trip, and takes it back.
class TripSave extends Notifier<void> {
  @override
  void build() {}

  /// Writes [draft] against [vehicle], creating or replacing [existing].
  Future<TripSaveOutcome> save({
    required Vehicle vehicle,
    required TripDraft draft,
    Trip? existing,
  }) async {
    final now = ref.read(clockProvider).now().millisecondsSinceEpoch;
    final unit = vehicle.distanceUnit ?? DistanceUnit.km;

    Distance? distance(int? metres) => metres == null ? null : Distance(metres);

    final trip = Trip(
      id: existing?.id ?? TripId.mint(ref.read(ulidFactoryProvider)),
      vehicleId: vehicle.id,
      title: _orNull(draft.title),
      purpose: draft.purpose,
      startedOn: draft.startedOn,
      // Still going wins over whatever is left in the field. §10 hides the end
      // fields when it is ticked, and a hidden field that still reaches the
      // database is a value the user cannot see and cannot correct.
      endedOn: draft.stillGoing ? null : draft.endedOn,
      startOdometer: distance(draft.startOdometerMetres(unit: unit)),
      endOdometer: draft.stillGoing
          ? null
          : distance(draft.endOdometerMetres(unit: unit)),
      // Null the moment either endpoint is filled — `manualDistanceMetres`
      // enforces that, once, for every caller. §3: the odometer wins, and a
      // bare-distance trip contributes nothing to the odometer series.
      manualDistance: distance(draft.manualDistanceMetres(unit: unit)),
      odometerUnit: unit,
      notes: _orNull(draft.notes),
      createdAtUtcMs: existing?.createdAtUtcMs ?? now,
      updatedAtUtcMs: now,
    );

    final written = await ref.read(tripRepositoryProvider).save(trip);
    return switch (written) {
      Ok(value: final saved) => TripSaved(saved),
      Err(:final failure) => TripSaveFailed(failure),
    };
  }

  /// Removes a trip, keeping everything attributed to it.
  ///
  /// SPEC.md §10: "Deleting a trip does **not** delete its expenses or
  /// fill-ups — they lose the trip link and stay in history." Eight years of
  /// spending is the thing this app exists to keep, and a cascade here would
  /// take a week of tolls out of the cost dashboard because somebody tidied up
  /// a trip.
  Future<Result<void, PersistFailure>> delete(TripId id) => ref
      .read(tripRepositoryProvider)
      .delete(
        id,
        deletedAtUtcMs: ref.read(clockProvider).now().millisecondsSinceEpoch,
      );
}

String? _orNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// The one way `trips.edit` writes.
final NotifierProvider<TripSave, void> tripSaveProvider =
    NotifierProvider<TripSave, void>(TripSave.new);
