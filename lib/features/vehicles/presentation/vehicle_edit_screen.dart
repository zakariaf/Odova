// `vehicle.edit` — every fact about one vehicle.
//
// SPEC.md §8. A modal, closed with a ✕ rather than the word Cancel, and it is
// the screen a dirty dismiss guards: EPIC-08's `showDiscardDialog` through its
// `DirtyModalGuard`, never a copy.
//
// The ODOMETER is a read-only row here and an input only in create mode. §8:
// "A facts form is the wrong place to write a dated reading — someone
// correcting the plate would stamp today's date on a number they last checked
// in March, and that corrupts the series the whole app depends on."
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/dirty_modal_guard.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/l10n/format_defaults.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/odometer/odometer_entry.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/vehicles/vehicle_colour.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/presentation/vehicle_actions.dart';
import 'package:odova/features/vehicles/vehicle_edit_draft.dart';
import 'package:odova/features/vehicles/vehicle_edit_notifier.dart';
import 'package:odova/features/vehicles/vehicle_status_line.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/unit_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/vehicle_swatch.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_icon_tile.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_segmented.dart';
import 'package:odova/ui/calm/calm_sheet.dart';
import 'package:odova/ui/calm/calm_swatch.dart';
import 'package:odova/ui/calm/calm_switch.dart';
import 'package:odova/ui/dialogs/discard_dialog.dart';

/// The four segments, in the order the artboard draws them.
///
/// `truck` has none — EPIC-09 F-9.21, raised rather than closed: §4.8 gives it
/// the car set unchanged, so the choice costs a label and not a reminder, but
/// this IS the screen a truck owner would come to in order to fix that label.
const List<VehicleType> _typeSegments = [
  VehicleType.car,
  VehicleType.van,
  VehicleType.motorcycle,
  VehicleType.other,
];

/// Every fact about one vehicle.
/// Which of `vehicle.edit`'s two modes this is.
///
/// SPEC.md §8 draws one screen twice: "in create mode it is an input; in edit
/// mode a row showing the latest reading and its age". An ENUM rather than a
/// nullable id, because a null id already means something else here — a deep
/// link carrying an id that will not parse — and the two states draw very
/// differently.
enum VehicleEditMode {
  /// Editing [VehicleEditScreen.vehicleId], or drawing the closable shell when
  /// it is null because the path was malformed.
  edit,

  /// Creating one. Save pops with the new vehicle's `VehicleId`, and what
  /// happens next is the CALLER's decision: the garage's + offers "Switch to
  /// it" in a snackbar, `vehicle.switcher` makes it active and dismisses
  /// itself too.
  create,
}

/// `vehicle.edit` — one vehicle's facts, or a new one.
class VehicleEditScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const VehicleEditScreen({
    required this.vehicleId,
    this.mode = VehicleEditMode.edit,
    super.key,
  });

  /// Whether this form edits a vehicle or creates one.
  final VehicleEditMode mode;

  /// Which vehicle, or null when a deep link carried an id that will not
  /// parse.
  ///
  /// NULLABLE because `/settings/vehicles/not-an-id` is a link somebody can
  /// send, and SPEC.md §7 says a bad one lands somewhere rather than nowhere.
  /// It draws the same shell an unloaded or deleted vehicle draws — the user
  /// sees a modal they can close, not a crash and not a blank route.
  final VehicleId? vehicleId;

  @override
  ConsumerState<VehicleEditScreen> createState() => _VehicleEditScreenState();
}

class _VehicleEditScreenState extends ConsumerState<VehicleEditScreen> {
  final _name = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _plate = TextEditingController();
  final _vin = TextEditingController();
  final _notes = TextEditingController();

  /// Create mode's odometer field. Never attached in edit mode, where the
  /// odometer is a read-only row.
  final _odometer = TextEditingController();

  /// Whether the controllers have been filled from the loaded row.
  ///
  /// Once, not on every build: re-seeding would fight the user's typing, and
  /// the notifier deliberately never reloads its row.
  bool _seeded = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _make,
      _model,
      _year,
      _plate,
      _vin,
      _notes,
      _odometer,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _seed(VehicleEditDraft draft) {
    _seeded = true;
    _name.text = draft.name;
    _make.text = draft.make ?? '';
    _model.text = draft.model ?? '';
    _year.text = draft.year?.toString() ?? '';
    _plate.text = draft.plate ?? '';
    _vin.text = draft.vin ?? '';
    _notes.text = draft.notes ?? '';
  }

