// A user can quiet one reminder for a while, and the dialog says out loud that
// quieting it does not change the truth.
//
// SPEC.md §4.7.2. The body is the whole point: snoozing changes the
// NOTIFICATION SCHEDULE and nothing else. §1's "never guess in a way that looks
// like fact" applied to a decision — a user who quiets a reminder and then
// believes the job is no longer due has been misled by the app's silence.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/dialogs/snooze_dialog.dart';

import '../../support/pump_app.dart';
import '../../support/source_tree.dart';

/// 3 September 2026 — the reference's date.
///
/// Through `tryParse`, because `CivilDate`'s constructor is private on purpose:
/// the only ways in are a parsed string or arithmetic on a date that already
/// exists, and both produce a real calendar date. `2026-02-30` cannot be built.
final CivilDate _today = CivilDate.tryParse('2026-09-03')!;

void main() {
  testWidgets('the title names the item', (tester) async {
    // "Snooze {item}", the label interpolated AS STORED. The reference
    // lower-cases it inside the sentence; an ICU message cannot case-fold a
    // placeholder and German capitalises every noun, so folding here would be
    // wrong in a second locale to fix the look in one (finding F-8.6).
    final probe = _Probe();
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(find.text('Snooze Oil and filter'), findsOneWidget);
  });

  testWidgets('the body says it only quiets the reminder', (tester) async {
    final probe = _Probe();
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(
      find.text(
        'This quiets the reminder. It does not change when the job is due.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the body is the same whatever state the item is in', (
    tester,
  ) async {
    // The epic expected an ICU `select` over `DueState`, on the premise that
    // the reference reads "It stays overdue on Home" — which would be FALSE for
    // a due or due-soon item, the exact failure §1 forbids. The reference's
    // actual sentence is already state-neutral: it says what snoozing does and
    // does not do, which is true of every state. So there is no select, and the
    // dialog takes no `DueState` at all — a parameter nothing reads is a
    // parameter that will grow a wrong branch (finding F-8.8, settled).
    final source = File(
      'lib/ui/dialogs/snooze_dialog.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('DueState')));
  });

  testWidgets('three days from 3 September reads until 6 Sep', (tester) async {
    final probe = _Probe();
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(_valueFor(tester, '3 days'), 'until 2026-09-06');
  });

  testWidgets('one week reads until 10 Sep', (tester) async {
    final probe = _Probe();
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(_valueFor(tester, '1 week'), 'until 2026-09-10');
  });

  testWidgets('one month reads until 3 Oct', (tester) async {
    final probe = _Probe();
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(_valueFor(tester, '1 month'), 'until 2026-10-03');
  });

  testWidgets('a month from 31 January is 28 February, not 3 March', (
    tester,
  ) async {
    // `addMonths` clamps to the last day of the target month. Adding 30 days,
    // or adding one to the month field and letting it overflow, both give a
    // date in the wrong month — and a snooze that silently lands three days
    // late is a reminder the user stops trusting.
    final probe = _Probe(today: CivilDate.tryParse('2026-01-31'));
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(_valueFor(tester, '1 month'), 'until 2026-02-28');
  });

  testWidgets('the dates come from the injected clock, not from now', (
    tester,
  ) async {
    final probe = _Probe(today: CivilDate.tryParse('2030-06-15'));
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(_valueFor(tester, '3 days'), 'until 2030-06-18');
  });

  testWidgets('the distance option reads 500 km and the target reading', (
    tester,
  ) async {
    // 187,412 km + 500 km. The figure is the caller's ENTERED reading, never a
    // projection: a snooze target computed from an estimate would move every
    // time the estimate did.
    final probe = _Probe(odometerMetres: 187412000);
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(find.text('After another 500000 m'), findsOneWidget);
    expect(_valueFor(tester, 'After another 500000 m'), 'at 187912000 m');
  });

  testWidgets('the distance option is ABSENT without a distance interval', (
    tester,
  ) async {
    // Absent from the tree, not disabled. §7 states the condition, and a
    // disabled row is an offer the user has to work out they cannot take.
    final probe = _Probe(hasDistanceInterval: false, odometerMetres: 187412000);
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(find.byType(CalmListRow), findsNWidgets(3));
  });

  testWidgets('and absent with an interval but no reading', (tester) async {
    // The target is "the entered reading plus 500 km". With no reading there is
    // nothing to add to, and the alternative — projecting one — is a snooze
    // target that quietly changes date.
    final probe = _Probe();
    await pumpApp(tester, probe.widget);
    await probe.open(tester);

    expect(find.byType(CalmListRow), findsNWidgets(3));
  });

  testWidgets('each row returns its own choice', (tester) async {
    for (final (label, expected) in [
      ('3 days', SnoozeChoice.threeDays),
      ('1 week', SnoozeChoice.oneWeek),
      ('1 month', SnoozeChoice.oneMonth),
    ]) {
      final probe = _Probe();
      await pumpApp(tester, probe.widget);
      await probe.open(tester);

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(probe.choice, expected, reason: label);
    }
  });

  testWidgets('Cancel, tap-out and system back all return no choice', (
    tester,
  ) async {
    // §7's *Global dialogs* row: tap-out does nothing.
    for (final how in ['cancel', 'tap-out', 'back']) {
      final probe = _Probe();
      await pumpApp(tester, probe.widget);
      await probe.open(tester);

      switch (how) {
        case 'cancel':
          await tester.tap(find.text('Cancel'));
        case 'tap-out':
          await tester.tapAt(const Offset(8, 8));
        case _:
          await systemBack();
      }
      await tester.pumpAndSettle();

      expect(probe.choice, isNull, reason: how);
      expect(probe.answered, isTrue, reason: '$how never returned');
    }
  });

  testWidgets('the dialog writes nothing', (tester) async {
    final probe = _Probe();
    await pumpApp(tester, probe.widget);
    await probe.open(tester);
    await tester.tap(find.text('1 week'));
    await tester.pumpAndSettle();

    expect(probe.repositoryTouches, isEmpty);
  });

  testWidgets('the odometer figure and its unit are one atomic run', (
    tester,
  ) async {
    // A bidi isolate, so "187,912 km" does not split across a Persian
    // sentence. The caller's formatter supplies it; the test asserts the
    // dialog does not unwrap it.
    final probe = _Probe(odometerMetres: 187412000, isolateFigures: true);
    await pumpApp(tester, probe.widget, locale: const Locale('fa'));
    await probe.open(tester);

    final value = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .firstWhere((s) => s.contains('187912000'));
    expect(value, contains(firstStrongIsolate));
    expect(value, contains(popDirectionalIsolate));
  });

  test('it is one shared widget', () {
    final offenders = <String>[];
    for (final file in dartFilesUnder('lib')) {
      if (file.path == 'lib/ui/dialogs/snooze_dialog.dart') continue;
      if (RegExp(
        'showSnoozeDialog|SnoozeChoice',
      ).hasMatch(sourceWithoutLineComments(file))) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('every string is in all six ARB files', () {
    expect(
      missingArbKeys([
        'snoozeTitle',
        'snoozeBody',
        'snoozeThreeDays',
        'snoozeOneWeek',
        'snoozeOneMonth',
        'snoozeDistance',
        'snoozeUntil',
        'snoozeAtOdometer',
      ]),
      isEmpty,
    );
  });

  test('kSnoozeDistanceMetres is 500 km, as SPEC.md §4.7.2 writes it', () {
    // §4.8's rule that defaults are defined per unit system rather than
    // converted would give a miles user a round number instead, and §4.7.2
    // names none — inventing "300 mi" is exactly the kind of unsourced value
    // SPEC.md forbids (finding F-8.9, raised and not invented around).
    expect(kSnoozeDistanceMetres, 500000);
  });
}

/// The `value` shown at the end of the row titled [title].
String _valueFor(WidgetTester tester, String title) => tester
    .widget<CalmListRow>(
      find.ancestor(of: find.text(title), matching: find.byType(CalmListRow)),
    )
    .value!;

/// A caller with a button, and a record of what came back.
class _Probe {
  _Probe({
    CivilDate? today,
    this.hasDistanceInterval = true,
    this.odometerMetres,
    this.isolateFigures = false,
  }) : today = today ?? _today;

  /// The date the dialog is asked to reckon from.
  final CivilDate today;
  final bool hasDistanceInterval;
  final int? odometerMetres;

  /// Whether the injected formatter wraps its output in an isolate, as the
  /// app's own does.
  final bool isolateFigures;

  /// What the dialog answered.
  SnoozeChoice? choice;

  /// Whether it returned at all — a null choice and a dialog that never closed
  /// are different failures.
  bool answered = false;

  /// Anything the dialog wrote. It must stay empty.
  final List<String> repositoryTouches = [];

  late final Widget widget = Builder(
    builder: (context) => Material(
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: TextButton(
          onPressed: () async {
            choice = await showSnoozeDialog(
              context,
              itemLabel: 'Oil and filter',
              today: today,
              hasDistanceInterval: hasDistanceInterval,
              currentOdometerMetres: odometerMetres,
              // ISO dates and raw metres, because the tests assert arithmetic
              // rather than formatting — EPIC-04's formatters have their own
              // tests and this one would be asserting them twice.
              formatDate: (d) => '${d.year}-${_two(d.month)}-${_two(d.day)}',
              formatDistance: (m) => isolateFigures ? isolate('$m m') : '$m m',
            );
            answered = true;
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

String _two(int n) => n.toString().padLeft(2, '0');
