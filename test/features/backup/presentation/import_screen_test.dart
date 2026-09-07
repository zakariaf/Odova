// SPEC.md §13's `settings.import`, and the sentence a future PR will soften.
//
// The three preview variants, the progress state and the result state are one
// widget over a sealed type — so the assertions here are mostly about what each
// state does NOT offer: the already-restored one offers no replacement
// sentence, the progress one offers no way out, and the result one holds until
// a tap when anything was skipped.
@TestOn('vm')
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/store_snapshot.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/features/backup/application/import_notifier.dart';
import 'package:odova/features/backup/domain/backup_format.dart';
import 'package:odova/features/backup/domain/import_plan.dart';
import 'package:odova/features/backup/domain/import_preview.dart';
import 'package:odova/features/backup/domain/import_warning.dart';
import 'package:odova/features/backup/domain/mapping/record_restore.dart';
import 'package:odova/features/backup/presentation/import_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_button.dart';

import '../../../support/pump_app.dart';

const int _exportedAt = 1788374460000;

final Currency _eur = Currency.tryParse('EUR')!;

ImportPlan _plan({List<ImportWarning> warnings = const []}) => ImportPlan(
  store: StoreSnapshot(
    settings: AppSettings(
      schemaVersion: 1,
      currencyDefault: _eur,
      createdAtUtcMs: 0,
      updatedAtUtcMs: 0,
    ),
  ),
  warnings: warnings,
  recordsRead: 388,
  recordsInFile: 391,
);

ImportPreviewState _preview({
  PreviewVariant variant = const ReplaceVariant(),
  List<ImportWarning> warnings = const [],
}) => ImportPreviewState(
  variant: variant,
  fileName: 'odova-backup-2026-04-11-0930.json',
  exportedAtUtcMs: _exportedAt,
  comparison: buildComparison(
    now: const {'vehicles': 1, 'fillups': 412, 'services': 37},
    after: const {'vehicles': 3, 'fillups': 388, 'services': 41},
    kinds: const ['vehicles', 'fillups', 'services'],
  ),
  plan: _plan(warnings: warnings),
);

Future<AppLocalizations> _l10n([String tag = 'en']) =>
    AppLocalizations.delegate.load(Locale(tag));

/// Counts every call, so "nothing is written to reach the preview" is a fact
/// about a spy rather than a hope about a widget.
class _SpyApply {
  int calls = 0;
  Completer<({int vehicles, int records})?>? pending;
  ({int vehicles, int records})? result;

  Future<({int vehicles, int records})?> call(ImportPlan plan) {
    calls++;
    return pending?.future ??
        Future<({int vehicles, int records})?>.value(result);
  }
}

Future<void> _pump(
  WidgetTester tester, {
  ImportScreenState? state,
  _SpyApply? apply,
  Locale? locale,
}) => pumpApp(
  tester,
  const ImportScreen(),
  locale: locale,
  overrides: [
    importInitialStateProvider.overrideWithValue(state ?? _preview()),
    if (apply != null) importActionsProvider.overrideWithValue(apply.call),
  ],
);

