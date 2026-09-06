// What a timeline row draws, decided before any widget is involved.
//
// SPEC.md §11's type table gives six row shapes and one widget to draw them
// in. What varies is the DATA, so the variation lives here and the widget
// switches once.
//
// Two rules from §11 that this file exists to hold:
//
//   1. **The consumption slot is blank or a real figure, never `0.0`.** It
//      "renders only where `buildFuelSegments` returns one for the segment
//      ending at that fill". A zero there is not a worse figure than 6.1, it
//      is a false one — the app claiming a car did 0.0 L/100 km.
//   2. **A discarded segment is visible.** §11: "The fuel engine discards data
//      silently, and a discarded segment with no visible cause is a bug report
//      we can never answer." The badges are the cause, made visible.
//
// Pure Dart, no Flutter import, no `BuildContext`.
import 'package:odova/core/fuel/fuel_segment.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/volume.dart';

/// §11's badge table, at the end of a row's primary line.
enum HistoryFlag {
  /// A part fill. It produces no figure on its own.
  partial,

  /// `chain_broken` — the tank before this one was not logged.
  chainBroken,

  /// This row is WHY a segment was thrown away.
  discardedSegment,

  /// The odometer was projected, not entered. Drawn with a leading `~`.
  estimatedOdometer,

  /// Same date, odometer within 1 km, volume within 0.1 L as another row.
  duplicate,
}

/// How close two fills must be to be called the same one.
///
/// §11 fixes both, and both are exact rather than proportional: a tolerance
/// that scaled with the odometer would call two genuine fills duplicates at
/// 400,000 km.
const Distance kDuplicateOdometerTolerance = Distance(1000);

/// 0.1 L, per §11.
const Volume kDuplicateVolumeTolerance = Volume(100);

/// How many service line labels a row names before it counts the rest.
const int kServiceLabelsShown = 2;

/// The consumption figure for the fill ending at [fillUpId], or null.
///
/// Null in every case where the engine did not close a segment there: the
/// opening fill of a chain, a part fill, a discarded segment, a lone fill.
/// §11 is unambiguous that this is a BLANK and not a zero.
///
/// The `> 0` guard is not defensive padding. A segment with zero distance or
/// zero quantity is a shape `buildFuelSegments` can produce — it discards most
/// of them, and the ones it does not are exactly where a naive division would
/// hand the screen a `0.0` or an infinity.
double? consumptionFor(
  String fillUpId,
  FuelSegmentSet segments, {
  ConsumptionUnit unit = ConsumptionUnit.lPer100km,
}) {
  for (final segment in segments.segments) {
    if (segment.toFillUpId != fillUpId) continue;
    // Through `Consumption.asUnit`, which owns this division and refuses a
    // MISMATCHED pairing. The first version did the arithmetic here as
    // `quantity.amount / 1000` — and `amount` is millilitres for petrol,
    // GRAMS for CNG and watt-hours for an EV. So a CNG row printed its
    // kilograms as though they were litres and an EV row printed its kWh the
    // same way: a plausible-looking L/100 km figure for a car that has never
    // held a litre of anything. `asUnit` returns null for those instead,
    // which §11 draws as a blank slot.
    return segment.consumption.asUnit(unit);
  }
  return null;
}

/// Which of §11's badges a fill-up row carries.
Set<HistoryFlag> fillUpFlags({
  required String id,
  required bool isFullTank,
  required bool chainBroken,
  required bool odometerEstimated,
  required bool isDuplicate,
  required FuelSegmentSet segments,
}) => {
  if (!isFullTank) HistoryFlag.partial,
  if (chainBroken) HistoryFlag.chainBroken,
  // The row is flagged when IT is the reason, which is what makes the badge
  // actionable: §11 opens the offending field in edit mode from here.
  if (segments.discarded.containsKey(id)) HistoryFlag.discardedSegment,
  if (odometerEstimated) HistoryFlag.estimatedOdometer,
  if (isDuplicate) HistoryFlag.duplicate,
};

/// Whether two fills look like the same one, per §11's three conditions.
///
/// All three, and the date is exact. Two fills a day apart at the same reading
/// are a real pair — a driver who filled up at midnight and again at one in
/// the morning has done something unusual, not something duplicated.
bool looksDuplicate({
  required String occurredOn,
  required String otherOccurredOn,
  required Distance odometer,
  required Distance otherOdometer,
  required Volume quantity,
  required Volume otherQuantity,
}) {
  if (occurredOn != otherOccurredOn) return false;
  final metres = (odometer.metres - otherOdometer.metres).abs();
  if (metres > kDuplicateOdometerTolerance.metres) return false;
  final millilitres = (quantity.millilitres - otherQuantity.millilitres).abs();
  return millilitres <= kDuplicateVolumeTolerance.millilitres;
}

/// §11's service primary line: two labels joined by `·`, then how many more.
///
/// [andMore] is supplied by the caller because this file has no
/// `BuildContext` and never will — "+2 more" is a localised, pluralised
/// string, and building it here would put English in the core.
String serviceLineSummary(
  List<String> labels, {
  required String Function(int) andMore,
}) {
  if (labels.length <= kServiceLabelsShown) return labels.join(' · ');
  final shown = labels.take(kServiceLabelsShown).join(' · ');
  return '$shown · ${andMore(labels.length - kServiceLabelsShown)}';
}
