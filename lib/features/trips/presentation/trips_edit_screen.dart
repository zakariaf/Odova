// SPEC.md §10's `trips.edit`, built against
// `design/reference/calm/trips.edit-*.png`.
//
// Near zero for a commuter; several times a day for a delivery or rideshare
// driver — which is the only reason this screen has to be as fast as the
// fill-up form.
//
// The rule underneath all of it, from §10 and §3 together: **a trip is never
// the source of truth for vehicle distance.** An odometer pair emits two
// readings and a bare distance emits none, and `TripDraft` is where that is
// decided so this file cannot get it wrong by drawing a field differently.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/active_vehicle.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/app/today.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/time/date_field.dart';
import 'package:odova/core/trips/trip_draft.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/trips/application/trip_save.dart';
import 'package:odova/features/trips/application/trips_list_model.dart';
import 'package:odova/features/trips/presentation/trip_labels.dart';
import 'package:odova/features/trips/presentation/trip_purpose_control.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_snackbar.dart';

/// §10's trip editor.
class TripsEditScreen extends ConsumerStatefulWidget {
  /// Creates the screen for [tripId], or `kNewRecordId` to create one.
  const TripsEditScreen({required this.tripId, super.key});

  /// The trip being edited, or `kNewRecordId`.
  final String tripId;

  /// Whether this is create mode.
  bool get isNew => tripId == kNewRecordId;

  @override
  ConsumerState<TripsEditScreen> createState() => _TripsEditScreenState();
}

class _TripsEditScreenState extends ConsumerState<TripsEditScreen> {
  final _title = TextEditingController();
  final _startOdometer = TextEditingController();
  final _endOdometer = TextEditingController();
  final _distance = TextEditingController();
  final _notes = TextEditingController();

  TripDraft? _draft;
  Trip? _existing;

  /// Nothing is red until Save has been pressed. §10: the form explains itself
  /// on tap, not while the user is still typing the first digit.
  bool _showProblems = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _startOdometer.dispose();
    _endOdometer.dispose();
    _distance.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;
    final today = ref.watch(todayProvider) ?? CivilDate.epoch;
    final vehicleId = ref.watch(activeVehicleIdProvider);
    final vehicle = ref
        .watch(vehiclesProvider)
        .value
        ?.where((v) => v.id == vehicleId)
        .firstOrNull;
    final unit = effectiveDistanceUnit(
      vehicle,
      ref.watch(settingsProvider).value,
    );

    final model = vehicleId == null
        ? TripsListModel.loading
        : ref.watch(tripsListProvider(vehicleId));
    _ensureDraft(today: today, vehicle: vehicle, model: model, unit: unit);

    final draft = _draft;
    if (draft == null) {
      return CalmScaffold(
        appBar: CalmAppBar(title: l10n.tripNewTitle),
        children: const [],
      );
    }

    final problems = draft.problems(today: today);
    String? errorFor(TripProblem problem, String message) =>
        _showProblems && problems.contains(problem) ? message : null;

