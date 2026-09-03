// CalmSheet — the default modal surface.
//
// `surface`, `elev4`, and `radius3xl` on the TOP TWO CORNERS ONLY, expressed as
// BorderRadiusDirectional so the file carries no `topLeft`/`topRight` for the
// RTL gate to find. (The two are identical here; the point is that the physical
// names never enter the tree, so the gate can be a grep.)
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_overlay_transition.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

/// How far the sheet rises as it enters. Not a slide: the scrim carries the
/// arrival and the surface only settles.
const double kCalmSheetRise = 24;

/// It starts at 60% opacity, not 0 — a sheet that fades from nothing reads as
/// a flash rather than as an arrival.
const double kCalmSheetFadeFrom = 0.6;

/// The tallest a sheet may be, as a fraction of the screen.
const double kCalmSheetMaxHeightFactor = 0.88;

/// The grip: 44 x 5 at 18% ink.
const Size kCalmSheetGripSize = Size(44, 5);

/// The grip's opacity.
const double kCalmSheetGripOpacity = 0.18;

/// The default modal surface.
class CalmSheet extends StatelessWidget {
  /// Creates a sheet.
  const CalmSheet({
    required this.title,
    required this.children,
    super.key,
    this.subtitle,
    this.actions = const [],
    this.full = false,
  });

  /// The sheet's name, already localised.
  final String title;

  /// A caption under it.
  final String? subtitle;

  /// The scrolling body.
  final List<Widget> children;

  /// Stacked, full-width, in the order given.
  final List<Widget> actions;

  /// Edge to edge, with no radius.
  final bool full;

  /// Opens a sheet.
  ///
  /// The call site never reaches for `showModalBottomSheet` directly: four of
  /// its arguments are decisions this app makes once — the sheet is scroll
  /// controlled, its own background is transparent because [CalmSheet] paints
  /// the surface, the barrier is `colors.scrim`, and the safe area is honoured
  /// so a sheet does not run under the home indicator.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool dismissible = true,
  }) {
    final colors = CalmColors.of(context);
    final motion = CalmMotion.of(context);

    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: colors.scrim,
      useSafeArea: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      // Entry is the slowest motion in the system, because a sheet is the one
      // thing that takes over the screen. The exit is NOT symmetric: it leaves
      // on motion.base with easeIn, because accelerating away is what makes a
      // dismissal feel like a dismissal rather than a rewind. `--ease-in` is
      // declared in odova.css and used by nothing else; this is its slot.
      sheetAnimationStyle: AnimationStyle(
        duration: calmDuration(context, motion.sheet),
        reverseDuration: calmDuration(context, motion.base),
        curve: motion.easeStandard,
        reverseCurve: motion.easeIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    final surface = DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.surface,
        shadows: shapes.elev4,
        shape: full
            ? const RoundedRectangleBorder()
            : RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(shapes.radius3xl),
                  topEnd: Radius.circular(shapes.radius3xl),
                ),
              ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!full) ...[
            SizedBox(height: space.s3),
            const CalmSheetGrip(),
          ],
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              space.s6,
              space.s5,
              space.s6,
              space.s3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: type.title.copyWith(
                    color: colors.ink,
                    fontWeight: type.semi,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: space.s1),
                  Text(
                    subtitle!,
                    style: type.caption.copyWith(color: colors.ink3),
                  ),
                ],
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsetsDirectional.symmetric(horizontal: space.s6),
              itemCount: children.length,
              separatorBuilder: (_, _) => SizedBox(height: space.s4),
              itemBuilder: (_, i) => children[i],
            ),
          ),
          if (actions.isNotEmpty)
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                space.s6,
                space.s5,
                space.s6,
                space.s6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) SizedBox(height: space.s3),
                    actions[i],
                  ],
                ],
              ),
            ),
          SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
        ],
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.sizeOf(context).height * kCalmSheetMaxHeightFactor,
      ),
      child: CalmOverlayTransition(
        rise: kCalmSheetRise,
        fadeFrom: kCalmSheetFadeFrom,
        scaleFrom: 1,
        child: surface,
      ),
    );
  }
}

/// The 44x5 grip.
class CalmSheetGrip extends StatelessWidget {
  /// Creates the grip.
  const CalmSheetGrip({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);

    return SizedBox.fromSize(
      size: kCalmSheetGripSize,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: colors.ink.withValues(alpha: kCalmSheetGripOpacity),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(shapes.radiusSm),
          ),
        ),
      ),
    );
  }
}
