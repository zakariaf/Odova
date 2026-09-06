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
import 'package:go_router/go_router.dart';
import 'package:odova/app/active_vehicle.dart';
import 'package:odova/app/routing/dirty_modal_guard.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/odometer/odometer_entry.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/due_snapshot_provider.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/logging/application/expense_save.dart';
import 'package:odova/features/logging/application/fillup_save.dart';
import 'package:odova/features/logging/application/log_modal_notifier.dart';
import 'package:odova/features/logging/application/log_save_service.dart';
import 'package:odova/features/logging/application/odometer_log_save.dart';
import 'package:odova/features/logging/application/service_save.dart';
import 'package:odova/features/logging/domain/expense_draft.dart';
import 'package:odova/features/logging/domain/fillup_draft.dart';
import 'package:odova/features/logging/domain/price_trio.dart';
import 'package:odova/features/logging/domain/service_cost_model.dart';
import 'package:odova/features/logging/domain/service_item_chips.dart';
import 'package:odova/features/logging/ui/log_expense_body.dart';
import 'package:odova/features/logging/ui/log_fillup_body.dart';
import 'package:odova/features/logging/ui/log_more_sheet.dart';
import 'package:odova/features/logging/ui/log_odometer_body.dart';
import 'package:odova/features/logging/ui/log_service_body.dart';
import 'package:odova/features/logging/ui/odometer_field.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/expense_labels.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_segmented.dart';
import 'package:odova/ui/calm/calm_snackbar.dart';
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

  /// The locale these forms format and PARSE in.
  ///
  /// One stub, not five. Every number the user types is read against this
  /// locale's grouping separator, so it has to be the same answer everywhere
  /// on the form — `1.234,50` is twelve hundred and thirty-four fifty in de-DE
  /// and something else entirely against a Latin comma. Wiring it to the
  /// locale provider is one line here rather than a hunt through the file.
  // TODO(EPIC-11): read from the locale provider with the selected vehicle.
  String get _formatsTag => 'en';

  late final String _groupingSeparator = groupingSeparatorFor(_formatsTag);

  late FillUpDraft _fillUp = FillUpDraft(
    trio: PriceTrio(groupingSeparator: _groupingSeparator),
  );
  late ServiceCostModel _cost = ServiceCostModel(
    groupingSeparator: _groupingSeparator,
  );
  late ExpenseDraft _expense = ExpenseDraft(
    groupingSeparator: _groupingSeparator,
  );
  String _odometer = '';
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
  bool _showProblems = false;

  @override
  void dispose() {
    // Through the same list the dirty check walks, so a controller added to
    // one is added to the other: a new field that escapes this list leaks, and
    // a new field that escapes the dirty check loses the user's typing.
    for (final controller in _allControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// One of the three was edited: recompute and write back the computed one.
  ///
  /// The controller for the COMPUTED field is updated here and nowhere else —
  /// §10 forbids recomputing an edited field, so the one the user is typing in
  /// is never touched and their caret never moves.
  void _onTrioChanged(TrioField field, String text) {
    setState(() {
      _fillUp = _fillUp.withTrio(_fillUp.trio.edited(field, text));
      final trio = _fillUp.trio;
      final computed = trio.computedField;
      if (computed == null) return;
      final value = switch (computed) {
        TrioField.quantity => trio.quantity,
        TrioField.pricePerUnit => trio.pricePerUnit,
        TrioField.total => trio.total,
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
  Widget _body() {
    final l10n = AppLocalizations.of(context);
    return switch (_segment) {
      LogType.fillUp => _fillUpBody(l10n),
      LogType.service => LogServiceBody(
        odometer: _odometerField(),
        dateRow: _dateRow(),
        items: _itemChips(),
        moreRow: _moreRow(l10n),
        cost: _cost,
        totalController: _totalController,
        onToggleItem: _toggleItem,
        onAddOther: () {},
        onTotalChanged: (text) => setState(() => _cost = _cost.withTotal(text)),
        onSplitChanged: (on) =>
            setState(() => _cost = on ? _cost.split() : _cost),
      ),
      LogType.expense => _expenseBody(l10n),
      LogType.odometer => LogOdometerBody(
        value: _odometer,
        unit: DistanceUnit.km,
        formatsTag: _formatsTag,
        dateRow: _dateRow(),
        onValueChanged: (v) => setState(() => _odometer = v),
        onSave: _save,
      ),
    };
  }

  /// The fill-up form, with its error slots read from ONE validation.
  ///
  /// §10's messages appear when Save is PRESSED and not while the user is
  /// typing, so every slot is null until `_showProblems`. The over-capacity
  /// line is the exception in the other direction: it is a warning, it is not
  /// gated on Save, and it never blocks one.
  Widget _fillUpBody(AppLocalizations l10n) {
    final problems = _fillUp.problems(today: _occurredOn).toSet();
    final warnings = _fillUp.warnings(tankCapacity: _tankCapacity);

    String? error(FillUpProblem problem, String message) =>
        _showProblems && problems.contains(problem) ? message : null;

    return LogFillUpBody(
      odometer: _odometerField(),
      dateRow: _dateRow(),
      trio: _fillUp.trio,
      moreRow: _moreRow(l10n),
      quantityUnit: _quantityUnit,
      isFullTank: _fillUp.isFullTank,
      controllers: _trioControllers,
      onTrioChanged: _onTrioChanged,
      onFullTankChanged: (full) =>
          setState(() => _fillUp = _fillUp.withFullTank(full: full)),
      // Both land under Quantity: §10 puts the trio sentence there because it
      // is the field the user is most likely to have filled in first.
      trioError:
          error(
            FillUpProblem.quantityNotPositive,
            l10n.logFillUpQuantityError,
          ) ??
          error(FillUpProblem.trioIncomplete, l10n.logFillUpTrioError),
      priceError: error(FillUpProblem.priceNegative, l10n.logFillUpPriceError),
      totalError: error(
        FillUpProblem.totalNegative,
        l10n.logFillUpTotalError(
          formatForDisplay(
            0,
            _formatsTag,
            numerals: CalmNumerals.auto,
            decimalDigits: 0,
          ),
        ),
      ),
      overTankWarning: warnings.contains(FillUpWarning.overTank)
          ? l10n.logFillUpOverTankWarning
          : null,
    );
  }

  /// This vehicle's tank capacity, or null when the app does not know it.
  ///
  /// Null is a real answer and produces no warning at all: SPEC.md §2 forbids
  /// guessing in a way that looks like fact, and "more than your tank holds"
  /// is a claim about a tank the app may never have been told the size of.
  // TODO(EPIC-11): read from the selected vehicle.
  Volume? get _tankCapacity => null;

  /// Opens §10's More section.
  ///
  /// A sheet and not an inline expansion, because the artboard draws the row
  /// as `row--nav` with a chevron. It is rebuilt from the draft each time it
  /// opens, which is also what makes "collapsed again next time" true: there
  /// is no expansion state to remember.
  void _openMore() => unawaited(
    showLogMoreSheet(
      context,
      type: _segment,
      fillUp: _fillUp,
      onFillUpChanged: (next) => setState(() => _fillUp = next),
    ),
  );

  /// §10's *What was done* chips: the vehicle's active items, in §9's order.
  ///
  /// From the due snapshot, so the order here is the one Home and
  /// `reminders.list` already use. A second comparator would be a second
  /// opinion about which item to name first.
  List<ServiceItemChip> _itemChips() {
    final vehicle = _vehicle;
    if (vehicle == null) return const [];
    final snapshot = ref.watch(vehicleDueSnapshotProvider(vehicle.id));
    return serviceItemChips(
      assessments: snapshot?.assessments ?? const [],
      ticked: _cost.tickedItemIds.toSet(),
    );
  }

  /// Ticks or unticks one item.
  ///
  /// Unticking keeps the money and drops only the reset — §10: "Unticking a
  /// chip whose amount was typed keeps the amount", because the work was still
  /// paid for even if it is not what re-anchors a reminder.
  void _toggleItem(String id) {
    final chip = _itemChips().where((c) => c.id == id).firstOrNull;
    if (chip == null) return;
    setState(() {
      _cost = chip.ticked ? _cost.unticked(id) : _cost.ticked(id, chip.label);
    });
  }

  /// The expense form, with its three error slots read from ONE validation.
  ///
  /// `problems()` parses the amount and both window dates, and it was called
  /// once per error slot — three full validations per build, on every
  /// keystroke, once Save had been pressed.
  Widget _expenseBody(AppLocalizations l10n) {
    final problems = _expense.problems().toSet();
    return LogExpenseBody(
      draft: _expense,
      moreRow: _moreRow(l10n),
      categoryLabel: (c) => expenseCategoryLabel(l10n, c),
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
      // §10: the messages appear when Save is PRESSED, not while the user is
      // still typing — "a form that scolds you before you have finished is a
      // form that is angry at you for arriving".
      categoryError: _expenseError(ExpenseProblem.noCategory, l10n, problems),
      labelError: _expenseError(ExpenseProblem.noLabel, l10n, problems),
      amountError: _expenseError(ExpenseProblem.noAmount, l10n, problems),
    );
  }

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
    formatsTag: _formatsTag,
    onChanged: (_) => setState(() {}),
    onUnitChanged: (_) {},
  );

  /// §10's More row: a nav row naming what is inside it.
  ///
  /// A ROW and not an inline disclosure, because that is what the artboard
  /// draws — `row--nav` with the value "Station · Grade · Trip" and a chevron.
  /// §10's prose sketches it as `── More ── ▾`; the two agree on the behaviour
  /// that matters ("collapsed by default and collapsed again next time:
  /// nothing inside it changes a consumption figure") and disagree only about
  /// the affordance, so CLAUDE.md §7 gives it to the reference.
  Widget _moreRow(AppLocalizations l10n) => CalmRowGroup(
    rows: [
      CalmListRow(
        title: l10n.logMoreRow,
        // The summary is the SUBTITLE, not the end value. The artboard draws it
        // end-aligned beside the title, and at 390pt with a chevron there
        // is not room: "Station · Grade · Trip" overflows by 54pt and the
        // German service summary by 114. A subtitle gets the full width, wraps
        // rather than truncating, and keeps the information the artboard is
        // showing — which is the half that matters, since the point of the row
        // is to let the section be skipped without opening it.
        subtitle: switch (_segment) {
          LogType.fillUp => l10n.logMoreFillUpSummary,
          LogType.service => l10n.logMoreServiceSummary,
          LogType.expense => l10n.logMoreExpenseSummary,
          // `log.odometer` has no More section at all — §10: "one more optional
          // field would be a net loss" — and never draws this row.
          LogType.odometer => '',
        },
        showChevron: true,
        size: CalmRowSize.compact,
        onTap: _openMore,
      ),
    ],
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
        value: formatLongDate(_occurredOn, _formatsTag),
        showChevron: true,
        size: CalmRowSize.compact,
        onTap: _pickDate,
      ),
    ],
  );

  /// Opens §10's date picker.
  // TODO(EPIC-11): task 11.4 builds the picker this opens.
  void _pickDate() {}

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
  ///
  /// It asks the FIELDS, and it has to. The first version asked only the
  /// notifier, whose `isDirty` is `note.isNotEmpty` — and nothing in `lib/`
  /// ever calls `setNote`, so the flag was permanently false and the guard,
  /// the dialog and the four-segment discard were all live code hanging off
  /// it. Only a test could make this modal dirty. §10's rule is "any field
  /// differs from its prefill", and no field on these forms is prefilled —
  /// §10 also says the odometer never is — so any content at all is a change.
  bool _isDirty() =>
      ref.read(logModalProvider).isDirty ||
      _odometer.trim().isNotEmpty ||
      _fillUp.isDirty ||
      _cost.isDirty ||
      _expense.isDirty ||
      _allControllers.any((c) => c.text.trim().isNotEmpty);

  /// Every text controller this modal owns, for the dirty check and dispose.
  Iterable<TextEditingController> get _allControllers => [
    ..._trioControllers.values,
    _totalController,
    _amountController,
    _labelController,
    _odometerController,
  ];

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

  /// Validates, writes, and dismisses with an Undo.
  ///
  /// §10: "On tap it validates, scrolls to the first failing field, focuses it,
  /// shows one inline error beneath it" — Save is never disabled, so the tap is
  /// where the form explains itself. A valid draft goes through
  /// `saveLogEntry`, which is the one place the write, the recompute and the
  /// reschedule happen in that order.
  Future<void> _save() async {
    // CAPTURED before the await. `CalmSnackbarHost.of` reads values rather than
    // holding a context precisely so the Undo survives the modal it was
    // offered from — the route is about to pop.
    final snackbars = CalmSnackbarHost.of(context);
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);

    if (_problems().isNotEmpty) {
      // The inline messages are already rendered by the bodies; showing a
      // dialog as well would be the second thing telling the user what one
      // sentence under the field already says.
      setState(() => _showProblems = true);
      return;
    }

    final written = await saveLogEntry(_steps());
    if (!mounted) return;
    if (written is Err<void, PersistFailure>) {
      // §10: the modal STAYS OPEN with everything intact. Losing six digits
      // typed at a pump because a disk was full is the one failure this form
      // must never have.
      snackbars.show(message: l10n.saveDiskFullError, danger: true);
      return;
    }

    if (router.canPop()) router.pop();
    snackbars.show(
      message: _savedMessage(l10n),
      actionLabel: l10n.commonUndo,
      onAction: _undo,
    );
  }

  /// One expense problem's sentence, or null when it does not apply yet.
  String? _expenseError(
    ExpenseProblem problem,
    AppLocalizations l10n,
    Set<ExpenseProblem> problems,
  ) {
    if (!_showProblems || !problems.contains(problem)) return null;
    return switch (problem) {
      ExpenseProblem.noCategory => l10n.logExpenseCategoryError,
      ExpenseProblem.noLabel => l10n.logExpenseNameError,
      ExpenseProblem.noAmount => l10n.logExpenseAmountError,
      ExpenseProblem.amountNotANumber => l10n.logNumberUnclearError(
        formatForDisplay(
          42.61,
          'en',
          numerals: CalmNumerals.auto,
          decimalDigits: 2,
        ),
      ),
      ExpenseProblem.periodBackwards => l10n.logExpenseCoversError,
      // §10 allows a future date on this form, so nothing produces it.
      ExpenseProblem.futureDate => null,
    };
  }

  /// Everything wrong with the visible segment, in the order it reads.
  List<Object> _problems() => switch (_segment) {
    LogType.fillUp => _fillUp.problems(
      today: _occurredOn,
      tankCapacity: _tankCapacity,
    ),
    LogType.expense => _expense.problems(),
    // `log.service` and `log.odometer` arrive with their own tasks. An empty
    // list here is not "valid", it is "not yet asked", and the tests that will
    // assert each rule are the ones that make it real.
    _ => const [],
  };

  /// The vehicle this modal is logging against, or null while it loads.
  Vehicle? get _vehicle {
    final id = ref.read(activeVehicleIdProvider);
    if (id == null) return null;
    return ref
        .read(vehiclesProvider)
        .value
        ?.where((v) => v.id == id)
        .firstOrNull;
  }

  /// The currency this vehicle's money is in.
  ///
  /// The vehicle's own overrides `settings.currency_default`, which is what
  /// `vehicles.currency` is for — a second car bought abroad keeps its
  /// receipts in the currency they were paid in.
  Currency? get _currency =>
      _vehicle?.currency ?? ref.read(settingsProvider).value?.currencyDefault;

  /// The three steps this save takes, in §10's order.
  ///
  /// All four segments supply real ones now. `_PendingSteps` survives for the
  /// two cases where there is genuinely nothing to write — no vehicle loaded
  /// yet, or a keypad with no readable number in it — and it still writes
  /// nothing and says so.
  LogSaveSteps _steps() {
    final vehicle = _vehicle;
    final currency = _currency;
    if (vehicle == null || currency == null) return _PendingSteps();
    void recompute() => ref.invalidate(vehicleDueSnapshotProvider(vehicle.id));

    return switch (_segment) {
      LogType.fillUp => _FillUpSteps(
        save: ref.read(fillUpSaveProvider.notifier),
        recomputeDue: recompute,
        vehicle: vehicle,
        draft: _fillUp,
        currency: currency,
        odometer: _enteredOdometer(),
        onWritten: (fillUp) =>
            _undoWritten = () =>
                ref.read(fillUpSaveProvider.notifier).undo(fillUp),
      ),
      LogType.expense => _ExpenseSteps(
        save: ref.read(expenseSaveProvider.notifier),
        recomputeDue: recompute,
        vehicle: vehicle,
        draft: _expense,
        currency: currency,
        onWritten: (expense) =>
            _undoWritten = () =>
                ref.read(expenseSaveProvider.notifier).undo(expense),
      ),
      LogType.service => _ServiceSteps(
        save: ref.read(serviceSaveProvider.notifier),
        recomputeDue: recompute,
        vehicle: vehicle,
        cost: _cost,
        occurredOn: _occurredOn,
        currency: currency,
        // The localised "Service", carried down rather than looked up: this
        // layer has no BuildContext, and a record labelled in English on a
        // Persian phone is a row the user cannot read back.
        fallbackLabel: AppLocalizations.of(context).logTitleService,
        odometer: _enteredOdometer(),
        onWritten: (record) =>
            _undoWritten = () =>
                ref.read(serviceSaveProvider.notifier).undo(record),
      ),
      LogType.odometer => switch (_keypadOdometer()) {
        final Distance reading => _OdometerSteps(
          save: ref.read(odometerLogSaveProvider.notifier),
          recomputeDue: recompute,
          vehicle: vehicle,
          odometer: reading,
          occurredOn: _occurredOn,
          onWritten: (written) =>
              _undoWritten = () =>
                  ref.read(odometerLogSaveProvider.notifier).undo(written),
        ),
        // Nothing readable in the pad. `problems()` refuses this upstream, so
        // reaching here means the form asked for a save it has no number for.
        _ => _PendingSteps(),
      },
    };
  }

  /// The keypad's value as a distance, or null.
  ///
  /// `log.odometer` types into `_odometer` rather than a controller — the pad
  /// reports digits, not text — so it parses from there. Through
  /// `OdometerEntry` all the same, because the overflow guard is not optional
  /// on the form whose whole job is one number.
  Distance? _keypadOdometer() {
    final metres = OdometerEntry(
      unit: DistanceUnit.km,
      groupingSeparator: _groupingSeparator,
      text: _odometer,
    ).metres;
    return metres == null ? null : Distance(metres);
  }

  /// The reading the shared odometer field is showing, or null.
  ///
  /// Through `OdometerEntry`, which is the app's one answer to what an odometer
  /// field says — including the overflow guard. A second parse here would be a
  /// second answer.
  Distance? _enteredOdometer() {
    final metres = OdometerEntry(
      unit: DistanceUnit.km,
      groupingSeparator: _groupingSeparator,
      text: _odometerController.text,
    ).metres;
    return metres == null ? null : Distance(metres);
  }

  /// How to take back what the last successful save wrote.
  ///
  /// A callback rather than the row, because the four segments write four
  /// different record types and the snackbar only needs to know how to undo —
  /// not what was written. It is set by the steps that did the writing, so a
  /// segment that writes nothing cannot leave a stale Undo behind it.
  Future<Result<void, PersistFailure>> Function()? _undoWritten;

  String _savedMessage(AppLocalizations l10n) => switch (_segment) {
    LogType.fillUp => l10n.logSaveFillUp,
    LogType.service => l10n.logSaveService,
    LogType.expense => l10n.logSaveExpense,
    LogType.odometer => l10n.odometerSavedSnack,
  };

  /// Takes back the row the snackbar is about.
  ///
  /// Null-guarded rather than assumed: the snackbar outlives the modal that
  /// offered it, and an Undo that fired against nothing would be worse than
  /// one that quietly does nothing.
  void _undo() {
    final undo = _undoWritten;
    if (undo == null) return;
    unawaited(undo());
  }
}

/// The steps a save takes before its body supplies a record.
///
/// It writes nothing and says so. §10's order is enforced by `saveLogEntry` and
/// asserted against a fake; this is the seam the four bodies will each fill
/// with their own record, and a version that pretended to write would make the
/// wiring look finished.
class _FillUpSteps implements LogSaveSteps {
  _FillUpSteps({
    required this.save,
    required this.recomputeDue,
    required this.vehicle,
    required this.draft,
    required this.currency,
    required this.odometer,
    required this.onWritten,
  });

  final FillUpSave save;
  final VoidCallback recomputeDue;
  final Vehicle vehicle;
  final FillUpDraft draft;
  final Currency currency;
  final Distance? odometer;
  final ValueChanged<FillUp> onWritten;

  @override
  Future<Result<void, PersistFailure>> persist() async {
    final written = await save.save(
      vehicle: vehicle,
      draft: draft,
      currency: currency,
      odometer: odometer,
    );
    return switch (written) {
      FillUpSaved(:final fillUp) => () {
        onWritten(fillUp);
        return const Ok<void, PersistFailure>(null);
      }(),
      FillUpSaveFailed(:final failure) => Err(failure),
    };
  }

  /// §9's recompute. The due engine is a pure function of what is on disk, so
  /// "recompute" is invalidating the snapshot rather than writing anything —
  /// SPEC.md §2: derived values are never persisted.
  @override
  Future<void> recompute() async => recomputeDue();

  @override
  Future<void> reschedule() async {}
}

class _ExpenseSteps implements LogSaveSteps {
  _ExpenseSteps({
    required this.save,
    required this.recomputeDue,
    required this.vehicle,
    required this.draft,
    required this.currency,
    required this.onWritten,
  });

  final ExpenseSave save;
  final VoidCallback recomputeDue;
  final Vehicle vehicle;
  final ExpenseDraft draft;
  final Currency currency;
  final ValueChanged<Expense> onWritten;

  @override
  Future<Result<void, PersistFailure>> persist() async {
    final written = await save.save(
      vehicle: vehicle,
      draft: draft,
      currency: currency,
    );
    return switch (written) {
      ExpenseSaved(:final expense) => () {
        onWritten(expense);
        return const Ok<void, PersistFailure>(null);
      }(),
      ExpenseSaveFailed(:final failure) => Err(failure),
    };
  }

  @override
  Future<void> recompute() async => recomputeDue();

  @override
  Future<void> reschedule() async {}
}

class _ServiceSteps implements LogSaveSteps {
  _ServiceSteps({
    required this.save,
    required this.recomputeDue,
    required this.vehicle,
    required this.cost,
    required this.occurredOn,
    required this.currency,
    required this.fallbackLabel,
    required this.odometer,
    required this.onWritten,
  });

  final ServiceSave save;
  final VoidCallback recomputeDue;
  final Vehicle vehicle;
  final ServiceCostModel cost;
  final String occurredOn;
  final Currency currency;
  final String fallbackLabel;
  final Distance? odometer;
  final ValueChanged<ServiceRecord> onWritten;

  @override
  Future<Result<void, PersistFailure>> persist() async {
    final written = await save.save(
      vehicle: vehicle,
      cost: cost,
      occurredOn: occurredOn,
      currency: currency,
      fallbackLabel: fallbackLabel,
      odometer: odometer,
    );
    return switch (written) {
      ServiceSaved(:final record) => () {
        onWritten(record);
        return const Ok<void, PersistFailure>(null);
      }(),
      ServiceSaveFailed(:final failure) => Err(failure),
    };
  }

  @override
  Future<void> recompute() async => recomputeDue();

  @override
  Future<void> reschedule() async {}
}

class _OdometerSteps implements LogSaveSteps {
  _OdometerSteps({
    required this.save,
    required this.recomputeDue,
    required this.vehicle,
    required this.odometer,
    required this.occurredOn,
    required this.onWritten,
  });

  final OdometerLogSave save;
  final VoidCallback recomputeDue;
  final Vehicle vehicle;
  final Distance odometer;
  final String occurredOn;
  final ValueChanged<OdometerReading> onWritten;

  @override
  Future<Result<void, PersistFailure>> persist() async {
    final written = await save.save(
      vehicle: vehicle,
      odometer: odometer,
      occurredOn: occurredOn,
    );
    return switch (written) {
      OdometerLogSaved(:final reading) => () {
        onWritten(reading);
        return const Ok<void, PersistFailure>(null);
      }(),
      OdometerLogSaveFailed(:final failure) => Err(failure),
    };
  }

  @override
  Future<void> recompute() async => recomputeDue();

  @override
  Future<void> reschedule() async {}
}

/// The steps a save takes before its body supplies a record.
class _PendingSteps implements LogSaveSteps {
  @override
  Future<Result<void, PersistFailure>> persist() async => const Ok(null);

  @override
  Future<void> recompute() async {}

  @override
  Future<void> reschedule() async {}
}
