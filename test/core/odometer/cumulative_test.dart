// The cumulative fold, against SPEC.md §3's own worked cases.
//
// A wrong answer here is not a crash. It is a consumption figure, a projected
// due date and a cost-per-km that are all quietly wrong, computed from a
// distance history that reads plausibly.
import 'dart:io';

import 'package:odova/core/odometer/cumulative.dart';
import 'package:test/test.dart';

/// A reading, with the fields that matter and defaults for the rest.
ReadingPoint reading(
  String id,
  String occurredOn,
  int odometerM, {
  int createdAtUtcMs = 0,
}) => (
  id: id,
  occurredOn: occurredOn,
  createdAtUtcMs: createdAtUtcMs,
  odometerM: odometerM,
);

const _km = 1000;

void main() {
  test('cumulative equals the raw reading when there are no corrections', () {
    final readings = [
      reading('odo_1', '2026-01-01', 180000 * _km),
      reading('odo_2', '2026-03-01', 185000 * _km),
      reading('odo_3', '2026-06-01', 190000 * _km),
    ];

    expect(cumulativeByReading(readings, const []), {
      'odo_1': 180000 * _km,
      'odo_2': 185000 * _km,
      'odo_3': 190000 * _km,
    });
  });

  test('a cluster replaced at 187,412 km reading zero adds +187,412 km', () {
    // SPEC.md §3's worked case, exactly.
    final readings = [
      reading('odo_1', '2026-01-01', 180000 * _km),
      reading('odo_2', '2026-06-01', 187412 * _km),
      reading('odo_3', '2026-06-02', 0), // the new cluster, from zero
      reading('odo_4', '2026-09-01', 3000 * _km),
    ];
    const corrections = [
      (fromReadingId: 'odo_3', previousM: 187412 * _km, newM: 0),
    ];

    final cumulative = cumulativeByReading(readings, corrections);

    expect(cumulative['odo_1'], 180000 * _km);
    expect(cumulative['odo_2'], 187412 * _km);
    // The boundary reading is ITSELF on the new scale, so it is corrected.
    expect(cumulative['odo_3'], 187412 * _km);
    expect(cumulative['odo_4'], 190412 * _km);

    // And the history is still monotonic in cumulative terms, which is the
    // whole point of the offset.
    final values = readings.map((r) => cumulative[r.id]!).toList();
    expect(values, orderedEquals(<int>[...values]..sort()));
  });

  test('a 999,999 rollover adds +1,000,000 km', () {
    final readings = [
      reading('odo_1', '2026-01-01', 999999 * _km),
      reading('odo_2', '2026-01-02', 12 * _km),
    ];
    const corrections = [
      (fromReadingId: 'odo_2', previousM: 999999 * _km, newM: 0),
    ];

    final cumulative = cumulativeByReading(readings, corrections);
    expect(cumulative['odo_2'], (999999 + 12) * _km);
    expect(cumulative['odo_2']! - cumulative['odo_1']!, 12 * _km);
  });

  test('a correction applies at or after its reading, never before', () {
    final readings = [
      reading('odo_1', '2026-01-01', 100 * _km),
      reading('odo_2', '2026-02-01', 200 * _km),
      reading('odo_3', '2026-03-01', 300 * _km),
    ];
    const corrections = [
      (fromReadingId: 'odo_2', previousM: 5000 * _km, newM: 0),
    ];

    final cumulative = cumulativeByReading(readings, corrections);
    expect(cumulative['odo_1'], 100 * _km, reason: 'before the boundary');
    expect(cumulative['odo_2'], (200 + 5000) * _km, reason: 'the boundary');
    expect(cumulative['odo_3'], (300 + 5000) * _km, reason: 'after it');
  });

  test('two corrections both carry forward, in order', () {
    final readings = [
      reading('odo_1', '2026-01-01', 100 * _km),
      reading('odo_2', '2026-02-01', 0),
      reading('odo_3', '2026-03-01', 50 * _km),
      reading('odo_4', '2026-04-01', 0),
      reading('odo_5', '2026-05-01', 10 * _km),
    ];
    const corrections = [
      (fromReadingId: 'odo_2', previousM: 100 * _km, newM: 0),
      (fromReadingId: 'odo_4', previousM: 50 * _km, newM: 0),
    ];

    final cumulative = cumulativeByReading(readings, corrections);
    expect(cumulative['odo_5'], (100 + 50 + 10) * _km);
  });

  test('readings sort by (occurred_on, created_at)', () {
    // Two readings on the same date order by CREATION, which is what makes
    // the correction boundary deterministic: without it, "at or after" over a
    // same-day pair depends on whatever order the rows came back in.
    final readings = [
      reading('odo_b', '2026-01-01', 200 * _km, createdAtUtcMs: 2000),
      reading('odo_a', '2026-01-01', 100 * _km, createdAtUtcMs: 1000),
    ];
    const corrections = [
      (fromReadingId: 'odo_b', previousM: 900 * _km, newM: 0),
    ];

    final cumulative = cumulativeByReading(readings, corrections);
    expect(cumulative['odo_a'], 100 * _km, reason: 'created first');
    expect(cumulative['odo_b'], (200 + 900) * _km, reason: 'created second');
  });

  test('the id breaks a tie in created_at', () {
    // A ULID makes this free and deterministic. Without it, two readings
    // written in the same millisecond order arbitrarily.
    final a = reading('odo_A', '2026-01-01', 1, createdAtUtcMs: 5);
    final b = reading('odo_B', '2026-01-01', 2, createdAtUtcMs: 5);
    expect(compareReadings(a, b), isNegative);
    expect(compareReadings(b, a), isPositive);
    expect(compareReadings(a, a), 0);
  });

  test('a correction naming an absent reading is ignored, not guessed at', () {
    // It is either deleted or from another vehicle. Applying its offset to
    // everything would silently move a whole history, which is the failure
    // mode SPEC.md §2 puts above every feature.
    final readings = [reading('odo_1', '2026-01-01', 100 * _km)];
    const corrections = [
      (fromReadingId: 'odo_gone', previousM: 5000 * _km, newM: 0),
    ];

    expect(cumulativeByReading(readings, corrections), {'odo_1': 100 * _km});
  });

  test('an unsorted input gives the same answer as a sorted one', () {
    final ordered = [
      reading('odo_1', '2026-01-01', 100 * _km),
      reading('odo_2', '2026-02-01', 0),
      reading('odo_3', '2026-03-01', 50 * _km),
    ];
    const corrections = [
      (fromReadingId: 'odo_2', previousM: 100 * _km, newM: 0),
    ];

    expect(
      cumulativeByReading(ordered.reversed, corrections),
      cumulativeByReading(ordered, corrections),
    );
  });

  test('the fold is pure Dart with no database in it', () {
    // It is domain logic, so it tests with three records and no harness, and
    // it cannot reach a row shape. The companion half of this rule — that no
    // COLUMN stores a cumulative value — is asserted against the real schema
    // in test/data/db/schema_reality_test.dart, because that is where a
    // regression would actually appear.
    final source = File('lib/core/odometer/cumulative.dart').readAsStringSync();
    for (final banned in ['package:drift', 'package:flutter', 'dart:ui']) {
      expect(source, isNot(contains(banned)), reason: banned);
    }
  });
}
