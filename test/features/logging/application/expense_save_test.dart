// The expense write path.
//
// SPEC.md §10 `log.expense`: "No recurrence engine, no 'repeat yearly' switch.
// One payment is one row with a coverage window." What is asserted here is
// that the row carries the window and the SIGN — `Expense.amount` is the only
// money field in the app that may be negative, and the switch is what makes
// it so.
@TestOn('vm')
library;

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/id_provider.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/logging/application/expense_save.dart';
import 'package:odova/features/logging/domain/expense_draft.dart';

import '../../../data/support/test_ids.dart';
import '../../../support/provider_harness.dart';

final Currency _eur = Currency.tryParse('EUR')!;
final VehicleId _vehicleId = VehicleId.tryParse(
  'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
)!;

Vehicle _vehicle() => Vehicle(
  id: _vehicleId,
  name: 'The Golf',
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

void main() {
  late DatabaseHarness harness;

  setUp(() async {
    harness = containerWithDatabase(
      overrides: [
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 9, 2, 10)),
        ),
        ulidFactoryProvider.overrideWithValue(testIds()),
      ],
    );
    await harness.container.read(vehicleRepositoryProvider).save(_vehicle());
  });

  Future<int> liveCount(String table) async {
    final row = await harness.db
        .customSelect(
          'SELECT COUNT(*) AS n FROM $table WHERE deleted_at_utc_ms IS NULL',
        )
        .getSingle();
    return row.read<int>('n');
  }

  ExpenseSave save() => harness.container.read(expenseSaveProvider.notifier);

  test('a parking fee is one row', () async {
    final written = await save().save(
      vehicle: _vehicle(),
      occurredOn: '2026-09-02',
      draft: const ExpenseDraft(
        occurredOn: '2026-09-02',
        amount: '4.50',
      ).withCategory(ExpenseCategory.parking),
      currency: _eur,
    );

    expect(written, isA<ExpenseSaved>());
    expect(await liveCount('expenses'), 1);
    expect((written as ExpenseSaved).expense.amount.amountMinor, 450);
  });

  test('the refund switch is what makes the amount negative', () async {
    // §10 gives the SWITCH the sign rather than a minus key: "a minus on a
    // numeric pad is inconsistent across platforms and reverses badly in RTL".
    final written =
        await save().save(
              vehicle: _vehicle(),
              occurredOn: '2026-09-02',
              draft: const ExpenseDraft(
                occurredOn: '2026-09-02',
                amount: '80.00',
              ).withCategory(ExpenseCategory.fine).withRefund(refund: true),
              currency: _eur,
            )
            as ExpenseSaved;

    expect(written.expense.amount.amountMinor, -8000);
  });

  test('an insurance policy carries its coverage window', () async {
    // The window the category prefilled, on the row — this is what the cost
    // dashboard spreads over the months it covers, instead of twelve
    // generated rows to maintain, edit and delete.
    final written =
        await save().save(
              vehicle: _vehicle(),
              occurredOn: '2026-09-02',
              draft: const ExpenseDraft(
                occurredOn: '2026-09-02',
                amount: '640.00',
              ).withCategory(ExpenseCategory.insurance),
              currency: _eur,
            )
            as ExpenseSaved;

    expect(written.expense.coversFrom, '2026-09-02');
    expect(written.expense.coversTo, '2027-09-01');
  });

  test('a half minor unit survives the whole path', () async {
    // The bug `scaleByPowerOfTen` exists for, asserted end to end rather than
    // only at the value object.
    final written =
        await save().save(
              vehicle: _vehicle(),
              occurredOn: '2026-09-02',
              draft: const ExpenseDraft(
                occurredOn: '2026-09-02',
                amount: '8500.005',
              ).withCategory(ExpenseCategory.parking),
              currency: _eur,
            )
            as ExpenseSaved;

    expect(written.expense.amount.amountMinor, 850001);
  });

  test('Undo removes it', () async {
    final s = save();
    final written =
        await s.save(
              vehicle: _vehicle(),
              occurredOn: '2026-09-02',
              draft: const ExpenseDraft(
                occurredOn: '2026-09-02',
                amount: '4.50',
              ).withCategory(ExpenseCategory.parking),
              currency: _eur,
            )
            as ExpenseSaved;

    final undone = await s.undo(written.expense);

    expect(undone, isA<Ok<void, PersistFailure>>());
    expect(await liveCount('expenses'), 0);
  });
}
