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
// It was not the only one. The same review pass found `CalmConsumptionUnit` in
// `lib/l10n/unit_format.dart` — four values against `ConsumptionUnit`'s six,
// with two of the four wire strings DIFFERENT (`l_per_100km` and `mpg_imp`
// against SPEC.md §3's `l_100km` and `mpg_uk`). It had no production caller,
// so nothing had gone wrong yet; the first `Settings` writer to import the
// nearer of the two names would have written a `consumption_unit` the schema's
// own CHECK refuses, and a backup file no other install could read.
//
// So this is the gate that says a stored vocabulary is declared once.
import 'package:flutter_test/flutter_test.dart';

import '../support/source_tree.dart';

String _describe(MapEntry<String, List<String>> entry) =>
    '  ${entry.key}: ${entry.value}';

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

  test('no enum is a second spelling of a SPEC.md stored vocabulary', () {
    // The general form of the Money and CalmConsumptionUnit failures: two
    // types that mean the same thing, one of which is wrong, and a caller
    // picking whichever name is nearer. Matched on the WIRE VALUES rather
    // than on the type name, because a duplicate never shares the name — it
    // is the values that collide, and the values are what reach a column and
    // a backup file.
    final byWire = <String, List<String>>{};
    for (final file in dartFilesUnder('lib')) {
      final source = sourceWithoutLineComments(file);
      for (final match in RegExp(
        // `,` OR `;` — the LAST value of an enum ends with a semicolon
        // before the constructor, and a first version of this pattern
        // accepted only the comma. It then saw five of every six values and
        // reported a planted duplicate as clean.
        r"^\s*(\w+)\('([a-z0-9_]+)'\)[,;]\s*$",
        multiLine: true,
      ).allMatches(source)) {
        byWire
            .putIfAbsent(match.group(2)!, () => [])
            .add('${file.path}: ${match.group(1)}');
      }
    }

    // A wire value declared in two files is two vocabularies for one setting.
    final duplicated = {
      for (final entry in byWire.entries)
        if (entry.value.map((v) => v.split(':').first).toSet().length > 1)
          entry.key: entry.value,
    };

    expect(
      duplicated,
      isEmpty,
      reason:
          'these wire values are declared in more than one file, so which one '
          'reaches the database depends on which import a caller reached '
          'for:\n'
          '${duplicated.entries.map(_describe).join('\n')}',
    );
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
  test('no two enums declare the same set of members', () {
    // The third instance of one idea with two types, after the two `Money`s
    // and the two `ConsumptionUnit`s — and the first that the wire-value check
    // above could not see, because `RateConfidence` had no wire strings at all.
    //
    // EPIC-02 wrote `RateConfidence { measured, assumed, defaulted }` for the
    // due card; EPIC-07 wrote `RateConfidence { measured, assumed, defaulted }`
    // for the rate. The value flows from one to the other — the rate's
    // confidence IS what the card renders — so two types means a conversion
    // function sitting between them, and a conversion function between two
    // enums that are supposed to be identical is a place they stop being
    // identical.
    //
    // Matched on the MEMBER SET, because that is what a duplicate shares: a
    // second spelling never shares the type name.
    final byMembers = <String, List<String>>{};
    for (final file in dartFilesUnder('lib')) {
      final source = sourceWithoutLineComments(file);
      for (final match in RegExp(
        r'^enum (\w+) \{(.*?)^\}',
        multiLine: true,
        dotAll: true,
      ).allMatches(source)) {
        final name = match.group(1)!;
        final body = match.group(2)!;
        // Members are the identifiers before the first `;` (which starts the
        // constructor and fields, if any).
        final head = body.split(';').first;
        final members =
            RegExp(r'^\s*(\w+)\s*(?:\(|,|$)', multiLine: true)
                .allMatches(head)
                .map((m) => m.group(1)!)
                .where((m) => m != 'const')
                .toList()
              ..sort();
        if (members.length < 2) continue;
        byMembers
            .putIfAbsent(members.join(','), () => [])
            .add('${file.path}: $name');
      }
    }

    final duplicated = {
      for (final entry in byMembers.entries)
        if (entry.value.length > 1) entry.key: entry.value,
    };

    expect(
      duplicated,
      isEmpty,
      reason:
          'these enums have identical members, so they are one idea with two '
          'names and something will have to convert between them:\n'
          '${duplicated.entries.map(_describe).join('\n')}',
    );
  });
}