    return CalmScaffold(
      appBar: CalmAppBar(
        title: widget.isNew ? l10n.tripNewTitle : l10n.tripEditTitle,
        actions: [
          CalmAppBarAction(
            label: l10n.commonSave,
            primary: true,
            // NEVER null. §10: "Save is never disabled; on tap it validates."
            onTap: _saving ? null : () => unawaited(_save(vehicle)),
          ),
        ],
      ),
      footer: CalmButton(
        label: l10n.tripSaveAction,
        onPressed: _saving ? null : () => unawaited(_save(vehicle)),
      ),
      children: [
        TripPurposeControl(
          purpose: draft.purpose,
          onChanged: (next) => _edit(draft.withPurpose(next)),
        ),
        SizedBox(height: space.s5),
        CalmField(label: l10n.tripTitleLabel, controller: _title),
        SizedBox(height: space.s4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DateTile(
                label: l10n.tripStartsLabel,
                value: formatRowDate(draft.startedOn, tag),
                errorText: errorFor(
                  TripProblem.startInFuture,
                  l10n.tripStartInFuture,
                ),
                onTap: () => unawaited(_pickDate(today: today, isEnd: false)),
              ),
            ),
            SizedBox(width: space.s3),
            Expanded(
              // Hidden while Still going is ticked — §10's field table. The
              // whole tile goes, not just its value: a greyed-out date is a
              // date the user still has to reason about.
              child: draft.stillGoing
                  ? const SizedBox.shrink()
                  : _DateTile(
                      label: l10n.tripEndsLabel,
                      value: formatRowDate(draft.endedOn ?? '', tag),
                      errorText: errorFor(
                        TripProblem.endBeforeStart,
                        l10n.tripEndBeforeStart,
                      ),
                      onTap: () =>
                          unawaited(_pickDate(today: today, isEnd: true)),
                    ),
            ),
          ],
        ),
        SizedBox(height: space.s4),
        CalmRowGroup(
          rows: [
            CalmListRow.switchRow(
              title: l10n.tripStillGoing,
              value: draft.stillGoing,
              onToggle: () {
                final next = draft.withStillGoing(going: !draft.stillGoing);
                // The controller too. The draft cleared the end reading; a
                // controller still holding `187,412` would put it straight
                // back on the next keystroke anywhere else on the form.
                if (next.stillGoing) _endOdometer.clear();
                _edit(next);
              },
            ),
          ],
        ),
        SizedBox(height: space.s4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CalmField(
                label: l10n.tripStartOdometerLabel,
                controller: _startOdometer,
                numeric: true,
                keyboardType: TextInputType.number,
                affix: Text(distanceUnitLabel(l10n, unit)),
                onChanged: (v) => _edit(draft.withStartOdometer(v)),
              ),
            ),
            SizedBox(width: space.s3),
            Expanded(
              child: draft.stillGoing
                  ? const SizedBox.shrink()
                  : CalmField(
                      label: l10n.tripEndOdometerLabel,
                      controller: _endOdometer,
                      numeric: true,
                      keyboardType: TextInputType.number,
                      affix: Text(distanceUnitLabel(l10n, unit)),
                      errorText: errorFor(
                        TripProblem.endBelowStart,
                        l10n.tripEndBelowStart,
                      ),
                      onChanged: (v) => _edit(draft.withEndOdometer(v)),
                    ),
            ),
          ],
        ),
        SizedBox(height: space.s4),
        _DistanceField(
          draft: draft,
          controller: _distance,
          unit: unit,
          formatsTag: tag,
          errorText: errorFor(
            TripProblem.distanceNotPositive,
            l10n.tripDistanceNotPositive,
          ),
          onChanged: (v) => _edit(draft.withManualDistance(v)),
        ),
        SizedBox(height: space.s6),
        _ExpensesSection(
          tripId: widget.isNew ? null : widget.tripId,
          model: model,
          formatsTag: tag,
        ),
        SizedBox(height: space.s5),
        CalmField(
          label: l10n.logNotes,
          controller: _notes,
          onChanged: (v) => _edit(draft.withNotes(v)),
        ),
        if (!widget.isNew) ...[
          SizedBox(height: space.s6),
          CalmRowGroup(
            rows: [
              CalmListRow(
                title: l10n.tripDeleteAction,
                danger: true,
                onTap: () => unawaited(_delete()),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Builds the draft once the data it prefills from has landed.
  ///
  /// Once, and never again: rebuilding it on every frame would throw away what
  /// the user has typed the moment any watched stream re-emits — and on this
  /// screen the expenses list is a LIVE query, so one arriving toll would
  /// clear the form.
  void _ensureDraft({
    required CivilDate today,
    required Vehicle? vehicle,
    required TripsListModel model,
    required DistanceUnit unit,
  }) {
    if (_draft != null || vehicle == null) return;

    if (widget.isNew) {
      final fresh = TripDraft.create(
        today: today,
        // §10: Business if the vehicle answered yes to "do you drive this for
        // work?", else Personal.
        drivenForWork: vehicle.isBusiness,
      );
      _draft = fresh;
      return;
    }

    if (!model.isLoaded) return;
    final row = [
      ...model.open,
      ...model.earlier,
    ].where((r) => r.trip.id.toString() == widget.tripId).firstOrNull;
    if (row == null) return;

    final trip = row.trip;
    final loaded = TripDraft(
      purpose: trip.purpose,
      title: trip.title ?? '',
      startedOn: trip.startedOn,
      endedOn: trip.endedOn,
      stillGoing: trip.endedOn == null,
      startOdometer: _asField(trip.startOdometer, unit),
      endOdometer: _asField(trip.endOdometer, unit),
      manualDistance: _asField(trip.manualDistance, unit),
      notes: trip.notes ?? '',
    );
    _existing = trip;
    _draft = loaded;
    _title.text = loaded.title;
    _startOdometer.text = loaded.startOdometer;
    _endOdometer.text = loaded.endOdometer;
    _distance.text = loaded.manualDistance;
    _notes.text = loaded.notes;
  }

  static String _asField(Distance? distance, DistanceUnit unit) =>
      distance == null ? '' : '${distance.inUnit(unit).round()}';

  void _edit(TripDraft next) => setState(() => _draft = next);

  /// §10's date range: thirty years back, no future at all.
  ///
  /// The picker STOPS at today rather than offering tomorrow and refusing it
  /// at Save — a rule met as a disabled day is a rule nobody has to discover.
  Future<void> _pickDate({
    required CivilDate today,
    required bool isEnd,
  }) async {
    final draft = _draft;
    if (draft == null) return;
    final range = dateFieldRange(today: today, allowFuture: false);
    final current =
        CivilDate.tryParse((isEnd ? draft.endedOn : draft.startedOn) ?? '') ??
        today;

    final picked = await showDatePicker(
      context: context,
      initialDate: _asPickerDate(current),
      firstDate: _asPickerDate(range.first),
      lastDate: _asPickerDate(range.last),
    );
    if (picked == null || !mounted) return;
    final chosen = CivilDate.fromDateTime(picked);
    if (chosen == null) return;
    _edit(
      isEnd
          ? draft.withEndedOn(chosen.toString())
          : draft.withStartedOn(chosen.toString()),
    );
  }

  /// Local midnight, which is what `showDatePicker` builds its grid from.
  DateTime _asPickerDate(CivilDate date) =>
      DateTime(date.year, date.month, date.day);

  Future<void> _save(Vehicle? vehicle) async {
    final draft = _draft;
    if (draft == null || vehicle == null) return;

    final snackbars = CalmSnackbarHost.of(context);
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final today = ref.read(todayProvider) ?? CivilDate.epoch;

    if (draft.problems(today: today).isNotEmpty) {
      // The inline messages under the fields are the explanation. A dialog as
      // well would be the second thing saying what one sentence already says.
      setState(() => _showProblems = true);
      return;
    }

    setState(() => _saving = true);
    final written = await ref
        .read(tripSaveProvider.notifier)
        .save(vehicle: vehicle, draft: draft, existing: _existing);
    if (!mounted) return;
    setState(() => _saving = false);

    if (written case TripSaveFailed(:final failure)) {
      // The form STAYS OPEN with everything intact. Losing a trip because a
      // disk was full is the one failure this screen must not have.
      snackbars.show(message: failure.toString(), danger: true);
      return;
    }
    snackbars.show(message: l10n.tripSavedToast);
    router.pop();
  }

  Future<void> _delete() async {
    final existing = _existing;
    if (existing == null) return;
    final router = GoRouter.of(context);
    final result = await ref
        .read(tripSaveProvider.notifier)
        .delete(existing.id);
    if (!mounted) return;
    if (result case Ok()) router.pop();
  }
}

/// A date, drawn as the reference's two-line tile.
class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final String value;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final error = errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // `CalmPressable`, not `InkWell`: Calm's press is a scale and not a
        // ripple, and `check_component_hygiene.sh` gates the difference.
        CalmPressable(
          onTap: onTap,
          borderRadius: shapes.radiusXl,
          child: Padding(
            padding: EdgeInsetsDirectional.all(space.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: type.caption.copyWith(color: colors.ink3),
                ),
                SizedBox(height: space.s1),
                Text(value, style: type.headline),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: EdgeInsetsDirectional.only(top: space.s1),
            child: Text(
              error,
              style: type.caption.copyWith(color: colors.danger),
            ),
          ),
      ],
    );
  }
}

