// CalmSnackbar — the only "are you sure" logging gets.
//
// SPEC.md §10: confirmation is a snackbar with Undo, never a dialog. It sits
// above the tab bar and the home indicator so it never covers the +, it routes
// through ScaffoldMessenger so it survives a route change, and there is never
// more than one on screen.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_scaffold.dart' show calmSnackbarBottomInset;

/// The bar itself.
class CalmSnackbar extends StatelessWidget {
  /// Creates a snackbar body.
  const CalmSnackbar({
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
    this.danger = false,
  });

  /// One plain sentence, already localised.
  final String message;

  /// Practically always Undo.
  final String? actionLabel;

  /// What it does.
  final VoidCallback? onAction;

  /// A destructive confirmation. One of the three sanctioned direct reads of a
  /// state slot: it is fixed when this widget is written, never resolved from
  /// a DueState.
  final bool danger;

  /// Shows [message] with an optional action.
  ///
  /// Clears whatever is already on screen first: a second Undo beside the
  /// first is two undos with no way to tell which is which.
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    bool danger = false,
    Duration? duration,
  }) => CalmSnackbarHost.of(context).show(
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
    danger: danger,
    duration: duration,
  );

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: danger ? colors.danger : colors.surfaceInverse,
        shadows: shapes.elev3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapes.radiusXl),
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          space.s5,
          space.s4,
          space.s3,
          space.s4,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: type.body.copyWith(color: colors.inkInverse),
              ),
            ),
            if (actionLabel != null) ...[
              SizedBox(width: space.s3),
              CalmPressable(
                onTap: onAction,
                borderRadius: shapes.radiusPill,
                pressScale: kCalmPressScaleChip,
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: space.s3,
                    vertical: space.s2,
                  ),
                  child: Text(
                    actionLabel!,
                    // inkInverse, NOT brand. `--color-brand` on
                    // `--color-surface-inverse` is 2.28:1 in light and 1.85:1
                    // in dark — the action would be the least legible thing on
                    // it. Weight and the pill target carry the affordance
                    // until a `brand-on-inverse` slot exists.
                    style: type.body.copyWith(
                      color: colors.inkInverse,
                      fontWeight: type.semi,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Everything a snackbar needs, captured before an await.
///
/// [CalmSnackbar.show] resolves the messenger, the tokens and the bottom inset
/// from the caller's context, which is right when nothing has happened yet and
/// wrong the moment the caller awaits something that unmounts it. A row that
/// has just been sold or deleted is exactly that: the list re-emits, the
/// element goes, and a `context.mounted` guard then skips the confirmation —
/// or, worse, the Undo that SPEC.md §8 calls the entire recovery window.
///
/// So this holds VALUES, not a context. The messenger outlives any one screen;
/// the space, the window and the inset are read where the CALLER stands,
/// because the inset in particular depends on what is under the caller — a tab
/// bar and a home indicator are 108pt that the messenger, sitting above the
/// shell, cannot see.
@immutable
class CalmSnackbarHost {
  const CalmSnackbarHost._(
    this._messenger,
    this._inlineInset,
    this._bottomInset,
    this._window,
  );

  /// Captures what [context] can see, while it can still see it.
  factory CalmSnackbarHost.of(BuildContext context) => CalmSnackbarHost._(
    ScaffoldMessenger.of(context),
    CalmSpace.of(context).s5,
    calmSnackbarBottomInset(context),
    CalmMotion.of(context).undoWindow,
  );

  final ScaffoldMessengerState _messenger;
  final double _inlineInset;
  final double _bottomInset;
  final Duration _window;

  /// Shows [message] with an optional action.
  ///
  /// Clears whatever is already on screen first: a second Undo beside the first
  /// is two undos with no way to tell which is which.
  void show({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    bool danger = false,
    Duration? duration,
  }) {
    _messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: CalmSnackbar(
            message: message,
            actionLabel: actionLabel,
            onAction: onAction,
            danger: danger,
          ),
          // NOT calmDuration: a user who asked for stillness did not ask for
          // less time to undo.
          duration: duration ?? _window,
          behavior: SnackBarBehavior.floating,
          // The bar paints itself; Material paints nothing.
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: EdgeInsetsDirectional.fromSTEB(
            _inlineInset,
            0,
            _inlineInset,
            _bottomInset,
          ),
        ),
      );
  }
}
