// CalmDueCard — the Home due card, at both densities.
//
// Every colour, word and silhouette arrives through CalmStatusStyle: this file
// contains no switch over DueState and reads no status colour slot directly.
// The dot itself is calm_status_dot.dart.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';
import 'package:odova/ui/calm/calm_surface.dart';

/// odova.css §13: the primary card fades from the state tint to the surface at
/// 78%, so the status line's ink must clear 4.5:1 on BOTH stops.
const double kCalmDueCardTintStop = 0.78;

/// `.due-card--primary` — "148pt+, tinted, the eye lands here first."
///
/// A FLOOR, not a fixed height: six languages and an unclamped text scaler mean
/// nothing on a Calm screen may depend on fitting. It exists because SPEC.md
/// §9's fold budget — 56 + 64 + 148 + 2 × 72 + 48 = 460 on a 375 × 667 screen —
/// is arithmetic over these two numbers, and a card that sized purely to its
/// content would move the see-all row above or below the fold depending on how
/// long the item's name happened to be.
const double kCalmDueCardPrimaryHeight = 148;

/// `.due-card--secondary { min-height: 72px }`.
const double kCalmDueCardSecondaryHeight = 72;

/// The `⋯` inside `.due-card__actions`.
///
/// A key rather than a finder on the icon: SPEC.md §9's overflow is the one
/// control on the card that carries no word, so there is nothing else to find
/// it by that would not also match a decorative glyph somebody adds later.
const Key kCalmDueCardMoreKey = Key('calm.dueCard.more');

/// `.due-card__more` paints 44 square; Calm's tap floor is still `touchMin`.
const double kCalmDueCardMorePaint = 44;

/// The two densities Home uses.
enum CalmDueDensity {
  /// The one big thing on Home: `radius3xl`, `elev2`, a gradient, an action.
  primary,

  /// 72pt: a dot, a title, a status line and a chevron.
  secondary,
}

/// Everything the card renders, already formatted and localised by the feature
/// layer.
///
/// The card never formats a number, a date or a tilde: those are ICU messages,
/// and a widget that builds `'~' + value` puts the tilde on the wrong side of
/// the digits in Arabic.
@immutable
class CalmDueView {
  /// Creates a view.
  const CalmDueView({
    required this.state,
    required this.driver,
    required this.confidence,
    required this.title,
    required this.statusLine,
    required this.actionLabel,
    this.actionIcon,
    this.anchorLine,
    this.snoozeLine,
    this.progress,
  });

  /// What the due engine decided.
  final DueState state;

  /// Distance, date, both, or neither.
  final DueDriver driver;

  /// How much the engine actually knew.
  final RateConfidence confidence;

  /// The item's name.
  final String title;

  /// `Overdue by 900 km`, `Due now`, or — at [RateConfidence.defaulted] — the
  /// no-confidence sentence and nothing else.
  final String statusLine;

  /// `Log it`, or the update-odometer label for the two uncertain states.
  final String actionLabel;

  /// The glyph beside it. `.btn` in the artboard carries one; null draws none.
  final IconData? actionIcon;

  /// `Was due at 186,512 km · 12 August`. Null when nothing is certain.
  final String? anchorLine;

  /// `Snoozed until 12 October`. Snoozing is a modifier, not a state.
  final String? snoozeLine;

  /// 0..1 of the interval consumed.
  ///
  /// Null for the uncertain states: a bar is a figure, and SPEC.md §1 forbids
  /// a figure the data cannot support.
  final double? progress;
}

/// The due card.
class CalmDueCard extends StatelessWidget {
  /// Creates a card from a view — not from loose strings, and not from a named
  /// constructor per state.
  const CalmDueCard({
    required this.view,
    required this.density,
    required this.onTap,
    required this.onAction,
    super.key,
    this.onMore,
    this.moreLabel,
  }) : assert(
         onMore == null || moreLabel != null,
         'a control with no word needs an accessible name',
       );

  /// What to render.
  final CalmDueView view;

  /// Which of the two shapes.
  final CalmDueDensity density;

  /// Opens the item.
  final VoidCallback onTap;

  /// Does the thing the card is asking for.
  final VoidCallback onAction;

