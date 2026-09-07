// Does the gate cover the gate?
//
// SPEC.md §17's accessibility gate is seven checkboxes — nine rules, two of
// them sharing a line — and a sentence calling
// it "a release blocker, not a polish item". A checkbox list is a thing people
// read; this file is what makes it a thing that fails.
//
// It tests the SUITE rather than the app. Every row of §17 is declared here
// with the test that covers it, so a row nobody wrote a test for is a failure —
// and, more usefully, a row whose test was DELETED becomes a failure too.
//
// **It is honest about what is not covered.** Six of the nine rows are only
// partly mechanised, and each names what is missing. A gate that claims nine of
// nine while covering three is worse than one that claims three, because the
// first one stops anybody looking.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// One row of §17's gate, and what stands behind it.
typedef GateRow = ({String rule, String coveredBy, String? notCovered});

/// The nine rules §17's gate states, in its order.
const _gate = <GateRow>[
  (
    rule: 'Minimum touch target 48x48 everywhere',
    coveredBy:
        'test/a11y/screen_sweep_test.dart — "has no tap target under '
        '48pt", through Flutter\'s own android and iOS guidelines',
    notCovered:
        'the 25 screens that need repository fakes; the odometer '
        'stepper and the chart tap targets are among them',
  ),
  (
    rule: 'Estimated values carry a non-visual signal',
    coveredBy:
        'test/a11y/estimated_value_semantics_test.dart and '
        'test/a11y/odometer_strip_semantics_test.dart — announced as words in '
        'all six locales, and the tilde is never read out',
    notCovered: null,
  ),
  (
    rule: 'Lighter text still meets 4.5:1 contrast',
    coveredBy:
        'test/theme/calm/calm_contrast_test.dart — every declared pair '
        'in both themes, with an EMPTY exception list',
    notCovered: null,
  ),
  (
    rule: 'Never a confidence percentage, bar or tier name in the UI',
    coveredBy:
        'test/a11y/due_card_semantics_test.dart — "no confidence tier, '
        'percentage or bar is announced"',
    notCovered: null,
  ),
  (
    rule: 'The computed badge has an accessible name',
    coveredBy: 'not yet — EPIC-17 task 17.4',
    notCovered: 'the fill-up price trio badge is unlabelled and untested',
  ),
  (
    rule: 'Both charts have a non-visual alternative',
    coveredBy:
        'test/a11y/chart_summary_test.dart — the summary is computed '
        'from the plotted series, so the sentence and the painting cannot '
        'drift apart',
    notCovered:
        'the accessible DATA TABLE behind one control is not built, '
        'and neither chart is wired to the summary yet',
  ),
  (
    rule: 'Save in the log modal is reachable one-handed',
    coveredBy: 'not yet — EPIC-17 task 17.4',
    notCovered:
        'geometry is asserted in the log-modal widget tests; reach is '
        'not asserted anywhere',
  ),
  (
    rule: 'Screen-reader language and direction are tagged per element',
    coveredBy:
        'partly — CalmListRow.nativeTitleLanguage carries the tag on '
        'language rows',
    notCovered: 'a Latin workshop name inside a Persian screen is untested',
  ),
  (
    rule: 'Full keyboard/switch traversal with a visible focus indicator',
    coveredBy:
        'the focus ring now clears SC 1.4.11 at 4.11:1 '
        '(test/theme/calm/calm_contrast_test.dart)',
    notCovered: 'traversal ORDER is untested — EPIC-17 task 17.8',
  ),
];

void main() {
  test('every row of §17 names what covers it', () {
    for (final row in _gate) {
      expect(row.coveredBy, isNotEmpty, reason: row.rule);
      expect(
        row.coveredBy.length,
        greaterThan(15),
        reason: '${row.rule} is claimed covered with no detail',
      );
    }
  });

  test('every named test file exists', () {
    // The assertion that makes this list decay loudly. A row can claim a test
    // that was renamed or deleted, and without this the claim outlives it.
    final missing = <String>[];
    for (final row in _gate) {
      for (final match in RegExp(r'test/[\w/]+\.dart').allMatches(
        row.coveredBy,
      )) {
        final path = match.group(0)!;
        if (!File(path).existsSync()) missing.add('${row.rule}: $path');
      }
    }

    expect(missing, isEmpty, reason: 'a row cites a test that is not there');
  });

  test('the gate is honest about what it does not cover', () {
    // THREE of nine rows are wholly covered. I wrote four here and this
    // assertion corrected me, which is the whole reason it counts rather than
    // trusting the prose above it.
    //
    // It does not demand more; it demands that the other six SAY what is
    // missing, and that the number never falls. A gate claiming nine of nine
    // while covering three is worse than one claiming three — the first stops
    // anybody looking.
    final covered = _gate.where((r) => r.notCovered == null).length;
    expect(
      covered,
      greaterThanOrEqualTo(3),
      reason: 'coverage went backwards',
    );

    for (final row in _gate.where((r) => r.notCovered != null)) {
      expect(
        row.notCovered,
        isNotEmpty,
        reason: '${row.rule} is marked incomplete with no gap named',
      );
    }
  });

  test('the accessibility finding records a resolution', () {
    // The assertion that stops this epic's central promise from rotting. The
    // finding was carried from EPIC-02 to EPIC-17 with a decision written in
    // it; if a future change reopens it, the file must say so again rather than
    // quietly losing the record.
    final finding = File(
      'design/calm/ACCESSIBILITY-FINDING.md',
    ).readAsStringSync();

    expect(
      finding,
      anyOf(contains('## Resolution'), contains('## Decision')),
      reason: 'the finding carries no dated decision',
    );
    expect(
      finding,
      matches(RegExp(r'20\d\d-\d\d-\d\d')),
      reason: 'a decision with no date is not a decision',
    );
  });

  test('the contrast exception list is empty', () {
    // EPIC-02 held the WCAG failures as dated exceptions asserting they still
    // fail. EPIC-17 fixed the values and the list emptied. This is what stops
    // a future failure being parked there instead of fixed.
    final source = File(
      'test/theme/calm/calm_contrast_test.dart',
    ).readAsStringSync();
    final list = source.substring(
      source.indexOf('knownContrastExceptions'),
    );
    final entries = RegExp(r'pair:\s').allMatches(list).length;

    expect(
      entries,
      0,
      reason: 'a contrast failure was parked as an exception rather than fixed',
    );
  });
}
