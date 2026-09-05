// Every destructive action in the app is guarded by one dialog that names
// exactly what dies.
//
// SPEC.md §2: delete is immediate, with Undo in the moment — no trash, no bin.
// So this dialog is the only place the SIZE of the loss is stated, which is why
// the count is in the title and the five per-type counts are one sentence
// rather than a list nobody reads.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/vehicles/delete_counts.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/dialogs/confirm_delete_dialog.dart';

import '../../support/device.dart';
import '../../support/pump_app.dart';
import '../../support/source_tree.dart';

const DeleteCounts _golfCounts = (
  fillUps: 96,
  services: 14,
  costs: 22,
  trips: 8,
  reminders: 16,
);
const DeleteCounts _empty = (
  fillUps: 0,
  services: 0,
  costs: 0,
  trips: 0,
  reminders: 0,
);

void main() {
  testWidgets('the title names the subject and its entry count', (
    tester,
  ) async {
    final probe = _Probe(counts: _golfCounts);
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    // Stripped of bidi controls before comparing: the subject travels in a
    // first-strong isolate, and asserting the raw string would be asserting
    // U+2068 in the middle of an English sentence.
    expect(
      _visible(tester, contains: 'entries?'),
      'Delete The Golf and its 140 entries?',
    );
  });

  testWidgets('the total is the sum, and no caller can disagree with it', (
    tester,
  ) async {
    // 96 + 14 + 22 + 8. `DeleteCounts` has no `total` field to pass, so a
    // dialog that said 412 while its body added to 140 is not expressible.
    expect(_golfCounts.total, 140);
    expect(_empty.total, 0);
  });

  testWidgets('a vehicle with only its seeded reminders has no entries', (
    tester,
  ) async {
    // An ENTRY is something the user entered. Reminders are not: SPEC.md
    // §4.8.3 seeds a set on every vehicle at creation, so counting them would
    // make §8's "Zero entries: one-tap Delete" unreachable — every car ever
    // created would demand its own name typed back before it could go, twenty
    // seconds after it was added by mistake.
    //
    // They are still named in the body, because they are still destroyed.
    const seededOnly = (
      fillUps: 0,
      services: 0,
      costs: 0,
      trips: 0,
      reminders: 8,
    );
    expect(seededOnly.total, 0);

    final probe = _Probe(counts: seededOnly);
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(find.byType(CalmField), findsNothing, reason: 'nothing to lose');
    expect(_enabled(tester, 'Delete'), isTrue);
    // 'Golf', not 'Delete The Golf': the subject travels in a first-strong
    // isolate, so U+2068 sits between the two halves of the raw string.
    expect(_visible(tester, contains: 'Golf'), 'Delete The Golf?');
    expect(
      _visible(tester, contains: 'reminders'),
      'No fill-ups, no services, no costs, no trips and 8 reminders go '
      'permanently.',
    );
  });

  testWidgets('a zero-count title claims no history the car does not have', (
    tester,
  ) async {
    // "Delete The Golf and its entries?" sat directly above "No fill-ups, no
    // services, no costs, no trips and no reminders go permanently." — two
    // sentences contradicting each other, and the first stating a history that
    // does not exist. SPEC.md §1: never guess in a way that looks like fact.
    final probe = _Probe(counts: _empty);
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(visibleText(tester, 'Delete The Golf'), 'Delete The Golf?');
  });

  testWidgets('the body names all five per-type counts in one sentence', (
    tester,
  ) async {
    final probe = _Probe(counts: _golfCounts);
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(
      find.text(
        '96 fill-ups, 14 services, 22 costs, 8 trips and 16 reminders go '
        'permanently.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a zero count reads as a word, never as "0 trips"', (
    tester,
  ) async {
    final probe = _Probe(
      counts: (fillUps: 1, services: 0, costs: 0, trips: 0, reminders: 0),
    );
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(
      find.text(
        '1 fill-up, no services, no costs, no trips and no reminders go '
        'permanently.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('zero entries gives a one-tap Delete with no typed field', (
    tester,
  ) async {
    // ABSENT, not disabled. A lock on a door with nothing behind it is
    // ceremony, and SPEC.md §8 asks for the confirmation only when there is
    // something to lose.
    final probe = _Probe(counts: _empty);
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(find.byType(CalmField), findsNothing);
    expect(_enabled(tester, 'Delete'), isTrue);
  });

  testWidgets('one or more entries requires typing the subject name', (
    tester,
  ) async {
    final probe = _Probe(counts: _golfCounts);
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(find.byType(CalmField), findsOneWidget);
    expect(_enabled(tester, 'Delete'), isFalse, reason: 'empty field');

    await tester.enterText(find.byType(TextField), 'The Gol');
    await tester.pumpAndSettle();
    expect(_enabled(tester, 'Delete'), isFalse, reason: 'a near miss');

    await tester.enterText(find.byType(TextField), 'The Golf');
    await tester.pumpAndSettle();
    expect(_enabled(tester, 'Delete'), isTrue);
  });

  testWidgets('the typed name is compared after digit normalisation', (
    tester,
  ) async {
    // A vehicle called "Golf 2019" typed on a Persian keyboard arrives as
    // "Golf ۲۰۱۹". Comparing the raw strings locks the user out of deleting
    // their own car over a numbering system they did not choose.
    final probe = _Probe(counts: _golfCounts, subject: 'Golf 2019');
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    await tester.enterText(find.byType(TextField), 'Golf ۲۰۱۹');
    await tester.pumpAndSettle();

    expect(_enabled(tester, 'Delete'), isTrue);
  });

  testWidgets('an EMPTY subject never satisfies the lock', (tester) async {
    // A vehicle can be named "". `vehicles.name` carries no non-empty CHECK,
    // and SPEC.md §2's import REPLACES — so a backup with an empty name
    // restores one. Comparing two empty strings left Delete enabled the instant
    // the dialog opened, and one tap destroyed 412 entries behind a
    // confirmation that had confirmed nothing.
    final probe = _Probe(counts: _golfCounts, subject: '');
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(_enabled(tester, 'Delete'), isFalse, reason: 'opened unlocked');

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(_enabled(tester, 'Delete'), isFalse, reason: 'empty matched empty');

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pumpAndSettle();
    expect(_enabled(tester, 'Delete'), isFalse, reason: 'whitespace matched');
  });

  testWidgets('a name carrying a bidi control is still deletable', (
    tester,
  ) async {
    // An imported name can carry an invisible U+200F. No soft keyboard can
    // reproduce one, so comparing the raw strings left Delete permanently
    // disabled and the vehicle permanently undeletable — there is no other
    // route to removing it. `lib/core/l10n/bidi.dart` says `stripBidi` is what
    // goes into anything compared, and this is a comparison.
    final probe = _Probe(counts: _golfCounts, subject: 'گلف\u200F');
    await pumpApp(tester, probe.widget, locale: const Locale('fa'));
    await probe.open(tester);

    await tester.enterText(find.byType(TextField), 'گلف');
    await tester.pumpAndSettle();

    expect(_enabled(tester, l10nOf(tester).confirmDeleteDelete), isTrue);
  });

  testWidgets('a subject that changes while mounted re-locks the button', (
    tester,
  ) async {
    // `ConfirmDeleteDialogBody` is public and its own doc invites composing it
    // outside a route — the parity harness already does. Its normalised and
    // isolated subject are cached for the keystroke path, and without
    // `didUpdateWidget` the cache outlived the input: the title and placeholder
    // updated to the new car while the field's label still named the old one,
    // and typing the OLD name unlocked a button that deleted the NEW one.
    final subject = ValueNotifier<String>('The Golf');
    addTearDown(subject.dispose);

    await pumpApp(
      tester,
      ValueListenableBuilder<String>(
        valueListenable: subject,
        builder: (context, value, _) => ConfirmDeleteDialogBody(
          subject: value,
          counts: _golfCounts,
          formatCount: (n) => '$n',
          onChoice: (_) {},
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'The Golf');
    await tester.pumpAndSettle();
    expect(_enabled(tester, 'Delete'), isTrue);

    subject.value = 'The Polo';
    await tester.pumpAndSettle();

    expect(
      _enabled(tester, 'Delete'),
      isFalse,
      reason: 'the old name still unlocks the new car',
    );

    await tester.enterText(find.byType(TextField), 'The Polo');
    await tester.pumpAndSettle();
    expect(_enabled(tester, 'Delete'), isTrue);
  });

  testWidgets('the safe alternative sits above Delete', (tester) async {
    // "Keep it — mark it sold" is usually what people mean, so it is offered
    // first. A caller with no alternative gets two actions, not a stub.
    final probe = _Probe(
      counts: _golfCounts,
      alternative: 'Keep it — mark it sold',
    );
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    // `.first` on Delete: the disabled button's explanation repeats the
    // field's label, so "Delete" is the only unambiguous one of the three.
    final alternative = _boxFor(tester, 'Keep it — mark it sold');
    final delete = _boxFor(tester, 'Delete');
    final cancel = _boxFor(tester, 'Cancel');
    expect(alternative.top, lessThan(delete.top));
    expect(delete.top, lessThan(cancel.top));
  });

  testWidgets('a caller with no alternative gets two actions, not a stub', (
    tester,
  ) async {
    final probe = _Probe(counts: _golfCounts);
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(find.byType(CalmButton), findsNWidgets(2));
  });

  testWidgets('each action returns its own outcome', (tester) async {
    for (final (label, expected) in [
      ('Keep it — mark it sold', ConfirmDeleteChoice.safeAlternative),
      ('Cancel', ConfirmDeleteChoice.cancel),
    ]) {
      final probe = _Probe(
        counts: _empty,
        alternative: 'Keep it — mark it sold',
      );
      await pumpApp(tester, probe.widget);
      await probe.open(tester);

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(probe.choice, expected, reason: label);
    }
  });

  testWidgets('tap-out and system back both return cancel', (tester) async {
    // No dialog is ever dismissed into a destructive outcome, and `showDialog`
    // returning null is mapped explicitly rather than falling through to the
    // enum's first member — which here is `delete`.
    for (final dismiss in ['tap-out', 'back']) {
      final probe = _Probe(counts: _empty);
      await pumpApp(tester, probe.widget);
      await probe.open(tester);

      if (dismiss == 'tap-out') {
        await tester.tapAt(const Offset(8, 8));
      } else {
        await systemBack();
      }
      await tester.pumpAndSettle();

      expect(probe.choice, ConfirmDeleteChoice.cancel, reason: dismiss);
    }
  });

  testWidgets('the subject is wrapped in a first-strong isolate', (
    tester,
  ) async {
    // A vehicle called "The Golf" inside a Persian sentence renders LTR without
    // reordering the sentence around it. §2's bidi rule, and the title is where
    // it breaks first.
    final probe = _Probe(counts: _golfCounts);
    await pumpApp(tester, probe.widget, locale: const Locale('fa'));
    await probe.open(tester);

    final title = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .firstWhere((s) => s.contains('The Golf'));
    expect(title.contains(firstStrongIsolate), isTrue, reason: title);
    expect(title.contains(popDirectionalIsolate), isTrue, reason: title);
    expect(stripBidi(title), contains('The Golf'));
  });

  testWidgets('three stacked actions survive 200% German and Sorani', (
    tester,
  ) async {
    // The parity tool shoots at scale 1 and cannot see this. SPEC.md §17 allows
    // zero glyph clipping at 200%, and this dialog is the app's tallest: a
    // safe alternative, a typed-confirmation field, its explanation, Delete and
    // Cancel. `CalmDialog` scrolls rather than clipping — the version before
    // this test overflowed by 35 pixels at scale 1.
    // `Device.compact` — the tightest surface Odova supports, per
    // `test/support/device.dart`. Written by hand it said "the smallest phone"
    // beside 750x1334, which is not the smallest phone the preset names.
    tester.useDevice(Device.compact);

    for (final locale in [const Locale('de'), const Locale('ckb')]) {
      final probe = _Probe(
        counts: _golfCounts,
        alternative: 'Behalten — als verkauft markieren',
      );
      await pumpApp(
        tester,
        probe.widget,
        locale: locale,
        textScaler: const TextScaler.linear(2),
      );
      await probe.open(tester);

      expect(
        tester.takeException(),
        isNull,
        reason: '${locale.languageCode} overflowed at 200%',
      );
      // All THREE actions, counted. `findsWidgets` means "at least one", so it
      // passed against a build that dropped the safe alternative at large text
      // scales "to make it fit" — losing the action a user most often wants,
      // silently, on exactly the configuration this test is named for.
      expect(find.byType(CalmButton), findsNWidgets(3));
    }
  });

  test('it is one shared widget, and only listed screens call it', () {
    // A second confirm-delete dialog in a feature is a second answer to "what
    // exactly am I destroying", and the two will disagree about the counts.
    //
    // **An ALLOW-LIST, because the first version forbade too much** — the same
    // correction `discard_dialog_test.dart` already carries, and for the same
    // reason. Banning the symbols outright was right while nothing called them
    // and wrong the moment a screen did: EPIC-09 task 9.6 says in so many words
    // that the garage's "Delete calls **EPIC-08 task 8.9's
    // `showConfirmDeleteDialog`**". The rule was never "nobody may call it"; it
    // was "nobody may write a second one", and those are only the same test
    // while the caller count is zero.
    //
    // Every screen that destroys a whole record earns a line here, and adding
    // one is a moment where somebody says what their screen deletes.
    const callers = {
      // §8's garage: the row swipe and the row overflow both land here, and
      // this is the only screen in v1 that deletes a VEHICLE.
      'lib/features/vehicles/presentation/vehicles_screen.dart',
    };

    final offenders = <String>[];
    for (final file in dartFilesUnder('lib')) {
      if (file.path == 'lib/ui/dialogs/confirm_delete_dialog.dart') continue;
      final source = sourceWithoutLineComments(file);
      // DEFINING a second one stays banned outright, from everywhere. A
      // DECLARATION, not a mention: `ConfirmDeleteChoice.delete` in a caller is
      // reading the shared answer, which is the whole point of sharing it.
      if (RegExp(
        r'(class|enum)\s+\w*ConfirmDelete\w*\b|'
        r'Future<\w*ConfirmDeleteChoice\w*>\s+show\w*Delete',
      ).hasMatch(source)) {
        offenders.add(
          '${file.path}: declares a confirm-delete dialog of its own',
        );
        continue;
      }
      if (RegExp('showConfirmDeleteDialog').hasMatch(source) &&
          !callers.contains(file.path)) {
        offenders.add('${file.path}: calls showConfirmDeleteDialog, unlisted');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('every string is in all six ARB files', () {
    expect(
      missingArbKeys([
        'confirmDeleteTitle',
        'confirmDeleteBody',
        'confirmDeleteTypeToConfirm',
        'confirmDeleteDelete',
      ]),
      isEmpty,
    );
  });
}

/// The one visible string containing [needle], with bidi controls removed.
String visibleText(WidgetTester tester, String needle) => stripBidi(
  tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .firstWhere((s) => stripBidi(s).contains(needle)),
);

/// The box of the [CalmButton] whose label is [label].
Rect _boxFor(WidgetTester tester, String label) => tester.getRect(
  find.ancestor(of: find.text(label), matching: find.byType(CalmButton)),
);

/// Whether the button labelled [label] can be pressed.
bool _enabled(WidgetTester tester, String label) =>
    tester
        .widget<CalmButton>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(CalmButton),
          ),
        )
        .onPressed !=
    null;

/// A caller with a button, and a record of what came back.
class _Probe {
  _Probe({required this.counts, this.subject = 'The Golf', this.alternative});

  final DeleteCounts counts;
  final String subject;
  final String? alternative;

  /// What the dialog answered.
  ConfirmDeleteChoice? choice;

  late final Widget widget = Builder(
    builder: (context) => Material(
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: TextButton(
          onPressed: () async {
            choice = await showConfirmDeleteDialog(
              context,
              subject: subject,
              counts: counts,
              // Latin digits, because the tests assert English copy. The real
              // caller passes the app's shaped formatter.
              formatCount: (n) => '$n',
              safeAlternativeLabel: alternative,
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );

  /// Taps the button and settles.
  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }
}

/// The one visible string containing [contains], with bidi controls removed.
String _visible(WidgetTester tester, {required String contains}) => stripBidi(
  tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .firstWhere((s) => s.contains(contains)),
);

/// The localisations the pumped app resolved.
AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.text('open')));
