/// The three global dialogs, composed inline for a capture.
///
/// **Not opened through `showDiscardDialog` and friends.** A route-based dialog
/// paints into an `Overlay` that the `RepaintBoundary` above `home:` does not
/// contain, so the capture would be the backdrop with no dialog on it — and
/// every mechanical check would pass. Composing the same widget tree the
/// builders compose keeps the capture honest about what is being shot.
///
/// The strings come from the ARB through `AppLocalizations`, so a capture and
/// the app cannot drift; the DATA is transcribed from the artboards, because
/// the picture is of one particular vehicle on one particular day. The snooze
/// dates are transcribed rather than computed for the same reason — the
/// dialog's own arithmetic is tested in
/// `test/ui/dialogs/snooze_dialog_test.dart`, and a capture that recomputed it
/// would be asserting it twice while proving nothing about the picture.
library;

import 'package:flutter/material.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_dialog.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';

/// The scrim the three dialogs sit on.
///
/// `CalmColors.scrim`, never a hex literal: a hand-written `0x66000000`
/// composited over the backdrop reads as #95918C, which is not a Calm colour at
/// all — the parity check said so over 32.8% of the frame, and it was right to.
class _Scrim extends StatelessWidget {
  const _Scrim();

  @override
  Widget build(BuildContext context) =>
      Positioned.fill(child: ColoredBox(color: CalmColors.of(context).scrim));
}

/// `dialog.discard`, as the artboard draws it.
class DiscardOverlay extends StatelessWidget {
  /// Creates the overlay.
  const DiscardOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    final subject = rtl ? 'روغن و فیلتر' : 'Oil and filter';
    final summary = rtl
        ? 'بازه ۱۵٬۰۰۰ کیلومتری و مبنای جدید'
        : 'a 15,000 km interval and a new baseline';

    return Stack(
      children: [
        const _Scrim(),
        CalmDialog.actions(
          icon: Icons.edit_note_outlined,
          title: l10n.discardTitle,
          body: l10n.discardBody(subject, summary),
          actions: [
            CalmButton(
              label: l10n.discardKeepEditing,
              onPressed: _inert,
              block: true,
            ),
            CalmButton(
              label: l10n.discardDiscard,
              onPressed: _inert,
              variant: CalmButtonVariant.danger,
              block: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// `dialog.confirmDelete`, as the artboard draws it.
///
/// The artboard shows Delete DISABLED with the field empty, which is the state
/// this captures. Calm requires a disabled control to say why, so the built
/// screen carries one line the reference does not — see
/// `lib/ui/dialogs/confirm_delete_dialog.dart`.
class ConfirmDeleteOverlay extends StatelessWidget {
  /// Creates the overlay.
  const ConfirmDeleteOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final subject = rtl ? 'گلف' : 'The Golf';
    String n(String latin, String persian) => rtl ? persian : latin;

    return Stack(
      children: [
        const _Scrim(),
        CalmDialog.actions(
          icon: Icons.delete_outline,
          danger: true,
          title: l10n.confirmDeleteTitle(subject, 412, n('412', '۴۱۲')),
          body: l10n.confirmDeleteBody(
            96,
            n('96', '۹۶'),
            14,
            n('14', '۱۴'),
            22,
            n('22', '۲۲'),
            8,
            n('8', '۸'),
            16,
            n('16', '۱۶'),
          ),
          actions: [
            CalmButton(
              label: n(
                'Keep it — mark it sold',
                'نگهش دار — فروخته‌شده علامت بزن',
              ),
              onPressed: _inert,
              variant: CalmButtonVariant.secondary,
              block: true,
            ),
            // Disabled, which is the state the artboard draws: the field is
            // empty, so the name has not been typed.
            CalmButton(
              label: l10n.confirmDeleteDelete,
              onPressed: null,
              variant: CalmButtonVariant.dangerSolid,
              block: true,
            ),
            CalmButtonExplain(
              reason: l10n.confirmDeleteTypeToConfirm(subject),
            ),
            CalmButton(
              label: l10n.confirmDeleteCancel,
              onPressed: _inert,
              variant: CalmButtonVariant.quiet,
              block: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// `dialog.snooze`, as the artboard draws it.
class SnoozeOverlay extends StatelessWidget {
  /// Creates the overlay.
  const SnoozeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    String n(String latin, String persian) => rtl ? persian : latin;

    return Stack(
      children: [
        const _Scrim(),
        CalmDialog.actions(
          icon: Icons.notifications_paused_outlined,
          title: l10n.snoozeTitle(n('Oil and filter', 'روغن و فیلتر')),
          body: l10n.snoozeBody,
          actions: [
            CalmRowGroup(
              flat: true,
              rows: [
                _row(
                  l10n.snoozeThreeDays(n('3', '۳')),
                  l10n.snoozeUntil(n('6 Sep', '۱۵ شهریور')),
                ),
                _row(
                  l10n.snoozeOneWeek(n('1', '۱')),
                  l10n.snoozeUntil(n('10 Sep', '۱۹ شهریور')),
                ),
                _row(
                  l10n.snoozeOneMonth(n('1', '۱')),
                  l10n.snoozeUntil(n('3 Oct', '۱۱ مهر')),
                ),
                _row(
                  l10n.snoozeDistance(n('500 km', '۵۰۰ کیلومتر')),
                  l10n.snoozeAtOdometer(
                    n('187,912 km', '۱۸۷٬۹۱۲ کیلومتر'),
                  ),
                ),
              ],
            ),
            CalmButton(
              label: l10n.snoozeCancel,
              onPressed: _inert,
              variant: CalmButtonVariant.quiet,
              block: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(String title, String value) => CalmListRow(
    title: title,
    value: value,
    size: CalmRowSize.compact,
    onTap: _inert,
  );
}

/// A captured dialog does nothing when tapped: it is a picture.
void _inert() {}
