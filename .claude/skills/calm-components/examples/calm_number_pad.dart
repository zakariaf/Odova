// CalmNumberPad — lib/ui/calm/calm_number_pad.dart
//
// The odometer is the one number that keeps every projection honest (SPEC.md
// §1) and it gets typed at a pump, one-handed, in the rain. The OS numeric
// keyboard puts its digits at the TOP of a full-width keyboard — past the far
// end of a thumb's arc on a large phone — at ~40pt, in whatever digit shapes
// the keyboard's own locale picked, with no room for the unit chip or the
// "+432 km since 12 Mar" delta that catches a dropped digit.
//
// So Calm ships its own: 3 columns, 68pt keys, in the bottom third, with the
// value still visible above it at --fs-display.
//
// The GRID DOES NOT MIRROR. Digit order is fixed in every locale; a mirrored
// keypad is a wrong keypad. Only the backspace glyph flips.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_pressable.dart'
    show
        CalmDirectionalIcon,
        CalmPressState,
        CalmPressable,
        calmDuration,
        kCalmPressScaleKey;

const double kCalmNumpadKeyHeight = 68; // .numpad__key { min-height: 68px }

enum CalmKeyKind { digit, action, confirm }

class CalmNumberPad extends StatelessWidget {
  const CalmNumberPad({
    required this.value,
    required this.unit,
    required this.hint,
    required this.onDigit,
    required this.onDecimal,
    required this.onBackspace,
    required this.onConfirm,
    required this.confirmLabel,
    required this.decimalLabel,
    required this.secondaryLabel,
    required this.onSecondary,
    required this.backspaceSemanticLabel,
    super.key,
  });

  /// Already formatted in the active numbering system and grouping — the pad
  /// renders a string, it does not do arithmetic. See `calm-typography-and-rtl`.
  final String value;
  final String unit;
  final String hint;

  final ValueChanged<String> onDigit;
  final VoidCallback onDecimal;
  final VoidCallback onBackspace;
  final VoidCallback onConfirm;

  final String confirmLabel;
  final String decimalLabel;
  final String secondaryLabel;
  final VoidCallback onSecondary;
  final String backspaceSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CalmNumpadDisplay(value: value, unit: unit, hint: hint),
        SizedBox(height: space.s5),
        _row(context, ['1', '2', '3']),
        SizedBox(height: space.s3),
        _row(context, ['4', '5', '6']),
        SizedBox(height: space.s3),
        _row(context, ['7', '8', '9']),
        SizedBox(height: space.s3),
        Row(
          children: [
            Expanded(
              child: CalmNumberPadKey(
                kind: CalmKeyKind.action,
                label: decimalLabel,
                onTap: onDecimal,
              ),
            ),
            SizedBox(width: space.s3),
            Expanded(
              child: CalmNumberPadKey(
                kind: CalmKeyKind.digit,
                label: '0',
                onTap: () => onDigit('0'),
              ),
            ),
            SizedBox(width: space.s3),
            Expanded(
              child: CalmNumberPadKey(
                kind: CalmKeyKind.action,
                semanticLabel: backspaceSemanticLabel,
                onTap: onBackspace,
                icon: Icons.backspace_outlined, // one of the six that mirrors
              ),
            ),
          ],
        ),
        SizedBox(height: space.s3),
        Row(
          children: [
            // .numpad__key--wide { grid-column: span 2 } — plus the gutter it
            // swallows, so the confirm key lines up with the two above it.
            Expanded(
              flex: 2,
              child: CalmNumberPadKey(
                kind: CalmKeyKind.confirm,
                label: confirmLabel,
                onTap: onConfirm,
              ),
            ),
            SizedBox(width: space.s3),
            Expanded(
              child: CalmNumberPadKey(
                kind: CalmKeyKind.action,
                label: secondaryLabel,
                onTap: onSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(BuildContext context, List<String> digits) {
    final space = CalmSpace.of(context);
    return Row(
      children: [
        for (final digit in digits) ...[
          if (digit != digits.first) SizedBox(width: space.s3),
          Expanded(
            child: CalmNumberPadKey(
              kind: CalmKeyKind.digit,
              label: digit,
              onTap: () => onDigit(digit),
            ),
          ),
        ],
      ],
    );
  }
}

class _CalmNumpadDisplay extends StatelessWidget {
  const _CalmNumpadDisplay({
    required this.value,
    required this.unit,
    required this.hint,
  });

  final String value;
  final String unit;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(shapes.radius2xl),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: space.s5,
          vertical: space.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: type.display.copyWith(
                color: colors.ink,
                fontWeight: type.semi,
                fontFeatures: const [
                  FontFeature.tabularFigures(),
                  FontFeature.liningFigures(),
                ],
              ),
            ),
            SizedBox(height: space.s1),
            Text(
              unit,
              style: type.body
                  .copyWith(color: colors.ink3, fontWeight: type.medium),
            ),
            Text(hint, style: type.caption.copyWith(color: colors.ink3)),
          ],
        ),
      ),
    );
  }
}

class CalmNumberPadKey extends StatelessWidget {
  const CalmNumberPadKey({
    required this.kind,
    required this.onTap,
    super.key,
    this.label,
    this.icon,
    this.semanticLabel,
  });

  final CalmKeyKind kind;
  final VoidCallback onTap;
  final String? label;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shapes = CalmShapes.of(context);

    return CalmPressable(
      onTap: onTap,
      borderRadius: shapes.radiusXl,
      pressScale: kCalmPressScaleKey, // .96 — a big slab needs a big give
      semanticLabel: semanticLabel ?? label,
      child: _CalmNumberPadKeyBody(kind: kind, label: label, icon: icon),
    );
  }
}

class _CalmNumberPadKeyBody extends StatelessWidget {
  const _CalmNumberPadKeyBody({
    required this.kind,
    required this.label,
    required this.icon,
  });

  final CalmKeyKind kind;
  final String? label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final motion = CalmMotion.of(context);
    final shapes = CalmShapes.of(context);
    final type = CalmType.of(context);
    final pressed = CalmPressState.of(context);

    final (Color background, Color foreground, List<BoxShadow> shadow) =
        switch (kind) {
      CalmKeyKind.digit => (colors.surface, colors.ink, shapes.elev1),
      CalmKeyKind.action => (colors.surface2, colors.ink2, shapes.elev0),
      CalmKeyKind.confirm => (colors.brand, colors.onBrand, shapes.elev1),
    };

    final textStyle = switch (kind) {
      CalmKeyKind.digit => type.titleLg.copyWith(
          color: foreground,
          fontWeight: type.medium,
          fontFeatures: const [
            FontFeature.tabularFigures(),
            FontFeature.liningFigures(),
          ],
        ),
      _ => type.bodyLg.copyWith(color: foreground, fontWeight: type.semi),
    };

    return AnimatedContainer(
      duration: calmDuration(context, motion.instant), // --dur-instant, 90ms
      curve: motion.easeOut,
      height: kCalmNumpadKeyHeight,
      decoration: BoxDecoration(
        color: pressed ? colors.surface3 : background, // .numpad__key:active
        borderRadius: BorderRadius.circular(shapes.radiusXl),
        boxShadow: pressed ? shapes.elev0 : shadow,
      ),
      alignment: Alignment.center,
      child: icon != null
          ? CalmDirectionalIcon(icon!, size: 24, color: foreground)
          : Text(label ?? '', style: textStyle, maxLines: 1),
    );
  }
}
