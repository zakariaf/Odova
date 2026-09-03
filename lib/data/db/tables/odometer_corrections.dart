// A correction: the dash number jumped, and the history has to survive it.
//
// SPEC.md §3 The odometer: continuity and corrections. A cluster swapped for
// one showing 0 at a real 187,412 km gives an offset of +187,412 km; a 999,999
// rollover gives +1,000,000 km. The offset carries FORWARD from the reading it
// names, so every later reading is comparable with every earlier one.
import 'package:drift/drift.dart';
import 'package:odova/data/db/tables/audit_columns.dart';

/// An odometer correction.
@DataClassName('OdometerCorrectionRow')
class OdometerCorrections extends Table with AuditColumns {
  /// The vehicle.
  TextColumn get vehicleId => text()
      .named('vehicle_id')
      .customConstraint(
        'NOT NULL REFERENCES vehicles (id) ON DELETE CASCADE',
      )();

  /// The FIRST reading on the new scale.
  ///
  /// The boundary reading is itself corrected — the offset applies at or after
  /// it, never before — which is what makes the boundary deterministic.
  TextColumn get fromReadingId => text()
      .named('from_reading_id')
      .customConstraint(
        'NOT NULL REFERENCES odometer_readings (id) ON DELETE CASCADE',
      )();

  /// What the old cluster last showed, in metres.
  IntColumn get previousM => integer()
      .named('previous_m')
      .customConstraint('NOT NULL CHECK (previous_m >= 0)')();

  /// What the new cluster shows, in metres.
  IntColumn get newM => integer()
      .named('new_m')
      .customConstraint('NOT NULL CHECK (new_m >= 0)')();

  /// The unit both sides were entered in.
  TextColumn get odometerUnit => text()
      .named('odometer_unit')
      .customConstraint("NOT NULL CHECK (odometer_unit IN ('km', 'mi'))")();

  /// Why.
  ///
  /// **Three reasons, not four.** SPEC.md §3's enum listed `unit_mixup` and
  /// §14 *Edge cases* said "`unit_mixup` is removed as a correction reason".
  /// §14 is the narrower, explicitly-decided statement and it is right:
  /// storage is canonical metres and the odometer unit is a per-record fact,
  /// so a km cluster fitted to a miles car needs no offset — the reading is
  /// entered in the unit the new cluster shows and converted on the way in.
  /// The `CHECK` was not widened to dodge the contradiction; §3 was fixed in
  /// the same PR as this table.
  TextColumn get reason => text().customConstraint(
    "NOT NULL CHECK (reason IN ('cluster_replaced', 'rollover', "
    "'typo_fix'))",
  )();

  /// Free text.
  TextColumn get notes => text().nullable()();
}
