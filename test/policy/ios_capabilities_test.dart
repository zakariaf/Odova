// What the app declares it can do, asserted whole.
//
// SPEC.md §2's claim is that Odova makes zero network calls and that this is
// true **by construction**. On Android that had mechanical proof: the merged
// manifest either contains `android.permission.INTERNET` or it does not, and
// the check reads what actually shipped. **iOS has no such permission**, so its
// absence proves nothing and there is nothing here to reproduce that assertion
// with. EPIC-19's platform decision says so in as many words rather than
// letting the checklist imply the evidence survived the move.
//
// What this file can prove is narrower and still worth having: the app declares
// no transport-security exception, no background mode it has not earned, and
// exactly the usage descriptions on a committed list. WHOLE-SET equality, not
// "no forbidden key" — the failure that actually happens is a transitive plugin
// bump adding a key nobody asked for, and a "no forbidden key" check passes on
// every key it was not told about.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The `Info.plist` source, as text.
///
/// Read as text rather than parsed: the file is a fixed shape written by
/// hand, and a plist parser is a dependency for something a regex answers.
String _plist() => File('ios/Runner/Info.plist').readAsStringSync();

/// Every `<key>` the plist declares, in order.
Set<String> _keys(String plist) => RegExp(
  '<key>([^<]+)</key>',
).allMatches(plist).map((m) => m.group(1)!).toSet();

void main() {
  test('usage descriptions are exactly the committed set', () {
    // A missing one is a rejection; an unused one is a claim we cannot defend
    // — App Review asks what the app does with a permission it declares, and
    // "a plugin added it" is not an answer.
    final declared = _keys(
      _plist(),
    ).where((k) => k.endsWith('UsageDescription')).toSet();

    final expected = File('ios/expected_usage_descriptions.txt')
        .readAsLinesSync()
        .map((l) => l.split('#').first.trim())
        .where((l) => l.isNotEmpty)
        .toSet();

    expect(
      declared,
      expected,
      reason:
          'the usage-description keys and the committed list disagree — a key '
          'nobody asked for is a claim nobody can defend at review',
    );
  });

  test('export compliance is answered in the plist, not per upload', () {
    // Every upload otherwise stops on a question whose answer never changes.
    // §2's app has no encryption to declare: no HTTPS because there is no
    // network, and §2's backup is a plain, unencrypted JSON file. `crypto`
    // hashes inside that file for integrity, and hashing is not encryption.
    //
    // Declaring it false here rather than answering "no" in the web form each
    // time removes the one gate that a person had to remember, and pins the
    // answer to the same review that reads this file. Answering "yes, standard
    // algorithms" out of caution inherits an annual self-classification report
    // this app does not owe.
    expect(
      RegExp(
        r'<key>ITSAppUsesNonExemptEncryption</key>\s*<(true|false)/>',
      ).firstMatch(_plist())?.group(1),
      'false',
      reason:
          'the plist must answer export compliance false — otherwise every '
          'upload stops on a question whose answer is already decided',
    );
  });

  test('no App Transport Security exception is declared', () {
    // The single most visible contradiction a reviewer can find in an app that
    // claims zero network calls, and it arrives by copy-paste from a
    // Stack Overflow answer about a plugin this app does not have.
    expect(
      _plist(),
      isNot(contains('NSAppTransportSecurity')),
      reason:
          'an ATS block in an app that claims to make no network calls is the '
          'first thing a reviewer will ask about',
    );
  });

  test('background modes are exactly the committed set', () {
    // Empty today, deliberately. §4 schedules local notifications, which the
    // OS delivers without the app running — `remote-notification` in
    // particular would imply a push server this app does not have and would
    // put a network claim in the capability surface itself.
    // NO early return for the absent key. The four lines below already handle
    // it — no match, null group, empty set — and a `return` here would make the
    // test silently assert nothing for the case it is most likely to be in.
    final plist = _plist();
    final modes = RegExp(
      r'<key>UIBackgroundModes</key>\s*<array>(.*?)</array>',
      dotAll: true,
    ).firstMatch(plist)?.group(1);

    expect(
      RegExp(
        '<string>([^<]+)</string>',
      ).allMatches(modes ?? '').map((m) => m.group(1)!).toSet(),
      isEmpty,
      reason:
          'a background mode is declared that §4 does not need — and '
          'remote-notification would imply a push server this app has none of',
    );
  });
}