  /// Opens SPEC.md §9's four-item overflow, at primary density only.
  ///
  /// Null draws no `⋯`. The secondary density has no `.due-card__actions` row
  /// to put one in — a 72pt line with a chevron has nowhere for a second
  /// control — so it never draws one whatever this is.
  final VoidCallback? onMore;

  /// The overflow's accessible name. Localised by the feature layer.
  final String? moreLabel;

  @override
  Widget build(BuildContext context) {
    final style = CalmStatusStyle.of(context, view.state);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final shapes = CalmShapes.of(context);
    final isPrimary = density == CalmDueDensity.primary;
    // CalmPressable takes the raw corner radius; the decoration takes the
    // BorderRadius built from the same number, so they cannot drift.
    final radius = isPrimary ? shapes.radius3xl : shapes.radiusXl;

    // The label goes through the primitive ONLY at secondary density.
    //
    // A `semanticLabel` replaces the subtree's words, which is right for a
    // secondary card — a dot, a title, a status line and a chevron, none of
    // them interactive. At primary density the body contains the card's own
    // action button, and replacing the subtree would strip Home's main action
    // out of the semantics tree entirely: a screen-reader user would hear
    // "Oil change, Due now, button" and have no way to invoke "Log it".
    final navigable = CalmPressable(
      onTap: onTap,
      borderRadius: radius,
      semanticLabel: isPrimary ? null : view.title,
      semanticsValue: isPrimary ? null : view.statusLine,
      child: CalmSurface(
        color: colors.surface,
        gradient: isPrimary
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [style.tint, colors.surface],
                stops: const [0, kCalmDueCardTintStop],
              )
            : null,
        radius: radius,
        shadow: isPrimary ? shapes.elev2 : shapes.elev1,
        padding: EdgeInsetsDirectional.all(
          isPrimary ? space.s6 : space.s4,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                (isPrimary
                    ? kCalmDueCardPrimaryHeight
                    : kCalmDueCardSecondaryHeight) -
                (isPrimary ? space.s6 : space.s4) * 2,
          ),
          child: isPrimary
              ? _PrimaryBody(
                  view: view,
                  style: style,
                  onAction: onAction,
                  onMore: onMore,
                  moreLabel: moreLabel,
                )
              : _SecondaryBody(view: view, style: style),
        ),
      ),
    );

    // MergeSemantics only where there is nothing interactive to merge away.
    return isPrimary ? navigable : MergeSemantics(child: navigable);
  }
}

class _PrimaryBody extends StatelessWidget {
  const _PrimaryBody({
    required this.view,
    required this.style,
    required this.onAction,
    required this.onMore,
    required this.moreLabel,
  });

  final CalmDueView view;
  final CalmStatusStyle style;
  final VoidCallback onAction;
  final VoidCallback? onMore;
  final String? moreLabel;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final progress = view.progress;
    final anchor = view.anchorLine;
    final snooze = view.snoozeLine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            CalmStatusDot(style: style),
            SizedBox(width: space.s3),
            Expanded(
              child: Text(
                view.title,
                style: type.headline.copyWith(color: colors.ink),
              ),
            ),
          ],
        ),
        SizedBox(height: space.s3),
        // Signals 2 and 3, always present: a dot with no word is invisible in
        // grayscale, and Calm's six state hues sit within 1.51:1 of each other.
        Text(
          view.statusLine,
          style: type.titleLg.copyWith(color: style.ink),
        ),
        if (anchor != null) ...[
          SizedBox(height: space.s2),
          // ink2, never ink3: ink3 at 13px measures 3.02-3.99:1 in light.
          Text(anchor, style: type.caption.copyWith(color: colors.ink2)),
        ],
        if (snooze != null) ...[
          SizedBox(height: space.s1),
          Text(snooze, style: type.caption.copyWith(color: style.ink)),
        ],
        if (progress != null) ...[
          SizedBox(height: space.s2),
          CalmProgressBar(value: progress, color: style.base),
        ],
        SizedBox(height: space.s3),
        // `.due-card__actions { justify-content: space-between }` — the
        // button sizes to its WORDS and the overflow sits at the far edge.
        // Not `block: true`: the reference draws a pill about a third of the
        // card wide, and a full-width button next to a 52pt target overflows
        // the row besides.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: CalmButton(
                label: view.actionLabel,
                icon: view.actionIcon,
                onPressed: onAction,
                // The action takes the colour of the item it acts on, resolved
                // through CalmStatusStyle rather than named here.
                variant: CalmButtonVariant.onState,
                dueState: view.state,
              ),
            ),
            if (onMore case final onMore?) ...[
              SizedBox(width: space.s3),
              _MoreButton(onPressed: onMore, label: moreLabel!),
            ],
          ],
        ),
      ],
    );
  }
}

