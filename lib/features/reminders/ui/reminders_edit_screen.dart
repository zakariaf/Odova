// `reminders.edit` — the one place a reminder's rules are set.
//
// SPEC.md §9's field table, in its order. Two rules govern the whole file:
// labels sit ABOVE inputs, never beside them, so German
// ("Wie weit im Voraus soll ich Bescheid sagen?") and Sorani wrap freely; and
// **Save is never silently disabled** — it validates, and every rejection is
// one inline sentence under the field it belongs to.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/notice_window.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/reminders/application/reminders_edit_notifier.dart';
import 'package:odova/features/reminders/application/reminders_list_notifier.dart';
import 'package:odova/features/reminders/domain/reminder_draft.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/unit_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_notice.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_segmented.dart';
import 'package:odova/ui/calm/calm_snackbar.dart';

/// The reminder editor, in create or edit mode.
class RemindersEditScreen extends ConsumerStatefulWidget {
  /// Creates the screen for [reminderId] — a `rem_<ULID>`, or `new`.
  const RemindersEditScreen({required this.reminderId, super.key});

  /// The path segment this form is editing.
  final String reminderId;

  @override
  ConsumerState<RemindersEditScreen> createState() =>
      _RemindersEditScreenState();
}

class _RemindersEditScreenState extends ConsumerState<RemindersEditScreen> {
  // One controller per text field, created once and disposed together. A
  // controller rebuilt on every frame loses the cursor position on every
  // keystroke.
  final Map<String, TextEditingController> _controllers = {};
  bool _seeded = false;

  TextEditingController _controller(String key, String initial) =>
      _controllers.putIfAbsent(key, () => TextEditingController(text: initial));

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(remindersEditProvider(widget.reminderId));
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;