  /// The provider key: null in create mode, the vehicle in edit mode.
  VehicleId? get _key =>
      widget.mode == VehicleEditMode.create ? null : widget.vehicleId;

  VehicleEditNotifier get _notifier =>
      ref.read(vehicleEditProvider(_key).notifier);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final creating = widget.mode == VehicleEditMode.create;
    final id = widget.vehicleId;
    // A malformed deep link is the only case with neither a mode nor an id,
    // and it must not read the create-mode provider by accident.
    final state = creating || id != null
        ? ref.watch(vehicleEditProvider(_key))
        : null;

    if (state is! VehicleEditReady) {
      return CalmScaffold(
        appBar: CalmAppBar.modal(
          title: l10n.vehicleEditTitle,
          startLabel: l10n.commonClose,
          startIcon: Icons.close,
          onStart: () => Navigator.of(context).maybePop(),
          endLabel: l10n.commonSave,
          onEnd: () {},
        ),
        children: const [],
      );
    }

    final draft = state.draft;
    if (!_seeded) _seed(draft);

    return DirtyModalGuard(
      // EPIC-08's guard and EPIC-08's dialog, never a copy. This screen
      // supplies only the SUBJECT and the SUMMARY and owns the draft it drops;
      // what a dismissal means is one decision made once, for every modal.
      // The STATE's, not the draft's: create mode's odometer is not on the
      // draft, and six digits typed at a pump is exactly the work this guard
      // exists to stop losing.
      isDirty: () => state.isDirty,
      onDiscard: () => ref.invalidate(vehicleEditProvider(_key)),
      confirmDiscard: (context) async =>
          await showDiscardDialog(
            context,
            subject: draft.name.trim().isEmpty
                ? l10n.vehicleAddTitle
                : draft.name,
            summary: l10n.vehicleEditTitle,
          ) ==
          DiscardChoice.discard,
      child: _form(context, l10n, space, state, id),
    );
  }

  Widget _form(
    BuildContext context,
    AppLocalizations l10n,
    CalmSpace space,
    VehicleEditReady state,
    VehicleId? id,
  ) {
    final draft = state.draft;
    return CalmScaffold(
      appBar: CalmAppBar.modal(
        // The VEHICLE'S NAME, not the word "Vehicle" — the artboard titles this
        // modal "Golf". A user with three cars open in three modals needs to
        // know which one they are looking at, and the generic word tells them
        // nothing. `vehicleEditTitle` stays for the loading state, where there
        // is no name to show yet.
        title: draft.name.trim().isNotEmpty
            ? draft.name.trim()
            // A create form has no name to title itself with until the user
            // types one, and "Vehicle" over a blank form says nothing about
            // what pressing Save would do.
            : state.creating
            ? l10n.vehicleAddTitle
            : l10n.vehicleEditTitle,
        // A GLYPH, per the artboard, and named all the same — a bare ✕
        // announced as "button" leaves the only way out of a full-screen modal
        // unlabelled.
        startLabel: l10n.commonClose,
        startIcon: Icons.close,
        onStart: () => Navigator.of(context).maybePop(),
        endLabel: l10n.commonSave,
        onEnd: state.canSave ? () => unawaited(_save()) : null,
      ),
      tight: true,
      // The artboard's inline `gap:10px; padding-block:18px 12px`, rounded to
      // the nearest tokens. Ten, eighteen and twelve are not on Calm's
      // 4/8/12/16/20/24 scale at all, and `lib/features/` may not carry a raw
      // number — so the screen takes s3/s5/s3 and the two-pixel difference is
      // recorded rather than smuggled in as a literal.
      bodyGap: space.s3,
      bodyPadBlock: (top: space.s5, bottom: space.s3),
      children: [
        _ColourRow(
          selected: draft.colour,
          onChanged: (colour) =>
              _notifier.edit((d) => d.copyWith(colour: colour)),
        ),
        CalmField(
          label: l10n.vehicleNameLabel,
          controller: _name,
          onChanged: (value) => _notifier.edit((d) => d.copyWith(name: value)),
        ),
        CalmSegmented(
          labels: [for (final t in _typeSegments) vehicleTypeLabel(l10n, t)],
          index: _typeSegments.indexOf(draft.vehicleType),
          onChanged: (i) =>
              _notifier.edit((d) => d.copyWith(vehicleType: _typeSegments[i])),
        ),
        // PAIRED, as the artboard draws them. Make and Model belong together
        // and so do Year and Plate; stacking all four turns four short answers
        // into four screenfuls of scrolling.
        _Pair(
          start: CalmField(
            label: l10n.vehicleMakeLabel,
            controller: _make,
            onChanged: (value) => _notifier.edit(
              (d) => value.trim().isEmpty
                  ? d.copyWith(clear: {VehicleField.make})
                  : d.copyWith(make: value),
            ),
          ),
          end: CalmField(
            label: l10n.vehicleModelLabel,
            controller: _model,
            onChanged: (value) => _notifier.edit(
              (d) => value.trim().isEmpty
                  ? d.copyWith(clear: {VehicleField.model})
                  : d.copyWith(model: value),
            ),
          ),
        ),
        _Pair(
          start: CalmField(
            label: l10n.vehicleYearLabel,
            controller: _year,
            numeric: true,
            keyboardType: TextInputType.number,
            errorText: draft.yearOutOfRange(_thisYear())
                ? l10n.vehicleYearRangeError(
                    _number(kEarliestVehicleYear),
                    _number(_thisYear() + 1),
                  )
                : null,
            onChanged: (value) => _notifier.edit((d) {
              final year = int.tryParse(value.trim());
              return year == null
                  ? d.copyWith(clear: {VehicleField.year})
                  : d.copyWith(year: year);
            }),
          ),
          end: CalmField(
            label: l10n.vehiclePlateLabel,
            controller: _plate,
            // Forced LTR and start-aligned even on a Persian screen, and
            // stored verbatim: an Iranian plate legitimately carries Persian
            // digits AND a Persian letter, and reordering it rewrites
            // somebody's own characters.
            code: true,
            onChanged: (value) => _notifier.edit(
              (d) => value.trim().isEmpty
                  ? d.copyWith(clear: {VehicleField.plate})
                  : d.copyWith(plate: value),
            ),
          ),
        ),
        CalmField(
          label: l10n.vehicleVinLabel,
          controller: _vin,
          code: true,
          // A NOTE, not an error: some pre-1981 and non-road vehicles have
          // shorter numbers, and refusing theirs would mean refusing the
          // vehicle. It goes in the hint slot rather than the error slot for
          // exactly that reason.
          hint: draft.vinLengthUnusual
              ? l10n.vehicleVinLengthNote(_number(kVinLength))
              : null,
          onChanged: (value) => _notifier.edit(
            (d) => value.trim().isEmpty
                ? d.copyWith(clear: {VehicleField.vin})
                : d.copyWith(vin: value),
          ),
        ),
        CalmField(
          label: l10n.vehicleNotesLabel,
          controller: _notes,
          size: CalmFieldSize.multiline,
          onChanged: (value) => _notifier.edit(
            (d) => value.trim().isEmpty
                ? d.copyWith(clear: {VehicleField.notes})
                : d.copyWith(notes: value),
          ),
        ),
        CalmRowGroup(
          rows: [
            CalmListRow.switchRow(
              title: l10n.vehicleBusinessLabel,
              // Null, not a no-op: the ROW toggles, and a live callback here
              // would make the switch a child recognizer that wins the arena
              // and does nothing.
              end: CalmSwitch(value: draft.isBusiness, onChanged: null),
              onToggle: () => _notifier.edit(
                (d) => d.copyWith(isBusiness: !d.isBusiness),
              ),
            ),
            CalmListRow.switchRow(
              title: l10n.vehicleMuteLabel,
              end: CalmSwitch(value: draft.notificationsMuted, onChanged: null),
              onToggle: () => _notifier.edit(
                (d) => d.copyWith(
                  notificationsMuted: !d.notificationsMuted,
                ),
              ),
            ),
          ],
        ),
        CalmRowGroup(
          rows: [
            CalmListRow(
              title: l10n.vehicleFuelLabel,
              value: vehicleFuelLabel(l10n, draft.fuelKindDefault),
              // A caret DOWN, and it does not mirror — the artboard omits
              // `icon--directional` here where the odometer and sale rows carry
              // it. A menu opens downward in both directions.
              end: const Icon(Icons.expand_more, size: 20),
              onTap: () => unawaited(_pickFuel()),
            ),
          ],
        ),
        // READ-ONLY in edit mode and an input in create mode. SPEC.md §8: a
        // facts form is the wrong place to write a DATED reading — someone
        // correcting the plate would stamp today's date on a number they last
        // checked in March, and that corrupts the series the whole app depends
        // on. A create has no series to corrupt and no other way to get its
        // first reading, which the domain contract requires (§3).
        if (state.odometer case final odometer?) ...[
          CalmField(
            label: l10n.odometerNowLabel,
            controller: _odometer,
            hint: l10n.odometerFirstRunHint,
            errorText: _odometerMessage(l10n, odometer),
            affix: Text(_unitLabel(l10n, odometer.unit)),
            numeric: true,
            keyboardType: TextInputType.number,
            onChanged: _notifier.typeOdometer,
          ),
          if (odometer.problem == OdometerProblem.implausible)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: CalmButton(
                label: l10n.commonUseItAnyway,
                variant: CalmButtonVariant.quiet,
                size: CalmButtonSize.sm,
                onPressed: _notifier.useItAnyway,
              ),
            ),
        ] else if (id != null)
          _OdometerRow(vehicleId: id, unit: draft.distanceUnit),
        // ABSENT in create mode, not disabled: there is nothing to sell and
        // nothing to delete, and a destructive row on a car that does not
        // exist is a control that can only lie.
        if (state.draft.original.id != kUnsavedVehicleId)
          CalmRowGroup(
            rows: [
              // The garage's flows, not copies of them. `vehicle_actions.dart`
              // owns "Keep it — mark it sold", the ten-second Undo and the
              // last-vehicle route, and a second copy here is a second place
              // for one of the three to go missing.
              CalmListRow(
                title: l10n.vehicleMarkAsSold,
                showChevron: true,
                onTap: () => unawaited(_sell(state.draft.original)),
              ),
              CalmListRow(
                title: l10n.vehicleDeleteRowEmpty(draft.name.trim()),
                danger: true,
                lead: const Icon(Icons.delete_outline, size: 20),
                onTap: () => unawaited(_delete(state.draft.original)),
              ),
            ],
          ),
        // NOT YET: SPEC.md §8's two disclosure groups — `Purchase and sale`
        // and `This vehicle's units & currency`. `CalmDisclosure` is built and
        // tested; what is missing is their CONTENTS, which need a date picker,
        // a money field and six override controls that do not exist yet.
        //
        // They are absent rather than stubbed. A collapsed group that opens on
        // nothing, or a `Mark as sold` row whose tap does nothing, is a control
        // that lies — and a user who taps it learns the app is unfinished in a
        // way an absent row never teaches them.
      ],
    );
  }

  /// The More… equivalent for fuel: every kind, in a sheet.
  Future<void> _pickFuel() async {
    final l10n = AppLocalizations.of(context);
    final chosen = await CalmSheet.show<FuelKind>(
      context,
      builder: (sheetContext) => CalmSheet(
        title: l10n.vehicleFuelLabel,
        children: [
          for (final fuel in FuelKind.values)
            CalmButton(
              label: vehicleFuelLabel(l10n, fuel),
              variant: CalmButtonVariant.tonal,
              block: true,
              onPressed: () => Navigator.of(sheetContext).pop(fuel),
            ),
        ],
      ),
    );
    if (chosen == null || !mounted) return;
    _notifier.edit((d) => d.copyWith(fuelKindDefault: chosen));
  }

  Future<void> _save() async {
    final saved = await _notifier.save();
    if (saved == null || !mounted) return;
    // `pop`, not `maybePop`. `DirtyModalGuard` holds `canPop: false` so that a
    // DISMISSAL can be refused and re-issued after the discard dialog answers
    // — and its re-issue carries no result, which silently swallowed the id
    // below. A save is not a dismissal: nothing is being lost, there is
    // nothing to ask about, and the guard has no business in it.
    //
    // The new vehicle's id travels back with the pop, and the CALLER decides
    // what it means. SPEC.md §8 gives the two doors opposite answers: the
    // garage's + "appends the vehicle, does not make it active", while
    // add-from-switcher makes it active and dismisses the sheet as well.
    Navigator.of(
      context,
    ).pop(widget.mode == VehicleEditMode.create ? saved : null);
  }

  /// Sells this vehicle, then leaves.
  ///
  /// The modal DISMISSES on a sale, and not for tidiness: `VehicleEditDraft`
  /// copies `status` from the row it loaded, so a form left open over a
  /// just-sold vehicle writes `active` back over it on the next Save and undoes
  /// the sale in silence. Leaving is also what the user asked for — they
  /// pressed a row that ends the vehicle's life in the app.
  Future<void> _sell(Vehicle vehicle) async {
    final outcome = await markVehicleSold(context, ref, vehicle);
    if (outcome == VehicleActionOutcome.sold && mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Deletes this vehicle, then leaves.
  ///
  /// A cancelled or failed delete stays: there is nothing to leave for, and a
  /// modal that closes on Cancel teaches the user that Cancel is not one.
  Future<void> _delete(Vehicle vehicle) async {
    final outcome = await confirmDeleteVehicle(context, ref, vehicle);
    if (outcome == VehicleActionOutcome.none || !mounted) return;
    // A last-vehicle delete has already routed to first run
    // (`vehicle_actions.dart`), and popping a modal off a route that is going
    // away anyway is harmless — `maybePop` would ask the dirty guard about a
    // vehicle that no longer exists.
    Navigator.of(context).pop();
  }

  /// What the odometer field says under itself, or nothing.
  ///
  /// The implausible case is a WARNING (§8: "never a block"), and it shares
  /// this one message slot with the two that are errors. Empty says nothing at
  /// all: a form that scolds before anything is typed is a form that is angry
  /// at the user for arriving, and here Save is simply not offered yet.
  String? _odometerMessage(AppLocalizations l10n, OdometerEntry odometer) =>
      switch (odometer.problem) {
        null || OdometerProblem.empty => null,
        OdometerProblem.notANumber => l10n.odometerNotANumberError,
        OdometerProblem.implausible => l10n.odometerImplausibleWarning,
      };

  String _unitLabel(AppLocalizations l10n, DistanceUnit unit) =>
      unit == DistanceUnit.mi ? l10n.unitDistanceMi : l10n.unitDistanceKm;

  /// This year, from the INJECTED clock.
  ///
  /// SPEC.md §3: time is an argument. `DateTime.now()` here would make the
  /// year field's upper bound depend on the machine running the test, and the
  /// message would read a different number every January.
  int _thisYear() => ref.read(clockProvider).now().year;

  String _number(int value) => formatForDisplay(
    value.toDouble(),
    ref.read(resolvedLocaleTagsProvider).formats,
    numerals: CalmNumerals.auto,
    // A year and a character count are counts, not quantities: no grouping
    // separator, or 1900 reads as 1,900.
    grouped: false,
  );
}

/// `.swatchrow` — nine colours in a row that SCROLLS.
///
/// EPIC-09 F-9.18: it wrapped in an earlier draft, which meant the screen
/// changed height as the palette grew. `other` is an outlined swatch with no
/// fill, because the design supplied eight paints and a ninth hex chosen to sit
/// beside eight hand-tuned ones is design work rather than engineering.
class _ColourRow extends StatelessWidget {
  const _ColourRow({required this.selected, required this.onChanged});

  final VehicleColour? selected;
  final ValueChanged<VehicleColour> onChanged;

  /// `.swatch { width: 26px; height: 26px }`.

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);
    final l10n = AppLocalizations.of(context);

    return Row(
      spacing: space.s4,
      children: [
        const CalmIconTile(icon: Icons.directions_car_outlined, brand: true),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: space.s2,
              children: [
                for (final colour in VehicleColour.values)
                  CalmSwatch(
                    paint: calmVehicleSwatch(colour),
                    selected: colour == selected,
                    label: _colourLabel(l10n, colour),
                    onTap: () => onChanged(colour),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _colourLabel(AppLocalizations l10n, VehicleColour colour) =>
      switch (colour) {
        VehicleColour.white => l10n.colourWhite,
        VehicleColour.silver => l10n.colourSilver,
        VehicleColour.grey => l10n.colourGrey,
        VehicleColour.black => l10n.colourBlack,
        VehicleColour.red => l10n.colourRed,
        VehicleColour.blue => l10n.colourBlue,
        VehicleColour.green => l10n.colourGreen,
        VehicleColour.yellow => l10n.colourYellow,
        VehicleColour.other => l10n.colourOther,
      };
}

/// The latest reading and how old it is, as a row that opens `log.odometer`.
class _OdometerRow extends ConsumerWidget {
  const _OdometerRow({required this.vehicleId, required this.unit});

  final VehicleId vehicleId;

  /// The vehicle's own override, or null to follow the app's setting.
  final DistanceUnit? unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;
    final readings = ref.watch(odometerReadingsProvider(vehicleId)).value;
    final shown = unit ?? formatDefaultsFor(tag).distance;

    // The LAST of the query's order, which SPEC.md §3 sorts oldest first.
    final latest = (readings == null || readings.isEmpty)
        ? null
        : readings.last;

    return CalmRowGroup(
      rows: [
        CalmListRow(
          title: l10n.vehicleOdometerRow,
          // The reading and its unit are ONE run — SPEC.md §5 — so a Persian
          // screen never splits `۱۸۷٬۴۱۲ کیلومتر` across the mirror.
          value: latest == null
              ? null
              : formatWithUnit(
                  latest.odometer.inUnit(shown),
                  shown == DistanceUnit.mi
                      ? l10n.unitDistanceMi
                      : l10n.unitDistanceKm,
                  tag,
                  numerals: CalmNumerals.auto,
                  decimalDigits: 0,
                ),
          subtitle: latest == null
              ? null
              // The GARAGE's formatter, not a copy. This screen had its own,
              // which forced `'en'` and Latin numerals — so one reading read
              // "۴ ماه پیش" in the garage and "4 months ago" one tap away.
              : l10n.vehicleOdometerRowHint(
                  formatDaysAgo(
                    l10n,
                    tag,
                    _daysSince(ref, latest.occurredOn),
                  ),
                ),
          showChevron: true,
          // EPIC-11 owns `log.odometer`. Until it exists the row is INERT —
          // `CalmListRow` draws an inert row without a tap target, so this is
          // an absent control rather than a chevron that navigates nowhere.
        ),
      ],
    );
  }

  /// Whole calendar days from [occurredOn] to the clock's today.
  ///
  /// Through `CivilDate`, which is the only thing in the repo allowed to count
  /// days. This row used to subtract two `DateUtils.dateOnly` values and read
  /// `.inDays` off the `Duration`, which counts ELAPSED TIME: two dates two
  /// calendar days apart across a spring-forward differ by 47 hours and
  /// truncate to 1, so "3 days ago" rendered as "2 days ago" for every user in
  /// Europe on the last Sunday in March. `CivilDate.daysUntil`'s own dartdoc
  /// documents that exact failure, `monotonicity.dart` shipped it once, and a
  /// suite running in UTC — which CI does — cannot see it.
  ///
  /// An unparseable date counts as today rather than throwing: the row's job
  /// is to draw, and SPEC.md §8's "the row never disappears" covers its
  /// sub-line for the same reason it covers the count.
  int _daysSince(WidgetRef ref, String occurredOn) {
    final taken = CivilDate.tryParse(occurredOn);
    final today = CivilDate.fromDateTime(ref.read(clockProvider).now());
    if (taken == null || today == null) return 0;
    return taken.daysUntil(today);
  }
}

/// Two fields side by side, as the artboard pairs Make/Model and Year/Plate.
///
/// A `Row` of `Expanded`s rather than a grid: the two halves are equal and the
/// order mirrors for free under RTL, which a hand-placed left/right would not.
class _Pair extends StatelessWidget {
  const _Pair({required this.start, required this.end});

  final Widget start;
  final Widget end;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: space.s3,
      children: [
        Expanded(child: start),
        Expanded(child: end),
      ],
    );
  }
}
