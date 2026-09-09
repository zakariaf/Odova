// Nothing that would change the submission plan is in the app.
//
// `release-and-store-shipping` rule 15: a FIRST release must submit the app
// version and its first in-app purchase together, or App Review closes the
// submission unreviewed under Guideline 2.1(b). `release/app-store-submission.md`
// states that Odova is exempt because it has no purchase of any kind.
//
// This test is what keeps that statement true. The day somebody adds a
// purchase, the submission plan changes and a paragraph written months earlier
// becomes wrong — so it fails here, in the same pull request, instead of at a
// submission that gets closed.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no purchase, ads or subscription package is resolved', () {
    // `pubspec.lock`, not `pubspec.yaml`: a transitive dependency that drags in
    // a billing SDK changes the submission exactly as much as a direct one.
    final lock = File('pubspec.lock').readAsStringSync();

    const banned = [
      'in_app_purchase',
      'purchases_flutter',
      'google_mobile_ads',
      'flutter_inapp_purchase',
      'adjust_sdk',
      'applovin',
    ];

    final found = banned.where((p) => lock.contains('\n  $p:')).toList();
    expect(
      found,
      isEmpty,
      reason:
          'a monetisation package is resolved, so §15 and the submission plan '
          'in release/app-store-submission.md are both out of date: $found',
    );
  });

  test('no StoreKit entitlement is declared', () {
    // The other half. An entitlement can be added in Xcode without touching
    // Dart at all, and it is what App Review reads.
    final entitlements = Directory('ios/Runner')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.entitlements'));

    for (final file in entitlements) {
      expect(
        file.readAsStringSync(),
        isNot(contains('com.apple.developer.in-app-payments')),
        reason: '${file.path} declares an in-app payments entitlement',
      );
    }
  });
}
