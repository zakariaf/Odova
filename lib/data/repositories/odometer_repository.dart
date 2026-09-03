// Odometer readings and corrections.
//
// The one repository with a decision in it. Every other write either succeeds
// or fails a schema constraint; a reading is checked against the vehicle's
// whole history first, because monotonicity is a property of the SEQUENCE and
// no `CHECK` can see more than one row.
import 'package:drift/drift.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/odometer/monotonicity.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/value_equality.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/mappers/row_mappers.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/guard.dart';

/// A reading that was written, and anything worth telling the user about it.
///
/// The warnings travel with the SUCCESS, not instead of it. SPEC.md §3 is
/// explicit that all three warn and never block: a rate above 2,000 km/day is
/// real for a delivery driver on a long day, and refusing it would make the
/// app unusable for exactly the person who logs most.
class SavedReading with ValueEquality {
  /// Creates a result.
  const SavedReading(this.reading, this.warnings);

  /// What was written.
  final OdometerReading reading;

  /// What to say about it, if anything.
  final List<OdometerWarning> warnings;

  @override
  List<Object?> get props => [reading, ...warnings];
}

/// Reads and writes odometer readings and corrections.
class OdometerRepository {
  /// Creates a repository over [_db].
  const OdometerRepository(this._db);

  final AppDatabase _db;

  /// Every live reading for one vehicle, in SPEC.md §3's order.
  Stream<List<OdometerReading>> watchReadings(VehicleId vehicleId) =>
      _readingsQuery(vehicleId)
          .watch()
          .map((rows) => rows.map(odometerReadingFromRow).toList())
          .distinct(valuesEqual);

  /// Every live correction for one vehicle.
  Stream<List<OdometerCorrection>> watchCorrections(VehicleId vehicleId) =>
      (_db.select(_db.odometerCorrections)..where(
            (c) =>
                c.vehicleId.equals(vehicleId.toString()) &
                c.deletedAtUtcMs.isNull(),
          ))
          .watch()
          .map((rows) => rows.map(odometerCorrectionFromRow).toList())
          .distinct(valuesEqual);

  /// The cumulative value of every live reading for [vehicleId], by id.
  ///
  /// Computed, never stored. SPEC.md §2: a stored cumulative survives an
  /// import and is then wrong forever, with the corrections applied twice or
  /// not at all and nothing to say which.
  Future<Result<Map<String, int>, PersistFailure>> cumulativeFor(
    VehicleId vehicleId,
  ) => guardPersist(() async {
    final state = await _stateOf(vehicleId);
    return Ok(cumulativeByReading(state.readings, state.corrections));
  });

  /// Writes [reading] if the history allows it.
  ///
  /// Returns [OdometerWouldGoBackwards] carrying the conflicting neighbour and
  /// its date, because SPEC.md §3's three resolutions — fix the typo, record a
  /// correction, accept it as backdated — all need both, and NOTHING is
  /// written when it is returned.
  Future<Result<SavedReading, PersistFailure>> saveReading(
    OdometerReading reading, {
    required DistanceUnit vehicleUnit,
    int? purchaseOdometerM,
  }) => guardPersist(() async {
    final state = await _stateOf(reading.vehicleId);

    // The proposed reading is excluded from the existing set so that an EDIT
    // is checked against its neighbours rather than against itself. Without
    // this, re-saving an unchanged reading compares it to its own old value
    // and any decrease at all is refused.
    final existing = [
      for (final point in state.readings)
        if (point.id != reading.id.toString()) point,
    ];

    final verdict = checkReading(
      proposed: _pointOf(reading),
      existing: existing,
      corrections: state.corrections,
      vehicleUnit: vehicleUnit,
      purchaseOdometerM: purchaseOdometerM,
    );

    final blocked = verdict.blocked;
    if (blocked != null) {
      return Err(
        OdometerWouldGoBackwards(
          previousCumulativeM: blocked.previousCumulativeM,
          previousOccurredOn: blocked.previousOccurredOn,
          attemptedCumulativeM: blocked.attemptedCumulativeM,
        ),
      );
    }

    await _db.transaction(() async {
      await _db
          .into(_db.odometerReadings)
          .insertOnConflictUpdate(_readingCompanion(reading));
    });

    return Ok(SavedReading(reading, verdict.warnings));
  });

  /// Writes [correction].
  Future<Result<OdometerCorrection, PersistFailure>> saveCorrection(
    OdometerCorrection correction,
  ) => guardPersist(() async {
    await _db.transaction(() async {
      await _db
          .into(_db.odometerCorrections)
          .insertOnConflictUpdate(_correctionCompanion(correction));
    });
    return Ok(correction);
  });

