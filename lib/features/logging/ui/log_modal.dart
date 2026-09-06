// The chrome all four log forms wear, and the rules that belong to none of
// them.
//
// SPEC.md §10 *The log modal shell*: "The four `log.*` screens are one modal
// with four bodies." Everything in this file is a decision made once for all
// four — the app bar, the segment bar, the pinned Save, the discard guard — and
// a segment body knows none of it. Four forms that each decided their own Save
// would read as four apps.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/routing/dirty_modal_guard.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/logging/application/log_modal_notifier.dart';
import 'package:odova/features/logging/domain/expense_draft.dart';
import 'package:odova/features/logging/domain/price_trio.dart';
import 'package:odova/features/logging/domain/service_cost_model.dart';
import 'package:odova/features/logging/ui/log_expense_body.dart';
import 'package:odova/features/logging/ui/log_fillup_body.dart';
import 'package:odova/features/logging/ui/log_odometer_body.dart';
import 'package:odova/features/logging/ui/log_service_body.dart';
import 'package:odova/features/logging/ui/odometer_field.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_segmented.dart';
import 'package:odova/ui/dialogs/discard_dialog.dart';

/// The segment bar, for the tests that must tell it from a body's own
/// segmented control.
///
/// `log.fillup` draws a second one — §10's full/part fill — so "is there a
/// `CalmSegmented`" stopped being the same question as "is the segment bar
/// showing" the moment the bodies were wired in.
const Key kLogSegmentBarKey = Key('log.segmentBar');

/// The log modal, on whichever segment it was opened.
class LogModalShell extends ConsumerStatefulWidget {
  /// Creates the shell.
  const LogModalShell({required this.type, super.key, this.entryId});

  /// The segment the URL named. In create mode the user may change it; in edit
  /// mode it is fixed, because an entry cannot change type.
  final LogType type;

  /// The record being edited, or null in create mode.
  final String? entryId;

  @override
  ConsumerState<LogModalShell> createState() => _LogModalShellState();
}

class _LogModalShellState extends ConsumerState<LogModalShell> {
  /// The segment on screen.
  ///
  /// Widget state, seeded from the URL — a deep link and the tab bar's `+` both
  /// name the segment in the path, and §10's "opens on Fill-up whatever the
  /// caller" is delivered by making that the path the `+` builds. The DRAFTS
  /// live in the notifier because they must outlive a segment switch; which one
  /// is showing need not.
  late LogType _segment = widget.type;

  PriceTrio _trio = const PriceTrio();
  ServiceCostModel _cost = const ServiceCostModel();
  ExpenseDraft _expense = const ExpenseDraft();
  String _odometer = '';
  bool _isFullTank = true;
  String get _quantityUnit => 'L';

  final Map<TrioField, TextEditingController> _trioControllers = {
    for (final field in TrioField.values) field: TextEditingController(),
  };
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();

  /// The date every form on this modal is dated.
  ///
  /// One value for all four segments: a user who typed a date, switched
  /// segments and switched back would not expect to have to type it again.
  final String _occurredOn = '2026-09-02';

