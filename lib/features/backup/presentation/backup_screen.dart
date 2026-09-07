// SPEC.md §13's `settings.backup`, built against
// `design/reference/calm/settings.backup-*.png`.
//
// "The most important screen after Home. Get your data out, get it back in,
// and destroy it deliberately." Three actions with three different weights,
// and the whole layout is about keeping them apart: one filled button, one
// group of quiet export rows, one restore group, and the destructive row
// alone at the bottom in its own colour.
//
// The seven states are `resolveBackupChrome`'s, not this file's. Two of them
// disable controls, one hides whole rows and one reorders the screen behind a
// red banner — and the one that matters most, migration-failed, is the one
// nobody would remember to pump.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/features/backup/application/backup_notifier.dart';
import 'package:odova/features/backup/domain/backup_chrome.dart';
import 'package:odova/features/backup/domain/backup_export_service.dart';
import 'package:odova/features/backup/domain/safety_copy_store.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/export_message.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/relative_past_text.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_badge.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_card.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_notice.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

/// §13's Backup & restore.
class BackupScreen extends ConsumerWidget {
  /// Creates the screen.
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final tags = ref.watch(resolvedLocaleTagsProvider);
    final state = ref.watch(backupScreenProvider);
    final chrome = state.chrome;

    return CalmScaffold(
      appBar: CalmAppBar(title: l10n.backupTitle),
      children: [
        // Above everything, because §6 §3.3 says the app may have opened HERE
        // instead of home and the banner is the reason why.
        if (chrome.showsMigrationBanner) ...[
          CalmNotice(
            icon: Icons.warning_amber_rounded,
            tone: CalmNoticeTone.warn,
            children: [Text(l10n.backupMigrationBanner)],
          ),
          SizedBox(height: space.s5),
        ],

        _LastBackupCard(state: state),

        SizedBox(height: space.s4),
        // Directly beneath the button. §13: "not in a footnote, not behind an
        // info icon" — the position IS the message, so the widget order here
        // is asserted rather than the string's presence.
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: space.s4),
          child: Text(
            l10n.backupNotEncrypted,
            style: type.caption.copyWith(color: colors.ink2),
          ),
        ),

        if (chrome.showsOtherExports) ...[
          SizedBox(height: space.s6),
          _GroupLabel(l10n.backupAlsoExport),
          CalmRowGroup(
            rows: [
              CalmListRow(
                title: l10n.backupFillUpsCsv,
                showChevron: true,
                onTap: () =>
                    ref.read(backupScreenProvider.notifier).exportFillUpsCsv(),
              ),
              CalmListRow(
                title: l10n.backupAllCostsCsv,
                showChevron: true,
                onTap: () =>
                    ref.read(backupScreenProvider.notifier).exportCostsCsv(),
              ),
              CalmListRow(
                title: l10n.backupServiceHistoryPdf,
                showChevron: true,
                onTap: () => ref
                    .read(backupScreenProvider.notifier)
                    .exportServiceHistoryPdf(),
              ),
            ],
          ),
        ],

        SizedBox(height: space.s6),
        _GroupLabel(l10n.backupRestoreHeader),
        CalmRowGroup(
          rows: [
            CalmListRow(
              title: l10n.backupRestoreRow,
              lead: const Icon(Icons.download_outlined),
              showChevron: true,
              enabled: chrome.canRestore,
              onTap: () =>
                  ref.read(backupScreenProvider.notifier).pickFileToRestore(),
            ),
            // One row per copy that EXISTS. A kind with none has no row —
            // absent, not greyed: a user who sees "Undo" greyed out will tap
            // it, and a disabled control with no explanation answers nothing.
            for (final kind in chrome.undoRows)
              CalmListRow(
                title: kind == SafetyCopyKind.wipe
                    ? l10n.backupUndoWipe
                    : l10n.backupUndoImport,
                subtitle: _expiryOf(context, ref, state, kind),
                showChevron: true,
                enabled: chrome.canRestore,
                onTap: () => ref.read(backupScreenProvider.notifier).undo(kind),
              ),
          ],
        ),

        if (chrome.undoRows.isNotEmpty) ...[
          SizedBox(height: space.s4),
          Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: space.s4),
            child: Text(
              l10n.backupCopiesGoOnUninstall,
              style: type.caption.copyWith(color: colors.ink2),
            ),
          ),
        ],

        SizedBox(height: space.s6),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: space.s4),
          child: Text(
            l10n.backupOnDiskSize(
              formatForDisplay(
                state.onDiskKilobytes,
                tags.formats,
                numerals: state.numerals,
              ),
            ),
            style: type.caption.copyWith(color: colors.ink2),
          ),
        ),

        SizedBox(height: space.s6),
        CalmRowGroup(
          rows: [
            CalmListRow(
              title: l10n.backupDeleteAll,
              lead: const Icon(Icons.delete_outline),
              danger: true,
              showChevron: true,
              enabled: chrome.canDelete,
              onTap: () =>
                  ref.read(backupScreenProvider.notifier).beginDeleteAll(),
            ),
          ],
        ),
      ],
    );
  }

  String? _expiryOf(
    BuildContext context,
    WidgetRef ref,
    BackupScreenState state,
    SafetyCopyKind kind,
  ) {
    final copy = state.safetyCopies
        .where((c) => c.kind == kind)
        .fold<SafetyCopy?>(
          null,
          (best, c) =>
              best == null || c.writtenAtUtcMs > best.writtenAtUtcMs ? c : best,
        );
    if (copy == null) return null;
    final tags = ref.watch(resolvedLocaleTagsProvider);
    return AppLocalizations.of(context).backupUndoUntil(
      formatLongDate(
        _isoOf(copy.writtenAtUtcMs + kSafetyCopyLifetime.inMilliseconds),
        tags.formats,
        calendar: state.calendar,
        numerals: state.numerals,
      ),
    );
  }
}

