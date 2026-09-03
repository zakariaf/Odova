// CalmNumberPad — the odometer's keyboard.
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
import 'package:odova/ui/calm/calm_pressable.dart';

/// `.numpad__key { min-height: 68px }`.
const double kCalmNumpadKeyHeight = 68;

/// The default glyphs: Western Arabic, for `en`, `de` and `fr`.
///
/// `fa`, `ar` and `ckb` pass their own through [CalmNumberPad.digits]. The
/// mapping from a locale to a numbering system is EPIC-04's; this widget only
/// draws what it is handed.
const List<String> kCalmNumpadLatinDigits = [
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
];

/// What a key is for.
enum CalmKeyKind {
  /// `surface` on `elev1`, `type.titleLg` medium, tabular lining figures.
  digit,

  /// Flat `surface2`/`ink2` — backspace, the decimal separator, clear.
  action,

  /// `brand`/`onBrand` on `elev1`, spanning two columns.
  confirm,
}

/// The odometer keypad.
class CalmNumberPad extends StatelessWidget {
  /// Creates the pad.
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
    this.digits,
  });

  /// Already formatted in the active numbering system and grouping — the pad
  /// renders a string, it does not do arithmetic.
  final String value;

  /// `km` or `mi`, already localised.
  final String unit;

  /// The delta line that catches a dropped digit: `+432 km since 12 Mar`.
  final String hint;

  /// Ten glyphs, `0` first. Defaults to [kCalmNumpadLatinDigits].
  final List<String>? digits;

  /// Reports the ASCII digit whatever glyph was drawn, so the caller never
  /// parses a Persian numeral back out of its own keypad.
  final ValueChanged<String> onDigit;

  /// The decimal separator key.
  final VoidCallback onDecimal;

  /// Backspace.
  final VoidCallback onBackspace;

  /// Confirm.
  final VoidCallback onConfirm;

  /// The confirm key's label, already localised.
  final String confirmLabel;

  /// The decimal separator, which is `,` in de and fr and `٫` in fa.
  final String decimalLabel;

  /// The secondary action's label.
  final String secondaryLabel;

  /// What it does.
  final VoidCallback onSecondary;

  /// Backspace carries a glyph and no text, so it needs a spoken name.
  final String backspaceSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);
    final glyphs = digits ?? kCalmNumpadLatinDigits;
    assert(glyphs.length == 10, 'Ten glyphs, 0 first.');
    // The direction the SCREEN is in. The grid below is forced to LTR, but the
    // backspace glyph still has to point the way the user reads.
    final outer = Directionality.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The display mirrors: `+432 km since 12 Mar` is a sentence.
        CalmNumberPadDisplay(value: value, unit: unit, hint: hint),
        SizedBox(height: space.s5),
        // The GRID does not. Digit order is not a reading order; it is a
        // machine every user has already learned, and 1-2-3 reversed is a
        // keypad that gives the wrong odometer.
        Directionality(
          textDirection: TextDirection.ltr,
          child: _grid(context, glyphs, outer),
        ),
      ],
    );
  }

  Widget _grid(BuildContext context, List<String> glyphs, TextDirection outer) {
    final space = CalmSpace.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row(context, glyphs, const [1, 2, 3]),
        SizedBox(height: space.s3),
        _row(context, glyphs, const [4, 5, 6]),
        SizedBox(height: space.s3),
        _row(context, glyphs, const [7, 8, 9]),
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
                label: glyphs[0],
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
                iconDirection: outer,
              ),
            ),
          ],
        ),
        SizedBox(height: space.s3),
        // `.numpad__key--wide { grid-column: span 2 }` — two columns PLUS the
        // gutter it swallows. `Expanded(flex: 2)` is NOT that: flex splits the
        // space left after ONE gutter, where the rows above split what is left
        // after two, so the confirm key comes out 4pt narrow and fails to line
        // up with the keys above it. The column width is computed instead.
        LayoutBuilder(
          builder: (context, constraints) {
            final column = (constraints.maxWidth - space.s3 * 2) / 3;
            return Row(
              children: [
                SizedBox(
                  width: column * 2 + space.s3,
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
            );
          },
        ),
      ],
    );
  }

  Widget _row(BuildContext context, List<String> glyphs, List<int> row) {
    final space = CalmSpace.of(context);
    return Row(
      children: [
        for (final digit in row) ...[
          if (digit != row.first) SizedBox(width: space.s3),
          Expanded(
            child: CalmNumberPadKey(
              kind: CalmKeyKind.digit,
              label: glyphs[digit],
              onTap: () => onDigit('$digit'),
            ),
          ),
        ],
      ],
    );
  }
}

