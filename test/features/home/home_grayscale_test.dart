// Home's cards with the colour taken out.
//
// SPEC.md §9: "Status is carried by **three** signals — dot shape, colour,
// wording — never colour alone. Dot shape is normative." Calm's six state hues
// sit within 1.51:1 of each other in luminance, which
// `calm_status_test.dart` measures — so in grayscale the colour signal is gone
// entirely and the other two have to carry the card on their own.
//
// NOT a pixel golden. A golden of six grey cards is green whether or not a
// reader can tell them apart, and "tell them apart" is the whole claim: this
// asserts that the six marks are six geometries and the six status lines are
// six sentences, which is what a person with a monochrome display, a colour
// filter on, or protanopia actually has to work with.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/l10n/due_copy.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/ui/calm/calm_due_card.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';

import '../../support/fonts.dart';
import '../../support/pump_app.dart';
import 'home_fixture.dart';

/// Zero-saturation matrix (ITU-R BT.709 luma).
///
/// The same one `calm_status_test.dart` uses. Two copies of a colour matrix is
/// two chances for one of them to be a filter that only dims.
const ColorFilter _grayscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// The five states SPEC.md §9 puts on a card.
///
/// `ok` is excluded because §9's card table says so — "`ok`, `paused` — **not
/// on Home at all**" — and because it shares `filledLarge` with `overdue`. A
/// set that included it would have to either weaken the distinctness claim or
/// assert something the design deliberately does not promise.
const List<DueState> _onHome = [
  DueState.overdue,
  DueState.due,
  DueState.dueSoon,
  DueState.needsOdometer,
  DueState.unknown,
];

/// One assessment per state, each with something real to say.
DueAssessment _assessmentFor(DueState state) => switch (state) {
  DueState.overdue => homeAssessment(
    state: state,
    remainingDays: -21,
    dueOn: '2026-08-15',
  ),
  DueState.due => homeAssessment(state: state, remainingDays: 0),
  DueState.dueSoon => homeAssessment(
    state: state,
    remainingDays: 21,
    dueOn: '2026-09-26',
  ),
  DueState.needsOdometer => homeAssessment(
    state: state,
    driver: DueDriver.distance,
    remainingDays: null,
    remainingMetres: -4000,
  ),
  DueState.unknown => homeAssessment(
    state: state,
    confidence: RateConfidence.defaulted,
    remainingDays: null,
  ),
  DueState.ok => homeAssessment(state: state, remainingDays: 120),
};

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the six-state card set is identifiable from mark and label with '
      'colour stripped', (tester) async {
    late AppLocalizations l10n;

    await pumpApp(
      tester,
      ColorFiltered(
        colorFilter: _grayscale,
        child: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return ListView(
              children: [
                for (final state in _onHome)
                  CalmDueCard(
                    key: ValueKey(state),
                    view: CalmDueView(
                      state: state,
                      driver: _assessmentFor(state).driver,
                      confidence: _assessmentFor(state).confidence,
                      title: 'Oil and filter',
                      statusLine: dueStatusLine(
                        l10n,
                        'en-GB',
                        _assessmentFor(state),
                        DistanceUnit.km,
                      ),
                      actionLabel: l10n.actionLogIt,
                    ),
                    density: CalmDueDensity.secondary,
                    onTap: () {},
                    onAction: () {},
                  ),
              ],
            );
          },
        ),
      ),
    );

    // Signal 1 — the mark. Five marks, and a mark is not a colour.
    //
    // The key carries opacity as well as geometry, because `unknown` and
    // `needsOdometer` are both 12pt rings 2pt thick and differ only by the
    // 0.7 on the first. That IS a grayscale-visible difference — a fainter
    // ring — but it is the weakest pair in the set, which is why the words
    // below are asserted as a second, independent separation rather than as a
    // nicety.
    final marks = <String>{};
    for (final state in _onHome) {
      final dot = find.descendant(
        of: find.byKey(ValueKey(state)),
        matching: find.byType(CalmStatusDot),
      );
      final style = CalmStatusStyle.resolve(calmColorsLight, state);
      expect(
        tester.getSize(dot),
        Size.square(style.mark.diameter),
        reason: state.name,
      );
      marks.add(
        '${style.mark.diameter}:${style.mark.strokeWidth}:'
        '${style.mark.opacity}',
      );
    }
    expect(
      marks,
      hasLength(_onHome.length),
      reason: 'two states share a mark, so grayscale cannot separate them',
    );

    // Signal 2 — the words. Five sentences, each on screen exactly once.
    final sentences = <String>{};
    for (final state in _onHome) {
      final line = dueStatusLine(
        l10n,
        'en-GB',
        _assessmentFor(state),
        DistanceUnit.km,
      );
      expect(find.text(line), findsOneWidget, reason: state.name);
      sentences.add(line);
    }
    expect(
      sentences,
      hasLength(_onHome.length),
      reason: 'two states say the same thing, so the words carry nothing',
    );
  });
}