/// `.due-card__more` — 44 painted, [CalmSpace.touchMin] hit.
class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);

    return CalmPressable(
      key: kCalmDueCardMoreKey,
      onTap: onPressed,
      borderRadius: kCalmDueCardMorePaint / 2,
      semanticLabel: label,
      child: CalmTapTarget(
        minSize: Size.square(space.touchMin),
        child: SizedBox(
          width: kCalmDueCardMorePaint,
          height: kCalmDueCardMorePaint,
          child: Icon(
            Icons.more_horiz,
            size: space.iconMd,
            color: colors.ink3,
          ),
        ),
      ),
    );
  }
}

class _SecondaryBody extends StatelessWidget {
  const _SecondaryBody({required this.view, required this.style});

  final CalmDueView view;
  final CalmStatusStyle style;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Row(
      children: [
        CalmStatusDot(style: style),
        SizedBox(width: space.s3),
        Expanded(
          child: Text(
            view.title,
            style: type.body.copyWith(color: colors.ink),
          ),
        ),
        SizedBox(width: space.s3),
        // Flexible, not a bare Text: at 200% text scale the title and the
        // status line together are wider than a phone, and an unconstrained
        // Text in a Row overflows rather than wrapping. The card's own
        // minHeight lets it grow instead.
        Flexible(
          child: Text(
            view.statusLine,
            textAlign: TextAlign.end,
            style: type.caption.copyWith(color: style.ink),
          ),
        ),
        CalmDirectionalIcon(
          Icons.chevron_right,
          size: space.iconSm,
          color: colors.ink3,
        ),
      ],
    );
  }
}

/// The interval-consumed bar.
///
/// Its own widget rather than a LinearProgressIndicator: the fill animates its
/// WIDTH over `motion.slow`, and it fills from the START edge, which is the
/// right-hand one in fa, ar and ckb.
class CalmProgressBar extends StatelessWidget {
  /// Creates a bar.
  const CalmProgressBar({required this.value, required this.color, super.key});

  /// 0..1.
  final double value;

  /// The state's graphic colour.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    // Through the extension, like every other value in this library. Reading
    // the global `calmMotion` const worked and was the only place in lib/ui/
    // that bypassed CalmMotion.of — so a Theme that overrode the extension,
    // which is what its lerp and copyWith exist for, was silently ignored by
    // this one widget. No gate catches it: the motion rule greps for literal
    // Durations and Curves.
    final motion = CalmMotion.of(context);
    final space = CalmSpace.of(context);
    return ClipPath(
      // A StadiumBorder's clip, not BorderRadius.circular(radiusPill): 999 is
      // a sentinel meaning "fully round", and as a real radius in a ClipRRect
      // it allocates a path Skia re-clamps on every frame of the fill.
      clipper: const ShapeBorderClipper(shape: StadiumBorder()),
      child: SizedBox(
        height: space.s1,
        child: ColoredBox(
          color: colors.surface3,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: value.clamp(0.0, 1.0)),
            duration: calmDuration(context, motion.slow),
            curve: motion.easeStandard,
            // FractionallySizedBox, not Align(widthFactor:): a width factor
            // multiplies the CHILD's width, and the fill has none of its own,
            // so an Align here draws a zero-width bar that looks like an empty
            // track. This one is a fraction of the TRACK.
            builder: (context, t, _) => FractionallySizedBox(
              // Directional: the fill grows away from the start edge, which is
              // the right-hand one in fa, ar and ckb.
              alignment: AlignmentDirectional.centerStart,
              widthFactor: t,
              child: ColoredBox(color: color),
            ),
          ),
        ),
      ),
    );
  }
}
