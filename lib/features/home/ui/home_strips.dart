// Home's three conditional strips.
//
// SPEC.md §9 *Conditional strips*, *Stale odometer*, *Done-from-notification
// confirmation*, *Away digest*. All three are `.notice` panels: flat, tinted,
// above the cards and never in place of one. The CAP and the priority are
// `home_strips.dart` in `domain/`; this file draws what that decided.
//
// Each strip takes its facts and its callbacks and holds no state of its own
// except the odometer field, which is a text controller and belongs to the
// widget that owns the keyboard.
import 'package:flutter/material.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/odometer/odometer_entry.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_notice.dart';
import 'package:odova/ui/calm/calm_odometer_input.dart';

/// The stale-odometer strip, and the field it carries.
///
/// §9: it "carries a number field, a unit label and **Save**, writing an
/// `OdometerReading` without leaving Home; `✕` hides it for 7 days on that
/// vehicle." The field is here rather than in a modal because the whole point
/// is not to leave Home — a strip that opened `log.odometer` would be a link
/// with extra steps.
class StalenessStrip extends StatefulWidget {
  /// Creates the strip.
  const StalenessStrip({
    required this.staleDays,
    required this.unit,
    required this.groupingSeparator,
    required this.formatsTag,
    required this.onSave,
    required this.onDismiss,
    super.key,
  });

  /// How long since the last reading.
  final int staleDays;

  /// The unit the field is in.
  final DistanceUnit unit;

  /// The locale's grouping separator, for `OdometerEntry`.
  final String groupingSeparator;

  /// The tag the day count is shaped by.
  final String formatsTag;

  /// Writes the reading. Given METRES, because storage is canonical and a
  /// widget that handed over a string would make the repository parse a
  /// locale.
  final void Function(int metres) onSave;

  /// `✕` — hides the strip for seven days on this vehicle.
  final VoidCallback onDismiss;

  @override
  State<StalenessStrip> createState() => _StalenessStripState();
}

class _StalenessStripState extends State<StalenessStrip> {
  late final TextEditingController _controller = TextEditingController();
  late OdometerEntry _entry = OdometerEntry(
    unit: widget.unit,
    groupingSeparator: widget.groupingSeparator,
  );

