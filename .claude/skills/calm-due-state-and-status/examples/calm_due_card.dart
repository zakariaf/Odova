// lib/ui/calm/calm_due_card.dart
//
// The Home due card at both densities. Every colour, word and silhouette
// arrives through CalmStatusStyle — this file contains no switch over DueState
// and reads no status colour slot directly. The dot itself is calm_status_dot.dart.
//
// Extensions (CalmColors/CalmType/CalmSpace/CalmShapes) are owned by `calm-tokens`.
import 'package:flutter/material.dart';

import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';

enum CalmDueDensity { primary, secondary }

/// Everything the card renders, already formatted and localised by the feature
/// layer. The card never formats a number, a date or a tilde: those are ICU
/// messages, and a widget that builds '~' + value puts the tilde on the wrong
/// side of the digits in Arabic (`calm-typography-and-rtl`).
@immutable
class CalmDueView {
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

  final DueState state;
  final DueDriver driver;
  final DueConfidence confidence;
  final String title;

  /// `Overdue by 900 km`, `Due now`, or — at DueConfidence.defaulted — the
  /// no-confidence sentence and nothing else.
  final String statusLine;

  /// `Log it`, or `Update odometer` for the two uncertain states.
  final String actionLabel;

  /// `Was due at 186,512 km · 12 August`. Null when nothing is certain.
  final String? anchorLine;

  /// `Snoozed until 12 October`. Snoozing is a modifier, not a state.
  final String? snoozeLine;

  /// 0..1 of the interval consumed. Null for the uncertain states — a bar is a
  /// figure, and SPEC §1.4 forbids a figure the data cannot support.
  final double? progress;
}

class CalmDueCard extends StatelessWidget {
  const CalmDueCard({
    super.key,
    required this.view,
    required this.density,
    required this.onTap,
    required this.onAction,
  });

  final CalmDueView view;
  final CalmDueDensity density;
  final VoidCallback onTap;
  final VoidCallback onAction;

  /// odova.css §13: the primary card fades from the state tint to the surface
  /// at 78%, so the status line's ink must clear 4.5:1 on both stops.
  static const double _tintStop = 0.78;

  @override
  Widget build(BuildContext context) {
    final CalmStatusStyle style = CalmStatusStyle.of(context, view.state);
    final CalmColors colors = CalmColors.of(context);
    final CalmSpace space = CalmSpace.of(context);
    final CalmShapes shapes = CalmShapes.of(context);
    final bool isPrimary = density == CalmDueDensity.primary;
    // CalmPressable takes the raw corner radius; the decoration takes the
    // BorderRadius built from the same number, so they can never drift.
    final double radius = isPrimary ? shapes.radius3xl : shapes.radiusXl;
    final BorderRadius borderRadius = BorderRadius.circular(radius);

    return MergeSemantics(
      child: Semantics(
        button: true,
        label: view.title,
        value: view.statusLine,
        // No Material + InkWell: the splash is a cool circle spreading across a
        // warm card and InkWell needs a Material ancestor whose elevation model
        // fights elev1. CalmPressable is the one press affordance
        // (`calm-components`).
        child: CalmPressable(
          onTap: onTap,
          borderRadius: radius,
          pressScale: kCalmPressScaleButton,
          child: Container(
            constraints:
                BoxConstraints(minHeight: isPrimary ? 0 : space.touchMin),
            padding: EdgeInsetsDirectional.all(isPrimary ? space.s6 : space.s4),
            decoration: BoxDecoration(
              color: isPrimary ? null : colors.surface,
              gradient: isPrimary
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[style.tint, colors.surface],
                      stops: const <double>[0, _tintStop],
                    )
                  : null,
              borderRadius: borderRadius,
              boxShadow: isPrimary ? shapes.elev2 : shapes.elev1,
            ),
            child: isPrimary
                ? _PrimaryBody(view: view, style: style, onAction: onAction)
                : _SecondaryBody(view: view, style: style),
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
    final CalmType type = CalmType.of(context);
    final CalmSpace space = CalmSpace.of(context);
    final CalmShapes shapes = CalmShapes.of(context);
    final CalmColors colors = CalmColors.of(context);
    final double? progress = view.progress;
    final String? anchor = view.anchorLine;
    final String? snooze = view.snoozeLine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            CalmStatusDot(style: style),
            SizedBox(width: space.s3),
            Expanded(
              child: Text(view.title,
                  style: type.headline.copyWith(color: colors.ink)),
            ),
          ],
        ),
        SizedBox(height: space.s3),
        // Signals 2 and 3, always present: a dot with no word is invisible in
        // grayscale, and Calm's six state hues sit within 1.51:1 of each other.
        Text(view.statusLine, style: type.titleLg.copyWith(color: style.ink)),
        if (anchor != null) ...<Widget>[
          SizedBox(height: space.s2),
          // ink2, never ink3: ink3 at 13px measures 3.02–3.99:1 in light.
          Text(anchor, style: type.caption.copyWith(color: colors.ink2)),
        ],
        if (snooze != null) ...<Widget>[
          SizedBox(height: space.s1),
          Text(snooze, style: type.caption.copyWith(color: style.ink)),
        ],
        if (progress != null) ...<Widget>[
          SizedBox(height: space.s2),
          ClipRRect(
            borderRadius: BorderRadius.circular(shapes.radiusPill),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: space.s1,
              backgroundColor: colors.surface3,
              valueColor: AlwaysStoppedAnimation<Color>(style.base),
            ),
          ),
        ],
        SizedBox(height: space.s3),
        SizedBox(
          height: space.touchMin,
          child:
              FilledButton(onPressed: onAction, child: Text(view.actionLabel)),
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
    final CalmType type = CalmType.of(context);
    final CalmSpace space = CalmSpace.of(context);
    final CalmColors colors = CalmColors.of(context);

    return Row(
      children: <Widget>[
        CalmStatusDot(style: style),
        SizedBox(width: space.s3),
        Expanded(
          child: Text(view.title, style: type.body.copyWith(color: colors.ink)),
        ),
        SizedBox(width: space.s3),
        Text(view.statusLine,
            textAlign: TextAlign.end,
            style: type.caption.copyWith(color: style.ink)),
        // Icons.chevron_right carries matchTextDirection: true, so it mirrors
        // under Directionality — no left/right in layout code (SPEC §2).
        Icon(Icons.chevron_right, size: space.s5, color: colors.ink3),
      ],
    );
  }
}
