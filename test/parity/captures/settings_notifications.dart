// `settings.notifications`, in all four combinations.
//
// SPEC.md §13 and §4.6. The reference draws the screen a user with permission
// GRANTED sees — the three category switches and the delivery time, with no
// permission card above them — so the capture supplies the granted answer
// rather than letting the port decide. On a test host the port answers
// `neverAsked`, which draws §4.6's pre-prompt card and pushes every band down
// by the height of it.

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/notifications/permission_preprompt.dart';
import 'package:odova/features/settings/presentation/notifications_screen.dart';

import '../support/parity_capture.dart';
import '../support/settings_backdrop.dart';

/// Captures `settings.notifications` in one combination.
Future<void> captureSettingsNotifications(
  WidgetTester tester,
  ParityCase config,
) async {
  await captureParity(
    tester,
    screen: 'settings.notifications',
    config: config,
    tab: 3,
    child: settingsBackdrop(
      rtl: isRtl(config),
      locale: config.locale,
      extra: [
        notificationPermissionState.overrideWith(
          (ref) => NotificationPermission.granted,
        ),
      ],
      child: const NotificationsSettingsScreen(),
    ),
  );
}
