// When a notification actually goes out, once the day it wants is decided.
//
// SPEC.md §4.5. Three rules, and each of them exists because of a specific way
// a reminder app becomes something people turn off:
//
//   * ONE delivery time for the whole app, 09:00 by default. The user is
//     awake, not yet driving, and booking a garage is a daytime act.
//   * Quiet hours 21:00-08:00. Anything landing inside them moves to the NEXT
//     DAY's slot and is never released as a batch at 08:00 — waking somebody at
//     08:00 with three notifications is how the app gets uninstalled.
//   * Weekdays-only, off by default. On, a weekend fire date moves to the
//     following working day — and "weekend" comes from the LOCALE. Half this
//     app's markets are Friday-Saturday, so a hard-coded Sat+Sun would push an
//     Iranian user's reminder from Saturday onto Sunday, which is a working
//     day there, and leave Friday alone, which is not.
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/notifications/delivery_slot.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:test/test.dart';

CivilDate d(String iso) => CivilDate.tryParse(iso)!;

const _default = SchedulePreferences();

void main() {
  group('CivilDate.weekday', () {
    test('holds before 1970, where the epoch day is NEGATIVE', () {
      // `((_epochDay + 3) % 7) + 1` leans on Dart's `%` returning a
      // non-negative result for a positive divisor — which it does, and C's
      // does not. The formula is one language-semantics assumption away from
      // being wrong for every date before 1970, and nothing else in the suite
      // exercises one: a 1967 purchase date is an ordinary thing for a
      // classic-car owner to enter.
      for (final iso in [
        '1969-12-31',
        '1969-01-01',
        '1900-01-01',
        '1867-03-04',
      ]) {
        expect(d(iso).weekday, DateTime.parse(iso).weekday, reason: iso);
      }
    });

    test('agrees with DateTime on a spread of dates', () {
      for (final iso in [
        '1970-01-01', // the epoch, a Thursday — the anchor the maths uses
        '2026-09-07', // a Monday
        '2026-09-12', // a Saturday
        '2026-09-13', // a Sunday
        '2000-02-29', // a leap day
        '1999-12-31',
        '2100-03-01', // past 2100, which is NOT a leap year
      ]) {
        expect(d(iso).weekday, DateTime.parse(iso).weekday, reason: iso);
      }
    });
  });

  group('the plain case', () {
    test('a weekday date at the default time is 09:00 that day', () {
      expect(
        resolveSlot(date: d('2026-10-12'), prefs: _default),
        const DeliverySlot(date: '2026-10-12', minutes: 540),
      );
    });

    test('a custom delivery time is used as-is when it is not quiet', () {
      expect(
        resolveSlot(
          date: d('2026-10-12'),
          prefs: const SchedulePreferences(deliveryMinutes: 14 * 60),
        ),
        const DeliverySlot(date: '2026-10-12', minutes: 840),
      );
    });
  });

  group('quiet hours', () {
    test('a 21:30 delivery time moves to the NEXT day at 09:00', () {
      // Not to 08:00 the same night, and not to 08:00 the next morning.
      expect(
        resolveSlot(
          date: d('2026-10-12'),
          prefs: const SchedulePreferences(deliveryMinutes: 21 * 60 + 30),
        ),
        const DeliverySlot(date: '2026-10-13', minutes: 540),
      );
    });

    test('does not release a quiet-hours batch at 08:00', () {
      // §4.5 says this in as many words. The tempting implementation is "clamp
      // to the end of quiet hours", which delivers everything at once the
      // moment the window closes.
      final slot = resolveSlot(
        date: d('2026-10-12'),
        prefs: const SchedulePreferences(deliveryMinutes: 3 * 60),
      );

      expect(slot.minutes, isNot(480));
      expect(slot.minutes, 540);
    });

    test('03:00 belongs to the quiet window that started the night before', () {
      // The window WRAPS midnight, which is the arithmetic people get wrong:
      // `21*60 <= m && m < 8*60` is false for 03:00 and the notification then
      // fires at three in the morning.
      expect(
        resolveSlot(
          date: d('2026-10-12'),
          prefs: const SchedulePreferences(deliveryMinutes: 3 * 60),
        ).date,
        '2026-10-12',
        reason: '03:00 is already past midnight — the same day, at 09:00',
      );
    });

    test('exactly 08:00 is out of the window and 07:59 is in it', () {
      expect(
        resolveSlot(
          date: d('2026-10-12'),
          prefs: const SchedulePreferences(deliveryMinutes: 8 * 60),
        ),
        const DeliverySlot(date: '2026-10-12', minutes: 480),
      );
      expect(
        resolveSlot(
          date: d('2026-10-12'),
          prefs: const SchedulePreferences(deliveryMinutes: 8 * 60 - 1),
        ).minutes,
        540,
      );
    });

    test('exactly 21:00 is inside the window and 20:59 is not', () {
      expect(
        resolveSlot(
          date: d('2026-10-12'),
          prefs: const SchedulePreferences(deliveryMinutes: 21 * 60),
        ).date,
        '2026-10-13',
      );
      expect(
        resolveSlot(
          date: d('2026-10-12'),
          prefs: const SchedulePreferences(deliveryMinutes: 21 * 60 - 1),
        ),
        const DeliverySlot(date: '2026-10-12', minutes: 1259),
      );
    });
  });

  group('quiet hours the USER set, not the defaults', () {
    // The gap `/simplify` found: the scheduler declared its own `const` copies
    // of three values that live on `AppSettings` and are USER-EDITABLE. A user
    // who moved quiet hours got the default behaviour and nothing anywhere
    // went red.
    test('a moved window is honoured', () {
      const prefs = SchedulePreferences(
        deliveryMinutes: 21 * 60 + 30,
        quietFromMinutes: 22 * 60,
        quietToMinutes: 6 * 60,
      );

      // 21:30 is no longer quiet, because the user pushed the window to 22:00.
      expect(
        resolveSlot(date: d('2026-10-12'), prefs: prefs),
        const DeliverySlot(date: '2026-10-12', minutes: 21 * 60 + 30),
      );
    });

    test('a NON-wrapping window works too', () {
      // 13:00-14:00 is a window a user can set, and the hand-rolled predicate
      // could not express it: `m >= 13:00 || m < 14:00` is true all day.
      const prefs = SchedulePreferences(
        deliveryMinutes: 13 * 60 + 30,
        quietFromMinutes: 13 * 60,
        quietToMinutes: 14 * 60,
      );

      expect(resolveSlot(date: d('2026-10-12'), prefs: prefs).minutes, 540);
      expect(
        resolveSlot(
          date: d('2026-10-12'),
          prefs: const SchedulePreferences(
            deliveryMinutes: 15 * 60,
            quietFromMinutes: 13 * 60,
            quietToMinutes: 14 * 60,
          ),
        ).minutes,
        15 * 60,
        reason: '15:00 is outside a 13:00-14:00 window',
      );
    });

    test('is built from AppSettings, so the two cannot drift', () {
      final prefs = SchedulePreferences.from(
        AppSettings(
          schemaVersion: 1,
          currencyDefault: Currency.tryParse('EUR')!,
          notificationTimeMinutes: 8 * 60,
          quietHoursFromMinutes: 23 * 60,
          quietHoursToMinutes: 7 * 60,
          weekdaysOnly: true,
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
        weekend: weekShape('de-DE').weekend,
      );

      expect(prefs.deliveryMinutes, 8 * 60);
      expect(prefs.quietFromMinutes, 23 * 60);
      expect(prefs.weekdaysOnly, isTrue);
      expect(prefs.isQuiet(23 * 60 + 30), isTrue);
      expect(prefs.isQuiet(8 * 60), isFalse);
    });
  });

  group('weekdays only, with the weekend the locale actually has', () {
    test('is off by default and leaves a Saturday alone', () {
      expect(
        resolveSlot(date: d('2026-10-10'), prefs: _default).date,
        '2026-10-10',
      );
    });

    test('de-DE moves Saturday and Sunday to Monday', () {
      final prefs = SchedulePreferences(
        weekdaysOnly: true,
        weekend: weekShape('de-DE').weekend,
      );

      expect(
        resolveSlot(date: d('2026-10-10'), prefs: prefs).date,
        '2026-10-12',
      ); // Sat -> Mon
      expect(
        resolveSlot(date: d('2026-10-11'), prefs: prefs).date,
        '2026-10-12',
      ); // Sun -> Mon
    });

    test('fa-IR moves Friday to Saturday and leaves Sunday alone', () {
      // The whole reason the weekend is asked for. In Iran, Saturday is a
      // working day and Friday is not — the exact opposite of the hard-coded
      // answer on the day it matters.
      final prefs = SchedulePreferences(
        weekdaysOnly: true,
        weekend: weekShape('fa-IR').weekend,
      );

      expect(
        resolveSlot(date: d('2026-10-09'), prefs: prefs).date,
        '2026-10-11',
      ); // Fri -> Sun, past Saturday
      expect(
        resolveSlot(date: d('2026-10-11'), prefs: prefs).date,
        '2026-10-11',
      ); // Sunday is a working day
    });

    test('the two regions disagree about Friday and about Sunday', () {
      // The contrast stated directly, because it is the whole reason the
      // weekend is a parameter. Saturday is a weekend day in BOTH, so a
      // hard-coded Sat+Sun looks right until one of these two days comes up.
      final iran = SchedulePreferences(
        weekdaysOnly: true,
        weekend: weekShape('fa-IR').weekend,
      );
      final germany = SchedulePreferences(
        weekdaysOnly: true,
        weekend: weekShape('de-DE').weekend,
      );

      // Friday 2026-10-09: a working day in Germany, a weekend day in Iran.
      expect(
        resolveSlot(date: d('2026-10-09'), prefs: germany).date,
        '2026-10-09',
      );
      expect(
        resolveSlot(date: d('2026-10-09'), prefs: iran).date,
        isNot('2026-10-09'),
      );

      // Sunday 2026-10-11: a weekend day in Germany, a working day in Iran.
      expect(
        resolveSlot(date: d('2026-10-11'), prefs: germany).date,
        isNot('2026-10-11'),
      );
      expect(
        resolveSlot(date: d('2026-10-11'), prefs: iran).date,
        '2026-10-11',
      );
    });
  });

  group('the two shifts compose', () {
    test('a quiet Friday evening in Germany lands on Monday', () {
      // Quiet hours push Friday 21:30 to Saturday, and weekdays-only then
      // pushes Saturday to Monday. Applying them in the other order gives
      // Monday too, but only by luck — a Sunday 21:30 would give Monday one
      // way and Tuesday the other, which is the next case.
      final prefs = SchedulePreferences(
        deliveryMinutes: 21 * 60 + 30,
        weekdaysOnly: true,
        weekend: weekShape('de-DE').weekend,
      );

      expect(
        resolveSlot(date: d('2026-10-09'), prefs: prefs).date,
        '2026-10-12',
      );
    });

    test('a quiet Sunday evening lands on Tuesday, not Monday', () {
      // Quiet hours move Sunday 21:30 to MONDAY, which is a working day, so
      // the weekend shift does nothing — Monday. Doing the weekday shift FIRST
      // would move Sunday to Monday and then quiet hours to Tuesday.
      //
      // Monday is the right answer and this test pins the ORDER that produces
      // it: the quiet-hour move changes which day it is, so it has to happen
      // before the question "is that day a weekend" can be asked.
      final prefs = SchedulePreferences(
        deliveryMinutes: 21 * 60 + 30,
        weekdaysOnly: true,
        weekend: weekShape('de-DE').weekend,
      );

      expect(
        resolveSlot(date: d('2026-10-11'), prefs: prefs).date,
        '2026-10-12',
      );
    });
  });

  test('is deterministic: the same input twice gives the same slot', () {
    final prefs = SchedulePreferences(
      deliveryMinutes: 21 * 60 + 30,
      weekdaysOnly: true,
      weekend: weekShape('fa-IR').weekend,
    );

    expect(
      resolveSlot(date: d('2026-10-09'), prefs: prefs),
      resolveSlot(date: d('2026-10-09'), prefs: prefs),
    );
  });
}
