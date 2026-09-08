// The triage table, held to the sweep.
//
// `design/review/parity-sweep.md` is what Task 18.4 produced and what Tasks
// 18.5 to 18.7 rewrite as they close rows. A table is a document, and a
// document drifts — a screen quietly dropped from the sweep leaves a row nobody
// notices, which is how a broken screen ships past a review that looked
// complete.
//
// So the table is a TESTED artefact: one row per comparison, every verdict a
// word from the vocabulary, and no empty cells. "We'll come back to it" cannot
// be the state at sign-off.
@Tags(['parity'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'parity_screens.dart';
import 'support/parity_capture.dart';

/// The four words a row may carry.
///
/// `deferred-NOTE` is a real verdict and a good one — §17's sign-off asks for
/// findings graded, not for findings absent. What it is not is a blank.
const _verdicts = {'pass', 'fixed', 'design-change', 'deferred-NOTE'};

void main() {
  final table = File('design/review/parity-sweep.md').readAsStringSync();

  /// Every `| screen | theme | dir | verdict | … |` row, as its cells.
  final rows = [
    for (final line in table.split('\n'))
      if (line.startsWith('| `')) line.split('|').map((c) => c.trim()).toList(),
  ];

  test('the table covers all 112 comparisons', () {
    final covered = {
      for (final cells in rows) '${cells[1]}-${cells[2]}-${cells[3]}',
    };
    final expected = {
      for (final screen in kParityScreens)
        for (final config in kParityCases)
          '`${screen.id}`-${config.theme}-${config.dir}',
    };

    expect(covered.difference(expected), isEmpty, reason: 'a row for nothing');
    expect(
      expected.difference(covered),
      isEmpty,
      reason: 'a comparison the table does not mention',
    );
    expect(rows, hasLength(kParityScreens.length * kParityCases.length));
  });

  test('no row is left unresolved', () {
    final bad = [
      for (final cells in rows)
        if (!_verdicts.contains(cells[4]))
          '${cells[1]}-${cells[2]}-${cells[3]}: "${cells[4]}"',
    ];

    expect(
      bad,
      isEmpty,
      reason:
          'a verdict outside ${_verdicts.join(', ')}:\n'
          '${bad.map((b) => '  - $b').join('\n')}',
    );
  });

  test('every failing row names its class and quotes the tool', () {
    // The two cells that make a row actionable. A row saying only "it failed"
    // sends the next reader back to a 900-line log to find out what the tool
    // said, and the log is the thing most likely to be regenerated.
    for (final cells in rows) {
      if (cells[4] == 'pass') continue;
      expect(cells[5], isNotEmpty, reason: '${cells[1]} names no class');
      expect(
        cells[6].length,
        greaterThan(20),
        reason: '${cells[1]} does not quote the tool',
      );
    }
  });

  test('the raw output it was written from is kept', () {
    // The table is a summary and the summary can be wrong. Keeping the
    // tool's own output beside it means a disagreement is settleable without
    // re-running a sweep whose inputs may have moved.
    final raw = File('design/review/parity-raw.txt');
    expect(raw.existsSync(), isTrue);
    expect(raw.readAsStringSync(), contains('band edges are absent'));
  });
}