/// The card at the top: the label, the date, the count and the one button.
class _LastBackupCard extends ConsumerWidget {
  const _LastBackupCard({required this.state});

  final BackupScreenState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final tags = ref.watch(resolvedLocaleTagsProvider);
    final chrome = state.chrome;
    final amber = chrome.age != BackupAge.recent;

    return CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A Wrap and not a Row, at both levels of this card. At 200% text
          // scale in German the label and the pill do not fit on one line, and
          // §13 says the button clears the fold at that scale — which it
          // cannot do if the card above it has already overflowed.
          // `accessibility-as-code` refuses `FittedBox` and `ellipsis` for
          // this: the text does not shrink, it moves.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: space.s4,
            runSpacing: space.s2,
            children: [
              Text(
                l10n.backupLastLabel,
                style: type.caption.copyWith(color: colors.ink2),
              ),
              if (state.lastBackupAtUtcMs case final at?)
                // A `CalmBadge`, not a hand-built pill. Only `lib/ui/calm/`
                // builds a decoration, and the first version of this screen
                // did — caught by `check_component_hygiene`, which is exactly
                // the drift it exists to stop: a one-off pill on one screen
                // becomes a second pill on the next one that is four pixels
                // shorter.
                CalmBadge(
                  label: formatDaysAgo(
                    l10n,
                    tags.formats,
                    (state.nowUtcMs - at) ~/ Duration.millisecondsPerDay,
                  ),
                  kind: amber ? CalmBadgeKind.due : CalmBadgeKind.ok,
                  icon: amber ? Icons.warning_amber_rounded : null,
                ),
            ],
          ),
          SizedBox(height: space.s2),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: space.s4,
            runSpacing: space.s2,
            children: [
              Text(
                state.lastBackupAtUtcMs == null
                    ? l10n.backupNever
                    : formatLongDate(
                        _isoOf(state.lastBackupAtUtcMs!),
                        tags.formats,
                        calendar: state.calendar,
                        numerals: state.numerals,
                      ),
                style: type.titleLg,
              ),
              if (chrome.showsEntryCount)
                Text(
                  state.lastBackupAtUtcMs == null
                      ? l10n.backupEntriesOnlyHere(
                          state.entriesSinceBackup,
                          formatForDisplay(
                            state.entriesSinceBackup,
                            tags.formats,
                            numerals: state.numerals,
                          ),
                        )
                      : l10n.backupEntriesSince(
                          state.entriesSinceBackup,
                          formatForDisplay(
                            state.entriesSinceBackup,
                            tags.formats,
                            numerals: state.numerals,
                          ),
                        ),
                  style: type.caption.copyWith(color: colors.ink2),
                ),
            ],
          ),
          SizedBox(height: space.s5),
          // The inline progress state REPLACES the button — §13. A spinner
          // beside a live button invites a second tap, and a second export
          // writes a second copy of the whole history.
          if (state.isExporting)
            Row(
              children: [
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: space.s4),
                Text(l10n.backupPreparing, style: type.body),
              ],
            )
          else ...[
            CalmButton(
              label: l10n.backupNow,
              icon: Icons.ios_share,
              block: true,
              size: CalmButtonSize.lg,
              disabledBecause: chrome.canBackUp
                  ? null
                  : l10n.backupNothingToBackUp,
              onPressed: chrome.canBackUp
                  ? () => ref.read(backupScreenProvider.notifier).backUpNow()
                  : null,
            ),
            // Inline, under the button, and never a dialog: §12's reasoning
            // holds here too — the user is already having a bad day, and a
            // dialog is a second thing to dismiss.
            if (state.exportFailure case final failure?) ...[
              SizedBox(height: space.s3),
              CalmNotice(
                icon: Icons.error_outline,
                tone: CalmNoticeTone.warn,
                children: [
                  Text(
                    exportFailureMessage(
                      l10n,
                      failure,
                      size: _sizeOf(failure, tags.formats, state.numerals),
                    ),
                  ),
                  if (exportFailureRetries(failure))
                    CalmButton(
                      label: l10n.commonRetry,
                      variant: CalmButtonVariant.quiet,
                      onPressed: () =>
                          ref.read(backupScreenProvider.notifier).backUpNow(),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// The figure §13's out-of-space message names.
///
/// Rounded UP to the next megabyte, and named: "free up some space" is advice
/// a user cannot act on where "free up about 6 MB" is.
String _sizeOf(ExportFailure failure, String tag, CalmNumerals numerals) {
  if (failure is! ExportNoSpace) return '';
  final megabytes = (failure.neededBytes / (1024 * 1024)).ceil();
  return '${formatForDisplay(megabytes, tag, numerals: numerals)} MB';
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        space.s4,
        0,
        space.s4,
        space.s2,
      ),
      child: Text(text, style: type.caption.copyWith(color: colors.ink2)),
    );
  }
}

/// A UTC instant as the `YYYY-MM-DD` string the date formatter takes.
String _isoOf(int utcMs) => DateTime.fromMillisecondsSinceEpoch(
  utcMs,
  isUtc: true,
).toIso8601String().substring(0, 10);
