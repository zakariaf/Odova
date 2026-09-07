// SPEC.md §6 §8.1's fill-ups CSV.
//
// Unlike the backup, this writes numbers in the USER'S OWN UNITS and prints
// the derived columns: `price_per_unit`, `distance_since_last` and
// `consumption`. "The point of a CSV is having the numbers without rewriting
// the formula."
//
// That is the one place in this app where a derived value is written down on
// purpose, and it is safe for the same reason the backup's `derived_fields`
// are: nothing reads a CSV back. §8.1 says so in a sentence — "CSV is
// export-only, there is no CSV import in v1" — and `backup_reader_test`
// asserts a CSV is refused as a restore source.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/fuel/build_fuel_segments.dart';
import 'package:odova/core/fuel/fuel_segment.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/features/backup/domain/csv/csv_writer.dart';

/// §6 §8.1's header, exactly.
const List<String> kFillUpsCsvHeader = [
  'date',
  'vehicle',
  'odometer',
  'odometer_unit',
  'quantity',
  'quantity_unit',
  'price_per_unit',
  'total_cost',
  'currency',
  'is_full_tank',
  'chain_broken',
  'grade',
  'distance_since_last',
  'consumption',
  'consumption_unit',
  'station',
  'notes',
];

/// The units a row is written in.
///
/// The USER's, resolved per vehicle before this is called — a household that
/// runs a van in miles and a bike in km gets each in its own units, because
/// converting on write is what §1 forbids and this is a read.
typedef CsvUnits = ({
  DistanceUnit distance,
  VolumeUnit volume,
  ConsumptionUnit consumption,
});

/// Every fill-up as a CSV row, newest last.
///
/// `consumption` comes from the fuel engine, per SEGMENT, attributed to the
/// fill that
/// CLOSED it. A per-fill consumption computed any other way would be an
/// estimate dressed as a measurement — §3 measures only full-to-full, and a
/// row whose tank was not full at both ends leaves the column empty rather
/// than guessing.
List<List<String>> fillUpCsvRows({
  required Vehicle vehicle,
  required List<FillUp> fillUps,
  required Map<String, int> cumulativeMetres,
  required CsvUnits units,
}) {
  final ordered = [...fillUps]
    ..sort((a, b) {
      final byDate = a.occurredOn.compareTo(b.occurredOn);
      return byDate != 0 ? byDate : a.id.toString().compareTo(b.id.toString());
    });

  final segments = buildFuelSegments([
    for (final fill in ordered)
      (
        id: fill.id.toString(),
        occurredOn: fill.occurredOn,
        createdAtUtcMs: fill.createdAtUtcMs,
        fuelKind: fill.fuelKind.wire,
        cumulativeM: cumulativeMetres[fill.id.toString()],
        quantity: fill.quantity ?? const LiquidVolume(Volume.zero),
        isFullTank: fill.isFullTank,
        chainBroken: fill.chainBroken,
        tankCapacityMl: vehicle.tankCapacityMl,
      ),
  ]);

  final byClosingFill = <String, FuelSegment>{
    for (final segment in segments.segments) segment.toFillUpId: segment,
  };

  return [
    for (var i = 0; i < ordered.length; i++)
      _row(
        vehicle: vehicle,
        fill: ordered[i],
        previous: i == 0 ? null : ordered[i - 1],
        cumulativeMetres: cumulativeMetres,
        segment: byClosingFill[ordered[i].id.toString()],
        units: units,
      ),
  ];
}

List<String> _row({
  required Vehicle vehicle,
  required FillUp fill,
  required FillUp? previous,
  required Map<String, int> cumulativeMetres,
  required FuelSegment? segment,
  required CsvUnits units,
}) {
  // Every cell is a LOCAL, and the row literal is flat. Not style: a column
  // built with an `if` element disappears when its condition is false, and a
  // disappearing column shifts every cell after it into the wrong header for
  // that one row. A CSV has no way to notice.
  final quantity = fill.quantity;
  final currency = fill.totalCost.currency;
  final major = fill.totalCost.amountMinor / currency.minorPerMajor;

  final amount = quantity == null ? null : _volume(quantity, units.volume);
  final quantityCell = amount == null ? '' : csvNumber(amount, decimals: 2);
  // Empty rather than zero when there is nothing to divide: a price per litre
  // of 0.00 is a number somebody will average.
  final priceCell = amount == null || amount == 0
      ? ''
      : csvNumber(major / amount, decimals: 3);

  // §3 measures consumption only full-to-full. A row whose tank was not full
  // at both ends leaves this empty rather than printing an estimate dressed
  // as a measurement.
  final figure = segment?.consumption.asUnit(units.consumption);
  final consumptionCell = figure == null ? '' : csvNumber(figure, decimals: 2);
  final consumptionUnitCell = figure == null ? '' : units.consumption.wire;

  return [
    // ISO, always. §8.1: the one date format every spreadsheet on earth parses
    // the same way.
    fill.occurredOn,
    vehicle.name,
    _distance(fill.odometer, units.distance),
    units.distance.wire,
    quantityCell,
    units.volume.wire,
    priceCell,
    csvNumber(major, decimals: currency.exponent),
    currency.code,
    csvBool(value: fill.isFullTank),
    csvBool(value: fill.chainBroken),
    fill.grade ?? '',
    _distanceSinceLast(fill, previous, cumulativeMetres, units.distance),
    consumptionCell,
    consumptionUnitCell,
    fill.station ?? '',
    fill.notes ?? '',
  ];
}

String _distance(Distance? distance, DistanceUnit unit) =>
    distance == null ? '' : csvNumber(distance.inUnit(unit), decimals: 1);

double _volume(FuelQuantity quantity, VolumeUnit unit) => switch (quantity) {
  LiquidVolume(:final volume) => volume.inUnit(unit),
  // Grams and watt-hours have no volume unit. The canonical integer is
  // written as it stands, and `quantity_unit` beside it says which it is —
  // converting kWh into gallons would be arithmetic on two different things.
  _ => quantity.amount.toDouble(),
};

String _distanceSinceLast(
  FillUp fill,
  FillUp? previous,
  Map<String, int> cumulative,
  DistanceUnit unit,
) {
  if (previous == null) return '';
  final here = cumulative[fill.id.toString()];
  final there = cumulative[previous.id.toString()];
  // Either end missing means the answer is unknown, and §1 forbids guessing
  // in a way that looks like fact. An empty cell is a fact; a zero is a claim.
  if (here == null || there == null || here <= there) return '';
  return csvNumber(Distance(here - there).inUnit(unit), decimals: 1);
}