/// Scrolls [finder] into view.
///
/// The sheet's body is a scrollable, and §13 pins the buttons below it — so a
/// row further down is not BUILT and a finder alone proves nothing about it.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) return;
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('nothing is written to reach the preview', (tester) async {
    // The reader produces the plan and writes nothing to produce it; the only
    // write in the whole flow is behind the primary button.
    final apply = _SpyApply();

    await _pump(tester, apply: apply);

    expect(apply.calls, 0);
  });

  testWidgets('the header carries the file name and when it was made', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('odova-backup-2026-04-11-0930.json'), findsOneWidget);
    expect(find.textContaining('2026'), findsWidgets);
  });

  testWidgets('the comparison carries every type, both columns', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = await _l10n();

    expect(find.text(l10n.importKindVehicles), findsOneWidget);
    expect(find.text(l10n.importKindFillups), findsOneWidget);
    expect(find.text(l10n.importKindServices), findsOneWidget);
    expect(find.text(l10n.importNow), findsOneWidget);
    expect(find.text(l10n.importAfter), findsOneWidget);
    // 412 → 388 is the row that loses.
    expect(find.text('412'), findsOneWidget);
    expect(find.text('388'), findsOneWidget);
  });

  testWidgets('every record type in the comparison has its own name', (
    tester,
  ) async {
    // The first version's `_kindLabel` ended `_ => importKindReadings`, so
    // `odometer_corrections` rendered as "Odometer readings" — two different
    // record types under one name, on the screen whose whole job is telling
    // the user what is about to change. A catch-all that returns a real label
    // compiles and renders something plausible.
    await _pump(
      tester,
      state: ImportPreviewState(
        variant: const ReplaceVariant(),
        fileName: 'odova-backup-2026-04-11-0930.json',
        exportedAtUtcMs: _exportedAt,
        comparison: buildComparison(
          now: const {},
          after: const {},
          kinds: kBackupArrays,
        ),
        plan: _plan(),
      ),
    );
    final l10n = await _l10n();

    final labels = <String>{};
    for (final label in [
      l10n.importKindVehicles,
      l10n.importKindReminders,
      l10n.importKindReadings,
      l10n.importKindCorrections,
      l10n.importKindFillups,
      l10n.importKindServices,
      l10n.importKindExpenses,
      l10n.importKindTrips,
    ]) {
      await _reveal(tester, find.text(label));
      expect(find.text(label), findsOneWidget, reason: label);
      labels.add(label);
    }
    // Eight arrays, eight distinct labels.
    expect(labels, hasLength(kBackupArrays.length));
    // And no raw array name reached the screen.
    for (final array in kBackupArrays) {
      expect(find.text(array), findsNothing, reason: array);
    }
  });

  testWidgets('the replacement sentence is present and unsoftened', (
    tester,
  ) async {
    // Asserted verbatim, on purpose. It is one of the two most heavily
    // reviewed strings in the app and it is the one a future PR will try to
    // make gentler.
    await _pump(tester);
    final l10n = await _l10n();

    await _reveal(tester, find.text(l10n.importReplacesEverything));
    expect(
      find.text('Everything now in Odova will be replaced by this file.'),
      findsOneWidget,
    );
    expect(find.text(l10n.importReplacesEverything), findsOneWidget);
    // And the reassurance beside it, which is true — the safety copy is
    // written by the importer before the swap.
    expect(find.textContaining('A copy of what you have now'), findsOneWidget);
  });

  testWidgets('the buttons are Replace my data and Cancel', (tester) async {
    await _pump(tester);
    final l10n = await _l10n();

    expect(find.text(l10n.importReplaceMyData), findsOneWidget);
    expect(find.text(l10n.commonCancel), findsOneWidget);
  });

  testWidgets('an empty device gets its own sentence and its own button', (
    tester,
  ) async {
    await _pump(tester, state: _preview(variant: const EmptyDeviceVariant()));
    final l10n = await _l10n();

    await _reveal(tester, find.text(l10n.importNothingToReplace));
    expect(find.text(l10n.importNothingToReplace), findsOneWidget);
    expect(find.text(l10n.importReplacesEverything), findsNothing);
    expect(find.text(l10n.importImport), findsOneWidget);
    // One column, not two: a column of zeros is noise pretending to be
    // information.
    expect(find.text(l10n.importNow), findsNothing);
    expect(find.text(l10n.importAfter), findsOneWidget);
  });

  testWidgets('the already-restored variant offers Done, then Replace anyway', (
    tester,
  ) async {
    await _pump(
      tester,
      state: _preview(variant: const AlreadyRestoredVariant()),
    );
    final l10n = await _l10n();

    await _reveal(tester, find.text(l10n.importAlreadyRestored));
    expect(find.text(l10n.importAlreadyRestored), findsOneWidget);
    expect(find.text(l10n.importReplacesEverything), findsNothing);
    expect(find.text(l10n.commonDone), findsOneWidget);
    // Beneath, and quiet. The user asked a question and the answer was no,
    // but it is still their data.
    expect(find.text(l10n.importReplaceAnyway), findsOneWidget);
    // No comparison at all: nothing changes, so there is nothing to compare.
    expect(find.text(l10n.importWhatChanges), findsNothing);
  });

  testWidgets('the undo variant names the moment, not a file', (tester) async {
    await _pump(
      tester,
      state: _preview(variant: const UndoVariant(_exportedAt)),
    );

    expect(find.text('odova-backup-2026-04-11-0930.json'), findsNothing);
    expect(find.textContaining('2026'), findsWidgets);
  });

  testWidgets('a skipped-record warning renders with its count', (
    tester,
  ) async {
    await _pump(
      tester,
      state: _preview(
        warnings: const [
          SkippedRecords([
            SkippedEntry(
              array: 'fillups',
              reason: SkipReason.fuel,
              occurredOn: '2021-01-12',
            ),
            SkippedEntry(array: 'services', reason: SkipReason.date),
            SkippedEntry(array: 'expenses', reason: SkipReason.money),
          ]),
        ],
      ),
    );
    final l10n = await _l10n();

    await _reveal(tester, find.text(l10n.importSeeWhich));
    expect(find.text(l10n.importSeeWhich), findsOneWidget);
    expect(
      find.textContaining("3 entries can't be read"),
      findsNothing,
      reason: 'the copy uses a typographic apostrophe',
    );
    expect(find.textContaining('entries can’t be read'), findsOneWidget);
  });

  testWidgets('the skipped list names type, date and reason — never an id', (
    tester,
  ) async {
    await _pump(
      tester,
      state: _preview(
        warnings: const [
          SkippedRecords([
            SkippedEntry(
              array: 'fillups',
              reason: SkipReason.fuel,
              occurredOn: '2021-01-12',
            ),
          ]),
        ],
      ),
    );
    final l10n = await _l10n();

    await _reveal(tester, find.text(l10n.importSeeWhich));
    await tester.tap(find.text(l10n.importSeeWhich));
    await tester.pumpAndSettle();

    expect(find.textContaining(l10n.importTypeFillup), findsWidgets);
    expect(find.textContaining(l10n.importSkipFuel), findsOneWidget);
    // A ULID tells the user nothing and makes the list read like a crash
    // report.
    expect(find.textContaining('fil_'), findsNothing);
  });

  testWidgets('confirming shows a progress state with no way out', (
    tester,
  ) async {
    final apply = _SpyApply()
      ..pending = Completer<({int vehicles, int records})?>();
    await _pump(tester, apply: apply);
    final l10n = await _l10n();

    await tester.tap(find.text(l10n.importReplaceMyData));
    await tester.pump();

    expect(find.text(l10n.importRestoring), findsOneWidget);
    // §13: non-cancellable. Past the swap there is nothing to cancel BACK to.
    expect(find.text(l10n.commonCancel), findsNothing);
    expect(find.byType(CalmButton), findsNothing);

    apply.pending!.complete((vehicles: 3, records: 3006));
    await tester.pumpAndSettle();
  });

  testWidgets('a failed import returns to the preview, unchanged', (
    tester,
  ) async {
    // §5.2's promise is that a failed import changes nothing, and putting the
    // user back on the screen they were on is what makes that visible.
    final apply = _SpyApply();
    await _pump(tester, apply: apply);
    final l10n = await _l10n();

    await tester.tap(find.text(l10n.importReplaceMyData));
    await tester.pumpAndSettle();

    await _reveal(tester, find.text(l10n.importReplacesEverything));
    expect(find.text(l10n.importReplacesEverything), findsOneWidget);
    expect(find.text(l10n.importReplaceMyData), findsOneWidget);
  });

  testWidgets('success with skipped entries holds on the result', (
    tester,
  ) async {
    // A snackbar cannot carry a list, and a count that quietly dropped three
    // things must be acknowledged by a tap.
    await _pump(
      tester,
      state: const ImportResultState(
        vehicles: 3,
        records: 3006,
        skipped: [SkippedEntry(array: 'fillups', reason: SkipReason.fuel)],
      ),
    );
    final l10n = await _l10n();

    expect(find.textContaining('Restored'), findsOneWidget);
    expect(find.text(l10n.commonDone), findsOneWidget);
    expect(find.textContaining(l10n.importSkipFuel), findsOneWidget);
  });

  testWidgets('a clean success has nothing to hold the user for', (
    tester,
  ) async {
    await _pump(
      tester,
      state: const ImportResultState(
        vehicles: 3,
        records: 3006,
        skipped: [],
      ),
    );

    expect(
      const ImportResultState(
        vehicles: 3,
        records: 3006,
        skipped: [],
      ).canDismissItself,
      isTrue,
    );
  });

  testWidgets('no screen string uses the vocabulary of a parser', (
    tester,
  ) async {
    // A scan of the RENDERED tree, in every locale, because the words come
    // from six ARB files and only one of them is proof-read here.
    for (final tag in const ['en', 'de', 'fr', 'fa', 'ar', 'ckb']) {
      await _pump(
        tester,
        locale: Locale(tag),
        state: _preview(
          warnings: const [
            SkippedRecords([
              SkippedEntry(array: 'fillups', reason: SkipReason.fuel),
            ]),
          ],
        ),
      );

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');

      expect(texts.contains('JSON'), isFalse, reason: tag);
      for (final word in const ['schema', 'parse', 'entity', 'row ']) {
        expect(
          texts.toLowerCase().contains(word),
          isFalse,
          reason: '$tag/$word',
        );
      }
    }
  });

  testWidgets('it renders in Arabic and at 200% German without overflowing', (
    tester,
  ) async {
    await _pump(tester, locale: const Locale('ar'));
    expect(find.byType(ImportScreen), findsOneWidget);

    await pumpApp(
      tester,
      const ImportScreen(),
      locale: const Locale('de'),
      textScaler: const TextScaler.linear(2),
      overrides: [
        importInitialStateProvider.overrideWithValue(_preview()),
      ],
    );
    expect(find.byType(ImportScreen), findsOneWidget);
  });
}