    return switch (state) {
      ReminderEditLoading() => CalmScaffold(
        appBar: _head(l10n, saving: true),
        children: const [],
      ),
      // The row went while the form was opening. Nothing to edit and nothing to
      // say about it that the user can act on, so the modal closes itself
      // rather than sitting on an error about a reminder that no longer exists.
      ReminderEditMissing() => CalmScaffold(
        appBar: _head(l10n, saving: true),
        children: const [],
      ),
      final ReminderEditReady ready => _form(context, l10n, ready, tag),
    };
  }

  CalmAppBar _head(
    AppLocalizations l10n, {
    bool saving = false,
    String? itemLabel,
  }) => CalmAppBar.modal(
    // The ITEM's own name where there is one, the way the artboard draws
    // it: a modal head that says "Reminder" over a form about the oil
    // change names the screen rather than the thing.
    title: itemLabel?.trim().isNotEmpty ?? false
        ? itemLabel!.trim()
        : (widget.reminderId == kNewRecordId
              ? l10n.reminderNewTitle
              : l10n.reminderEditTitle),
    startLabel: l10n.commonCancel,
    onStart: () => unawaited(_dismiss()),
    endLabel: l10n.commonSave,
    // NEVER null. §9: "Save is never silently disabled" — it validates,
    // scrolls to the failing field and says why, which is the opposite of
    // a grey button with no explanation.
    onEnd: saving ? () {} : _save,
  );

  Widget _form(
    BuildContext context,
    AppLocalizations l10n,
    ReminderEditReady ready,
    String tag,
  ) {
    final draft = ready.draft;
    final space = CalmSpace.of(context);
    final unit = distanceUnitLabel(l10n, draft.unit);
    // Read, never recomputed. `save()` already validated this draft, against
    // the clock reading that decided whether the row was written; validating
    // again here would answer the same question at a different moment, and
    // this screen would own a second copy of the rules the notifier exists to
    // hold.
    final problems = ready.problems;

    // Seeded ONCE, when the row arrives. Re-seeding on every build would put
    // the stored value back over whatever the user is typing.
    if (!_seeded) {
      _seeded = true;
      _controller('label', draft.label);
      _controller('intervalDistance', draft.intervalDistance);
      _controller('intervalMonths', draft.intervalMonths);
      _controller('targetOdometer', draft.targetOdometer);
      _controller('baselineOdometer', draft.baselineOdometer);
      _controller('noticeDistance', draft.noticeDistance);
      _controller('noticeDays', draft.noticeDays);
      _controller('notes', draft.notes);
    }

    final notice = _automaticNotice(ready, l10n, tag);

    return CalmScaffold(
      appBar: _head(l10n, itemLabel: ready.item?.label),
      children: [
        // §9's two banners. Neither is dismissible: they state what is true
        // about the item and offer the one action that changes it.
        if (ready.item case final item?) ...[
          if (!item.isTracked)
            CalmNotice(
              icon: Icons.visibility_off_outlined,
              tone: CalmNoticeTone.info,
              children: [
                Text(l10n.reminderNotTrackedBanner),
                CalmButton(
                  label: l10n.reminderStartTracking,
                  variant: CalmButtonVariant.quiet,
                  size: CalmButtonSize.sm,
                  onPressed: () => unawaited(_setTracked(item, true)),
                ),
              ],
            )
          else if (!item.isActive)
            CalmNotice(
              icon: Icons.notifications_off_outlined,
              tone: CalmNoticeTone.info,
              children: [
                Text(l10n.remindersGroupPaused),
                CalmButton(
                  label: l10n.reminderTurnBackOn,
                  variant: CalmButtonVariant.quiet,
                  size: CalmButtonSize.sm,
                  onPressed: () => unawaited(_setActive(item, true)),
                ),
              ],
            ),
        ],
        CalmField(
          label: l10n.reminderName,
          controller: _controller('label', draft.label),
          errorText: problems.contains(ReminderProblem.customNeedsLabel)
              ? l10n.reminderName
              : null,
          onChanged: (text) => _edit((d) => d.copyWith(label: text)),
        ),
        CalmField(
          label: l10n.reminderEveryDistance,
          controller: _controller('intervalDistance', draft.intervalDistance),
          affix: Text(unit),
          numeric: true,
          keyboardType: TextInputType.number,
          onChanged: (text) => _edit((d) => d.copyWith(intervalDistance: text)),
        ),
        CalmField(
          label: l10n.reminderEveryMonths,
          controller: _controller('intervalMonths', draft.intervalMonths),
          // The one inline message §9 puts under the INTERVAL BLOCK rather
          // than under a field: none of the four is set, and no single one of
          // them is at fault.
          errorText: problems.contains(ReminderProblem.noSchedule)
              ? l10n.reminderNoScheduleError
              : null,
          numeric: true,
          keyboardType: TextInputType.number,
          onChanged: (text) => _edit((d) => d.copyWith(intervalMonths: text)),
        ),
        CalmField(
          label: l10n.reminderOnceAtOdometer,
          controller: _controller('targetOdometer', draft.targetOdometer),
          affix: Text(unit),
          numeric: true,
          keyboardType: TextInputType.number,
          onChanged: (text) => _edit((d) => d.copyWith(targetOdometer: text)),
        ),
        _DateRow(
          label: l10n.reminderOnceOnDate,
          value: draft.targetDate,
          tag: tag,
          onChanged: (date) => _edit(
            (d) => date == null
                ? d.copyWith(clearTargetDate: true)
                : d.copyWith(targetDate: date),
          ),
        ),
        _DateRow(
          label: l10n.reminderLastDoneDate,
          value: draft.baselineDate,
          tag: tag,
          errorText: problems.contains(ReminderProblem.baselineInFuture)
              ? l10n.reminderBaselineFutureError
              : null,
          onChanged: (date) => _edit(
            (d) => date == null
                ? d.copyWith(clearBaselineDate: true)
                : d.copyWith(baselineDate: date),
          ),
        ),
        CalmField(
          label: l10n.reminderLastDoneOdometer,
          controller: _controller('baselineOdometer', draft.baselineOdometer),
          affix: Text(unit),
          errorText:
              problems.contains(ReminderProblem.baselineBelowFirstReading)
              ? l10n.reminderBaselineTooLowError
              : null,
          numeric: true,
          keyboardType: TextInputType.number,
          onChanged: (text) => _edit((d) => d.copyWith(baselineOdometer: text)),
        ),
        CalmRowGroup(
          rows: [
            CalmListRow.switchRow(
              title: l10n.reminderNotify,
              value: draft.notify,
              onToggle: () => _edit((d) => d.copyWith(notify: !d.notify)),
            ),
            CalmListRow.switchRow(
              title: l10n.reminderRepeats,
              value: draft.repeats,
              onToggle: () => _edit((d) => d.copyWith(repeats: !d.repeats)),
            ),
          ],
        ),
        CalmField(
          label: l10n.reminderNoticeAhead,
          controller: _controller('noticeDistance', draft.noticeDistance),
          affix: Text(unit),
          numeric: true,
          keyboardType: TextInputType.number,
          onChanged: (text) => _edit((d) => d.copyWith(noticeDistance: text)),
        ),
        CalmField(
          // Its own NAME, and no visible label. §9 asks the question once,
          // above the pair — but two fields with one accessible name are two a
          // screen-reader user cannot tell apart, and that is not a layout
          // decision.
          label: l10n.reminderNoticeAheadDays,
          showLabel: false,
          controller: _controller('noticeDays', draft.noticeDays),
          numeric: true,
          keyboardType: TextInputType.number,
          onChanged: (text) => _edit((d) => d.copyWith(noticeDays: text)),
        ),
        // The automatic window as ONE hint under the pair, the way the artboard
        // draws it — not as a placeholder inside each field, which said the
        // same sentence twice. A placeholder-class value and never a stored
        // one: §2 forbids persisting a derived number, and a notice window
        // written into the row would survive an interval change and then be
        // wrong for ever.
        Text(notice),
        _Segmented(
          label: l10n.reminderPriority,
          options: [
            (ServicePriority.safety, l10n.reminderPrioritySafety),
            (ServicePriority.normal, l10n.reminderPriorityNormal),
            (ServicePriority.low, l10n.reminderPriorityLow),
          ],
          selected: draft.priority,
          onChanged: (value) => _edit((d) => d.copyWith(priority: value)),
        ),
        _Segmented(
          label: l10n.reminderRollover,
          options: [
            (ServiceRollover.fromActual, l10n.reminderRolloverActual),
            (ServiceRollover.fromDue, l10n.reminderRolloverDue),
          ],
          selected: draft.rollover,
          onChanged: (value) => _edit((d) => d.copyWith(rollover: value)),
        ),
        CalmField(
          label: l10n.reminderNotes,
          controller: _controller('notes', draft.notes),
          size: CalmFieldSize.multiline,
          onChanged: (text) => _edit((d) => d.copyWith(notes: text)),
        ),
        // §9's *Last done*: "the evidence behind the anchor, so a user who
        // thinks the app is wrong can check instead of argue."
        if (ready.records.isNotEmpty) ...[
          Text(l10n.reminderLastDoneHeading),
          CalmRowGroup(
            rows: [
              for (final record in ready.records)
                CalmListRow(
                  title: formatLongDate(record.occurredOn, tag),
                  value: record.odometer == null
                      ? null
                      : formatWithUnit(
                          record.odometer!.inUnit(draft.unit),
                          unit,
                          tag,
                          numerals: CalmNumerals.auto,
                          decimalDigits: 0,
                        ),
                  showChevron: true,
                  onTap: () {},
                ),
            ],
          ),
        ],
        SizedBox(height: space.s2),
        if (ready.item case final item?)
          if (ready.deletable)
            CalmButton(
              label: l10n.commonDelete,
              variant: CalmButtonVariant.danger,
              block: true,
              onPressed: () => unawaited(_delete(item)),
            )
          else ...[
            CalmButton(
              label: l10n.reminderTurnThisOff,
              variant: CalmButtonVariant.danger,
              block: true,
              onPressed: () => unawaited(_setActive(item, false)),
            ),
            Text(
              l10n.reminderCannotDelete(
                ready.lineCount,
                formatForDisplay(
                  ready.lineCount,
                  tag,
                  numerals: CalmNumerals.auto,
                  decimalDigits: 0,
                ),
              ),
            ),
          ],
      ],
    );
  }

  /// The automatic notice window, as §9's placeholder sentence.
  String _automaticNotice(
    ReminderEditReady ready,
    AppLocalizations l10n,
    String tag,
  ) {
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return '';

    // Against the DRAFT's schedule, not the stored row's: the placeholder has
    // to move when the user changes the interval, because that is the number it
    // is a tenth of.
    final window = noticeWindow(
      item: ServiceItem(
        id: ready.item?.id ?? _placeholderId,
        vehicleId: ready.vehicle.id,
        kind: ready.draft.kind,
        priority: ready.draft.priority,
        rollover: ready.draft.rollover,
        intervalDistance: ready.draft.intervalDistanceValue,
        intervalMonths: ready.draft.intervalMonthsValue,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      ),
      vehicle: ready.vehicle,
      settings: settings,
    );

    return l10n.reminderNoticeAutomatic(
      formatWithUnit(
        Distance(window.graceDistanceMetres).inUnit(ready.draft.unit),
        distanceUnitLabel(l10n, ready.draft.unit),
        tag,
        numerals: CalmNumerals.auto,
        decimalDigits: 0,
      ),
      l10n.homeDurationDays(
        window.graceDays,
        formatForDisplay(
          window.graceDays,
          tag,
          numerals: CalmNumerals.auto,
          decimalDigits: 0,
        ),
      ),
    );
  }

  void _edit(ReminderDraft Function(ReminderDraft) change) =>
      ref.read(remindersEditProvider(widget.reminderId).notifier).edit(change);

  Future<void> _save() async {
    final router = GoRouter.of(context);
    final written = await ref
        .read(remindersEditProvider(widget.reminderId).notifier)
        .save();
    // Null means REFUSED, and the form is already showing why. Popping here
    // would throw away the messages the user has to read.
    if (written != null && router.canPop()) router.pop();
  }

  Future<void> _dismiss() async {
    // `dialog.discard` is EPIC-08's global dialog and belongs to no feature.
    // Wiring it needs a dirty flag the draft does not carry yet — recorded in
    // epics/progress/EPIC-10.md — so a dismiss closes, and nothing is written
    // either way.
    final router = GoRouter.of(context);
    if (router.canPop()) router.pop();
  }

  Future<void> _setTracked(ServiceItem item, bool tracked) async {
    await ref
        .read(remindersListNotifierProvider.notifier)
        .setTracked(item.id, tracked: tracked);
    ref.invalidate(remindersEditProvider(widget.reminderId));
  }

  Future<void> _setActive(ServiceItem item, bool active) async {
    await ref
        .read(remindersListNotifierProvider.notifier)
        .setActive(item.id, active: active);
    ref.invalidate(remindersEditProvider(widget.reminderId));
  }

  Future<void> _delete(ServiceItem item) async {
    final l10n = AppLocalizations.of(context);
    final snackbars = CalmSnackbarHost.of(context);
    final router = GoRouter.of(context);
    final notifier = ref.read(
      remindersEditProvider(widget.reminderId).notifier,
    );

    final removed = await notifier.delete();
    if (removed is! Ok) {
      snackbars.show(message: l10n.saveDiskFullError, danger: true);
      return;
    }
    if (router.canPop()) router.pop();
    snackbars.show(
      message: l10n.homeTurnedOff(item.label ?? ''),
      actionLabel: l10n.commonUndo,
      onAction: () => unawaited(notifier.undoDelete(item.id)),
    );
  }
}

