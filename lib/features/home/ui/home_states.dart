// Home when there is nothing to do, nothing yet, nothing left, or nothing
// readable.
//
// SPEC.md §9 *Every state*. Four panels and one card, each replacing something
// rather than sitting beside it — which is the whole discipline of this screen:
// one thing wins the eye, and a screen with an all-clear card AND a due stack
// has answered its own question twice.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/features/home/domain/home_view_model.dart';
import 'package:odova/features/home/ui/odometer_strip.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_all_clear.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_due_card.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';
import 'package:odova/ui/calm/calm_surface.dart';

/// §9's unknown-anchor card, and the first-run card, which are one widget.
///
/// The only difference is the headline: with a list of items it asks "When were
/// these last done?", and with nothing at all it invites — "Set up your
/// reminders". The BODY is the same because the answer is: tell me, and these
/// become reminders.
class UnknownAnchorPanel extends StatelessWidget {
  /// Creates the card.
  const UnknownAnchorPanel({
    required this.card,
    required this.formatsTag,
    required this.onOpenList,
    required this.onOpenItem,
    super.key,
    this.firstRun = false,
  });

  /// What `buildHomeStack` collapsed, or an empty one on first run.
  final UnknownAnchorCard card;

  /// The tag the count is shaped by.
  final String formatsTag;

  /// Opens `reminders.list`.
  final VoidCallback onOpenList;

  /// Opens `reminders.edit` for one named item.
  final void Function(int index) onOpenItem;

  /// Whether this is the empty, nothing-known-yet case.
  final bool firstRun;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final style = CalmStatusStyle.of(context, DueState.unknown);

    return CalmPressable(
      onTap: onOpenList,
      borderRadius: shapes.radius3xl,
      child: CalmSurface(
        color: colors.surface,
        radius: shapes.radius3xl,
        shadow: shapes.elev1,
        padding: EdgeInsetsDirectional.all(space.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: space.s3,
          children: [
            Row(
              spacing: space.s3,
              children: [
                CalmStatusDot(style: style),
                Expanded(
                  child: Text(
                    firstRun ? l10n.homeFirstRunSetUp : l10n.homeUnknownTitle,
                    style: type.headline.copyWith(color: colors.ink),
                  ),
                ),
              ],
            ),
            // The named items, each its own tap target. §9: "The card opens
            // `reminders.list`, a named item opens `reminders.edit`."
            if (card.labels.isNotEmpty)
              Wrap(
                spacing: space.s2,
                runSpacing: space.s2,
                children: [
                  for (final (index, label) in card.labels.indexed)
                    CalmPressable(
                      onTap: () => onOpenItem(index),
                      borderRadius: shapes.radiusPill,
                      semanticLabel: label,
                      child: CalmTapTarget(
                        minSize: Size(0, space.touchMin),
                        child: Padding(
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: space.s3,
                            vertical: space.s2,
                          ),
                          child: Text(
                            label,
                            style: type.body.copyWith(color: colors.ink2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            Text(
              l10n.homeUnknownHint,
              style: type.caption.copyWith(color: colors.ink2),
            ),
            if (card.moreCount > 0)
              Text(
                l10n.homeUnknownMore(
                  card.moreCount,
                  // Through the formatter, like every other count on this
                  // screen. A raw `'${'$'}{card.moreCount}'` renders Latin
                  // digits, so in fa, ar and ckb this one line read `+ 2 more`
                  // while the strip above it and the see-all row beside it
                  // both read `۲`.
                  formatForDisplay(
                    card.moreCount,
                    formatsTag,
                    numerals: CalmNumerals.auto,
                    decimalDigits: 0,
                  ),
                ),
                style: type.caption.copyWith(color: colors.ink2),
              ),
          ],
        ),
      ),
    );
  }
}

/// §9's sold or archived vehicle: the due stack, replaced.
///
/// "The due stack is replaced entirely; History and Costs stay fully available,
/// no reminders, no notifications, no nudges." So this panel offers no action
/// at all — a vehicle the user has sold does not need to be told what to do
/// about it.
class SoldVehiclePanel extends StatelessWidget {
  /// Creates the panel.
  const SoldVehiclePanel({
    required this.soldOn,
    required this.owned,
    required this.driven,
    super.key,
  });

  /// The sale date, already formatted.
  final String soldOn;

  /// How long it was owned, already formatted. Null when the purchase date is
  /// not known — which is common, and not worth a guess.
  final String? owned;

  /// How far it went, already formatted. Null for the same reason.
  final String? driven;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return CalmSurface(
      color: colors.surface2,
      radius: shapes.radiusXl,
      sheen: false,
      padding: EdgeInsetsDirectional.all(space.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: space.s2,
        children: [
          Text(
            l10n.homeSoldTitle(soldOn),
            style: type.body.copyWith(
              color: colors.ink,
              fontWeight: type.medium,
            ),
          ),
          // Both halves or neither. "Owned 6 years · — driven" is a sentence
          // with a hole in it, and §1 would rather say less than say that.
          if (owned != null && driven != null)
            Text(
              l10n.homeSoldOwned(owned!, driven!),
              style: type.caption.copyWith(color: colors.ink2),
            ),
        ],
      ),
    );
  }
}

/// §9's *Error*: one message and one button.
///
/// "Get the data out of the building before anything else." So the single
/// action is Backup & restore, and there is deliberately no Retry: a store that
/// cannot be read is not a request that failed.
class HomeErrorPanel extends StatelessWidget {
  /// Creates the panel.
  const HomeErrorPanel({required this.onOpenBackup, super.key});

  /// Pushes `settings.backup`.
  final VoidCallback onOpenBackup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: space.s4,
      children: [
        Text(
          l10n.homeErrorTitle,
          textAlign: TextAlign.center,
          style: type.title.copyWith(color: colors.ink),
        ),
        CalmButton(
          label: l10n.actionOpenBackup,
          onPressed: onOpenBackup,
          block: true,
        ),
      ],
    );
  }
}

/// One card whose derived state threw.
///
/// §9: "A single item whose derived state throws renders as a grey card,
/// `Something's wrong with this reminder`, with a chevron to `reminders.edit` —
/// one bad row never blanks the screen."
class BrokenReminderCard extends StatelessWidget {
  /// Creates the card.
  const BrokenReminderCard({required this.onTap, super.key});

  /// Opens `reminders.edit`.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CalmRowGroup(
      rows: [
        CalmListRow(
          title: l10n.homeRowBroken,
          // GREY, through the `unknown` state's own dot rather than a colour
          // named here: an item the app cannot reason about is exactly what
          // `unknown` means, and it must not borrow overdue's red.
          lead: CalmStatusDot(
            style: CalmStatusStyle.of(context, DueState.unknown),
          ),
          showChevron: true,
          onTap: onTap,
        ),
      ],
    );
  }
}

