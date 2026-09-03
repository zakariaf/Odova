// The Calm press primitive.
//
// Every tappable surface in the app goes through CalmPressable: a scale-and-
// tint press, a focus ring drawn outside the layout, keyboard activation, and
// a hit area that never falls below --touch-min even when the paint does.
//
// There is deliberately no InkWell here. Its splash is a cool circle spreading
// from the touch point across a 28pt-radius warm card, it outlives the touch by
// ~400ms, its colour comes from ThemeData rather than a Calm slot, and it needs
// a Material ancestor whose elevation model then fights --elev-1.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';

// Press displacement, by widget mass. odova.css: .btn:active .98,
// .chip.is-pressed .97, .numpad__key:active .96, .tabbar__fab:active .94.
// These have no token; see the skill's findings.
/// A button's press displacement. `odova.css` `.btn:active`.
const double kCalmPressScaleButton = 0.98;

/// A chip's. `.chip.is-pressed` — lighter mass, further travel.
const double kCalmPressScaleChip = 0.97;

/// A number-pad key's. `.numpad__key:active`.
const double kCalmPressScaleKey = 0.96;

/// The tab bar's `+`. `.tabbar__fab:active`, the largest displacement in
/// the system, because it is the largest control.
const double kCalmPressScaleFab = 0.94;

// odova.css :focus-visible { outline: 3px solid; outline-offset: 3px }
/// The focus ring's stroke. `odova.css` `:focus-visible { outline: 3px }`.
const double kCalmFocusWidth = 3;

/// How far outside the layout box the ring is drawn: 3pt offset plus its own
/// 3pt width, so taking focus never resizes the control.
const double kCalmFocusOutset = 6; // 3 offset + 3 width, drawn outside layout

/// Calm's single motion gate: reduced motion collapses to zero, never to a
/// shorter duration. The press tint still fires, so nothing is lost.
/// See `calm-layout-and-motion`.
Duration calmDuration(BuildContext context, Duration full) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : full;

/// Every tappable surface in the app.
///
/// A 90ms scale-and-tint press, a focus ring drawn outside the layout,
/// keyboard activation, and a hit area that never falls below `touchMin` even
/// when the paint does.
class CalmPressable extends StatefulWidget {
  /// Creates a pressable surface.
  const CalmPressable({
    required this.child,
    required this.borderRadius,
    super.key,
    this.onTap,
    this.onLongPress,
    this.pressScale = kCalmPressScaleButton,
    this.enabled = true,
    this.semanticLabel,
    this.isButton = true,
    this.focusNode,
    this.expandTapTarget = false,
  });

  /// What is pressed.
  final Widget child;

  /// The child's radius, so the focus ring can follow its silhouette.
  final double borderRadius;

  /// Null means disabled: the control absorbs its taps and reports
  /// `enabled: false`.
  final VoidCallback? onTap;

  /// Optional. Rarely used in Calm; a long press is not a discoverable
  /// affordance.
  final VoidCallback? onLongPress;

  /// One of the four `kCalmPressScale*` constants, by widget mass.
  final double pressScale;

  /// Whether the control accepts input at all.
  final bool enabled;

  /// The accessible name, when the child does not carry one.
  final String? semanticLabel;

  /// Whether this announces as a button. False for a row that navigates.
  final bool isButton;

  /// Supplied when a caller owns traversal order.
  final FocusNode? focusNode;

  /// Set on any control that PAINTS smaller than --touch-min: a chip (40), a
  /// segment (46), a switch (34 tall), a stepper button (48). The paint stays
  /// as designed; only the gesture box grows to 52.
  final bool expandTapTarget;

  @override
  State<CalmPressable> createState() => _CalmPressableState();
}

class _CalmPressableState extends State<CalmPressable> {
  bool _pressed = false;
  bool _focused = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final motion = CalmMotion.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final active = widget.enabled && widget.onTap != null;

    Widget content = AnimatedScale(
      scale: _pressed && active ? widget.pressScale : 1,
      duration: calmDuration(context, motion.instant), // --dur-instant, 90ms
      curve: motion.easeOut, // --ease-out
      child: CalmPressState(pressed: _pressed && active, child: widget.child),
    );

    // The focus ring lives OUTSIDE the child's box, so taking focus never
    // resizes the control and never reflows the row it sits in.
    content = Stack(
      clipBehavior: Clip.none,
      children: [
        content,
        if (_focused)
          Positioned.fill(
            left: -kCalmFocusOutset,
            top: -kCalmFocusOutset,
            right: -kCalmFocusOutset,
            bottom: -kCalmFocusOutset,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  // A pill's ring is a stadium. borderRadius is the 999
                  // sentinel there, and 999 + the outset as a real radius is
                  // a path Skia re-clamps every frame to draw the stadium it
                  // would have drawn anyway.
                  shape: widget.borderRadius >= shapes.radiusPill
                      ? StadiumBorder(
                          side: BorderSide(
                            color: colors.focus,
                            width: kCalmFocusWidth,
                          ),
                        )
                      : RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            widget.borderRadius + kCalmFocusOutset,
                          ),
                          side: BorderSide(
                            color: colors.focus,
                            width: kCalmFocusWidth,
                          ),
                        ),
                ),
              ),
            ),
          ),
      ],
    );

    Widget gesture = GestureDetector(
      // Opaque so a disabled control absorbs its own taps instead of letting
      // them fall through to whatever is behind it.
      behavior: HitTestBehavior.opaque,
      onTapDown: active ? (_) => _setPressed(true) : null,
      onTapUp: active ? (_) => _setPressed(false) : null,
      onTapCancel: active ? () => _setPressed(false) : null,
      onTap: active ? widget.onTap : null,
      onLongPress: active ? widget.onLongPress : null,
      child: content,
    );

    if (widget.expandTapTarget) {
      gesture = CalmTapTarget(
        minSize: Size(space.touchMin, space.touchMin),
        child: gesture,
      );
    }

    return Semantics(
      button: widget.isButton,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: active,
        focusNode: widget.focusNode,
        mouseCursor: active
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        // KEYBOARD focus only — a mouse or touch activation draws no ring.
        onShowFocusHighlight: (value) {
          if (_focused != value) setState(() => _focused = value);
        },
        // Without this a GestureDetector-based control is focusable and
        // unusable: Enter and Space would do nothing.
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: gesture,
      ),
    );
  }
}

