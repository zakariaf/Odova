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

/// The date and odometer a cycle is measured from.
///
/// Either half may be null, and they are not null together for the same
/// reason: each walked the ladder on its own.
@immutable
class DueAnchor with ValueEquality {
  /// Creates an anchor.
  const DueAnchor({this.date, this.odometerMetres});

  /// Nothing was found on either axis.
  static const none = DueAnchor();

  /// The date the next cycle is measured from.
  final CivilDate? date;

  /// The odometer the next cycle is measured from, in canonical metres.
  final int? odometerMetres;

  /// Whether neither axis could be anchored.
  ///
  /// The caller turns this into `unknown` — never `overdue`, per §14.
  bool get isEmpty => date == null && odometerMetres == null;

  @override
  List<Object?> get props => [date, odometerMetres];

  @override
  String toString() => 'DueAnchor($date, ${odometerMetres}m)';
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
  final rungs = <(CivilDate?, int?)>[
    if (completing != null)
      (
        _anchorDate(item, completing, vehicle, earliest),
        completing.odometer?.metres,
      ),
    (
      CivilDate.tryParseOrNull(item.baselineDate),
      item.baselineOdometer?.metres,
    ),
    (
      CivilDate.tryParseOrNull(vehicle.purchaseDate),
      vehicle.purchaseOdometer?.metres,
    ),
    if (earliest != null) (earliest.date, earliest.cumulative.metres),
  ];

  return DueAnchor(
    date: rungs
        .map((r) => r.$1)
        .firstWhere((d) => d != null, orElse: () => null),
    odometerMetres: rungs
        .map((r) => r.$2)
        .firstWhere((m) => m != null, orElse: () => null),
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
  var k = 0;
  var candidate = base;
  while (true) {
    final next = base.addMonths(months * (k + 1));
    if (next > done) break;
    candidate = next;
    k++;
  }

  // The base itself is later than the record — the job was done before the
  // first cycle even opened. Nothing has been satisfied, so the record's own
  // date is the anchor.
  return candidate > done ? done : candidate;
}
