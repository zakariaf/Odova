// The odometer field, its message and its "Use it anyway", in one place.
//
// SPEC.md §8 asks for this on two screens: `firstrun.vehicle`, where it is the
// only thing the user has to type, and `vehicle.edit` in create mode, where the
// read-only odometer row becomes an input. `OdometerEntry` already shares the
// MODEL — parsing, the whole-number rule, and the three-million-kilometre
// warning that is "a warning with a 'Use it anyway' affordance, never a block".
// This is the widget around it, which was copied instead.
//
// The copies had already parted: first run holds the empty message back until
// Start has been pressed and refused, and create mode has no such moment, so
// its empty case says nothing at all. That difference is deliberate, so it is
// an ARGUMENT — [emptyMessage] — rather than a second widget.
import 'package:flutter/material.dart';
import 'package:odova/core/odometer/odometer_entry.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_field.dart';

/// The odometer field for the two screens that ask for a reading.
class CalmOdometerInput extends StatelessWidget {
  /// Creates the input.
  const CalmOdometerInput({
    required this.entry,
    required this.controller,
    required this.onChanged,
    required this.onUseAnyway,
    super.key,
    this.emptyMessage,
  });

  /// What has been typed, and what it means.
  final OdometerEntry entry;

  /// The field's controller, owned by the screen.
  final TextEditingController controller;

  /// Records the keystroke, exactly as typed.
  final ValueChanged<String> onChanged;

  /// Accepts the implausible-odometer warning.
  final VoidCallback onUseAnyway;

  /// What an EMPTY field says, or null for nothing.
  ///
  /// Null is not "no message" by oversight. §8 puts the empty message under
  /// "Empty on Save", so first run passes it only once Start has been pressed
  /// and refused — a form that scolds you before you have typed is a form that
  /// is angry at you for arriving. Create mode never passes it: Save is simply
  /// not offered yet, and there is no refused press to answer.
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // ONCE. Reading it parses the field — eleven `replaceAll` passes and two
    // fresh `RegExp`s — and the message and the affordance both ask.
    final problem = entry.problem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalmField(
          label: l10n.odometerNowLabel,
          controller: controller,
          hint: l10n.odometerFirstRunHint,
          errorText: switch (problem) {
            null => null,
            OdometerProblem.empty => emptyMessage,
            OdometerProblem.notANumber => l10n.odometerNotANumberError,
            // A WARNING sharing the one message slot with two errors. §8:
            // "never a block", and Save stays live behind it.
            OdometerProblem.implausible => l10n.odometerImplausibleWarning,
          },
          affix: Text(distanceUnitLabel(l10n, entry.unit)),
          numeric: true,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
        ),
        if (problem == OdometerProblem.implausible)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CalmButton(
              label: l10n.commonUseItAnyway,
              variant: CalmButtonVariant.quiet,
              size: CalmButtonSize.sm,
              onPressed: onUseAnyway,
            ),
          ),
      ],
    );
  }
}
