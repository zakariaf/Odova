// SPEC.md §13's `settings.import`, built against
// `design/reference/calm/settings.import-*.png`.
//
// "Import replaces everything. No merge, no append, no per-record picker in v1.
// One sentence on this screen says so and it is not softened."
//
// Everything above the buttons is there to make that sentence believable: the
// file's own name and date, the vehicles it holds, and a NOW → AFTER table
// with every record type in it — including the rows that do not change,
// because a table that hid those would make a user count what was missing.
//
// Nothing on this screen writes. The plan it renders came from `BackupReader`,
// which writes nothing to produce one, and the single write in the whole flow
// is behind the primary button.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/core/l10n/locale_resolution.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/features/backup/application/import_notifier.dart';
import 'package:odova/features/backup/domain/import_preview.dart';
import 'package:odova/features/backup/domain/import_warning.dart';
import 'package:odova/features/backup/domain/safety_copy_store.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/import_message.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_disclosure.dart';
import 'package:odova/ui/calm/calm_notice.dart';
import 'package:odova/ui/calm/calm_sheet.dart';
import 'package:odova/ui/calm/calm_surface.dart';

/// §13's Restore modal.
class ImportScreen extends ConsumerWidget {
  /// Creates the modal.
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(importScreenProvider);

    return switch (state) {
      ImportPreviewState() => _Preview(state: state),
      ImportProgressState() => CalmSheet(
        title: l10n.importTitle,
        // No actions at all. §13: the progress state is non-cancellable and
        // disables swipe-down dismissal — past the swap there is nothing to
        // cancel BACK to, and a Cancel that cannot work is worse than none.
        children: [_Progress(label: l10n.importRestoring)],
      ),
      ImportResultState() => _Result(state: state),
    };
  }
}

class _Preview extends ConsumerWidget {
  const _Preview({required this.state});

  final ImportPreviewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final colors = CalmColors.of(context);
    final tags = ref.watch(resolvedLocaleTagsProvider);
    final skipped = _skippedCount(state.warnings);

