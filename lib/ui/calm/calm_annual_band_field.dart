// "Roughly how far a year" — the four bands, labelled in the user's own unit.
//
// SPEC.md §8 asks for this on `firstrun.vehicle` and lists `expected_annual_m`
// among `vehicle.edit`'s controls that "need no explanation". It is one
// control, so it is one widget: the labels are the same four ranges, shaped by
// the same numbering system, and the second copy would be where they drift.
//
// The numbers are formatted HERE and never written into an ARB value: the ARB
// gate refuses a literal digit, and it refuses it for the reason this needs —
// `۱۰–۲۰` is what a Persian reader must see, and a hard-coded "10" renders
// Latin in every locale.
import 'package:flutter/material.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/vehicles/annual_band.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_segmented.dart';

/// The four annual-distance bands, as a labelled segmented control.
class CalmAnnualBandField extends StatelessWidget {
  /// Creates the field.
  const CalmAnnualBandField({
    required this.unit,
    required this.selected,
    required this.onChanged,
    required this.formatsTag,
    super.key,
  });

  /// The unit the ranges are shown in — the vehicle's, or the app's.
  final DistanceUnit unit;

  /// The chosen band, or null for a stored figure that matches none.
  ///
  /// Null draws no selection rather than picking one: §2's import REPLACES
  /// without validating a figure like this, and a control that invents a
  /// selection for a number the app did not write is the app guessing in a way
  /// that looks like fact.
  final AnnualBand? selected;

  /// Reports the band the user picked.
  final ValueChanged<AnnualBand> onChanged;

  /// The formats tag the numbers are shaped by.
  final String formatsTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: space.s2,
      children: [
        CalmFieldLabel(
          unit == DistanceUnit.mi
              ? l10n.annualBandLabelMi
              : l10n.annualBandLabelKm,
        ),
        CalmSegmented(
          labels: [
            for (final band in AnnualBand.values) _label(l10n, band),
          ],
          numeric: true,
          // -1 is "none of them", which `CalmSegmented` draws as no selection.
          index: selected == null ? -1 : AnnualBand.values.indexOf(selected!),
          onChanged: (i) => onChanged(AnnualBand.values[i]),
        ),
      ],
    );
  }

  String _label(AppLocalizations l10n, AnnualBand band) {
    String n(int value) => formatForDisplay(
      value.toDouble(),
      formatsTag,
      numerals: CalmNumerals.auto,
    );

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
