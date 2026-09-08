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
import 'package:odova/app/id_provider.dart';
import 'package:odova/app/routing/dirty_modal_guard.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/app/today.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/odometer/odometer_entry.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/time/date_field.dart';
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
import 'package:odova/features/logging/domain/mark_done.dart';
import 'package:odova/features/logging/domain/price_trio.dart';
import 'package:odova/features/logging/domain/service_cost_model.dart';
import 'package:odova/features/logging/domain/service_item_chips.dart';
import 'package:odova/features/logging/ui/entry_context_band.dart';
import 'package:odova/features/logging/ui/log_expense_body.dart';
import 'package:odova/features/logging/ui/log_fillup_body.dart';
import 'package:odova/features/logging/ui/log_more_sheet.dart';
import 'package:odova/features/logging/ui/log_odometer_body.dart';
import 'package:odova/features/logging/ui/log_service_body.dart';
import 'package:odova/features/logging/ui/odometer_field.dart';
import 'package:odova/features/logging/ui/service_confirmation_panel.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/expense_labels.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/money_format.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/persist_failure_message.dart';
import 'package:odova/l10n/service_kind_label.dart';
import 'package:odova/l10n/unit_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
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
  const LogModalShell({
    required this.type,
    super.key,
    this.entryId,
    this.prefillItemId,
    this.prefillOccurredOn,
    this.prefillOdometerMetres,
  });

  /// The segment the URL named. In create mode the user may change it; in edit
  /// mode it is fixed, because an entry cannot change type.
  final LogType type;

  /// The record being edited, or null in create mode.
  final String? entryId;

  /// The item this modal was opened to mark done, from `?item`.
  ///
  /// §10's mark-done: the originating item arrives ticked, which is what makes
  /// the save re-anchor a reminder rather than record an unrelated service.
  final String? prefillItemId;

  /// The date the caller asked for, from `?on`.
  final String? prefillOccurredOn;

  /// The reading the caller already knows, from `?odometer_m`.
  ///
  /// §10 prefills it "and selected so typing replaces it", because a user
  /// marking an oil change done is usually not standing at the car. It arrives
  /// WITHOUT a `~`: the estimate mark belongs to an offer, and a number already
  /// in the field is not one.
  final int? prefillOdometerMetres;

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

  /// The unit THIS entry is being typed in, when it differs from the vehicle's.
  ///
  /// §10 gives the odometer's unit chip an entry-scoped effect: a driver who
  /// reads a rental's dash in miles switches it for that one reading and does
  /// not change what the car is measured in. It is the provenance the row
  /// stores, never arithmetic — the conversion has already happened in
  /// `OdometerEntry`.
  DistanceUnit? _entryUnit;

  /// The unit the odometer field shows, from the vehicle.
  ///
  /// Read in `build` and in `initState` alike, so it cannot be a `ref.watch`.
  /// A vehicle that has not loaded yet answers km, which is also what the
  /// field defaults to.
  DistanceUnit get _vehicleUnit =>
      _entryUnit ?? _vehicle?.distanceUnit ?? DistanceUnit.km;

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

  /// The character this locale separates a fraction with.
  late final String _decimalSeparator = decimalSeparatorFor(_formatsTag);

  late FillUpDraft _fillUp = FillUpDraft(
    trio: PriceTrio(
      groupingSeparator: _groupingSeparator,
      decimalSeparator: _decimalSeparator,
    ),
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

  /// The date every form on this modal is dated, or null until Today is read.
  ///
  /// One value for all four segments: a user who typed a date, switched
  /// segments and switched back would not expect to have to type it again.
  String? _chosenDate;

  /// The date the forms use — what was picked, or what the field defaults to.
  ///
  /// Through `dateFieldDefault`, which is §10 *Dates and a suspect clock*: "in
  /// clock-suspect mode every date field defaults to the newest `occurred_on`
  /// in the database rather than today", because a phone whose clock reads
  /// 2050 would otherwise stamp every entry with it and the whole history
  /// would be wrong in a way no single row looks wrong in.
  String get _occurredOn =>
      _chosenDate ??
      dateFieldDefault(
        today: ref.watch(todayProvider) ?? CivilDate.epoch,
        newestOccurredOn: _newestOccurredOn,
        clockIsSuspect: _clockIsSuspect,
      ).toString();

  /// The fill-up draft with the modal's chosen date on it.
  ///
  /// `FillUpDraft.occurredOn` defaults to `''` and NOTHING ever set it, so the
  /// most-used form in the app could not save at all: `FillUpSave` parsed that
  /// empty string, got null, and returned the §3 clock-suspicion refusal —
  /// which the UI renders as "Couldn't save. Your phone may be out of space."
  /// on a device with 60 GB free. The Date row showed a date the whole time,
  /// because the row reads `_occurredOn` and the draft is a different object.
  ///
  /// `problems()` read it too, so §10's "Pick today or a day in the past"
  /// could never fire either — an empty string parses to null and the
  /// comparison is skipped.
  ///
  /// One getter rather than two call sites passing the date, because two call
  /// sites is how this happened: `_ExpenseSteps` and `_ServiceSteps` are
  /// handed `occurredOn: _occurredOn` explicitly and `_FillUpSteps` was not.
  FillUpDraft get _datedFillUp => _fillUp.withDate(_occurredOn);

  /// Today, as the forms' validation means it.
  String? get _today => ref.watch(todayProvider)?.toString();

  /// The newest `occurred_on` this vehicle has, for the suspect-clock fallback.
  ///
  /// From the ODOMETER readings, which is the closest thing the app has to
  /// "the newest date in the database": §3 makes every record carrying an
  /// odometer emit one, so this table sees fill-ups, services, expenses and
  /// trips as well as manual entries. An expense with no odometer is the one
  /// kind it misses, and a fallback that is one row stale is still enormously
  /// better than a clock reading 2050.
  String? get _newestOccurredOn {
    final vehicle = _vehicle;
    if (vehicle == null) return null;
    final readings = ref.watch(odometerReadingsProvider(vehicle.id)).value;
    if (readings == null || readings.isEmpty) return null;
    return readings
        .map((r) => r.occurredOn)
        .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
  }

  /// Whether the device clock is not to be trusted with a date.
  bool get _clockIsSuspect {
    final vehicle = _vehicle;
    if (vehicle == null) return false;
    return ref.watch(vehicleDueSnapshotProvider(vehicle.id))?.clock.isSuspect ??
        false;
  }

  bool _showProblems = false;

  @override
  void initState() {
    super.initState();
    // The prefill is the CALLER's, applied once. §10 is emphatic that none of
    // this is a default: the central `+` opens an empty form, and a field that
    // arrived filled in from somewhere the user did not ask about gets saved
    // unread.
    _chosenDate = widget.prefillOccurredOn;
    final metres = widget.prefillOdometerMetres;
    if (metres != null) {
      // In the FIELD's unit, ungrouped and unmarked — the same shape the
      // estimate chip writes when it is tapped. Grouping separators would have
      // to be parsed back out on the first keystroke.
      _odometerController.text =
          '${Distance(metres).inUnit(_vehicleUnit).round()}';
    }
    final item = widget.prefillItemId;
    if (item != null) _pendingTickItemId = item;
  }

  /// The item `?item` named, until the chip list has loaded and it can tick.
  ///
  /// Held rather than applied in `initState`, because the chips come from the
  /// due snapshot and that is a stream: at `initState` there is nothing to tick
  /// yet, and ticking an id the vehicle does not have would put a phantom
  /// reminder on a real service record.
  String? _pendingTickItemId;

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
          //
          // The one exception is AFTER the write, while the confirmation panel
          // is up: there is nothing left to save and the row already exists,
          // so a second tap would write it twice. The panel shipped replacing
          // only the BODY — a "Service done" card under a live Save, over a
          // segmented control offering to switch to Expense, above a
          // "Save service" button. A person asked what the screen was.
          onEnd: _showingConfirmation ? null : _save,
        ),
        // No footer on `log.odometer`: §10 puts Save "in the app bar, and as a
        // full-width primary button pinned above the keyboard", and on that
        // screen the keypad IS the keyboard — its confirm key is that button,
        // which is how the artboard draws it. A footer as well would be three
        // Saves, two of them adjacent.
        // Gone while the confirmation is up, for the reason on `onEnd` above:
        // the entry is written and the panel's Close is the only thing left to
        // do.
        footer: _segment == LogType.odometer || _showingConfirmation
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
          // And not while the confirmation is up: a segmented control that
          // offers to switch to Expense, over a card saying the service was
          // saved, is a screen asking the user to do something that would
          // throw away what they just read.
          if (!_isEdit && !_showingConfirmation)
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
          // §11's context band, above the fields and only in edit mode: "the
          // derived numbers this record participates in, and what it is
          // attached to." In create mode there is no record yet to be the
          // context of.
          if (_isEdit) EntryContextBand(lines: _bandLines(l10n)),
          _body(),
          // §11: Delete "sits at the bottom of the form, destructive-styled,
          // never in the app bar where Save is." Never beside Save, because
          // the two are one slip apart and only one of them is reversible by
          // pressing it again.
          if (_isEdit) ...[
            SizedBox(height: CalmSpace.of(context).s4),
            CalmButton(
              label: _deleteLabel(l10n),
              variant: CalmButtonVariant.danger,
              block: true,
              onPressed: _confirmDelete,
            ),
          ],
        ],
      ),
    );
  }

  /// The band's lines for this segment, already formatted.
  ///
  /// Empty until each form supplies the record it is editing — the DECISIONS
  /// are `entry_band.dart`'s and are tested there; what is missing is the
  /// prefill that gives this modal a record to describe, which arrives with
  /// edit-mode loading.
  // TODO(EPIC-12): task 12.7's edit-mode load supplies the record.
  List<String> _bandLines(AppLocalizations l10n) => const [];

  /// The destructive row's own words, naming what dies.
  ///
  /// Per SEGMENT, because "Delete this fill-up" and "Delete this expense" are
  /// different promises and a generic "Delete" makes the user check which form
  /// they are on before pressing it.
  String _deleteLabel(AppLocalizations l10n) => switch (_segment) {
    LogType.fillUp => l10n.logDeleteFillUp,
    LogType.service => l10n.logDeleteService,
    LogType.expense => l10n.logDeleteExpense,
    LogType.odometer => l10n.logDeleteOdometer,
  };

  /// Opens §7's shared confirm dialog.
  ///
  /// EPIC-08 built it once, globally, and §7 makes it belong to no feature —
  /// so this calls it and builds none. The cascade it names is task 12.9's.
  // TODO(EPIC-12): task 12.9 wires dialog.confirmDelete and its guards.
  void _confirmDelete() {}

  /// The form for whichever segment is showing.
  ///
  /// The shell knows nothing about what any of them contains — it hands each
  /// one its draft and its callbacks and gets a widget back. That is the seam
  /// §10 is built around: "a segment body knows nothing about" the chrome, and
  /// the chrome returns the compliment.
  Widget _body() {
    final l10n = AppLocalizations.of(context);
    // §10: a mark-done save "replaces the body with the confirmation panel for
    // five seconds or until Close". A panel and not a snackbar because BOTH
    // halves of the next-due pair have to be visible at once — "the
    // consequence of finishing 3,000 km early is what a user needs to see
    // once", and a snackbar can carry one fact.
    if (_confirmation case final panel?) return panel;
    return switch (_segment) {
      LogType.fillUp => _fillUpBody(l10n),
      LogType.service => LogServiceBody(
        // The currency symbol as an AFFIX. Every money field shipped as a
        // bare number — somebody typed 2500 into Cost with nothing saying
        // whether that was euros, dollars or rials, in an app whose point is
        // that it holds several and never sums across them. §10's artboard
        // draws it on Price/L and Total; only litres had one.
        moneySymbol: currencySymbolFor(
          _currency ?? Currency.tryParse('EUR')!,
          _formatsTag,
        ),
        odometer: _odometerField(),
        navRows: _dateAndMoreRows(l10n),
        items: _itemChips(),
        cost: _cost,
        totalController: _totalController,
        onToggleItem: _toggleItem,
        onAddOther: () {},
        onTotalChanged: (text) => setState(() => _cost = _cost.withTotal(text)),
        onSplitChanged: (on) =>
            setState(() => _cost = _cost.withSplit(split: on)),
      ),
      LogType.expense => _expenseBody(l10n),
      LogType.odometer => LogOdometerBody(
        value: _odometer,
        unit: _vehicleUnit,
        formatsTag: _formatsTag,
        occurredOn: _occurredOn,
        onPickDate: _pickDate,
        // The anchor this screen is measured against. It was never passed, so
        // the pad's panel showed a number with nothing to compare it to — on
        // the one screen whose whole job is that comparison.
        lastReading: _lastReading?.odometer,
        lastReadingOn: _lastReading?.occurredOn,
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
    final problems = _datedFillUp
        .problems(today: _today, tankCapacity: _tankCapacity)
        .toSet();
    final warnings = _fillUp.warnings(tankCapacity: _tankCapacity);

    String? error(FillUpProblem problem, String message) =>
        _showProblems && problems.contains(problem) ? message : null;

    return LogFillUpBody(
      // The currency symbol as an AFFIX. Every money field shipped as a
      // bare number — somebody typed 2500 into Cost with nothing saying
      // whether that was euros, dollars or rials, in an app whose point
      // is that it holds several and never sums across them. §10's
      // artboard draws it on Price/L and Total; only litres had one.
      moneySymbol: currencySymbolFor(
        _currency ?? Currency.tryParse('EUR')!,
        _formatsTag,
      ),
      odometer: _odometerField(),
      navRows: _dateAndMoreRows(l10n),
      trio: _fillUp.trio,
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

  /// The confirmation panel, while a mark-done save is being shown.
  ///
  /// Null on every other save. A save from the `+` skips it entirely — nothing
  /// was reset, so there is no consequence to show — which is why this is a
  /// field set by the save rather than a branch on the segment.
  ServiceConfirmationPanel? _confirmation;

  /// Whether the write is done and the panel is showing its result.
  ///
  /// The chrome reads this and stands down — §10 says the panel "replaces the
  /// body", and the modal shipped taking that literally: the Save in the app
  /// bar, the segmented control and the `Save service` button all stayed live
  /// over a card announcing the save had already happened.
  bool get _showingConfirmation => _confirmation != null;

  /// Closes the panel and leaves.
  void _closeConfirmation() {
    if (!mounted) return;
    setState(() => _confirmation = null);
    final router = GoRouter.of(context);
    if (router.canPop()) router.pop();
  }

  /// §10's *What was done* chips: the vehicle's active items, in §9's order.
  ///
  /// From the due snapshot, so the order here is the one Home and
  /// `reminders.list` already use. A second comparator would be a second
  /// opinion about which item to name first.
  List<ServiceItemChip> _itemChips() {
    final vehicle = _vehicle;
    if (vehicle == null) return const [];
    final snapshot = ref.watch(vehicleDueSnapshotProvider(vehicle.id));
    final chips = serviceItemChips(
      assessments: snapshot?.assessments ?? const [],
      ticked: _cost.tickedItemIds.toSet(),
    );

    // The `?item` tick is applied AFTER this frame, never during it. Writing
    // `_cost` here mutated State inside `build` with no rebuild scheduled —
    // harmless only because the pending tick fires once, before anything else
    // is ticked, and `_toggleItem` already calls this method. A second caller
    // makes it a silent state change nothing repaints.
    _applyPendingTick(chips);
    return chips;
  }

  /// Ticks the item `?item` named, once the chip it names exists.
  ///
  /// Ticking an id the vehicle does not have would put a phantom reminder on a
  /// real service record, so an unknown id simply never fires — which is also
  /// what makes a stale notification from an older build harmless.
  void _applyPendingTick(List<ServiceItemChip> chips) {
    final pending = _pendingTickItemId;
    if (pending == null) return;
    final match = chips.where((c) => c.id == pending).firstOrNull;
    if (match == null) return;

    _pendingTickItemId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(
        () => _cost = _cost.ticked(match.id, _chipLabel(match)),
      );
    });
  }

  /// What a ticked line is called in the cost split.
  ///
  /// A seed has no label of its own, so the name comes from its kind — the
  /// same resolution the chip itself draws, so the split and the chip cannot
  /// disagree about what the user ticked.
  String _chipLabel(ServiceItemChip chip) => serviceItemLabel(
    AppLocalizations.of(context),
    kind: chip.kind,
    label: chip.label,
  );

  /// Ticks or unticks one item.
  ///
  /// Unticking keeps the money and drops only the reset — §10: "Unticking a
  /// chip whose amount was typed keeps the amount", because the work was still
  /// paid for even if it is not what re-anchors a reminder.
  void _toggleItem(String id) {
    final chip = _itemChips().where((c) => c.id == id).firstOrNull;
    if (chip == null) return;
    setState(() {
      _cost = chip.ticked
          ? _cost.unticked(id)
          : _cost.ticked(id, _chipLabel(chip));
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
      // The currency symbol as an AFFIX. Every money field shipped as a
      // bare number — somebody typed 2500 into Cost with nothing saying
      // whether that was euros, dollars or rials, in an app whose point
      // is that it holds several and never sums across them. §10's
      // artboard draws it on Price/L and Total; only litres had one.
      moneySymbol: currencySymbolFor(
        _currency ?? Currency.tryParse('EUR')!,
        _formatsTag,
      ),
      draft: _expense,
      navRows: _dateAndMoreRows(l10n),
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
          setState(() => _expense = _expense.withRefund(refund: on)),
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
  Widget _odometerField() {
    final vehicle = _vehicle;
    final snapshot = vehicle == null
        ? null
        : ref.watch(vehicleDueSnapshotProvider(vehicle.id));
    final estimate = snapshot?.estimate;

    return OdometerField(
      controller: _odometerController,
      unit: _vehicleUnit,
      // The vehicle's REAL history. These were `const []`, which made the whole
      // rule engine inert: no helper line, no delta, no monotonicity check and
      // no estimate chip, on the one field §10 says "feeds the due engine, so
      // it behaves identically on log.fillup, log.service and log.odometer".
      existing: _readings,
      corrections: _corrections,
      occurredOn: _occurredOn,
      formatsTag: _formatsTag,
      estimate: estimate == null ? null : Distance(estimate.metres),
      estimateStaleDays: estimate?.staleDays ?? 0,
      onChanged: (_) => setState(() {}),
      // §10: "switches the unit for THIS entry only." It was an empty callback
      // under a chip that renders as tappable and announces itself to a screen
      // reader — a control that says it does something and does not.
      onUnitChanged: (unit) => setState(() => _entryUnit = unit),
    );
  }

  /// This vehicle's readings, as the points the odometer maths works in.
  List<ReadingPoint> get _readings {
    final vehicle = _vehicle;
    if (vehicle == null) return const [];
    final readings = ref.watch(odometerReadingsProvider(vehicle.id)).value;
    return readings?.map(asReadingPoint).toList() ?? const [];
  }

  /// The newest reading at or before this entry's date, if there is one.
  ReadingPoint? get _lastReading {
    final earlier = _readings
        .where((r) => r.occurredOn.compareTo(_occurredOn) <= 0)
        .toList();
    if (earlier.isEmpty) return null;
    earlier.sort(compareReadings);
    return earlier.last;
  }

  /// This vehicle's cluster swaps, likewise.
  List<CorrectionPoint> get _corrections {
    final vehicle = _vehicle;
    if (vehicle == null) return const [];
    final corrections = ref
        .watch(odometerCorrectionsProvider(vehicle.id))
        .value;
    return corrections?.map(asCorrectionPoint).toList() ?? const [];
  }

  /// The date row every form carries.
  ///
  /// A read-only row that opens the picker, per §10's Field kit: "Date — none;
  /// a read-only row opening the calendar picker." The picker itself is the
  /// shared control EPIC-09 deferred to this epic and is not built yet, so the
  /// row renders the date and does not yet open anything.
  /// §10's Date row and More row, as ONE group.
  ///
  /// The artboard draws them as a single card with a divider between them, not
  /// as two cards with a gap. That is what the band profile measures and it is
  /// also the right grouping: both are navigation rows that leave the form,
  /// and `log.odometer` — which has no More section — gets the Date row alone
  /// from the same function.
  Widget _dateAndMoreRows(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _dateAndMoreGroup(l10n),
      // §1: "Save is never disabled without an explanation." A future date
      // blocks the save and had NO message anywhere: `FillUpProblem.futureDate`
      // was computed, checked, and never rendered, so Save simply did nothing.
      // The date lives in a nav row rather than a field, so the error hangs
      // under the group instead of inside a box.
      if (_showProblems && _problems().contains(FillUpProblem.futureDate))
        Padding(
          padding: EdgeInsets.only(
            top: CalmSpace.of(context).s2,
            left: CalmSpace.of(context).s4,
          ),
          child: Text(
            l10n.logDateFutureError,
            style: CalmType.of(context).caption.copyWith(
              color: CalmColors.of(context).danger,
            ),
          ),
        ),
    ],
  );

  Widget _dateAndMoreGroup(AppLocalizations l10n) => CalmRowGroup(
    rows: [
      CalmListRow(
        // `logDateLabel`, not `reminderOnceOnDate`. That key is
        // `reminders.edit`'s "Or once, on date" and reads as a choice between
        // schedules; this row is the day the thing being logged happened.
        title: l10n.logDateLabel,
        value: formatLongDate(_occurredOn, _formatsTag),
        showChevron: true,
        size: CalmRowSize.compact,
        onTap: _pickDate,
      ),
      if (logTypeHasMore(_segment))
        CalmListRow(
          title: l10n.logMoreRow,
          // The summary is the SUBTITLE, not the end value. The artboard draws
          // it end-aligned beside the title, and at 390pt with a chevron there
          // is not room: "Station · Grade · Trip" overflows by 54pt and the
          // German service summary by 114. A subtitle gets the full width,
          // wraps rather than truncating, and keeps the information the
          // artboard is showing — which is the half that matters, since the
          // point of the row is to let the section be skipped without opening
          // it.
          subtitle: switch (_segment) {
            LogType.fillUp => l10n.logMoreFillUpSummary,
            LogType.service => l10n.logMoreServiceSummary,
            LogType.expense => l10n.logMoreExpenseSummary,
            LogType.odometer => '',
          },
          showChevron: true,
          size: CalmRowSize.compact,
          onTap: _openMore,
        ),
    ],
  );

  /// Opens §10's date picker.
  ///
  /// The RANGE is `dateFieldRange`'s, which is the part the four forms have to
  /// agree about: thirty years back because a second-hand car's service book
  /// goes back that far, and no future at all except on `log.expense`, where
  /// prepaid insurance is real. The picker STOPS at the boundary rather than
  /// offering tomorrow and refusing it at Save — "a rule the user meets as a
  /// disabled day is a rule they never have to discover".
  ///
  /// `showDatePicker` renders it. §10's Field kit asks for "correct first day
  /// of week per locale", which `MaterialLocalizations` supplies and
  /// `supported_locales.dart` has already wired for all six including the ckb
  /// fallback. A hand-built Calm calendar would be a month grid, six locales
  /// of weekday order and a Jalali question §18 has not answered; that is a
  /// deliberate deferral, recorded in the progress file rather than taken
  /// quietly.
  Future<void> _pickDate() async {
    final today = ref.read(todayProvider) ?? CivilDate.epoch;
    final range = dateFieldRange(
      today: today,
      // §10 allows a future date on `log.expense` alone.
      allowFuture: _segment == LogType.expense,
    );
    final current = CivilDate.tryParse(_occurredOn) ?? today;

    final picked = await showDatePicker(
      context: context,
      initialDate: asPickerDate(current),
      firstDate: asPickerDate(range.first),
      lastDate: asPickerDate(range.last),
    );
    if (picked == null || !mounted) return;
    final chosen = CivilDate.fromDateTime(picked);
    if (chosen == null) return;
    setState(() => _chosenDate = chosen.toString());
  }

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
    //
    // `overTabBar: true` because of where it POPS TO. §7 pushes the four
    // `log.*` routes on the root navigator so the form covers the tab bar, and
    // `CalmChromeScope` says so correctly from in here — but on save the modal
    // is gone and the snackbar is drawn over the shell, which has one. Without
    // this the inset was 62pt short and "Odometer saved · Undo" came up behind
    // the bar with its Undo under the `+`: a write whose recovery window the
    // user cannot reach.
    final snackbars = CalmSnackbarHost.of(context, overTabBar: true);
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
    if (written case Err<void, PersistFailure>(:final failure)) {
      // §10: the modal STAYS OPEN with everything intact. Losing six digits
      // typed at a pump because a disk was full is the one failure this form
      // must never have.
      //
      // And it says which failure it was. Every one of these used to report
      // `saveDiskFullError`, so a user whose reading was refused as below the
      // previous one was told their phone was out of space — a message that
      // sends them to Settings to delete photos over a number they could have
      // corrected in two taps.
      snackbars.show(
        message: persistFailureMessage(l10n, failure),
        danger: true,
      );
      return;
    }

    // §10: a MARK-DONE stays and shows the panel; every other save pops and
    // gets the snackbar. The difference is whether a reminder was reset, not
    // which segment was showing — a service logged from the `+` with no chip
    // ticked reset nothing and has no consequence to explain.
    final panel = _confirmationFor(l10n);
    if (panel != null) {
      setState(() => _confirmation = panel);
      return;
    }

    if (router.canPop()) router.pop();
    snackbars.show(
      message: _savedMessage(l10n),
      actionLabel: l10n.commonUndo,
      onAction: _undo,
    );
  }

  /// The panel this save earns, or null when it earns none.
  ///
  /// Null unless a service save actually ticked an item. §10: "A save from the
  /// `+` skips it entirely — nothing was reset, so there is no consequence to
  /// show."
  ServiceConfirmationPanel? _confirmationFor(AppLocalizations l10n) {
    if (_segment != LogType.service) return null;
    final ticked = _cost.tickedItemIds;
    if (ticked.isEmpty) return null;

    final vehicle = _vehicle;
    final assessments = vehicle == null
        ? const <AssessedItem>[]
        : ref.read(vehicleDueSnapshotProvider(vehicle.id))?.assessments ??
              const <AssessedItem>[];
    final assessed = assessments
        .where((a) => a.$1.id.toString() == ticked.first)
        .firstOrNull;
    if (assessed == null) return null;

    final unit = _vehicleUnit;
    final next = nextDueAfterMarkDone(
      item: assessed.$1,
      record: _markDoneRecord(assessed.$1),
      previousDueOn: assessed.$2.dueOn?.toString(),
    );

    return ServiceConfirmationPanel(
      itemLabel: assessed.$1.label ?? l10n.logTitleService,
      facts: formatLongDate(_occurredOn, _formatsTag),
      nextOdometer: next.odometer == null
          ? null
          : formatWithUnit(
              next.odometer!.inUnit(unit),
              distanceUnitLabel(l10n, unit),
              _formatsTag,
              numerals: CalmNumerals.auto,
              decimalDigits: 0,
            ),
      nextDate: next.date == null
          ? null
          : formatLongDate(next.date.toString(), _formatsTag),
      onClose: _closeConfirmation,
    );
  }

  /// The record the re-anchor measures from.
  ///
  /// The odometer is the one the user ENTERED, which is the entire point:
  /// `mark_done.dart` exists because anchoring on the value the item was due at
  /// "would quietly steal 1,412 km of interval from anyone who serviced their
  /// car late, every cycle, for ever".
  ServiceRecord _markDoneRecord(ServiceItem item) => ServiceRecord(
    id: ServiceRecordId.mint(ref.read(ulidFactoryProvider)),
    vehicleId: item.vehicleId,
    occurredOn: _occurredOn,
    odometer: _enteredOdometer(),
    odometerUnit: _vehicleUnit,
    lines: const [],
    createdAtUtcMs: 0,
    updatedAtUtcMs: 0,
  );

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
    LogType.fillUp => _datedFillUp.problems(
      // TODAY, not the entry's own date. Passing the entry date made
      // `on > now` unreachable, so §10's "Pick today or a day in the past"
      // could never fire — including for a date arriving from an unvalidated
      // `?on` query parameter.
      today: _today,
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
    // WATCHED, not read. Both of these are streams, and on the frame the modal
    // is first built neither has delivered — a `read` returns null and nothing
    // ever asks again, so the form spends its whole life with no vehicle: no
    // reading history, no estimate chip, no currency, and `_steps()` handing
    // back the placeholder that writes nothing. The parity capture showed it
    // first, as an odometer field with no helper line.
    final id = ref.watch(activeVehicleIdProvider);
    if (id == null) return null;
    return ref
        .watch(vehiclesProvider)
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
      _vehicle?.currency ?? ref.watch(settingsProvider).value?.currencyDefault;

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
        draft: _datedFillUp,
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
        occurredOn: _occurredOn,
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
      unit: _vehicleUnit,
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
      // The VEHICLE's unit, which is the one the field renders in. Hardcoding
      // km here parsed `100000` on a miles vehicle as 100,000,000 m instead of
      // 160,934,400 — a 38% error written into the series the due engine reads,
      // while the helper line beside it said "mi".
      unit: _vehicleUnit,
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

  /// What the snackbar says after a successful save.
  ///
  /// The PAST tense. The first version reused the pinned button's own labels,
  /// so a user who had just saved a fill-up was shown the imperative "Save
  /// fill-up" beside an Undo — a sentence that reads as an instruction to do
  /// the thing they have already done.
  String _savedMessage(AppLocalizations l10n) => switch (_segment) {
    LogType.fillUp => l10n.logSavedFillUp,
    LogType.service => l10n.logSavedService,
    LogType.expense => l10n.logSavedExpense,
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
    required this.occurredOn,
    required this.currency,
    required this.onWritten,
  });

  final ExpenseSave save;
  final VoidCallback recomputeDue;
  final Vehicle vehicle;
  final ExpenseDraft draft;
  final String occurredOn;
  final Currency currency;
  final ValueChanged<Expense> onWritten;

  @override
  Future<Result<void, PersistFailure>> persist() async {
    final written = await save.save(
      vehicle: vehicle,
      draft: draft,
      occurredOn: occurredOn,
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
  Future<Result<void, PersistFailure>> persist() async =>
      // An Err, not `Ok(null)`. Returning success made `_save` pop the route
      // and show "saved" with a dead Undo over a write that never happened —
      // on `log.odometer` with an empty pad, and on any segment whose vehicle
      // had not loaded. A step that writes nothing must not report that it
      // wrote something.
      const Err(WriteFailed('nothing to write yet'));

  @override
  Future<void> recompute() async {}

  @override
  Future<void> reschedule() async {}
}
