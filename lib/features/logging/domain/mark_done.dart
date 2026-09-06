// Where a reminder's next cycle starts, once work has been recorded.
//
// SPEC.md §10 *Marking a reminder done → a service record*: "There is no 'just
// mark it done' state anywhere — a reminder resets because work was recorded,
// never because a switch was flipped. That rule is what makes `report.service`
// worth money at resale."
//
// The rule this file exists to enforce is that the next cycle is anchored on
// **the odometer the user actually entered**, not the one the item was due at.
// An item due at 186,000 km serviced at 187,412 with a 10,000 km interval is
// next due at 197,412 — anchoring on the due value would quietly steal 1,412 km
// of interval from anyone who serviced their car late, every cycle, for ever.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';

/// The next-due pair §10's confirmation panel shows.
///
/// Either half may be null: "a distance-only or time-only item names one axis",
/// and a date invented for an item with no month interval would be a fact the
/// app made up.
@immutable
class NextDue {
  /// Creates the pair.
  const NextDue({this.odometer, this.date});

  /// Where the next one falls on the distance axis.
  final Distance? odometer;

  /// When it falls on the time axis.
  final CivilDate? date;
}

/// Where [item]'s next cycle starts, given the [record] that just closed one.
///
/// [previousDueOn] is the date the item was due BEFORE this record, and is used
/// only by `from_due`: §3 keeps an annual inspection on its anniversary however
/// late the visit was, because the deadline is the fact and the visit is not.
@useResult
NextDue nextDueAfterMarkDone({
  required ServiceItem item,
  required ServiceRecord record,
  String? previousDueOn,
}) {
  final interval = item.intervalDistance;
  final months = item.intervalMonths;

  return NextDue(
    // ALWAYS from the record's own odometer. There is no `from_due` for the
    // distance axis — §3's rollover is about the calendar, and a distance
    // interval measured from a due value the car never actually reached would
    // be measuring from a place it has not been.
    odometer: interval == null || record.odometer == null
        ? null
        : record.odometer! + interval,
    date: months == null
        ? null
        : _plusMonths(_anchorDate(item, record, previousDueOn), months),
  );
}

/// The date the time axis counts from.
///
/// `from_actual` counts from the visit; `from_due` counts from the deadline the
/// visit was answering, so a late inspection does not walk its anniversary
/// forward a little every year.
CivilDate _anchorDate(
  ServiceItem item,
  ServiceRecord record,
  String? previousDueOn,
) {
  if (item.rollover == ServiceRollover.fromDue) {
    final due = CivilDate.tryParse(previousDueOn ?? '');
    if (due != null) return due;
  }
  return CivilDate.tryParse(record.occurredOn) ?? CivilDate.epoch;
}

/// [from] plus [months], clamped to the end of a shorter month.
///
/// 31 January plus one month is 28 February, not 3 March: a service interval
/// that skidded past the end of a month would drift a day or two every year.
CivilDate _plusMonths(CivilDate from, int months) {
  final total = from.month - 1 + months;
  final year = from.year + total ~/ 12;
  final month = total % 12 + 1;
  final day = from.day.clamp(1, CivilDate.daysInMonth(year, month));
  return CivilDate.tryParse(
        '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}',
      ) ??
      from;
}
