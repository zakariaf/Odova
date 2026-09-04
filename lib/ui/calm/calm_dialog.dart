// CalmDialog — reserved, deliberately.
//
// SPEC.md §10: confirmation is a snackbar with Undo, not a dialog. A dialog is
// paid for on every CORRECT entry, so Calm has exactly three: discarding a
// dirty form, confirming a delete that names what dies, and deleting a vehicle.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_overlay_transition.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

/// The dialog's icon disc.
const double kCalmDialogIconSize = 56;

/// It scales up from 0.96, not from 0.8: a big pop reads as an alarm.
const double kCalmDialogScaleFrom = 0.96;

/// One of Calm's three dialogs.
class CalmDialog extends StatelessWidget {
  /// Creates a two-action dialog: the confirming action, then the way out.
  ///
  /// The order is the widget's, not the caller's, so a user who has learned
  /// where the way out is on one dialog has learned it on all of them. A dialog
  /// that offers a safe ALTERNATIVE — something that does a different thing
  /// rather than nothing — needs three actions and uses [CalmDialog.actions].
  const CalmDialog({
    required this.title,
    required this.body,
    required String this.confirmLabel,
    required VoidCallback this.onConfirm,
    required String this.cancelLabel,
    required VoidCallback this.onCancel,
    super.key,
    this.icon,
    this.danger = false,
  }) : actions = null;

  /// Creates a dialog whose actions the caller orders.
  ///
  /// For the dialogs whose reference offers a safe alternative. All three
  /// references in `design/reference/calm/` order their actions **safe first**:
  /// *Keep editing* above *Discard*, and *Keep it — mark it sold* above
  /// *Delete* above *Cancel*. `calm-components` said "destructive first"; the
  /// reference is the authority (`calm-visual-parity` rule 1) and SPEC.md §7's
  /// "no dialog is ever dismissed into a destructive outcome" points the same
  /// way. The skill is amended to match (EPIC-08 finding F-8.4).
  ///
  /// The dialog still owns the STACKING and the gaps — full width, one under
  /// another, never a row. A row of two puts the destructive action under the
  /// thumb that was reaching for the other one.
  const CalmDialog.actions({
    required this.title,
    required this.body,
    required List<Widget> this.actions,
    super.key,
    this.icon,
    this.danger = false,
  }) : confirmLabel = null,
       onConfirm = null,
       cancelLabel = null,
       onCancel = null;

  /// The question, already localised.
  final String title;

  /// One or two plain sentences.
  final String body;

  /// The destructive or confirming action's label.
  ///
  /// Null on [CalmDialog.actions].
  final String? confirmLabel;

  /// What it does.
  final VoidCallback? onConfirm;

  /// The way out.
  final String? cancelLabel;

  /// What that does.
  final VoidCallback? onCancel;

  /// The caller's own actions, in the order they are shown.
  ///
  /// Null on the two-action constructor, which builds its own pair.
  final List<Widget>? actions;

  /// An optional glyph in a 56pt disc above the title.
  final IconData? icon;

  /// Draws the disc and the confirming action in the destructive palette.
  final bool danger;

  /// Opens a dialog.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    final colors = CalmColors.of(context);
    final motion = CalmMotion.of(context);

    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: colors.scrim,
      transitionDuration: calmDuration(context, motion.base),
      pageBuilder: (context, _, _) => builder(context),
      // The identity transition, on purpose. RawDialogRoute's default is a
      // linear FadeTransition, and CalmOverlayTransition already fades — the
      // two multiply, so the dialog's effective opacity was t squared: an
      // ease-in nobody chose, on top of a duration that is supposed to be
      // easeStandard.
      transitionBuilder: (context, _, _, child) => child,
    );
  }

  /// What to stack, whichever constructor was used.
  List<Widget> get _actions =>
      actions ??
      [
        CalmButton(
          label: confirmLabel!,
          onPressed: onConfirm,
          variant: danger
              ? CalmButtonVariant.dangerSolid
              : CalmButtonVariant.primary,
          block: true,
        ),
        CalmButton(
          label: cancelLabel!,
          onPressed: onCancel,
          variant: CalmButtonVariant.tonal,
          block: true,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final motion = CalmMotion.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return CalmOverlayTransition(
      rise: 0,
      scaleFrom: kCalmDialogScaleFrom,
      fadeFrom: 0,
      curve: motion.easeSettle,
      reverseCurve: motion.easeIn,
      child: Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(space.s6),
          // An overlay route has no Material above it, and `WidgetsApp`'s
          // fallback `DefaultTextStyle` for that case is 48pt bold red
          // monospace with a double yellow underline — an error style meant to
          // be unmissable. It is not, here: every `Text` below sets its size
          // and colour from `CalmType`, which overrides all of that except the
          // one part it never sets, the FAMILY. So without this the dialog came
          // out the right size, in the right colour, in monospace, and nothing
          // went red. The parity capture is what noticed.
          //
          // `transparency`, because the dialog paints its own surface below.
          child: Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: colors.surface,
                shadows: shapes.elev4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(shapes.radius3xl),
                ),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  space.s6,
                  space.s7,
                  space.s6,
                  space.s6,
                ),
                child: Column(
                  // start, not centre: centred body copy is unreadable at
                  // Sorani line lengths.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _CalmDialogIcon(icon: icon!, danger: danger),
                      ),
                      SizedBox(height: space.s4),
                    ],
                    Text(
                      title,
                      textAlign: TextAlign.start,
                      style: type.title.copyWith(
                        color: colors.ink,
                        fontWeight: type.semi,
                      ),
                    ),
                    SizedBox(height: space.s2),
                    Text(
                      body,
                      textAlign: TextAlign.start,
                      style: type.bodyLg.copyWith(color: colors.ink2),
                    ),
                    SizedBox(height: space.s6),
                    // Stacked and full width. A row of two puts the
                    // destructive action under the thumb that was reaching
                    // for the other one.
                    for (final (index, action) in _actions.indexed) ...[
                      if (index > 0) SizedBox(height: space.s3),
                      action,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalmDialogIcon extends StatelessWidget {
  const _CalmDialogIcon({required this.icon, required this.danger});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);

    return SizedBox.square(
      dimension: kCalmDialogIconSize,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: danger ? colors.dangerTint : colors.brandSoft,
          shape: const CircleBorder(),
        ),
        child: Icon(
          icon,
          size: 26,
          color: danger ? colors.danger : colors.brandSoftInk,
        ),
      ),
    );
  }
}
