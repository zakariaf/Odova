// How every repository turns a drift query into a stream the UI can trust.
//
// Three behaviours that were a convention at eleven call sites and are now one
// helper, because a convention is something a stream added in a later epic can
// be written without.
//
//   1. Soft-deleted rows are excluded. SPEC.md §3: a deleted row is invisible
//      to every query and every derived value, immediately.
//   2. The result is mapped to domain models before it leaves the data layer.
//   3. Consecutive identical results are dropped.
//
// The third is the one that is easy to leave out and expensive to leave out.
// Drift's stream invalidation is TABLE-level: a write to vehicle A re-runs
// every query over that table, including vehicle B's, whatever the `WHERE`
// says. The models carry value equality, so `distinct` is what turns "the query
// ran again" into "nothing changed, do not rebuild". Seven of the nine watch
// streams had it; the two that did not were `VehicleRepository`'s — and
// `vehiclesProvider` is the one provider that is NOT autoDispose, alive for the
// whole session and feeding the app shell. The single most-subscribed stream in
// the app was the one missing the de-dup.
import 'package:drift/drift.dart';
import 'package:odova/core/value_equality.dart';

/// A stream of [T]s from a query over [rows], de-duplicated.
Stream<List<T>> watchList<R, T>(
  Selectable<R> rows,
  T Function(R row) toModel,
) => rows.watch().map((r) => r.map(toModel).toList()).distinct(valuesEqual);

/// A stream of one [T], or null, de-duplicated.
Stream<T?> watchOne<R, T>(
  SingleOrNullSelectable<R> row,
  T Function(R row) toModel,
) => row
    .watchSingleOrNull()
    .map((r) => r == null ? null : toModel(r))
    .distinct();
