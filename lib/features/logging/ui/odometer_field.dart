// The one odometer field, on all three forms that carry it.
//
// SPEC.md §10 *The odometer field, everywhere it appears*: "This one field
// feeds the due engine, so it behaves identically on `log.fillup`,
// `log.service` and `log.odometer`." Three copies would be three histories
// written into one table.
//
// The rule it is built around is that the field is **never prefilled from an
// estimate**. The projection is offered as a tappable chip instead, because
// "an estimate that arrives as a default gets saved unread; one that takes a
// tap was chosen" — and the app's whole claim is that it never guesses in a
// way that looks like fact.
import 'package:flutter/material.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/odometer/monotonicity.dart';
import 'package:odova/core/odometer/odometer_entry.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/logging/domain/decimal_input.dart';
import 'package:odova/features/logging/domain/odometer_rules.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/unit_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_chip.dart';
import 'package:odova/ui/calm/calm_field.dart';

/// The unit chip, for the tests that tap it.
const Key kOdometerUnitChipKey = Key('log.odometer.unitChip');

/// The estimate chip, for the tests that tap it.
const Key kOdometerEstimateChipKey = Key('log.odometer.estimateChip');

/// How stale a reading may be before the estimate chip is withdrawn.
///
/// SPEC.md §10 sets it at 60 days and says why it is shorter than
/// `estimateOdometer`'s 180-day projection lifetime: "a form must not hand the
/// user a number it would only hedge on a card". A card can wear a `~`; a field
/// the user is about to save cannot.
const int kOdometerEstimateMaxStaleDays = 60;

/// `+432 km since 12 Mar` — one isolate-wrapped atom.
///
/// Top-level and shared, because `log.odometer` draws this line too and built
/// it a second time: same message, same formatting, a hand-rolled
/// `entered > last` rule in place of the engine's, and its own isolate
/// wrapping. The isolate is the part that matters — it is what keeps the sign
/// attached to the number in RTL, and it is exactly the kind of thing that
/// gets fixed in one copy.
String odometerDeltaLine(
  AppLocalizations l10n, {
  required Distance delta,
  required String sinceOccurredOn,
  required DistanceUnit unit,
  required String formatsTag,
}) => isolate(
  l10n.logOdometerDelta(
    withUnitUnisolated(
      delta.inUnit(unit),
      distanceUnitLabel(l10n, unit),
      formatsTag,
      numerals: CalmNumerals.auto,
      decimalDigits: 0,
    ),
    formatLongDate(sinceOccurredOn, formatsTag),
  ),
);

/// The shared odometer field.
class OdometerField extends StatelessWidget {
  /// Creates the field.
  const OdometerField({
    required this.controller,
    required this.unit,
    required this.existing,
    required this.corrections,
    required this.occurredOn,
    required this.formatsTag,
    required this.onChanged,
    required this.onUnitChanged,
    super.key,
    this.estimate,
    this.estimateStaleDays = 0,
    this.emptyMessage,
  });

  /// What has been typed. The screen owns it.
  final TextEditingController controller;

  /// The unit THIS ENTRY is in — not the vehicle's.
  ///
  /// §10 makes the affix a chip: tapping it "switches the unit for this entry
  /// only and records it as the entry's `odometer_unit`; the vehicle's display
  /// unit is untouched". A garage that fits a kilometre cluster to a miles car
  /// is logged without re-rendering eight years of history.
  final DistanceUnit unit;

  /// The vehicle's readings, for the neighbour comparison.
  final List<ReadingPoint> existing;

  /// Its corrections, so the comparison is on the corrected scale.
  final List<CorrectionPoint> corrections;

  /// The date this entry is dated, which decides who its neighbours are.
  final String occurredOn;

  /// The tag numbers and dates are shaped by.
  final String formatsTag;

  /// The projection, or null when there is nothing to project from.
  final Distance? estimate;

  /// How old the reading behind [estimate] is.
  final int estimateStaleDays;

  /// The message when the field is empty, or null to say nothing.
  ///
  /// Null on `log.expense`, where an odometer is optional and an empty one is
  /// not a problem to report.
  final String? emptyMessage;

  /// Called on every keystroke.
  final ValueChanged<String> onChanged;

