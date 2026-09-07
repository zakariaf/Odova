// Every port this app declares is satisfied in PRODUCTION, not only in tests.
//
// The defect this exists for: `scheduleRebuilderProvider` threw
// `UnimplementedError` until overridden, `bootstrap()` never overrode it, and
// every text-affecting settings write committed to the database and then threw
// out of an `unawaited()` tap handler. All 4,300 tests passed, because every
// test supplied its own fake.
//
// A port is only safe to declare as throwing when something in production
// actually satisfies it. This asserts that for the ones a real user's tap can
// reach.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/notifications/schedule_rebuilder.dart';

void main() {
  test('a bare container can reschedule notifications', () {
    // No overrides at all — the state a real app is in before EPIC-16 lands.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(scheduleRebuilderProvider),
      returnsNormally,
      reason: 'a settings write must not throw in an app with no scheduler',
    );
  });

  test('the default rebuilder is honest about doing nothing', () async {
    // Not a stub hiding a gap: EPIC-16 owns the scheduler, so until it lands
    // there is genuinely nothing scheduled to cancel or re-bake.
    await expectLater(
      const NoScheduledNotifications().rebuildAll(),
      completes,
    );
  });
}
