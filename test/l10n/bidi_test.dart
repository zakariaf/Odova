// Isolation is a rendering device, and the tests are mostly about where it is
// NOT allowed to reach.
//
// SPEC.md §5: a bidi control in storage survives an export and a screen reader
// — which either voices U+2068 or silently swallows it, and both are wrong —
// and it defeats every comparison, sort and search along the way.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/l10n/money_format.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/unit_format.dart';
import 'package:odova/ui/calm/calm_figure.dart';

import '../support/pump_app.dart';
import '../support/source_tree.dart';

/// `Money` needs a parsed `Currency`, and a test that writes
/// `Currency.tryParse('EUR')!` eleven times is testing the reader's patience.
Money _money(int amountMinor, String code) =>
    Money(amountMinor, Currency.tryParse(code)!);

/// SPEC.md §5 testing item 5's corpus, verbatim.
const _corpus = <String>[
  'BMW ۳۲۰i',
  'قبض از Shell — €۵۲٫۳۰ (A2)',
  'Autohaus Müller',
];

void main() {
  group('the isolation helpers', () {
    test('wrap with the right controls', () {
      // Escapes, not the characters: a literal control in source reorders the
      // code a reviewer reads, which is what these exist to prevent on screen.
      expect(isolate('x'), '\u2068x\u2069'); // FSI ... PDI
      expect(isolateLtr('x'), '\u2066x\u2069'); // LRI ... PDI
      expect(isolateRtl('x'), '\u2067x\u2069'); // RLI ... PDI
    });

    test('no legacy embedding or override appears in lib/', () {
      // LRE, RLE, LRO, RLO and PDF are the pre-Unicode-6.3 mechanism. They do
      // not nest, they leak across a string boundary, and an unbalanced one
      // reorders the rest of the paragraph. The isolates replaced them.
      const legacy = {
        '\u202A': 'LRE',
        '\u202B': 'RLE',
        '\u202C': 'PDF',
        '\u202D': 'LRO',
        '\u202E': 'RLO',
      };
      final offenders = <String>[];
      for (final file in dartFilesUnder('lib')) {
        // bidi.dart names them in order to strip them.
        if (file.path.endsWith('l10n/bidi.dart')) continue;
        final source = file.readAsStringSync();
        for (final MapEntry(key: char, value: name) in legacy.entries) {
          if (source.contains(char)) offenders.add('${file.path}: $name');
        }
      }
      expect(offenders, isEmpty);
    });
  });

  group('no control reaches anything that is not a pixel', () {
    test('the corpus survives isolation and stripping unchanged', () {
      for (final original in _corpus) {
        final rendered = isolate(original);
        expect(hasBidiControls(rendered), isTrue);
        // What goes to storage, to an export, to a search index.
        expect(stripBidi(rendered), original, reason: original);
        expect(hasBidiControls(stripBidi(rendered)), isFalse);
      }
    });

    test('the corpus carries no control to begin with', () {
      // The fixtures are what a user actually types. If one of them already
      // contained an isolate, every assertion below would be vacuous.
      for (final original in _corpus) {
        expect(hasBidiControls(original), isFalse, reason: original);
      }
    });

    test('stripping is idempotent and total', () {
      final everything = bidiControls.join();
      expect(stripBidi(everything), isEmpty);
      expect(stripBidi(stripBidi(isolate('x'))), 'x');
    });

    test(
      'a formatted amount is isolated for the screen and bare for a file',
      () {
        final shown = formatMoney(
          _money(123456, 'EUR'),
          'de-DE',
          numerals: CalmNumerals.auto,
        );
        expect(
          hasBidiControls(shown),
          isTrue,
          reason: 'not isolated for screen',
        );
        expect(hasBidiControls(formatForExport(123456)), isFalse);
        expect(hasBidiControls(stripBidi(shown)), isFalse);
      },
    );

    test('a number with a unit is isolated for the screen only', () {
      final shown = formatWithUnit(
        45.2,
        'لیتر',
        'fa-IR',
        numerals: CalmNumerals.auto,
        decimalDigits: 1,
      );
      expect(hasBidiControls(shown), isTrue);
      expect(hasBidiControls(stripBidi(shown)), isFalse);
    });
  });

  group('search and comparison see through isolation', () {
    test('searching for Golf finds an isolated title', () {
      final title = isolate('VW Golf TDI 2.0');
      expect(title.contains('Golf'), isTrue, reason: 'FSI is not inline');
      // And the normalised form is what an index should hold.
      expect(stripBidi(title), 'VW Golf TDI 2.0');
    });

    test('two strings that differ only by isolation compare equal once '
        'normalised', () {
      expect(isolate('Shell') == 'Shell', isFalse);
      expect(stripBidi(isolate('Shell')), 'Shell');
    });
  });

  testWidgets('a code is forced LTR even on an RTL screen', (tester) async {
    // A VIN is matched character by character against papers and a database.
    // Letting it take the paragraph's direction reverses it on three of the
    // six locales.
    await pumpApp(
      tester,
      const Center(child: CalmCode('WVWZZZ1KZAW123456')),
      locale: const Locale('fa'),
    );

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.textDirection, TextDirection.ltr);
    // Verbatim: not shaped, not reordered, not normalised.
    expect(text.data, 'WVWZZZ1KZAW123456');
  });

  testWidgets('a plate keeps the digits it was typed with, in either script', (
    tester,
  ) async {
    // SPEC.md §5: verbatim as typed, never shaped either way. An Iranian plate
    // legitimately contains Persian digits AND a Persian letter — transcribed,
    // not computed.
    for (final plate in ['۱۲ ب ۳۴۵ ایران ۶۷', '12 B 345']) {
      await pumpApp(
        tester,
        Center(child: CalmCode(plate)),
        locale: const Locale('fa'),
      );
      expect(tester.widget<Text>(find.byType(Text)).data, plate);
    }
  });

  testWidgets('an estimate is announced as "about", never as "tilde"', (
    tester,
  ) async {
    // The ~ stays in the VISIBLE string as the non-colour marker of an
    // estimate, and the spoken form is an ICU message.
    final handle = tester.ensureSemantics();

    await pumpApp(
      tester,
      const Center(
        child: CalmFigure(
          186512,
          formatsTag: 'en-US',
          numerals: CalmNumerals.latin,
          semanticsLabel: 'estimated, about 186,512 km',
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(CalmFigure));
    expect(node.label, 'estimated, about 186,512 km');
    expect(node.label, isNot(contains('~')));
    expect(node.label, isNot(contains('tilde')));

    handle.dispose();
  });

  testWidgets('no bidi control reaches a semantics label', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpApp(
      tester,
      Center(
        child: Semantics(
          label: stripBidi(isolate('قبض از Shell — €۵۲٫۳۰ (A2)')),
          child: const SizedBox.shrink(),
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(Semantics).first);
    expect(hasBidiControls(node.label), isFalse, reason: node.label);

    handle.dispose();
  });
}
