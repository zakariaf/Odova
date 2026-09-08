// SPEC.md §13's `settings.notifications`, built against
// `design/reference/calm/settings.notifications-*.png`.
//
// Three groups, a calendar row and a footer — and a card at the top that this
// screen does not decide: `resolveNotificationsChrome` does, in one pure
// function, because §13's five states differ in more than a sentence and one
// of them reorders the screen.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/notifications/notification_permission_port.dart';
import 'package:odova/app/notifications/notification_settings_link.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/settings/data/settings_writer.dart';
import 'package:odova/features/settings/domain/notice_window.dart';
import 'package:odova/features/settings/domain/notifications_chrome.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_notice.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_sheet.dart';
import 'package:odova/ui/calm/calm_snackbar.dart';

/// The permission the screen reads, refreshed on every open.
///
/// Read rather than cached: a user can turn notifications off in the phone's
/// settings while the app is in the background, and a cached `granted` shows
/// them a screen full of controls that do nothing.
final FutureProvider<NotificationPermission> notificationPermissionState =
    FutureProvider<NotificationPermission>(
      (ref) => ref.watch(notificationPermissionProvider).read(),
    );

/// §13's notifications screen.
class NotificationsSettingsScreen extends ConsumerWidget {
  /// Creates the screen.
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;
    final settings = ref.watch(settingsProvider).value;
    final writer = ref.read(settingsWriterProvider);

    final notifyService = settings?.notifyService ?? true;
    final notifyOdometer = settings?.notifyOdometer ?? true;
    final notifyBackup = settings?.notifyBackup ?? true;
    final unit = effectiveDistanceUnit(null, settings);

    final chrome = resolveNotificationsChrome(
      // LOADING assumes granted and draws no card — the alternative is a
      // "Reminders are off" card that flashes on every open for a user whose
      // reminders are perfectly on.
      //
      // An ERROR does not. It used to: this was `.value ?? granted`, which
      // treats "the read failed" and "the read has not finished" as the same
      // thing — and the read failed on every build, because
      // `notificationPermissionProvider` threw and nothing wired it. The screen
      // drew a page of switches over an OS that had never been asked, and said
      // nothing. `neverAsked` is the honest answer to a read that failed, and
      // it is the state §4.6's pre-prompt exists for.
      permission: ref
          .watch(notificationPermissionState)
          .when(
            data: (permission) => permission,
            loading: () => NotificationPermission.granted,
            error: (_, _) => NotificationPermission.neverAsked,
          ),
      allCategoriesOff: !notifyService && !notifyOdometer && !notifyBackup,
    );

