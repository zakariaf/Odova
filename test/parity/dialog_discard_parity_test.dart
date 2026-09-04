// `dialog.discard`, captured over its backdrop, in all four combinations.
//
// The capture FILENAME is the screen id, dot included — `compare_to_reference
// .mjs` looks up its reference by that name and cannot find one called
// `dialog_discard`. The test file uses underscores because Dart does.
@Tags(['parity'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_dialog.dart';

import 'support/dialog_backdrop.dart';
import 'support/parity_capture.dart';

void main() {
  setUpAll(loadParityFonts);

  for (final config in kParityCases) {
    testWidgets('dialog.discard ${config.theme}/${config.dir}', (tester) async {
      await captureParity(
        tester,
        screen: 'dialog.discard',
        config: config,
        child: const HomeBackdrop(),
        // The dialog is composed inline rather than opened through
        // `showDiscardDialog`, because a route-based dialog paints into an
        // Overlay the RepaintBoundary above `home:` does not contain — the
        // capture would be the backdrop with no dialog on it, and every
        // mechanical check would pass.
        overlay: const _DiscardOverlay(),
      );
    });
  }
}

/// The scrim and the dialog, as the reference draws them.
class _DiscardOverlay extends StatelessWidget {
  const _DiscardOverlay();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    // The reference's own two halves, transcribed from `data-en`/`data-fa`
    // rather than invented: the body interpolates them and a different subject
    // is a different line count.
    final subject = rtl ? 'روغن و فیلتر' : 'Oil and filter';
    final summary = rtl
        ? 'بازه ۱۵٬۰۰۰ کیلومتری و مبنای جدید'
        : 'a 15,000 km interval and a new baseline';

    return Stack(
      children: [
        // The TOKEN, not a hex literal. A hand-written `0x66000000` composited
        // over the backdrop reads as #95918C, which is not a Calm colour at
        // all — the parity check said so, over 32.8% of the frame, and it was
        // right to.
        Positioned.fill(
          child: ColoredBox(color: CalmColors.of(context).scrim),
        ),
        CalmDialog.actions(
          icon: Icons.edit_note_outlined,
          title: l10n.discardTitle,
          body: l10n.discardBody(subject, summary),
          actions: [
            CalmButton(
              label: l10n.discardKeepEditing,
              onPressed: () {},
              block: true,
            ),
            CalmButton(
              label: l10n.discardDiscard,
              onPressed: () {},
              variant: CalmButtonVariant.danger,
              block: true,
            ),
          ],
        ),
      ],
    );
  }
}
