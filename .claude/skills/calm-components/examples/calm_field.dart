// CalmField — lib/ui/calm/calm_field.dart
//
// A filled 56pt field with an inset ring. No floating label, no underline, no
// OutlineInputBorder: the wrapping container owns fill, radius, padding and
// ring, and InputDecoration is fully neutralised so Material cannot put a
// border back in dark mode three sprints from now.
//
// This file is the ONLY place in lib/ui/calm/ allowed to construct a Border —
// the focus/error ring is the single border in the whole system, and
// scripts/check_component_hygiene.sh allowlists exactly this filename.
//
// Validators, FormState, focus traversal and keyboard types belong to
// `forms-and-input`; this is the skin.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_pressable.dart' show calmDuration;

enum CalmFieldSize {
  /// 56pt — .input
  md,

  /// 72pt at --fs-hero — .input--lg, the odometer on log.odometer
  lg,

  /// 108pt — .textarea
  multiline,
}

class CalmField extends StatefulWidget {
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
    this.enabled = true,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;

  /// Hint and error share one slot; the error replaces the hint.
  final String? hint;
  final String? errorText;
  final String? placeholder;

  /// Sits on the END edge (the odometer's `km ▾` chip). Mirrors for free.
  final Widget? affix;

  /// Sits on the START edge (a currency glyph).
  final Widget? lead;

  final CalmFieldSize size;
  final bool numeric;

  /// A value Odova worked out from two others (fill-up total / litres / price).
  /// Lighter ground + secondary ink + the ƒ badge: three signals, and it stays
  /// editable, because typing in it recomputes a sibling.
  final bool computed;

  final bool enabled;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;

  @override
  State<CalmField> createState() => _CalmFieldState();
}

class _CalmFieldState extends State<CalmField> {
  late final FocusNode _node = widget.focusNode ?? FocusNode();
  late final bool _ownsNode = widget.focusNode == null;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _node.removeListener(_handleFocusChange);
    if (_ownsNode) _node.dispose();
    super.dispose();
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
      // One of the two allowed direct ramp reads: the error state is fixed when
      // this widget is written, never resolved from a DueState.
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
        _ => widget.numeric || widget.size == CalmFieldSize.lg
            ? type.semi
            : type.medium,
      },
      fontFeatures: widget.numeric
          // Tabular lining figures so a column of readings aligns and a digit
          // change does not reflow the string.
          ? const [FontFeature.tabularFigures(), FontFeature.liningFigures()]
          : null,
    );

    // .inputgroup reserves 76pt of end padding for the affix, 56pt of start
    // padding for the lead. The ring is painted INSIDE the box (BoxDecoration
    // borders deflate the child), so subtract it from the padding to keep the
    // 56pt height identical across rest, focus and error.
    final padStart = (widget.lead == null ? space.s5 : 56.0) - ringWidth;
    final padEnd = (widget.affix == null ? space.s5 : 76.0) - ringWidth;
    final padBlock = space.s4 - ringWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: space.s1),
          child: Text(
            widget.label,
            style: type.label
                .copyWith(color: colors.ink2, fontWeight: type.semi),
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
              child: TextField(
                controller: widget.controller,
                focusNode: _node,
                enabled: widget.enabled,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                inputFormatters: widget.inputFormatters,
                onSubmitted: widget.onSubmitted,
                maxLines: widget.size == CalmFieldSize.multiline ? null : 1,
                minLines: widget.size == CalmFieldSize.multiline ? 4 : 1,
                style: textStyle,
                cursorColor: colors.brand,
                textAlign: TextAlign.start,
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
                // NOT wrapped in IgnorePointer: on the odometer field the unit
                // affix is a tappable chip that switches the unit for this
                // entry only (SPEC.md §10).
                child: Center(child: widget.affix),
              ),
          ],
        ),
        if (hasError)
          _CalmFieldMessage(
            text: widget.errorText!,
            // The error voice is the same confident terracotta as an overdue
            // item. `danger` is reserved for destructive ACTIONS.
            color: colors.overdue.ink,
            icon: Icons.error_outline,
            bold: true,
          )
        else if (widget.hint != null)
          _CalmFieldMessage(text: widget.hint!, color: colors.ink3),
      ],
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
