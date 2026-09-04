// The reminder definition: the thing that comes due.
//
// SPEC.md §3 Entities (`ServiceItem`), §3 Invariants and validation.
//
// **No `mode` column and no `rule` column.** Which axes apply is DERIVED from
// which interval fields are non-null, and the combination is always
// whichever-comes-first. A stored mode is a second answer to a question the
// data already answers, and the day it disagrees with the intervals the engine
// reads one and the screen shows the other.
//
// **No `lead_*` columns and no `notice_months`.** `notice_distance_m` and
// `notice_days` ARE the per-item lead override. The time notice window clamps
// to 7-30 days, which cannot be expressed in months at all.
import 'package:drift/drift.dart';
import 'package:odova/data/db/tables/audit_columns.dart';

/// A service item.
@DataClassName('ServiceItemRow')
class ServiceItems extends Table with AuditColumns {
  /// The vehicle this belongs to.
  ///
  /// Vehicles never share service items, intervals, fuel history or costs
  /// (SPEC.md §3 Scope), so this is not nullable and the cascade is real.
  /// Written as a `customConstraint` rather than with drift's
  /// `.references()`. `.references()` compiled and emitted no `REFERENCES`
  /// clause at all — the column came out as a bare `TEXT NOT NULL` — so an
  /// item pointing at a vehicle that does not exist was accepted, and the
  /// cascade that Undo depends on did not exist. The test that inserts an
  /// orphan is what found it; nothing in Dart could have.
  TextColumn get vehicleId => text()
      .named('vehicle_id')
      .customConstraint(
        'NOT NULL REFERENCES vehicles (id) ON DELETE CASCADE',
      )();

  /// Which catalogue item, or `custom`.
  TextColumn get kind => text().customConstraint(
    "NOT NULL CHECK (kind IN ('oil_and_filter', 'air_filter', "
    "'cabin_filter', 'fuel_filter', 'spark_plugs', 'timing_belt', "
    "'brake_pads_check', 'brake_pads_front', 'brake_pads_rear', "
    "'brake_fluid', 'coolant', 'transmission_fluid', 'wheel_alignment', "
    "'tyre_rotate', 'tyre_replace', 'battery', 'wipers', 'inspection', "
    "'registration', 'insurance_renewal', 'ac_service', 'chain_lube', "
    "'chain_and_sprockets', 'valve_clearance', 'fork_oil', "
    "'reduction_gearbox_oil', 'battery_12v', 'custom'))",
  )();

  /// What to call it.
  ///
  /// Required when [kind] is `custom`, and an optional override otherwise —
  /// the `CHECK` below is what makes a nameless custom item impossible rather
  /// than merely discouraged.
  TextColumn get label => text().nullable()();

  /// Distance interval in metres. Null means not distance-based.
  IntColumn get intervalDistanceM => integer()
      .named('interval_distance_m')
      .customConstraint(
        'CHECK (interval_distance_m IS NULL OR interval_distance_m > 0)',
      )
      .nullable()();

  /// The unit the interval was ENTERED in, kept for display fidelity.
  ///
  /// SPEC.md §3: provenance units never enter arithmetic. Storage is metres;
  /// this exists so "every 10,000 miles" reads back as miles rather than as
  /// 16,093 km.
  TextColumn get intervalDistanceUnit => text()
      .named('interval_distance_unit')
      .customConstraint("CHECK (interval_distance_unit IN ('km', 'mi'))")
      .nullable()();

  /// Time interval in months. Null means not time-based.
  IntColumn get intervalMonths => integer()
      .named('interval_months')
      .customConstraint(
        'CHECK (interval_months IS NULL OR interval_months > 0)',
      )
      .nullable()();

  /// A one-off target odometer, in metres. "Cambelt at 120,000 km."
  IntColumn get targetOdometerM =>
      integer().named('target_odometer_m').nullable()();

  /// A one-off target date. "Registration renewal."
  TextColumn get targetDate => text().named('target_date').nullable()();

  /// "Last done March 2024", set when the item is created.
  TextColumn get baselineDate => text().named('baseline_date').nullable()();

  /// The odometer at [baselineDate], in metres.
  IntColumn get baselineOdometerM =>
      integer().named('baseline_odometer_m').nullable()();

  /// Per-item distance notice window override, in metres. Null = computed.
  IntColumn get noticeDistanceM =>
      integer().named('notice_distance_m').nullable()();

  /// Per-item time notice window override, in days. Null = computed.
  IntColumn get noticeDays => integer().named('notice_days').nullable()();

  /// False = seeded from the catalogue but never adopted. Invisible to the
  /// engine, so a fresh vehicle does not open on a wall of amber.
  BoolColumn get isTracked =>
      boolean().named('is_tracked').withDefault(const Constant(false))();

  /// False = the user paused it. Never notifies, greys out, keeps its history.
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  /// Whether this item may raise a notification.
  BoolColumn get notify => boolean().withDefault(const Constant(true))();

  /// How it sorts when several are due at once.
  TextColumn get priority => text().customConstraint(
    "NOT NULL CHECK (priority IN ('safety', 'normal', 'low'))",
  )();

  /// What the next due date is measured from when it completes late.
  TextColumn get rollover => text().customConstraint(
    "NOT NULL CHECK (rollover IN ('from_actual', 'from_due'))",
  )();

  /// False = completes once and retires.
  BoolColumn get repeats => boolean().withDefault(const Constant(true))();

  /// Snoozed until this date.
  TextColumn get snoozedUntil => text().named('snoozed_until').nullable()();

  /// Snoozed until this odometer, in metres.
  IntColumn get snoozeUntilOdometerM =>
      integer().named('snooze_until_odometer_m').nullable()();

  /// How many times it has been snoozed. Reset to 0 on completion or on an
  /// interval edit.
  IntColumn get snoozeCount =>
      integer().named('snooze_count').withDefault(const Constant(0))();

  /// Free text.
  TextColumn get notes => text().nullable()();

  /// SPEC.md §3 Invariants: an item with no interval and no target can never
  /// come due. It is not a harmless empty row — it appears in the list, it can
  /// be edited, and it silently never fires.
  ///
  /// A named constant because the analyzer reads two adjacent string literals
  /// inside a list as a missing comma, which is usually right.
  static const _hasSomeSchedule =
      'CHECK (interval_distance_m IS NOT NULL OR interval_months IS NOT NULL '
      'OR target_odometer_m IS NOT NULL OR target_date IS NOT NULL)';

  /// A custom item with no label has nothing to show on a card.
  static const _customNeedsLabel =
      "CHECK (kind <> 'custom' OR label IS NOT NULL)";

  @override
  List<String> get customConstraints => [
    _hasSomeSchedule,
    _customNeedsLabel,
  ];
}
