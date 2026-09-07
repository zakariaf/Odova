// SPEC.md §13's `settings`, built against
// `design/reference/calm/settings-*.png`.
//
// Backup & restore is the FIRST row, in its own group, above Vehicles — §13
// gives one reason and it is the whole shape of this screen: "the person who
// needs Export is standing in a phone shop with a dead handset in their
// pocket." It must stay visible without scrolling at 200% text scale in
// German, which is why no preference may be added above it.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/app_version.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/l10n/locale_resolution.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/features/settings/application/settings_root_model.dart';
import 'package:odova/features/settings/data/settings_writer.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/relative_past_text.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_segmented.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';

/// The three themes, in §13's order.
const List<String> kThemeChoices = ['system', 'light', 'dark'];

/// How many vehicles the Vehicles row names before it counts them instead.
///
/// The reference draws three names — `Golf, Transit, CB500X` — and names are
/// more use than a number to somebody deciding whether to tap. Past three the
/// line stops fitting on the narrowest phone, and §13's plural takes over.
const int kNamedVehicleLimit = 3;

/// §13's settings screen.
class SettingsScreen extends ConsumerWidget {
  /// Creates the screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final colors = CalmColors.of(context);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;
    final state = ref.watch(settingsRootProvider);

    void push(String location) => unawaited(context.push(location));

    return CalmScaffold(
      appBar: CalmAppBar.large(title: l10n.settingsTitle),
      children: [
        // FIRST, and alone in its group. `settings_screen_test.dart` asserts
        // the first group holds exactly this one row, which is the test that
        // stops the next epic appending a preference above it.
        CalmRowGroup(
          rows: [
            CalmListRow(
              title: l10n.settingsBackupRow,
              subtitle: _backupSubtitle(l10n, tag, state),
              detailState: _backupDue(state),
              lead: const Icon(Icons.ios_share),
              end: state.backup == BackupState.recent
                  ? null
                  : CalmStatusDot(
                      style: CalmStatusStyle.of(context, _backupDue(state)!),
                    ),
              showChevron: true,
              onTap: () => push(Routes.settingsBackup),
            ),
          ],
        ),
        SizedBox(height: space.s4),
        CalmRowGroup(
          rows: [
            CalmListRow(
              title: l10n.settingsVehiclesRow,
              subtitle: vehiclesSubtitle(l10n, tag, state.vehicles),
              lead: const Icon(Icons.garage_outlined),
              showChevron: true,
              onTap: () => push(Routes.vehicles),
            ),
          ],
        ),
        SizedBox(height: space.s4),
        CalmRowGroup(
          rows: [
            CalmListRow(
              title: l10n.settingsLanguageRow,
              // The language's OWN name, never translated. §13: someone who
              // has ended up in a language they cannot read has to find their
              // own by shape — and `System (English)` names what it resolves
              // to, live.
              value: state.language == systemLanguage
                  ? l10n.settingsLanguageSystem(
                      localeEndonym(languageOf(tag)),
                    )
                  : localeEndonym(state.language),
              showChevron: true,
              onTap: () => push(Routes.settingsLanguage),
            ),
            CalmListRow(
              title: l10n.settingsUnitsRow,
              value: unitsSummary(l10n, state),
              showChevron: true,
              onTap: () => push(Routes.settingsUnits),
            ),
            CalmListRow(
              title: l10n.settingsNotificationsRow,
              value: l10n.settingsNotificationsValue(
                state.notifyService
                    ? l10n.settingsNotificationsOn
                    : l10n.settingsNotificationsOff,
                formatMinutesOfDay(state.notificationTimeMinutes, tag),
              ),
              showChevron: true,
              onTap: () => push(Routes.settingsNotifications),
            ),
          ],
        ),
        SizedBox(height: space.s5),
        Text(
          l10n.settingsAppearance,
          style: type.label.copyWith(color: colors.ink2),
        ),
        SizedBox(height: space.s3),
        // INLINE, and applied on tap with no confirmation. §13: one
        // three-valued setting with an instantly visible result — a dialog
        // over a change the user can see land is a dialog asking them to
        // confirm what they are already looking at.
        CalmSegmented(
          labels: [
            l10n.settingsThemeSystem,
            l10n.settingsThemeLight,
            l10n.settingsThemeDark,
          ],
          index: kThemeChoices.indexOf(state.theme),
          onChanged: (i) => unawaited(
            ref.read(settingsWriterProvider).setTheme(kThemeChoices[i]),
          ),
        ),
        SizedBox(height: space.s5),
        CalmRowGroup(
          rows: [
            CalmListRow(
              title: l10n.settingsAboutRow,
              // LATIN digits whatever `numerals` says. §13: "1.4.0 stays Latin
              // digits regardless — a version string, not a number." It is an
              // identifier a support conversation quotes back.
              value: kAppVersion,
              showChevron: true,
              onTap: () => push(Routes.settingsAbout),
            ),
          ],
        ),
      ],
    );
  }

  /// §13's four backup subtitles.
  static String _backupSubtitle(
    AppLocalizations l10n,
    String tag,
    SettingsRootState state,
  ) => switch (state.backup) {
    BackupState.never => l10n.settingsBackupNever,
    BackupState.migrationFailed => l10n.settingsBackupMigrationFailed,
    BackupState.recent ||
    BackupState.stale => _lastBackupLine(l10n, tag, state),
  };

  static String _lastBackupLine(
    AppLocalizations l10n,
    String tag,
    SettingsRootState state,
  ) {
    final on = CivilDate.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(
        state.lastBackupAtUtcMs!,
        isUtc: true,
      ),
    );
    // Through `todayProvider`, like every other date in the app. Reading the
    // wall clock here would give this one line a different idea of "today"
    // from the screen around it the moment midnight passes with the app open.
    final days = on == null || state.today == null
        ? 0
        : on.daysUntil(state.today!);
    return l10n.settingsBackupLast(
      on == null ? '' : formatLongDate(on.toString(), tag),
      // BUCKETED — "3 months ago", never "97 days ago". §5, and the reference
      // draws both the date and the age because they answer different
      // questions: one is checked against memory, the other against urgency.
      formatDaysAgo(l10n, tag, days),
    );
  }

  /// Which status treatment the row wears, or null for none.
  static DueState? _backupDue(SettingsRootState state) =>
      switch (state.backup) {
        BackupState.recent => null,
        BackupState.migrationFailed => DueState.overdue,
        BackupState.never || BackupState.stale => DueState.due,
      };
}

