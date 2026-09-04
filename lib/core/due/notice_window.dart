// How much warning an item gets before it is due, and how much forgiveness
// after.
//
// SPEC.md §3 *Notice window*, and *The due engine*'s `grace_m` / `grace_days`.
//
// **NOTICE and GRACE are computed by the same formula and are not the same
// setting.** Notice is the warning before the due point; grace is the tolerance
// after it, before an item reads `overdue`. A user who asks for 2,000 km of
// warning has asked to be told EARLIER — reading that as 2,000 km of
// forgiveness moves the moment their car goes red outward by a kilometre for
// every kilometre of extra warning, which is the opposite of what they asked
// for and entirely silent.
//
// So the override applies to notice only, and grace always uses the computed
// default.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/rounding/rounding.dart';
import 'package:odova/core/value_equality.dart';

/// 200 km. Below this a short interval gives no usable heads-up.
const kNoticeDistanceFloorMetres = 200000;

/// 1,000 km. Above this the warning arrives so early it is noise.
const kNoticeDistanceCeilingMetres = 1000000;

/// A week.
const kNoticeDaysFloor = 7;

/// A month.
const kNoticeDaysCeiling = 30;

/// Days in an average month, for turning an interval in months into days.
///
/// The Gregorian mean, 365.2425 / 12. Used ONLY to size a warning window —
/// never to advance a date, which is `CivilDate.addMonths`'s job and clamps
/// to the last day of the month.
const kDaysPerMonth = 30.44;

/// A tenth of the interval, per SPEC.md §3.
const kNoticeFraction = 0.10;

// A note on the rounding below, so nobody mistakes it for load-bearing.
//
// SPEC.md §3 states half-away-from-zero, and `roundHalfAwayFromZero` is used —
// but no realistic input distinguishes it from truncation, on either axis.
//
// DISTANCE: an interval is a whole number of kilometres, so its metre count is
// a multiple of 1,000 and `x 0.10` is exactly representable. Swept every
// interval from 100 km to 200,000 km in 100 km steps: zero disagreements.
//
// TIME: `months x 30.44 x 0.10` genuinely is inexact, and truncation differs
// for 12-22, 35-45 and 57-60 months — every one of which is above 30 days and
// clamps to the ceiling anyway. The window only escapes the clamp for 3-9
// months, and none of those disagree.
//
// It stays because it is what the spec says and because the clamp bounds are a
// product decision that may move. If the ceiling ever rises above 67 days, the
// twelve-month case starts caring.

/// The warning and forgiveness windows for one item, on both axes.
@immutable
class NoticeWindow with ValueEquality {
  /// Creates a window.
  const NoticeWindow({
    required this.noticeDistanceMetres,
    required this.noticeDays,
    required this.graceDistanceMetres,
    required this.graceDays,
  });

  /// How far before the due odometer the item starts reading `due_soon`.
  final int noticeDistanceMetres;

  /// How many days before the due date the item starts reading `due_soon`.
  final int noticeDays;

  /// How far past the due odometer the item stays `due` before `overdue`.
  ///
  /// The COMPUTED default, never the override — see the file header.
  final int graceDistanceMetres;

  /// How many days past the due date the item stays `due` before `overdue`.
  final int graceDays;

  @override
  List<Object?> get props => [
    noticeDistanceMetres,
    noticeDays,
    graceDistanceMetres,
    graceDays,
  ];

  @override
  String toString() =>
      'NoticeWindow(notice ${noticeDistanceMetres}m/${noticeDays}d, '
      'grace ${graceDistanceMetres}m/${graceDays}d)';
}

/// The windows for [item], resolving overrides item → vehicle → settings.
NoticeWindow noticeWindow({
  required ServiceItem item,
  required Vehicle vehicle,
  required AppSettings settings,
}) {
  final computedDistance = _computedDistance(item);
  final computedDays = _computedDays(item);

  return NoticeWindow(
    // An explicit override is used AS WRITTEN and is not clamped: §3 says the
    // clamp defines the computed default only, which is why
    // `settings.notifications` may offer 2,000 km.
    noticeDistanceMetres:
        item.noticeDistance?.metres ??
        vehicle.noticeDistance?.metres ??
        settings.noticeDistance?.metres ??
        computedDistance,
    noticeDays:
        item.noticeDays ??
        vehicle.noticeDays ??
        settings.noticeDays ??
        computedDays,
    graceDistanceMetres: computedDistance,
    graceDays: computedDays,
  );
}

/// A tenth of the distance interval, clamped — or the ceiling for a one-off.
int _computedDistance(ServiceItem item) {
  final interval = item.intervalDistance?.metres;
  // A one-off `target_odometer_m` has no interval to take a percentage of, so
  // §3 gives it the ceiling: the most warning the app ever offers.
  if (interval == null || interval <= 0) return kNoticeDistanceCeilingMetres;

  final tenth = roundHalfAwayFromZero(interval * kNoticeFraction).toInt();
  return tenth < kNoticeDistanceFloorMetres
      ? kNoticeDistanceFloorMetres
      : tenth > kNoticeDistanceCeilingMetres
      ? kNoticeDistanceCeilingMetres
      : tenth;
}

/// A tenth of the month interval in days, clamped — or the ceiling.
int _computedDays(ServiceItem item) {
  final months = item.intervalMonths;
  if (months == null || months <= 0) return kNoticeDaysCeiling;

  // Half away from zero, per SPEC.md §3's rounding rule: 18.264 is 18 and
  // 36.528 is 37 before the clamp takes it to 30.
  final tenth = roundHalfAwayFromZero(
    months * kDaysPerMonth * kNoticeFraction,
  ).toInt();
  return tenth < kNoticeDaysFloor
      ? kNoticeDaysFloor
      : tenth > kNoticeDaysCeiling
      ? kNoticeDaysCeiling
      : tenth;
}
