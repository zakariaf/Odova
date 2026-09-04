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
import 'package:odova/app/file_picker.dart';
import 'package:odova/core/l10n/locale_resolution.dart';
import 'package:odova/features/first_run/first_run_language_notifier.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

/// The language step of first run.
class FirstRunLanguageScreen extends ConsumerWidget {
  /// Creates the screen.
  const FirstRunLanguageScreen({super.key});

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
            CalmButton(
              label: l10n.commonContinue,
              size: CalmButtonSize.lg,
              block: true,
              // Never disabled: nothing on this screen can be invalid, and
              // `System` is a real answer.
              onPressed: () =>
                  ref.read(firstRunLanguageProvider.notifier).commit(),
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
          const LanguageRowList(),
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

/// The seven rows: `System (…)` and the six, in a fixed order.
///
/// Extracted because EPIC-14's pushed `settings.language` is the same list in a
/// different frame, and a copy of it is a second place for the order, the
/// endonyms and the tick to be wrong.
class LanguageRowList extends ConsumerWidget {
  /// Creates the list.
  const LanguageRowList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final l10n = AppLocalizations.of(context);

    final selected = ref.watch(localeControllerProvider);
    // What `system` resolves to right now — not the device's language, which
    // is a different answer whenever the device is set to a seventh one.
    final resolved = ref.watch(resolvedLocaleTagsProvider).strings;

    return CalmRowGroup(
      rows: [
        for (final value in localeOverrideValues)
          CalmListRow(
            title: value == systemLanguage
                ? l10n.settingsLanguageSystem(localeEndonym(resolved))
                // NOT an ARB key. SPEC.md §5: never translated into the current
                // UI language, because someone stuck in the wrong language has
                // to find their own — and an ARB key is an invitation for a
                // translator to translate it.
                : localeEndonym(value),
            size: CalmRowSize.compact,
            // `.row__native`: medium weight even when selected, and the CSS's
            // 1.4 leading in both scripts.
            nativeTitle: true,
            selected: value == selected,
            end: value == selected
                // `.row__check`. Not a CalmDirectionalIcon — a tick is not one
                // of the six glyphs that mirror; it moves to the end edge
                // because the ROW mirrors, and keeps its own shape.
                ? Icon(Icons.check, size: space.iconMd, color: colors.brand)
                : null,
            onTap: () =>
                ref.read(firstRunLanguageProvider.notifier).select(value),
          ),
      ],
    );
  }
}