    return CalmScaffold(
      appBar: CalmAppBar.pushed(
        title: l10n.settingsNotificationsRow,
      ),
      children: [
        if (chrome.card case final card when card is! NotificationsNoCard) ...[
          _PermissionCard(card: card),
          SizedBox(height: space.s5),
        ],
        // §13's "Add reminders to my calendar" row is NOT here, and its
        // absence is a decision rather than an omission. SPEC.md §18 decision
        // 13 — "does the `.ics` calendar export ship in v1?" — is open, §6 §8
        // says yes, §13 specifies the row, and EPIC-16 says in writing that it
        // is out. A row wired to nothing is worse than no row, and building
        // the writer against an open decision is building something that may
        // be deleted. Recorded in `epics/progress/EPIC-14.md`; it returns with
        // the writer if the answer is yes.
        Text(
          l10n.notifGroupWhat,
          style: type.label.copyWith(color: colors.ink2),
        ),
        SizedBox(height: space.s3),
        CalmRowGroup(
          rows: [
            CalmListRow.switchRow(
              title: l10n.notifRowService,
              value: notifyService,
              onToggle: () =>
                  unawaited(writer.setNotifyService(notify: !notifyService)),
            ),
            CalmListRow.switchRow(
              title: l10n.notifRowOdometer,
              value: notifyOdometer,
              onToggle: () =>
                  unawaited(writer.setNotifyOdometer(notify: !notifyOdometer)),
            ),
            CalmListRow.switchRow(
              title: l10n.notifRowBackup,
              value: notifyBackup,
              onToggle: () =>
                  unawaited(writer.setNotifyBackup(notify: !notifyBackup)),
            ),
          ],
        ),
        SizedBox(height: space.s5),
        Text(
          l10n.notifGroupWhen,
          style: type.label.copyWith(color: colors.ink2),
        ),
        SizedBox(height: space.s3),
        CalmRowGroup(
          rows: [
            CalmListRow(
              title: l10n.notifRowTimeOfDay,
              value: formatMinutesOfDay(
                settings?.notificationTimeMinutes ??
                    kDefaultNotificationMinutes,
                tag,
              ),
              showChevron: true,
              onTap: () => unawaited(
                _pickTime(
                  context,
                  ref,
                  current:
                      settings?.notificationTimeMinutes ??
                      kDefaultNotificationMinutes,
                ),
              ),
            ),
            CalmListRow(
              title: l10n.notifRowQuietHours,
              value: quietHoursLabel(
                l10n,
                tag,
                from:
                    settings?.quietHoursFromMinutes ?? kDefaultQuietFromMinutes,
                to: settings?.quietHoursToMinutes ?? kDefaultQuietToMinutes,
              ),
              showChevron: true,
              onTap: () => unawaited(
                _pickQuietHours(
                  context,
                  ref,
                  from:
                      settings?.quietHoursFromMinutes ??
                      kDefaultQuietFromMinutes,
                  to: settings?.quietHoursToMinutes ?? kDefaultQuietToMinutes,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: space.s5),
        Text(
          l10n.notifGroupHowFar,
          style: type.label.copyWith(color: colors.ink2),
        ),
        SizedBox(height: space.s3),
        CalmRowGroup(
          footer: l10n.notifAutomaticNote(
            formatForDisplay(
              kAutomaticNoticePercent,
              tag,
              numerals: CalmNumerals.auto,
              decimalDigits: 0,
              grouped: false,
            ),
          ),
          rows: [
            CalmListRow(
              title: l10n.notifRowByDistance,
              value: settings?.noticeDistance == null
                  ? l10n.notifAutomatic
                  : formatDistanceFigure(
                      l10n,
                      tag,
                      settings!.noticeDistance!,
                      unit,
                      estimated: false,
                    ),
              showChevron: true,
              onTap: () => unawaited(
                _pickNoticeDistance(context, ref, unit: unit),
              ),
            ),
            CalmListRow(
              title: l10n.notifRowByTime,
              value: settings?.noticeDays == null
                  ? l10n.notifAutomatic
                  : l10n.homeDurationDays(
                      settings!.noticeDays!,
                      formatForDisplay(
                        settings.noticeDays!,
                        tag,
                        numerals: CalmNumerals.auto,
                        decimalDigits: 0,
                      ),
                    ),
              showChevron: true,
              onTap: () => unawaited(_pickNoticeDays(context, ref)),
            ),
          ],
        ),
        SizedBox(height: space.s4),
        // A FACT, not a switch. A user who could raise the cap would, and
        // would then blame the app for the noise §14's damping exists to
        // prevent.
        Text(
          l10n.notifCapFooter,
          style: type.caption.copyWith(color: colors.ink3),
        ),
        if (chrome.showsSilentFooter) ...[
          SizedBox(height: space.s3),
          // What still works. The alternative reading of three switches off is
          // that the app has stopped doing anything.
          Text(
            l10n.notifSilentFooter,
            style: type.caption.copyWith(color: colors.ink3),
          ),
        ],
      ],
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref, {
    required int current,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    // LOCAL WALL-CLOCK minutes, never an instant. §14 delivers at 09:00 in
    // whatever timezone the phone is in, and a stored instant would move the
    // delivery when the user flies.
    await ref
        .read(settingsWriterProvider)
        .setNotificationTime(picked.hour * 60 + picked.minute);
  }

  /// Both ends of §13's quiet-hours window, in one flow.
  ///
  /// The row shipped as `onTap: () {}` — drawn, chevroned, and dead — with the
  /// write path already written and tested underneath it. That is the exact
  /// shape of defect this project keeps finding, and it is invisible to every
  /// test that asserts the row is DRAWN.
  ///
  /// Two pickers rather than a range control: a range widget for two times is
  /// a component nobody else needs, and cancelling the second one leaves the
  /// window unchanged rather than half-set.
  Future<void> _pickQuietHours(
    BuildContext context,
    WidgetRef ref, {
    required int from,
    required int to,
  }) async {
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: from ~/ 60, minute: from % 60),
    );
    if (start == null || !context.mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: to ~/ 60, minute: to % 60),
    );
    if (end == null) return;

    // BOTH ends in one write. They are one window and one decision, and two
    // writes would leave a frame in which the window is inverted — the shape
    // that silences a whole day rather than a night.
    await ref
        .read(settingsWriterProvider)
        .setQuietHours(
          from: start.hour * 60 + start.minute,
          to: end.hour * 60 + end.minute,
        );
  }

  Future<void> _pickNoticeDistance(
    BuildContext context,
    WidgetRef ref, {
    required DistanceUnit unit,
  }) => _pickOption<Distance?>(
    context,
    title: AppLocalizations.of(context).notifRowByDistance,
    options: [null, ...noticeDistanceOptions(unit)],
    labelFor: (value) {
      final l10n = AppLocalizations.of(context);
      if (value == null) return l10n.notifAutomatic;
      return formatDistanceFigure(
        l10n,
        ref.read(resolvedLocaleTagsProvider).formats,
        value,
        unit,
        estimated: false,
      );
    },
    onChosen: (value) =>
        ref.read(settingsWriterProvider).setNoticeDistance(value),
  );

  Future<void> _pickNoticeDays(BuildContext context, WidgetRef ref) =>
      _pickOption<int?>(
        context,
        title: AppLocalizations.of(context).notifRowByTime,
        options: [null, ...kNoticeDays],
        labelFor: (value) {
          final l10n = AppLocalizations.of(context);
          if (value == null) return l10n.notifAutomatic;
          return l10n.homeDurationDays(
            value,
            formatForDisplay(
              value,
              ref.read(resolvedLocaleTagsProvider).formats,
              numerals: CalmNumerals.auto,
              decimalDigits: 0,
            ),
          );
        },
        onChosen: (value) =>
            ref.read(settingsWriterProvider).setNoticeDays(value),
      );

  Future<void> _pickOption<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required String Function(T) labelFor,
    required Future<void> Function(T) onChosen,
  }) => CalmSheet.show<void>(
    context,
    builder: (sheetContext) => CalmSheet(
      title: title,
      children: [
        CalmRowGroup(
          rows: [
            for (final option in options)
              CalmListRow(
                title: labelFor(option),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(onChosen(option));
                },
              ),
          ],
        ),
      ],
    ),
  );
}

