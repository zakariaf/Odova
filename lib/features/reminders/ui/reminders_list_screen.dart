// `reminders.list` — the full catalogue for one vehicle.
//
// SPEC.md §9: "what Home's three cards left out, plus untracked items the user
// can switch on." Three groups whose HEADERS carry the vocabulary the rows do
// not print, so the screen needs no legend — and the first group uses Home's
// own dots, colours and wording, which is why the copy comes from
// `lib/l10n/due_copy.dart` rather than from a second mapper here.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/active_vehicle.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/reminders/application/reminders_list_notifier.dart';
import 'package:odova/features/reminders/domain/reminders_groups.dart';
import 'package:odova/l10n/due_copy.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_snackbar.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';
import 'package:odova/ui/calm/calm_swipe_actions.dart';

/// The reminder catalogue.
class RemindersListScreen extends ConsumerWidget {
  /// Creates the screen.
  const RemindersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vehicleId = ref.watch(activeVehicleIdProvider);
    final vehicles = ref.watch(vehiclesProvider).value;
    final vehicle = vehicleId == null || vehicles == null
        ? null
        : vehicles.where((v) => v.id == vehicleId).firstOrNull;
    final groups = vehicleId == null
        ? null
        : ref.watch(remindersListProvider(vehicleId));

    if (vehicle == null || groups == null) {
      return CalmScaffold(
        appBar: CalmAppBar(title: l10n.remindersTitle),
        children: const [],
      );
    }

    final tag = ref.watch(resolvedLocaleTagsProvider).formats;
    final unit =
        vehicle.distanceUnit ??
        ref.watch(settingsProvider).value?.distanceUnit ??
        DistanceUnit.km;

    return CalmScaffold(
      appBar: CalmAppBar(
        title: l10n.remindersTitle,
        actions: [
          CalmAppBarAction(
            label: l10n.commonAdd,
            icon: Icons.add,
            onTap: () => unawaited(context.push(Routes.reminderNew)),
          ),
        ],
      ),
      children: [
        if (groups.isEmpty)
          _Note(l10n.remindersEmpty)
        else ...[
          // The SAME key as the first-run catalogue. §9: "one string, one place
          // to fix it" — a second copy is a second disclaimer, and only one of
          // them gets corrected.
          _Note(l10n.remindersDisclaimer),
          if (groups.allPaused) _Note(l10n.remindersNothingTracked),
          if (groups.active.isNotEmpty)
            _Group(
              rows: groups.active,
              tag: tag,
              unit: unit,
              onOpen: (item) => _open(context, item),
              onSwipe: (item, action) => _swipe(context, ref, item, action),
            ),
          if (groups.paused.isNotEmpty) ...[
            _Header(l10n.remindersGroupPaused),
            _Group(
              rows: groups.paused,
              tag: tag,
              unit: unit,
              onOpen: (item) => _open(context, item),
              onSwipe: (item, action) => _swipe(context, ref, item, action),
            ),
          ],
          if (groups.notTracked.isNotEmpty) ...[
            _Header(l10n.remindersGroupNotTracked),
            _Group(
              rows: groups.notTracked,
              tag: tag,
              unit: unit,
              onOpen: (item) => unawaited(_track(context, ref, item)),
              onSwipe: (item, action) => _swipe(context, ref, item, action),
            ),
          ],
        ],
      ],
    );
  }

  void _open(BuildContext context, ServiceItem item) =>
      unawaited(context.push(Routes.reminderEdit(item.id.toString())));

  /// §9's `+ Track`: the flag, then the editor.
  ///
  /// In that order and not the other way round: "a tracked item with no anchor
  /// is just another `unknown`", so the row has to become a reminder before the
  /// screen that asks when it was last done can mean anything.
  Future<void> _track(
    BuildContext context,
    WidgetRef ref,
    ServiceItem item,
  ) async {
    final snackbars = CalmSnackbarHost.of(context);
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);

    final written = await ref
        .read(remindersListNotifierProvider.notifier)
        .setTracked(item.id, tracked: true);
    if (written is! Ok) {
      snackbars.show(message: l10n.saveDiskFullError, danger: true);
      return;
    }
    unawaited(router.push<void>(Routes.reminderEdit(item.id.toString())));
  }

  Future<void> _swipe(
    BuildContext context,
    WidgetRef ref,
    ServiceItem item,
    ReminderSwipe action,
  ) async {
    final snackbars = CalmSnackbarHost.of(context);
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(remindersListNotifierProvider.notifier);

    switch (action) {
      // EPIC-11 owns `log.service`'s mark-done path; this pushes the route with
      // the item and today, which is the whole navigation contract §9 states.
      case ReminderSwipe.doneToday:
        unawaited(
          context.push(
            Routes.log(LogType.service, itemId: item.id.toString()),
          ),
        );
      // `dialog.snooze` is EPIC-08's global dialog and the snooze WRITE is task
      // 10.8's. Named rather than defaulted, so the day it lands the switch is
      // already three cases and not two plus a silence.
      case ReminderSwipe.snooze:
        break;
      case ReminderSwipe.turnOff:
        final written = await notifier.setActive(item.id, active: false);
        if (written is! Ok) {
          snackbars.show(message: l10n.saveDiskFullError, danger: true);
          return;
        }
        snackbars.show(
          message: l10n.homeTurnedOff(item.label ?? ''),
          actionLabel: l10n.commonUndo,
          onAction: () => unawaited(notifier.setActive(item.id, active: true)),
        );
    }
  }
}

