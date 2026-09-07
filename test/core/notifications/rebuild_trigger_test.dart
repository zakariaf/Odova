// Everything the phone and the user can do to the queue, and what survives it.
//
// SPEC.md §6.2. A full rebuild is cheap — cancel everything, recompute,
// reschedule — and the spec's own advice is "when in doubt, rebuild". So the
// interesting decisions here are the ones that say NO, because each of them is
// a case where rebuilding would be wrong rather than merely wasteful.
//
// The one that matters most is the absence at the bottom: **delivery is itself
// a rebuild trigger.** Without it a user who does not open Odova for eight
// months — precisely the user reminders exist for — exhausts the 120-day queue
// and then receives nothing, forever, with no signal that anything is wrong.
import 'package:odova/core/notifications/rebuild_trigger.dart';
import 'package:test/test.dart';

void main() {
  group('what forces a full rebuild', () {
    test('a version change, because bodies and payloads may have moved', () {
      expect(
        needsRebuildForVersion(lastBuilt: '1.2.0', current: '1.3.0'),
        isTrue,
      );
      expect(
        needsRebuildForVersion(lastBuilt: '1.3.0', current: '1.3.0'),
        isFalse,
      );
    });

    test('a first launch, where nothing was ever built', () {
      expect(needsRebuildForVersion(lastBuilt: null, current: '1.3.0'), isTrue);
    });

    test('a timezone change', () {
      expect(
        needsRebuildForZone(lastZone: 'Europe/Berlin', current: 'Asia/Tehran'),
        isTrue,
      );
    });

    test('NOT a DST transition', () {
      // §6.2: "No action — wall-clock storage handles it." The zone name does
      // not change across a DST boundary, only the offset, and the whole point
      // of storing a wall clock is that the offset is resolved at schedule
      // time. Rebuilding here would cancel and re-add the entire queue twice a
      // year for no change at all.
      expect(
        needsRebuildForZone(
          lastZone: 'Europe/Berlin',
          current: 'Europe/Berlin',
        ),
        isFalse,
      );
    });

    test('a locale change, because bodies are frozen into the OS', () {
      // Without this the user switches to Arabic and keeps receiving German
      // notifications for four months.
      expect(needsRebuildForLocale(lastLocale: 'de', current: 'ar'), isTrue);
      expect(needsRebuildForLocale(lastLocale: 'ar', current: 'ar'), isFalse);
    });

    test('the enum lists exactly the events that force one', () {
      // Asserted as a SET. A DST transition is deliberately NOT a member — the
      // rule §6.2 states as "no action" — so adding one here fails rather than
      // silently rebuilding the queue twice a year.
      expect(RebuildTrigger.values.map((t) => t.name).toSet(), {
        'bootCompleted',
        'versionChanged',
        'timeZoneChanged',
        'localeChanged',
        'dataImported',
        'permissionGranted',
        'vehicleArchivedOrDeleted',
      });
    });
  });

  group('a clock moved backwards', () {
    test('is detected past an hour and suppresses the next hour', () {
      // §6.2's last row. A user who sets their clock back finds every
      // notification the app thought was in the future is now due, and firing
      // that batch is the worst possible answer.
      final suspicion = clockMovedBackwards(
        lastSeenUtcMs: 1000 * 60 * 60 * 10,
        nowUtcMs: 1000 * 60 * 60 * 10 - 1000 * 60 * 61,
      );

      expect(suspicion.moved, isTrue);
      expect(suspicion.suppressWithinMs, 1000 * 60 * 60);
    });

    test('tolerates a small backwards step', () {
      // NTP corrects a drifting phone clock by seconds all the time, and a
      // rebuild on every one of those would be a rebuild several times a day.
      expect(
        clockMovedBackwards(
          lastSeenUtcMs: 1000 * 60 * 60 * 10,
          nowUtcMs: 1000 * 60 * 60 * 10 - 1000 * 60 * 59,
        ).moved,
        isFalse,
      );
    });

    test('a clock moving FORWARD is not suspicious', () {
      // Time passing is the normal case, and treating it as suspicious would
      // rebuild on every launch.
      expect(
        clockMovedBackwards(
          lastSeenUtcMs: 1000,
          nowUtcMs: 1000 * 60 * 60 * 24 * 400,
        ).moved,
        isFalse,
      );
    });
  });

  group('the keeper', () {
    test('is scheduled at horizon minus 7 days', () {
      expect(keeperOffsetDays, 113);
    });

    // `keeperCarriesReminderId` and `keeperCountsAgainstCap` were `const bool`s
    // asserted against their own literals — spec sentences dressed as
    // declarations, which no code could branch on and no test could fail.
    // The cap claim is a statement about `ReminderScheduler`, and it is
    // asserted there, over a keeper candidate competing for a real slot.
  });

  group('the away digest', () {
    test('is shown when the app has been away longer than the horizon', () {
      expect(needsAwayDigest(daysAway: 121), isTrue);
      expect(needsAwayDigest(daysAway: 120), isFalse);
    });

    test('is shown regardless of permission state', () {
      // §6.2's last paragraph, and §6.4's rule that no feature may depend on
      // delivery. A user who denied notifications and did not open the app for
      // five months still has to be told what went due.
      expect(needsAwayDigest(daysAway: 200), isTrue);
    });
  });

  group('the OEM battery-optimisation card', () {
    test('appears after three deliveries unconfirmed past 48 hours', () {
      expect(
        shouldFlagBackgroundRestriction(
          unconfirmedDeliveries: 3,
          appForegroundedSince: true,
          alreadyAsked: false,
        ),
        isTrue,
      );
    });

    test('does not appear at two', () {
      expect(
        shouldFlagBackgroundRestriction(
          unconfirmedDeliveries: 2,
          appForegroundedSince: true,
          alreadyAsked: false,
        ),
        isFalse,
      );
    });

    test('does not appear if the app was never foregrounded since', () {
      // Otherwise it fires for a phone that was simply switched off, which is
      // not a battery-optimisation problem and has no fix in settings.
      expect(
        shouldFlagBackgroundRestriction(
          unconfirmedDeliveries: 5,
          appForegroundedSince: false,
          alreadyAsked: false,
        ),
        isFalse,
      );
    });

    test('is asked once, ever', () {
      // §6.4: "Record the outcome so it is asked once." A card that returns
      // every week about a setting the user declined to change is the thing
      // that gets an app uninstalled.
      expect(
        shouldFlagBackgroundRestriction(
          unconfirmedDeliveries: 9,
          appForegroundedSince: true,
          alreadyAsked: true,
        ),
        isFalse,
      );
    });
  });
}