/// The value, its unit and the delta hint, on a `surface2` block.
class CalmNumberPadDisplay extends StatelessWidget {
  /// Creates the display.
  const CalmNumberPadDisplay({
    required this.value,
    required this.unit,
    required this.hint,
    super.key,
  });

  /// The formatted value.
  final String value;

  /// Its unit.
  final String unit;

  /// The delta line.
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapes.radius2xl),
        ),
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
              maxLines: 1,
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
              style: type.body.copyWith(
                color: colors.ink3,
                fontWeight: type.medium,
              ),
            ),
            Text(hint, style: type.caption.copyWith(color: colors.ink3)),
          ],
        ),
      ),
    );
  }
}

/// One key.
class CalmNumberPadKey extends StatelessWidget {
  /// Creates a key.
  const CalmNumberPadKey({
    required this.kind,
    required this.onTap,
    super.key,
    this.label,
    this.icon,
    this.semanticLabel,
    this.iconDirection,
  });

  /// What it is for.
  final CalmKeyKind kind;

  /// What it does.
  final VoidCallback onTap;

  /// The glyph or word it draws.
  final String? label;

  /// A glyph instead of a word. Backspace is the only one, and it mirrors.
  final IconData? icon;

  /// Overrides [label] for a screen reader.
  final String? semanticLabel;

  /// The direction [icon] mirrors against.
  ///
  /// Supplied explicitly because the grid around it is forced to LTR: the
  /// keypad does not mirror, and the backspace arrow does.
  final TextDirection? iconDirection;

  @override
  Widget build(BuildContext context) {
    final shapes = CalmShapes.of(context);

    return CalmPressable(
      onTap: onTap,
      borderRadius: shapes.radiusXl,
      pressScale: kCalmPressScaleKey, // .96 — a big slab needs a big give
      // The key's own Text carries the label, so declaring it here too would
      // announce "5, 5". An icon key has no text of its own and needs one.
      semanticLabel: label == null ? semanticLabel : null,
      child: _CalmNumberPadKeyBody(
        kind: kind,
        label: label,
        icon: icon,
        iconDirection: iconDirection,
      ),
    );
  }
}

class _CalmNumberPadKeyBody extends StatelessWidget {
  const _CalmNumberPadKeyBody({
    required this.kind,
    required this.label,
    required this.icon,
    required this.iconDirection,
  });

  final CalmKeyKind kind;
  final String? label;
  final IconData? icon;
  final TextDirection? iconDirection;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final motion = CalmMotion.of(context);
    final shapes = CalmShapes.of(context);
    final type = CalmType.of(context);
    final pressed = CalmPressState.of(context);

    final (
      Color background,
      Color foreground,
      List<BoxShadow> shadow,
    ) = switch (kind) {
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
      decoration: ShapeDecoration(
        color: pressed ? colors.surface3 : background, // .numpad__key:active
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapes.radiusXl),
        ),
        shadows: pressed ? shapes.elev0 : shadow,
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Directionality(
              textDirection: iconDirection ?? Directionality.of(context),
              child: CalmDirectionalIcon(icon!, size: 24, color: foreground),
            )
          : Text(label!, style: textStyle, maxLines: 1),
    );
  }
}
