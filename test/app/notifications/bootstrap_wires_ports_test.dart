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
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/notifications/notification_permission_port.dart';
import 'package:odova/app/notifications/schedule_rebuilder.dart';
import 'package:odova/core/result.dart';
import 'package:odova/features/backup/application/backup_notifier.dart';
import 'package:odova/features/backup/domain/backup_export_service.dart';

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

  test('a bare container can reach every backup action', () async {
    // EPIC-15's screens were built against a no-op port for the same reason,
    // and `bootstrap()` now installs the real one — but the default has to
    // stay reachable, because a widget test pumps `settings.backup` without a
    // database and a throwing default would make the screen untestable rather
    // than merely inert.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final actions = container.read(backupActionsProvider);
    // A typed refusal, not a null and not a throw: the default is honest
    // about being unwired, and the screen renders it as §13's third export
    // error rather than as a spinner that stops.
    await expectLater(
      actions.backUpNow(),
      completion(isA<Err<int, ExportFailure>>()),
    );
    await expectLater(actions.pickFileToRestore(), completes);
    await expectLater(actions.beginDeleteAll(), completes);
  });

  test('bootstrap installs the wired backup actions, not the no-op', () {
    // The assertion that would have caught EPIC-13's and EPIC-14's defects.
    // It reads the SOURCE rather than running `bootstrap()`, which needs a
    // real directory and a real database: what it proves is that the override
    // is present, which is the thing that was missing both times.
    final source = File('lib/app/bootstrap.dart').readAsStringSync();

    expect(source, contains('backupActionsProvider.overrideWith'));
    expect(source, contains('WiredBackupActions'));
    expect(source, contains('backupDirectoryProvider.overrideWithValue'));
  });

  test('the default rebuilder is honest about doing nothing', () async {
    // Not a stub hiding a gap: EPIC-16 owns the scheduler, so until it lands
    // there is genuinely nothing scheduled to cancel or re-bake.
    await expectLater(
      const NoScheduledNotifications().rebuildAll(),
      completes,
    );
  });

  test('the permission port has a working default', () async {
    // It threw `UnimplementedError`, and nothing ever saw it:
    // `notifications_screen.dart` reads `.value ?? granted`, so the throw came
    // back null and the screen assumed the OS had said yes — a page of
    // switches over a permission nobody had asked for. On a device that is no
    // dialog, ever, and no error either.
    //
    // The default is inert rather than absent, for the reason the backup
    // actions give above: a widget test pumps `settings.notifications` with no
    // plugin, and a throwing default makes the screen untestable rather than
    // merely quiet.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final port = container.read(notificationPermissionProvider);
    expect(
      await port.read(),
      NotificationPermission.neverAsked,
      reason: 'an app with no plugin has not asked, and must not claim it has',
    );
    expect(
      await port.request(),
      NotificationPermission.neverAsked,
      reason: 'and it cannot ask, which is not the same as being refused',
    );
  });
}
