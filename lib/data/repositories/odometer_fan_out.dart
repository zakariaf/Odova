// Every record carrying an odometer emits a reading.
//
// SPEC.md §3: "EVERY record carrying an odometer emits a reading: one table
// computes distance history and enforces monotonicity." So a fill-up, a
// service, an expense and a trip each contribute theirs automatically — and
// this file is the ONLY writer of a non-manual reading. Four repositories
// writing their own would be four chances to disagree about the id, the source
// or the date, and the symptom would be a distance history with duplicates
// nobody can attribute.
//
// Every function here runs INSIDE the caller's transaction. A derived reading
// written in a second transaction is a moment where the parent exists and its
// reading does not, and a monotonicity check in between sees a history with a
// hole in it.
import 'package:drift/drift.dart' show Variable;
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/ids/ulid.dart';
import 'package:odova/core/odometer/monotonicity.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/mappers/row_mappers.dart';
import 'package:odova/data/failures/persist_failure.dart';

/// Writes, updates or removes the derived reading for one parent row.
///
/// The existing reading is found by `(source_id, source)` rather than by an id
/// constructed from the parent's. A constructed id would make the upsert a
/// one-liner, but SPEC.md §3 fixes every id in the app as `<prefix>_<ULID>` —
/// in the database, in the export file and in every notification payload — and
/// `odo~fil_01J…` is none of those. It would also fail `RecordId.parse` on the
/// way back out, so the row could be written and never read.
///
/// `(source_id, source)` is the right key anyway: a trip carries two readings
/// and they differ by `source` alone, so one lookup shape covers all five
/// parents.
///
/// [odometerM] null means the parent carries no reading — an expense without
/// one, or a trip with no start — and any existing derived reading is DELETED
/// rather than left behind. A stale reading from a value the user cleared is a
/// number in the distance history that nothing on screen explains.
Future<void> syncDerivedReading(
  AppDatabase db, {
  required UlidFactory ids,
  required String parentId,
  required VehicleId vehicleId,
  required OdometerSource source,
  required String occurredOn,
  required DistanceUnit odometerUnit,
  required int? odometerM,
  required int nowUtcMs,
}) async {
  if (odometerM == null) {
    // SOFT-deleted, never hard-deleted, and that is not tidiness.
    // `odometer_corrections.from_reading_id` is `ON DELETE CASCADE`, and the
    // reading a correction is anchored to is very often a derived one — a
    // fill-up is the commonest reading source, and a cluster gets swapped
    // between fill-ups. A hard delete here silently took the correction with
    // it: clearing one fill-up's odometer removed +187,412 km of offset from
    // every later reading, the save returned success, and nothing on screen
    // explained why the lifetime distance had changed.
    //
    // A soft delete leaves the row for the foreign key to point at, and the
    // purge that eventually removes it is the same one that removes the
    // correction — together, after the Undo window, rather than silently on an
    // edit.
    await db.customStatement(
      'UPDATE odometer_readings SET deleted_at_utc_ms = ? '
      'WHERE source_id = ? AND source = ? AND deleted_at_utc_ms IS NULL;',
      [nowUtcMs, parentId, source.wire],
    );
    return;
  }

  // ONE statement, on `idx_readings_source`. It was a SELECT and then an
  // INSERT or an UPDATE — two round trips inside the write transaction, and
  // the SELECT was a full table scan because nothing indexed `source_id`. That
  // ran on every fill-up, service and expense save, and twice on a trip, under
  // `synchronous = FULL`, on the save somebody makes standing at a pump.
  //
  // The `WHERE source_id IS NOT NULL` on the conflict target is not optional:
  // `idx_readings_source` is a PARTIAL unique index, and SQLite only matches a
  // conflict target to one when the predicates match too. Without it the
  // statement fails with "ON CONFLICT clause does not match any PRIMARY KEY or
  // UNIQUE constraint" — inside the write transaction, so the save returns an
  // Err and NO reading is written at all. The index is partial on purpose: a
  // manual reading has no `source_id` and has no business occupying it.
  //
  // The id is minted unconditionally and discarded on the update path. That is
  // one ULID and costs nothing; reading the row first to find out whether it
  // was needed is what cost something.
  await db.customStatement(
    '''
      INSERT INTO odometer_readings (
        id, vehicle_id, occurred_on, odometer_m, odometer_unit, source,
        source_id, created_at_utc_ms, updated_at_utc_ms
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (source_id, source) WHERE source_id IS NOT NULL
      DO UPDATE SET
        -- `vehicle_id` is in the SET list, and leaving it out was a silent
        -- corruption. The conflict key is `(source_id, source)`, which is
        -- vehicle-INDEPENDENT, so re-parenting a fill-up to another car
        -- updated its reading in place: the row stayed on the OLD vehicle and
        -- took the NEW vehicle's odometer. The old car's history then carried
        -- a 5,000 km reading among its 100,000 km ones — non-monotonic at a
        -- point no guard had looked at, because the guard validated against
        -- the new vehicle — and the new car's fill-up had no reading at all.
        vehicle_id = excluded.vehicle_id,
        occurred_on = excluded.occurred_on,
        odometer_m = excluded.odometer_m,
        odometer_unit = excluded.odometer_unit,
        updated_at_utc_ms = excluded.updated_at_utc_ms,
        deleted_at_utc_ms = NULL;
    ''',
    [
      OdometerReadingId.mint(ids).toString(),
      vehicleId.toString(),
      occurredOn,
      odometerM,
      odometerUnit.wire,
      source.wire,
      parentId,
      nowUtcMs,
      nowUtcMs,
    ],
  );
}