  @override
  void dispose() {
    for (final controller in _trioControllers.values) {
      controller.dispose();
    }
    _totalController.dispose();
    _amountController.dispose();
    _labelController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  /// One of the three was edited: recompute and write back the computed one.
  ///
  /// The controller for the COMPUTED field is updated here and nowhere else —
  /// §10 forbids recomputing an edited field, so the one the user is typing in
  /// is never touched and their caret never moves.
  void _onTrioChanged(TrioField field, String text) {
    setState(() {
      _trio = _trio.edited(field, text);
      final computed = _trio.computedField;
      if (computed == null) return;
      final value = switch (computed) {
        TrioField.quantity => _trio.quantity,
        TrioField.pricePerUnit => _trio.pricePerUnit,
        TrioField.total => _trio.total,
      };
      if (_trioControllers[computed]!.text != value) {
        _trioControllers[computed]!.text = value;
      }
    });
  }

  /// Whether this modal edits an existing row.
  ///
  /// The presence of an id, not a mode flag: `/log/fillup` and
  /// `/log/fillup/fil_…` are two routes and the id is the only thing that
  /// differs between them.
  bool get _isEdit => widget.entryId != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // WATCHED, not read. The provider is `autoDispose`, so without a listener
    // it is created and disposed on the spot and every draft goes with it —
    // which is the opposite of §10's "per-segment drafts live in memory for
    // the life of the modal". The subscription IS that lifetime.
    ref.watch(logModalProvider);

    return DirtyModalGuard(
      isDirty: _isDirty,
      onDiscard: _discardEverySegment,
      confirmDiscard: (context) async =>
          await showDiscardDialog(
            context,
            subject: _title(l10n),
            summary: l10n.logDiscardSummary,
          ) ==
          DiscardChoice.discard,
      child: CalmScaffold(
        appBar: CalmAppBar.modal(
          title: _title(l10n),
          startLabel: l10n.commonClose,
          // A GLYPH per the artboard, and named all the same: a bare ✕
          // announced as "button" leaves the only way out of a full-screen
          // modal unlabelled.
          startIcon: Icons.close,
          onStart: _dismiss,
          endLabel: l10n.commonSave,
          // NEVER null. §10: "Save is never disabled on the four log.*
          // segments. On tap it validates, scrolls to the first failing field,
          // focuses it, shows one inline error beneath it." A greyed-out Save
          // tells the user nothing about what it wants.
          onEnd: _save,
        ),
        // No footer on `log.odometer`: §10 puts Save "in the app bar, and as a
        // full-width primary button pinned above the keyboard", and on that
        // screen the keypad IS the keyboard — its confirm key is that button,
        // which is how the artboard draws it. A footer as well would be three
        // Saves, two of them adjacent.
        footer: _segment == LogType.odometer
            ? null
            : CalmButton(
                label: _saveLabel(l10n),
                block: true,
                size: CalmButtonSize.lg,
                onPressed: _save,
              ),
        children: [
          // Create mode only: an entry cannot change type, so an edit that
          // offered the choice would be offering to delete this row and write
          // a different one.
          if (!_isEdit)
            CalmSegmented(
              key: kLogSegmentBarKey,
              labels: [
                l10n.logSegmentFillUp,
                l10n.logSegmentService,
                l10n.logSegmentExpense,
                l10n.logSegmentOdometer,
              ],
              index: LogType.values.indexOf(_segment),
              onChanged: (index) =>
                  setState(() => _segment = LogType.values[index]),
            ),
          _body(),
        ],
      ),
    );
  }

  /// The form for whichever segment is showing.
  ///
  /// The shell knows nothing about what any of them contains — it hands each
  /// one its draft and its callbacks and gets a widget back. That is the seam
  /// §10 is built around: "a segment body knows nothing about" the chrome, and
  /// the chrome returns the compliment.
  Widget _body() => switch (_segment) {
    LogType.fillUp => LogFillUpBody(
      odometer: _odometerField(),
      dateRow: _dateRow(),
      trio: _trio,
      quantityUnit: _quantityUnit,
      isFullTank: _isFullTank,
      controllers: _trioControllers,
      onTrioChanged: _onTrioChanged,
      onFullTankChanged: (full) => setState(() => _isFullTank = full),
    ),
    LogType.service => LogServiceBody(
      odometer: _odometerField(),
      dateRow: _dateRow(),
      items: const [],
      cost: _cost,
      totalController: _totalController,
      onToggleItem: (_) {},
      onAddOther: () {},
      onTotalChanged: (text) => setState(() => _cost = _cost.withTotal(text)),
      onSplitChanged: (on) =>
          setState(() => _cost = on ? _cost.split() : _cost),
    ),
    LogType.expense => LogExpenseBody(
      draft: _expense,
      categoryLabel: (c) => c.wire,
      amountController: _amountController,
      labelController: _labelController,
      onCategoryChanged: (c) =>
          setState(() => _expense = _expense.withCategory(c)),
      onAmountChanged: (text) =>
          setState(() => _expense = _expense.withAmount(text)),
      onLabelChanged: (text) =>
          setState(() => _expense = _expense.withLabel(text)),
      onRefundChanged: (on) =>
          setState(() => _expense = on ? _expense.refunded() : _expense),
    ),
    LogType.odometer => LogOdometerBody(
      value: _odometer,
      unit: DistanceUnit.km,
      formatsTag: 'en',
      occurredOn: _occurredOn,
      onValueChanged: (v) => setState(() => _odometer = v),
      onSave: _save,
      onPickDate: () {},
    ),
  };

