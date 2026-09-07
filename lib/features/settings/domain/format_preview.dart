// SPEC.md §13's live format preview: the three lines that change in the same
// frame as any row below them.
//
// The preview is the whole reason `settings.units` is not a list of dropdowns.
// §5's rules interact — the numeral system, the calendar, the group and
// decimal separators, the currency's placement and its exponent — and a user
// cannot hold that in their head. They can look at `۱۲ اسفند ۱۴۰۴ · ۱۴۲٬۳۸۰
// کیلومتر` and know immediately whether it is right.
//
// PURE, and no Flutter import: the labels arrive as already-resolved strings
// in [FormatLabels], the way `ReportFormatters` does. A function that reached
// for `AppLocalizations` would need a `BuildContext` and could not be tested
// without a widget harness — and this is the file whose output must be
// asserted byte-for-byte in six locales.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/money_format.dart';
import 'package:odova/l10n/unit_format.dart';

/// The seven format settings the preview reads.
@immutable
class SettingsFormats {
  /// Creates the formats.
  const SettingsFormats({
    required this.currency,
    this.numerals = CalmNumerals.auto,
    this.calendar = CalmCalendar.gregorian,
    this.distanceUnit = DistanceUnit.km,
    this.volumeUnit = VolumeUnit.l,
    this.consumptionUnit = ConsumptionUnit.lPer100km,
    this.currencyDisplay = 'none',
  });

  /// Which digits.
  final CalmNumerals numerals;

  /// Which calendar the date is projected into.
  final CalmCalendar calendar;

  /// Distance.
  final DistanceUnit distanceUnit;

  /// Volume.
  final VolumeUnit volumeUnit;

  /// Consumption.
  final ConsumptionUnit consumptionUnit;

  /// The default currency.
  final Currency currency;

  /// `none` or `toman`.
  final String currencyDisplay;
}

/// The unit words, already localised.
///
/// A record of resolved strings rather than an `AppLocalizations`: §13 says
/// unit abbreviations come from our ARB files and never from the platform's
/// unit formatter, and passing the strings in is what lets this file assert
/// that without importing Flutter.
typedef FormatLabels = ({
  String distance,
  String volume,
  String consumption,
  String separator,
});

/// The three lines §13's preview shows.
@immutable
class FormatPreview {
  /// Creates a preview.
  const FormatPreview({
    required this.dateAndDistance,
    required this.volumeAndMoney,
    required this.consumption,
  });

  /// `12 Mar 2026 · 142,380 km`.
  final String dateAndDistance;

  /// `38.42 L · €68.90`.
  final String volumeAndMoney;

  /// `6.4 L/100 km`.
  final String consumption;
}

/// A fixed sample, so the preview is a golden vector rather than a clock read.
///
/// SPEC.md §3 makes time an argument everywhere, and a preview built from
/// `DateTime.now()` would render differently on every frame and could not be
/// pinned in a test at all.
@immutable
class FormatSample {
  /// Creates a sample.
  const FormatSample({
    required this.isoDate,
    required this.distance,
    required this.volume,
    required this.amount,
    required this.consumption,
  });

  /// §13's sample instant, as an ISO date.
  final String isoDate;

  /// Its odometer.
  final Distance distance;

  /// Its tankful.
  final Volume volume;

  /// Its price, in the default currency's minor units.
  final int amount;

  /// Its consumption, in the chosen unit.
  final double consumption;
}

/// §13's fixed sample: 12 March 2026, 142,380 km, 38.42 L, 68.90, 6.4.
const FormatSample kFormatSample = FormatSample(
  isoDate: '2026-03-12',
  distance: Distance(142_380_000),
  volume: Volume(38_420),
  amount: 6890,
  consumption: 6.4,
);

/// The three preview lines for [formats].
///
/// Every interpolated value is isolate-wrapped and every number carries its
/// unit inside the SAME isolate: §5 says a figure and its unit are one atomic
/// run, and splitting them is what puts `km` on the far side of a Persian
/// line from `۱۴۲٬۳۸۰`.
///
/// The separator comes from [labels] rather than from a `' · '` here, because
/// which mark joins two facts is a translation decision — and because a Dart
/// literal is exactly what `check_status_encoding.sh` was written to find.
FormatPreview buildFormatPreview({
  required SettingsFormats formats,
  required String formatsTag,
  required FormatLabels labels,
  FormatSample sample = kFormatSample,
}) {
  String join(List<String> parts) => parts.join(labels.separator);

  final date = formatLongDate(
    sample.isoDate,
    formatsTag,
    calendar: formats.calendar,
    numerals: formats.numerals,
  );

  final distance = isolate(
    withUnitUnisolated(
      sample.distance.inUnit(formats.distanceUnit),
      labels.distance,
      formatsTag,
      numerals: formats.numerals,
      decimalDigits: 0,
    ),
  );

  final volume = isolate(
    withUnitUnisolated(
      sample.volume.inUnit(formats.volumeUnit),
      labels.volume,
      formatsTag,
      numerals: formats.numerals,
      // TWO decimals on a tankful. §5's decimals table: a pump measures to a
      // hundredth of a litre and a driver checking a receipt against the app
      // is comparing exactly those digits.
      decimalDigits: 2,
    ),
  );

  final money = formatMoney(
    Money(sample.amount, formats.currency),
    formatsTag,
    numerals: formats.numerals,
    display: formats.currencyDisplay == 'toman'
        ? CalmCurrencyDisplay.toman
        : CalmCurrencyDisplay.iso,
  );

  final consumption = isolate(
    withUnitUnisolated(
      sample.consumption,
      labels.consumption,
      formatsTag,
      numerals: formats.numerals,
      // ONE decimal. §12: the measurement is not good enough for two, and a
      // second invites the reader to compare 6.42 with 6.47 as though the
      // difference meant something.
      decimalDigits: 1,
    ),
  );

  return FormatPreview(
    dateAndDistance: join([isolate(date), distance]),
    volumeAndMoney: join([volume, money]),
    consumption: consumption,
  );
}
