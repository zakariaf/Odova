// Every odometer reading in the app, from whatever produced it.
//
// SPEC.md §3 The odometer: continuity and corrections. EVERY record carrying an
// odometer emits a reading here, so ONE table computes distance history and
// enforces monotonicity — rather than four tables each holding a number that
// nothing reconciles.
import 'package:drift/drift.dart';
import 'package:odova/data/db/tables/audit_columns.dart';

/// An odometer reading.
@DataClassName('OdometerReadingRow')
class OdometerReadings extends Table with AuditColumns {
  /// The vehicle.
  TextColumn get vehicleId => text()
      .named('vehicle_id')
      .customConstraint(
        'NOT NULL REFERENCES vehicles (id) ON DELETE CASCADE',
      )();

  /// The day the dash showed this.
  TextColumn get occurredOn => text()
      .named('occurred_on')
      .customConstraint(
        'NOT NULL CHECK (occurred_on GLOB '
        "'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
      )();

  /// What the dash showed, in metres.
  ///
  /// The RAW dash number, not the cumulative one. The cumulative value is a
  /// pure function of this plus the corrections that sort at or before it, and
  /// SPEC.md §2 forbids persisting a derived value: a stored cumulative
  /// survives an import and is then wrong forever.
  IntColumn get odometerM => integer()
      .named('odometer_m')
      .customConstraint('NOT NULL CHECK (odometer_m >= 0)')();

  /// The unit it was entered in. Display fidelity only.
  TextColumn get odometerUnit => text()
      .named('odometer_unit')
      .customConstraint("NOT NULL CHECK (odometer_unit IN ('km', 'mi'))")();

  /// Which record produced it.
  TextColumn get source => text().customConstraint(
    "NOT NULL CHECK (source IN ('manual', 'fillup', 'service', 'expense', "
    "'trip_start', 'trip_end', 'import'))",
  )();

  /// The row that produced it, if any.
  ///
  /// Not a foreign key: it points into one of five different tables depending
  /// on [source], and SQLite has no polymorphic reference. The fan-out in task
  /// 5.9 is what keeps it consistent, and a derived reading is deleted with
  /// its parent by that code rather than by a constraint.
  TextColumn get sourceId => text().named('source_id').nullable()();

  /// Free text. Carried by an import and by derived readings; the odometer log
  /// itself offers no notes field.
  TextColumn get notes => text().nullable()();
}