/// §13's quiet-hours value — `21:00–08:00`, or `Off`.
///
/// ONE isolate around the whole run, so the two times and the en dash cannot
/// be split: under RTL a half-isolated range reads back-to-front, and
/// `08:00–21:00` is a different window from the one the user set.
///
/// `from == to` is OFF, not a zero-length window. A user who dragged both ends
/// together meant "no quiet hours", and a window of zero minutes is a rule
/// that silences nothing while looking like a rule.
String quietHoursLabel(
  AppLocalizations l10n,
  String formatsTag, {
  required int from,
  required int to,
}) {
  if (from == to) return l10n.notifQuietOff;
  return isolate(
    '${formatMinutesOfDay(from, formatsTag)}–'
    '${formatMinutesOfDay(to, formatsTag)}',
  );
}

/// Asks the OS, then re-reads it so the card answers to the new state.
Future<void> _ask(WidgetRef ref) async {
  await ref.read(notificationPermissionProvider).request();
  // INVALIDATED rather than assumed. `request()` returns what the OS said and
  // the screen could take that word for it — but a user can change the answer
  // in Settings between the dialog and the rebuild, and this file's own
  // `read()` doc says a cached grant "shows them a screen full of controls
  // that do nothing".
  ref.invalidate(notificationPermissionState);
}