/// Nothing for `CalmMotion.skeletonDelay`, then [child].
///
/// §9's "a skeleton appears only past 150 ms, to avoid a flash on the common
/// path": a warm database answers in single-digit milliseconds, and a
/// silhouette that flashes for one frame reads as a stutter rather than as
/// progress. A `Timer` rather than an animation, so a device with reduced
/// motion still gets the delay — the point is not to animate, it is not to
/// flash.
class DelayedSkeleton extends StatefulWidget {
  /// Creates the gate.
  const DelayedSkeleton({required this.child, super.key});

  /// What to show once the delay is up.
  final Widget child;

  @override
  State<DelayedSkeleton> createState() => _DelayedSkeletonState();
}

class _DelayedSkeletonState extends State<DelayedSkeleton> {
  // A `Timer` held and cancelled, not a bare `Future.delayed`. A future cannot
  // be cancelled, so a screen that resolved in 5 ms left one pending for the
  // remaining 145 — and `testWidgets` asserts on a timer outliving the tree,
  // which turned every test that so much as opened Home into a teardown
  // failure. It is also the ordinary rule: what `initState` starts, `dispose`
  // stops.
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // In `initState` via a post-frame callback, because `CalmMotion.of` needs
    // an inherited widget and `initState` may not read one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _timer = Timer(CalmMotion.of(context).skeletonDelay, () {
        if (mounted) setState(() => _visible = true);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _visible ? widget.child : const SizedBox.shrink();
}

/// The silhouette Home wears past [DelayedSkeleton]'s delay.
///
/// The shapes the screen is about to draw, in `surface-2` and with no text: a
/// strip, a primary card and two secondaries. §9 draws no skeleton, so this
/// invents nothing — it is the layout the next frame has, without the content
/// it does not have yet.
class HomeSkeleton extends StatelessWidget {
  /// Creates the silhouette.
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);

    Widget block(double height, double radius) => CalmSurface(
      color: colors.surface2,
      radius: radius,
      sheen: false,
      child: SizedBox(height: height, width: double.infinity),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: space.s3,
      children: [
        block(kOdometerStripHeight, shapes.radiusXl),
        block(kCalmDueCardPrimaryHeight, shapes.radius3xl),
        block(kCalmDueCardSecondaryHeight, shapes.radiusXl),
        block(kCalmDueCardSecondaryHeight, shapes.radiusXl),
      ],
    );
  }
}

/// The all-clear, assembled from `HomeState`'s raw facts.
///
/// A thin wrapper over `CalmAllClear` rather than a second card: §9 says
/// "nothing due renders `CalmAllClear`, never `CalmEmptyState`" — an empty
/// state is for a list with no rows, and this is an answer.
class HomeAllClearPanel extends StatelessWidget {
  /// Creates the panel.
  const HomeAllClearPanel({
    required this.nextLine,
    required this.fuzzLine,
    required this.since,
    super.key,
  });

  /// `Next: Inspection, 14 March`, or null when nothing is tracked.
  final String? nextLine;

  /// `in about 5 months`, or null.
  final String? fuzzLine;

  /// The receipt, or null when there is no service to point at.
  final CalmSinceLine? since;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CalmAllClear(
      headline: l10n.homeNothingDue,
      // An empty next line rather than a made-up one. A vehicle with nothing
      // tracked has no next item, and "Next: —" would be a row pretending to
      // carry an answer.
      nextLine: nextLine ?? '',
      fuzzLine: fuzzLine,
      since: since,
    );
  }
}
