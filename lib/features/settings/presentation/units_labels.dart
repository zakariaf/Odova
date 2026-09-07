// The words `settings.units` puts beside each row, and the sample its preview
// renders.
//
// Split from the screen because every one of these is a lookup the format
// preview also needs, and because a switch over an enum belongs where it can
// be exhaustive: adding a unit should stop the build here rather than render
// an empty row.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/features/settings/domain/format_preview.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/vehicle_labels.dart';

/// A distance unit's row value — `Kilometres (km)`.
String distanceOptionLabel(AppLocalizations l10n, DistanceUnit unit) =>
    switch (unit) {
      DistanceUnit.km => l10n.unitsDistanceKm,
      DistanceUnit.mi => l10n.unitsDistanceMi,
    };

/// A volume unit's row value.
String volumeOptionLabel(AppLocalizations l10n, VolumeUnit unit) =>
    switch (unit) {
      VolumeUnit.l => l10n.unitsVolumeLitre,
      VolumeUnit.galUs => l10n.unitsVolumeGalUs,
      VolumeUnit.galUk => l10n.unitsVolumeGalUk,
    };

/// A volume unit's short word, for the preview line.
String volumeUnitLabel(AppLocalizations l10n, VolumeUnit unit) =>
    unit == VolumeUnit.l ? l10n.unitVolumeLitre : l10n.unitVolumeGallon;

/// A consumption unit's label, with its `100` already shaped.
///
/// The hundred is a PLACEHOLDER, never a baked literal: `arb_template_test`
/// refuses a digit in copy because a baked one cannot be shaped, and a Latin
/// `100` inside an Arabic-Indic line is the mixed render §5 forbids.
/// The SAME mapping `glance_tiles.dart` uses, and it has to be: four units
/// collapsed onto `mpg` here meant a user who picked `km/L` read `6.4 mpg` on
/// this screen and `6.4 km/L` on Home for one stored value — a figure under
/// the wrong unit, off by the 2.35 between them. It also made US and imperial
/// gallons unpickable, which is the 17% difference `units_catalogue.dart`
/// names by name.
String consumptionOptionLabel(
  AppLocalizations l10n,
  ConsumptionUnit unit,
  String hundred,
) => switch (unit) {
  ConsumptionUnit.lPer100km => l10n.unitConsumptionPerDistance(hundred),
  ConsumptionUnit.kwhPer100km => l10n.unitConsumptionKwhPerDistance(hundred),
  ConsumptionUnit.kmPerL => l10n.unitConsumptionKmPerLitre,
  ConsumptionUnit.mpgUs => l10n.unitConsumptionMpgUs,
  ConsumptionUnit.mpgUk => l10n.unitConsumptionMpgUk,
  ConsumptionUnit.miPerKwh => l10n.unitConsumptionMiPerKwh,
};

/// A calendar's row value.
String calendarOptionLabel(AppLocalizations l10n, CalmCalendar calendar) =>
    switch (calendar) {
      CalmCalendar.gregorian => l10n.unitsCalendarGregorian,
      CalmCalendar.persian => l10n.unitsCalendarPersian,
    };

/// A numeral option's row value, with a SAMPLE of the digits it selects.
///
/// The sample answers the question the row asks: a Persian user reading
/// `محلی (۰–۹)` can see what they are choosing without applying it first.
String numeralsOptionLabel(
  AppLocalizations l10n,
  CalmNumerals option,
  String formatsTag,
) => switch (option) {
  CalmNumerals.auto => l10n.unitsNumeralsAuto,
  CalmNumerals.latin => l10n.unitsNumeralsLatin(digitSample(option)),
  CalmNumerals.arabicIndic ||
  CalmNumerals.extendedArabicIndic => l10n.unitsNumeralsLocal(
    digitSample(option),
  ),
};

/// `0–9` in [numerals]' own block.
///
/// An EN DASH between them, not a hyphen: it is a range, and §5's typography
/// rules apply to a sample of digits as much as to a date range.
String digitSample(CalmNumerals numerals) =>
    '${shapeDigits('0', numerals)}–${shapeDigits('9', numerals)}';

/// The labels the preview needs, resolved once.
FormatLabels formatLabelsFor(
  AppLocalizations l10n,
  DistanceUnit distance,
  VolumeUnit volume,
  ConsumptionUnit consumption,
  String hundred,
) => (
  distance: distanceUnitLabel(l10n, distance),
  volume: volumeUnitLabel(l10n, volume),
  consumption: consumptionOptionLabel(l10n, consumption, hundred),
  // From the ARB, not a `' · '` here: which mark joins two facts is a
  // translation decision, and a Dart literal takes it away from the
  // translator.
  separator: l10n.commonSeparator,
);
