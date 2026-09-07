// SPEC.md §12: "Tapping any estimated value opens a one-sentence explanation
// and one action: **Update odometer**."
//
// One sentence, and the right one. §12 gives three different sentences for
// three different reasons, and `CostReason` carries a fourth the table does
// not list. Showing the wrong one is worse than showing none: "not enough
// distance logged" to somebody whose problem is that the month has not ended
// sends them out to drive.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/costs/cost_aggregates.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_sheet.dart';

/// The one sentence for [reason].
///
/// An exhaustive switch with no `default`: a fifth reason added to the engine
/// should stop the build here rather than open an empty sheet.
String estimateSentence(
  AppLocalizations l10n,
  String formatsTag,
  CostReason reason, {
  int boundaryGapDays = 0,
}) => switch (reason) {
  CostReason.boundaryReadingStale => l10n.costsEstimateStaleBoundary(
    formatForDisplay(
      boundaryGapDays,
      formatsTag,
      numerals: CalmNumerals.auto,
      decimalDigits: 0,
      grouped: false,
    ),
  ),
  CostReason.notEnoughDistance => l10n.costsEstimateNotEnoughDistance,
  CostReason.noCompletedMonth => l10n.costsEstimateNoCompletedMonth,
  CostReason.noReadings => l10n.costsEstimateNoReadings,
};

/// Whether the sheet offers its action for [reason].
///
/// Everything except `noCompletedMonth`. Updating the odometer does not make
/// the month end sooner, and §12 says so by giving that one case no action —
/// an action that cannot help is worse than none, because the user takes it.
bool estimateOffersAction(CostReason reason) =>
    reason != CostReason.noCompletedMonth;

/// Opens §12's explanation for [reason].
Future<void> showEstimateExplainSheet(
  BuildContext context, {
  required String formatsTag,
  required CostReason reason,
  int boundaryGapDays = 0,
}) => CalmSheet.show<void>(
  context,
  builder: (sheetContext) {
    final l10n = AppLocalizations.of(sheetContext);
    return CalmSheet(
      title: l10n.costsEstimateTitle,
      subtitle: estimateSentence(
        l10n,
        formatsTag,
        reason,
        boundaryGapDays: boundaryGapDays,
      ),
      actions: [
        if (estimateOffersAction(reason))
          CalmButton(
            label: l10n.costsUpdateOdometer,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              unawaited(
                context.push(Routes.log(LogType.odometer)),
              );
            },
          ),
      ],
      children: const [],
    );
  },
);
