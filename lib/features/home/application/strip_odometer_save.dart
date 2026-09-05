// Writing a reading from the staleness strip, without leaving Home.
//
// SPEC.md §9: "Strip **Save** — Writes `OdometerReading{source: manual}`,
// validates monotonicity, snackbar with **Undo**. On a violation the strip
// yields to the full `log.odometer` modal, which owns the
// typo/correction/backdate dialogue."
//
// The yield is the interesting half. `OdometerWouldGoBackwards` carries the
// conflicting neighbour and its date because §3's three resolutions all need
// both — and none of the three fits in a strip two lines tall. So the strip
// does not try: it reports that it could not, and the caller opens the screen
// that can.
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// What the strip's Save did.
sealed class StripSaveOutcome {
  const StripSaveOutcome();
}

/// It was written, and [reading] is the row an Undo would remove.
final class StripSaveWritten extends StripSaveOutcome {
  /// Creates the outcome.
  const StripSaveWritten(this.reading);

  /// What was written.
  final OdometerReading reading;
}

/// The history refuses it, and the full modal owns the conversation.
///
/// Carries the METRES the user typed so the modal opens on the number they
/// entered rather than empty — retyping a reading you have already typed once
/// is the fastest way to make somebody stop logging.
final class StripSaveYieldsToModal extends StripSaveOutcome {
  /// Creates the outcome.
  const StripSaveYieldsToModal(this.metres);

  /// The reading that could not be written.
  final int metres;
}

/// It could not be written for a reason that is not the history's.
final class StripSaveFailed extends StripSaveOutcome {
  /// Creates the outcome.
  const StripSaveFailed(this.failure);

  /// A full disk, a locked database, a degraded-mode refusal.
  final PersistFailure failure;
}

/// The strip's write path.
class StripOdometerSave extends Notifier<void> {
  @override
  void build() {}

  /// Writes [metres] against [vehicle] as a manual reading dated today.
  Future<StripSaveOutcome> save(Vehicle vehicle, int metres) async {
    final now = ref.read(clockProvider).now();
    final today = CivilDate.fromDateTime(now);
    // §3's clock-suspicion rule reaches here too: a phone that cannot say what
    // day it is cannot date a reading, and a reading with an invented date is
    // indistinguishable from a real one afterwards.
    if (today == null) {
      return const StripSaveFailed(
        WriteFailed('the device clock does not name a day'),
      );
    }

    final reading = OdometerReading(
      id: OdometerReadingId.mint(ref.read(ulidFactoryProvider)),
      vehicleId: vehicle.id,
      occurredOn: today.toString(),
      odometer: Distance(metres),
      // The unit the FIELD was in — provenance, never arithmetic. Storage is
      // metres and the conversion already happened in `OdometerEntry`.
      odometerUnit: vehicle.distanceUnit ?? DistanceUnit.km,
      source: OdometerSource.manual,
      createdAtUtcMs: now.millisecondsSinceEpoch,
      updatedAtUtcMs: now.millisecondsSinceEpoch,
    );

    final written = await ref
        .read(odometerRepositoryProvider)
        .saveReading(
          reading,
          vehicleUnit: vehicle.distanceUnit ?? DistanceUnit.km,
          purchaseOdometer: vehicle.purchaseOdometer,
        );

    return switch (written) {
      Ok() => StripSaveWritten(reading),
      // §9's yield, and only for THIS failure. A full disk is not a
      // conversation about backdating, and opening the modal over one would
      // make the user retype a reading into a form that cannot save it either.
      Err(failure: final OdometerWouldGoBackwards _) => StripSaveYieldsToModal(
        metres,
      ),
      Err(:final failure) => StripSaveFailed(failure),
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

/// The one way the strip writes a reading.
final NotifierProvider<StripOdometerSave, void> stripOdometerSaveProvider =
    NotifierProvider<StripOdometerSave, void>(StripOdometerSave.new);
