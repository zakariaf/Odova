// Home — what does my car need next.
//
// SPEC.md §9. The most-opened screen in the app, and the one hard layout rule:
// "the answer is above the fold, always" — on 375 × 667 at default text scale
// the primary card and both secondaries are visible without scrolling. The
// budget is 56 + 64 + 148 + 2 × 72 + 48 = 460, which leaves the first tile row
// under a 56pt tab bar.
//
// A DUMB widget over one provider. Everything it draws was decided in
// `home_view_model.dart` and `home_copy.dart`; this file is composition and
// navigation, and the *deliberately not on Home* table is a checklist it keeps:
// no FAB, no chips, no charts, no banners.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/app/routing/tab_reselected.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/home/application/home_notifier.dart';
import 'package:odova/features/home/application/home_state.dart';
import 'package:odova/features/home/application/reminder_activation.dart';
import 'package:odova/features/home/domain/home_view_model.dart';
import 'package:odova/features/home/ui/card_overflow_sheet.dart';
import 'package:odova/features/home/ui/due_stack.dart';
import 'package:odova/features/home/ui/estimate_popover.dart';
import 'package:odova/features/home/ui/glance_tiles.dart';
import 'package:odova/features/home/ui/home_copy.dart';
import 'package:odova/features/home/ui/last_fillup_row.dart';
import 'package:odova/features/home/ui/odometer_strip.dart';
import 'package:odova/features/home/ui/other_vehicles_row.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_snackbar.dart';

/// Home's index among the four tabs, for the re-tap seam.
const int kHomeTabIndex = 0;

