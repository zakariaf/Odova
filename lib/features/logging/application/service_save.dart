// The one way a service record is written.
//
// SPEC.md §10 `log.service`. This is the only log row with CHILD rows, and §3
// makes `service_lines` live and die with its record — no soft delete of its
// own, `ON DELETE CASCADE` in the schema — so the record and its lines are
// assembled together here and written in one transaction by the repository.
//
// The rule that shapes the assembly is §10's cost model: a record ALWAYS has at
// least one line. `ServiceRepository.saveRecord` refuses a record with none,
// and it is right to: a service that reset no reminder is still a service that
// cost money, and a record with no line is a cost with nothing to attribute it
// to. `ServiceCostModel.lines` is what guarantees the one, and it takes the
// localised fallback label as an argument because it has no `BuildContext` and
// never will.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:odova/app/id_provider.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/minor_units.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/logging/domain/decimal_input.dart';
import 'package:odova/features/logging/domain/service_cost_model.dart';

/// What came of a service save.
@immutable
sealed class ServiceSaveOutcome {
  /// Creates an outcome.
  const ServiceSaveOutcome();
}

/// The record and its lines are on disk.
final class ServiceSaved extends ServiceSaveOutcome {
  /// Creates the outcome.
  const ServiceSaved(this.record);

  /// What was written — held so the Undo can name it.
  final ServiceRecord record;
}

/// Nothing was written.
final class ServiceSaveFailed extends ServiceSaveOutcome {
  /// Creates the outcome.
  const ServiceSaveFailed(this.failure);

  /// A full disk, a monotonicity refusal, a record with no line.
  final PersistFailure failure;
}

/// Writes a service record, and takes it back.
class ServiceSave extends Notifier<void> {
  @override
  void build() {}

  /// Writes [cost] as a record against [vehicle].
  ///
  /// [fallbackLabel] is the localised "Service", used when no item is ticked.
  /// It is passed in rather than looked up because this layer has no
  /// `BuildContext`, and a record with an English label on a Persian phone is
  /// a row the user cannot read back.
  Future<ServiceSaveOutcome> save({
    required Vehicle vehicle,
    required ServiceCostModel cost,
    required String occurredOn,
    required Currency currency,
    required String fallbackLabel,
    Distance? odometer,
  }) async {
    final now = ref.read(clockProvider).now();
    final on = CivilDate.tryParse(occurredOn);
    if (on == null) {
      return const ServiceSaveFailed(
        WriteFailed('the service record does not name a day'),
      );
    }

    final ids = ref.read(ulidFactoryProvider);
    final recordId = ServiceRecordId.mint(ids);
    final lines = [
      for (final line in cost.lines(fallbackLabel: fallbackLabel))
        ServiceLine(
          id: ServiceLineId.mint(ids),
          serviceRecordId: recordId,
          label: line.label,
          amount: Money(_minor(line.amount, cost, currency), currency),
          // Null for a `+ Other` line and for the fallback: §9 says a line
          // whose item is gone keeps its label and its money and loses only
          // the link, and a line that never had one is the same shape.
          serviceItemId: line.itemId == null || line.itemId == kOtherLineId
              ? null
              : ServiceItemId.tryParse(line.itemId!),
        ),
    ];

    final record = ServiceRecord(
      id: recordId,
      vehicleId: vehicle.id,
      occurredOn: on.toString(),
      odometer: odometer,
      odometerUnit: vehicle.distanceUnit ?? DistanceUnit.km,
      lines: lines,
      // §10 prints `—` rather than 0 for a job with no cost recorded, and this
      // is the flag that tells it which it is: zero entered is a real zero (a
      // warranty job really did cost nothing), and nothing entered is not.
      costEstimated: cost.sum.isEmpty && cost.total.trim().isEmpty,
      createdAtUtcMs: now.millisecondsSinceEpoch,
      updatedAtUtcMs: now.millisecondsSinceEpoch,
    );

    final written = await ref
        .read(serviceRepositoryProvider)
        .saveRecord(record);
    return switch (written) {
      Ok(value: final saved) => ServiceSaved(saved),
      Err(:final failure) => ServiceSaveFailed(failure),
    };
  }

  /// Removes what [save] wrote, reading included.
  Future<Result<void, PersistFailure>> undo(ServiceRecord record) => ref
      .read(serviceRepositoryProvider)
      .deleteRecord(
        record.id,
        deletedAtUtcMs: ref.read(clockProvider).now().millisecondsSinceEpoch,
      );

  /// Puts back what [undo] removed.
  Future<Result<void, PersistFailure>> redo(ServiceRecord record) =>
      ref.read(serviceRepositoryProvider).undeleteRecord(record.id);

  int _minor(String amount, ServiceCostModel cost, Currency currency) {
    final read = parseDecimal(
      amount,
      groupingSeparator: cost.groupingSeparator,
    );
    if (read is! DecimalOk) return 0;
    return minorUnitsFrom(read.canonical, currency) ?? 0;
  }
}

/// The one way the log modal writes a service record.
final NotifierProvider<ServiceSave, void> serviceSaveProvider =
    NotifierProvider<ServiceSave, void>(ServiceSave.new);
