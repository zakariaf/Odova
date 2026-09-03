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

/// odova.css §13: the primary card fades from the state tint to the surface at
/// 78%, so the status line's ink must clear 4.5:1 on BOTH stops.
const double kCalmDueCardTintStop = 0.78;

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
    this.anchorLine,
    this.snoozeLine,
    this.progress,
  });

  /// What the due engine decided.
  final DueState state;

  /// Distance, date, both, or neither.
  final DueDriver driver;

  /// How much the engine actually knew.
  final DueConfidence confidence;

  /// The item's name.
  final String title;

  /// `Overdue by 900 km`, `Due now`, or — at [DueConfidence.defaulted] — the
  /// no-confidence sentence and nothing else.
  final String statusLine;

  /// `Log it`, or the update-odometer label for the two uncertain states.
  final String actionLabel;

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
  });

  /// What to render.
  final CalmDueView view;

  /// Which of the two shapes.
  final CalmDueDensity density;

  /// Opens the item.
  final VoidCallback onTap;

  /// Does the thing the card is asking for.
  final VoidCallback onAction;

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

    return MergeSemantics(
      child: Semantics(
        button: true,
        label: view.title,
        value: view.statusLine,
        child: ExcludeSemantics(
          child: CalmPressable(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              constraints: BoxConstraints(
                minHeight: isPrimary ? 0.0 : space.touchMin,
              ),
              padding: EdgeInsetsDirectional.all(
                isPrimary ? space.s6 : space.s4,
              ),
              decoration: BoxDecoration(
                color: isPrimary ? null : colors.surface,
                gradient: isPrimary
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [style.tint, colors.surface],
                        stops: const [0, kCalmDueCardTintStop],
                      )
                    : null,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: isPrimary ? shapes.elev2 : shapes.elev1,
              ),
              child: isPrimary
                  ? _PrimaryBody(view: view, style: style, onAction: onAction)
                  : _SecondaryBody(view: view, style: style),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryBody extends StatelessWidget {
  const _PrimaryBody({
    required this.view,
    required this.style,
    required this.onAction,
  });

  final CalmDueView view;
  final CalmStatusStyle style;
  final VoidCallback onAction;

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
        CalmButton(
          label: view.actionLabel,
          onPressed: onAction,
          // The action takes the colour of the item it acts on, resolved
          // through CalmStatusStyle rather than named here.
          variant: CalmButtonVariant.onState,
          dueState: view.state,
          block: true,
        ),
      ],
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
        Text(
          view.statusLine,
          textAlign: TextAlign.end,
          style: type.caption.copyWith(color: style.ink),
        ),
        CalmDirectionalIcon(
          Icons.chevron_right,
          size: space.s5,
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

  /// How long the fill takes to move.
  Duration get duration => calmMotion.slow;

  /// The curve it moves on.
  Curve get curve => calmMotion.easeStandard;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
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
            duration: calmDuration(context, duration),
            curve: curve,
            // FractionallySizedBox, not Align(widthFactor:): a width factor
            // multiplies the CHILD's width, and the fill has none of its own,
            // so an Align here draws a zero-width bar that looks like an empty
            // track. This one is a fraction of the TRACK.
            builder: (context, t, _) => FractionallySizedBox(
              // Directional: the fill grows away from the start edge, which is
              // the right-hand one in fa, ar and ckb.
              alignment: AlignmentDirectional.centerStart,
              widthFactor: t,
              child: CalmProgressFill(color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// The filled part of a [CalmProgressBar].
class CalmProgressFill extends StatelessWidget {
  /// Creates the fill.
  const CalmProgressFill({required this.color, super.key});

  /// The state's graphic colour.
  final Color color;

  @override
  Widget build(BuildContext context) => ColoredBox(color: color);
}
