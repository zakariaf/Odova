// The cumulative odometer: what the app COMPUTES with.
//
// SPEC.md §3 The odometer: continuity and corrections.
//
//   cumulative_m(reading) = reading.odometer_m
//                         + Σ (c.previous_m − c.new_m) for every correction c
//                           whose from_reading_id sorts at or before `reading`
//
// Pure Dart, no Flutter, no database. It is a FUNCTION and never a column:
// SPEC.md §2 forbids persisting a derived value, and a stored cumulative
// survives an import and is then wrong forever — the corrections would be
// applied twice, or not at all, and nothing would say which.
import 'package:meta/meta.dart';
import 'package:odova/core/units/distance.dart';

/// One reading, reduced to what the arithmetic needs.
///
/// Deliberately not the Drift row: this is domain code and lives above the
/// data layer's shapes, so the fold can be tested with three records and no
/// database.
typedef ReadingPoint = ({
  String id,
  String occurredOn,
  int createdAtUtcMs,
  Distance odometer,
});

/// One correction, reduced the same way.
typedef CorrectionPoint = ({
  String fromReadingId,
  Distance previous,
  Distance replacement,
});

/// Orders readings the way SPEC.md §3 does: `(occurred_on, created_at)`.
///
/// The tiebreak is what makes the correction boundary deterministic. Two
/// readings entered on the same date order by when they were CREATED, so
/// "at or after the correction's reading" is a total order and not a coin
/// toss — and the id breaks a tie in created_at, which a ULID makes free.
int compareReadings(ReadingPoint a, ReadingPoint b) {
  final byDate = a.occurredOn.compareTo(b.occurredOn);
  if (byDate != 0) return byDate;
  final byCreated = a.createdAtUtcMs.compareTo(b.createdAtUtcMs);
  if (byCreated != 0) return byCreated;
  return a.id.compareTo(b.id);
}

/// The cumulative value of every reading, keyed by id.
///
/// [readings] need not be sorted; [corrections] are matched to their boundary
/// reading by `fromReadingId`. A correction naming a reading that is not in
/// [readings] is IGNORED rather than guessed at — it is either deleted or from
/// another vehicle, and applying its offset to everything would silently move
/// a whole history.
@useResult
Map<String, Distance> cumulativeByReading(
  Iterable<ReadingPoint> readings,
  Iterable<CorrectionPoint> corrections,
) => cumulativeBySorted([...readings]..sort(compareReadings), corrections);

/// [cumulativeByReading] over readings ALREADY in [compareReadings] order.
///
/// Split out because `checkReading` needs the sorted list for itself — it has
/// to find the proposed reading's neighbours — and was sorting the same list
/// twice per save: once here and once for the neighbour lookup. That runs on
/// every fill-up, service, expense and trip write, over the vehicle's entire
/// reading history, on the path a user is standing at a pump waiting for.
///
/// Passing an unsorted list here produces a wrong answer rather than a slow
/// one, which is why the public entry point above exists at all.
@useResult
Map<String, Distance> cumulativeBySorted(
  List<ReadingPoint> sorted,
  Iterable<CorrectionPoint> corrections,
) {
  final byId = {for (final r in sorted) r.id: r};

  // Each correction's offset, placed at its boundary reading's position.
  final offsetAt = <String, Distance>{};
  for (final correction in corrections) {
    final boundary = byId[correction.fromReadingId];
    if (boundary == null) continue;
    offsetAt[boundary.id] =
        (offsetAt[boundary.id] ?? Distance.zero) +
        (correction.previous - correction.replacement);
  }

  // One pass forward, accumulating. "At or after" means the offset is added
  // when the boundary reading itself is reached — the boundary is the FIRST
  // reading on the new scale, so it is corrected too.
  final result = <String, Distance>{};
  var running = Distance.zero;
  for (final reading in sorted) {
    running += offsetAt[reading.id] ?? Distance.zero;
    result[reading.id] = reading.odometer + running;
  }
  return result;
}