    return CalmSheet(
      title: l10n.importTitle,
      actions: [
        CalmButton(
          label: switch (state.variant) {
            EmptyDeviceVariant() => l10n.importImport,
            AlreadyRestoredVariant() => l10n.commonDone,
            _ => l10n.importReplaceMyData,
          },
          block: true,
          variant: switch (state.variant) {
            // The one destructive primary in the app that is not a delete.
            ReplaceVariant() || UndoVariant() => CalmButtonVariant.dangerSolid,
            _ => CalmButtonVariant.primary,
          },
          onPressed: () => switch (state.variant) {
            AlreadyRestoredVariant() => Navigator.of(context).maybePop(),
            _ => ref.read(importScreenProvider.notifier).confirm(),
          },
        ),
        // Beneath Done, and quiet. The user asked a question and the answer
        // was "nothing will change" — but it is still their data and they may
        // mean it.
        if (state.variant is AlreadyRestoredVariant)
          CalmButton(
            label: l10n.importReplaceAnyway,
            block: true,
            variant: CalmButtonVariant.quiet,
            onPressed: () => ref.read(importScreenProvider.notifier).confirm(),
          )
        else
          CalmButton(
            label: l10n.commonCancel,
            block: true,
            variant: CalmButtonVariant.tonal,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
      ],
      children: [
        _FileHeader(state: state, tags: tags),
        SizedBox(height: space.s5),

        if (state.variant is! AlreadyRestoredVariant) ...[
          _Comparison(rows: state.comparison, state: state),
          SizedBox(height: space.s4),
        ],

        if (skipped > 0) ...[
          CalmNotice(
            icon: Icons.warning_amber_rounded,
            tone: CalmNoticeTone.warn,
            children: [
              Text(
                l10n.importSkippedCount(
                  skipped,
                  formatForDisplay(
                    skipped,
                    tags.formats,
                    numerals: CalmNumerals.auto,
                  ),
                ),
              ),
              CalmDisclosure(
                title: l10n.importSeeWhich,
                children: [
                  // Type, date and a plain reason. Never an identifier: a ULID
                  // tells the user nothing and makes the list read like a
                  // crash report.
                  for (final entry in _skippedEntries(state.warnings))
                    Text(_skippedLine(context, entry, tags.formats)),
                ],
              ),
            ],
          ),
          SizedBox(height: space.s4),
        ],

        // The sentence. One ICU message, never concatenated, never softened —
        // and on its own surface so it cannot be read as small print under the
        // table above it.
        // Through `CalmStatusStyle`, not a raw slot. `check_status_encoding`
        // refuses a screen reaching into `colors.overdue` directly and it is
        // right: `resolve` is what keeps `overdue.tint` paired with
        // `overdue.ink`, and a screen that picks the two separately can pair a
        // tint from one family with ink from another and nothing notices.
        CalmSurface(
          color: CalmStatusStyle.of(context, DueState.overdue).tint,
          radius: space.s4,
          padding: EdgeInsets.all(space.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                switch (state.variant) {
                  EmptyDeviceVariant() => l10n.importNothingToReplace,
                  AlreadyRestoredVariant() => l10n.importAlreadyRestored,
                  _ => l10n.importReplacesEverything,
                },
                style: CalmType.of(context).bodyLg.copyWith(
                  color: CalmStatusStyle.of(context, DueState.overdue).ink,
                  fontWeight: CalmType.of(context).semi,
                ),
              ),
              if (state.variant is! AlreadyRestoredVariant) ...[
                SizedBox(height: space.s3),
                Text(
                  l10n.importCopySavedFirst(
                    formatForDisplay(
                      kSafetyCopyLifetimeDays,
                      tags.formats,
                      numerals: CalmNumerals.auto,
                    ),
                  ),
                  style: CalmType.of(context).body.copyWith(color: colors.ink2),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FileHeader extends StatelessWidget {
  const _FileHeader({required this.state, required this.tags});

  final ImportPreviewState state;
  final ResolvedLocale tags;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final plan = state.plan;

    return CalmSurface(
      color: colors.surface2,
      radius: space.s4,
      padding: EdgeInsets.all(space.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.variant case UndoVariant(:final takenAtUtcMs))
            Text(
              l10n.importUndoHeader(
                formatLongDate(isoDateOfUtcMs(takenAtUtcMs), tags.formats),
                _clockOf(takenAtUtcMs, tags.formats),
              ),
              style: type.bodyLg.copyWith(fontWeight: type.semi),
            )
          else ...[
            // Forced LTR and start-aligned inside an RTL layout, so
            // `odova-backup-2026-09-02-1412.json` never reverses. The name is
            // ASCII by construction — `backupFileName` makes it so — and this
            // is what keeps it looking that way in Arabic.
            Directionality(
              textDirection: TextDirection.ltr,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  state.fileName,
                  style: type.bodyLg.copyWith(fontWeight: type.semi),
                ),
              ),
            ),
            SizedBox(height: space.s2),
            if (state.exportedAtUtcMs case final at?)
              Text(
                l10n.importFileMade(
                  formatLongDate(isoDateOfUtcMs(at), tags.formats),
                  _clockOf(at, tags.formats),
                  l10n.backupVehicleCount(
                    plan.store.vehicles.length,
                    formatForDisplay(
                      plan.store.vehicles.length,
                      tags.formats,
                      numerals: CalmNumerals.auto,
                    ),
                  ),
                  l10n.backupEntryCount(
                    plan.recordsRead,
                    formatForDisplay(
                      plan.recordsRead,
                      tags.formats,
                      numerals: CalmNumerals.auto,
                    ),
                  ),
                ),
                style: type.body.copyWith(color: colors.ink2),
              ),
          ],
        ],
      ),
    );
  }
}

class _Comparison extends ConsumerWidget {
  const _Comparison({required this.rows, required this.state});

  final List<ImportCountRow> rows;
  final ImportPreviewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final tags = ref.watch(resolvedLocaleTagsProvider);
    final empty = state.variant is EmptyDeviceVariant;

    Widget cell(String text, {required bool strong, Color? colour}) => Text(
      text,
      textAlign: TextAlign.end,
      style: CalmType.tabular(
        (strong ? type.body.copyWith(fontWeight: type.semi) : type.body)
            .copyWith(color: colour ?? colors.ink2),
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.importWhatChanges,
                style: type.body.copyWith(color: colors.ink2),
              ),
            ),
            // On an empty device the comparison collapses to one column:
            // "now" is zero on every row, and a column of zeros is noise
            // pretending to be information.
            if (!empty)
              SizedBox(width: 72, child: cell(l10n.importNow, strong: false)),
            SizedBox(width: space.s5),
            SizedBox(width: 72, child: cell(l10n.importAfter, strong: false)),
          ],
        ),
        for (final row in rows)
          Padding(
            padding: EdgeInsetsDirectional.only(top: space.s3),
            child: Row(
              children: [
                Expanded(child: Text(_kindLabel(l10n, row.kind))),
                if (!empty)
                  SizedBox(
                    width: 72,
                    child: cell(
                      formatForDisplay(
                        row.now,
                        tags.formats,
                        numerals: CalmNumerals.auto,
                      ),
                      strong: false,
                    ),
                  ),
                SizedBox(
                  width: space.s5,
                  // The arrow mirrors with the layout: `→` in an LTR locale
                  // and `←` in an RTL one, because a comparison that reads
                  // right-to-left with a left-to-right arrow points at the
                  // wrong column.
                  child: Icon(
                    Icons.chevron_right,
                    size: space.iconSm,
                    color: colors.ink3,
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: cell(
                    formatForDisplay(
                      row.after,
                      tags.formats,
                      numerals: CalmNumerals.auto,
                    ),
                    strong: true,
                    // A row that LOSES records is amber. Losing 24 fill-ups
                    // must not look like the three rows above it that gained.
                    colour: row.loses
                        ? CalmStatusStyle.of(context, DueState.due).ink
                        : colors.ink,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: space.s8),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: space.s4),
          Text(label, style: CalmType.of(context).body),
        ],
      ),
    );
  }
}

