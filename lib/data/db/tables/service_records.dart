// A job that was actually done, and its lines.
//
// SPEC.md §3 Entities (`ServiceRecord`, `ServiceLine`), §3 Invariants.
//
// **There is no total column on the record.** Cost is ALWAYS the sum of the
// lines. A stored total is a second answer that drifts the first time a line is
// edited, and then the history screen and the cost dashboard disagree about
// what a service cost — with no way to tell which one is the receipt.
import 'package:drift/drift.dart';
import 'package:odova/data/db/tables/audit_columns.dart';

/// A service record.
@DataClassName('ServiceRecordRow')
class ServiceRecords extends Table with AuditColumns {
  /// The vehicle. Carried directly even where a parent could supply it, so
  /// orphan detection on import is a single pass (SPEC.md §3).
  TextColumn get vehicleId => text()
      .named('vehicle_id')
      .customConstraint(
        'NOT NULL REFERENCES vehicles (id) ON DELETE CASCADE',
      )();

  /// The day the work happened. Zoneless `YYYY-MM-DD`.
  TextColumn get occurredOn => text()
      .named('occurred_on')
      .customConstraint(
        'NOT NULL CHECK (occurred_on GLOB '
        "'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
      )();

  /// The odometer at the time, in metres. Strongly encouraged, not required.
  IntColumn get odometerM => integer()
      .named('odometer_m')
      .customConstraint('CHECK (odometer_m IS NULL OR odometer_m >= 0)')
      .nullable()();

  /// The unit the reading was ENTERED in. Display fidelity only.
  TextColumn get odometerUnit => text()
      .named('odometer_unit')
      .customConstraint("NOT NULL CHECK (odometer_unit IN ('km', 'mi'))")();

  /// True = the app filled the odometer in, so it is drawn with a `~`.
  BoolColumn get odometerEstimated => boolean()
      .named('odometer_estimated')
      .withDefault(const Constant(false))();

  /// True = no cost was recorded. Contributes 0 to the dashboard and prints
  /// `—` in the report, footnoted. Set by "Done" from a notification, which
  /// must not require typing.
  BoolColumn get costEstimated =>
      boolean().named('cost_estimated').withDefault(const Constant(false))();

  /// Who did the work.
  TextColumn get vendor => text().nullable()();

  /// The workshop's reference.
  TextColumn get invoiceRef => text().named('invoice_ref').nullable()();

  /// The day the workshop's warranty on this job expires.
  TextColumn get warrantyUntil => text().named('warranty_until').nullable()();

  /// Free text.
  TextColumn get notes => text().nullable()();
}

/// One line of a service record.
///
/// A child row: it carries an `id` and nothing else from [AuditColumns],
/// because it lives and dies with its parent and is never listed, filtered or
/// soft-deleted on its own.
@DataClassName('ServiceLineRow')
class ServiceLines extends Table {
  /// `lin_<ULID>`.
  TextColumn get id => text()();

  /// The record this belongs to.
  TextColumn get serviceRecordId => text()
      .named('service_record_id')
      .customConstraint(
        'NOT NULL REFERENCES service_records (id) ON DELETE CASCADE',
      )();

  /// Which reminder this line resets, or null.
  ///
  /// `ON DELETE SET NULL`, not cascade. SPEC.md §3: deleting a ServiceItem
  /// never touches history — every referencing line is rewritten to null and
  /// KEEPS its label and amount. Cascading here would delete the record of
  /// work that was actually done because the user tidied up a reminder.
  TextColumn get serviceItemId => text()
      .named('service_item_id')
      .customConstraint(
        'REFERENCES service_items (id) ON DELETE SET NULL',
      )
      .nullable()();

  /// What it was: "Oil and filter", "Front pads", "Labour".
  ///
  /// Kept on the line rather than read through [serviceItemId], which is
  /// exactly what lets the line survive its item being deleted.
  TextColumn get label => text()();

  /// The amount in minor units.
  ///
  /// `>= 0`. A warranty job is 0 — the model requires at least one line, so
  /// zero is the only representable "not recorded" — and it is never negative.
  /// A refund is an `Expense`, which is the one money column that may be.
  IntColumn get amountMinor => integer()
      .named('amount_minor')
      .customConstraint('NOT NULL CHECK (amount_minor >= 0)')();

  /// The currency, ISO 4217.
  TextColumn get currency => text().customConstraint(
    'NOT NULL CHECK (length(currency) = 3)',
  )();

  /// The part fitted.
  TextColumn get partNumber => text().named('part_number').nullable()();

  /// Free text.
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  bool get isStrict => true;
}
