// Two fields, the keypad up, and nothing optional.
//
// SPEC.md §10 `log.odometer`: "No notes, no category, no More section — this
// screen exists to be finished before the user changes their mind; one more
// optional field would be a net loss." It is the fastest entry in the app and
// the one that clears a stale-odometer state on Home.
//
// `CalmNumberPad` holds nothing: it renders a string and reports ASCII digits
// whatever glyphs it drew. The buffer, the grouping and the delta are this
// widget's, which is what lets the same pad serve a Persian keypad without ever
// parsing a Persian numeral back out of its own output.
import 'package:flutter/material.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/number_format.dart';
import 'package:odova/l10n/unit_format.dart';
import 'package:odova/l10n/vehicle_labels.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_number_pad.dart';

/// The odometer segment's body.
class LogOdometerBody extends StatelessWidget {
  /// Creates the body.
  const LogOdometerBody({
    required this.value,
    required this.unit,
    required this.formatsTag,
    required this.occurredOn,
    required this.onPickDate,
    required this.onValueChanged,
    required this.onSave,
    super.key,
    this.lastReading,
    this.lastReadingOn,
  });

  /// The digits typed so far, ASCII and ungrouped. The screen owns them.
  final String value;

  /// The unit this entry is in.
  final DistanceUnit unit;

  /// The tag numbers and dates are shaped by.
  final String formatsTag;

  /// The date this reading is dated, as an ISO day.
  ///
  /// A KEY on the pad and not a row above it. §10 gives this screen two fields
  /// and nothing else — "one more optional field would be a net loss" — and
  /// the artboard puts the date next to Save, at its shortest, where it can be
  /// changed without leaving the keypad the user is already using.
  final String occurredOn;

  /// Opens the date picker.
  final VoidCallback onPickDate;

  /// The last entered reading, or null on a vehicle's first.
  final Distance? lastReading;

  /// Its date.
  final String? lastReadingOn;

  /// Called with the new buffer on every key.
  final ValueChanged<String> onValueChanged;

  /// The pad's own confirm key.
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final space = CalmSpace.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: space.s4,
      children: [
        CalmNumberPad(
          value: _display,
          unit: distanceUnitLabel(l10n, unit),
          hint: _hint(l10n),
          // ASCII in, ASCII kept. The pad draws whichever glyphs the locale
          // uses and reports the digit, so nothing here ever parses a numeral
          // back out of its own keypad.
          onDigit: (digit) => onValueChanged('$value$digit'),
          // CLEAR sits where a decimal point would be, because §10's Field kit
          // gives the odometer no decimal at all — "a dash reads whole units,
          // and a separator there is a mis-parse on its way to a column" — and
          // the artboard puts Clear in that key rather than leaving it blank.
          // A pad with two ways to delete one character and none to start over
          // is a pad you fight.
          onDecimal: () => onValueChanged(''),
          decimalLabel: l10n.logOdometerPadClear,
          onBackspace: () => onValueChanged(
            value.isEmpty ? value : value.substring(0, value.length - 1),
          ),
          onConfirm: onSave,
          confirmLabel: l10n.logSaveOdometer,
          // The DATE, beside Save. At its shortest because the key is one
          // third of the row wide, and §10 allows no date row on this screen
          // to put it anywhere else.
          secondaryLabel: formatShortDayMonth(occurredOn, formatsTag),
          onSecondary: onPickDate,
          backspaceSemanticLabel: l10n.logOdometerPadBackspace,
          digits: _digits,
        ),
      ],
    );
  }

  /// The buffer, grouped and in the locale's own digits.
  ///
  /// Grouped for READING — six digits of odometer are unreadable without it —
  /// and never fed back into the buffer, which stays ASCII and ungrouped.
  String get _display {
    if (value.isEmpty) return '';
    final n = int.tryParse(value);
    if (n == null) return value;
    return formatForDisplay(
      n,
      formatsTag,
      numerals: CalmNumerals.auto,
      decimalDigits: 0,
    );
  }

  /// The locale's ten glyphs, or null for Latin.
  List<String>? get _digits {
    final numerals = resolveNumerals(CalmNumerals.auto, formatsTag);
    if (numerals == CalmNumerals.latin) return null;
    return [
      for (var d = 0; d < 10; d++) shapeDigits('$d', numerals),
    ];
  }

  /// `+432 km since 12 Mar`, or nothing.
  ///
  /// §10 puts it where the number being typed is, because it is the cheapest
  /// possible check on a dropped digit. A vehicle's FIRST reading has no hint
  /// at all — there is nothing behind it to be a delta from, and that reading
  /// is the anchor the whole app hangs from.
  String _hint(AppLocalizations l10n) {
    final last = lastReading;
    final on = lastReadingOn;
    if (last == null || on == null) return '';

    // Line one: what was last entered, and when. It shows whether or not
    // anything has been typed yet — a user who has just opened this screen
    // needs the anchor more than one who is halfway through a number.
    final entered = l10n.logOdometerLastEntered(
      formatWithUnit(
        last.inUnit(unit),
        distanceUnitLabel(l10n, unit),
        formatsTag,
        numerals: CalmNumerals.auto,
        decimalDigits: 0,
      ),
      formatDayMonth(on, formatsTag),
    );

    // Line two: the delta, once there is one. `since then` and not the date
    // again — the line above just said it.
    final n = int.tryParse(value);
    if (n == null) return entered;
    final now = unit == DistanceUnit.mi
        ? Distance.fromMiles(n)
        : Distance.fromKm(n);
    if (now.metres <= last.metres) return entered;

    final delta = l10n.logOdometerSinceThen(
      isolate(
        withUnitUnisolated(
          (now - last).inUnit(unit),
          distanceUnitLabel(l10n, unit),
          formatsTag,
          numerals: CalmNumerals.auto,
          decimalDigits: 0,
        ),
      ),
    );
    return '$entered\n$delta';
  }
}
