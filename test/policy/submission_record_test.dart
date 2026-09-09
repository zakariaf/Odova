// The submission record answers every gate that has no API.
//
// Each row in it blocks submission with a message naming a symptom rather than
// the setting — "this app cannot be submitted" rather than "nobody accepted the
// agreement" — so each is raised on day one and dated. A blank line in that
// table is a gate somebody will discover on the day they try to ship.
//
// The test asserts the SHAPE, not the answers: whether the account holder has
// created the app record is not knowable from here. What is knowable is whether
// the question is written down and whether the exemptions carry a reason.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _record() => File('release/app-store-submission.md').readAsStringSync();

void main() {
  test('every account-holder-only gate is named', () {
    // The list is here rather than parsed out of the document, because a test
    // that reads its own subject can only check the rows that exist. A gate
    // nobody wrote down is exactly the one this is for.
    const gates = [
      'App record created',
      'Bundle ID registered',
      'Privacy questionnaire',
      'Age rating',
      'Paid Applications Agreement',
      'Export compliance',
    ];

    final record = _record();
    for (final gate in gates) {
      expect(
        record,
        contains(gate),
        reason: '$gate is not on the submission record',
      );
    }
  });

  test('no gate is left blank', () {
    // A row whose Status cell is empty is a row somebody skimmed past. "not
    // done" is a fine answer; nothing is not.
    final rows = _record()
        .split('\n')
        .where((l) => l.startsWith('| ') && l.split('|').length >= 5)
        .where((l) => !l.contains('---') && !l.contains('Status'));

    expect(rows, isNotEmpty, reason: 'the gate table is gone');
    for (final row in rows) {
      final cells = row.split('|').map((c) => c.trim()).toList();
      expect(
        cells[3],
        isNotEmpty,
        reason: 'a gate has an empty status: $row',
      );
    }
  });

  test('the no-IAP position names the rule it is an exception to', () {
    // The paragraph exists so nobody re-derives it under submission pressure.
    // A version of it that says "we have no IAP" without naming 2.1(b) is a
    // sentence that does not survive its first contradiction.
    final record = _record();

    expect(
      record,
      contains('2.1(b)'),
      reason: 'the guideline the exemption is against is not named',
    );
    expect(
      record,
      contains('test/policy/no_iap_test.dart'),
      reason: 'nothing ties the claim to the test that keeps it true',
    );
  });

  test('the Paid Applications Agreement exemption carries a reason', () {
    // Marked "not required" is an assertion. Marked "not required — free app,
    // no IAP" is a checkable one.
    expect(
      _record(),
      matches(RegExp(r'Paid Applications Agreement.*not required.*free app')),
      reason: 'the exemption is claimed without the reason for it',
    );
  });
}
