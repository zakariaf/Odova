// SPEC.md §13's `settings.backup`, through the widget tree.
//
// The state table itself is `backup_chrome_test`'s. What is asserted here is
// what a pure function cannot: that "Back up now" is the only filled button on
// the screen, and that the unencrypted warning is BENEATH it — a position, not
// a presence, because §13's sentence is "not in a footnote, not behind an info
// icon" and a test for the string alone would pass on a footnote.
@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/backup/application/backup_notifier.dart';
import 'package:odova/features/backup/domain/safety_copy_store.dart';
import 'package:odova/features/backup/presentation/backup_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_button.dart';

import '../../../support/pump_app.dart';

const int _day = Duration.millisecondsPerDay;
const int _now = 1788374460000;

SafetyCopy _copy(SafetyCopyKind kind, {int ageDays = 1}) => SafetyCopy(
  kind: kind,
  file: File('x'),
  writtenAtUtcMs: _now - ageDays * _day,
  vehicles: 2,
  records: 431,
  contentHash: 'sha256:abc',
);

/// Records every action the screen asks for, and answers none of them.
class _SpyActions implements BackupActions {
  final List<String> calls = [];
  int? exportedAt;

  /// Held open by the progress test, so the in-flight state is observable.
  /// Without it the export finishes inside the same microtask and the screen
  /// is back to its button before the first `pump` — which would make the
  /// progress assertion pass for the wrong reason.
  Completer<int?>? pending;

  @override
  Future<int?> backUpNow() {
    calls.add('backUpNow');
    return pending?.future ?? Future<int?>.value(exportedAt);
  }

  @override
  Future<void> exportFillUpsCsv() async => calls.add('fillUpsCsv');

  @override
  Future<void> exportCostsCsv() async => calls.add('costsCsv');

  @override
  Future<void> exportServiceHistoryPdf() async => calls.add('pdf');

  @override
  Future<void> pickFileToRestore() async => calls.add('pickFile');

  @override
  Future<void> undo(SafetyCopyKind kind) async =>
      calls.add('undo:${kind.name}');

  @override
  Future<void> beginDeleteAll() async => calls.add('beginDeleteAll');
}

Future<AppLocalizations> _l10n() =>
    AppLocalizations.delegate.load(const Locale('en'));

Future<void> _pump(
  WidgetTester tester, {
  int entries = 68,
  int since = 68,
  int? lastBackup,
  List<SafetyCopy> copies = const [],
  bool migrationFailed = false,
  _SpyActions? actions,
  Locale? locale,
}) => pumpApp(
  tester,
  const BackupScreen(),
  locale: locale,
  overrides: [
    backupActionsProvider.overrideWithValue(actions ?? _SpyActions()),
    backupInitialStateProvider.overrideWithValue(
      BackupScreenState(
        nowUtcMs: _now,
        entryCount: entries,
        entriesSinceBackup: since,
        onDiskKilobytes: 4200,
        safetyCopies: copies,
        lastBackupAtUtcMs: lastBackup,
        migrationFailed: migrationFailed,
      ),
    ),
  ],
);

