// The seven language rows, shared by `firstrun.language` and
// `settings.language`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/core/l10n/locale_resolution.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';

/// The seven rows: `System (…)` and the six, in a fixed order.
///
/// Extracted because `settings.language` is the same list in a different
/// frame, and a copy of it is a second place for the order, the endonyms and
/// the tick to be wrong.
///
/// It lives in `lib/ui/` for the reason `lib/ui/dialogs/` does: two features
/// draw it and `structure_test.dart` refuses one importing the other. What it
/// does NOT own is the write — the two frames apply a language differently
/// (first run commits on Continue, settings applies on tap and reschedules
/// notifications), so [onSelect] is required and the decision stays with the
/// caller.
class LanguageRowList extends ConsumerWidget {
  /// Creates the list.
  const LanguageRowList({required this.onSelect, super.key});

  /// What tapping a row does, with the tapped value — `system` or a language.
  final ValueChanged<String> onSelect;

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
            // `.row__native`, with the artboard's `lang` attribute: medium
            // weight even when selected, the CSS's 1.4 leading in both scripts,
            // and — for فارسی, العربية and کوردیی ناوەندی under a Latin UI —
            // the bundled family, without which they are three empty boxes.
            nativeTitleLanguage: value == systemLanguage ? resolved : value,
            selected: value == selected,
            end: value == selected
                // `.row__check`. Not a CalmDirectionalIcon — a tick is not one
                // of the six glyphs that mirror; it moves to the end edge
                // because the ROW mirrors, and keeps its own shape.
                ? Icon(Icons.check, size: space.iconMd, color: colors.brand)
                : null,
            onTap: () => onSelect(value),
          ),
      ],
    );
  }
}