/// The Home tab.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Owned here rather than by `CalmScaffold`, because SPEC.md §7's re-tap has
  // to reach it from outside the frame.
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(homeStateProvider);
    final tag = ref.watch(resolvedLocaleTagsProvider).formats;

    // §7: "a second tap on the active tab pops that tab to its root and scrolls
    // that root to the top." A TICK rather than a bool, so a screen already at
    // offset 0 that gets a second request still sees an event.
    ref.listen(tabReselectedProvider, (_, next) {
      if (next?.index != kHomeTabIndex || !_scroll.hasClients) return;
      unawaited(
        _scroll.animateTo(
          0,
          duration: CalmMotion.of(context).slow,
          curve: CalmMotion.of(context).easeOut,
        ),
      );
    });

    if (state == null) {
      // The first frame before the streams land. NOT a spinner: §9's skeleton
      // appears only past 150 ms (task 10.6), and a spinner that flashes for
      // one frame is worse than a screen that arrives whole.
      //
      // And NOT titled "Home" either. §9's app bar carries the VEHICLE's name,
      // there is no vehicle yet, and borrowing the tab's word would put the
      // same heading on the screen twice — once as a title and once as the tab
      // it was reached from.
      return const CalmScaffold(
        appBar: CalmAppBar(title: ''),
        children: [],
      );
    }

    // The VEHICLE's unit where it has one, then the app's — the same
    // precedence `vehicle_status_line.dart` uses, so a car set to miles reads
    // in miles on every screen that mentions it.
    final space = CalmSpace.of(context);
    final settings = ref.watch(settingsProvider).value;
    final unit =
        state.vehicle.distanceUnit ?? settings?.distanceUnit ?? DistanceUnit.km;
    final consumptionUnit =
        state.vehicle.consumptionUnit ??
        settings?.consumptionUnit ??
        ConsumptionUnit.lPer100km;

    return CalmScaffold(
      controller: _scroll,
      tight: true,
      // The artboard's own overrides, not the stylesheet's defaults:
      // `.screen__body--tight` with `padding-block: var(--space-2)
      // var(--space-3); gap: var(--space-3)`. They are what makes §9's fold
      // guarantee hold — the budget is arithmetic and 4pt of extra gap between
      // four children is 12pt off the bottom card, which is the difference
      // between the second secondary being readable in German and not.
      bodyGap: space.s3,
      bodyPadBlock: (top: space.s2, bottom: space.s3),
      appBar: CalmAppBar(
        // §9: the vehicle's NAME, and a chevron only when there is somewhere to
        // go. "The garage is invisible until it is real."
        title: state.vehicle.name,
        showVehicleChevron: state.showsSwitcher,
        onTapVehicle: state.showsSwitcher ? _openSwitcher : null,
      ),
      children: [
        if (state.estimate case final estimate?)
          OdometerStrip(
            estimate: estimate,
            unit: unit,
            formatsTag: tag,
            onTap: () => unawaited(context.push(Routes.log(LogType.odometer))),
            onTapValue: () => unawaited(
              showEstimatePopover(
                context,
                body: EstimatePopover(
                  message: l10n.homeEstimateExpired,
                  action: EstimatePopoverAction(
                    label: l10n.actionUpdateOdometer,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
        DueStack(
          stack: state.stack,
          unit: unit,
          formatsTag: tag,
          onOpenItem: _openItem,
          onAct: (card) => _act(card, state),
          onMore: (card) => _more(card, state),
          onSeeAll: () => unawaited(context.push(Routes.reminders)),
        ),
        GlanceTiles(
          // Null until EPIC-13 composes the fuel segments — see `HomeState`.
          // The row is still drawn: §9's layout budget reserves it, and the
          // `—` is a designed state rather than a gap.
          consumption: state.consumption,
          consumptionUnit: consumptionUnit,
          distanceUnitLabel: distanceUnitLabel(l10n, unit),
          formatsTag: tag,
        ),
        if (state.lastFillUp case final fillUp?)
          LastFillUpRow(fillUp: fillUp, formatsTag: tag),
        if (state.otherVehicleNeedingAttention case final other?)
          OtherVehiclesRow(
            name: other.vehicle.name,
            count: other.count,
            overdue: other.overdue,
            formatsTag: tag,
            onTap: _openSwitcher,
          ),
      ],
    );
  }

  void _openSwitcher() => unawaited(context.push(Routes.vehicleSwitcher));

  void _openItem(DueCardModel card) =>
      unawaited(context.push(Routes.reminderEdit(card.item.id.toString())));

  /// The card's own button: **Log it**, or **Update odometer**.
  ///
  /// The prefill is §9's, exactly: "this item, today, last known odometer". It
  /// travels in the QUERY rather than in `extra` — see `Routes.log` — so the
  /// same push works from a notification on a cold start.
  void _act(DueCardModel card, HomeState state) {
    // Through `homeActionKey`, not through a `DueState` comparison. It is the
    // same function that chose the button's WORD, so "Update odometer" and
    // "goes to log.odometer" cannot disagree — and the two uncertain cases §9
    // names are `needs_odometer` AND a distance-driven `due_soon` at
    // `confidence = default`, which an equality test on the state misses.
    if (homeActionKey(card.assessment) == HomeAction.updateOdometer) {
      unawaited(context.push(Routes.log(LogType.odometer)));
      return;
    }
    unawaited(
      context.push(
        Routes.log(
          LogType.service,
          itemId: card.item.id.toString(),
          on: CivilDate.fromDateTime(ref.read(clockProvider).now())?.toString(),
          odometerMetres: state.estimate?.metres,
        ),
      ),
    );
  }

  Future<void> _more(DueCardModel card, HomeState state) async {
    final chosen = await showCardOverflowSheet(context, title: card.item.label);
    if (!mounted || chosen == null) return;

    switch (chosen) {
      case CardOverflowAction.logIt:
        _act(card, state);
      case CardOverflowAction.snooze:
        // `dialog.snooze` is EPIC-08's global dialog and is not wired until
        // task 10.7, which is where the snooze WRITE lives. Naming the case
        // here rather than leaving a default is what makes that a compile-time
        // list of four rather than three plus a silence.
        break;
      case CardOverflowAction.edit:
        _openItem(card);
      case CardOverflowAction.turnOff:
        await _turnOff(card);
    }
  }

  /// §9: `is_active = false`, and a snackbar with **Undo**.
  ///
  /// The host and the notifier are captured BEFORE the await. Turning the item
  /// off removes its card from the stack, which unmounts the element this
  /// callback was invoked from — so `context.mounted` is false by the time the
  /// write returns and every line after it, including the Undo the user needs,
  /// would be skipped. That is the exact bug EPIC-09 found in the vehicle
  /// delete flow.
  Future<void> _turnOff(DueCardModel card) async {
    final l10n = AppLocalizations.of(context);
    final snackbars = CalmSnackbarHost.of(context);
    final activation = ref.read(reminderActivationProvider.notifier);

    final result = await activation.setActive(card.item, active: false);
    if (result is! Ok) {
      // The failure reaches the user. A swallowed one leaves the reminder
      // looking off until the next rebuild puts it back with no explanation.
      snackbars.show(message: l10n.saveDiskFullError, danger: true);
      return;
    }

    snackbars.show(
      message: l10n.homeTurnedOff(card.item.label ?? ''),
      actionLabel: l10n.commonUndo,
      onAction: () => unawaited(
        activation.undo(card.item.id, wasActive: true),
      ),
    );
  }
}
