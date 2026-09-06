// What a form in EDIT mode shows above its fields.
//
// SPEC.md §11: "There is no read-only detail screen. Tapping a history row
// opens the same form that created the record, prefilled … with a context band
// pinned above the fields carrying what the form cannot: the derived numbers
// this record participates in, and what it is attached to."
//
// And why it is a band: "the numbers are the reason someone opened the row,
// and they are three lines. A page that shows three lines and an Edit button
// costs a tap and teaches nothing."
//
// Every DECISION lives here — which sentence, which figure, whether there is
// one at all — so the widget formats and never chooses. A band that says the
// wrong thing then fails in a pure test rather than in a screenshot.
//
// Pure Dart, no Flutter import.
import 'package:meta/meta.dart';
import 'package:odova/core/time/civil_date.dart';

/// Why a fill-up has no consumption figure.
///
/// §11 gives each one a sentence, and a row gets exactly ONE.
enum FillUpNoFigure {
  /// Nothing before it to measure from.
  firstFill,

  /// The tank before this one was not logged.
  chainBroken,

  /// A part fill produces no figure on its own.
  partialFill,
}

/// A fill-up's band: either the figure or the reason there is none.
@immutable
sealed class FillUpBand {
  /// Creates a band.
  const FillUpBand();
}

/// The segment closed at this fill.
@immutable
final class FillUpBandFigure extends FillUpBand {
  /// Creates the band.
  const FillUpBandFigure({
    required this.consumption,
    required this.segmentDistanceM,
    required this.sinceOccurredOn,
    required this.unitPriceMinor,
  });

  /// Litres per 100 km, or the equivalent for this fuel form.
  final double consumption;

  /// How far the segment covered.
  final int? segmentDistanceM;

  /// The date the segment opened.
  final String? sinceOccurredOn;

  /// Price per unit, in minor units. §11 shows it to three decimals.
  final int? unitPriceMinor;
}

/// No figure, and the one sentence that says why.
@immutable
final class FillUpBandReason extends FillUpBand {
  /// Creates the band.
  const FillUpBandReason(this.reason);

  /// Which of §11's three sentences applies.
  final FillUpNoFigure reason;

  @override
  bool operator ==(Object other) =>
      other is FillUpBandReason && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}

/// The band for one fill-up.
///
/// The ORDER of the three reasons is a decision, not an accident. A partial
/// fill on a broken chain is reported as a partial fill: that is what the USER
/// did, and it is the thing they can change. The broken chain is what happened
/// to them, and naming it would explain the wrong half.
FillUpBand fillUpBand({
  required double? consumption,
  required bool isFullTank,
  required bool chainBroken,
  required bool isFirstFill,
  int? segmentDistanceM,
  String? segmentFromOccurredOn,
  int? unitPriceMinor,
}) {
  if (consumption != null) {
    return FillUpBandFigure(
      consumption: consumption,
      segmentDistanceM: segmentDistanceM,
      sinceOccurredOn: segmentFromOccurredOn,
      unitPriceMinor: unitPriceMinor,
    );
  }
  if (!isFullTank) return const FillUpBandReason(FillUpNoFigure.partialFill);
  if (isFirstFill) return const FillUpBandReason(FillUpNoFigure.firstFill);
  if (chainBroken) return const FillUpBandReason(FillUpNoFigure.chainBroken);
  // Everything else that produces no segment — a missing odometer, a
  // discarded neighbour — reads as a broken chain, which is what it is from
  // the user's side: the tank before this one did not produce a figure.
  return const FillUpBandReason(FillUpNoFigure.chainBroken);
}

/// An expense's coverage window, spread over the months it covers.
@immutable
class ExpenseBand {
  /// Creates the band.
  const ExpenseBand({required this.months, required this.perMonthMinor});

  /// How many months the window spans. Never zero.
  final int months;

  /// One month's share, in minor units.
  final int perMonthMinor;
}

/// The band for one expense, or null when it covers no period.
///
/// §11: "€ 480.00 over 12 months = € 40.00 a month."
///
/// The division FLOORS, so twelve shares never add up to more than was paid.
/// Rounding each share up would show a user a year that costs more than their
/// policy did, on the one screen they opened to check the number.
ExpenseBand? expenseBand({
  required int amountMinor,
  required String? coversFrom,
  required String? coversTo,
}) {
  final from = CivilDate.tryParse(coversFrom ?? '');
  final to = CivilDate.tryParse(coversTo ?? '');
  if (from == null || to == null || to < from) return null;

  final months = _monthsBetween(from, to);
  return ExpenseBand(
    months: months,
    perMonthMinor: amountMinor ~/ months,
  );
}

/// How many calendar months a window touches, at least one.
///
/// At least one because a week-long policy is a month's share of itself, not a
/// division by zero.
int _monthsBetween(CivilDate from, CivilDate to) {
  final months = (to.year - from.year) * 12 + (to.month - from.month) + 1;
  return months < 1 ? 1 : months;
}

/// A reading's distance, its days and the rate they imply.
@immutable
class OdometerBand {
  /// Creates the band.
  const OdometerBand({
    required this.metres,
    required this.days,
    required this.metresPerDay,
  });

  /// How far since the previous reading.
  final int metres;

  /// How many days that took.
  final int days;

  /// Metres a day, or null when the two readings share a date.
  ///
  /// Null and not an infinity. Two readings on one day are a correction or a
  /// second entry, not a car that drove infinitely fast, and §2 forbids the
  /// app inventing a figure that looks like a fact.
  final int? metresPerDay;
}

/// The band for one odometer reading, or null with nothing before it.
OdometerBand? odometerBand({
  required int metres,
  required String? sinceOccurredOn,
  required String occurredOn,
}) {
  final from = CivilDate.tryParse(sinceOccurredOn ?? '');
  final to = CivilDate.tryParse(occurredOn);
  if (from == null || to == null) return null;

  final days = from.daysUntil(to);
  return OdometerBand(
    metres: metres,
    days: days,
    metresPerDay: days > 0 ? metres ~/ days : null,
  );
}
