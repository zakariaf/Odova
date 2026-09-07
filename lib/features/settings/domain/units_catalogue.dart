// The rows `settings.units` offers, and the one rule that fills a row in for
// the user.
//
// Pure Dart, no Flutter: the option LISTS and the pairing rule are decisions
// the screen renders rather than makes, and keeping them here means they can
// be tested without a widget harness.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/l10n/numerals.dart';

// The distance, volume, consumption and calendar rows offer every value of
// their enum, so the screen passes `.values` directly rather than through a
// const alias that filters nothing. Four aliases here documented curation the
// code did not do — and the doc on the volume one described a decision that
// lives in the ENUM: both gallons are there because they are different units
// and not variants, a US gallon being 3.785 L and an imperial one 4.546 L, so
// offering "gal" alone makes a British user's consumption wrong by 17%.
//
// `numeralOptionsFor` below is the one that really does subset, and it is a
// function for that reason.

/// The numeral rows §13 offers, over FOUR stored values.
///
/// `auto`, `latin`, and the local set — which is `arabicIndic` or
/// `extendedArabicIndic` depending on the user. Offering both Eastern sets to
/// everyone would ask a Persian user to choose between `۴۵۶` and `٤٥٦`, a
/// question with no meaning outside a font table.
///
/// Both tags are consulted, and the reason is a real user: §5 keeps FORMATS
/// with the region and STRINGS with the language, so a Persian speaker on a
/// British phone reads Persian words and British numbers. Keying the local
/// row on the formats tag alone would offer them Latin and Latin — no way to
/// choose Persian digits at all — and keying it on the language alone would
/// offer an English speaker in Iran a row for a script they do not read.
List<CalmNumerals> numeralOptionsFor(String formatsTag, {String? stringsTag}) {
  final locals = <CalmNumerals>{
    resolveNumerals(CalmNumerals.auto, formatsTag),
    if (stringsTag != null) resolveNumerals(CalmNumerals.auto, stringsTag),
  };
  return [
    CalmNumerals.auto,
    CalmNumerals.latin,
    // Only where a local set is not already Latin. A German user offered a
    // "Local" row that renders the same digits as the row above it is being
    // asked a question with one answer.
    for (final local in locals)
      if (local != CalmNumerals.latin) local,
  ];
}

/// The consumption units some pairing implies.
///
/// Membership is how the app tells a DEFAULT from a CHOICE without a stored
/// flag. `km/L`, `kWh/100 km` and `mi/kWh` are in nobody's pairing, so a user
/// showing one of them picked it — and must keep it.
///
/// The rule this replaced compared against what the PREVIOUS pairing implied,
/// which is path-dependent and loses the choice: pick `km/L` on km and litres,
/// switch volume to US gallons (nothing happens, correctly — km with gallons
/// implies nothing), then switch distance to miles, and the previous pairing
/// implied null, so the app read that as "not chosen" and overwrote `km/L`
/// with mpg. §13: never override an explicit choice again.
const Set<ConsumptionUnit> kSuggestibleConsumptionUnits = {
  ConsumptionUnit.lPer100km,
  ConsumptionUnit.mpgUs,
  ConsumptionUnit.mpgUk,
};

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