class _PermissionCard extends ConsumerWidget {
  const _PermissionCard({required this.card});

  final NotificationsCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);

    final (message, action) = switch (card) {
      NotificationsOffCard() => (l10n.notifOffTitle, l10n.notifOffAction),
      NotificationsBlockedCard() => (
        l10n.notifBlockedTitle,
        l10n.notifBlockedAction,
      ),
      NotificationsBackgroundRestrictedCard() => (
        l10n.notifBackgroundTitle,
        l10n.notifBlockedAction,
      ),
      NotificationsNoCard() => (null, null),
    };
    if (message == null || action == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CalmNotice(
          icon: Icons.notifications_off_outlined,
          tone: CalmNoticeTone.warn,
          children: [Text(message, style: CalmType.of(context).body)],
        ),
        SizedBox(height: space.s3),
        // ROUTED BY CARD. Every one of these three called `_ask`, and only one
        // of them should: asking is the right move on `neverAsked` and a no-op
        // on the other two. iOS shows its permission dialog ONCE per install,
        // so after a refusal `request()` answers instantly from cached state
        // and nothing appears — a person tapping "Open phone settings" and
        // watching nothing happen is what found it. On §14's card the
        // permission is already granted, so asking cannot even fail visibly.
        //
        // The deep link is a method channel of our own with two verbs and no
        // arguments, for the reason `share_service.dart` gives: `url_launcher`
        // takes a URL, and SPEC.md §2's "zero network calls" is a claim about
        // what the code CAN do.
        CalmButton(
          label: action,
          variant: CalmButtonVariant.secondary,
          onPressed: () => unawaited(switch (card) {
            NotificationsOffCard() => _ask(ref),
            NotificationsBlockedCard() => _openSettings(
              context,
              ref,
              details: false,
            ),
            // The app DETAILS page, not the notification page. An OEM battery
            // manager is what §14's card is about, and the notification screen
            // looks entirely correct on a phone that has one.
            //
            // UNREACHABLE today, and deliberately written anyway: the screen
            // never passes `deliveriesUnconfirmed`, because §14's ledger of
            // unseen deliveries does not exist yet — the same status as
            // `calendarFirst` in `notifications_chrome.dart`. The arm is the
            // answer to a question this switch will be asked the day that
            // ledger lands, and leaving it calling `_ask` — on a card where
            // the permission is already GRANTED, so asking cannot even fail
            // visibly — is how it would arrive dead.
            NotificationsBackgroundRestrictedCard() => _openSettings(
              context,
              ref,
              details: true,
            ),
            // Unreachable: the caller returns early when both strings are null.
            NotificationsNoCard() => Future<void>.value(),
          }),
        ),
      ],
    );
  }
}

/// Opens the phone's settings, and says so when it cannot.
///
/// §1: a control that refuses explains itself. A door that silently fails to
/// open is the same defect this button already had once — and on a platform
/// with no native half, or an OEM that ships neither screen, `false` is a real
/// answer rather than a rare one.
Future<void> _openSettings(
  BuildContext context,
  WidgetRef ref, {
  required bool details,
}) async {
  final link = ref.read(notificationSettingsLinkProvider);
  // CAPTURED BEFORE the await. `async_safety`: a BuildContext used after one is
  // a context that may be gone, and this awaits an OS round trip on a screen
  // the user can leave.
  final snackbars = CalmSnackbarHost.of(context);
  final message = AppLocalizations.of(context).notifSettingsOpenFailed;

  final opened = details
      ? await link.openAppDetailsSettings()
      : await link.openNotificationSettings();
  if (!opened) snackbars.show(message: message);
}
