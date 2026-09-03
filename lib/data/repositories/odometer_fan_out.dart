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
import 'package:odova/data/db/app_database.dart';

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
  final existing = await db
      .customSelect(
        'SELECT id FROM odometer_readings WHERE source_id = ? AND source = ?;',
        variables: [
          Variable.withString(parentId),
          Variable.withString(source.wire),
        ],
      )
      .getSingleOrNull();

  if (odometerM == null) {
    if (existing != null) {
      await db.customStatement('DELETE FROM odometer_readings WHERE id = ?;', [
        existing.read<String>('id'),
      ]);
    }
    return;
  }

  if (existing != null) {
    await db.customStatement(
      '''
        UPDATE odometer_readings SET
          occurred_on = ?, odometer_m = ?, odometer_unit = ?,
          updated_at_utc_ms = ?, deleted_at_utc_ms = NULL
        WHERE id = ?;
      ''',
      [
        occurredOn,
        odometerM,
        odometerUnit.wire,
        nowUtcMs,
        existing.read<String>('id'),
      ],
    );
    return;
  }

  await db.customStatement(
    '''
      INSERT INTO odometer_readings (
        id, vehicle_id, occurred_on, odometer_m, odometer_unit, source,
        source_id, created_at_utc_ms, updated_at_utc_ms
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
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

/// Stamps the derived readings of [parentId] with [deletedAtUtcMs].
///
/// The same timestamp as the parent, so the vehicle-level Undo restores the
/// pair together. Matching on `source_id` covers a trip's two readings in one
/// statement.
Future<void> softDeleteDerivedReadings(
  AppDatabase db,
  String parentId,
  int deletedAtUtcMs,
) => db.customStatement(
  'UPDATE odometer_readings SET deleted_at_utc_ms = ? '
  "WHERE source_id = ? AND source <> 'manual' AND deleted_at_utc_ms IS NULL;",
  [deletedAtUtcMs, parentId],
);

/// Clears the delete stamp [softDeleteDerivedReadings] wrote.
Future<void> undoDeleteDerivedReadings(
  AppDatabase db,
  String parentId,
  int deletedAtUtcMs,
) => db.customStatement(
  'UPDATE odometer_readings SET deleted_at_utc_ms = NULL '
  'WHERE source_id = ? AND deleted_at_utc_ms = ?;',
  [parentId, deletedAtUtcMs],
);
