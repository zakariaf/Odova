// A search field for an app bar's title slot.
//
// It lives HERE and not in the feature that uses it, because it wraps
// `TextField` and `IconButton` — and CLAUDE.md is explicit that "wrapping
// Material is lib/ui/calm/'s job and only there". Two gates said so when it
// was first written under `features/history/`: `check_component_hygiene.sh`
// and `check_calm_layering.sh`, and both were right.
//
// SPEC.md §11 is its only caller today and the reason it exists.
//
// "Tapping `⌕` replaces the app bar title with a text field IN PLACE — no
// push, no modal, no route change." That is a behavioural promise, not a
// layout one: a pushed route would give the user a back gesture that leaves
// the list, and §11 wants back to leave SEARCH and keep the list.
//
// **RTL.** §11: "The field takes paragraph direction from its content,
// first-strong, so a Latin query in an Arabic UI reads left-to-right in a
// right-aligned field." Flutter's default for a `TextField` is the ambient
// direction, which would render `shell` right-to-left inside an Arabic UI and
// put the cursor on the wrong side of what was typed.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_icon_button.dart';

/// The app bar's search field.
class CalmSearchField extends StatelessWidget {
  /// Creates the field.
  const CalmSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClose,
    required this.hint,
    required this.closeLabel,
    super.key,
  });

  /// Holds what has been typed.
  final TextEditingController controller;

  /// Called on every keystroke. The DEBOUNCE is the notifier's.
  final ValueChanged<String> onChanged;

  /// Leaves search and restores the previous filter.
  final VoidCallback onClose;

  /// The placeholder, already localised.
  ///
  /// Passed in rather than read here: `lib/ui/calm/` owns how a control looks
  /// and never what it says, so a component that reached for an ARB key would
  /// be a component only one screen could use.
  final String hint;

  /// The close button's accessible name, already localised.
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            onChanged: onChanged,
            // No `textDirection`, deliberately. Flutter's default for a null
            // one is first-strong from the content — which is exactly what §11
            // asks for: "a Latin query in an Arabic UI reads left-to-right in
            // a right-aligned field." Passing the ambient direction instead
            // would render `shell` right-to-left and put the caret on the
            // wrong side of what was typed.
            style: type.body.copyWith(color: colors.ink),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: type.body.copyWith(color: colors.ink3),
            ),
          ),
        ),
        // At the field's END edge, per §11 — which mirrors with the field.
        //
        // `CalmIconButton`, not Material's `IconButton`. This was the only
        // `IconButton(` in all of `lib/ui/calm/`, and it dropped two contracts
        // the component exists to keep: `CalmTapTarget` grows the hit box to
        // `space.touchMin` — 52pt, above Material's 48 and above the floor
        // `check_touch_targets.sh` enforces — and `CalmPressable` gives the
        // scale-and-tint response Calm uses instead of a Material ripple. A
        // search field's close button is exactly the control someone hits
        // one-handed, in the rain, which is the situation SPEC.md §1 says to
        // design for.
        CalmIconButton(
          icon: Icons.close,
          label: closeLabel,
          onPressed: onClose,
          paintSize: space.touchMin,
          iconSize: space.iconSm,
          color: colors.ink2,
        ),
      ],
    );
  }
}
