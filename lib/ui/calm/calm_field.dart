// CalmField — a filled 56pt field with an inset ring.
//
// No floating label, no underline, no OutlineInputBorder: the wrapping
// container owns fill, radius, padding and ring, and InputDecoration is fully
// neutralised so Material cannot put a border back in dark mode three sprints
// from now.
//
// This file is one of only two in lib/ui/calm/ allowed to construct a Border —
// the focus/error ring is the single border in the whole system, and
// check_component_hygiene.sh allowlists exactly this filename.
//
// Validators, FormState, focus traversal and keyboard types belong to
// `forms-and-input`; this is the skin.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_pressable.dart' show calmDuration;

/// The glyph on the computed badge: `ƒ`, "Odova worked this one out".
///
/// A symbol, not a sentence — it is the same mark in all six locales, and the
/// words that explain it are [CalmField.computedHint].
const String kCalmComputedBadge = 'ƒ';

/// `.fbadge` — its painted height at 1x, and its minimum width.
///
/// A named constant like every other Calm size, not a bare literal: a bare 19
/// in `lib/ui/calm/` is what check_calm_rejects.sh is looking for, and it is
/// right to look. The badge is decorative and carries no gesture; the 52pt
/// floor is measured on the widgets that do, by getSize, in their own tests.
const double kCalmComputedBadgeSize = 19;

/// The three field heights.
enum CalmFieldSize {
  /// 56pt — `.input`.
  md,

  /// 72pt at `type.hero` — `.input--lg`, the odometer on `log.odometer`.
  lg,

  /// 108pt — `.textarea`.
  multiline,
}

