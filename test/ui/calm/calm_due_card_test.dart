// CalmDueCard — the answer to "what does my car need next?".
//
// Every colour, word and silhouette arrives through CalmStatusStyle. The card
// contains no switch over DueState and reads no status colour slot, so the day
// somebody decides `needsOdometer` should look "a bit more urgent" there is
// exactly one file to change and one test to argue with.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_due_card.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';

import '../../support/calm_finders.dart';
import '../../support/pump_app.dart';

CalmDueView _view({
  DueState state = DueState.due,
  DueConfidence confidence = DueConfidence.measured,
  String title = 'Oil change',
  String statusLine = 'Due now',
  String? anchorLine = 'Was due at 186,512 km',
  String? snoozeLine,
  double? progress = 0.7,
}) => CalmDueView(
  state: state,
  driver: DueDriver.distance,
  confidence: confidence,
  title: title,
  statusLine: statusLine,
  actionLabel: 'Log it',
  anchorLine: anchorLine,
  snoozeLine: snoozeLine,
  progress: progress,
);

Widget _card({
  CalmDueView? view,
  CalmDueDensity density = CalmDueDensity.primary,
}) => Center(
  child: CalmDueCard(
    view: view ?? _view(),
    density: density,
    onTap: () {},
    onAction: () {},
  ),
);

BoxDecoration _decoration(WidgetTester tester) =>
    calmDecorationOf<BoxDecoration>(tester, find.byType(CalmDueCard));

void main() {
  testWidgets('the primary density is radius3xl on elev2 with a gradient, and '
      'the secondary is radiusXl on elev1', (tester) async {
    await pumpApp(tester, _card());

    final primary = _decoration(tester);
    expect(
      primary.borderRadius,
      BorderRadius.circular(calmShapesLight.radius3xl),
    );
    expect(primary.boxShadow, calmShapesLight.elev2);
    final gradient = primary.gradient! as LinearGradient;
    expect(
      gradient.colors.first,
      CalmStatusStyle.resolve(calmColorsLight, DueState.due).tint,
    );
    expect(gradient.colors.last, calmColorsLight.surface);

    await pumpApp(tester, _card(density: CalmDueDensity.secondary));
    final secondary = _decoration(tester);
    expect(
      secondary.borderRadius,
      BorderRadius.circular(calmShapesLight.radiusXl),
    );
    expect(secondary.boxShadow, calmShapesLight.elev1);
    expect(secondary.gradient, isNull);
    expect(secondary.color, calmColorsLight.surface);
    expect(
      tester.getSize(find.byType(CalmDueCard)).height,
      greaterThanOrEqualTo(calmSpace.touchMin),
    );
  });

  testWidgets('all six DueStates render, each resolving through '
      'CalmStatusStyle', (tester) async {
    for (final state in DueState.values) {
      await pumpApp(tester, _card(view: _view(state: state)));

      final style = CalmStatusStyle.resolve(calmColorsLight, state);
      // Fails the moment `needsOdometer` borrows terracotta.
      expect(
        (_decoration(tester).gradient! as LinearGradient).colors.first,
        style.tint,
        reason: state.name,
      );
      expect(
        tester.widget<Text>(find.text('Due now')).style!.color,
        style.ink,
        reason: state.name,
      );
    }
  });

  testWidgets('every card renders the dot AND the word', (tester) async {
    for (final state in DueState.values) {
      await pumpApp(tester, _card(view: _view(state: state)));

      // Three signals. A dot with no word is invisible in grayscale, and
      // Calm's six state hues sit within 1.51:1 of one another.
      final dot = tester.widget<CalmStatusDot>(find.byType(CalmStatusDot));
      expect(
        dot.style.mark,
        CalmStatusStyle.resolve(calmColorsLight, state).mark,
        reason: state.name,
      );
      expect(find.text('Due now'), findsOneWidget, reason: state.name);
      expect(find.text('Oil change'), findsOneWidget, reason: state.name);
    }
  });

  testWidgets('DueConfidence.defaulted renders no date and no figure', (
    tester,
  ) async {
    await pumpApp(
      tester,
      _card(
        view: _view(
          state: DueState.unknown,
          confidence: DueConfidence.defaulted,
          statusLine: 'Odova needs a reading to work this out',
          anchorLine: null,
          progress: null,
        ),
      ),
    );

    // SPEC.md §1: the app would rather show a dash than a plausible lie. A
    // progress bar is a figure, and there is no figure here to draw.
    expect(find.byType(CalmProgressBar), findsNothing);
    expect(find.text('Was due at 186,512 km'), findsNothing);
    expect(find.text('Odova needs a reading to work this out'), findsOneWidget);
  });

  testWidgets('an estimated figure keeps its ~ inside the visible title', (
    tester,
  ) async {
    // There is no estimate FLAG by design: the `~` lives in the formatted
    // string, so it survives a grayscale golden and an RTL mirror without the
    // widget ever concatenating it onto the wrong side of the digits.
    await pumpApp(
      tester,
      _card(view: _view(statusLine: 'Due in ~900 km')),
    );
    expect(find.text('Due in ~900 km'), findsOneWidget);
  });

  testWidgets('a snoozed item keeps its state and its colour and gains a '
      'fourth line', (tester) async {
    await pumpApp(
      tester,
      _card(
        view: _view(
          state: DueState.overdue,
          snoozeLine: 'Snoozed until 12 October',
        ),
      ),
    );

    final style = CalmStatusStyle.resolve(calmColorsLight, DueState.overdue);
    // Snoozing suppresses the notification, not the truth.
    expect(
      (_decoration(tester).gradient! as LinearGradient).colors.first,
      style.tint,
    );
    expect(
      tester.widget<Text>(find.text('Snoozed until 12 October')).style!.color,
      style.ink,
    );
  });

  testWidgets('the progress fill animates over motion.slow and fills toward '
      'the end edge', (tester) async {
    for (final (locale, mirrored) in [('en', false), ('fa', true)]) {
      await pumpApp(
        tester,
        _card(view: _view()),
        locale: Locale(locale),
      );

      final bar = tester.widget<CalmProgressBar>(find.byType(CalmProgressBar));
      expect(bar.duration, calmMotion.slow, reason: locale);
      expect(bar.curve, calmMotion.easeStandard, reason: locale);

      final track = tester.getRect(find.byType(CalmProgressBar));
      // The ColoredBox INSIDE the FractionallySizedBox is the fill — the
      // fractional box itself spans the whole track and positions the fill
      // within it. A public CalmProgressFill widget existed only to give this
      // line a `find.byType`, which is a public API for a test handle.
      final fill = tester.getRect(
        find.descendant(
          of: find.byType(FractionallySizedBox),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(fill.width, closeTo(track.width * 0.7, 0.5), reason: locale);
      if (mirrored) {
        // Right to left, from the start edge, which is the right one.
        expect(fill.right, closeTo(track.right, 0.5), reason: locale);
      } else {
        expect(fill.left, closeTo(track.left, 0.5), reason: locale);
      }
    }
  });

  testWidgets('the action button takes the state colour, not the brand', (
    tester,
  ) async {
    await pumpApp(tester, _card(view: _view(state: DueState.overdue)));

    final button = tester.widget<CalmButton>(find.byType(CalmButton));
    expect(button.variant, CalmButtonVariant.onState);
    expect(button.dueState, DueState.overdue);
  });

  testWidgets('a card is one semantics node carrying its title and status', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, _card());

    final node = tester.getSemantics(find.byType(CalmDueCard));
    expect(node.label, 'Oil change');
    expect(node.value, 'Due now');

    handle.dispose();
  });
}
