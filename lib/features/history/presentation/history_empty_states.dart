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
            style: type.body.copyWith(color: colors.ink2),
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
  const HistoryFilteredEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: space.s7),
      child: Text(
        l10n.historyFilteredEmpty,
        textAlign: TextAlign.center,
        style: type.body.copyWith(color: colors.ink3),
      ),
    );
  }
}