/// §10's field 8: computed from the odometer pair, editable only without one.
class _DistanceField extends StatelessWidget {
  const _DistanceField({
    required this.draft,
    required this.controller,
    required this.unit,
    required this.formatsTag,
    required this.onChanged,
    this.errorText,
  });

  final TripDraft draft;
  final TextEditingController controller;
  final DistanceUnit unit;
  final String formatsTag;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (draft.distanceIsEditable) {
      return CalmField(
        label: l10n.tripDistanceLabel,
        controller: controller,
        numeric: true,
        keyboardType: TextInputType.number,
        affix: Text(distanceUnitLabel(l10n, unit)),
        errorText: errorText,
        onChanged: onChanged,
      );
    }

    final from = draft.startOdometerMetres(unit: unit);
    final to = draft.endOdometerMetres(unit: unit);
    // Both, or nothing. One endpoint is not half a distance — §1 forbids the
    // app printing a figure it cannot support, and a `ƒ` badge over a guess is
    // exactly the "looks like fact" this rule names.
    final metres = from != null && to != null && to >= from ? to - from : null;

    return CalmField(
      label: l10n.tripDistanceLabel,
      controller: TextEditingController(
        text: metres == null
            ? ''
            : tripDistanceLabel(l10n, formatsTag, Distance(metres), unit),
      ),
      // The `ƒ` badge, and the field goes read-only with it: §10 makes it
      // editable ONLY when both odometer fields are empty.
      computed: true,
      enabled: false,
    );
  }
}