/// Publishes the press flag down the subtree so a child can tint itself
/// without a second gesture recognizer.
/// Publishes the press flag down the subtree.
///
/// A child tints itself by reading this rather than by adding a second gesture
/// recognizer, which would compete with the first for the same pointer.
class CalmPressState extends InheritedWidget {
  /// Creates the scope.
  const CalmPressState({
    required this.pressed,
    required super.child,
    super.key,
  });

  /// Whether an ancestor [CalmPressable] is being pressed.
  final bool pressed;

  /// Whether an ancestor [CalmPressable] is pressed.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CalmPressState>()?.pressed ??
      false;

  @override
  bool updateShouldNotify(CalmPressState oldWidget) =>
      oldWidget.pressed != pressed;
}

/// Reports a box at least [minSize] while laying the child out at its natural
/// size, and hit-tests the whole padded box. This is how a 40pt chip gets a
/// 52pt target without a 52pt chip.
/// Reports a box of at least [minSize] while laying its child out naturally.
///
/// This is how a 40pt chip gets a 52pt target without becoming a 52pt chip.
/// SPEC.md §1: the app is used one-handed, at a fuel pump, in the rain.
class CalmTapTarget extends SingleChildRenderObjectWidget {
  /// Creates a target with a size floor.
  const CalmTapTarget({
    required this.minSize,
    required Widget super.child,
    super.key,
  });

  /// The floor. Always `CalmSpace.touchMin` square in practice.
  final Size minSize;

  @override
  RenderCalmTapTarget createRenderObject(BuildContext context) =>
      RenderCalmTapTarget(minSize);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderCalmTapTarget renderObject,
  ) {
    renderObject.minSize = minSize;
  }
}

/// The render object behind [CalmTapTarget].
class RenderCalmTapTarget extends RenderShiftedBox {
  /// Creates the render object.
  RenderCalmTapTarget(this._minSize) : super(null);

  Size _minSize;

  /// The size floor.
  Size get minSize => _minSize;
  set minSize(Size value) {
    if (_minSize == value) return;
    _minSize = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = Size.zero;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(
      Size(
        math.max(child.size.width, minSize.width),
        math.max(child.size.height, minSize.height),
      ),
    );
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      (size - child.size) as Offset,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    if (!size.contains(position)) return false;
    // Anywhere in the padded box counts as a hit on the child's centre.
    final center = child!.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (result, position) => child!.hitTest(result, position: center),
    );
  }
}

/// The ONLY icons in Calm that mirror: back chevron, disclosure chevron,
/// backspace, swap, undo, prev/next. A car, a pump, a wrench, a clock and a
/// check keep one canonical asset in all six locales. Flutter mirrors an Icon
/// only when the font declares `matchTextDirection`, which Calm's 24pt stroke
/// set does not — so flip it explicitly, and never by accident.
/// An icon that mirrors under RTL — and the only kind in Calm that does.
///
/// Six glyphs mirror: the back chevron, the disclosure chevron, backspace,
/// swap, undo and prev/next. A car, a pump, a wrench, a clock and a check keep
/// one canonical asset in all six locales. Flutter mirrors an [Icon] only when
/// the font declares `matchTextDirection`, which Calm's 24pt stroke set does
/// not — so the flip is explicit, and never by accident.
class CalmDirectionalIcon extends StatelessWidget {
  /// Creates a mirroring icon.
  const CalmDirectionalIcon(
    this.icon, {
    required this.size,
    required this.color,
    super.key,
  });

  /// The glyph.
  final IconData icon;

  /// Its size in logical pixels.
  final double size;

  /// Its colour, read from a Calm slot by the caller.
  final Color color;

  @override
  Widget build(BuildContext context) {
    // The glyph is drawn under a forced LTR so Flutter never mirrors it
    // itself. Material's directional icons — backspace_outlined, arrow_back,
    // undo — carry `matchTextDirection: true`, and an Icon that mirrors itself
    // inside a Transform that also mirrors it comes out UNFLIPPED. One flip,
    // decided here, whatever the glyph's own flag says.
    final glyph = Directionality(
      textDirection: TextDirection.ltr,
      child: Icon(icon, size: size, color: color),
    );
    if (Directionality.of(context) != TextDirection.rtl) return glyph;
    return Transform(
      alignment: Alignment.center,
      // scaleByDouble rather than the deprecated scale(): the mirror is a
      // -1 flip on X only, and naming all four components makes that explicit.
      transform: Matrix4.identity()..scaleByDouble(-1, 1, 1, 1),
      child: glyph,
    );
  }
}
