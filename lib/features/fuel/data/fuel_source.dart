// The real `FuelRepository`.
//
// Its provider threw `UnimplementedError` until now, so `costs.fuel` was a
// route that crashed on open outside a test. Read-only, like everything on
// §12's two cost screens.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/fuel/fuel_insights.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/data/repositories/log_repositories.dart';
import 'package:odova/data/repositories/odometer_repository.dart';
import 'package:odova/features/fuel/application/fuel_notifier.dart';

/// Everything `costs.fuel` is computed from.
class FuelSource implements FuelRepository {
  /// Creates a source.
  const FuelSource(this._fillUps, this._odometer);

  final FillUpRepository _fillUps;
  final OdometerRepository _odometer;

  @override
  Future<List<InsightFill>> read(String vehicleId) async {
    final id = VehicleId.tryParse(vehicleId);
    if (id == null) return const [];

    final fills = await _fillUps.watchForVehicle(id).first;
    final readings = await _odometer.watchReadings(id).first;
    final corrections = await _odometer.watchCorrections(id).first;

    // CUMULATIVE, not the raw dash number. A cluster swap mid-history makes
    // every consumption figure after it wrong, and this map is where the
    // correction has been folded in.
    final cumulative = cumulativeByReading(
      readings.map(asReadingPoint),
      corrections.map(asCorrectionPoint),
    );
    final byFill = <String, int>{
      for (final reading in readings)
        if (reading.source == OdometerSource.fillUp &&
            reading.sourceId != null &&
            cumulative[reading.id.toString()] != null)
          reading.sourceId!: cumulative[reading.id.toString()]!.metres,
    };

    return [
      // A fill with no QUANTITY is skipped, not zeroed. `InsightFill.quantity`
      // is non-nullable and every figure on `costs.fuel` divides by it; a
      // zero-litre fill would put a segment of infinite consumption into the
      // average, which is worse than a row nobody sees. §10 allows a fill with
      // only a price, so this is reachable.
      for (final fill in fills)
        if (fill.quantity case final quantity?)
          (
            id: fill.id.toString(),
            occurredOn: fill.occurredOn,
            createdAtUtcMs: fill.createdAtUtcMs,
            fuelKind: fill.fuelKind.wire,
            cumulativeM: byFill[fill.id.toString()],
            quantity: quantity,
            isFullTank: fill.isFullTank,
            chainBroken: fill.chainBroken,
            tankCapacityMl: null,
            cost: fill.totalCost,
          ),
    ];
  }
}