  /// Removes [id] and reports the monotonicity breaks it was covering.
  ///
  /// SPEC.md §3: deleting a correction removes its offset and re-runs the
  /// vehicle recompute, "which may re-expose a monotonicity violation on the
  /// readings it was covering". Those readings STAY — they are facts the user
  /// entered — and the caller is told which ones now conflict so it can offer
  /// the same three resolutions rather than silently keeping numbers that no
  /// longer add up.
  Future<Result<List<OdometerReading>, PersistFailure>> deleteCorrection(
    OdometerCorrectionId id,
    VehicleId vehicleId,
  ) => guardPersist(() async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.odometerCorrections,
      )..where((c) => c.id.equals(id.toString()))).go();
    });

    final state = await _stateOf(vehicleId);
    final cumulative = cumulativeByReading(state.readings, state.corrections);
    final ordered = [...state.readings]..sort(compareReadings);

    final exposed = <OdometerReading>[];
    for (var i = 1; i < ordered.length; i++) {
      if (cumulative[ordered[i].id]! < cumulative[ordered[i - 1].id]!) {
        final row = state.rowsById[ordered[i].id]!;
        exposed.add(odometerReadingFromRow(row));
      }
    }
    return Ok(exposed);
  });

  SimpleSelectStatement<$OdometerReadingsTable, OdometerReadingRow>
  _readingsQuery(VehicleId vehicleId) => _db.select(_db.odometerReadings)
    ..where(
      (r) =>
          r.vehicleId.equals(vehicleId.toString()) & r.deletedAtUtcMs.isNull(),
    )
    ..orderBy([
      (r) => OrderingTerm(expression: r.occurredOn),
      (r) => OrderingTerm(expression: r.createdAtUtcMs),
    ]);

  Future<_VehicleOdometerState> _stateOf(VehicleId vehicleId) async {
    final readingRows = await _readingsQuery(vehicleId).get();
    final correctionRows =
        await (_db.select(_db.odometerCorrections)..where(
              (c) =>
                  c.vehicleId.equals(vehicleId.toString()) &
                  c.deletedAtUtcMs.isNull(),
            ))
            .get();

    return _VehicleOdometerState(
      readings: readingRows.map(_pointOfRow).toList(),
      corrections: [
        for (final row in correctionRows)
          (
            fromReadingId: row.fromReadingId,
            previousM: row.previousM,
            newM: row.newM,
          ),
      ],
      rowsById: {for (final row in readingRows) row.id: row},
    );
  }

  ReadingPoint _pointOf(OdometerReading reading) => (
    id: reading.id.toString(),
    occurredOn: reading.occurredOn,
    createdAtUtcMs: reading.createdAtUtcMs,
    odometerM: reading.odometerM,
  );

  ReadingPoint _pointOfRow(OdometerReadingRow row) => (
    id: row.id,
    occurredOn: row.occurredOn,
    createdAtUtcMs: row.createdAtUtcMs,
    odometerM: row.odometerM,
  );

  OdometerReadingsCompanion _readingCompanion(OdometerReading reading) =>
      OdometerReadingsCompanion.insert(
        id: reading.id.toString(),
        createdAtUtcMs: reading.createdAtUtcMs,
        updatedAtUtcMs: reading.updatedAtUtcMs,
        vehicleId: reading.vehicleId.toString(),
        occurredOn: reading.occurredOn,
        odometerM: reading.odometerM,
        odometerUnit: reading.odometerUnit.wire,
        source: reading.source.wire,
        sourceId: Value(reading.sourceId),
        notes: Value(reading.notes),
      );

  OdometerCorrectionsCompanion _correctionCompanion(
    OdometerCorrection correction,
  ) => OdometerCorrectionsCompanion.insert(
    id: correction.id.toString(),
    createdAtUtcMs: correction.createdAtUtcMs,
    updatedAtUtcMs: correction.updatedAtUtcMs,
    vehicleId: correction.vehicleId.toString(),
    fromReadingId: correction.fromReadingId.toString(),
    previousM: correction.previousM,
    newM: correction.newM,
    odometerUnit: correction.odometerUnit.wire,
    reason: correction.reason.wire,
  );
}

/// One vehicle's readings and corrections, read once for a decision.
class _VehicleOdometerState {
  const _VehicleOdometerState({
    required this.readings,
    required this.corrections,
    required this.rowsById,
  });

  final List<ReadingPoint> readings;
  final List<CorrectionPoint> corrections;
  final Map<String, OdometerReadingRow> rowsById;
}
