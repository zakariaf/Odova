// One timeline row, for all six of §11's entry types.
//
// §11 draws them through "one row widget for all five types", so the variation
// is in the DATA — `HistoryRow` in `lib/core/history/` decides what each type
// says — and this file decides only how a row looks.
//
// The eye order §11 fixes: "sticky month header, then type icon and date at
// the start edge, then money at the end edge in a FIXED-WIDTH column so
// amounts stack. Consumption, odometer and vendor are secondary weight; it is
// a ledger, not a call to action."
//
// That fixed width is the part a `Row` does not give you for free. Amounts of
// different lengths must share a start edge or the column reads as ragged, so
// the money sits in a sized box rather than being laid out by its own width.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_card.dart';
import 'package:odova/ui/calm/calm_icon_tile.dart';

/// How wide §11's money column is.
///
/// Fixed, so `€74.20` and `€612.00` share a start edge and the digits stack.
/// Sized to the widest amount the app formats at default scale plus its
/// symbol; a column that fitted the CONTENT would jump every time a month with
/// a four-figure service scrolled into view.
///
/// And no wider than that. Every point here is a point the primary line does
/// not have, and the line that loses it wraps — which is what turned a 76pt
/// row into a 140pt one in the first capture.
const double kHistoryAmountColumnWidth = 76;

/// One row on the timeline.
class HistoryRowTile extends StatelessWidget {
  /// Creates a row.
  const HistoryRowTile({
    required this.icon,
    required this.primaryLine,
    required this.secondaryLine,
    required this.amount,
    super.key,
    this.trailingFigure,
    this.onTap,
  });

  /// The type glyph, per §11's table.
  final IconData icon;

  /// The row's first line.
  final String primaryLine;

  /// Its second, in secondary weight.
  final String secondaryLine;

  /// The money, already formatted, or null where the type has none.
  ///
  /// An odometer row has no amount at all — §11's table prints an em dash in
  /// the column — so this is nullable rather than a zero.
  final String? amount;

  /// The consumption figure, or null.
  ///
  /// §11: it "renders only where `buildFuelSegments` returns one … Otherwise
  /// the slot is blank; never `0.0`." `consumptionFor` is what answers that;
  /// this widget only draws what it is handed.
  final String? trailingFigure;

  /// Opens the row in edit mode.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    // A `CalmCard` and not a decorated box. `check_component_hygiene.sh` is
    // right to refuse the latter: "only lib/ui/calm/ builds a decoration", and
    // a feature that paints its own surface is a feature that will not follow
    // the next token change.
    return CalmCard(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsetsDirectional.all(space.s3),
        child: Row(
          spacing: space.s3,
          children: [
            CalmIconTile(icon: icon),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    primaryLine,
                    maxLines: 2,
                    style: type.body.copyWith(color: colors.ink),
                  ),
                  Text(
                    secondaryLine,
                    maxLines: 2,
                    style: type.label.copyWith(color: colors.ink3),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: kHistoryAmountColumnWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (amount case final money?)
                    Text(
                      money,
                      textAlign: TextAlign.end,
                      style: type.body.copyWith(
                        color: colors.ink,
                        fontWeight: type.semi,
                      ),
                    ),
                  if (trailingFigure case final figure?)
                    Text(
                      figure,
                      textAlign: TextAlign.end,
                      style: type.label.copyWith(color: colors.ink3),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
