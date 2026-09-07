// What the app BELIEVES the OS is holding, and why.
//
// SPEC.md §6.1: "`scheduled_notifications` persists what the app believes is
// pending, reconciled against the OS's pending list on every rebuild. **The OS
// is the truth for 'is it pending'; the table is the truth for 'why'.** Without
// it there is no telling a notification the user dismissed from one the OS
// dropped for cap."
//
// That sentence is the whole reason this table exists, and it is easy to read
// as redundancy. It is not: iOS keeps the 64 soonest pending notifications and
// silently discards the rest — no error, no callback, no trace anywhere except
// here. A row that says `pending` while `getPending()` does not list its id is
// the only evidence such a discard ever leaves.
//
// **Deliberately not an entity.** No `AuditColumns`, no ULID `id`, no soft
// delete. It is device bookkeeping, not history: it does not go in the backup
// (§6 §7), it does not survive an import, and a user who restores onto a new
// phone gets a full rebuild rather than a queue of ids belonging to an app
// install that no longer exists. Giving it the entity shape would invite it
// into the export projection, which is exactly the mistake worth designing out.
import 'package:drift/drift.dart';

/// One notification the app has handed to the OS.
class ScheduledNotifications extends Table {
  /// `<vehicle_id>:<reminder_id>:<stage>` — SPEC.md §4.2.2 rule 1.
  ///
  /// THE identity, and the primary key. Rescheduling is cancel-then-add on the
  /// same key, which is what stops the OS accumulating duplicates: without a
  /// stable key, every reprojection adds a notification and cancels nothing,
  /// and a user who logs fuel weekly ends the month with thirty copies of the
  /// same reminder.
  ///
  /// `reminder_id` is absent from the key for a nudge, giving `veh_…::nudge`.
  /// That is correct rather than sloppy — a vehicle has one nudge.
  TextColumn get key => text()();

  /// The 31-bit int the OS actually knows it by.
  ///
  /// Not the key: Android's API takes an int. The mapping is persisted here
  /// because `deterministicId` linear-probes on collision, so the id for a key
  /// is not always a pure function of it — and cancelling requires the id we
  /// really used, not the one we would compute today.
  IntColumn get osId => integer().named('os_id')();

  /// The vehicle, for cancelling a car's keys on archive or delete.
  ///
  /// No foreign key. The row is a record of what the OS was told, and it has to
  /// outlive the vehicle by exactly long enough to cancel it — a cascade would
  /// delete the row that says which id still needs cancelling, leaving a
  /// notification about a car the user deleted, with no way to find it.
  TextColumn get vehicleId => text().named('vehicle_id')();

  /// The item, or null for a nudge, a keeper or a backup nudge.
  TextColumn get reminderId => text().nullable().named('reminder_id')();

  /// `early | due | overdue1 | overdue2 | nudge` — SPEC.md §4.4.1.
  TextColumn get stage => text()();

  /// `YYYY-MM-DDTHH:MM`, WALL CLOCK.
  ///
  /// Never a UTC instant, and the CHECK enforces the shape. SPEC.md §4.5: a
  /// notification is stored as `(local_date, delivery_time)` and resolved in
  /// the current zone at schedule time, so a user who flies Berlin → Tehran
  /// still gets 09:00 in Tehran. An instant here would be an hour wrong after
  /// every DST transition and four and a half hours wrong after that flight —
  /// both invisible until somebody's phone buzzes at 04:30.
  TextColumn get fireAtLocal => text().named('fire_at_local')();

  /// A hash of the body that was baked into the OS.
  ///
  /// The body itself is not stored. §4.2.2 rule 6 re-bakes it on reschedule, so
  /// what is needed is "did it change", not "what did it say" — and keeping the
  /// sentence would put six languages of user-visible text in a table that
  /// never leaves the device and can never be re-rendered.
  TextColumn get bodyHash => text().named('body_hash')();

  /// `pending | fired | dropped | cancelled`.
  ///
  /// `dropped` is not `cancelled` and that distinction is §6.1's point: we
  /// cancelled the second one and something else lost the first.
  TextColumn get state => text()();

  /// When this row was last written. UTC epoch milliseconds.
  IntColumn get updatedAtUtcMs => integer().named('updated_at_utc_ms')();

  @override
  Set<Column> get primaryKey => {key};

  @override
  List<String> get customConstraints => [
    "CHECK (state IN ('pending', 'fired', 'dropped', 'cancelled'))",
    "CHECK (stage IN ('early', 'due', 'overdue1', 'overdue2', 'nudge'))",
    // The wall-clock shape, enforced in the database rather than only in Dart.
    // A row that reaches here as an ISO instant is a bug that would otherwise
    // surface as a notification at the wrong hour on one user's device, months
    // later, with nothing to point at.
    // INLINE, and it must stay inline. This was a named constant interpolated
    // into the string — introduced so the GLOB's quoting could not get
    // "tidied" — and that is exactly what broke it: drift_dev reads
    // `customConstraints` off the SYNTAX TREE and cannot constant-fold an
    // interpolation, so it silently dropped this one element from the
    // versioned schema while keeping the four plain literals.
    //
    // The consequence was invisible and one-sided. A FRESH install resolves
    // constraints through this Dart getter and got the check; an UPGRADE
    // resolves them through the generated `VersionedTable` and did not — so
    // every user with history worth protecting had no wall-clock check at all,
    // leaving only `length = 16`, which a UTC instant and any 16-character
    // garbage both satisfy.
    // A CHECK too long for one line. It cannot be a named constant: drift_dev
    // reads this list off the syntax tree and silently drops anything it
    // cannot fold, which is how these two vanished from the schema snapshots.
    // ignore: no_adjacent_strings_in_list, missing_whitespace_between_adjacent_strings
    "CHECK (fire_at_local GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]"
        "T[0-9][0-9]:[0-9][0-9]')",
    'CHECK (os_id >= 0 AND os_id < 2147483648)',
    // Length as SQL, not as `withLength`. `withLength` is a Dart-side
    // validator that emits nothing, so a row written by a raw statement — which
    // the fan-out and the migration both use — passes it without being
    // checked. `schema_reality_test` refuses it for exactly that reason.
    'CHECK (length(fire_at_local) = 16)',
  ];

  @override
  bool get isStrict => true;
}
