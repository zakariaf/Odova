// What the shared date control offers, and what it defaults to.
//
// SPEC.md §10's Field kit: "Date — none; a read-only row opening the calendar
// picker. Correct first day of week per locale; future dates disabled where the
// entity forbids them."
//
// EPIC-09 deferred this seam here on purpose — "EPIC-11 and EPIC-13 need the
// same picker, and the seam should be designed against three callers rather
// than extrapolated from one." It has five now: the three log forms that
// forbid a future date, `log.expense`, which allows one, and `trips.edit`.
//
// It lives in `core/time/` and not in the logging feature because that fifth
// caller is in another feature, and `structure_test.dart` refuses one feature
// importing another — correctly. Two features share code by lifting it down,
// which is what this is: the file was already pure Dart with no picker and no
// `BuildContext`, so the move is a path change and nothing else.
//
// Pure Dart, no picker and no `BuildContext`. The RULES are what the four forms
// must agree about; which widget renders a month is not.
import 'package:meta/meta.dart';
import 'package:odova/core/time/civil_date.dart';

/// How far back any date field will offer.
///
/// Thirty years, because a second-hand car's service book goes back that far
/// and SPEC.md §14 insists a used-car buyer typing out of one must work. A
/// picker whose floor was this decade would refuse the entry that makes the
/// history worth having.
const int kDateFieldPastYears = 30;

/// How far forward a field that allows the future will offer.
///
/// One year: `log.expense` is the only form that allows a future date at all,
/// and prepaid insurance is the case it exists for.
const int kDateFieldFutureYears = 1;

/// The first and last dates a field will offer.
@immutable
class DateFieldRange {
  /// Creates a range.
  const DateFieldRange({required this.first, required this.last});

  /// The earliest offer.
  final CivilDate first;

  /// The latest.
  final CivilDate last;
}

/// What a field dated against [today] will offer.
///
/// [allowFuture] is false on fill-up, service and odometer, where §10 gives
/// "Pick today or a day in the past." The picker STOPS there rather than
/// offering tomorrow and refusing it at Save — a rule the user meets as a
/// disabled day is a rule they never have to discover.
@useResult
DateFieldRange dateFieldRange({
  required CivilDate today,
  required bool allowFuture,
}) => DateFieldRange(
  first: today.addMonths(-kDateFieldPastYears * 12),
  last: allowFuture ? today.addMonths(kDateFieldFutureYears * 12) : today,
);

/// The date a field opens on.
///
/// §10 *Dates and a suspect clock*: "In clock-suspect mode every date field
/// defaults to the newest `occurred_on` in the database rather than today." A
/// phone whose clock reads 2050 would otherwise stamp every entry with it, and
/// the whole history would be wrong in a way no single row looks wrong in.
///
/// A suspect clock with nothing to fall back to still yields a date: a fresh
/// install that refused to open its own form would be worse than one dated
/// oddly, and §10 blocks the SAVE in that state rather than the field.
@useResult
CivilDate dateFieldDefault({
  required CivilDate today,
  required String? newestOccurredOn,
  required bool clockIsSuspect,
}) {
  if (!clockIsSuspect) return today;
  return CivilDate.tryParse(newestOccurredOn ?? '') ?? today;
}

/// How far [chosen] is past everything, or null when it is not.
///
/// §10: "a date more than a day after both the newest `occurred_on` and today
/// warns without blocking". BOTH, because a database full of backdated rows
/// would otherwise make every ordinary entry look alarming.
///
/// It warns and never blocks: a user really can log a service booked for next
/// year, and refusing it would be the app disbelieving them.
@useResult
int? dateFieldFarFutureDays({
  required CivilDate chosen,
  required CivilDate today,
  required String? newestOccurredOn,
}) {
  final newest = CivilDate.tryParse(newestOccurredOn ?? '');
  final floor = newest != null && newest > today ? newest : today;
  final days = floor.daysUntil(chosen);
  return days > 1 ? days : null;
}
