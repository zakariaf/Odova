// The harness, tested before anything is tested with it.
//
// SPEC.md §17 calls accessibility "the weakest area of this spec and treated as
// a release blocker, not a polish item". A harness that silently swallows is
// worse than no harness at all: it converts a release blocker into a green
// suite, which is the one outcome nobody can recover from by reading the code.
//
// So every assertion here is about the harness FAILING. A gate nobody has
// watched go red is not a gate.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/l10n/supported_locales.dart';

import '../support/a11y_harness.dart';

void main() {
  group('the tuple reaches the widget tree', () {
    testWidgets('pumpA11y pins textScaler, boldText and accessibleNavigation', (
      tester,
    ) async {
      late MediaQueryData seen;
      await pumpA11y(
        tester,
        const A11yCase(
          locale: Locale('de'),
          textScale: 2,
          boldText: true,
        ),
        Builder(
          builder: (context) {
            seen = MediaQuery.of(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(seen.textScaler.scale(10), 20);
      expect(seen.boldText, isTrue);
      expect(seen.accessibleNavigation, isTrue);
    });

    testWidgets('and the locale actually reaches Directionality', (
      tester,
    ) async {
      late TextDirection direction;
      await pumpA11y(
        tester,
        const A11yCase(locale: Locale('ar')),
        Builder(
          builder: (context) {
            direction = Directionality.of(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(direction, TextDirection.rtl);
    });
  });

  group('the failures it exists to produce', () {
    testWidgets('an overflow at 200% is a failure, not a warning', (
      tester,
    ) async {
      // A fixed height around text is the commonest 200% break in this app —
      // every card in `design/reference/calm/` was drawn at 100%.
      await pumpA11y(
        tester,
        const A11yCase(textScale: 2),
        // A COLUMN in a fixed height. A bare SizedBox around a Text clips
        // silently and reports nothing — it is RenderFlex that shouts, which
        // is worth knowing before writing a test that relies on the shout.
        const SizedBox(
          height: 20,
          child: Column(
            children: [
              Text('Odometer last updated 8 weeks ago'),
              Text('The estimates below are getting rough.'),
            ],
          ),
        ),
      );

      expect(
        () => expectNoOverflow(tester),
        throwsA(isA<TestFailure>()),
        reason: 'a red overflow must fail the test that caused it',
      );
    });

    testWidgets('no overflow is silent', (tester) async {
      await pumpA11y(
        tester,
        const A11yCase(textScale: 2),
        const Text('Oil'),
      );

      expect(() => expectNoOverflow(tester), returnsNormally);
    });

    testWidgets('an unlabelled icon fails the semantics sweep', (tester) async {
      await pumpA11y(
        tester,
        const A11yCase(),
        // A bare icon is invisible to a screen reader: it is announced as
        // nothing at all, so a row reading "Oil and filter, button" loses the
        // only thing distinguishing it from the row below.
        const Icon(Icons.star),
      );

      expect(
        () => expectEverythingLabelled(tester),
        throwsA(isA<TestFailure>()),
      );
    });

    testWidgets('an unlabelled BUTTON fails — the semantics pass really runs', (
      tester,
    ) async {
      // This case exists because the semantics half was sweeping an EMPTY tree
      // and passing everything: it read `rootPipelineOwner.semanticsOwner`,
      // which is null in a widget test even with a live handle. The icon pass
      // — which walks the WIDGET tree — was carrying every assertion on its
      // own, so the self-test was green and half the sweep did nothing.
      //
      // A button carries no `Icon`, so only the semantics pass can catch it.
      await pumpA11y(
        tester,
        const A11yCase(),
        GestureDetector(
          onTap: () {},
          child: const SizedBox(width: 48, height: 48),
        ),
      );

      expect(
        () => expectEverythingLabelled(tester),
        throwsA(isA<TestFailure>()),
        reason: 'a tappable node with no label is announced as nothing',
      );
    });

    testWidgets('a labelled button passes', (tester) async {
      await pumpA11y(
        tester,
        const A11yCase(),
        Semantics(
          label: 'Update odometer',
          button: true,
          child: GestureDetector(
            onTap: () {},
            child: const SizedBox(width: 48, height: 48),
          ),
        ),
      );

      expect(() => expectEverythingLabelled(tester), returnsNormally);
    });

    testWidgets('a labelled icon passes', (tester) async {
      await pumpA11y(
        tester,
        const A11yCase(),
        const Icon(Icons.star, semanticLabel: 'Safety item'),
      );

      expect(() => expectEverythingLabelled(tester), returnsNormally);
    });

    testWidgets('a decorative icon passes when it is EXCLUDED, not silenced', (
      tester,
    ) async {
      // The honest way to have an unlabelled icon: say it carries no meaning.
      // `ExcludeSemantics` is a claim a reviewer can check; a missing label is
      // an omission nobody can tell from an oversight.
      await pumpA11y(
        tester,
        const A11yCase(),
        const ExcludeSemantics(child: Icon(Icons.star)),
      );

      expect(() => expectEverythingLabelled(tester), returnsNormally);
    });
  });

  group('the matrix', () {
    test('enumerates six locales x two scales x two bold states', () {
      expect(a11yMatrix, hasLength(odovaSupportedLocales.length * 2 * 2));
      expect(a11yMatrix, hasLength(24));
    });

    test('names every case, so a dropped locale is visible', () {
      // Counted matrices hide a dropped locale in an integer. Named ones put it
      // in a test name, which is what somebody actually reads in CI output.
      for (final locale in odovaSupportedLocales) {
        expect(
          a11yMatrix.where((c) => c.locale == locale),
          hasLength(4),
          reason: '${locale.languageCode} is short of its four cases',
        );
      }
      expect(
        a11yMatrix.map((c) => c.name).toSet(),
        hasLength(24),
        reason: 'two cases share a name, so one of them cannot be read',
      );
    });

    test('covers all three right-to-left locales', () {
      // Half the shipped locales are RTL and the mirror is where layout bugs
      // live — §17's per-locale gate is not satisfiable without them.
      expect(
        a11yMatrix.map((c) => c.locale.languageCode).toSet(),
        containsAll(<String>['fa', 'ar', 'ckb']),
      );
    });

    test('reaches 200%, which is what the gate is about', () {
      expect(a11yMatrix.where((c) => c.textScale == 2.0), hasLength(12));
      expect(a11yMatrix.where((c) => c.boldText), hasLength(12));
    });
  });
}
