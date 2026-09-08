// The channel carries a verb and no payload.
//
// SPEC.md §2's no-network rule is a claim about what the code CAN do, not about
// what it does. `url_launcher` would have opened these pages and was refused
// for the same reason `share_plus` was: a channel that takes a URL is a channel
// that can open one. These assertions are what keeps that true — they pin the
// argument list as EMPTY, so a later change that adds a destination string
// fails here rather than quietly widening the app's reach.
@TestOn('vm')
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/notifications/notification_settings_link.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];

  void mock(Object? Function(MethodCall call) answer) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kNotificationSettingsChannel, (call) async {
          calls.add(call);
          return answer(call);
        });
  }

  setUp(calls.clear);
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kNotificationSettingsChannel, null);
  });

  test('each door is its own verb, and neither carries an argument', () async {
    mock((_) => true);
    const link = PlatformNotificationSettingsLink();

    expect(await link.openNotificationSettings(), isTrue);
    expect(await link.openAppDetailsSettings(), isTrue);

    expect(calls.map((c) => c.method), [
      'openNotificationSettings',
      'openAppDetailsSettings',
    ]);
    // THE assertion. A destination argument is the one change that would turn
    // this into something that can open a URL, and it would otherwise arrive
    // with every existing test still green.
    expect(
      calls.map((c) => c.arguments),
      everyElement(isNull),
      reason: 'the channel grew a payload it could be pointed with',
    );
  });

  test('the three-state status maps from the native name', () async {
    // The states §13's screen is built on. `notDetermined` is the one the
    // plugin cannot report on iOS — its `checkPermissions` gives an options
    // object with every flag false for BOTH never-asked and refused — and
    // collapsing it into `denied` is what stopped the app ever asking.
    const link = PlatformNotificationSettingsLink();
    for (final (name, expected) in [
      ('notDetermined', NotificationAuthorization.notDetermined),
      ('denied', NotificationAuthorization.denied),
      ('authorized', NotificationAuthorization.authorized),
    ]) {
      mock((_) => name);
      expect(await link.authorization(), expected, reason: name);
    }
  });

  test('a name this build does not know is unknown, not denied', () async {
    // A future iOS status, or a platform answering something else. `unknown`
    // reads as never-asked at the caller: asking is recoverable, and telling
    // someone they are blocked when they are not is not.
    mock((_) => 'provisionalIshSomething');
    const link = PlatformNotificationSettingsLink();

    expect(await link.authorization(), NotificationAuthorization.unknown);
  });

  test('a refusal is a value, not a throw', () async {
    // The screen has a card on it already and needs a sentence under the
    // button, not a red screen. §13 gives it no dialog to put an error in.
    mock((_) => throw PlatformException(code: 'no_such_activity'));
    const link = PlatformNotificationSettingsLink();

    expect(await link.openNotificationSettings(), isFalse);
  });

  test('a platform with no native half answers false', () async {
    // No mock at all: MissingPluginException, which is what a desktop build or
    // a half-wired platform produces. Returning true there would leave the user
    // staring at a screen that never changed, told the door had opened.
    const link = PlatformNotificationSettingsLink();

    expect(await link.openAppDetailsSettings(), isFalse);
  });

  test('a null answer is not a success', () async {
    // `invokeMethod<bool>` returns null when the native side calls
    // `result.success(null)` — which is what the share channel does on every
    // successful call. Treating that as true here would report an opened door
    // on any platform that answered in the older style.
    mock((_) => null);
    const link = PlatformNotificationSettingsLink();

    expect(await link.openNotificationSettings(), isFalse);
  });
}
