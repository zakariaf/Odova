// The tilde, and what a screen reader does with it.
//
// SPEC.md §1.4 puts a `~` in front of every projected figure so a user can tell
// at a glance which numbers the app knows and which it guessed. A screen reader
// reads that as "tilde", or as nothing — either way the warning the mark exists
// to give is the one thing a blind user does not get.
//
// §17's gate names the announcement literally: "about 187,400 kilometres,
// estimated". The ARB key has existed since EPIC-04 in all six locales and had
// no caller until EPIC-17.
@TestOn('vm')
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/l10n/supported_locales.dart';
import 'package:odova/ui/calm/estimated_value_semantics.dart';

import '../support/a11y_harness.dart';

void main() {
  testWidgets('announces the meaning, never the glyph', (tester) async {
    await pumpA11y(
      tester,
      const A11yCase(),
      const EstimatedValueSemantics(
        value: '187,400 km',
        child: Text('~187,400 km'),
      ),
    );

    final node = tester.getSemantics(find.byType(EstimatedValueSemantics));
    expect(node.label, contains('187,400 km'));
    expect(node.label, contains('estimated'));
    expect(
      node.label,
      isNot(contains('~')),
      reason: 'the mark is visual; the label says what it means in words',
    );
  });

  testWidgets('the figure is announced ONCE', (tester) async {
    // The child renders the `~` form. Without `excludeSemantics` a reader walks
    // into it and announces the number twice — once as this sentence and once
    // as the tilde string.
    await pumpA11y(
      tester,
      const A11yCase(),
      const EstimatedValueSemantics(
        value: '187,400 km',
        child: Text('~187,400 km'),
      ),
    );

    final node = tester.getSemantics(find.byType(EstimatedValueSemantics));
    var descendants = 0;
    node.visitChildren((_) {
      descendants++;
      return true;
    });

    expect(
      descendants,
      0,
      reason: 'the tilde string must not be announced too',
    );
  });

  testWidgets('the visible string still carries the tilde', (tester) async {
    // The mark is not replaced by the label — a sighted user keeps it. A fix
    // that dropped the `~` would satisfy the reader and break §1.4.
    await pumpA11y(
      tester,
      const A11yCase(),
      const EstimatedValueSemantics(
        value: '187,400 km',
        child: Text('~187,400 km'),
      ),
    );

    expect(find.text('~187,400 km'), findsOneWidget);
  });

  for (final locale in odovaSupportedLocales) {
    testWidgets('${locale.languageCode} announces a sentence, not a figure', (
      tester,
    ) async {
      // The point of taking this from ARB rather than concatenating: five of
      // the six languages do not share English word order, and three are
      // right-to-left. A Dart-side "estimated, " + figure would be wrong in
      // all of them and would look right in the one the author reads.
      await pumpA11y(
        tester,
        A11yCase(locale: locale),
        const EstimatedValueSemantics(
          value: '187,400',
          child: Text('~187,400'),
        ),
      );

      final node = tester.getSemantics(find.byType(EstimatedValueSemantics));
      expect(node.label, contains('187,400'));
      expect(
        node.label.length,
        greaterThan('187,400'.length),
        reason:
            '${locale.languageCode} announces the bare figure — the key is '
            'missing or untranslated, so the warning is silently absent',
      );
    });
  }
}
