// A trip.
//
// SPEC.md §3 Entities (`Trip`). Trips are NEVER the source of truth for total
// distance — people log some trips, not all — and the odometer is. Trip
// distance exists only to attribute cost.
import 'package:drift/drift.dart';
import 'package:odova/data/db/tables/audit_columns.dart';

/// A trip.
@DataClassName('TripRow')
class Trips extends Table with AuditColumns {
  /// The vehicle.
  TextColumn get vehicleId => text()
      .named('vehicle_id')
      .customConstraint(
        'NOT NULL REFERENCES vehicles (id) ON DELETE CASCADE',
      )();

  /// What to call it.
  TextColumn get title => text().nullable()();

  /// Why it was taken. Drives the business/personal cost split.
  TextColumn get purpose => text().customConstraint(
    "NOT NULL CHECK (purpose IN ('business', 'commute', 'personal', "
    "'other'))",
  )();

  /// The day it began.
  TextColumn get startedOn => text()
      .named('started_on')
      .customConstraint(
        'NOT NULL CHECK (started_on GLOB '
        "'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
      )();

  /// The day it ended, or null for an open trip.
  TextColumn get endedOn => text().named('ended_on').nullable()();

  /// The odometer at the start, in metres.
  IntColumn get startOdometerM =>
      integer().named('start_odometer_m').nullable()();

  /// The odometer at the end, in metres.
  IntColumn get endOdometerM => integer().named('end_odometer_m').nullable()();

  /// A distance typed by hand, used ONLY when both odometer endpoints are
  /// absent.
  IntColumn get manualDistanceM => integer()
      .named('manual_distance_m')
      .customConstraint(
        'CHECK (manual_distance_m IS NULL OR manual_distance_m >= 0)',
      )
      .nullable()();

  /// The unit the readings were entered in.
  TextColumn get odometerUnit => text()
      .named('odometer_unit')
      .customConstraint("NOT NULL CHECK (odometer_unit IN ('km', 'mi'))")();

  /// Free text.
  TextColumn get notes => text().nullable()();

  /// A trip cannot end before it started.
  static const _endsAfterItStarts =
      'CHECK (ended_on IS NULL OR ended_on >= started_on)';

  /// Nor can its odometer go backwards. Both endpoints are on the same
  /// cluster and the same scale, so this is arithmetic and not a correction —
  /// a genuine cluster change mid-trip is an `OdometerCorrection`.
  static const _odometerRunsForwards =
      'CHECK (start_odometer_m IS NULL OR end_odometer_m IS NULL '
      'OR end_odometer_m >= start_odometer_m)';

  @override
  List<String> get customConstraints => [
    _endsAfterItStarts,
    _odometerRunsForwards,
  ];
}
