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
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/data/ui_state/ui_state_provider.dart';
import 'package:odova/data/ui_state/ui_state_store.dart';
import 'package:odova/features/home/application/home_notifier.dart';
import 'package:odova/features/home/application/home_state.dart';
import 'package:odova/features/home/application/reminder_activation.dart';
import 'package:odova/features/home/application/strip_odometer_save.dart';
import 'package:odova/features/home/domain/home_strips.dart';
import 'package:odova/features/home/domain/home_view_model.dart';
import 'package:odova/features/home/ui/card_overflow_sheet.dart';
import 'package:odova/features/home/ui/due_stack.dart';
import 'package:odova/features/home/ui/estimate_popover.dart';
import 'package:odova/features/home/ui/glance_tiles.dart';
import 'package:odova/features/home/ui/home_states.dart';
import 'package:odova/features/home/ui/home_strips.dart';
import 'package:odova/features/home/ui/last_fillup_row.dart';
import 'package:odova/features/home/ui/odometer_strip.dart';
import 'package:odova/features/home/ui/other_vehicles_row.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/due_copy.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/unit_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_all_clear.dart';
import 'package:odova/ui/calm/calm_popover.dart';
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
        // §9: "A skeleton appears only past 150 ms, to avoid a flash on the
        // common path." A warm database answers in single-digit milliseconds,
        // and a silhouette that flashes for one frame reads as a stutter.
        children: [DelayedSkeleton(child: HomeSkeleton())],
      );
    }

    // The VEHICLE's unit where it has one, then the app's — the same
    // precedence `vehicle_status_line.dart` uses, so a car set to miles reads
    // in miles on every screen that mentions it.
    final space = CalmSpace.of(context);
    final settings = ref.watch(settingsProvider).value;
    final unit = effectiveDistanceUnit(state.vehicle, settings);
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
        // §9's *Error*, and it replaces everything: "Home renders no cards and
        // one full-width message." Not a banner over the stack — a store that
        // cannot be read has no stack to put one over.
        if (state.storeUnreadable)
          HomeErrorPanel(
            onOpenBackup: () => unawaited(context.push(Routes.settingsBackup)),
          )
        else ...[
          // ABOVE the odometer strip and above the cards, capped at two by
          // `homeStripQueue`. §9: "A conditional strip pushes the tiles
          // below the fold, never the cards."
          // The screen's OWN context, not a Builder's. `CalmSnackbarHost.of`
          // reads `CalmChromeScope` for the bottom inset, and F-10.2 was that
          // no scaffold on a tab root published one — a snackbar from here
          // believed there was no tab bar, floated 108pt too low, and had its
          // Undo swallowed by the `+`. That was fixed in `AppShell`, which
          // publishes the scope ABOVE every branch, so every context in a tab
          // root resolves it and the ritual of reaching for one lower down is
          // over. `home_screen_test` asserts the inset clears the bar.
          for (final strip in state.strips)
            _strip(context, strip, state, unit, tag),
          if (state.estimate case final estimate?)
            OdometerStrip(
              estimate: estimate,
              unit: unit,
              formatsTag: tag,
              onTap: () =>
                  unawaited(context.push(Routes.log(LogType.odometer))),
              onTapValue: () => unawaited(
                showEstimatePopover(
                  context,
                  body: CalmPopover(
                    message: l10n.homeEstimateExpired,
                    action: (
                      label: l10n.actionUpdateOdometer,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ),
          // §9: a sold or archived vehicle's due stack "is replaced
          // entirely", and it earns no reminders, no notifications and no
          // nudges. The tiles and the history below stay: what the car cost
          // is still true.
          if (state.vehicle.status != VehicleStatus.active)
            SoldVehiclePanel(
              soldOn: formatLongDate(state.vehicle.soldOn ?? '', tag),
              // Both halves come from records the user entered. §1 forbids
              // inventing either, so a vehicle bought before the app existed
              // shows the sale date alone — which is the common case and not
              // worth a guess.
              owned: _ownedFor(l10n, tag, state.vehicle),
              driven: _drivenBy(l10n, tag, state, unit),
            )
          // §9's unknown-anchor card. It takes the PRIMARY slot when there
          // is nothing else, and sits at the foot of the stack when there is
          // — `buildHomeStack` decided which, and this only draws it.
          else if (state.stack.unknown case final unknown?) ...[
            if (state.stack.cards.isNotEmpty) _dueStack(state, unit, tag),
            UnknownAnchorPanel(
              card: unknown,
              firstRun: state.stack.cards.isEmpty && state.lastFillUp == null,
              onOpenList: () => unawaited(context.push(Routes.reminders)),
              onOpenItem: (index) => unawaited(
                context.push(
                  Routes.reminderEdit(unknown.items[index].id.toString()),
                ),
              ),
            ),
          ] else if (state.allClear case final allClear?) ...[
            HomeAllClearPanel(
              nextLine: _nextLine(l10n, tag, allClear),
              fuzzLine: _fuzzLine(l10n, tag, allClear),
              since: _sinceLine(l10n, tag, allClear, unit),
            ),
            // The row SURVIVES the all-clear. §9's zone table: "Present
            // whenever the vehicle has >= 1 tracked item", and its *Nothing
            // due* drawing shows it under the card. The all-clear replaces the
            // cards, not the way into the list.
            _dueStack(state, unit, tag, showCards: false),
          ] else
            _dueStack(state, unit, tag),
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
      ],
    );
  }

  /// The due stack.
  Widget _dueStack(
    HomeState state,
    DistanceUnit unit,
    String tag, {
    bool showCards = true,
  }) => DueStack(
    stack: state.stack,
    showCards: showCards,
    unit: unit,
    formatsTag: tag,
    onOpenItem: _openItem,
    onAct: (card) => _act(card, state),
    onMore: (card) => _more(context, card, state),
    onSeeAll: () => unawaited(context.push(Routes.reminders)),
  );

  /// `Next: Inspection, 14 March` — the exact date, off the TIME axis.
  ///
  /// Null when nothing is tracked. §9 gives the all-clear four things and this
  /// is one of them; a card with three is still the right card, and one with a
  /// made-up fourth is not.
  String? _nextLine(AppLocalizations l10n, String tag, HomeAllClear allClear) {
    final next = allClear.next;
    final on = next?.$2.projectedDueDate;
    if (next == null || on == null) return null;
    return l10n.homeNextIs(
      next.$1.label ?? l10n.vehicleStatusItemGeneric,
      formatLongDate(on.toString(), tag),
    );
  }

  /// `in about 5 months` — the estimate, on its own line so it can never read
  /// as a fact.
  String? _fuzzLine(AppLocalizations l10n, String tag, HomeAllClear allClear) {
    final next = allClear.next;
    if (next == null) return null;
    final days = next.$2.remainingDays;
    if (days == null) return null;
    return homeRelativeLine(l10n, tag, days);
  }

  /// The receipt: `Since the last oil change: 3,120 km · 4 months`.
  ///
  /// Both halves or nothing. §9 calls it evidence, and evidence with a hole in
  /// it is an assertion again.
  CalmSinceLine? _sinceLine(
    AppLocalizations l10n,
    String tag,
    HomeAllClear allClear,
    DistanceUnit unit,
  ) {
    final last = allClear.lastService;
    final metres = allClear.sinceMetres;
    final days = allClear.sinceDays;
    if (last == null || metres == null || days == null) return null;

    return CalmSinceLine(
      label: l10n.homeSinceLast(
        last.lines.firstOrNull?.label ?? l10n.vehicleStatusItemGeneric,
      ),
      figure: l10n.homeSinceLastFigure(
        formatWithUnit(
          Distance(metres).inUnit(unit),
          distanceUnitLabel(l10n, unit),
          tag,
          numerals: CalmNumerals.auto,
          decimalDigits: 0,
        ),
        homeDurationLine(l10n, tag, days),
      ),
    );
  }

  /// One conditional strip, by kind.
  ///
  /// Two of the three cannot be eligible yet — their triggers arrive with
  /// EPIC-16 — but they are built here rather than left to a `default`, so the
  /// day the trigger lands the drawing is already done and the switch is a
  /// compile-time list of three.
  Widget _strip(
    BuildContext context,
    HomeStripKind kind,
    HomeState state,
    DistanceUnit unit,
    String tag,
  ) => switch (kind) {
    HomeStripKind.staleOdometer => StalenessStrip(
      staleDays: state.estimate?.staleDays ?? 0,
      unit: unit,
      groupingSeparator: groupingSeparatorFor(tag),
      formatsTag: tag,
      onSave: (metres) => unawaited(_saveReading(context, state, metres)),
      onDismiss: () => unawaited(_dismissStaleness(state)),
    ),
    // EPIC-16 writes the record these two report on. Until then they are
    // never queued, and a placeholder here would be a strip nobody can see
    // pretending to be one nobody built.
    HomeStripKind.doneConfirmation ||
    HomeStripKind.awayDigest => const SizedBox.shrink(),
  };

  /// §9's inline Save: a reading, a snackbar with Undo, or the full modal.
  Future<void> _saveReading(
    BuildContext context,
    HomeState state,
    int metres,
  ) async {
    final l10n = AppLocalizations.of(context);
    final snackbars = CalmSnackbarHost.of(context);
    final router = GoRouter.of(context);
    final saver = ref.read(stripOdometerSaveProvider.notifier);

    final outcome = await saver.save(state.vehicle, metres);
    switch (outcome) {
      case StripSaveWritten(:final reading):
        snackbars.show(
          message: l10n.odometerSavedSnack,
          actionLabel: l10n.commonUndo,
          onAction: () => unawaited(saver.undo(reading)),
        );
      // §9: "On a violation the strip yields to the full `log.odometer` modal,
      // which owns the typo/correction/backdate dialogue." Through the captured
      // router: the strip disappears the moment the reading lands, so the
      // element this ran from may already be gone.
      case StripSaveYieldsToModal(:final metres):
        unawaited(
          router.push<void>(
            Routes.log(LogType.odometer, odometerMetres: metres),
          ),
        );
      case StripSaveFailed():
        snackbars.show(message: l10n.saveDiskFullError, danger: true);
    }
  }

  /// §9's `✕`: "hides for 7 days, this vehicle".
  Future<void> _dismissStaleness(HomeState state) async {
    final today = CivilDate.fromDateTime(ref.read(clockProvider).now());
    if (today == null) return;
    await ref
        .read(uiStateProvider.notifier)
        .set(
          uiKeyStalenessDismissedUntil(state.vehicle.id.toString()),
          stalenessDismissedUntil(today).toString(),
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
    // Through `dueActionKey`, not through a `DueState` comparison. It is the
    // same function that chose the button's WORD, so "Update odometer" and
    // "goes to log.odometer" cannot disagree — and the two uncertain cases §9
    // names are `needs_odometer` AND a distance-driven `due_soon` at
    // `confidence = default`, which an equality test on the state misses.
    if (dueActionKey(card.assessment) == DueActionKind.updateOdometer) {
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

  Future<void> _more(
    BuildContext context,
    DueCardModel card,
    HomeState state,
  ) async {
    // Captured BEFORE the sheet is awaited. The sheet is a route: while it is
    // open this element can be rebuilt or removed, and `CalmSnackbarHost`
    // exists precisely so that what a context could see is read while it can
    // still see it.
    final snackbars = CalmSnackbarHost.of(context);
    final l10n = AppLocalizations.of(context);

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
        await _turnOff(snackbars, l10n, card);
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
  Future<void> _turnOff(
    CalmSnackbarHost snackbars,
    AppLocalizations l10n,
    DueCardModel card,
  ) async {
    final activation = ref.read(reminderActivationProvider.notifier);

    final result = await activation.setActive(card.item.id, active: false);
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
        activation.setActive(card.item.id, active: true),
      ),
    );
  }
}

/// How long the vehicle was owned, or null when the purchase date is unknown.
String? _ownedFor(AppLocalizations l10n, String tag, Vehicle vehicle) {
  final bought = CivilDate.tryParseOrNull(vehicle.purchaseDate);
  final sold = CivilDate.tryParseOrNull(vehicle.soldOn);
  if (bought == null || sold == null || sold < bought) return null;
  return homeDurationLine(l10n, tag, bought.daysUntil(sold));
}

/// How far it went, or null when either end of the span is unknown.
///
/// The last estimate is the far end even when it is PROJECTED: a sold vehicle
/// stopped being driven, so the projection is the odometer at the sale as
/// nearly as the app can know it. It carries no `~` here because the figure is
/// inside a sentence about the past, and §9 spends the tilde on values the user
/// might act on.
String? _drivenBy(
  AppLocalizations l10n,
  String tag,
  HomeState state,
  DistanceUnit unit,
) {
  final from = state.vehicle.purchaseOdometer?.metres;
  final to = state.estimate?.metres;
  if (from == null || to == null || to < from) return null;
  return formatWithUnit(
    Distance(to - from).inUnit(unit),
    distanceUnitLabel(l10n, unit),
    tag,
    numerals: CalmNumerals.auto,
    decimalDigits: 0,
  );
}
