// `firstrun.vehicle` — one vehicle and one number.
//
// SPEC.md §8: five controls, one required entry, eight interactions on a
// realistic path. Everything but the odometer has a default, and the odometer
// is the one thing the app cannot invent: with no readings every reminder is
// `unknown`, and day one is a home screen full of dashes.
//
// The back edge is SWALLOWED here, where `firstrun.language` exits the app. The
// two first-run screens answer the same gesture in opposite ways and both are
// right: there is nothing behind the language step, while dismissing this one
// lands in an app with no data — a bug with a nice animation.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/file_picker.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/vehicles/annual_band.dart';
import 'package:odova/features/first_run/first_run_vehicle_notifier.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_chip.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_segmented.dart';
import 'package:odova/ui/calm/calm_sheet.dart';

/// The three tiles, in the order SPEC.md §8 draws them.
///
/// `truck` and `other` are deliberately absent — EPIC-09 F-9.11. §4.8's seeded
/// set has three distinct outcomes and both of them "take the car set
/// unchanged", so a truck owner tapping Car gets exactly the right rows.
const List<VehicleType> _tiles = [
  VehicleType.car,
  VehicleType.motorcycle,
  VehicleType.van,
];

/// The three chips. The other four live behind More….
const List<FuelKind> _chips = [
  FuelKind.petrol,
  FuelKind.diesel,
  FuelKind.electric,
];

/// The More… sheet's contents, per SPEC.md §8's field table.
const List<FuelKind> _moreFuels = [
  FuelKind.lpg,
  FuelKind.cng,
  FuelKind.hybrid,
  FuelKind.other,
];

/// The vehicle step of first run.
class FirstRunVehicleScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const FirstRunVehicleScreen({super.key});

  @override
  ConsumerState<FirstRunVehicleScreen> createState() =>
      _FirstRunVehicleScreenState();
}

class _FirstRunVehicleScreenState extends ConsumerState<FirstRunVehicleScreen> {
  late final TextEditingController _name;
  late final TextEditingController _odometer;