class _Result extends ConsumerWidget {
  const _Result({required this.state});

  final ImportResultState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final tags = ref.watch(resolvedLocaleTagsProvider);

    return CalmSheet(
      title: l10n.importTitle,
      actions: [
        CalmButton(
          label: l10n.commonDone,
          block: true,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
      children: [
        Text(
          l10n.importRestored(
            l10n.backupVehicleCount(
              state.vehicles,
              formatForDisplay(
                state.vehicles,
                tags.formats,
                numerals: CalmNumerals.auto,
              ),
            ),
            l10n.backupEntryCount(
              state.records,
              formatForDisplay(
                state.records,
                tags.formats,
                numerals: CalmNumerals.auto,
              ),
            ),
          ),
          style: CalmType.of(context).bodyLg,
        ),
        // A state and not a snackbar, when anything was skipped: a snackbar
        // cannot carry a list, and a count that quietly dropped three things
        // must be acknowledged by a tap.
        if (state.skipped.isNotEmpty) ...[
          SizedBox(height: space.s4),
          for (final entry in state.skipped)
            Padding(
              padding: EdgeInsetsDirectional.only(bottom: space.s2),
              child: Text(_skippedLine(context, entry, tags.formats)),
            ),
        ],
      ],
    );
  }
}

int _skippedCount(List<ImportWarning> warnings) => warnings
    .whereType<SkippedRecords>()
    .fold(0, (sum, warning) => sum + warning.count);

List<SkippedEntry> _skippedEntries(List<ImportWarning> warnings) => [
  for (final warning in warnings.whereType<SkippedRecords>())
    ...warning.entries,
];

String _skippedLine(BuildContext context, SkippedEntry entry, String tag) {
  final l10n = AppLocalizations.of(context);
  final date = entry.occurredOn;
  return date == null
      ? skippedEntryLine(l10n, entry)
      : skippedEntryLine(l10n, entry, date: formatLongDate(date, tag));
}

/// The label for one record type.
///
/// EVERY array named, and the fallback says so rather than picking one. The
/// first version ended `_ => l10n.importKindReadings`, so `odometer_
/// corrections` rendered as "Odometer readings" — two different record types
/// under one name, on the screen whose whole job is telling the user what is
/// about to change. A catch-all that returns a real label is a catch-all that
/// lies; `backupArrayLabels` is asserted complete against `kBackupArrays`.
String _kindLabel(AppLocalizations l10n, String kind) => switch (kind) {
  'vehicles' => l10n.importKindVehicles,
  'reminders' => l10n.importKindReminders,
  'odometer_readings' => l10n.importKindReadings,
  'odometer_corrections' => l10n.importKindCorrections,
  'fillups' => l10n.importKindFillups,
  'services' => l10n.importKindServices,
  'expenses' => l10n.importKindExpenses,
  'trips' => l10n.importKindTrips,
  // Not reachable: `import_message_completeness_test` asserts every entry of
  // `kBackupArrays` is named above. A wrong label is worse than a visibly
  // missing one, so this says nothing rather than guessing.
  _ => kind,
};

String _clockOf(int utcMs, String tag) {
  final t = DateTime.fromMillisecondsSinceEpoch(utcMs, isUtc: true);
  return formatMinutesOfDay(t.hour * 60 + t.minute, tag);
}
