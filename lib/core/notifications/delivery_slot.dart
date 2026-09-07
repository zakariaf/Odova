// The day a notification wants, turned into the moment it actually goes out.
//
// SPEC.md §4.5. Everything here is about not being the app somebody turns off.
//
// **One delivery time for the whole app**, 09:00 by default: the user is
// awake, not yet driving, and booking a garage is a daytime act. Per-reminder
// times would be a settings screen nobody wants.
//
// **A slot is a wall clock, not an instant.** §4.5 again: it is stored as
// `(local_date, delivery_time)` and resolved in the CURRENT zone at schedule
// time, so a user who flies Berlin -> Tehran still gets 09:00 in Tehran. Every
// type in this file is therefore zone-free on purpose, and adding a `DateTime`
// to any of them reintroduces the bug.
import 'package:meta/meta.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/value_equality.dart';

/// 09:00. See the file comment for why this hour and not another.
const int kDefaultDeliveryMinutes = 9 * 60;

/// 21:00 — the first minute that is too late.
const int kQuietStartMinutes = 21 * 60;

/// 08:00 — the first minute that is no longer too early.
const int kQuietEndMinutes = 8 * 60;

/// The app-level delivery settings the scheduler reads.
///
/// The weekend is a FIELD and not a constant. SPEC.md §5: "the scheduler asks
/// and never hard-codes Sat/Sun." Half of Odova's target markets are
/// Friday-Saturday, and getting this wrong is not a rounding error — it moves
/// an Iranian user's reminder off Saturday, which is a working day there, and
/// leaves Friday alone, which is not.
@immutable
class SchedulePreferences with ValueEquality {
  /// Creates the preferences.
  const SchedulePreferences({
    this.deliveryMinutes = kDefaultDeliveryMinutes,
    this.weekdaysOnly = false,
    this.weekend = const <Weekday>{},
  });

  /// Minutes past local midnight.
  final int deliveryMinutes;

  /// Whether weekend fire dates move to the next working day.
  final bool weekdaysOnly;

  /// Which days those are, from `weekShape(formatsTag).weekend`.
  ///
  /// Empty by default, which is safe rather than lazy: with [weekdaysOnly] off
  /// it is never read, and with it on an empty set moves nothing — the failure
  /// is "the setting did not work", which a user can see, rather than "the
  /// reminder moved to the wrong day", which they cannot.
  final Set<Weekday> weekend;

  // The weekend is SORTED and spread for the same reason a list is spread in
  // `PlannedNotification`: `==` on two distinct Sets is identity, so an
  // unspread set makes two identical preference objects unequal. Sorted
  // because a Set's iteration order is not part of its value, and unsorted
  // spreading would make {sat, sun} and {sun, sat} differ.
  @override
  List<Object?> get props => [
    deliveryMinutes,
    weekdaysOnly,
    ...(weekend.toList()..sort()),
  ];
}

/// A wall-clock delivery moment.
@immutable
class DeliverySlot with ValueEquality implements Comparable<DeliverySlot> {
  /// Creates a slot.
  const DeliverySlot({required this.date, required this.minutes});

  /// `YYYY-MM-DD`.
  final String date;

  /// Minutes past local midnight.
  final int minutes;

  /// `YYYY-MM-DDTHH:MM`, the form `ScheduledNotification.fireAtLocal` takes.
  String get wallClock {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '${date}T$h:$m';
  }

  @override
  int compareTo(DeliverySlot other) {
    final byDate = date.compareTo(other.date);
    return byDate != 0 ? byDate : minutes.compareTo(other.minutes);
  }

  @override
  List<Object?> get props => [date, minutes];

  @override
  String toString() => 'DeliverySlot($wallClock)';
}

/// Where a notification wanting [date] actually goes out.
///
/// The two shifts apply IN THIS ORDER and the order is load-bearing: the
/// quiet-hours move changes which day it is, so "is that day a weekend" cannot
/// be asked until after it. A Sunday 21:30 in Germany moves to Monday and then
/// stays there; doing the weekday shift first would move Sunday to Monday and
/// then quiet hours would push it to Tuesday, a day later than the user asked
/// for and for no reason they could work out.
DeliverySlot resolveSlot({
  required CivilDate date,
  required SchedulePreferences prefs,
}) {
  var day = date;
  var minutes = prefs.deliveryMinutes;

  // Quiet hours WRAP midnight, which is where this arithmetic is usually
  // wrong: `21*60 <= m && m < 8*60` is false for every minute, so 03:00 sails
  // through and the phone buzzes at three in the morning.
  if (minutes >= kQuietStartMinutes || minutes < kQuietEndMinutes) {
    // Late evening belongs to tomorrow; the small hours are already tomorrow.
    // Either way the delivery goes to a DAY's slot at the default hour and
    // never to the end of the quiet window — §4.5 forbids releasing a batch at
    // 08:00, which is what clamping would do.
    if (minutes >= kQuietStartMinutes) day = day.addDays(1);
    minutes = kDefaultDeliveryMinutes;
  }

  if (prefs.weekdaysOnly && prefs.weekend.isNotEmpty) {
    // Bounded by seven: a weekend cannot be every day, and a set that somehow
    // was would otherwise loop forever inside a pure function on the cold-start
    // path.
    var guard = 0;
    while (prefs.weekend.contains(day.weekday) && guard < 7) {
      day = day.addDays(1);
      guard++;
    }
  }

  return DeliverySlot(date: day.toString(), minutes: minutes);
}
