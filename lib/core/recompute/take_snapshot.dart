// Reducing a vehicle to the two things §11's snackbar is allowed to talk about.
//
// The epic's task 12.8 describes `recomputeVehicle` as though it had to be
// written here. It does not: EPIC-07 built it, in
// `core/due/vehicle_due_snapshot`, and it already runs the dependency order
// §11 lists — rate → estimate →
// anchor → due state → projection — once per vehicle rather than once per item.
// EPIC-06 built `buildFuelSegmentsByKind` for the fuel half, one chain per
// fuel kind: merging an LPG fill into a petrol series reads as a chain break.
//
// So this file composes those two rather than growing a third copy of either.
// A second pipeline would have to be kept in step with the first for the life
// of the app, and the day it drifted the snackbar would describe a recompute
// that never happened.
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/due/vehicle_due_snapshot.dart';
import 'package:odova/core/fuel/build_fuel_segments.dart';
import 'package:odova/core/recompute/vehicle_recompute.dart';
import 'package:odova/core/time/civil_date.dart';

/// Every derived figure §11 watches, for one vehicle, at one instant.
///
/// [fills] are the same `FillUpPoint`s the fuel engine takes: cumulative and
/// correction-aware, because a raw dash reading is not comparable across a
/// cluster swap and the whole point of this snapshot is comparing two of them.
RecomputeSnapshot takeRecomputeSnapshot({
  required Vehicle vehicle,
  required List<ServiceItem> items,
  required List<ServiceRecord> records,
  required ReadingSeries series,
  required AppSettings settings,
  required Iterable<FillUpPoint> fills,
  required CivilDate today,
  required CivilDate buildDate,
}) {
  // The fuel half. Keyed by the fill that CLOSES each segment, because that is
  // the fill whose row shows the figure — a segment's number is reported
  // against the tank it measured, not the one that opened it.
  //
  // Every fill is seeded to null first and only then overwritten. A fill whose
  // segment was discarded has to appear in the map holding null, or the diff
  // cannot tell "this figure disappeared" from "this fill was never here", and
  // §11's whole promise is that a correction which BREAKS a chain is reported
  // as loudly as one that fixes it.
  final consumption = <String, double?>{for (final f in fills) f.id: null};
  for (final set in buildFuelSegmentsByKind(fills).values) {
    for (final segment in set.segments) {
      final millilitres = segment.quantity.amount;
      consumption[segment.toFillUpId] = millilitres == 0
          ? null
          : segment.distance.metres / millilitres;
    }
  }

  // The due half, straight from EPIC-07's engine.
  final due = recomputeVehicle(
    vehicle,
    items,
    records,
    series,
    settings,
    today: today,
    buildDate: buildDate,
  );

  return RecomputeSnapshot(
    consumptionByFillUp: consumption,
    dueByItem: {
      for (final (item, assessment) in due.assessments)
        item.id.body: _factsOf(assessment),
    },
  );
}

DueFacts _factsOf(DueAssessment a) => DueFacts(
  state: a.state,
  // `dueOn`, never `projectedDueDate`. §11 rebuilds the OS schedule from this
  // diff, and a projection is the app's guess about when a distance-driven item
  // will come round — it moves every time the daily rate wobbles. Re-anchoring
  // sixteen notifications because the user drove to the coast at the weekend is
  // how a maintenance app teaches someone to turn its notifications off.
  dueOn: a.dueOn?.toString(),
  dueAtOdometerM: a.dueAtOdometerMetres,
);