/// Scrolls [finder] into view.
///
/// The screen is a `ListView`, so a row below the fold is not BUILT — which is
/// correct for a list and means a finder alone proves nothing about a row
/// further down. Every assertion about the lower half scrolls to it first.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('"Back up now" is the only filled button on the screen', (
    tester,
  ) async {
    // Calm allows one primary element per screen, and two primaries means the
    // screen has failed: the user's eye has nowhere to land and the most
    // important action stops being the most important thing.
    await _pump(tester);
    final l10n = await _l10n();

    final filled = tester
        .widgetList<CalmButton>(find.byType(CalmButton))
        .where((b) => b.variant == CalmButtonVariant.primary)
        .toList();

    expect(filled, hasLength(1));
    expect(filled.single.label, l10n.backupNow);
  });

  testWidgets('the unencrypted warning sits directly beneath the button', (
    tester,
  ) async {
    // A POSITION, not a presence. §13: "not in a footnote, not behind an info
    // icon" — and a test for the string alone would pass on a footnote.
    await _pump(tester);
    final l10n = await _l10n();

    final button = tester.getRect(find.byType(CalmButton).first);
    final warning = tester.getRect(find.text(l10n.backupNotEncrypted));

    expect(warning.top, greaterThan(button.bottom - 1));
    // And NOTHING is drawn between them. That is the property §13 is asking
    // for — "not in a footnote, not behind an info icon" — and a distance
    // check would pass on a screen that had grown a row in the gap.
    final between = tester.widgetList<Text>(find.byType(Text)).where((text) {
      final rect = tester.getRect(find.byWidget(text));
      return rect.top >= button.bottom && rect.bottom <= warning.top;
    });
    expect(between, isEmpty);
  });

  testWidgets('never backed up says so, in amber, with the count', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = await _l10n();

    expect(find.text(l10n.backupNever), findsOneWidget);
    expect(find.textContaining('68'), findsWidgets);
  });

  testWidgets('a recent backup hides the count below twenty entries', (
    tester,
  ) async {
    await _pump(tester, lastBackup: _now - 12 * _day, since: 3);

    expect(find.textContaining('3 entries since'), findsNothing);
  });

  testWidgets('an empty store disables the button and hides the exports', (
    tester,
  ) async {
    await _pump(tester, entries: 0, since: 0);
    final l10n = await _l10n();

    final button = tester.widget<CalmButton>(find.byType(CalmButton).first);
    expect(button.onPressed, isNull);
    expect(button.disabledBecause, l10n.backupNothingToBackUp);
    // Hidden, not greyed: an absent row asks no question.
    await _reveal(tester, find.text(l10n.backupDeleteAll));
    expect(find.text(l10n.backupFillUpsCsv), findsNothing);
    expect(find.text(l10n.backupServiceHistoryPdf), findsNothing);
  });

  testWidgets('a kind with no safety copy has no row', (tester) async {
    await _pump(tester);
    final l10n = await _l10n();

    await _reveal(tester, find.text(l10n.backupRestoreRow));
    expect(find.text(l10n.backupUndoImport), findsNothing);
    expect(find.text(l10n.backupUndoWipe), findsNothing);
    // And no uninstall line either: it belongs to the copies.
    expect(find.text(l10n.backupCopiesGoOnUninstall), findsNothing);
  });

  testWidgets('a wipe copy renders its own row, with an expiry', (
    tester,
  ) async {
    await _pump(tester, copies: [_copy(SafetyCopyKind.wipe)]);
    final l10n = await _l10n();

    await _reveal(tester, find.text(l10n.backupUndoWipe));
    expect(find.text(l10n.backupUndoWipe), findsOneWidget);
    expect(find.text(l10n.backupUndoImport), findsNothing);
    expect(find.textContaining('Until'), findsOneWidget);
    // The line about uninstalling appears exactly once, next to the buttons.
    expect(find.text(l10n.backupCopiesGoOnUninstall), findsOneWidget);
  });

  testWidgets('both copies render both rows', (tester) async {
    await _pump(
      tester,
      copies: [
        _copy(SafetyCopyKind.wipe, ageDays: 5),
        _copy(SafetyCopyKind.restore),
      ],
    );
    final l10n = await _l10n();

    await _reveal(tester, find.text(l10n.backupUndoWipe));
    expect(find.text(l10n.backupUndoImport), findsOneWidget);
    expect(find.text(l10n.backupUndoWipe), findsOneWidget);
  });

  testWidgets('a failed migration banners, keeps export, refuses the rest', (
    tester,
  ) async {
    await _pump(tester, migrationFailed: true);
    final l10n = await _l10n();

    expect(find.text(l10n.backupMigrationBanner), findsOneWidget);
    // Getting the data out of the building is the entire reason the app
    // opened on this screen.
    expect(
      tester.widget<CalmButton>(find.byType(CalmButton).first).onPressed,
      isNotNull,
    );
    await _reveal(tester, find.text(l10n.backupFillUpsCsv));
    expect(find.text(l10n.backupFillUpsCsv), findsOneWidget);

    final restore = tester.widgetList<Widget>(
      find.ancestor(
        of: find.text(l10n.backupRestoreRow),
        matching: find.byType(IgnorePointer),
      ),
    );
    expect(restore, isNotEmpty);
  });

  testWidgets('Back up now replaces itself with the progress state', (
    tester,
  ) async {
    // A spinner beside a live button invites a second tap, and a second export
    // writes a second copy of the whole history.
    final actions = _SpyActions()..pending = Completer<int?>();
    await _pump(tester, actions: actions);
    final l10n = await _l10n();

    await tester.tap(find.text(l10n.backupNow));
    await tester.pump();

    expect(find.text(l10n.backupPreparing), findsOneWidget);
    expect(find.text(l10n.backupNow), findsNothing);

    actions.pending!.complete(null);
    await tester.pumpAndSettle();
    expect(actions.calls, ['backUpNow']);
    expect(find.text(l10n.backupNow), findsOneWidget);
  });

  testWidgets('a completed export stamps the date and clears the count', (
    tester,
  ) async {
    final actions = _SpyActions()..exportedAt = _now;
    await _pump(tester, actions: actions);
    final l10n = await _l10n();

    await tester.tap(find.text(l10n.backupNow));
    await tester.pumpAndSettle();

    // Not "never" any more, and "entries since" is now none.
    expect(find.text(l10n.backupNever), findsNothing);
    expect(find.textContaining('68'), findsNothing);
  });

  testWidgets('Restore from a backup asks for the picker', (tester) async {
    final actions = _SpyActions();
    await _pump(tester, actions: actions);
    final l10n = await _l10n();

    await _reveal(tester, find.text(l10n.backupRestoreRow));
    await tester.tap(find.text(l10n.backupRestoreRow));
    await tester.pumpAndSettle();

    expect(actions.calls, ['pickFile']);
  });

  testWidgets('Delete all data starts the flow that writes the copy first', (
    tester,
  ) async {
    // The ordering lives in the action, because a copy written after
    // confirmation is a copy that does not exist at the moment the user
    // changes their mind about having confirmed.
    final actions = _SpyActions();
    await _pump(tester, actions: actions);
    final l10n = await _l10n();

    await _reveal(tester, find.text(l10n.backupDeleteAll));
    await tester.tap(find.text(l10n.backupDeleteAll));
    await tester.pumpAndSettle();

    expect(actions.calls, ['beginDeleteAll']);
  });

  testWidgets('the three export rows each ask for their own export', (
    tester,
  ) async {
    final actions = _SpyActions();
    await _pump(tester, actions: actions);
    final l10n = await _l10n();

    for (final row in [
      l10n.backupFillUpsCsv,
      l10n.backupAllCostsCsv,
      l10n.backupServiceHistoryPdf,
    ]) {
      await _reveal(tester, find.text(row));
      await tester.tap(find.text(row));
      await tester.pumpAndSettle();
    }

    expect(actions.calls, ['fillUpsCsv', 'costsCsv', 'pdf']);
  });

  testWidgets('the screen renders in Arabic without overflowing', (
    tester,
  ) async {
    // Three of the six locales are right-to-left, and the mirror is where
    // layout bugs live. An overflow throws in a widget test, so pumping is
    // the assertion.
    await _pump(
      tester,
      locale: const Locale('ar'),
      copies: [_copy(SafetyCopyKind.wipe), _copy(SafetyCopyKind.restore)],
    );

    expect(find.byType(BackupScreen), findsOneWidget);
  });

  testWidgets('it survives 200% text scale in German', (tester) async {
    // §13: "Back up now clears the fold at 200% text scale in German", and
    // German is the width constraint for the whole screen.
    await pumpApp(
      tester,
      const BackupScreen(),
      locale: const Locale('de'),
      textScaler: const TextScaler.linear(2),
      overrides: [
        backupActionsProvider.overrideWithValue(_SpyActions()),
        backupInitialStateProvider.overrideWithValue(
          const BackupScreenState(
            nowUtcMs: _now,
            entryCount: 68,
            entriesSinceBackup: 68,
            onDiskKilobytes: 4200,
            safetyCopies: [],
          ),
        ),
      ],
    );

    expect(find.byType(BackupScreen), findsOneWidget);
  });
}
