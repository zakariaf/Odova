// SPEC.md §8's four annual-distance bands, and the metres each one stores.
//
// The screen asks "About how far a year?" once, at first run, and the answer
// becomes `Vehicle.expected_annual_m` — the projection's fallback until there
// is enough odometer history to measure. Without it a delivery driver and a
// pensioner get the same guess.
//
// **The numbers are SPEC's, settled by EPIC-09's F-9.1.** §8 drew four chips
// and named no value for any of them; the table now lives in §8 and this file
// transcribes it. Nothing here is derived at runtime and nothing is invented.
//
// Pure Dart, no Flutter import.
import 'package:odova/core/units/distance.dart';

/// One of the four bands, in the order they are drawn.
enum AnnualBand {
  /// Under ten thousand km, or six thousand miles.
  lowest(
    kmEdges: (min: null, max: 10),
    miEdges: (min: null, max: 6),
    km: 5000,
    mi: 3000,
  ),

  /// Ten to twenty thousand km. The default.
  lower(
    kmEdges: (min: 10, max: 20),
    miEdges: (min: 6, max: 12),
    km: 15000,
    mi: 9000,
  ),

  /// Twenty to thirty thousand km.
  higher(
    kmEdges: (min: 20, max: 30),
    miEdges: (min: 12, max: 18),
    km: 25000,
    mi: 15000,
  ),

  /// Over thirty thousand km. Open-ended.
  highest(
    kmEdges: (min: 30, max: null),
    miEdges: (min: 18, max: null),
    km: 40000,
    mi: 24000,
  );

  const AnnualBand({
    required this.kmEdges,
    required this.miEdges,
    required this.km,
    required this.mi,
  });

  /// SPEC.md §8's prefill.
  static const AnnualBand defaultBand = lower;

  /// The chip's boundary numbers in kilometres. A null end is open.
  final ({int? min, int? max}) kmEdges;

  /// The same boundaries in miles — round mile numbers, NOT the kilometre
  /// figures converted. §4.8: "a miles user gets 6,000 mi, not 9,656 km
  /// rendered as 6,000."
  final ({int? min, int? max}) miEdges;

  /// The stored value in whole kilometres.
  ///
  /// Public because this enum is a transcription of SPEC.md §8's table and
  /// hiding a column of it buys nothing. [metresFor] is how the app asks.
  final int km;

  /// The stored value in whole miles. See [km].
  final int mi;

  /// What this band writes to `Vehicle.expected_annual_m`, in metres.
  ///
  /// The round number in the user's own unit, converted ONCE and exactly on the
  /// way into storage — §2 keeps metres and only metres, and 1,609.344 m is the
  /// international mile by definition.
  int metresFor(DistanceUnit unit) => unit == DistanceUnit.mi
      ? Distance.fromMiles(mi).metres
      : Distance.fromKm(km).metres;

  /// The chip's boundaries in [unit], for the label.
  ///
  /// Numbers rather than a formatted string, because the active numbering
  /// system shapes them at the last moment — and because an ARB value with a
  /// literal digit in it is rejected by the gate for exactly that reason.
  ({int? min, int? max}) edgesFor(DistanceUnit unit) =>
      unit == DistanceUnit.mi ? miEdges : kmEdges;
}
