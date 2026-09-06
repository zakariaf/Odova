// One visit to a pump or a charger.
//
// SPEC.md §10 `log.fillup`. The design target is the whole section's opening
// sentence — "a fill-up logged one-handed at a pump, in the rain: four taps and
// two numbers, under fifteen seconds" — which is why the odometer, the
// full/part control and the price trio are above the fold and everything else
// is behind More.
import 'package:flutter/material.dart';
import 'package:odova/features/logging/domain/price_trio.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_segmented.dart';

/// The fill-up segment's body.
class LogFillUpBody extends StatelessWidget {
  /// Creates the body.
  const LogFillUpBody({
    required this.odometer,
    required this.navRows,
    required this.trio,
    required this.quantityUnit,
    required this.isFullTank,
    required this.controllers,
    required this.onTrioChanged,
    required this.onFullTankChanged,
    super.key,
    this.isFirstEver = false,
    this.trioError,
    this.priceError,
    this.totalError,
    this.overTankWarning,
  });

  /// §10's shared odometer field, built by the shell.
  ///
  /// A SLOT and not a construction: the same widget appears on three forms and
  /// the shell owns the reading history it needs, so a body that built its own
  /// would be a second opinion about the field that feeds the due engine.
  final Widget odometer;

  /// §10's Date row, and the More row under it where there is one.
  ///
  /// ONE widget and not two slots: the artboard draws them as a single card
  /// with a divider, and the shell builds it so the four bodies cannot
  /// disagree about the grouping.
  final Widget navRows;

  /// The three fields and which one the app is writing.
  final PriceTrio trio;

  /// `L`, `kg` or `kWh`, by fuel kind — already localised.
  final String quantityUnit;

  /// §10's two-option control, defaulting to *Filled it up*.
  final bool isFullTank;

  /// One controller per trio field, owned by the screen.
  final Map<TrioField, TextEditingController> controllers;

  /// Called when one of the three is edited.
  final void Function(TrioField, String) onTrioChanged;

  /// Called when the full/part control moves.
  final ValueChanged<bool> onFullTankChanged;

  /// Whether this is the vehicle's first fill-up.
  final bool isFirstEver;

  /// The trio's one message, when fewer than two carry a value.
  final String? trioError;

  /// The message under Price per unit, or null.
  final String? priceError;

  /// The message under Total, or null.
  final String? totalError;

  /// The amber over-capacity line, or null. Never a refusal — §10 saves it.
  final String? overTankWarning;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: space.s4,
      children: [
        // §10: "One line above the form. No empty chart, no zero, no
        // placeholder." A first fill-up cannot produce a consumption figure and
        // saying so is better than drawing an empty one.
        if (isFirstEver) Text(l10n.logFillUpFirstEver),
        // FIRST, per §10's sketch and the artboard: the odometer is what the
        // due engine reads, and it is the field a user at a pump reaches for
        // before the receipt is out of their hand.
        odometer,
        CalmSegmented(
          labels: [l10n.logFillUpFullTank, l10n.logFillUpPartFill],
          index: isFullTank ? 0 : 1,
          onChanged: (index) => onFullTankChanged(index == 0),
        ),
        // §10 explains the consequence rather than leaving it to be discovered:
        // a part fill produces no figure on its own.
        if (!isFullTank) Text(l10n.logFillUpPartFillHint),
        // ONE ROW of three, which is what §10's sketch draws and what the
        // artboard renders:
        //
        //     Fuel                Price/L   Total
        //     [ 42.61 ] L      [ 1.799 ] € [ 76.66 ] €
        //
        // The first version stacked them full-width and it read as three
        // unrelated money fields. They are one arithmetic — two entered, one
        // computed — and the row is what says so: the `ƒ` badge only makes
        // sense beside the other two it was worked out from.
        //
        // A `Row` and not a `Wrap`: §10's RTL note puts the money row as "a
        // `start → end` sequence that mirrors as a whole", and a Row in a
        // directional context does that for free.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: space.s2,
          children: [
            Expanded(
              child: _TrioField(
                field: TrioField.quantity,
                label: l10n.logFillUpQuantityLabel,
                affix: quantityUnit,
                trio: trio,
                controllers: controllers,
                onChanged: onTrioChanged,
              ),
            ),
            Expanded(
              child: _TrioField(
                field: TrioField.pricePerUnit,
                label: l10n.logFillUpPricePerUnitLabel(quantityUnit),
                trio: trio,
                controllers: controllers,
                onChanged: onTrioChanged,
              ),
            ),
            Expanded(
              child: _TrioField(
                field: TrioField.total,
                label: l10n.logFillUpTotalLabel,
                trio: trio,
                controllers: controllers,
                onChanged: onTrioChanged,
              ),
            ),
          ],
        ),
        // The messages go UNDER the row, full width, rather than inside a
        // third-width field. §10's trio sentence — "Enter how much fuel you put
        // in, and either the price per litre or the total" — does not fit in
        // 110pt, and a message that truncates is a message that does not exist.
        if (trioError case final error?) Text(error),
        if (priceError case final error?) Text(error),
        if (totalError case final error?) Text(error),
        // §10 puts the over-capacity line here, under the quantity it is about,
        // in amber and never as a refusal.
        if (overTankWarning case final warning?) Text(warning),
        navRows,
      ],
    );
  }
}

/// One of the three, marked `ƒ` when the app is the one writing it.
class _TrioField extends StatelessWidget {
  const _TrioField({
    required this.field,
    required this.label,
    required this.trio,
    required this.controllers,
    required this.onChanged,
    this.affix,
  });

  final TrioField field;
  final String label;
  final PriceTrio trio;
  final Map<TrioField, TextEditingController> controllers;
  final void Function(TrioField, String) onChanged;
  final String? affix;

  @override
  Widget build(BuildContext context) => CalmField(
    label: label,
    controller: controllers[field]!,
    numeric: true,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    affix: affix == null ? null : Text(affix!),
    // §10: "The computed field looks computed: lighter text plus a `ƒ` badge
    // whose accessible name is 'calculated from the other two'." `CalmField`
    // draws both from this one flag.
    computed: trio.computedField == field,
    onChanged: (text) => onChanged(field, text),
  );
}
