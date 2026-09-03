// A payment.
//
// SPEC.md §3 Entities (`Expense`). No recurrence engine: one payment is one
// row, and an annual premium is a single expense with a twelve-month coverage
// window that the monthly cost view amortises.
import 'package:drift/drift.dart';
import 'package:odova/data/db/tables/audit_columns.dart';

/// An expense.
@DataClassName('ExpenseRow')
class Expenses extends Table with AuditColumns {
  /// The vehicle. Carried directly even when [tripId] is set.
  TextColumn get vehicleId => text()
      .named('vehicle_id')
      .customConstraint(
        'NOT NULL REFERENCES vehicles (id) ON DELETE CASCADE',
      )();

  /// The trip this belongs to, if any.
  TextColumn get tripId => text()
      .named('trip_id')
      .customConstraint('REFERENCES trips (id) ON DELETE SET NULL')
      .nullable()();

  /// The day it was PAID.
  TextColumn get occurredOn => text()
      .named('occurred_on')
      .customConstraint(
        'NOT NULL CHECK (occurred_on GLOB '
        "'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
      )();

  /// What it was for. Ten values, no more (SPEC.md §3 Enums).
  TextColumn get category => text().customConstraint(
    "NOT NULL CHECK (category IN ('insurance', 'tax_registration', "
    "'parking', 'toll', 'fine', 'wash', 'tyre_storage', 'accessories', "
    "'finance', 'other'))",
  )();

  /// What to call it. Required when [category] is `other`.
  TextColumn get label => text().nullable()();

  /// The amount in minor units.
  ///
  /// **The one money column in the schema with no `>= 0` check, and that is
  /// deliberate.** A refund, a warranty reimbursement or an insurance payout
  /// is a negative expense, and it is the only way to represent money coming
  /// back. `test/data/db/tables/expenses_test.dart` asserts a negative row
  /// inserts, so that nobody later "fixes" the missing check.
  IntColumn get amountMinor => integer().named('amount_minor')();

  /// The currency, ISO 4217.
  TextColumn get currency => text().customConstraint(
    'NOT NULL CHECK (length(currency) = 3)',
  )();

  /// The start of an optional coverage window, for amortisation.
  TextColumn get coversFrom => text().named('covers_from').nullable()();

  /// The end of it.
  TextColumn get coversTo => text().named('covers_to').nullable()();

  /// The odometer, in metres.
  IntColumn get odometerM => integer()
      .named('odometer_m')
      .customConstraint('CHECK (odometer_m IS NULL OR odometer_m >= 0)')
      .nullable()();

  /// The unit the reading was entered in.
  TextColumn get odometerUnit => text()
      .named('odometer_unit')
      .customConstraint("NOT NULL CHECK (odometer_unit IN ('km', 'mi'))")();

  /// Who was paid.
  TextColumn get vendor => text().nullable()();

  /// Free text.
  TextColumn get notes => text().nullable()();

  /// `other` has no name of its own, so it needs one.
  static const _otherNeedsLabel =
      "CHECK (category <> 'other' OR label IS NOT NULL)";

  /// A coverage window that runs backwards amortises to a negative month.
  static const _coverageRunsForwards =
      'CHECK (covers_from IS NULL OR covers_to IS NULL '
      'OR covers_to >= covers_from)';

  @override
  List<String> get customConstraints => [
    _otherNeedsLabel,
    _coverageRunsForwards,
  ];
}
