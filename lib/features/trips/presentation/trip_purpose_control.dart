// SPEC.md §10's purpose control, and the one thing it does that a plain
// segmented control does not.
//
// §10: "`Geschäftlich` / `Arbeitsweg` / `Privat` / `Sonstiges` do not fit four
// abreast in German at large text scales — it wraps to a 2×2 grid rather than
// shrinking its text." Shrinking is the Material default and it is the wrong
// answer here: the user turned the text up because they cannot read it at the
// old size, and a control that responds by making its text smaller has
// answered the opposite of what was asked.
import 'package:flutter/material.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/features/trips/presentation/trip_labels.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_segmented.dart';

/// The text scale at which four German words stop fitting abreast.
///
/// Measured against `Geschäftlich` on the narrowest supported phone, which is
/// the longest of the four in the longest of the six languages.
const double kTripPurposeGridScale = 1.3;

/// The four purposes, in SPEC.md §10's order.
const List<TripPurpose> kTripPurposes = TripPurpose.values;

/// §10's purpose control.
class TripPurposeControl extends StatelessWidget {
  /// Creates the control.
  const TripPurposeControl({
    required this.purpose,
    required this.onChanged,
    super.key,
  });

  /// The chosen purpose.
  final TripPurpose purpose;

  /// Reports the tapped purpose.
  final ValueChanged<TripPurpose> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final labels = [
      for (final p in kTripPurposes) tripPurposeLabel(l10n, p),
    ];
    final index = kTripPurposes.indexOf(purpose);

    // The accessible name. The four options say what the control is to
    // somebody who can see them; a screen reader landing on four unlabelled
    // segments gets no such hint.
    return Semantics(
      label: l10n.tripPurposeLabel,
      container: true,
      child: MediaQuery.textScalerOf(context).scale(1) < kTripPurposeGridScale
          ? CalmSegmented(
              labels: labels,
              index: index,
              onChanged: (i) => onChanged(kTripPurposes[i]),
            )
          : Column(
              children: [
                // An index outside a row's range simply selects nothing in it,
                // which is exactly right: the selection lives in one of the
                // two rows and the other must show none.
                CalmSegmented(
                  labels: labels.sublist(0, 2),
                  index: index,
                  onChanged: (i) => onChanged(kTripPurposes[i]),
                ),
                SizedBox(height: space.s2),
                CalmSegmented(
                  labels: labels.sublist(2),
                  index: index - 2,
                  onChanged: (i) => onChanged(kTripPurposes[i + 2]),
                ),
              ],
            ),
    );
  }
}
