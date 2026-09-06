// §11's snackbar, derived from what actually changed.
//
// "The snackbar names the consequence. One line, one Undo, no dialog."
//
//   | Fill-up odometer changed | "Fill-up updated · 14 later fuel figures
//   |                          |  recalculated"
//   | Expense edited           | "Expense updated"
//   | Nothing derived changed  | "Saved"
//
// The rule that makes it worth having: §11's own wording is that "the message
// is derived from what actually changed, never from what was edited." A
// message built from the FORM would announce fourteen recalculated figures for
// an edit that fixed a vendor's spelling — and a user who reads that once
// stops believing the next one.
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/recompute/vehicle_recompute.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';

/// The snackbar line for [diff] after editing a [type] row.
String recomputeMessage({
  required LogType type,
  required RecomputeDiff diff,
  required AppLocalizations l10n,
  required String formatsTag,
}) {
  // §11's last row. Not "Fill-up updated" with nothing after it: an edit that
  // moved no derived number is the same event whatever form it came from, and
  // saying so in one word is what stops the message being a claim.
  if (diff.changedNothing) return l10n.recomputeSaved;

  final head = switch (type) {
    LogType.fillUp => l10n.recomputeFillUpUpdated,
    LogType.service => l10n.recomputeServiceUpdated,
    LogType.expense => l10n.recomputeExpenseUpdated,
    LogType.odometer => l10n.recomputeOdometerUpdated,
  };

  if (diff.changedConsumptionCount == 0) return head;

  final count = l10n.recomputeFiguresRecalculated(
    diff.changedConsumptionCount,
    formatForDisplay(
      diff.changedConsumptionCount,
      formatsTag,
      numerals: CalmNumerals.auto,
      decimalDigits: 0,
    ),
  );
  // The middot §11 uses, with spaces, so the two halves stay two facts rather
  // than reading as one run-on sentence.
  return '$head · $count';
}
