// The three ways Odova interrupts someone.
//
// SPEC.md §10 spends the app's whole interruption budget on one thing: a
// snackbar with Undo. A dialog is paid for on every CORRECT entry, so there
// are exactly three of them, and the snackbar must never cover the + it sits
// above.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_dialog.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_sheet.dart';
import 'package:odova/ui/calm/calm_snackbar.dart';

import '../../support/calm_finders.dart';
import '../../support/pump_app.dart';
import '../../support/source_tree.dart';

/// A screen with one button that opens the overlay under test.
Widget _opener(void Function(BuildContext) open, {String label = 'Open'}) =>
    Builder(
      builder: (context) => CalmScaffold(
        appBar: const CalmAppBar(title: 'Home'),
        children: [
          CalmButton(label: label, onPressed: () => open(context)),
        ],
      ),
    );

ShapeDecoration _decorationOf(WidgetTester tester, Type type) =>
    calmDecorationOf<ShapeDecoration>(tester, find.byType(type));

Future<void> _openSheet(WidgetTester tester) async {
  await pumpApp(
    tester,
    _opener(
      (context) => CalmSheet.show<void>(
        context,
        builder: (_) => const CalmSheet(
          title: 'Choose a category',
          children: [Text('Oil change')],
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
}

void main() {
  testWidgets('the sheet rounds its top two corners logically', (tester) async {
    await _openSheet(tester);
    await tester.pumpAndSettle();

    final shape =
        _decorationOf(tester, CalmSheet).shape as RoundedRectangleBorder;
    expect(
      shape.borderRadius,
      BorderRadiusDirectional.only(
        topStart: Radius.circular(calmShapesLight.radius3xl),
        topEnd: Radius.circular(calmShapesLight.radius3xl),
      ),
    );

    // And the physical names never enter the tree, which is what lets the RTL
    // gate be a grep.
    expectNoBannedPatterns(const {
      'topLeft:': 'a physical corner name; use BorderRadiusDirectional',
      'topRight:': 'a physical corner name; use BorderRadiusDirectional',
      'bottomLeft:': 'a physical corner name; use BorderRadiusDirectional',
      'bottomRight:': 'a physical corner name; use BorderRadiusDirectional',
    });
  });

  testWidgets('the sheet enters with a rise and a fade from 0.6 over '
      'motion.sheet', (tester) async {
    await _openSheet(tester);
    await tester.pump(); // start the route

    final route = ModalRoute.of(
      tester.element(find.byType(CalmSheet)),
    )!;
    expect(route.transitionDuration, calmMotion.sheet);

    // At the first frame the surface sits 24pt low and at 60% — a sheet that
    // fades from nothing reads as a flash rather than as an arrival.
    final opacity = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byType(CalmSheet),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity.opacity, closeTo(kCalmSheetFadeFrom, 0.01));

    final translate = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(CalmSheet),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(
      translate.transform.getTranslation().y,
      closeTo(kCalmSheetRise, 0.5),
    );

    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Opacity>(
            find
                .descendant(
                  of: find.byType(CalmSheet),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      1,
    );
  });

  testWidgets('the sheet exits over motion.base, not over motion.sheet', (
    tester,
  ) async {
    await _openSheet(tester);
    await tester.pumpAndSettle();

    final route = ModalRoute.of(tester.element(find.byType(CalmSheet)))!;
    // Exits are not symmetric: accelerating away is what makes a dismissal
    // feel like a dismissal rather than a rewind.
    expect(route.reverseTransitionDuration, calmMotion.base);
    expect(route.reverseTransitionDuration, lessThan(calmMotion.sheet));
  });

  testWidgets('the scrim and the surface end on the same frame', (
    tester,
  ) async {
    await _openSheet(tester);
    await tester.pumpAndSettle();
    // The colour claim, asserted once at rest. It cannot be the timing probe:
    // ModalBottomSheetRoute's barrier is an AnimatedModalBarrier whose colour
    // tweens from transparent, so "is it the scrim colour" reads false the
    // moment the exit starts — while the barrier is very much still there.
    expect(
      tester
          .widgetList<ModalBarrier>(find.byType(ModalBarrier))
          .map((b) => b.color),
      contains(calmColorsLight.scrim),
    );

    // What matters is what the user SEES, so the probe is the barrier's
    // painted alpha rather than its presence in the tree: the route's barrier
    // element is torn down a frame after the surface, at alpha 0, which is
    // invisible and harmless.
    double scrimAlpha() => tester
        .widgetList<ModalBarrier>(find.byType(ModalBarrier))
        .map((b) => b.color?.a ?? 0.0)
        .fold(0, (a, b) => b > a ? b : a);
    bool sheetIsUp() => find.byType(CalmSheet).evaluate().isNotEmpty;

    Navigator.of(tester.element(find.byType(CalmSheet))).pop();

    // Step frame by frame to the end of the exit. Neither may outlast the
    // other visibly: a scrim that lingers dims an empty screen, and a scrim
    // that clears early shows the page through a sheet still on it.
    var frames = 0;
    while (sheetIsUp() || scrimAlpha() > 0) {
      expect(
        sheetIsUp() || scrimAlpha() == 0,
        isTrue,
        reason: 'a visible scrim over no sheet, at frame $frames',
      );
      // The converse, stated in terms of what is on screen rather than what
      // is in the tree: once the scrim has cleared, the surface may still
      // exist for a frame or two, but it must already be off the viewport.
      if (scrimAlpha() == 0 && sheetIsUp()) {
        expect(
          tester.getRect(find.byType(CalmSheet)).top,
          greaterThanOrEqualTo(
            tester.getRect(find.byType(MaterialApp)).bottom - 0.5,
          ),
          reason: 'a sheet still on screen with no scrim, at frame $frames',
        );
      }
      await tester.pump(const Duration(milliseconds: 16));
      expect(++frames, lessThan(120), reason: 'the exit never finished');
    }
  });

  testWidgets('every overlay animation collapses to zero under '
      'disableAnimations', (tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: true),
          child: _opener(
            (context) => CalmSheet.show<void>(
              context,
              builder: (_) => const CalmSheet(
                title: 'Choose a category',
                children: [Text('Oil change')],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();

    // The sheet APPEARS. It does not slide. A shorter animation is not the
    // same answer as no animation.
    final route = ModalRoute.of(tester.element(find.byType(CalmSheet)))!;
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
  });

  testWidgets('CalmSheet.show pins isScrollControlled, a transparent '
      'background, the barrier colour and useSafeArea', (tester) async {
    await _openSheet(tester);
    await tester.pumpAndSettle();

    final route =
        ModalRoute.of(tester.element(find.byType(CalmSheet)))!
            as ModalBottomSheetRoute<void>;

    // None of these is a decision a feature re-makes.
    expect(route.isScrollControlled, isTrue);
    expect(route.backgroundColor, Colors.transparent);
    expect(route.barrierColor, calmColorsLight.scrim);
    expect(route.useSafeArea, isTrue);
  });

  testWidgets('dialog actions are stacked, full-width and >=52, destructive '
      'first and Cancel last', (tester) async {
    await pumpApp(
      tester,
      _opener(
        (context) => CalmDialog.show<void>(
          context,
          builder: (_) => CalmDialog(
            title: 'Delete this fill-up?',
            body: '42.8 L on 12 March. This cannot be undone.',
            confirmLabel: 'Delete',
            onConfirm: () {},
            cancelLabel: 'Keep it',
            onCancel: () {},
            danger: true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    Rect buttonFor(String label) => tester.getRect(
      find.ancestor(of: find.text(label), matching: find.byType(CalmButton)),
    );

    // The BUTTONS, not their labels: the labels are centred, so their left
    // edges differ by half the difference in word length and say nothing.
    final confirm = buttonFor('Delete');
    final cancel = buttonFor('Keep it');
    // Stacked, not side by side: a row of two puts the destructive action
    // under the thumb that was reaching for Cancel.
    expect(confirm.top, lessThan(cancel.top));
    expect(confirm.left, closeTo(cancel.left, 0.5));
    expect(confirm.width, closeTo(cancel.width, 0.5));

    for (final label in ['Delete', 'Keep it']) {
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byType(CalmButton),
      );
      expect(
        tester.getSize(button).height,
        greaterThanOrEqualTo(calmSpace.touchMin),
        reason: label,
      );
    }
    // Full width: both buttons span the dialog's content box.
    expect(
      tester
          .getSize(
            find.ancestor(
              of: find.text('Delete'),
              matching: find.byType(CalmButton),
            ),
          )
          .width,
      closeTo(
        tester
            .getSize(
              find.ancestor(
                of: find.text('Keep it'),
                matching: find.byType(CalmButton),
              ),
            )
            .width,
        0.5,
      ),
    );
  });

  testWidgets('dialog text is start-aligned, not centred', (tester) async {
    await pumpApp(
      tester,
      _opener(
        (context) => CalmDialog.show<void>(
          context,
          builder: (_) => CalmDialog(
            title: 'Delete this fill-up?',
            body: '42.8 L on 12 March. This cannot be undone.',
            confirmLabel: 'Delete',
            onConfirm: () {},
            cancelLabel: 'Keep it',
            onCancel: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Centred body copy is unreadable at Sorani line lengths.
    for (final text in [
      'Delete this fill-up?',
      '42.8 L on 12 March. This cannot be undone.',
    ]) {
      expect(
        tester.widget<Text>(find.text(text)).textAlign,
        TextAlign.start,
        reason: text,
      );
    }
  });

  testWidgets('the snackbar sits above the tab bar and the home indicator', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          // The home indicator, as the design assumes it.
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.only(bottom: calmSpace.homebarH),
          ),
          child: _opener(
            (context) => CalmSnackbar.show(
              context,
              message: 'Fill-up saved',
              actionLabel: 'Undo',
              onAction: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final bar = tester.getRect(find.byType(CalmSnackbar));
    final screen = tester.getRect(find.byType(MaterialApp));
    // It must never cover the +.
    expect(
      screen.bottom - bar.bottom,
      closeTo(calmSpace.tabbarH + calmSpace.homebarH + calmSpace.s3, 1),
    );
  });

  testWidgets('the snackbar action renders inkInverse semi, not brand', (
    tester,
  ) async {
    await pumpApp(
      tester,
      _opener(
        (context) => CalmSnackbar.show(
          context,
          message: 'Fill-up saved',
          actionLabel: 'Undo',
          onAction: () {},
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // brand on surfaceInverse is 2.28:1 light and 1.85:1 dark — the action
    // would be the least legible thing on the bar.
    final style = tester.widget<Text>(find.text('Undo')).style!;
    expect(style.color, calmColorsLight.inkInverse);
    expect(style.color, isNot(calmColorsLight.brand));
    expect(style.fontWeight, FontWeight.w600);
  });

  testWidgets('only one snackbar shows at a time', (tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => CalmScaffold(
          appBar: const CalmAppBar(title: 'Home'),
          children: [
            CalmButton(
              label: 'First',
              onPressed: () => CalmSnackbar.show(
                context,
                message: 'Fill-up saved',
                actionLabel: 'Undo',
                onAction: () {},
              ),
            ),
            CalmButton(
              label: 'Second',
              onPressed: () => CalmSnackbar.show(
                context,
                message: 'Service saved',
                actionLabel: 'Undo',
                onAction: () {},
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('First'));
    await tester.pump();
    await tester.tap(find.text('Second'));
    await tester.pumpAndSettle();

    // A second Undo beside the first is two undos with no way to tell which is
    // which.
    expect(find.byType(CalmSnackbar), findsOneWidget);
    expect(find.text('Fill-up saved'), findsNothing);
    expect(find.text('Service saved'), findsOneWidget);
  });
}