/// The Vehicles row's subtitle.
///
/// Names up to [kNamedVehicleLimit], a count beyond it. Two rules, and each
/// earns its place: the reference draws names because they are what a user
/// recognises, and a garage of eight would push the row past the narrowest
/// phone's width — where §13 says rows wrap rather than truncate, so the count
/// is what keeps the screen the shape §13 describes.
String vehiclesSubtitle(
  AppLocalizations l10n,
  String tag,
  List<Vehicle> vehicles,
) {
  if (vehicles.length <= kNamedVehicleLimit) {
    return vehicles.map((v) => v.name).join(', ');
  }
  return l10n.settingsVehicleCount(
    vehicles.length,
    formatForDisplay(
      vehicles.length,
      tag,
      numerals: CalmNumerals.auto,
      decimalDigits: 0,
    ),
  );
}

/// The Units row's `km · L · €` summary.
///
/// Isolate-wrapped as one run: split, the currency symbol drags to the wrong
/// end of a Persian line, which is §5's whole reason for the isolate.
String unitsSummary(AppLocalizations l10n, SettingsRootState state) {
  final volume = state.volumeUnit == VolumeUnit.l
      ? l10n.unitVolumeLitre
      : l10n.unitVolumeGallon;
  return isolate(
    [
      distanceUnitLabel(l10n, state.distanceUnit),
      volume,
      state.currencyCode,
    ].join(' · '),
  );
}
