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
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/l10n/format_defaults.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/l10n/relative_past.dart';
import 'package:odova/core/vehicles/vehicle_colour.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/vehicle_edit_draft.dart';
import 'package:odova/features/vehicles/vehicle_edit_notifier.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/unit_format.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/vehicle_swatch.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_icon_tile.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_segmented.dart';
import 'package:odova/ui/calm/calm_sheet.dart';
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
class VehicleEditScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const VehicleEditScreen({required this.vehicleId, super.key});

  /// Which vehicle.
  final VehicleId vehicleId;

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

  /// Whether the controllers have been filled from the loaded row.
  ///
  /// Once, not on every build: re-seeding would fight the user's typing, and
  /// the notifier deliberately never reloads its row.
  bool _seeded = false;

  @override
  void dispose() {
    for (final c in [_name, _make, _model, _year, _plate, _vin, _notes]) {
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

  VehicleEditNotifier get _notifier =>
      ref.read(vehicleEditProvider(widget.vehicleId).notifier);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final state = ref.watch(vehicleEditProvider(widget.vehicleId));

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
      isDirty: () => draft.isDirty,
      onDiscard: () => ref.invalidate(vehicleEditProvider(widget.vehicleId)),
      confirmDiscard: (context) async =>
          await showDiscardDialog(
            context,
            subject: draft.name,
            summary: l10n.vehicleEditTitle,
          ) ==
          DiscardChoice.discard,
      child: _form(context, l10n, space, state),
    );
  }

  Widget _form(
    BuildContext context,
    AppLocalizations l10n,
    CalmSpace space,
    VehicleEditReady state,
  ) {
    final draft = state.draft;
    return CalmScaffold(
      appBar: CalmAppBar.modal(
        // The VEHICLE'S NAME, not the word "Vehicle" — the artboard titles this
        // modal "Golf". A user with three cars open in three modals needs to
        // know which one they are looking at, and the generic word tells them
        // nothing. `vehicleEditTitle` stays for the loading state, where there
        // is no name to show yet.
        title: draft.name.trim().isEmpty
            ? l10n.vehicleEditTitle
            : draft.name.trim(),
        // A GLYPH, per the artboard, and named all the same — a bare ✕
        // announced as "button" leaves the only way out of a full-screen modal
        // unlabelled.
        startLabel: l10n.commonClose,
        startIcon: Icons.close,
        onStart: () => Navigator.of(context).maybePop(),
        endLabel: l10n.commonSave,
        onEnd: draft.canSave ? () => unawaited(_save()) : null,
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
          labels: [for (final t in _typeSegments) _typeLabel(l10n, t)],
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
              end: CalmSwitch(
                value: draft.isBusiness,
                onChanged: (_) {},
              ),
              onToggle: () => _notifier.edit(
                (d) => d.copyWith(isBusiness: !d.isBusiness),
              ),
            ),
            CalmListRow.switchRow(
              title: l10n.vehicleMuteLabel,
              end: CalmSwitch(
                value: draft.notificationsMuted,
                onChanged: (_) {},
              ),
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
              value: _fuelLabel(l10n, draft.fuelKindDefault),
              // A caret DOWN, and it does not mirror — the artboard omits
              // `icon--directional` here where the odometer and sale rows carry
              // it. A menu opens downward in both directions.
              end: const Icon(Icons.expand_more, size: 20),
              onTap: () => unawaited(_pickFuel()),
            ),
          ],
        ),
        // READ-ONLY here and an input only in create mode. SPEC.md §8: a facts
        // form is the wrong place to write a dated reading — someone
        // correcting the plate would stamp today's date on a number they last
        // checked in March, and that corrupts the series the whole app depends
        // on. Tapping it goes to `log.odometer`, where a reading has a date.
        _OdometerRow(vehicleId: widget.vehicleId, unit: draft.distanceUnit),
        CalmRowGroup(
          rows: [
            CalmListRow(
              title: l10n.vehicleMarkAsSold,
              showChevron: true,
              // EPIC-09 task 9.6 owns the sale form and the confirm-delete
              // dialog. Inert until then rather than wired to nothing.
            ),
            CalmListRow(
              title: l10n.vehicleDeleteRowEmpty(draft.name.trim()),
              danger: true,
              lead: const Icon(Icons.delete_outline, size: 20),
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
              label: _fuelLabel(l10n, fuel),
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

  String _fuelLabel(AppLocalizations l10n, FuelKind fuel) => switch (fuel) {
    FuelKind.petrol => l10n.fuelPetrol,
    FuelKind.diesel => l10n.fuelDiesel,
    FuelKind.electric => l10n.fuelElectric,
    FuelKind.lpg => l10n.fuelLpg,
    FuelKind.cng => l10n.fuelCng,
    FuelKind.hybrid => l10n.fuelHybrid,
    FuelKind.other => l10n.fuelOther,
  };

  Future<void> _save() async {
    if (await _notifier.save() && mounted) {
      await Navigator.of(context).maybePop();
    }
  }

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

  String _typeLabel(AppLocalizations l10n, VehicleType type) => switch (type) {
    VehicleType.van => l10n.vehicleTypeVan,
    VehicleType.motorcycle => l10n.vehicleTypeMotorcycle,
    VehicleType.other => l10n.vehicleTypeOther,
    _ => l10n.vehicleTypeCar,
  };
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
  static const double _swatch = 26;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
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
                  _Swatch(
                    colour: colour,
                    paint: calmVehicleSwatch(colour),
                    selected: colour == selected,
                    label: _colourLabel(l10n, colour),
                    size: _swatch,
                    ring: colors.brand,
                    outline: colors.divider,
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

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.colour,
    required this.paint,
    required this.selected,
    required this.label,
    required this.size,
    required this.ring,
    required this.outline,
    required this.onTap,
  });

  final VehicleColour colour;
  final Color? paint;
  final bool selected;
  final String label;
  final double size;
  final Color ring;
  final Color outline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CalmPressable(
      onTap: onTap,
      borderRadius: size / 2,
      // The NAME, because a circle of colour has no text and a screen reader
      // would otherwise announce nine identical buttons.
      semanticLabel: label,
      toggled: selected,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: paint,
            shape: BoxShape.circle,
            border: Border.all(
              // A paint gets a hairline so white reads against white; `other`
              // gets the same hairline and no fill, which IS its drawing.
              color: selected ? ring : outline,
              width: selected ? 2.5 : 1.5,
            ),
          ),
        ),
      ),
    );
  }
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
              : l10n.vehicleOdometerRowHint(_age(context, l10n, latest)),
          showChevron: true,
          // EPIC-11 owns `log.odometer`. Until it exists the row is INERT —
          // `CalmListRow` draws an inert row without a tap target, so this is
          // an absent control rather than a chevron that navigates nowhere.
        ),
      ],
    );
  }

  /// How long ago the reading was taken, as a phrase.
  String _age(
    BuildContext context,
    AppLocalizations l10n,
    OdometerReading reading,
  ) {
    final today = DateUtils.dateOnly(
      ProviderScope.containerOf(context).read(clockProvider).now(),
    );
    final taken = DateTime.tryParse(reading.occurredOn);
    if (taken == null) return l10n.dateToday;

    // The PAST side of the bucketing, not `bucketRelativeDays`. Its `overdue`
    // bucket counts exact days because a missed due date must say 123 rather
    // than "about 4 months" — but a READING taken 123 days ago is a fact about
    // how much the app knows, and SPEC.md §5's "in about 7 weeks is an answer"
    // applies to it unchanged. This used to read "123 days ago".
    //
    // A date in the FUTURE collapses to today rather than inventing a phrase:
    // the app never writes one, but a restored backup can.
    final past = bucketDaysAgo(
      today.difference(DateUtils.dateOnly(taken)).inDays,
    );
    return switch (past.bucket) {
      PastDateBucket.today => l10n.dateToday,
      PastDateBucket.yesterday => l10n.dateYesterday,
      PastDateBucket.daysAgo => l10n.dateDaysAgo(
        past.count,
        _plain(past.count),
      ),
      PastDateBucket.aboutWeeksAgo => l10n.dateAboutWeeksAgo(
        past.count,
        _plain(past.count),
      ),
      PastDateBucket.aboutMonthsAgo => l10n.dateAboutMonthsAgo(
        past.count,
        _plain(past.count),
      ),
    };
  }

  String _plain(int value) => formatForDisplay(
    value.toDouble(),
    'en',
    numerals: CalmNumerals.latin,
    grouped: false,
  );
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