/// A stand-in id for the notice-window computation in create mode.
///
/// `noticeWindow` takes an item and reads only its intervals, so the id is
/// never used — but the type demands one, and minting a real ULID for a row
/// that may never be saved would burn an id the user never sees.
final ServiceItemId _placeholderId = ServiceItemId.tryParse(
  'rem_00000000000000000000000000',
)!;

/// A labelled date row. The label sits ABOVE, like every other field.
class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.tag,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final CivilDate? value;
  final String tag;
  final String? errorText;
  final ValueChanged<CivilDate?> onChanged;

  @override
  Widget build(BuildContext context) => CalmField(
    label: label,
    controller: TextEditingController(
      text: value == null ? '' : formatLongDate(value.toString(), tag),
    ),
    errorText: errorText,
    // READ-ONLY, and the picker is EPIC-11's: §10 owns the date control every
    // logging form shares, and a second one built here would be the second
    // calendar in an app that ships three.
    enabled: false,
  );
}

/// A labelled segmented control, with the label above it.
class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: space.s2,
      children: [
        CalmFieldLabel(label),
        CalmSegmented(
          labels: [for (final (_, text) in options) text],
          index: options.indexWhere((o) => o.$1 == selected),
          onChanged: (index) => onChanged(options[index].$1),
        ),
      ],
    );
  }
}
