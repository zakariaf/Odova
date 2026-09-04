// The one place `updated_at` is clamped, and the one place it is stamped.
//
// SPEC.md §3 Invariants and validation: `updated_at >= created_at`, repaired on
// READ. Not blocked on write, and the difference matters — blocking would
// refuse a row whose only fault is that the device's clock moved backwards
// between two saves, and refusing to save what somebody just typed, at a pump,
// in the rain, is the worst available answer to a clock problem.

/// A row's two bookkeeping times.
typedef AuditTimes = ({int createdAtUtcMs, int updatedAtUtcMs});

/// Clamps [updatedAtUtcMs] to at least [createdAtUtcMs].
///
/// Called by every mapper on the way OUT of the database, so a row written by
/// an older version, by a clock that jumped, or by an import survives and reads
/// sensibly rather than producing a negative age.
AuditTimes repairAuditTimes({
  required int createdAtUtcMs,
  required int updatedAtUtcMs,
}) => (
  createdAtUtcMs: createdAtUtcMs,
  updatedAtUtcMs: updatedAtUtcMs < createdAtUtcMs
      ? createdAtUtcMs
      : updatedAtUtcMs,
);
