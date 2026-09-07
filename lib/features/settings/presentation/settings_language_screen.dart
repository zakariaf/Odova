// SPEC.md §13's `settings.language`.
//
// The same seven rows as `firstrun.language`, in a different frame and with a
// different write. §13 is exact about the write: "Tapping a row applies the
// language IMMEDIATELY in both modes — strings, direction, font stack,
// notification bodies. Not on Continue, not on back: the user must see the
// result while the list is still on screen."
//
// That sentence is the whole screen. Somebody whose second-hand phone booted
// in a language they cannot read is looking for the shape of their own script
// and then for proof that the tap worked; a confirmation step is a second
// thing to understand in a language they still cannot read.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/core/l10n/locale_resolution.dart';
import 'package:odova/features/settings/data/settings_writer.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/language/language_row_list.dart';

/// §13's language screen, in settings mode.
class SettingsLanguageScreen extends ConsumerWidget {
  /// Creates the screen.
  const SettingsLanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    final deviceTags = ref
        .watch(deviceLocalesProvider)
        .map((l) => l.toLanguageTag())
        .toList();
    final setting = ref.watch(localeControllerProvider);

    return CalmScaffold(
      appBar: CalmAppBar(title: l10n.settingsLanguageRow),
      children: [
        LanguageRowList(
          // IMMEDIATELY, and through `SettingsWriter` so the write reschedules
          // notifications: §13's rule 2, and the reason it exists is this
          // screen. Bodies are baked into the OS at schedule time, so a
          // language switch without the rebuild leaves German text arriving on
          // a Persian phone for four months.
          onSelect: (value) =>
              unawaited(ref.read(settingsWriterProvider).setLanguage(value)),
        ),
        SizedBox(height: space.s4),
        // The one-line note, only when the device's language is none of the
        // six AND the user has not chosen one. Somebody who picked a language
        // is not stranded in it and does not need telling.
        if (needsNotTranslatedNote(setting, deviceTags)) ...[
          Text(
            l10n.settingsLanguageNotTranslated,
            style: type.caption.copyWith(color: colors.ink3),
          ),
          SizedBox(height: space.s4),
        ],
        // SETTINGS mode only. §8's firstRun variant omits it, because there is
        // no Units screen to point at yet — and the paragraph exists to stop a
        // user hunting for the numeral setting in the language list, which is
        // where they look first and where it is not.
        Text(
          l10n.settingsLanguageNote,
          style: type.caption.copyWith(color: colors.ink3),
        ),
      ],
    );
  }
}
