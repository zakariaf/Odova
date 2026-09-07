// The rows `settings.units` offers, and the one rule that fills a row in for
// the user.
//
// Pure Dart, no Flutter: the option LISTS and the pairing rule are decisions
// the screen renders rather than makes, and keeping them here means they can
// be tested without a widget harness.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/numerals.dart';

/// SPEC.md §13's distance options.
const List<DistanceUnit> kDistanceOptions = DistanceUnit.values;

/// Its volume options.
///
/// Both gallons, because they are different UNITS and not variants: a US
/// gallon is 3.785 L and an imperial one 4.546 L, and offering "gal" alone
/// would make a British user's consumption wrong by 17%.
const List<VolumeUnit> kVolumeOptions = VolumeUnit.values;

/// Its consumption options.
const List<ConsumptionUnit> kConsumptionOptions = ConsumptionUnit.values;

/// Its calendar options — exactly two.
///
/// §5 ships one alternative calendar, not a catalogue: Jalali, for the users
/// whose dates genuinely are counted that way. A list of twelve would be a
/// list eleven of which nobody has checked a single date against.
const List<CalmCalendar> kCalendarOptions = CalmCalendar.values;

/// The numeral rows §13 offers, over FOUR stored values.
///
/// Three rows: `auto`, `latin`, and the locale's own — which is
/// `arabicIndic` or `extendedArabicIndic` depending on where the user is.
/// Offering both Eastern sets to everyone would ask a Persian user to choose
/// between `۴۵۶` and `٤٥٦`, a question with no meaning outside a font table.
List<CalmNumerals> numeralOptionsFor(String formatsTag) {
  final local = resolveNumerals(CalmNumerals.auto, formatsTag);
  return [
    CalmNumerals.auto,
    CalmNumerals.latin,
    // Only where the locale's default is not already Latin. A German user
    // offered a "Local" row that renders the same digits as the row above it
    // is being asked a question with one answer.
    if (local != CalmNumerals.latin) local,
  ];
}

/// The consumption unit that goes with [distance] and [volume].
///
/// SPEC.md §13 fills this in rather than asking: somebody who switches to
/// miles and gallons wants mpg, and leaving `L/100 km` selected under them
/// produces a figure that is not wrong so much as meaningless.
///
/// Returns null once the user has chosen explicitly — `chosen` is the flag
/// that stops the app overwriting a deliberate answer. A rideshare driver in
/// the US who prefers `L/100 km` picked it on purpose and must keep it.
ConsumptionUnit? suggestConsumptionUnit({
  required DistanceUnit distance,
  required VolumeUnit volume,
  required bool chosen,
}) {
  if (chosen) return null;
  return switch ((distance, volume)) {
    (DistanceUnit.km, VolumeUnit.l) => ConsumptionUnit.lPer100km,
    (DistanceUnit.mi, VolumeUnit.galUs) => ConsumptionUnit.mpgUs,
    (DistanceUnit.mi, VolumeUnit.galUk) => ConsumptionUnit.mpgUk,
    // Every other pairing — miles with litres, kilometres with gallons — is a
    // combination with no conventional unit, and inventing one would be the
    // app stating a preference the user has not got. The row keeps whatever
    // it had.
    _ => null,
  };
}
