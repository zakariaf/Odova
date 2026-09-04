// "Snooze oil and filter" — quieting a reminder without pretending the job is
// done.
//
// SPEC.md §4.7.2. The body is the reference's own sentence and it is the whole
// point of the dialog: snoozing changes the NOTIFICATION SCHEDULE and nothing
// else. This is §1's "never guess in a way that looks like fact" applied to a
// decision — a user who quiets a reminder and then believes the job is no
// longer due has been misled by the app's silence.
//
// A global dialog (§7). EPIC-10 says it is owned by the notifications epic; it
// is not, it is owned here and CALLED from Home's card overflow and from a
// `reminders.list` swipe (EPIC-08 finding F-8.1).

import 'package:flutter/material.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_dialog.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';

/// How long to stay quiet.
enum SnoozeChoice {
  /// Three days.
  threeDays,

  /// One week.
  oneWeek,

  /// One calendar month, clamped to the last day of the target month.
  oneMonth,

  /// Another 500 km, from the reading the caller supplies.
  fiveHundredKilometres,
}

/// The distance the fourth option adds.
///
/// SPEC.md §4.7.2 and §7 both write it as "another **500 km**", with no mile
/// equivalent — and §4.8's rule that defaults are defined per unit system
/// rather than converted would give a miles user a round number instead. That
/// is unsettled (EPIC-08 finding F-8.9); inventing "300 mi" here is exactly the
/// kind of unsourced value SPEC.md forbids, so it is 500 km until the spec says
/// otherwise.
const kSnoozeDistanceMetres = 500000;

/// Asks how long to quiet [itemLabel]'s reminder.
///
/// [today] comes from the injected `Clock` — SPEC.md §3's due engine is a pure
/// function of the date, and a dialog that read `DateTime.now()` would be the
/// one place in the app that could not be tested at a chosen date.
///
/// The distance row is ABSENT, not disabled, when the item has no distance
/// interval: §7 states the condition, and a disabled row is an offer the user
/// has to work out they cannot take.
///
/// **It writes nothing.** EPIC-16 applies the choice — `snoozed_until`, the
/// distance-to-date conversion through the projection, the three-consecutive
/// limit and the fourth-offer escalation of §4.7.2 are all its.
Future<SnoozeChoice?> showSnoozeDialog(
  BuildContext context, {
  required String itemLabel,
  required CivilDate today,
  required bool hasDistanceInterval,
  required String Function(CivilDate) formatDate,
  required String Function(int metres) formatDistance,
  int? currentOdometerMetres,
}) {
  return CalmDialog.show<SnoozeChoice>(
    context,
    builder: (context) => SnoozeDialogBody(
      itemLabel: itemLabel,
      today: today,
      hasDistanceInterval: hasDistanceInterval,
      formatDate: formatDate,
      formatDistance: formatDistance,
      currentOdometerMetres: currentOdometerMetres,
      onChoice: (choice) => Navigator.of(context).pop(choice),
    ),
  );
}

/// The dialog itself, without the route.
///
/// Public so `test/parity/` can capture the SHIPPED widget rather than a
/// hand-built copy of it — a gate that photographs the test's own composition
/// stays green while the real dialog reorders its actions.
class SnoozeDialogBody extends StatelessWidget {
  /// Creates the body.
  const SnoozeDialogBody({
    required this.itemLabel,
    required this.today,
    required this.hasDistanceInterval,
    required this.formatDate,
    required this.formatDistance,
    required this.onChoice,
    super.key,
    this.currentOdometerMetres,
  });

  /// The item being quieted.
  final String itemLabel;

  /// The date to reckon from.
  final CivilDate today;

  /// Whether the item has a distance interval at all.
  final bool hasDistanceInterval;

  /// Formats a date in the active calendar and numerals.
  final String Function(CivilDate) formatDate;

  /// Formats a distance in the user's unit.
  final String Function(int metres) formatDistance;

  /// The last entered reading, or null.
  final int? currentOdometerMetres;

  /// Reports the decision, or null for Cancel. `showSnoozeDialog` pops with it.
  final ValueChanged<SnoozeChoice?> onChoice;

  /// Whether the distance row can be offered at all.
  ///
  /// It needs a reading as well as an interval: the target is "the entered
  /// reading plus 500 km", and with no reading there is nothing to add to.
  /// A projection would move every time the estimate did, which is a snooze
  /// target that quietly changes date.
  bool get _showsDistance =>
      hasDistanceInterval && currentOdometerMetres != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CalmDialog.actions(
      icon: Icons.notifications_paused_outlined,
      // The label AS STORED. The reference lower-cases it inside the sentence
      // and an ICU message cannot case-fold a placeholder — German capitalises
      // every noun, so folding here would be wrong in a second locale to fix
      // the look in one (EPIC-08 finding F-8.6).
      title: l10n.snoozeTitle(itemLabel),
      body: l10n.snoozeBody,
      actions: [
        CalmRowGroup(
          flat: true,
          rows: [
            _option(
              context,
              SnoozeChoice.threeDays,
              l10n.snoozeThreeDays('3'),
              l10n.snoozeUntil(formatDate(today.addDays(3))),
            ),
            _option(
              context,
              SnoozeChoice.oneWeek,
              l10n.snoozeOneWeek('1'),
              l10n.snoozeUntil(formatDate(today.addDays(7))),
            ),
            _option(
              context,
              SnoozeChoice.oneMonth,
              l10n.snoozeOneMonth('1'),
              // `addMonths`, which clamps to the last day of the target month:
              // 31 January plus one month is 28 February, not 3 March.
              l10n.snoozeUntil(formatDate(today.addMonths(1))),
            ),
            if (_showsDistance)
              _option(
                context,
                SnoozeChoice.fiveHundredKilometres,
                l10n.snoozeDistance(formatDistance(kSnoozeDistanceMetres)),
                l10n.snoozeAtOdometer(
                  formatDistance(
                    currentOdometerMetres! + kSnoozeDistanceMetres,
                  ),
                ),
              ),
          ],
        ),
        CalmButton(
          label: l10n.commonCancel,
          onPressed: () => onChoice(null),
          variant: CalmButtonVariant.quiet,
          block: true,
        ),
      ],
    );
  }

  Widget _option(
    BuildContext context,
    SnoozeChoice choice,
    String title,
    String value,
  ) => CalmListRow(
    title: title,
    value: value,
    size: CalmRowSize.compact,
    onTap: () => onChoice(choice),
  );
}
