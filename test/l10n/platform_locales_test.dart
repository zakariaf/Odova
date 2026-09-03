// The two platform manifests have to agree with lib/l10n/.
//
// Neither is reachable from Dart at runtime, so nothing else in this suite can
// notice when they drift. The symptom is invisible in development and specific
// in the field: on iOS a tag missing from CFBundleLocalizations is a language
// the OS will not offer and will not pass to the app, so a Persian phone gets
// an English Odova and no error anywhere.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/l10n/supported_locales.dart';

void main() {
  final shipped = odovaSupportedLocales.map((l) => l.languageCode).toSet();

  test('Info.plist CFBundleLocalizations lists exactly the shipped six', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final array = RegExp(
      r'<key>CFBundleLocalizations</key>\s*<array>(.*?)</array>',
      dotAll: true,
    ).firstMatch(plist);

    expect(array, isNotNull, reason: 'no CFBundleLocalizations array');
    final listed = RegExp(
      '<string>([^<]+)</string>',
    ).allMatches(array!.group(1)!).map((m) => m.group(1)!).toSet();

    expect(listed, shipped);
  });

  test('locales_config.xml lists exactly the shipped six', () {
    // Android 13's per-app language picker reads this. Without it Odova is not
    // in the picker at all.
    final xml = File(
      'android/app/src/main/res/xml/locales_config.xml',
    ).readAsStringSync();
    final listed = RegExp(
      'android:name="([^"]+)"',
    ).allMatches(xml).map((m) => m.group(1)!).toSet();

    expect(listed, shipped);
  });

  test('the manifest points at locales_config', () {
    // The file existing is not the same as the file being read.
    expect(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
      contains('android:localeConfig="@xml/locales_config"'),
    );
  });
}
