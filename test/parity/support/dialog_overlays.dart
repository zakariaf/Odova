/// The three global dialogs, over their scrim, for a capture.
///
/// **The SHIPPED widget, not a copy of it.** These compose
/// `DiscardDialogBody`, `ConfirmDeleteDialogBody` and `SnoozeDialogBody` — the
/// same widgets `showDiscardDialog` and friends put on a route. An earlier
/// version hand-rebuilt each dialog inline, and three independent review passes
/// found the same hazard: a parity gate that photographs the test's own
/// composition stays green while the real dialog reorders its actions, changes
/// a variant or drops the safe alternative, which is the one thing the gate
/// exists to catch.
///
/// They are composed rather than OPENED because a route-based dialog paints
/// into an `Overlay` the capture's `RepaintBoundary` does not contain — the
/// capture would be the backdrop with no dialog on it, and every mechanical
/// check would pass.
///
/// The DATA is transcribed from the artboards, because the picture is of one
/// particular vehicle on one particular day. The snooze dates are transcribed
/// rather than computed for the same reason: the dialog's own arithmetic is
/// tested in `test/ui/dialogs/snooze_dialog_test.dart`, and recomputing it here
/// would assert it twice while proving nothing about the picture.
library;

import 'package:flutter/material.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/ui/dialogs/confirm_delete_dialog.dart';
import 'package:odova/ui/dialogs/discard_dialog.dart';
import 'package:odova/ui/dialogs/snooze_dialog.dart';

import 'dialog_backdrop.dart';

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
    final copy = ParityCopy.of(context);

    return Stack(
      children: [
        const _Scrim(),
        DiscardDialogBody(
          subject: copy.oil,
          summary: copy.discardSummary,
          onChoice: (_) {},
        ),
      ],
    );
  }
}

/// `dialog.confirmDelete`, as the artboard draws it.
///
/// The artboard shows Delete DISABLED with the field empty, which is the state
/// an untouched `ConfirmDeleteDialogBody` produces on its own — the capture
/// does not have to arrange it.
class ConfirmDeleteOverlay extends StatelessWidget {
  /// Creates the overlay.
  const ConfirmDeleteOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final copy = ParityCopy.of(context);

    return Stack(
      children: [
        const _Scrim(),
        ConfirmDeleteDialogBody(
          subject: copy.vehicle,
          counts: const (
            fillUps: 96,
            services: 14,
            costs: 22,
            trips: 8,
            reminders: 16,
          ),
          formatCount: copy.number,
          safeAlternativeLabel: copy.keepItMarkSold,
          onChoice: (_) {},
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
    final copy = ParityCopy.of(context);

    return Stack(
      children: [
        const _Scrim(),
        SnoozeDialogBody(
          itemLabel: copy.oil,
          today: _artboardToday,
          hasDistanceInterval: true,
          currentOdometerMetres: 187412000,
          formatDate: copy.artboardDate,
          formatDistance: copy.artboardDistance,
          onChoice: (_) {},
        ),
      ],
    );
  }
}

/// 3 September 2026 — the date every artboard in the set is drawn on.
final CivilDate _artboardToday = CivilDate.tryParse('2026-09-03')!;
