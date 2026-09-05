// "Couldn't save. Your phone may be out of space." with a Retry.
//
// SPEC.md §8 gives BOTH first-run screens the same Error state — "Only a disk
// write can fail" — and the same recovery. It lived inside
// `first_run_vehicle_screen.dart` while `firstrun.language` showed nothing at
// all: the notifier set `failed`, no widget watched it, and a user on a full
// disk tapped Continue forever with no message, no spinner and no error.
//
// Shared between the two screens of one feature, so no layer is crossed.
import 'package:flutter/material.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_button.dart';

/// The disk-write failure both first-run screens can hit.
class FirstRunSaveFailure extends StatelessWidget {
  /// Creates the failure block.
  const FirstRunSaveFailure({required this.onRetry, super.key});

  /// Tries the write again.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: space.s2,
      children: [
        Text(
          l10n.saveDiskFullError,
          textAlign: TextAlign.center,
          style: type.caption.copyWith(color: colors.danger),
        ),
        CalmButton(
          label: l10n.commonRetry,
          variant: CalmButtonVariant.tonal,
          size: CalmButtonSize.sm,
          block: true,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
