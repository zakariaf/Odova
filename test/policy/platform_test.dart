// Policy tests over the two native platform projects.
//
// `flutter create` writes defaults that contradict SPEC.md §2 and §17 — a
// `com.example` organisation, an Android minSdk below API 26, an iOS
// deployment target below 15.0, and an INTERNET permission in the debug and
// profile manifests. Each of those is a decision, so each gets a test.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `AndroidManifest.xml` under `android/app/src/`, in any build variant.
List<File> _androidManifests() => Directory('android/app/src')
    .listSync()
    .whereType<Directory>()
    .map((d) => File('${d.path}/AndroidManifest.xml'))
    .where((f) => f.existsSync())
    .toList();

void main() {
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
      expect(
        File('android/app/build.gradle.kts').readAsStringSync(),
        contains('minSdk = 26'),
      );

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
