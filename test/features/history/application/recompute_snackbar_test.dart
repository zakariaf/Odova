// §11's five snackbar cases, each from the diff rather than from the edit.
@TestOn('vm')
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/recompute/vehicle_recompute.dart';
import 'package:odova/features/history/application/recompute_snackbar.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

RecomputeDiff _diff({int figures = 0, Set<String> items = const {}}) =>
    RecomputeDiff(
      changedConsumptionCount: figures,
      changedDueItemIds: items,
    );

void main() {
  late AppLocalizations en;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  String message(LogType type, RecomputeDiff diff) => recomputeMessage(
    type: type,
    diff: diff,
    l10n: en,
    formatsTag: 'en',
  );

  test('nothing derived changed reads "Saved"', () {
    // §11's last row. An edit that fixed a vendor's spelling must not claim to
    // have recalculated anything.
    expect(message(LogType.fillUp, _diff()), en.recomputeSaved);
    expect(message(LogType.expense, _diff()), en.recomputeSaved);
  });

  test('a fill-up that moved figures names how many', () {
    // §11: "Fill-up updated · 14 later fuel figures recalculated".
    final line = message(LogType.fillUp, _diff(figures: 14));

    expect(line, contains(en.recomputeFillUpUpdated));
    expect(line, contains('14'));
    expect(line, contains('·'));
  });

  test('and one figure reads singular', () {
    final line = message(LogType.fillUp, _diff(figures: 1));

    expect(line, contains('1 later fuel figure recalculated'));
  });

  test('an expense that moved a due state names no figures', () {
    // An expense participates in no consumption figure, so the second half
    // would be a zero dressed up as information.
    final line = message(
      LogType.expense,
      _diff(items: const {'item'}),
    );

    expect(line, en.recomputeExpenseUpdated);
    expect(line, isNot(contains('·')));
  });

  test('the count comes from the DIFF, not from the type', () {
    // The same edit type with two different diffs produces two different
    // messages — which is the whole reason the diff exists.
    expect(
      message(LogType.fillUp, _diff(figures: 2)),
      isNot(message(LogType.fillUp, _diff(figures: 3))),
    );
  });

  test('a due-only change still says the row was updated', () {
    // Deleting a service moves reminders without touching a fuel figure. §11
    // still names the act; it just has no count to add.
    final line = message(
      LogType.service,
      _diff(items: const {'oil'}),
    );

    expect(line, en.recomputeServiceUpdated);
  });

  test('the diff decides the schedule rebuild, not the message', () {
    // Separate concerns that a single flag would have merged: a rebuild is
    // needed whenever a due fact moved, whether or not the sentence mentions
    // it.
    final due = _diff(items: const {'oil'});
    final figuresOnly = _diff(figures: 3);

    expect(due.needsScheduleRebuild, isTrue);
    expect(figuresOnly.needsScheduleRebuild, isFalse);
    expect(DueState.values, isNotEmpty);
  });
}