  /// Called when the unit chip is tapped, with the unit to switch TO.
  final ValueChanged<DistanceUnit> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);

    // Computed ONCE per build and handed down. `groupingSeparatorFor` is not
    // a lookup — it formats a number, folds its digits and compiles a RegExp —
    // and `_lastBefore` filters and sorts the whole reading history. Between
    // them they ran up to six times per frame, on every keystroke, for one
    // answer that cannot change within a build.
    final separator = groupingSeparatorFor(formatsTag);
    final last = _lastBefore();
    final entered = _entered(separator);
    final check = entered == null
        ? null
        : checkOdometerField(
            entered: entered,
            occurredOn: occurredOn,
            existing: existing,
            corrections: corrections,
            vehicleUnit: unit,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: space.s2,
      children: [
        CalmField(
          label: l10n.logOdometerLabel,
          controller: controller,
          numeric: true,
          keyboardType: TextInputType.number,
          // No decimal, per §10's Field kit: a dash reads whole units, and a
          // separator there is a mis-parse on its way to a column.
          inputFormatters: [
            DecimalFieldFormatter(
              decimals: 0,
              groupingSeparator: separator,
            ),
          ],
          affix: _UnitChip(
            unit: unit,
            label: distanceUnitLabel(l10n, unit),
            semanticLabel: l10n.logOdometerUnitChipLabel,
            onTap: () => onUnitChanged(
              unit == DistanceUnit.km ? DistanceUnit.mi : DistanceUnit.km,
            ),
          ),
          errorText: _message(l10n, check, last, separator),
          hint: _helper(l10n, last),
          onChanged: onChanged,
        ),
        if (_offersEstimate)
          _EstimateChip(
            estimate: estimate!,
            unit: unit,
            formatsTag: formatsTag,
            onTap: () => _fill(estimate!),
          ),
        if (check case OdometerFieldOk(isNewEarliest: true))
          Text(l10n.logOdometerOlderThanAnything),
        if (_delta(l10n, check, last) case final delta?) Text(delta),
      ],
    );
  }

  /// §10 withdraws the chip past 60 days rather than offering a stale guess.
  bool get _offersEstimate =>
      estimate != null && estimateStaleDays <= kOdometerEstimateMaxStaleDays;

  /// The typed value as a distance, or null when it is not one yet.
  ///
  /// Through `OdometerEntry`, which is the app's one answer to "what does this
  /// odometer field say". The version this replaced re-derived the parse and
  /// dropped its overflow guard: `double.round()` CLAMPS to `int` max rather
  /// than throwing and `Distance.fromKm` then multiplies by a thousand in
  /// wrapping 64-bit arithmetic, so `18446744073709551` came back as 384
  /// metres — and the whole monotonicity check ran against that, announcing
  /// the largest number the user has ever typed as the vehicle's earliest
  /// reading. `DecimalFieldFormatter(decimals: 0)` accepts arbitrarily many
  /// digits, so the field is reachable.
  Distance? _entered(String separator) {
    final metres = OdometerEntry(
      unit: unit,
      groupingSeparator: separator,
      text: controller.text,
    ).metres;
    return metres == null ? null : Distance(metres);
  }

  void _fill(Distance value) {
    // The value in the FIELD's unit, ungrouped and unmarked. Once it is in the
    // field it is a number the user has accepted; the `~` belonged to the
    // offer, not to the answer.
    controller.text = '${value.inUnit(unit).round()}';
    onChanged(controller.text);
  }

  /// The helper line: the last entered reading, and its age when it is stale.
  String? _helper(AppLocalizations l10n, ReadingPoint? last) {
    if (last == null) return null;

    final distance = formatWithUnit(
      last.odometer.inUnit(unit),
      distanceUnitLabel(l10n, unit),
      formatsTag,
      numerals: CalmNumerals.auto,
      decimalDigits: 0,
    );
    final date = formatLongDate(last.occurredOn, formatsTag);

    if (estimateStaleDays > kOdometerEstimateMaxStaleDays) {
      return l10n.logOdometerLastEnteredStale(
        estimateStaleDays,
        distance,
        date,
        formatForDisplay(
          estimateStaleDays,
          formatsTag,
          numerals: CalmNumerals.auto,
          decimalDigits: 0,
        ),
      );
    }
    return l10n.logOdometerLastEntered(distance, date);
  }

  /// The reading immediately before this entry's date, if there is one.
  ReadingPoint? _lastBefore() {
    final earlier = existing
        .where((r) => r.occurredOn.compareTo(occurredOn) <= 0)
        .toList();
    if (earlier.isEmpty) return null;
    earlier.sort(compareReadings);
    return earlier.last;
  }

  String? _delta(
    AppLocalizations l10n,
    OdometerFieldCheck? check,
    ReadingPoint? last,
  ) {
    if (check is! OdometerFieldOk) return null;
    final since = check.sinceLast;
    if (since == null || last == null) return null;
    return odometerDeltaLine(
      l10n,
      delta: since,
      sinceOccurredOn: last.occurredOn,
      unit: unit,
      formatsTag: formatsTag,
    );
  }

  /// The field's one message line.
  ///
  /// A soft warning goes HERE, in amber, and saves anyway. A below-last value
  /// does NOT: §10 gives it the three-way sheet, and a message under the field
  /// would be the app asking the user to guess which of the three it meant.
  String? _message(
    AppLocalizations l10n,
    OdometerFieldCheck? check,
    ReadingPoint? last,
    String separator,
  ) {
    if (controller.text.trim().isEmpty) return emptyMessage;
    if (check is! OdometerFieldOk) return null;
    if (check.warnings.isEmpty) return null;

    return switch (check.warnings.first) {
      OdometerWarning.impliedRateHigh => l10n.logOdometerRateWarning(
        _ratePerDay(l10n, check, last),
        formatLongDate(last?.occurredOn ?? occurredOn, formatsTag),
      ),
      OdometerWarning.jumpVeryLarge => l10n.logOdometerJumpWarning(
        withUnitUnisolated(
          (check.sinceLast ?? Distance.zero).inUnit(unit),
          distanceUnitLabel(l10n, unit),
          formatsTag,
          numerals: CalmNumerals.auto,
          decimalDigits: 0,
        ),
      ),
      OdometerWarning.probableUnitMixUp => l10n.logOdometerUnitMixUpWarning(
        formatWithUnit(
          (_entered(separator) ?? Distance.zero).inUnit(DistanceUnit.mi),
          distanceUnitLabel(l10n, DistanceUnit.mi),
          formatsTag,
          numerals: CalmNumerals.auto,
          decimalDigits: 0,
        ),
      ),
    };
  }

  String _ratePerDay(
    AppLocalizations l10n,
    OdometerFieldOk check,
    ReadingPoint? last,
  ) {
    final since = check.sinceLast;
    if (last == null || since == null) return '';
    final days = _daysBetween(last.occurredOn, occurredOn);
    return formatWithUnit(
      since.inUnit(unit) / (days == 0 ? 1 : days),
      distanceUnitLabel(l10n, unit),
      formatsTag,
      numerals: CalmNumerals.auto,
      decimalDigits: 0,
    );
  }

  /// Calendar days between two ISO dates.
  ///
  /// `CivilDate.daysUntil`, never `DateTime.difference().inDays`:
  /// `no_local_day_arithmetic_test` bans the latter across `lib/` because a
  /// `Duration` over a daylight-saving boundary is 23 or 25 hours and
  /// truncates to the wrong number of days — which here would move the implied
  /// rate across §10's 2,000 km/day threshold twice a year.
  int _daysBetween(String from, String to) {
    final a = CivilDate.tryParse(from);
    final b = CivilDate.tryParse(to);
    if (a == null || b == null) return 0;
    return a.daysUntil(b);
  }
}

/// The unit affix, as a chip.
class _UnitChip extends StatelessWidget {
  const _UnitChip({
    required this.unit,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final DistanceUnit unit;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: CalmChip(
      key: kOdometerUnitChipKey,
      label: label,
      onTap: onTap,
    ),
  );
}

/// `~187,700 now` — the projection, offered rather than assumed.
class _EstimateChip extends StatelessWidget {
  const _EstimateChip({
    required this.estimate,
    required this.unit,
    required this.formatsTag,
    required this.onTap,
  });

  final Distance estimate;
  final DistanceUnit unit;
  final String formatsTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: CalmChip(
        key: kOdometerEstimateChipKey,
        // Through `formatDistanceFigure`, which is the ONE place the estimate
        // mark is applied — the `~` comes from an ICU message so a translator
        // decides which side of the figure it sits on.
        label: l10n.logOdometerEstimateChip(
          formatDistanceFigure(
            l10n,
            formatsTag,
            estimate,
            unit,
            estimated: true,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
