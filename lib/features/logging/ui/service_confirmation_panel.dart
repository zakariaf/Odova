// What a mark-done save replaces the form with, for five seconds.
//
// SPEC.md §10 *The confirmation panel*: "A panel and not a snackbar because
// both the resulting due date and the due odometer have to be visible: the
// consequence of finishing 3,000 km early is what a user needs to see once."
//
// A save from the `+` skips it entirely — nothing was reset, so there is no
// consequence to show.
import 'package:flutter/material.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_button.dart';

/// The panel shown after a mark-done save.
class ServiceConfirmationPanel extends StatelessWidget {
  /// Creates the panel.
  const ServiceConfirmationPanel({
    required this.itemLabel,
    required this.facts,
    required this.onClose,
    super.key,
    this.nextOdometer,
    this.nextDate,
  });

  /// The item that was reset.
  final String itemLabel;

  /// `2 September 2026 · 187,412 km · 92.50 €`, already formatted and joined.
  final String facts;

  /// Where the next one falls on the distance axis, already formatted.
  final String? nextOdometer;

  /// When it falls on the time axis, already formatted — and already FUZZY
  /// ("around September 2027") when the projection is not measured, because §10
  /// forbids an exact date the data cannot support.
  final String? nextDate;

  /// Dismisses the panel early.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: space.s3,
      children: [
        Text(l10n.logDoneTitle(itemLabel), style: type.title),
        Text(facts),
        // BOTH halves when there are two. §10's whole reason for a panel is
        // that seeing one hides the consequence: an item finished early moves
        // its distance half and not its date, and only the pair shows that.
        if (_nextLine(l10n) case final line?) Text(line),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: CalmButton(
            label: l10n.logDoneClose,
            variant: CalmButtonVariant.tonal,
            size: CalmButtonSize.sm,
            onPressed: onClose,
          ),
        ),
      ],
    );
  }

  /// The next-due line, naming whichever axes the item actually has.
  ///
  /// §10: "A distance-only or time-only item names one axis." A date invented
  /// for an item with no month interval would be a fact the app made up, and
  /// this panel is the one place a user reads the consequence as a promise.
  String? _nextLine(AppLocalizations l10n) =>
      switch ((nextOdometer, nextDate)) {
        (final odometer?, final date?) => l10n.logDoneNextBoth(odometer, date),
        (final odometer?, null) => l10n.logDoneNextDistance(odometer),
        (null, final date?) => l10n.logDoneNextDate(date),
        (null, null) => null,
      };
}