/// Whether the reading [parentId] is about to emit would break monotonicity.
///
/// Returns the failure, or null when the write may proceed.
///
/// **Called BEFORE the parent's transaction opens**, by each of the four
/// repositories that emit a reading. `syncDerivedReading` writes with a raw
/// upsert and cannot itself refuse — it runs inside a transaction, so throwing
/// from it would surface through `guardPersist` as an unclassified write
/// error rather than as the typed failure SPEC.md §3's three resolutions need.
///
/// Without this, four of the five write paths into `odometer_readings` skipped
/// the guard entirely: a fill-up whose odometer went backwards was accepted,
/// and the distance history it feeds was non-monotonic from that point on —
/// which is a wrong consumption figure, a wrong projection and a wrong cost per
/// km, all of them plausible-looking.
Future<PersistFailure?> checkDerivedReading(
  AppDatabase db, {
  required String parentId,
  required VehicleId vehicleId,
  required OdometerSource source,
  required String occurredOn,
  required int? odometerM,
  required int nowUtcMs,
}) async {
  if (odometerM == null) return null;

  // The vehicle's own unit and purchase odometer, read here rather than passed
  // in. Making every caller supply them would put the same two arguments on
  // four `save` signatures and on every call site in the app, for values the
  // database already holds one primary-key lookup away.
  //
  // A null `distance_unit` means inherit from Settings, and this does NOT
  // chase that: the unit affects only the km/mi mix-up WARNING, never the
  // block, and a warning raised by a derived reading has nowhere to surface
  // yet. `km` is the fallback, and the consequence of it being wrong is one
  // unshown warning rather than a wrong answer.
  final vehicle = await db
      .customSelect(
        'SELECT distance_unit, purchase_odometer_m FROM vehicles '
        'WHERE id = ?;',
        variables: [Variable.withString(vehicleId.toString())],
      )
      .getSingleOrNull();

  final vehicleUnit =
      optionalEnumFromWire(
        DistanceUnit.values,
        (v) => v.wire,
        vehicle?.data['distance_unit'] as String?,
      ) ??
      DistanceUnit.km;
  final purchaseOdometerM = vehicle?.data['purchase_odometer_m'] as int?;

  // Every live reading for the vehicle, including the one this parent already
  // owns — which is then SEPARATED out rather than filtered in SQL, so the
  // proposed reading can inherit its id.
  //
  // That matters more than it looks. `compareReadings` breaks a same-date,
  // same-created-at tie on the id, so a proposed reading carrying an invented
  // id sorts at an arbitrary point among its own neighbours: an edit is then
  // compared against a predecessor or a successor depending on how the
  // invented string happens to collate. Reusing the real id makes the position
  // exact, and reusing the real CREATED-AT keeps the tie-break stable across
  // the edit.
  final all = await db
      .customSelect(
        'SELECT id, source_id, source, occurred_on, created_at_utc_ms, '
        'odometer_m FROM odometer_readings '
        'WHERE vehicle_id = ? AND deleted_at_utc_ms IS NULL;',
        variables: [Variable.withString(vehicleId.toString())],
      )
      .get();

  final mine = all
      .where(
        (row) =>
            row.data['source_id'] == parentId &&
            row.read<String>('source') == source.wire,
      )
      .firstOrNull;

  // EVERY reading this parent owns is excluded, not just the one for this
  // source. A trip owns two, and saving it rewrites BOTH — so checking its new
  // start against its own stale end compares the new value to one that is
  // about to stop existing. The symptom is that correcting a whole trip's
  // odometer UPWARD is refused: the new start (300,000) is measured against the
  // old end (200,000) and reported as going backwards, and the user who
  // mistyped both endpoints cannot fix them.
  //
  // Nothing is lost by excluding the sibling. The two endpoints are checked
  // against each other by the schema — `trips` carries
  // `CHECK (end_odometer_m >= start_odometer_m)` — which is a stronger
  // guarantee than this function could give, because it holds for every writer
  // including an import.
  final existing = all.where((row) => row.data['source_id'] != parentId);

  final corrections = await db
      .customSelect(
        'SELECT from_reading_id, previous_m, new_m '
        'FROM odometer_corrections '
        'WHERE vehicle_id = ? AND deleted_at_utc_ms IS NULL;',
        variables: [Variable.withString(vehicleId.toString())],
      )
      .get();

  final verdict = checkReading(
    proposed: (
      // The id and created-at the row will actually have: the existing one on
      // an edit, a placeholder that sorts last on an insert. An invented id
      // would sort arbitrarily among its own neighbours.
      id: mine?.read<String>('id') ?? '\uffff$parentId',
      occurredOn: occurredOn,
      createdAtUtcMs: mine?.read<int>('created_at_utc_ms') ?? nowUtcMs,
      odometer: Distance(odometerM),
    ),
    existing: [
      for (final row in existing)
        (
          id: row.read<String>('id'),
          occurredOn: row.read<String>('occurred_on'),
          createdAtUtcMs: row.read<int>('created_at_utc_ms'),
          odometer: Distance(row.read<int>('odometer_m')),
        ),
    ],
    corrections: [
      for (final row in corrections)
        (
          fromReadingId: row.read<String>('from_reading_id'),
          previous: Distance(row.read<int>('previous_m')),
          replacement: Distance(row.read<int>('new_m')),
        ),
    ],
    vehicleUnit: vehicleUnit,
    purchaseOdometer: distanceOrNull(purchaseOdometerM),
  );

  final blocked = verdict.blocked;
  if (blocked == null) return null;

  return OdometerWouldGoBackwards(
    previousCumulative: blocked.previousCumulative,
    previousOccurredOn: blocked.previousOccurredOn,
    attemptedCumulative: blocked.attemptedCumulative,
  );
}
