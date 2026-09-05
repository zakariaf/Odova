// The 56pt read-out under the tiles.
//
// SPEC.md §9's *Interactions* table gives it one behaviour: "Last fill-up row —
// Nothing (read-out)". So it takes no `onTap` and draws no chevron: a row that
// looks tappable and is not is worse than one that is neither, and this is the
// screen where every other row goes somewhere.
//
// The reference artboard puts the money on the END and the date and volume
// under the title, which is why this is a `CalmListRow` with a `detail` and a
// `value` rather than one long sentence.
import 'package:flutter/material.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/money_format.dart';
import 'package:odova/l10n/unit_format.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_list_row.dart';

/// The most recent fill-up, as a read-out.
class LastFillUpRow extends StatelessWidget {
  /// Creates the row.
  const LastFillUpRow({
    required this.fillUp,
    required this.formatsTag,
    super.key,
  });

  /// The fill-up to show.
  final FillUp fillUp;

  /// The tag numbers, dates and money are shaped by.
  final String formatsTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);

    return CalmListRow(
      title: l10n.homeLastFillUp,
      detail: l10n.homeLastFillUpDetail(
        formatLongDate(fillUp.occurredOn, formatsTag),
        _quantity(l10n) ?? '',
      ),
      value: formatMoney(
        fillUp.totalCost,
        formatsTag,
        numerals: CalmNumerals.auto,
      ),
      lead: Icon(
        Icons.local_gas_station_outlined,
        size: space.iconMd,
        color: colors.ink3,
      ),
      size: CalmRowSize.compact,
      standalone: true,
    );
  }

  /// How much went in, in whichever form this fuel is sold by.
  ///
  /// Null when the fill-up carries no quantity — a partial entry the user never
  /// finished. §1 forbids inventing one, and an empty half of the line is
  /// better than a plausible litre figure nobody typed.
  String? _quantity(AppLocalizations l10n) => switch (fillUp.quantity) {
    LiquidVolume(:final volume) => formatWithUnit(
      volume.litres,
      l10n.unitVolumeLitre,
      formatsTag,
      numerals: CalmNumerals.auto,
      decimalDigits: 2,
    ),
    ElectricEnergy(:final energy) => formatWithUnit(
      energy.kwh,
      l10n.unitEnergyKwh,
      formatsTag,
      numerals: CalmNumerals.auto,
      decimalDigits: 2,
    ),
    GasMass(:final mass) => formatWithUnit(
      mass.kg,
      l10n.unitMassKg,
      formatsTag,
      numerals: CalmNumerals.auto,
      decimalDigits: 2,
    ),
    null => null,
  };
}