/// §10's expenses section — a LIVE query, never a draft.
///
/// "An expense added through Add expense appears without a save." It reads the
/// same model `trips.list` does, so there is one answer in the app to what a
/// trip cost.
class _ExpensesSection extends ConsumerWidget {
  const _ExpensesSection({
    required this.tripId,
    required this.model,
    required this.formatsTag,
  });

  final String? tripId;
  final TripsListModel model;
  final String formatsTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    final row = tripId == null
        ? null
        : [
            ...model.open,
            ...model.earlier,
          ].where((r) => r.trip.id.toString() == tripId).firstOrNull;
    // Grouped per currency and never summed: §10 draws "612.00 € · 80.00 £"
    // and applies no rate, because there is no rate in this app to apply.
    final total = row == null ? null : tripCostLabel(row.cost, formatsTag);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                total == null
                    ? l10n.tripExpensesLabel
                    : '${l10n.tripExpensesLabel}$kTripsSeparator$total',
                style: type.label,
              ),
            ),
          ],
        ),
        SizedBox(height: space.s3),
        if (total == null)
          Text(
            l10n.tripNoExpenses,
            style: type.body.copyWith(color: colors.ink3),
          ),
        SizedBox(height: space.s3),
        CalmButton(
          label: l10n.tripAddExpense,
          variant: CalmButtonVariant.tonal,
          // §10: `log.expense` with `trip_id` prefilled and locked. The lock
          // is the log modal's to draw; the id travels in the route.
          onPressed: tripId == null
              ? null
              : () => unawaited(
                  context.push('${Routes.log(LogType.expense)}?trip=$tripId'),
                ),
        ),
        // §10 draws the affordance in create mode too, and an expense carries
        // a `trip_id` there is not one of yet. Disabled AND explained: a
        // greyed-out button that says nothing is the failure `CalmButton`
        // asserts against, and dropping it would hide a control §10 names.
        if (tripId == null)
          CalmButtonExplain(reason: l10n.tripSaveFirstToAddExpense),
      ],
    );
  }
}
