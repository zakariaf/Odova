// The one way `log.odometer` writes a reading.
//
// SPEC.md §10: "Two fields. No notes, no category, no More section — this
// screen exists to be finished before the user changes their mind." What it
// writes is a MANUAL reading, and that word is the whole distinction: nothing
// implied this number, the user read it off the dash and typed it.
// `odometer_fan_out.dart` owns every other source and says so — it "is the
// ONLY writer of a non-manual reading" — so this file writes the one kind it
// does not.
//
// `StripOdometerSave` does the same job for Home's staleness strip and is not
// reused here, deliberately: its outcomes carry §9's yield-to-modal case,
// which exists because the strip has somewhere to hand the user off TO. This
// form is that somewhere, so the same outcome would be a loop.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:odova/app/id_provider.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';

/// What came of an odometer save.
@immutable
sealed class OdometerLogSaveOutcome {
  /// Creates an outcome.
  const OdometerLogSaveOutcome();
}

/// The reading is on disk.
final class OdometerLogSaved extends OdometerLogSaveOutcome {
  /// Creates the outcome.
  const OdometerLogSaved(this.reading);

  /// What was written — held so the Undo can name it.
  final OdometerReading reading;
}

/// Nothing was written.
final class OdometerLogSaveFailed extends OdometerLogSaveOutcome {
  /// Creates the outcome.
  const OdometerLogSaveFailed(this.failure);

  /// A full disk, or the monotonicity refusal §14 defines.
  final PersistFailure failure;
}

/// Writes a manual odometer reading, and takes it back.
class OdometerLogSave extends Notifier<void> {
  @override
  void build() {}

  /// Writes [odometer] against [vehicle], dated [occurredOn].
  Future<OdometerLogSaveOutcome> save({
    required Vehicle vehicle,
    required Distance odometer,
    required String occurredOn,
  }) async {
    final now = ref.read(clockProvider).now();
    final on = CivilDate.tryParse(occurredOn);
    // §3's clock-suspicion rule: a reading with an invented date is
    // indistinguishable from a real one afterwards.
    if (on == null) {
      return const OdometerLogSaveFailed(
        WriteFailed('the reading does not name a day'),
      );
    }

    final unit = vehicle.distanceUnit ?? DistanceUnit.km;
    final reading = OdometerReading(
      id: OdometerReadingId.mint(ref.read(ulidFactoryProvider)),
      vehicleId: vehicle.id,
      occurredOn: on.toString(),
      odometer: odometer,
      // The unit the FIELD was in — provenance, never arithmetic. Storage is
      // metres and the conversion already happened in `OdometerEntry`.
      odometerUnit: unit,
      source: OdometerSource.manual,
      createdAtUtcMs: now.millisecondsSinceEpoch,
      updatedAtUtcMs: now.millisecondsSinceEpoch,
    );

    final written = await ref
        .read(odometerRepositoryProvider)
        .saveReading(
          reading,
          vehicleUnit: unit,
          purchaseOdometer: vehicle.purchaseOdometer,
        );

    return switch (written) {
      Ok() => OdometerLogSaved(reading),
      Err(:final failure) => OdometerLogSaveFailed(failure),
    };
  }

  /// Removes what [save] wrote.
  Future<Result<void, PersistFailure>> undo(OdometerReading reading) => ref
      .read(odometerRepositoryProvider)
      .deleteReading(
        reading.id,
        reading.vehicleId,
        deletedAtUtcMs: ref.read(clockProvider).now().millisecondsSinceEpoch,
      );
}

/// The one way `log.odometer` writes a reading.
final NotifierProvider<OdometerLogSave, void> odometerLogSaveProvider =
    NotifierProvider<OdometerLogSave, void>(OdometerLogSave.new);