/// What a swipe on a reminder row offers. §9 names three, in this order.
enum ReminderSwipe {
  /// Writes a `ServiceRecord` through the logging mark-done path.
  doneToday,

  /// Opens `dialog.snooze`.
  snooze,

  /// `is_active = false`, with an Undo.
  turnOff,
}

/// One group of rows, inside one `CalmRowGroup`.
class _Group extends StatelessWidget {
  const _Group({
    required this.rows,
    required this.tag,
    required this.unit,
    required this.onOpen,
    required this.onSwipe,
  });

  final List<ReminderRow> rows;
  final String tag;
  final DistanceUnit unit;
  final void Function(ServiceItem) onOpen;
  final void Function(ServiceItem, ReminderSwipe) onSwipe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CalmRowGroup(
      rows: [
        // The swipe wraps each ROW, inside the group, the way the garage does
        // it: §9 gives the actions to a row, and a group-level swipe would act
        // on whichever one the finger happened to start over.
        for (final row in rows)
          CalmSwipeActions(
            endActions: [
              // All three are `caution`. §9 assigns no tones here, Calm has
              // exactly two, and `danger` is reserved for "destructive, and
              // behind a confirmation of its own" — none of these is: Done
              // today writes a record, Snooze opens a dialog, and Turn off
              // comes back with an Undo. A third, quieter tone is a design
              // question, and is recorded as one rather than invented here.
              CalmSwipeAction(
                label: l10n.actionDoneToday,
                icon: Icons.check,
                tone: CalmSwipeTone.caution,
                onPressed: () => onSwipe(row.item, ReminderSwipe.doneToday),
              ),
              CalmSwipeAction(
                // The SHORT key. A swipe tile is 88pt wide with a glyph above
                // its label, and the Persian `actionSnooze` overflows it by
                // 4pt — the menu row keeps the fuller phrase.
                label: l10n.actionSnoozeShort,
                icon: Icons.schedule_outlined,
                tone: CalmSwipeTone.caution,
                onPressed: () => onSwipe(row.item, ReminderSwipe.snooze),
              ),
              CalmSwipeAction(
                label: l10n.actionTurnOffShort,
                icon: Icons.notifications_off_outlined,
                tone: CalmSwipeTone.caution,
                onPressed: () => onSwipe(row.item, ReminderSwipe.turnOff),
              ),
            ],
            child: CalmListRow(
              title: row.item.label ?? l10n.vehicleStatusItemGeneric,
              lead: row.assessment == null
                  ? null
                  : CalmStatusDot(
                      style: CalmStatusStyle.of(context, row.assessment!.state),
                    ),
              // The END text carries the status for a tracked row, the word
              // "Paused" for a paused one and `+ Track` for an untracked one —
              // §9's three vocabularies, and the reason the screen needs no
              // legend.
              value: _endText(l10n, row),
              detailState: row.assessment?.state,
              showChevron: row.item.isTracked,
              onTap: () => onOpen(row.item),
            ),
          ),
      ],
    );
  }

  String _endText(AppLocalizations l10n, ReminderRow row) {
    if (!row.item.isTracked) return l10n.remindersTrack;
    if (!row.item.isActive) return l10n.remindersPausedStatus;

    final assessment = row.assessment;
    // §9's `reminders.list` drawing gives a tracked item the app cannot date
    // the QUESTION rather than a blank: "When was this last done".
    if (assessment == null) return l10n.remindersWhenLastDone;
    return dueStatusLine(l10n, tag, assessment, unit);
  }
}

/// A group separator — `— Paused ————`.
class _Header extends StatelessWidget {
  const _Header(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.only(start: space.s2, top: space.s2),
      child: Text(
        label,
        style: type.caption.copyWith(
          color: colors.ink2,
          fontWeight: type.medium,
        ),
      ),
    );
  }
}

/// One plain line — the disclaimer, the empty state, the all-paused note.
class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final type = CalmType.of(context);

    return Text(text, style: type.caption.copyWith(color: colors.ink2));
  }
}
