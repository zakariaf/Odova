// No modal in this app can lose a user's typing silently, and the dialog that
// guarantees it exists exactly once.
//
// SPEC.md §7's two rules that hold everywhere: dismissing a dirty modal opens
// this; dismissing a clean one is silent. The body NAMES what would be lost,
// because "you have unsaved changes" is not a question anyone can answer —
// the user has to know whether the thing they are about to throw away is worth
// the tap they would spend keeping it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/dialogs/discard_dialog.dart';

import '../../support/pump_app.dart';
import '../../support/source_tree.dart';

void main() {
  testWidgets('the title reads "Discard changes?"', (tester) async {
    await pumpApp(tester, const _Opener());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
  });

  testWidgets('the body names what would be lost', (tester) async {
    // The reference's sentence, with the caller's two halves interpolated. A
    // generic "you have unsaved changes" is not what it says and is not what
    // makes the decision answerable.
    await pumpApp(tester, const _Opener());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      visibleText(tester, 'Your edits to'),
      'Your edits to Oil and filter — a 15,000 km interval and a new '
      'baseline — have not been saved.',
    );
  });

  testWidgets('Keep editing sits ABOVE Discard', (tester) async {
    // The reference orders the actions safe-first. `calm-components` said
    // "destructive first, Cancel last"; the reference is the authority
    // (`calm-visual-parity` rule 1) and §7's "no dialog is ever dismissed into
    // a destructive outcome" points the same way. The skill is amended in this
    // PR (finding F-8.4).
    await pumpApp(tester, const _Opener());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    Rect boxFor(String label) => tester.getRect(
      find.ancestor(of: find.text(label), matching: find.byType(CalmButton)),
    );

    final keep = boxFor('Keep editing');
    final discard = boxFor('Discard');
    expect(keep.top, lessThan(discard.top));
    // Stacked and full width, not side by side: a row of two puts the
    // destructive action under the thumb that was reaching for the other one.
    expect(keep.left, closeTo(discard.left, 0.5));
    expect(keep.width, closeTo(discard.width, 0.5));
  });

  testWidgets('Discard returns discard; Keep editing returns keep', (
    tester,
  ) async {
    for (final (label, expected) in [
      ('Discard', DiscardChoice.discard),
      ('Keep editing', DiscardChoice.keep),
    ]) {
      final probe = _ChoiceProbe();
      await pumpApp(tester, probe.widget);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(probe.choice, expected, reason: label);
    }
  });

  testWidgets('tap-out returns keep', (tester) async {
    // §7: tap-outside and system back are ALWAYS the negative action.
    // `showDialog`'s null is mapped explicitly rather than falling through to
    // whatever the enum's first member happens to be.
    final probe = _ChoiceProbe();
    await pumpApp(tester, probe.widget);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(probe.choice, DiscardChoice.keep);
  });

  testWidgets('system back returns keep', (tester) async {
    final probe = _ChoiceProbe();
    await pumpApp(tester, probe.widget);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await systemBack();
    await tester.pumpAndSettle();

    expect(probe.choice, DiscardChoice.keep);
  });

  testWidgets('Keep editing restores focus to the field that had it', (
    tester,
  ) async {
    // Otherwise the user says "keep editing" and lands on a form with no
    // cursor and no keyboard, one tap from the dismissal they just refused.
    final probe = _ChoiceProbe(withField: true);
    await pumpApp(tester, probe.widget);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(probe.fieldHasFocus, isTrue);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(probe.fieldHasFocus, isFalse, reason: 'the dialog took focus');

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    expect(probe.fieldHasFocus, isTrue);
  });

  testWidgets('both action labels come from the ARB, in RTL too', (
    tester,
  ) async {
    await pumpApp(tester, const _Opener(), locale: const Locale('fa'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.text('open')),
    );
    expect(find.text(l10n.discardKeepEditing), findsOneWidget);
    expect(find.text(l10n.discardDiscard), findsOneWidget);
    expect(find.text('Keep editing'), findsNothing);
  });

  test('it is one shared widget', () {
    // A second discard dialog in a feature is a second answer to "what happens
    // to your typing", and the two will disagree.
    final offenders = <String>[];
    for (final file in dartFilesUnder('lib')) {
      if (file.path == 'lib/ui/dialogs/discard_dialog.dart') continue;
      if (RegExp(
        'showDiscardDialog|DiscardChoice',
      ).hasMatch(sourceWithoutLineComments(file))) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('the four strings are in all six ARB files', () {
    expect(
      missingArbKeys([
        'discardTitle',
        'discardBody',
        'discardKeepEditing',
        'discardDiscard',
      ]),
      isEmpty,
    );
  });
}

/// A screen with a button that opens the dialog, and a record of the answer.
class _ChoiceProbe {
  _ChoiceProbe({this.withField = false});

  /// Whether the screen has a focusable field for the focus-restoration test.
  final bool withField;

  /// What the dialog answered, or null before it has.
  DiscardChoice? choice;

  final FocusNode _field = FocusNode(debugLabel: 'field');

  /// Whether the form field currently holds focus.
  bool get fieldHasFocus => _field.hasFocus;

  late final Widget widget = _Opener(
    onChoice: (value) => choice = value,
    field: withField ? _field : null,
  );
}

/// The caller: a button that opens the dialog, and an optional field.
class _Opener extends StatelessWidget {
  const _Opener({this.onChoice, this.field});

  final ValueChanged<DiscardChoice?>? onChoice;
  final FocusNode? field;

  @override
  Widget build(BuildContext context) => Material(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (field != null) TextField(focusNode: field),
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              // The caller captures focus BEFORE opening and restores it after,
              // which is where that responsibility belongs: the dialog does not
              // know what had focus and must not guess.
              final restore = FocusManager.instance.primaryFocus;
              final choice = await showDiscardDialog(
                context,
                subject: 'Oil and filter',
                summary: 'a 15,000 km interval and a new baseline',
              );
              onChoice?.call(choice);
              if (choice == DiscardChoice.keep) restore?.requestFocus();
            },
            child: const Text('open'),
          ),
        ),
      ],
    ),
  );
}

/// The one visible string containing [needle], with bidi controls removed.
///
/// The dialogs wrap the user's own words in first-strong isolates — SPEC.md §2
/// — so asserting the raw string would be asserting U+2068 in the middle of an
/// English sentence.
String visibleText(WidgetTester tester, String needle) => stripBidi(
  tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .firstWhere((s) => stripBidi(s).contains(needle)),
);
