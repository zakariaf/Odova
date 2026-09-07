// Exactly one file in the app knows an OS notification centre exists.
//
// SPEC.md §4.6.1, and the reason is testability rather than tidiness. The
// moment a second file imports the plugin, the scheduling decision inside it
// can only be checked on a device — and §4's hardest rules (never more than two
// in a rolling seven days, never two on one day, the 46-slot budget) are the
// kind that a device test cannot check at all, because they are claims about a
// set rather than about one delivery.
//
// A shell gate covers the same ground and runs in the repo CI lane. This one
// exists because it runs in the `flutter` lane over the same tree the tests
// compile, and because a failure here names the file in a test report rather
// than in a build log nobody opens.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/source_tree.dart';

void main() {
  test('flutter_local_notifications is imported in exactly one file', () {
    final importers = [
      for (final file in dartFilesUnder('lib'))
        if (sourceWithoutLineComments(
          file,
        ).contains('package:flutter_local_notifications/'))
          file.path,
    ];

    expect(
      importers,
      ['lib/app/notifications/fln_notification_gateway.dart'],
      reason:
          'the adapter is the whole of HOW; everything else talks to '
          'NotificationGateway',
    );
  });

  test('the timezone packages are confined to the same file', () {
    // Same rule, and it is the one people forget: `tz.local` is global mutable
    // state set once at startup, and a second file calling `setLocalLocation`
    // would move every pending fire time out from under the scheduler.
    for (final package in ['timezone/timezone.dart', 'flutter_timezone/']) {
      final importers = [
        for (final file in dartFilesUnder('lib'))
          if (sourceWithoutLineComments(file).contains('package:$package'))
            file.path,
      ];
      expect(
        importers,
        ['lib/app/notifications/fln_notification_gateway.dart'],
        reason: package,
      );
    }
  });

  test('no feature calls the gateway directly', () {
    // SPEC.md §4.2: every scheduling change goes through one reconcile, so it
    // can be idempotent. A feature that cancels one notification on its own
    // desyncs `scheduled_notifications` from the OS, and §6.1 makes that table
    // the truth for WHY a notification is or is not pending — the one question
    // the OS cannot answer.
    final offenders = <String>[];
    for (final file in dartFilesUnder('lib/features')) {
      final source = sourceWithoutLineComments(file);
      if (source.contains('NotificationGateway') ||
          source.contains('notificationGatewayProvider')) {
        offenders.add(file.path);
      }
    }

    expect(offenders, isEmpty);
  });

  test('the manifest asks for neither exact-alarm permission', () {
    // SPEC.md §4.6.3. The shell gate is the authority and has its own planted
    // arms; this is the same claim where a Dart reader will find it.
    //
    // Comments stripped, because the manifest carries a paragraph explaining
    // why these are absent and it names both of them.
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync().replaceAll(RegExp('<!--.*?-->', dotAll: true), '');

    expect(manifest, isNot(contains('USE_EXACT_ALARM')));
    expect(manifest, isNot(contains('SCHEDULE_EXACT_ALARM')));
    expect(manifest, contains('POST_NOTIFICATIONS'));
    expect(manifest, contains('ScheduledNotificationBootReceiver'));
  });
}
