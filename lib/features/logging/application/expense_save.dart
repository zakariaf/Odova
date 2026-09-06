// The one way an expense is written.
//
// SPEC.md §10 `log.expense`: "No recurrence engine, no 'repeat yearly' switch.
// One payment is one row with a coverage window, which the cost dashboard
// spreads over the months it covers; twelve generated rows would be twelve rows
// to maintain, edit and delete."
//
// The sign is the interesting part. `Expense.amount` is the ONLY money field in
// the app that may be negative — a refund, a warranty reimbursement, an
// insurance payout — and §10 gives that sign to a SWITCH rather than a minus
// key, "because a minus key on a numeric pad is inconsistent across platforms
// and reverses badly in RTL; a switch reads the same in six languages". So the
// draft holds a positive number and a boolean, and this is where the two
// become one signed integer.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:odova/app/id_provider.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/logging/domain/expense_draft.dart';

/// What came of an expense save.
@immutable
sealed class ExpenseSaveOutcome {
  /// Creates an outcome.
  const ExpenseSaveOutcome();
}

/// The row is on disk.
final class ExpenseSaved extends ExpenseSaveOutcome {
  /// Creates the outcome.
  const ExpenseSaved(this.expense);

  /// What was written — held so the Undo can name it.
  final Expense expense;
}

/// Nothing was written.
final class ExpenseSaveFailed extends ExpenseSaveOutcome {
  /// Creates the outcome.
  const ExpenseSaveFailed(this.failure);

  /// A full disk, a degraded-mode refusal, an orphan reference.
  final PersistFailure failure;
}

/// Writes an expense, and takes it back.
class ExpenseSave extends Notifier<void> {
  @override
  void build() {}

  /// Writes [draft] against [vehicle].
  Future<ExpenseSaveOutcome> save({
    required Vehicle vehicle,
    required ExpenseDraft draft,
    required Currency currency,
    Distance? odometer,
  }) async {
    final now = ref.read(clockProvider).now();
    final occurredOn = CivilDate.tryParse(draft.occurredOn);
    final category = draft.category;
    if (occurredOn == null || category == null) {
      return const ExpenseSaveFailed(
        WriteFailed('the expense has no date or no category'),
      );
    }

    final expense = Expense(
      id: ExpenseId.mint(ref.read(ulidFactoryProvider)),
      vehicleId: vehicle.id,
      occurredOn: occurredOn.toString(),
      category: category,
      // Signed HERE and nowhere else. The draft carries a positive figure and
      // the refund switch; one signed integer is what the column holds.
      amount: Money(
        draft.signedMinorUnits(exponent: currency.exponent) ?? 0,
        currency,
      ),
      // Only for `other`, which is what the `expenses` CHECK enforces: a
      // custom row without a name is a cost nothing on screen can explain.
      label: category == ExpenseCategory.other ? _orNull(draft.label) : null,
      coversFrom: draft.coversPeriod ? draft.coversFrom : null,
      coversTo: draft.coversPeriod ? draft.coversTo : null,
      odometer: odometer,
      odometerUnit: vehicle.distanceUnit ?? DistanceUnit.km,
      createdAtUtcMs: now.millisecondsSinceEpoch,
      updatedAtUtcMs: now.millisecondsSinceEpoch,
    );

    final written = await ref.read(expenseRepositoryProvider).save(expense);
    return switch (written) {
      Ok(value: final saved) => ExpenseSaved(saved),
      Err(:final failure) => ExpenseSaveFailed(failure),
    };
  }

  /// Removes what [save] wrote, reading included.
  Future<Result<void, PersistFailure>> undo(Expense expense) => ref
      .read(expenseRepositoryProvider)
      .delete(
        expense.id,
        deletedAtUtcMs: ref.read(clockProvider).now().millisecondsSinceEpoch,
      );

  /// Puts back what [undo] removed.
  Future<Result<void, PersistFailure>> redo(Expense expense) =>
      ref.read(expenseRepositoryProvider).undelete(expense.id);

  String? _orNull(String value) => value.trim().isEmpty ? null : value.trim();
}

/// The one way the log modal writes an expense.
final NotifierProvider<ExpenseSave, void> expenseSaveProvider =
    NotifierProvider<ExpenseSave, void>(ExpenseSave.new);
