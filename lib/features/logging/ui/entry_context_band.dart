// The read-only band above a form in edit mode.
//
// SPEC.md §11: "a context band pinned above the fields carrying what the form
// cannot: the derived numbers this record participates in, and what it is
// attached to." Read-only and muted — it is context, not a control.
//
// It FORMATS and never decides. Which sentence a fill-up gets, whether an
// expense has a monthly share, whether two readings imply a rate at all: all
// of that is `lib/core/history/entry_band.dart`, so a band that says the wrong
// thing fails in a pure test rather than in a screenshot.
import 'package:flutter/material.dart';
import 'package:odova/core/history/entry_band.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';

/// The lines a band draws, already formatted by the caller.
///
/// A list of STRINGS and not a model, because the widget's whole job is to
/// stack them at one weight — everything that decides what they say lives in
/// the core, and everything that turns numbers into text lives with the
/// formatters that know the locale.
class EntryContextBand extends StatelessWidget {
  /// Creates the band.
  const EntryContextBand({required this.lines, super.key});

  /// The lines, in the order §11 draws them.
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: space.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in lines)
            Text(line, style: type.label.copyWith(color: colors.ink3)),
        ],
      ),
    );
  }
}

/// §11's sentence for a fill-up with no figure.
///
/// Mapped from the core's decision rather than re-derived: the widget layer
/// choosing between three sentences would be the second place that rule lives.
String fillUpNoFigureSentence(FillUpNoFigure reason, AppLocalizations l10n) =>
    switch (reason) {
      FillUpNoFigure.firstFill => l10n.bandFillUpFirstFill,
      FillUpNoFigure.chainBroken => l10n.bandFillUpChainBroken,
      FillUpNoFigure.partialFill => l10n.bandFillUpPartial,
    };