/// A filled field with an inset ring.
class CalmField extends StatefulWidget {
  /// Creates a field.
  const CalmField({
    required this.label,
    required this.controller,
    super.key,
    this.hint,
    this.errorText,
    this.placeholder,
    this.affix,
    this.lead,
    this.size = CalmFieldSize.md,
    this.numeric = false,
    this.computed = false,
    this.computedHint,
    this.enabled = true,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  /// Sits ABOVE the field, not beside it: German `Kraftstoffart` and Sorani
  /// labels blow up a side label, and a stacked one survives 200%.
  final String label;

  /// The text being edited. The caller owns it and disposes it.
  final TextEditingController controller;

  /// The helper line, when there is no error.
  final String? hint;

  /// The error. It REPLACES [hint] in the same slot — two helper lines stack
  /// and move the field below.
  final String? errorText;

  /// The placeholder inside the box.
  final String? placeholder;

  /// Sits on the END edge (the odometer's `km` chip). Mirrors for free, and is
  /// NOT wrapped in an IgnorePointer: on `log.odometer` it is tappable.
  final Widget? affix;

  /// Sits on the START edge (a currency glyph).
  final Widget? lead;

  /// 56 / 72 / 108, all of them minimums.
  final CalmFieldSize size;

  /// Tabular lining figures, semibold — a column of readings that does not
  /// reflow as a digit changes.
  final bool numeric;

  /// A value Odova worked out from two others.
  ///
  /// A real state, not a disabled one: lighter ground plus secondary ink plus
  /// the `ƒ` badge — three signals, never colour alone — and it stays
  /// editable, because typing in it recomputes a sibling.
  final bool computed;

  /// What the `ƒ` badge means, in the user's words ("calculated from the other
  /// two"). Already localised; it reaches a screen reader as the field's hint.
  final String? computedHint;

  /// False draws `bgSunk` with `ink4` text and no ring.
  final bool enabled;

  /// Supplied by the caller when the form owns traversal.
  final FocusNode? focusNode;

  /// Passed straight through.
  final TextInputType? keyboardType;

  /// Passed straight through.
  final TextInputAction? textInputAction;

  /// Passed straight through.
  final List<TextInputFormatter>? inputFormatters;

  /// Fires on every keystroke — but VALIDATION does not. SPEC.md §10: the
  /// check runs on blur and on Save, because `1` is a prefix of `187412`.
  final ValueChanged<String>? onChanged;

  /// Passed straight through.
  final ValueChanged<String>? onSubmitted;

  @override
  State<CalmField> createState() => _CalmFieldState();
}

class _CalmFieldState extends State<CalmField> {
  /// Created only when the caller supplies none, and disposed only if so.
  FocusNode? _ownNode;
  late FocusNode _node;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(CalmField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A form that swaps its focus nodes — or drops one — would otherwise leave
    // this listener on the old node forever, and the field would report the
    // focus of a box that is no longer on screen.
    if (oldWidget.focusNode != widget.focusNode) {
      _node.removeListener(_handleFocusChange);
      _attach();
      if (_focused != _node.hasFocus) {
        setState(() => _focused = _node.hasFocus);
      }
    }
  }

  @override
  void dispose() {
    _node.removeListener(_handleFocusChange);
    _ownNode?.dispose();
    super.dispose();
  }

  void _attach() {
    _node = widget.focusNode ?? (_ownNode ??= FocusNode());
    _node.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focused != _node.hasFocus) setState(() => _focused = _node.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final motion = CalmMotion.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    final hasError = widget.errorText != null;

    // Three (ring, fill, width) pairs, and nothing else changes.
    final (Color ring, Color fill, double ringWidth) = switch ((
      widget.enabled,
      hasError,
      _focused,
    )) {
      (false, _, _) => (Colors.transparent, colors.bgSunk, 0.0),
      // One of the two allowed direct ramp reads: the error state is fixed
      // when this widget is written, never resolved from a DueState.
      (_, true, _) => (colors.overdue.base, colors.overdue.tint, 2.0),
      (_, false, true) => (colors.brand, colors.surface, 2.0),
      _ => (
        Colors.transparent,
        widget.computed ? colors.bgSunk : colors.surface2,
        1.5,
      ),
    };

    final minHeight = switch (widget.size) {
      CalmFieldSize.md => 56.0,
      CalmFieldSize.lg => 72.0,
      CalmFieldSize.multiline => 108.0,
    };

    final baseStyle = widget.size == CalmFieldSize.lg ? type.hero : type.bodyLg;
    final textStyle = baseStyle.copyWith(
      color: widget.enabled
          ? (widget.computed ? colors.ink2 : colors.ink)
          : colors.ink4,
      fontWeight: switch (widget.size) {
        CalmFieldSize.multiline => type.regular,
        _ =>
          widget.numeric || widget.size == CalmFieldSize.lg
              ? type.semi
              : type.medium,
      },
      // `.input` sets its own line-height: 1.4, and `.input--lg` 1.1 — tighter
      // than the type role's, and the difference is exactly what makes 56pt
      // land on 56 instead of 58.
      height: widget.size == CalmFieldSize.lg ? 1.1 : 1.4,
      fontFeatures: widget.numeric
          // Tabular lining figures so a column of readings aligns and a digit
          // change does not reflow the string.
          ? const [FontFeature.tabularFigures(), FontFeature.liningFigures()]
          : null,
    );

    // `.inputgroup` reserves 76pt of end padding for the affix and 56pt of
    // start padding for the lead. The ring is painted INSIDE the box
    // (BoxDecoration borders deflate the child), so subtract it from the
    // padding to keep the height identical across rest, focus and error.
    final padStart = (widget.lead == null ? space.s5 : 56.0) - ringWidth;
    final padEnd = (widget.affix == null ? space.s5 : 76.0) - ringWidth;
    final padBlock = space.s4 - ringWidth;

    // One node, not four. A screen reader that reads label, box, hint and
    // error as four stops in layout order is a screen reader that reads the
    // error after the user has already moved on.
    return MergeSemantics(
      child: Semantics(
        label: widget.label,
        // The error rides the HINT, not the value. MergeSemantics absorbs the
        // TextField's own configuration, and SemanticsConfiguration.absorb
        // CONCATENATES value strings — so an error in `value` fused with the
        // typed text, and a user editing the odometer heard a stale error
        // string every time the value was re-announced.
        hint: [
          if (widget.errorText != null) widget.errorText!,
          if (widget.computed && widget.computedHint != null)
            widget.computedHint!
          else if (widget.hint != null)
            widget.hint!,
        ].join('. '),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: space.s1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.label,
                        style: type.label.copyWith(
                          color: colors.ink2,
                          fontWeight: type.semi,
                        ),
                      ),
                    ),
                    if (widget.computed) ...[
                      SizedBox(width: space.s1),
                      const _CalmComputedBadge(),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: space.s2),
            Stack(
              children: [
                AnimatedContainer(
                  duration: calmDuration(context, motion.quick),
                  curve: motion.easeOut,
                  constraints: BoxConstraints(minHeight: minHeight),
                  padding: EdgeInsetsDirectional.fromSTEB(
                    padStart,
                    padBlock,
                    padEnd,
                    padBlock,
                  ),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(shapes.radiusLg),
                    border: Border.all(color: ring, width: ringWidth),
                  ),
                  // TextField needs a Material ancestor for its selection
                  // handles and its ink host. TRANSPARENT: it paints nothing,
                  // has no elevation, and gives the field what Flutter
                  // requires without putting a Material surface under a Calm
                  // one. Without it every CalmField outside a Scaffold throws
                  // "No Material widget found".
                  child: Material(
                    type: MaterialType.transparency,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _node,
                      enabled: widget.enabled,
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      inputFormatters: widget.inputFormatters,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      maxLines: widget.size == CalmFieldSize.multiline
                          ? null
                          : 1,
                      minLines: widget.size == CalmFieldSize.multiline ? 4 : 1,
                      style: textStyle,
                      cursorColor: colors.brand,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        counterText: '',
                        hintText: widget.placeholder,
                        hintStyle: textStyle.copyWith(
                          color: colors.ink4,
                          fontWeight: type.regular,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.lead != null)
                  PositionedDirectional(
                    start: space.s5,
                    top: 0,
                    bottom: 0,
                    child: Center(child: IgnorePointer(child: widget.lead)),
                  ),
                if (widget.affix != null)
                  PositionedDirectional(
                    end: space.s5,
                    top: 0,
                    bottom: 0,
                    // NOT wrapped in IgnorePointer: on the odometer field the
                    // unit affix is a tappable chip that switches the unit for
                    // this entry only (SPEC.md §10).
                    child: Center(child: widget.affix),
                  ),
              ],
            ),
            // Excluded like the label above it: the error reaches a screen
            // reader as the node's VALUE, and leaving it as a Text as well
            // makes it part of the label — "Odometer, Lower than the last
            // reading" as the field's name.
            if (hasError)
              ExcludeSemantics(
                child: _CalmFieldMessage(
                  text: widget.errorText!,
                  // The error voice is the same confident terracotta as an
                  // overdue item. `danger` is reserved for destructive ACTIONS.
                  color: colors.overdue.ink,
                  icon: Icons.error_outline,
                  bold: true,
                ),
              )
            else if (widget.hint != null)
              ExcludeSemantics(
                child: _CalmFieldMessage(
                  text: widget.hint!,
                  color: colors.ink3,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// `.fbadge` — a 19pt italic pill beside the label of a computed field.
class _CalmComputedBadge extends StatelessWidget {
  const _CalmComputedBadge();

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final type = CalmType.of(context);

    final glyph = type.caption.copyWith(
      color: colors.ink2,
      fontWeight: type.semi,
      fontStyle: FontStyle.italic,
    );
    // `.fbadge` is 19px tall at 1x. Expressed as PADDING derived from the type
    // metrics rather than as a minHeight, for two reasons: a height floor on a
    // 19pt box does nothing except clip the glyph at 200% text scale, and a
    // `minHeight:` literal below 52 is what check_touch_targets.sh exists to
    // find. It cannot tell a decorative badge from a control, and it should
    // not have to.
    // Clamped at zero. CalmType.arabicScript raises the leading so Persian
    // ascenders are not clipped, which makes the caption line box TALLER than
    // the 19pt badge — and a negative EdgeInsets asserts on the first fa
    // frame. The badge simply grows there, which is the right answer.
    final padBlock = math.max<double>(
      0,
      (kCalmComputedBadgeSize - glyph.fontSize! * glyph.height!) / 2,
    );

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.surface3,
        shape: const StadiumBorder(),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: kCalmComputedBadgeSize),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: 4,
            vertical: padBlock,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(kCalmComputedBadge, style: glyph),
          ),
        ),
      ),
    );
  }
}

class _CalmFieldMessage extends StatelessWidget {
  const _CalmFieldMessage({
    required this.text,
    required this.color,
    this.icon,
    this.bold = false,
  });

  final String text;
  final Color color;
  final IconData? icon;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(space.s1, space.s2, 0, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            SizedBox(width: space.s1),
          ],
          Expanded(
            child: Text(
              text,
              style: type.caption.copyWith(
                color: color,
                fontWeight: bold ? type.medium : type.regular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
