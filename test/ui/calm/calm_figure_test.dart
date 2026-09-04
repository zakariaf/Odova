// The two widgets that put a number or a code on screen.
//
// SPEC.md §5: numbers are announced in the display digit set, and tabular
// figures are not a style preference — a column that jitters as a digit
// changes reads as broken rather than as live.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money.dart';
import 'package:odova/l10n/money_format.dart';
import 'package:odova/l10n/unit_format.dart';
import 'package:odova/ui/calm/calm_figure.dart';

import '../../support/pump_app.dart';

TextStyle _styleOf(WidgetTester tester) =>
    tester.widget<Text>(find.byType(Text)).style!;

void main() {
  testWidgets('a figure formats, shapes and sets tabular figures', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Center(
        child: CalmFigure(
          1234.5,
          formatsTag: 'fa-IR',
          numerals: CalmNumerals.auto,
          decimalDigits: 1,
        ),
      ),
    );

    expect(find.text('۱٬۲۳۴٫۵'), findsOneWidget);
    expect(
      _styleOf(tester).fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('an already-formatted run gets the same treatment', (
    tester,
  ) async {
    // Money and units come out of their own formatters as finished strings —
    // the symbol placed, the isolate wrapped, the digits shaped. Re-deriving
    // them from a `num` here is impossible: `formatMoney` decides the symbol
    // side and `formatUnit` the abbreviation, and neither is recoverable from
    // the number. Without this constructor the first screen reaches for a
    // plain `Text` and silently drops the one guarantee this widget exists to
    // make. It is the same tabular-figures path, not a second one.
    final money = formatMoney(
      const Money.of(123456, 'EUR'),
      'de-DE',
      numerals: CalmNumerals.auto,
    );

    await pumpApp(tester, Center(child: CalmFigure.formatted(money)));

    expect(find.text(money), findsOneWidget);
    expect(
      _styleOf(tester).fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('a formatted run carries a semantics label of its own', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final distance = formatWithUnit(
      186512,
      'km',
      'en-US',
      numerals: CalmNumerals.latin,
    );

    await pumpApp(
      tester,
      Center(
        child: CalmFigure.formatted(
          distance,
          semanticsLabel: 'estimated, about 186,512 kilometres',
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(CalmFigure)).label,
      'estimated, about 186,512 kilometres',
    );
    handle.dispose();
  });

  testWidgets('a code is pinned LTR and never shaped', (tester) async {
    // A VIN inside a Persian sentence is a Latin run, and letting it take the
    // paragraph's direction is what reverses it.
    await pumpApp(
      tester,
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(child: CalmCode('WVWZZZ1KZAW123456')),
      ),
    );

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, 'WVWZZZ1KZAW123456');
    expect(text.textDirection, TextDirection.ltr);
  });
}