  /// The unit and the separator are the WIDGET's, and they change under it.
  ///
  /// `_entry` was `late` and initialised once. A user switching the app between
  /// kilometres and miles — or the locale, which moves the grouping separator —
  /// left the strip parsing what they typed with the unit it was built with,
  /// while the affix beside the field had already redrawn with the new one.
  /// `_entry.metres` then converted through the wrong unit and the canonical
  /// metres column took a reading 1.6x out. SPEC.md §2: storage is canonical
  /// and conversion happens on read — a conversion done on WRITE with a stale
  /// unit is the one way that rule fails silently.
  @override
  void didUpdateWidget(StalenessStrip old) {
    super.didUpdateWidget(old);
    if (old.unit == widget.unit &&
        old.groupingSeparator == widget.groupingSeparator) {
      return;
    }
    // The TEXT is kept: the user typed those digits and the unit changing
    // underneath them is not a reason to throw them away. It is re-parsed
    // against the new unit, which is what they now mean.
    _entry = OdometerEntry(
      text: _entry.text,
      unit: widget.unit,
      groupingSeparator: widget.groupingSeparator,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);

    return CalmNotice(
      icon: Icons.info_outline,
      tone: CalmNoticeTone.warn,
      onClose: widget.onDismiss,
      closeLabel: l10n.homeStripStaleDismiss,
      children: [
        Text(
          l10n.homeStripStale(
            widget.staleDays,
            formatForDisplay(
              widget.staleDays,
              widget.formatsTag,
              numerals: CalmNumerals.auto,
              decimalDigits: 0,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: space.s3,
          children: [
            Expanded(
              // `CalmField` directly, not `CalmOdometerInput`. The shared input
              // is a stacked label, a field, a helper line and a "Use it
              // anyway" button — 216pt on the floor screen, which pushed the
              // PRIMARY CARD below the fold. §9's drawing is two lines, and the
              // rule it is drawn under is that a strip never displaces the
              // card.
              //
              // Nothing is lost but pixels: the label is still announced (the
              // field's own `Semantics` carries it), and the error line appears
              // only when there IS one, so the strip grows exactly when the
              // user needs it to.
              child: CalmField(
                label: l10n.odometerNowLabel,
                showLabel: false,
                controller: _controller,
                // The SHARED switch, with no empty message: an untouched
                // strip says nothing, the way create mode does. §8's
                // "never a block" lives in one place now, which is the point
                // — this was the third widget to decide it.
                errorText: odometerProblemMessage(l10n, _entry.problem),
                affix: Text(distanceUnitLabel(l10n, widget.unit)),
                numeric: true,
                keyboardType: TextInputType.number,
                onChanged: (text) =>
                    setState(() => _entry = _entry.copyWith(text: text)),
              ),
            ),
            CalmButton(
              label: l10n.commonSave,
              // NEVER disabled, and never silently inert: SPEC.md §10's rule
              // is that Save explains rather than greys out. An unusable entry
              // is already saying why under the field, so the press is a no-op
              // with the reason already on screen.
              onPressed: () {
                final metres = _entry.metres;
                if (metres != null) widget.onSave(metres);
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// The done-from-notification confirmation.
///
/// §9: "Highest-priority strip, not dismissible, appears once." Not dismissible
/// is expressed by passing no `onClose` at all rather than by a disabled one —
/// a control that refuses is a control the user tries twice.
class DoneConfirmationStrip extends StatelessWidget {
  /// Creates the strip.
  const DoneConfirmationStrip({
    required this.itemLabel,
    required this.doneOn,
    required this.recordedOdometer,
    required this.nextOdometer,
    required this.nextDate,
    required this.onAddRealNumbers,
    required this.onConfirm,
    super.key,
  });

  /// The item the notification action completed.
  final String itemLabel;

  /// The day it was marked done, already formatted.
  final String doneOn;

  /// What the app recorded, already formatted AND already marked as an
  /// estimate — the `~` is what "Add the real numbers" is offering to replace.
  final String recordedOdometer;

  /// The next due odometer, formatted.
  final String nextOdometer;

  /// The next due date, formatted.
  final String nextDate;

  /// Opens `log.service` in edit mode on that record.
  final VoidCallback onAddRealNumbers;

  /// Clears `odometer_estimated` and `cost_estimated`.
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);

    return CalmNotice(
      icon: Icons.check_circle_outline,
      children: [
        Text(l10n.homeStripDoneTitle(itemLabel, doneOn)),
        Text(l10n.homeStripDoneRecorded(recordedOdometer)),
        Text(l10n.homeStripDoneNext(nextOdometer, nextDate)),
        Row(
          spacing: space.s3,
          children: [
            Flexible(
              child: CalmButton(
                label: l10n.actionAddRealNumbers,
                onPressed: onAddRealNumbers,
              ),
            ),
            Flexible(
              child: CalmButton(
                label: l10n.actionThatsRight,
                onPressed: onConfirm,
                variant: CalmButtonVariant.quiet,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One line of the away digest.
typedef AwayDigestLine = ({String item, String date, bool overdue});

/// The away digest.
///
/// §9: "One dismissible card, at most three lines." The cap is applied HERE
/// rather than by the caller, because it is a property of the card: a digest
/// that grew a fourth line would be a list, and a list belongs on
/// `reminders.list`.
class AwayDigestStrip extends StatelessWidget {
  /// Creates the strip.
  const AwayDigestStrip({
    required this.lines,
    required this.onDismiss,
    super.key,
  });

  /// How many lines §9 allows.
  static const int cap = 3;

  /// What happened while the app was closed.
  final List<AwayDigestLine> lines;

  /// `✕`.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CalmNotice(
      icon: Icons.schedule_outlined,
      tone: CalmNoticeTone.info,
      onClose: onDismiss,
      closeLabel: l10n.homeDigestDismiss,
      children: [
        for (final line in lines.take(cap))
          Text(
            line.overdue
                ? l10n.homeDigestOverdue(line.item, line.date)
                : l10n.homeDigestDue(line.item, line.date),
          ),
      ],
    );
  }
}
