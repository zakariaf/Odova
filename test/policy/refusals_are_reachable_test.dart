// Every refusal the fuel engine declares can actually be produced.
//
// EPIC-06 wrote a seven-case sealed `ConsumptionUnavailable` and then wired
// ONE of them. Six had no construction site anywhere in `lib/`, and
// `InsufficientData(have: 0, need: 1)` stood in for five distinct causes —
// including a CNG vehicle asked for litres per 100 km, which was told "one
// more full fill" when no number of fills would ever produce a litre figure
// for a car with no tank.
//
// That is a taxonomy pretending to be a mechanism. It costs more than dead
// code: the localisation epic writes six sentences no code path can emit, and
// the screen epic reads a `code` vocabulary in which one value means five
// different things. CLAUDE.md rule 7 — never guess in a way that looks like
// fact — is broken most easily by a refusal that is technically typed and
// substantively wrong.
//
// So: a declared reason is a promise that something can produce it.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import '../support/source_tree.dart';

void main() {
  test('every ConsumptionUnavailable case is constructed somewhere', () {
    final declared = <String>{};
    final source = sourceWithoutLineComments(
      dartFilesUnder(
        'lib/core/fuel',
      ).firstWhere((f) => f.path.endsWith('consumption_unavailable.dart')),
    );
    for (final match in RegExp(
      r'^final class (\w+) extends ConsumptionUnavailable',
      multiLine: true,
    ).allMatches(source)) {
      declared.add(match.group(1)!);
    }

    expect(
      declared,
      isNotEmpty,
      reason:
          'the parser found no cases — it is broken, and a gate that '
          'checks nothing passes',
    );

    // Where they are constructed. The declaration file is excluded: a case
    // that only appears in its own declaration is exactly the thing this gate
    // is looking for.
    final constructed = <String>{};
    for (final file in dartFilesUnder('lib')) {
      if (file.path.endsWith('consumption_unavailable.dart')) continue;
      final body = sourceWithoutLineComments(file);
      for (final name in declared) {
        if (RegExp('\\b$name\\(').hasMatch(body)) constructed.add(name);
      }
    }

    expect(
      declared.difference(constructed),
      isEmpty,
      reason:
          'these refusals are declared and nothing under lib/ can produce '
          'them, so the sentence a translator writes for each will never be '
          'shown — either wire them or delete them',
    );
  });
}
