// The two empty states §11 distinguishes, and why they are two.
//
// **"Nothing logged yet"** is a new vehicle. It offers the one action that
// starts a history — a fill-up, because §10 says that is what a driver does
// 2–6 times a month against everything else once or twice a year.
//
// **"No entries match these filters"** is a full history behind a narrow
// filter, and it is a different sentence because the remedy is different:
// there is nothing to log, there is something to widen. §11's rule is that the
// chip row STAYS visible and interactive here — a screen that hid its own
// controls behind its empty state would strand the user in a filter they can
// neither see nor undo.
//
// Neither carries an illustration. §11 is explicit, and the reason is the same
// one that keeps the app quiet elsewhere: a drawing celebrating an empty list
// is the app being pleased about a car nobody has logged.
import 'package:flutter/material.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_button.dart';

/// A vehicle with nothing logged.
class HistoryEmptyState extends StatelessWidget {
  /// Creates the state.
  const HistoryEmptyState({required this.onLogFillUp, super.key});

  /// Opens `log.fillup`.
  final VoidCallback onLogFillUp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: space.s7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: space.s4,
        children: [
          Text(
            l10n.historyEmptyTitle,
            textAlign: TextAlign.center,
            style: type.body.copyWith(color: colors.ink),
          ),
          // What STARTS the record, rather than an apology for it being
          // empty. §11 gives this state two lines and one button.
          Text(
            l10n.historyEmptySubtitle,
            textAlign: TextAlign.center,
            style: type.label.copyWith(color: colors.ink3),
          ),
          CalmButton(label: l10n.historyEmptyAction, onPressed: onLogFillUp),
        ],
      ),
    );
  }
}

/// A history that exists, behind a filter that matches none of it.
class HistoryFilteredEmptyState extends StatelessWidget {
  /// Creates the state.
  const HistoryFilteredEmptyState({required this.onClearFilters, super.key});

  /// Drops every filter and reloads.
  ///
  /// §11 puts a **Clear filters** button here BESIDE a chip row that stays
  /// interactive. Both, not either: the chips are how the user narrows and the
  /// button is the one tap out, and a screen with only the chips makes undoing
  /// four selections four taps.
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: space.s7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: space.s3,
        children: [
          Text(
            l10n.historyFilteredEmpty,
            textAlign: TextAlign.center,
            style: type.body.copyWith(color: colors.ink3),
          ),
          CalmButton(
            label: l10n.historyClearFilters,
            variant: CalmButtonVariant.quiet,
            onPressed: onClearFilters,
          ),
        ],
      ),
    );
  }
}

/// §11's store-read failure: the whole screen, and one useful act.
///
/// "Odova couldn't open your records." One button, **Go to Backup & restore**,
/// with Export enabled — §11 in four words: "Get the data out of the building
/// first." No retry, no error code, no diagnostics: the user's next decision
/// is about eight years of their own records, not about our bug.
class HistoryReadFailureState extends StatelessWidget {
  /// Creates the state.
  const HistoryReadFailureState({required this.onGoToBackup, super.key});

  /// Opens `settings.backup`.
  final VoidCallback onGoToBackup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: space.s7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: space.s4,
        children: [
          Text(
            l10n.historyReadFailureTitle,
            textAlign: TextAlign.center,
            style: type.body.copyWith(color: colors.ink),
          ),
          CalmButton(
            label: l10n.historyReadFailureAction,
            onPressed: onGoToBackup,
          ),
        ],
      ),
    );
  }
}
