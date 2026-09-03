// Policy tests over the two native platform projects.
//
// `flutter create` writes defaults that contradict SPEC.md §2 and §17 — a
// `com.example` organisation, an Android minSdk below API 26, an iOS
// deployment target below 15.0, and an INTERNET permission in the debug and
// profile manifests. Each of those is a decision, so each gets a test.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/l10n/supported_locales.dart';

/// Every `AndroidManifest.xml` under `android/app/src/`, in any build variant.
List<File> _androidManifests() => Directory('android/app/src')
    .listSync()
    .whereType<Directory>()
    .map((d) => File('${d.path}/AndroidManifest.xml'))
    .where((f) => f.existsSync())
    .toList();

void main() {
  group('the six locales are reachable from the OS', () {
    // SPEC.md §5 ships six locales. Declaring them in the app is not enough on
    // iOS: the OS filters `[NSLocale preferredLanguages]` against the bundle's
    // declared localizations before handing the list to the engine, so a locale
    // absent from CFBundleLocalizations never reaches
    // `PlatformDispatcher.locales` and `basicLocaleListResolution` never sees
    // it. An iPhone set to Persian would launch Odova in English, LTR.
    //
    // test/l10n/supported_locales_test.dart cannot catch this: it passes an
    // explicit `locale:` to OdovaApp and bypasses resolution entirely.
    test('ios CFBundleLocalizations lists exactly the shipped locales', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();

      final declared = RegExp(
        r'<key>CFBundleLocalizations</key>\s*<array>(.*?)</array>',
        dotAll: true,
      ).firstMatch(plist);
      expect(
        declared,
        isNotNull,
        reason:
            'Info.plist has no CFBundleLocalizations — iOS will offer only '
            'CFBundleDevelopmentRegion',
      );

      expect(
        RegExp(
          r'<string>(\w+)</string>',
        ).allMatches(declared!.group(1)!).map((m) => m.group(1)!).toSet(),
        odovaSupportedLocales.map((l) => l.languageCode).toSet(),
      );
    });
  });

  group('application identity', () {
    test('android applicationId is io.applander.odova', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();

      expect(gradle, contains('applicationId = "io.applander.odova"'));
      expect(
        gradle,
        isNot(contains('com.example')),
        reason: 'the flutter create default survived',
      );
    });

    test('the launcher name is Odova on both platforms', () {
      // A brand name, per app_en.arb's own metadata: identical in all six
      // locales, never translated and never transliterated. `flutter create`
      // writes the lowercase project name into the Android label, and it is
      // what the launcher, the app switcher and Settings all show.
      expect(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        contains('android:label="Odova"'),
      );

      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(
        plist,
        contains('<key>CFBundleDisplayName</key>\n\t<string>Odova</string>'),
      );
    });

    test('ios PRODUCT_BUNDLE_IDENTIFIER is io.applander.odova', () {
      final pbxproj = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();

      expect(
        pbxproj,
        contains('PRODUCT_BUNDLE_IDENTIFIER = io.applander.odova'),
      );
      expect(
        pbxproj,
        isNot(contains('com.example')),
        reason: 'the flutter create default survived',
      );
    });
  });

  group('deployment floor', () {
    // SPEC.md §17 Targets: iOS 15+, Android 8.0 / API 26+.
    test('minSdk is 26 and iOS deployment target is 15.0', () {
      // Every assignment, not the presence of the string: a second flavour or
      // product-flavour block setting `minSdk = 21` would pass a `contains`.
      // This mirrors the iOS arm below, which already sweeps for a lower one.
      final minSdks = RegExp(r'minSdk\s*=\s*(\d+)')
          .allMatches(File('android/app/build.gradle.kts').readAsStringSync())
          .map((m) => int.parse(m.group(1)!))
          .toList();

      expect(minSdks, isNotEmpty, reason: 'no minSdk assignment at all');
      for (final minSdk in minSdks) {
        expect(
          minSdk,
          greaterThanOrEqualTo(26),
          reason: 'SPEC.md §17 Targets: Android 8.0 / API 26+',
        );
      }

      final pbxproj = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      expect(pbxproj, contains('IPHONEOS_DEPLOYMENT_TARGET = 15.0'));
      expect(
        pbxproj,
        isNot(contains(RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = 1[0-4]\.'))),
        reason: 'a build configuration still targets below iOS 15',
      );

      expect(
        File('ios/Podfile').readAsStringSync(),
        contains("platform :ios, '15.0'"),
      );
    });
  });

  group('SPEC.md §2 — no network permission it can avoid', () {
    test('no INTERNET permission in any AndroidManifest', () {
      final manifests = _androidManifests();

      // Guard the guard: flutter create writes three variants, and a walk that
      // silently finds none would pass without checking anything.
      expect(
        manifests.length,
        greaterThanOrEqualTo(3),
        reason: 'expected main, debug and profile manifests',
      );

      for (final manifest in manifests) {
        expect(
          manifest.readAsStringSync(),
          isNot(contains('android.permission.INTERNET')),
          reason: '${manifest.path} holds the INTERNET permission',
        );
      }
    });
  });
}
