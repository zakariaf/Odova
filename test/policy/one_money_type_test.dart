// There is exactly one Money in this codebase, and one currency-exponent table.
//
// EPIC-04 needed an amount before EPIC-06 existed, so it wrote a small
// `lib/core/money.dart` whose own header said EPIC-06 would "extend rather than
// replace" it. EPIC-06 wrote `lib/core/money/money.dart` instead, and for one
// commit the tree held TWO types named `Money` — an extension type over
// `(int, String)` with a `double get major`, and a class over
// `(int, Currency)` that refuses doubles — plus two tables of ISO 4217
// exponents that could drift apart. Both compiled. Both were imported. An
// import in the wrong file would have been a silent hundredfold error on a yen
// amount, and nothing would have gone red.
//
// So this is the gate that says a value object is a value object once.
import 'package:flutter_test/flutter_test.dart';

import '../support/source_tree.dart';

void main() {
  test('only one declaration of Money exists under lib/', () {
    final declarations = <String>[];
    for (final file in dartFilesUnder('lib')) {
      final source = sourceWithoutLineComments(file);
      for (final match in RegExp(
        r'^\s*(?:@\w+\s*)?(?:abstract\s+|final\s+|sealed\s+|base\s+)*'
        r'(?:extension type(?: const)?|class)\s+Money\b',
        multiLine: true,
      ).allMatches(source)) {
        declarations.add('${file.path}: ${match.group(0)!.trim()}');
      }
    }
    expect(
      declarations,
      hasLength(1),
      reason:
          'Money is declared ${declarations.length} times:\n'
          '${declarations.join('\n')}',
    );
    expect(declarations.single, startsWith('lib/core/money/money.dart:'));
  });

  test('only one ISO 4217 exponent table exists under lib/', () {
    // Two tables are two answers. The one that ships is whichever file the
    // caller happened to import, which is not a decision anybody made.
    final tables = <String>[];
    for (final file in dartFilesUnder('lib')) {
      final source = sourceWithoutLineComments(file);
      // A map literal that maps a currency code to its exponent: the JPY row
      // is in every version of this table and in nothing else.
      if (RegExp(r"'JPY':\s*0").hasMatch(source)) tables.add(file.path);
    }
    expect(tables, ['lib/core/money/currency.dart'], reason: tables.join('\n'));
  });
}
