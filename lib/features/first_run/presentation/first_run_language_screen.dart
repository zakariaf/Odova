// `firstrun.language` — the app's first screen.
//
// SPEC.md §8: "Wordmark, seven rows, one button, one text link. No app-bar, no
// back, no skip, no explanatory paragraph." It is the RTL decision as much as
// the language one, which is why it comes before the car: a hand-me-down phone
// in the wrong language is a silent disaster, and the user has to be able to
// fix it before they have typed anything they could lose.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/file_picker.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/l10n/locale_resolution.dart';
import 'package:odova/features/first_run/first_run_language_notifier.dart';
import 'package:odova/features/first_run/presentation/first_run_save_failure.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/language/language_row_list.dart';

/// The language step of first run.
class FirstRunLanguageScreen extends ConsumerWidget {
  /// Creates the screen.
  const FirstRunLanguageScreen({super.key});

  /// SPEC.md §8: "Continue — Commits `Settings`, pushes `vehicle.edit`
  /// (firstRun)."
  ///
  /// The navigation is the half that was missing, and no test on either screen
  /// could see it: `Settings.onboarding_done` stays FALSE until a vehicle
  /// exists — §8 says so, so a kill between the two steps replays from here —
  /// which means `appRedirect` rule 3 pins the user on this screen until
  /// something moves them. Nothing did, so a fresh install could not create a
  /// vehicle at all.
  ///
  /// `go`, not `push`. §8: "No back edge"; there is nothing behind this screen
  /// and a back stack would let the user return to a decision they have made.
  static Future<void> _continue(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(firstRunLanguageProvider.notifier).commit();
    if (ok && context.mounted) context.go(Routes.firstRunVehicle);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final l10n = AppLocalizations.of(context);

    final deviceTags = ref
        .watch(deviceLocalesProvider)
        .map((l) => l.toLanguageTag())
        .toList();

    final status = ref.watch(firstRunLanguageProvider);

    return PopScope(
      // SPEC.md §8 Navigation: "No back edge; Android system back exits the
      // app." `firstrun.vehicle` does the opposite and SWALLOWS it — there the
      // user has a language and no car, and dismissing into an app with no data
      // is a bug with a nice animation. Here there is nothing behind this
      // screen to return to, so leaving is the honest answer.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(SystemNavigator.pop());
      },
      child: CalmScaffold(
        appBar: null,
        brand: true,
        tight: true,
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: space.s3,
          children: [
            // SPEC.md §8's Error state, which this screen showed nowhere: the
            // notifier set `failed`, nothing watched it, and a user on a full
            // disk tapped Continue forever with no message and no error.
            if (status == FirstRunLanguageStatus.failed)
              FirstRunSaveFailure(
                onRetry: () => unawaited(_continue(context, ref)),
              ),
            CalmButton(
              label: l10n.commonContinue,
              size: CalmButtonSize.lg,
              block: true,
              // Never disabled: nothing on this screen can be invalid, and
              // `System` is a real answer.
              onPressed: () => unawaited(_continue(context, ref)),
            ),
            Text(
              l10n.firstRunRestorePrompt,
              textAlign: TextAlign.center,
              style: type.caption.copyWith(color: colors.ink3),
            ),
            CalmButton(
              label: l10n.commonRestoreBackup,
              variant: CalmButtonVariant.quiet,
              block: true,
              onPressed: () => unawaited(ref.read(filePickerProvider)()),
            ),
          ],
        ),
        children: [
          Padding(
            // The artboard's inline `padding-block-start: var(--space-3)` on
            // the wordmark stack, on top of the body's own s5.
            padding: EdgeInsetsDirectional.only(top: space.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: space.s2,
              children: [
                Text(
                  // The brand, never translated and never transliterated as a
                  // title — the RTL reference still renders Latin "Odova",
                  // end-aligned.
                  l10n.appTitle,
                  style: type.hero.copyWith(color: colors.brand),
                ),
                Text(
                  l10n.firstRunLanguageTagline,
                  style: type.bodyLg.copyWith(color: colors.ink2),
                ),
              ],
            ),
          ),
          LanguageRowList(
            onSelect: (value) =>
                ref.read(firstRunLanguageProvider.notifier).select(value),
          ),
          if (needsNotTranslatedNote(
            ref.watch(localeControllerProvider),
            deviceTags,
          ))
            Text(
              l10n.settingsLanguageNotTranslated,
              style: type.caption.copyWith(color: colors.ink3),
            ),
        ],
      ),
    );
  }
}
