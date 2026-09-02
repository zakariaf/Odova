// Home, assembled end to end from Calm primitives — the layering in one file.
// Conceptual location: lib/features/home/home_screen.dart
//   lib/theme/calm/   CalmSpace / DueState   <- values, read for LAYOUT only
//   lib/ui/calm/      Calm* widgets          <- the only layer that styles
//   lib/features/**   this file              <- composition only
// Deliberately absent: every hex, fontSize, BorderRadius, Duration, Curve,
// Material widget, and every direct read of a status colour. Appearance lives one
// layer down; this file decides only WHAT appears and IN WHAT ORDER. The bare 3
// is the card cap from SPEC.md §9. Widget parameter lists are the documented
// subset owned by `calm-components`.
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/calm/calm_space.dart';
import '../../theme/calm/calm_status.dart'
    show DueConfidence, DueDriver, DueState;
import '../../ui/calm/calm_all_clear.dart';
import '../../ui/calm/calm_button.dart';
import '../../ui/calm/calm_due_card.dart';
import '../../ui/calm/calm_rows.dart';
import '../../ui/calm/calm_scaffold.dart';
import '../../ui/calm/calm_tile.dart';

/// One due item, already formatted. Every string arrives pre-localised and
/// pre-rounded: this file never formats a number, because numerals, the calendar
/// and the `~` prefix are locale decisions owned by `calm-typography-and-rtl`.
@immutable
class DueItemView {
  const DueItemView({
    required this.id,
    required this.title,
    required this.state,
    required this.statusLine,
    required this.driver,
    required this.confidence,
    required this.actionLabel,
    this.anchorLine,
    this.progress,
  });

  final String id;
  final String title;
  final DueState state;

  /// Which axis put the item in this state, and how much the projection engine
  /// actually knows. Both are rendered by the card, so both are view data.
  final DueDriver driver;
  final DueConfidence confidence;

  /// 'Log it', or 'Update odometer' when the reading is what is missing.
  final String actionLabel;

  /// Positive phrasing only — 'Overdue by 1,400 km', never 'in -21 days'.
  final String statusLine;

  /// 'Was due at 186,000 km · 12 August'; primary card only.
  final String? anchorLine;

  /// 0..1+, or null when the item has no computable progress.
  final double? progress;

  /// SPEC.md §9: a stale odometer asks for a reading rather than making an
  /// accusation arithmetic alone cannot support, so the action changes too.
  bool get wantsOdometer => state == DueState.needsOdometer;
}

/// An at-a-glance figure, already formatted, or '—' — never a zero standing in
/// for "no data" (SPEC.md §9).
typedef StatView = ({String value, String label});

@immutable
class HomeView {
  const HomeView({
    required this.vehicleName,
    required this.canSwitchVehicle,
    required this.odometer,
    required this.odometerMeta,
    required this.odometerIsEstimated,
    required this.due,
    required this.trackedItemCount,
    required this.nextUpLine,
    required this.sinceLastServiceLine,
    required this.stats,
    required this.lastFillUpLine,
  });

  final String vehicleName;

  /// The garage is invisible until it is real: no chevron with one vehicle.
  final bool canSwitchVehicle;

  /// '187,412 km' or '~187,400 km' — the tilde is part of the visible string, so
  /// the distinction survives colour and weight being stripped out (SPEC.md §9).
  final String odometer;
  final String odometerMeta;
  final bool odometerIsEstimated;

  /// Sorted by projected due date; `ok` and `paused` items are not in here.
  final List<DueItemView> due;
  final int trackedItemCount;

  /// All-clear copy: 'Next: Inspection, 14 March' and '3,120 km · 4 months'.
  final String nextUpLine;
  final String sinceLastServiceLine;

  final List<StatView> stats;
  final String lastFillUpLine;

  /// The most common state in the app, and the best-looking one.
  bool get isAllClear => due.isEmpty;

