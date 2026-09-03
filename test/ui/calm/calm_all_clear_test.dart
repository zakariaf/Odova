// CalmAllClear — the most common state in the product, and the best-looking
// screen in the app (SPEC.md §9).
//
// It is NOT an empty state. An empty state is a list nobody has filled in yet;
// this is the answer "nothing needs doing", and rendering it as a grey icon in
// a box tells a user who has looked after their car that the app has nothing
// for them.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/ui/calm/calm_all_clear.dart';
import 'package:odova/ui/calm/calm_button.dart';

import '../../support/pump_app.dart';

BoxDecoration _decorationOf(WidgetTester tester, Type type) =>
    tester
            .widget<Container>(
              find
                  .descendant(
                    of: find.byType(type),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .decoration!
        as BoxDecoration;

void main() {
  testWidgets('CalmAllClear renders the ok radial wash, a 92pt mark with a '
      '12pt halo, and the since block on surface2', (tester) async {
    await pumpApp(
      tester,
      const Center(
        child: CalmAllClear(
          headline: 'Nothing due',
          nextLine: 'Next: Inspection, 14 March',
          fuzzLine: 'in about 6 weeks',
          since: CalmSinceLine(
            label: 'Since the last oil change',
            figure: '3,120 km · 4 months',
          ),
        ),
      ),
    );

    final decoration = _decorationOf(tester, CalmAllClear);
    // The sage wash is what makes this NOT an empty state.
    final gradient = decoration.gradient! as RadialGradient;
    expect(gradient.colors.first, calmColorsLight.ok.tint);
    expect(gradient.colors.last, calmColorsLight.surface);
    expect(decoration.boxShadow, calmShapesLight.elev2);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(calmShapesLight.radius3xl),
    );

    expect(
      tester.getSize(find.byType(CalmAllClearMark)),
      const Size(kCalmAllClearMarkSize, kCalmAllClearMarkSize),
    );
    // `box-shadow: 0 0 0 12px var(--color-ok-tint)` — a halo, not a blur.
    final halo = _decorationOf(tester, CalmAllClearMark).boxShadow!.single;
    expect(halo.spreadRadius, kCalmAllClearHalo);
    expect(halo.blurRadius, 0);
    expect(halo.color, calmColorsLight.ok.tint);

    for (final line in [
      'Nothing due',
      'Next: Inspection, 14 March',
      'in about 6 weeks',
      'Since the last oil change',
      '3,120 km · 4 months',
    ]) {
      expect(find.text(line), findsOneWidget, reason: line);
    }
  });

  testWidgets('the since block is omitted entirely when there is nothing to '
      'measure from', (tester) async {
    await pumpApp(
      tester,
      const Center(
        child: CalmAllClear(
          headline: 'Nothing due',
          nextLine: 'Next: Inspection, 14 March',
        ),
      ),
    );

    // SPEC.md §1 forbids a plausible-looking blank: no label with a dash under
    // it, no zero, nothing.
    expect(find.byType(CalmAllClearSince), findsNothing);
    expect(find.text('in about 6 weeks'), findsNothing);
  });

  testWidgets('the estimate keeps its own line and never merges into the '
      'fact', (tester) async {
    await pumpApp(
      tester,
      const Center(
        child: CalmAllClear(
          headline: 'Nothing due',
          nextLine: 'Next: Inspection, 14 March',
          fuzzLine: 'in about 6 weeks',
        ),
      ),
    );

    // Two Texts, never one sentence: "Next: Inspection, 14 March, in about 6
    // weeks" reads as a single confident claim, and half of it is a guess.
    final next = tester.getRect(find.text('Next: Inspection, 14 March'));
    final fuzz = tester.getRect(find.text('in about 6 weeks'));
    expect(fuzz.top, greaterThanOrEqualTo(next.bottom - 0.01));
  });

  testWidgets('CalmAllClear is not CalmEmptyState', (tester) async {
    await pumpApp(
      tester,
      const Center(
        child: CalmAllClear(
          headline: 'Nothing due',
          nextLine: 'Next: 14 March',
        ),
      ),
    );

    // Distinct widgets with distinct art. The all-clear fires on most Home
    // opens; it never renders as a grey icon in a box, and it never gets a
    // filled call to action, because there is nothing to do.
    expect(find.byType(CalmEmptyState), findsNothing);
    expect(find.byType(CalmButton), findsNothing);
    expect(
      _decorationOf(tester, CalmAllClear).gradient,
      isA<RadialGradient>(),
    );

    await pumpApp(
      tester,
      Center(
        child: CalmEmptyState(
          icon: Icons.local_gas_station_outlined,
          title: 'No fill-ups yet',
          body: 'Log one at the pump and Odova works out the rest.',
          action: CalmButton(label: 'Log a fill-up', onPressed: () {}),
        ),
      ),
    );
    expect(find.byType(CalmAllClear), findsNothing);
    expect(
      _decorationOf(tester, CalmEmptyState).color,
      calmColorsLight.surface2,
    );
  });

  testWidgets('CalmEmptyState renders icon, title, a capped body and a '
      'centred 52pt action', (tester) async {
    await pumpApp(
      tester,
      Center(
        child: CalmEmptyState(
          icon: Icons.local_gas_station_outlined,
          title: 'No fill-ups yet',
          body:
              'Log one at the pump and Odova works out the rest of it for '
              'you, every month, forever.',
          action: CalmButton(label: 'Log a fill-up', onPressed: () {}),
        ),
      ),
    );

    expect(find.byIcon(Icons.local_gas_station_outlined), findsOneWidget);
    expect(find.text('No fill-ups yet'), findsOneWidget);

    // `.empty__text` caps at 28ch — a max width, never a FittedBox and never
    // an ellipsis.
    final body = tester.getSize(
      find.text(
        'Log one at the pump and Odova works out the rest of it for you, '
        'every month, forever.',
      ),
    );
    expect(body.width, lessThanOrEqualTo(kCalmEmptyStateBodyWidth + 0.01));
    expect(find.byType(FittedBox), findsNothing);

    expect(
      tester.getSize(find.byType(CalmButton)).height,
      greaterThanOrEqualTo(calmSpace.touchMin),
    );
  });

  testWidgets('the mark is decorative and the headline is the heading', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      const Center(
        child: CalmAllClear(
          headline: 'Nothing due',
          nextLine: 'Next: 14 March',
        ),
      ),
    );

    // A screen reader hears the sentence, not "image, image". The mark adds
    // no node of its own, so looking it up lands on the card's node — which is
    // exactly the assertion, stated as an identity rather than as a list of
    // flags nobody reads.
    expect(
      tester.getSemantics(find.byType(CalmAllClearMark)),
      same(tester.getSemantics(find.byType(CalmAllClear))),
    );
    expect(
      tester.getSemantics(find.text('Nothing due')),
      matchesSemantics(label: 'Nothing due', isHeader: true),
    );

    handle.dispose();
  });
}
