// Where a reminder's next cycle is measured from.
//
// SPEC.md §3 *Due state per item*, and §14 *Second-hand car with a service
// book*.
//
// Four rungs, first one that can supply a half wins — and the two halves are
// resolved INDEPENDENTLY. That last part is the one worth stating: an
// inspection with a baseline date and no baseline odometer still knows when it
// is due by time, and collapsing the whole item to `unknown` because one half
// was missing is what §14 forbids. A used car whose previous owner wrote dates
// in a book and never wrote the mileage is not a car that missed a service.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/value_equality.dart';

/// Which rung of SPEC.md §3's ladder supplied a half of the anchor.
///
/// Recorded per axis, because the two axes walk the ladder separately and
/// routinely land on different rungs — a vehicle with a purchase DATE and no
/// purchase odometer takes its date from `purchase` and its odometer from
/// `firstReading`.
///
/// It exists for §9. Home "renders any item anchored on the `purchase` or
/// `first_reading` rung as `unknown`, whatever the due engine returns", so a
/// 2019 car entered today does not open on eleven red cards. That is a
/// PRESENTATION rule and this enum is how it stays one: without the
/// provenance, Home would have to walk the ladder a second time and could
/// disagree with the engine about what anchored an item.
enum AnchorRung {
  /// The newest service record whose lines reference this item.
  record,

  /// The item's own `baseline_date` / `baseline_odometer_m`.
  baseline,

  /// The vehicle's purchase facts.
  purchase,

  /// The earliest odometer reading Odova holds.
  firstReading,
}

/// The date and odometer a cycle is measured from.
///
/// Either half may be null, and they are not null together for the same
/// reason: each walked the ladder on its own.
@immutable
class DueAnchor with ValueEquality {
  /// Creates an anchor.
  const DueAnchor({
    this.date,
    this.odometerMetres,
    this.dateRung,
    this.odometerRung,
  });

  /// Nothing was found on either axis.
  static const none = DueAnchor();

  /// The date the next cycle is measured from.
  final CivilDate? date;

  /// The odometer the next cycle is measured from, in canonical metres.
  final int? odometerMetres;

  /// Which rung supplied [date], or null when nothing did.
  final AnchorRung? dateRung;

  /// Which rung supplied [odometerMetres], or null when nothing did.
  final AnchorRung? odometerRung;

  /// Whether neither axis could be anchored.
  ///
  /// The caller turns this into `unknown` — never `overdue`, per §14.
  bool get isEmpty => date == null && odometerMetres == null;

  @override
  List<Object?> get props => [date, odometerMetres, dateRung, odometerRung];

  @override
  String toString() =>
      'DueAnchor($date via $dateRung, ${odometerMetres}m via $odometerRung)';
}

/// The anchor for [item], per SPEC.md §3's ladder.
///
/// The rungs, in order: the newest service record whose lines reference this
/// item, the item's own baseline, the vehicle's purchase facts, the earliest
/// odometer reading. Each axis takes the first rung that carries it.
DueAnchor resolveAnchor(
  ServiceItem item,
  List<ServiceRecord> records,
  Vehicle vehicle,
  ReadingSeries series, {
  Map<ServiceItemId, ServiceRecord>? completingIndex,
}) {
  final completing = completingIndex != null
      ? completingIndex[item.id]
      : _newestCompleting(item, records);
  final earliest = series.points.isEmpty ? null : series.points.first;

  // The rungs as (date, odometer) pairs, most authoritative first. Written
  // once and walked twice, so the two axes cannot drift apart in the order
  // they consult.
  final rungs = <(AnchorRung, CivilDate?, int?)>[
    if (completing != null)
      (
        AnchorRung.record,
        _anchorDate(item, completing, vehicle, earliest),
        completing.odometer?.metres,
      ),
    (
      AnchorRung.baseline,
      CivilDate.tryParseOrNull(item.baselineDate),
      item.baselineOdometer?.metres,
    ),
    (
      AnchorRung.purchase,
      CivilDate.tryParseOrNull(vehicle.purchaseDate),
      vehicle.purchaseOdometer?.metres,
    ),
    if (earliest != null)
      (AnchorRung.firstReading, earliest.date, earliest.cumulative.metres),
  ];

  // One walk per axis, and each keeps the rung it stopped on. The rung is
  // carried out with the value rather than re-derived later, because a second
  // walk is a second opinion — and §9's Home rule turns on which rung won.
  final date = _firstOn(rungs, (r) => r.$2);
  final odometer = _firstOn(rungs, (r) => r.$3);

  return DueAnchor(
    date: date?.$2,
    odometerMetres: odometer?.$2,
    dateRung: date?.$1,
    odometerRung: odometer?.$1,
  );
}