  /// Hard cap at three however many are overdue: nine red cards say less than
  /// three plus a number, so the overflow row carries the tone instead.
  List<DueItemView> get visible => due.take(3).toList(growable: false);
  int get overflowCount => due.length - visible.length;

  bool get overflowIsUrgent => due
      .skip(3)
      .any((i) => i.state == DueState.overdue || i.state == DueState.due);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.view,
    required this.onSwitchVehicle,
    required this.onOpenOdometer,
    required this.onOpenItem,
    required this.onActOnItem,
    required this.onSeeAllReminders,
  });

  final HomeView view;
  final VoidCallback onSwitchVehicle;
  final VoidCallback onOpenOdometer;
  final ValueChanged<String> onOpenItem;
  final ValueChanged<String> onActOnItem;
  final VoidCallback onSeeAllReminders;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);
    final l10n = AppLocalizations.of(context);

    return CalmScaffold(
      appBar: CalmAppBar(
        title: view.vehicleName,
        showVehicleChevron: view.canSwitchVehicle,
        onTapVehicle: view.canSwitchVehicle ? onSwitchVehicle : null,
      ),
      // CalmScaffold owns the scroll and the screen padding; a screen that adds
      // its own SingleChildScrollView gets two scrollables and one of them wins
      // at random.
      children: [
        // The odometer is the most valuable thing a user can give the app, so it
        // sits above the cards. The `~` on an estimate is inside the string, so
        // the distinction survives colour and weight being stripped out.
        CalmListRow(
          title: view.odometer,
          subtitle: view.odometerMeta,
          showChevron: true,
          standalone: true,
          onTap: onOpenOdometer,
        ),
        SizedBox(height: space.s5),

        // ONE primary thing. Either the answer is an item, or the answer is
        // "nothing" — and "nothing" is the good state, not an empty state.
        if (view.isAllClear)
          CalmAllClear(
            headline: l10n.homeNothingDue,
            nextLine: view.nextUpLine,
            since: CalmSinceLine(
              label: l10n.homeSinceLastService,
              figure: view.sinceLastServiceLine,
            ),
          )
        else
          _dueStack(context),
        SizedBox(height: space.s5),

        CalmRowGroup(
          rows: [
            CalmListRow(
              title: view.overflowIsUrgent
                  ? l10n.homeSeeAllUrgent(view.overflowCount)
                  : l10n.homeSeeAllReminders(view.trackedItemCount),
              showChevron: true,
              onTap: onSeeAllReminders,
            ),
            CalmListRow(
              title: l10n.homeLastFillUp,
              subtitle: view.lastFillUpLine,
            ),
          ],
        ),
        SizedBox(height: space.s5),
        _statRow(context),
      ],
    );
  }

  /// Three at-a-glance tiles, equal widths: none is the primary thing, so none
  /// of them grows.
  Widget _statRow(BuildContext context) => Row(
        spacing: CalmSpace.of(context).s3,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final stat in view.stats)
            Expanded(child: CalmTile(value: stat.value, label: stat.label)),
        ],
      );

  /// One primary card, then at most two secondaries, --space-4 apart. The gap is
  /// the parent's rhythm, so no card carries a margin of its own.
  Widget _dueStack(BuildContext context) {
    final items = view.visible;

    return Column(
      spacing: CalmSpace.of(context).s4,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, item) in items.indexed)
          CalmDueCard(
            // The first item is the screen's one primary thing; everything after
            // it is secondary, whatever state it is in.
            density: index == 0
                ? CalmDueDensity.primary
                : CalmDueDensity.secondary,
            view: CalmDueView(
              state: item.state,
              driver: item.driver,
              confidence: item.confidence,
              title: item.title,
              statusLine: item.statusLine,
              // The needs-odometer state asks for a reading instead of a job.
              actionLabel: item.actionLabel,
              anchorLine: index == 0 ? item.anchorLine : null,
              progress: item.progress,
            ),
            onTap: () => onOpenItem(item.id),
            onAction: () => onActOnItem(item.id),
          ),
      ],
    );
  }
}
