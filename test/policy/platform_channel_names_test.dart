// The Dart name and the two native names are the same string.
//
// A method channel is a string typed in three files — Dart, Swift, Kotlin —
// with a comment in each saying "must match". A comment is not a gate, and the
// failure mode is silent on both platforms: the invocation goes nowhere,
// `MissingPluginException` is caught, and the app reports the polite `false`
// the port was designed to return. The share channel has carried that exposure
// since EPIC-12 and the settings channel would have joined it.
//
// It is a repo-shaped test rather than a build-shaped one on purpose. CI builds
// `flutter build apk --debug`, so a Swift typo compiles nowhere and is reported
// by nothing — which is exactly how `engineBridge.binaryMessenger` reached main
// and stopped the iOS app building at all.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// One channel, and the three files that must agree about its name.
typedef Channel = ({String dart, String swift, String kotlin, String name});

const _channels = <Channel>[
  (
    name: 'dev.odova/share',
    dart: 'lib/app/share/share_service.dart',
    swift: 'ios/Runner/AppDelegate.swift',
    kotlin: 'android/app/src/main/kotlin/io/applander/odova/MainActivity.kt',
  ),
  (
    name: 'dev.odova/notification_settings',
    dart: 'lib/app/notifications/notification_settings_link.dart',
    swift: 'ios/Runner/AppDelegate.swift',
    kotlin: 'android/app/src/main/kotlin/io/applander/odova/MainActivity.kt',
  ),
];

void main() {
  for (final channel in _channels) {
    test('${channel.name} is spelled the same in all three', () {
      for (final path in [channel.dart, channel.swift, channel.kotlin]) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path is gone');
        // QUOTED, in whichever quote the language uses — Dart writes `'`,
        // Swift and Kotlin write `"`. A bare `contains(name)` would also match
        // the name inside a "must match" comment, which is the one place it is
        // guaranteed to be right and the one place it does nothing.
        expect(
          file.readAsStringSync(),
          anyOf(
            contains("'${channel.name}'"),
            contains('"${channel.name}"'),
          ),
          reason:
              '$path does not name ${channel.name} — the call goes nowhere '
              'and the port answers false, which looks like a refusal',
        );
      }
    });
  }

  test('every method the Dart side invokes has a native handler', () {
    // The other half, and the one a name check alone would miss: a channel can
    // be spelled right in three files and still carry a verb only two of them
    // know. `openNotificationSettings` on a phone whose native half spells it
    // `openNotificationSetting` is a button that does nothing — which is the
    // whole defect this channel exists to fix.
    final swift = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final kotlin = File(
      'android/app/src/main/kotlin/io/applander/odova/MainActivity.kt',
    ).readAsStringSync();

    final dart = File(
      'lib/app/notifications/notification_settings_link.dart',
    ).readAsStringSync();
    // Every string this file names as a channel method, however it reaches
    // the channel. The first version matched only `_open('…')` and therefore
    // missed `authorization()`, which invokes directly — a gate that covered
    // two of the three verbs and reported success. Whitespace is collapsed
    // first, because `dart format` wraps a long invocation across lines and a
    // regex that assumes one line is a regex that stops matching the day the
    // name gets longer.
    final flat = dart.replaceAll(RegExp(r'\s+'), ' ');
    final invoked = {
      for (final pattern in [
        RegExp(r"_open\( ?'(\w+)' ?\)"),
        RegExp(r"invokeMethod<\w+>\( ?'(\w+)'"),
      ])
        ...pattern.allMatches(flat).map((m) => m.group(1)!),
    };

    expect(
      invoked,
      {
        'openNotificationSettings',
        'openAppDetailsSettings',
        'notificationAuthorizationStatus',
      },
      reason: 'the port grew or lost a verb and this list did not follow',
    );
    for (final method in invoked) {
      expect(swift, contains('"$method"'), reason: 'iOS cannot answer $method');
      expect(
        kotlin,
        contains('"$method"'),
        reason: 'Android cannot answer $method',
      );
    }
  });
}