/// The newest completing record for EVERY item, in one pass.
///
/// `resolveAnchor` runs per item, and walking every record and every line for
/// each of a vehicle's sixteen reminders is O(items x records x lines) — a
/// plumber with two vans and eight years of receipts pays for that on every app
/// foreground. `recomputeVehicle` builds this once and hands it in.
///
/// The un-indexed path stays: `resolveAnchor` is a documented pure function its
/// own tests call with three arguments, and an index is an optimisation rather
/// than part of its contract.
Map<ServiceItemId, ServiceRecord> newestCompletingByItem(
  List<ServiceRecord> records,
) {
  final newest = <ServiceItemId, ServiceRecord>{};
  for (final record in records) {
    for (final line in record.lines) {
      final itemId = line.serviceItemId;
      if (itemId == null) continue;
      final current = newest[itemId];
      if (current == null ||
          record.occurredOn.compareTo(current.occurredOn) > 0) {
        newest[itemId] = record;
      }
    }
  }
  return newest;
}

/// The newest record with a line referencing [item].
///
/// A brake job does not reset the inspection clock: the line's
/// `service_item_id` is the only thing that ties a record to an item.
ServiceRecord? _newestCompleting(
  ServiceItem item,
  List<ServiceRecord> records,
) {
  ServiceRecord? newest;
  for (final record in records) {
    final completes = record.lines.any((line) => line.serviceItemId == item.id);
    if (!completes) continue;
    if (newest == null || record.occurredOn.compareTo(newest.occurredOn) > 0) {
      newest = record;
    }
  }
  return newest;
}

/// The date half of rung 1, which is where `from_due` differs from
/// `from_actual`.
///
/// `from_actual` anchors on the record's own date. `from_due` anchors on the
/// date the job WAS due — "registration falls in June whenever you paid".
CivilDate? _anchorDate(
  ServiceItem item,
  ServiceRecord completing,
  Vehicle vehicle,
  OdometerPoint? earliest,
) {
  final done = CivilDate.tryParse(completing.occurredOn);
  if (item.rollover != ServiceRollover.fromDue) return done;

  final months = item.intervalMonths;
  final base =
      CivilDate.tryParseOrNull(item.baselineDate) ??
      CivilDate.tryParseOrNull(vehicle.purchaseDate) ??
      earliest?.date;

  // No cycle to walk. An item marked `from_due` with no interval or no base
  // has no "date it was due", and the record's own date is the only honest
  // answer available.
  if (months == null || months <= 0 || base == null || done == null) {
    return done;
  }

  // **The LARGEST k >= 0 whose cycle date is ON OR BEFORE the completing
  // record — the cycle that record satisfied.**
  //
  // SPEC.md §3 said "the smallest k >= 1 whose result is AFTER the record's
  // occurred_on", which anchors on the NEXT cycle and therefore puts the due
  // date a full period later. Baseline 2024-06-01, 12 months, done 2026-07-14
  // — six weeks late — gives anchor 2027-06-01 and due 2028-06-01 under that
  // reading, on the class of item whose whole purpose is a legal deadline.
  // The paragraph is corrected in the same commit as this file.
  //
  // Walked rather than divided, because `addMonths` clamps to the last day of
  // the target month: a base on the 31st does not advance by a fixed number of
  // days and `(done - base) / interval` would drift.
  // BOUNDED. The loop steps one interval at a time from the base to the
  // record, so a corrupt `baseline_date` of `0001-01-01` with a one-month
  // interval is ~24,000 iterations — each doing two calendar conversions — per
  // item, per recompute, sixteen items per vehicle on every app foreground.
  //
  // The bound is not a tolerance: a base more than a thousand cycles before the
  // record is not a baseline anybody typed, and anchoring on the record's own
  // date is the same answer the pre-first-cycle guard below already gives for
  // an unusable base.
  const maxCycles = 1000;
  var k = 0;
  var candidate = base;
  while (k < maxCycles) {
    final next = base.addMonths(months * (k + 1));
    if (next > done) break;
    candidate = next;
    k++;
  }
  if (k >= maxCycles) return done;

  // The base itself is later than the record — the job was done before the
  // first cycle even opened. Nothing has been satisfied, so the record's own
  // date is the anchor.
  return candidate > done ? done : candidate;
}

/// The first rung whose [axis] carries a value, with the rung it came from.
(AnchorRung, T)? _firstOn<T>(
  List<(AnchorRung, CivilDate?, int?)> rungs,
  T? Function((AnchorRung, CivilDate?, int?)) axis,
) {
  for (final rung in rungs) {
    final value = axis(rung);
    if (value != null) return (rung.$1, value);
  }
  return null;
}
