// SPEC.md §3's notice window, as the two rows `settings.notifications` offers.
//
// The options are defined PER UNIT SYSTEM and never converted. 500 km is a
// round number a driver recognises; 311 miles is the same distance and is
// not. §5's rule about units applies to a menu as much as to a figure.
import 'package:odova/core/units/distance.dart';

/// The distance options a kilometre user is offered.
const List<int> kNoticeKilometres = [500, 1000, 2000];

/// The distance options a miles user is offered.
///
/// Round MILES, not converted kilometres. A menu that offered 311, 621 and
/// 1,243 miles would be a menu nobody chose from.
const List<int> kNoticeMiles = [300, 600, 1200];

/// The date options, in days.
const List<int> kNoticeDays = [7, 14, 30];

/// What Automatic means, as a percentage of the item's own interval.
const int kAutomaticNoticePercent = 10;

/// The distance options for [unit], as canonical distances.
///
/// Built from the unit's OWN round numbers, so the value the user picked is
/// the value the row shows back — a converted 500 km would read as 311 mi and
/// then, converted again on a unit switch, as 501 km.
List<Distance> noticeDistanceOptions(DistanceUnit unit) => switch (unit) {
  DistanceUnit.km => [for (final km in kNoticeKilometres) Distance.fromKm(km)],
  DistanceUnit.mi => [
    for (final mi in kNoticeMiles) Distance.fromMiles(mi),
  ],
};