  /// The prefill the type tile implies, or null once the user has typed.
  ///
  /// SPEC.md §8: the name is "text, pre-selected so typing replaces it". The
  /// tile keeps renaming it until a keystroke lands, and then never again — a
  /// user who types "Dad's Volvo" and then corrects the tile must not lose it.
  VehicleType? _followingTile = VehicleType.car;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _odometer = TextEditingController();
    _name.addListener(_onNameEdited);
  }

  @override
  void dispose() {
    _name
      ..removeListener(_onNameEdited)
      ..dispose();
    _odometer.dispose();
    super.dispose();
  }

  void _onNameEdited() {
    final typed = _name.text;
    if (_followingTile == null || typed == _prefillFor(_followingTile!)) return;
    setState(() => _followingTile = null);
    ref.read(firstRunVehicleProvider.notifier).rename(typed);
  }

  String _prefillFor(VehicleType type) {
    final l10n = AppLocalizations.of(context);
    return switch (type) {
      VehicleType.van => l10n.vehicleNameDefaultVan,
      VehicleType.motorcycle => l10n.vehicleNameDefaultMotorcycle,
      _ => l10n.vehicleNameDefaultCar,
    };
  }

  void _chooseType(VehicleType type) {
    ref.read(firstRunVehicleProvider.notifier).chooseType(type);
    if (_followingTile == null) return;
    setState(() => _followingTile = type);
    _applyPrefill(type);
  }

  /// Writes the tile's prefill into the field, PRE-SELECTED.
  ///
  /// Selected rather than merely filled: SPEC.md §8 says "text, pre-selected so
  /// typing replaces it", and the difference is naming a car versus editing a
  /// name somebody else wrote. The first version set the initial prefill with a
  /// bare `_name.text =`, which leaves the selection collapsed at -1 and put
  /// the caret nowhere — so the very first thing a user types would have
  /// appended to "My car".
  void _applyPrefill(VehicleType type) {
    final text = _prefillFor(type);
    _name.value = TextEditingValue(
      text: text,
      selection: TextSelection(baseOffset: 0, extentOffset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(firstRunVehicleProvider);
    final notifier = ref.read(firstRunVehicleProvider.notifier);

    if (_followingTile != null && _name.text.isEmpty) {
      _applyPrefill(_followingTile!);
    }

    return PopScope(
      // SWALLOWED, not exiting. SPEC.md §8: "No Cancel, no back, no
      // swipe-to-dismiss, and Android system back is swallowed."
      canPop: false,
      child: CalmScaffold(
        appBar: CalmAppBar.large(
          title: l10n.firstRunVehicleTitle,
          subtitle: l10n.firstRunVehicleSubtitle,
        ),
        tight: true,
        // The artboard's inline overrides. `.screen__body` at s1/s3 with an s3
        // gap, and `.screen__foot` at s3/s4 — this screen carries five controls
        // where `firstrun.language` carries one list.
        bodyPadBlock: (top: space.s1, bottom: space.s3),
        bodyGap: space.s3,
        footPadBlock: (top: space.s3, bottom: space.s4),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: space.s3,
          children: [
            _StartButton(
              enabled: draft.canStart,
              label: l10n.commonStart,
              onPressed: () => unawaited(_save()),
              onBlockedTap: notifier.refuseStart,
            ),
            CalmButton(
              label: l10n.firstRunHaveBackup,
              variant: CalmButtonVariant.quiet,
              size: CalmButtonSize.sm,
              block: true,
              onPressed: () => unawaited(ref.read(filePickerProvider)()),
            ),
          ],
        ),
        children: [
          CalmSegmented(
            labels: [for (final t in _tiles) _typeLabel(l10n, t)],
            icons: const [
              Icons.directions_car_outlined,
              Icons.two_wheeler_outlined,
              Icons.local_shipping_outlined,
            ],
            index: _tiles.indexOf(draft.type),
            onChanged: (i) => _chooseType(_tiles[i]),
          ),
          CalmField(
            label: l10n.vehicleNameLabel,
            controller: _name,
            textInputAction: TextInputAction.next,
          ),
          _Labelled(
            label: l10n.vehicleFuelLabel,
            child: CalmChipBar(
              chips: [
                for (final fuel in _chips)
                  CalmChip(
                    label: _fuelLabel(l10n, fuel),
                    selected: draft.fuel == fuel,
                    onTap: () => notifier.chooseFuel(fuel),
                  ),
                CalmChip(
                  label: l10n.commonMore,
                  // Selected when the chosen fuel is one of the four behind it,
                  // or the sheet is the only place the user can see what they
                  // picked.
                  selected: _moreFuels.contains(draft.fuel),
                  onTap: () => unawaited(_pickMoreFuel()),
                ),
              ],
            ),
          ),
          CalmField(
            label: l10n.odometerNowLabel,
            controller: _odometer,
            hint: l10n.odometerFirstRunHint,
            errorText: _odometerError(l10n, draft),
            affix: Text(_unitLabel(l10n, draft.unit)),
            numeric: true,
            keyboardType: TextInputType.number,
            onChanged: notifier.typeOdometer,
          ),
          if (draft.problem == OdometerProblem.implausible)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: CalmButton(
                label: l10n.commonUseItAnyway,
                variant: CalmButtonVariant.quiet,
                size: CalmButtonSize.sm,
                onPressed: notifier.useItAnyway,
              ),
            ),
          _Labelled(
            label: draft.unit == DistanceUnit.mi
                ? l10n.annualBandLabelMi
                : l10n.annualBandLabelKm,
            child: CalmSegmented(
              labels: [
                for (final band in AnnualBand.values)
                  _bandLabel(context, l10n, band, draft.unit),
              ],
              numeric: true,
              index: AnnualBand.values.indexOf(draft.band),
              onChanged: (i) => notifier.chooseBand(AnnualBand.values[i]),
            ),
          ),
          if (draft.saveFailed)
            _Labelled(
              label: l10n.saveDiskFullError,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: CalmButton(
                  label: l10n.commonRetry,
                  variant: CalmButtonVariant.quiet,
                  size: CalmButtonSize.sm,
                  onPressed: () => unawaited(_save()),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    ref
        .read(firstRunVehicleProvider.notifier)
        .rename(
          _name.text.trim().isEmpty
              ? _prefillFor(_followingTile ?? VehicleType.car)
              : _name.text.trim(),
        );
    await ref.read(firstRunVehicleProvider.notifier).save();
  }

  Future<void> _pickMoreFuel() async {
    final l10n = AppLocalizations.of(context);
    final chosen = await CalmSheet.show<FuelKind>(
      context,
      builder: (sheetContext) => CalmSheet(
        title: l10n.vehicleFuelLabel,
        children: [
          for (final fuel in _moreFuels)
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
    ref.read(firstRunVehicleProvider.notifier).chooseFuel(chosen);
  }

  String? _odometerError(AppLocalizations l10n, FirstRunVehicleDraft draft) =>
      switch (draft.problem) {
        null => null,
        // Empty says nothing until Start has been pressed and refused. SPEC.md
        // §8 puts this message under "Empty on Save" and pairs it with "tapping
        // it flashes the odometer hint" — a form that scolds you before you
        // have typed is a form that is angry at you for arriving, and a
        // disabled button that does nothing at all when tapped is a dead
        // rectangle.
        OdometerProblem.empty =>
          draft.startRefused ? l10n.odometerEmptyError : null,
        OdometerProblem.notANumber => l10n.odometerNotANumberError,
        OdometerProblem.implausible => l10n.odometerImplausibleWarning,
      };

  String _typeLabel(AppLocalizations l10n, VehicleType type) => switch (type) {
    VehicleType.van => l10n.vehicleTypeVan,
    VehicleType.motorcycle => l10n.vehicleTypeMotorcycle,
    _ => l10n.vehicleTypeCar,
  };

  String _fuelLabel(AppLocalizations l10n, FuelKind fuel) => switch (fuel) {
    FuelKind.petrol => l10n.fuelPetrol,
    FuelKind.diesel => l10n.fuelDiesel,
    FuelKind.electric => l10n.fuelElectric,
    FuelKind.lpg => l10n.fuelLpg,
    FuelKind.cng => l10n.fuelCng,
    FuelKind.hybrid => l10n.fuelHybrid,
    FuelKind.other => l10n.fuelOther,
  };

  String _unitLabel(AppLocalizations l10n, DistanceUnit unit) =>
      unit == DistanceUnit.mi ? l10n.unitDistanceMi : l10n.unitDistanceKm;

  /// One band's chip label, with its numbers shaped by the active system.
  ///
  /// The numbers are formatted HERE and passed in as strings, because the ARB
  /// gate refuses a literal digit in a value — and it refuses it for the same
  /// reason the design needs this: `۱۰–۲۰` is what a Persian reader must see,
  /// and a hard-coded "10" renders Latin in every locale.
  String _bandLabel(
    BuildContext context,
    AppLocalizations l10n,
    AnnualBand band,
    DistanceUnit unit,
  ) {
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;
    String n(int value) =>
        formatForDisplay(value.toDouble(), tag, numerals: CalmNumerals.auto);

    final edges = band.edgesFor(unit);
    return switch (edges) {
      (min: null, max: final max?) => l10n.annualBandUnder(n(max)),
      (min: final min?, max: null) => l10n.annualBandOver(n(min)),
      (min: final min?, max: final max?) => l10n.annualBandRange(
        n(min),
        n(max),
      ),
      _ => '',
    };
  }
}

/// `.field` — a label above a control that is not a `CalmField`.
class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: space.s2,
      children: [CalmFieldLabel(label), child],
    );
  }
}

/// Start, and the tap a disabled Start still has to receive.
///
/// SPEC.md §8 wants both halves — "visibly disabled, and tapping it flashes the
/// odometer hint" — and a disabled `CalmPressable` is wrapped in an
/// `IgnorePointer`, so the button cannot hear its own tap. The listener is
/// therefore OUTSIDE it.
///
/// `opaque` rather than the default `deferToChild`, and it is defensive rather
/// than load-bearing: today a disabled button still paints a decorated box that
/// answers a hit test, so `deferToChild` would work too. It would stop working
/// the day that box became transparent or the button started wrapping itself in
/// an `IgnorePointer` from the outside — and the failure would be a Start that
/// silently does nothing, which is the exact defect this widget exists to
/// prevent.
class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.enabled,
    required this.label,
    required this.onPressed,
    required this.onBlockedTap,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;
  final VoidCallback onBlockedTap;

  @override
  Widget build(BuildContext context) {
    final button = CalmButton(
      label: label,
      size: CalmButtonSize.lg,
      block: true,
      onPressed: enabled ? onPressed : null,
      // The explanation is the odometer hint, on screen whether or not this
      // button is disabled. A second copy of "Read it off the dash." beneath
      // the button is the same sentence twice, on the screen with the least
      // room for it.
      disabledBecause: 'the odometer hint, always visible under the field',
    );
    if (enabled) return button;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onBlockedTap,
      child: button,
    );
  }
}
