// The one way a fill-up is written.
//
// SPEC.md §10's Definition of done for this epic: "every save is one
// transaction ending in a due-state recompute and a notification". The
// transaction is the repository's — `FillUpRepository.save` writes the row and
// fans out the derived reading together, because §3 says every record carrying
// an odometer emits one and `odometer_fan_out.dart` is the ONLY writer of a
// non-manual reading.
//
// What lives HERE is the assembly: turning what the user typed into the row,
// with the ids, the clock and the vehicle's units read once. It is the seam
// `StripOdometerSave` already established for the home strip, and the shape is
// deliberately the same — a `Notifier` with a `save` and an `undo`, returning a
// sealed outcome rather than throwing.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:odova/app/id_provider.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/minor_units.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/logging/domain/decimal_input.dart';
import 'package:odova/features/logging/domain/fillup_draft.dart';
import 'package:odova/features/logging/domain/fuel_quantity_input.dart';

/// What came of a fill-up save.
@immutable
sealed class FillUpSaveOutcome {
  /// Creates an outcome.
  const FillUpSaveOutcome();
}

/// The row is on disk, with its derived reading.
final class FillUpSaved extends FillUpSaveOutcome {
  /// Creates the outcome.
  const FillUpSaved(this.fillUp);

  /// What was written — held so the Undo can name it.
  final FillUp fillUp;
}

/// Nothing was written.
final class FillUpSaveFailed extends FillUpSaveOutcome {
  /// Creates the outcome.
  const FillUpSaveFailed(this.failure);

  /// A full disk, a monotonicity refusal, a degraded-mode refusal.
  final PersistFailure failure;
}

/// Writes a fill-up, and takes it back.
class FillUpSave extends Notifier<void> {
  @override
  void build() {}

  /// Writes [draft] against [vehicle].
  ///
  /// [odometer] is passed IN rather than read off the draft: the odometer
  /// field is shared across three forms and owns its own parsing, including
  /// the overflow guard that `OdometerEntry` exists for. A second parse here
  /// would be a second answer.
  Future<FillUpSaveOutcome> save({
    required Vehicle vehicle,
    required FillUpDraft draft,
    required Currency currency,
    Distance? odometer,
  }) async {
    final now = ref.read(clockProvider).now();
    final occurredOn = CivilDate.tryParse(draft.occurredOn);
    // §3's clock-suspicion rule reaches here too, by way of the draft: a row
    // dated by a phone that cannot say what day it is is indistinguishable
    // from a real one afterwards.
    if (occurredOn == null) {
      return const FillUpSaveFailed(
        WriteFailed('the fill-up does not name a day'),
      );
    }

    final fuelKind = vehicle.fuelKindDefault;
    final fillUp = FillUp(
      id: FillUpId.mint(ref.read(ulidFactoryProvider)),
      vehicleId: vehicle.id,
      occurredOn: occurredOn.toString(),
      odometer: odometer,
      // The unit the FIELD was in — provenance, never arithmetic. Storage is
      // metres and the conversion already happened in `OdometerEntry`.
      odometerUnit: vehicle.distanceUnit ?? DistanceUnit.km,
      fuelKind: fuelKind,
      // From the DISPLAYED string, never the raw quotient. §10: "76.66 € ÷
      // 1.799 shows 42.61 L and stores 42 610 mL, not 42 613.7 — a hidden
      // extra decimal makes the app's own price-per-litre disagree with the
      // receipt, and then nothing on screen is trusted."
      quantity: _quantity(draft, fuelKind),
      quantityUnit: vehicle.volumeUnit ?? VolumeUnit.l,
      totalCost: _total(draft, currency),
      isFullTank: draft.isFullTank,
      chainBroken: draft.chainBroken,
      grade: _orNull(draft.grade),
      station: _orNull(draft.station),
      notes: _orNull(draft.notes),
      createdAtUtcMs: now.millisecondsSinceEpoch,
      updatedAtUtcMs: now.millisecondsSinceEpoch,
    );

    final written = await ref.read(fillUpRepositoryProvider).save(fillUp);
    return switch (written) {
      Ok(value: final saved) => FillUpSaved(saved),
      Err(:final failure) => FillUpSaveFailed(failure),
    };
  }

  /// Removes what [save] wrote, reading included.
  ///
  /// §10 makes the snackbar the only confirmation logging gets — "a wrong
  /// entry costs one tap to fix; a confirmation dialog is paid for on every
  /// correct entry" — and that trade only holds if this works.
  Future<Result<void, PersistFailure>> undo(FillUp fillUp) => ref
      .read(fillUpRepositoryProvider)
      .delete(
        fillUp.id,
        deletedAtUtcMs: ref.read(clockProvider).now().millisecondsSinceEpoch,
      );

  /// Puts back what [undo] removed, for an Undo of the Undo.
  Future<Result<void, PersistFailure>> redo(FillUp fillUp) =>
      ref.read(fillUpRepositoryProvider).undelete(fillUp.id);

  FuelQuantity? _quantity(FillUpDraft draft, FuelKind kind) {
    final read = parseDecimal(
      draft.trio.quantity,
      groupingSeparator: draft.trio.groupingSeparator,
    );
    if (read is! DecimalOk) return null;
    return fuelQuantityFrom(kind: kind, canonical: read.canonical);
  }

  Money _total(FillUpDraft draft, Currency currency) {
    final read = parseDecimal(
      draft.trio.total,
      groupingSeparator: draft.trio.groupingSeparator,
    );
    if (read is! DecimalOk) return Money.zero(currency);
    // A free fill-up is 0 and is legal; an unreadable one is also 0 rather
    // than a refusal, because `problems()` has already refused it upstream and
    // this is not a second place to decide that.
    return Money(minorUnitsFrom(read.canonical, currency) ?? 0, currency);
  }

  String? _orNull(String value) => value.trim().isEmpty ? null : value.trim();
}

/// The one way the log modal writes a fill-up.
final NotifierProvider<FillUpSave, void> fillUpSaveProvider =
    NotifierProvider<FillUpSave, void>(FillUpSave.new);