  /// §10's shared odometer field.
  ///
  /// Built ONCE here and handed to whichever body needs it, because "this one
  /// field feeds the due engine, so it behaves identically on `log.fillup`,
  /// `log.service` and `log.odometer`" — and three bodies each constructing
  /// their own would be three chances to disagree about the reading history it
  /// compares against.
  Widget _odometerField() => OdometerField(
    controller: _odometerController,
    unit: DistanceUnit.km,
    existing: const [],
    corrections: const [],
    occurredOn: _occurredOn,
    formatsTag: 'en',
    onChanged: (_) => setState(() {}),
    onUnitChanged: (_) {},
  );

  /// The date row every form carries.
  ///
  /// A read-only row that opens the picker, per §10's Field kit: "Date — none;
  /// a read-only row opening the calendar picker." The picker itself is the
  /// shared control EPIC-09 deferred to this epic and is not built yet, so the
  /// row renders the date and does not yet open anything.
  Widget _dateRow() => CalmRowGroup(
    rows: [
      CalmListRow(
        title: AppLocalizations.of(context).reminderOnceOnDate,
        value: formatLongDate(_occurredOn, 'en'),
        showChevron: true,
        size: CalmRowSize.compact,
      ),
    ],
  );

  /// The modal's title: the form's own name in create mode, the record's in
  /// edit mode.
  ///
  /// `logTitle*` and not `logSegment*`, which are four DIFFERENT keys. The
  /// artboard's Persian reads سوخت‌گیری in the modal head and سوخت in the
  /// segment bar, and کیلومترشمار against کیلومتر — so the design wants two
  /// words where English happens to have one. One key would have made every
  /// RTL locale choose which of the two to be wrong about.
  String _title(AppLocalizations l10n) => switch ((_segment, _isEdit)) {
    (LogType.fillUp, false) => l10n.logTitleFillUp,
    (LogType.service, false) => l10n.logTitleService,
    (LogType.expense, false) => l10n.logTitleExpense,
    (LogType.odometer, false) => l10n.logTitleOdometer,
    (LogType.fillUp, true) => l10n.logEditFillUpTitle,
    (LogType.service, true) => l10n.logEditServiceTitle,
    (LogType.expense, true) => l10n.logEditExpenseTitle,
    (LogType.odometer, true) => l10n.logEditOdometerTitle,
  };

  /// The pinned button's own words.
  ///
  /// Segment-specific where the app bar's stays the plain verb, because the
  /// artboard draws it that way and because a full-width button at the bottom
  /// of a scrolled form is often the only thing on screen naming what is about
  /// to happen.
  String _saveLabel(AppLocalizations l10n) => switch (_segment) {
    LogType.fillUp => l10n.logSaveFillUp,
    LogType.service => l10n.logSaveService,
    LogType.expense => l10n.logSaveExpense,
    LogType.odometer => l10n.logSaveOdometer,
  };

  /// Whether anything would be lost by leaving.
  ///
  /// Asked of the MODAL, not of the visible body: a user who typed into Expense
  /// and switched to Fill-up still has something to lose, and a guard that
  /// asked only the segment on screen would let it go silently.
  bool _isDirty() => ref.read(logModalProvider).isDirty;

  /// Drops all four drafts.
  ///
  /// ONE callback, because §10's Discard "drops EVERY segment's draft, not only
  /// the visible one" — a user who mis-tapped the segment bar twice and then
  /// discarded has said one thing, not four.
  void _discardEverySegment() => ref.read(logModalProvider.notifier).discard();

  /// The ✕, routed through the guard rather than around it.
  ///
  /// `maybePop` and not `DirtyModalGuard.of(context).requestDismiss()`: the
  /// guard is built INSIDE this `build`, so this State's context sits above it
  /// and `of` would not find it without a `Builder` in between. The guard
  /// mounts a `PopScope(canPop: false)`, so a `maybePop` from anywhere in the
  /// route reaches it — which is how `vehicle.edit` and `reminders.edit`
  /// already do it, and one mechanism for three modals is better than two.
  void _dismiss() => unawaited(Navigator.of(context).maybePop());

  void _save() {}
}
