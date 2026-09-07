// SPEC.md §6 §8.1's all-costs CSV.
//
// "One row per cost event across all three sources, sorted by date — the file
// someone opens to build a pivot table."
//
// The union is the whole point and it is also where this can go wrong: a fill
// is a `fuel` row and a service is a `service` row, and NEITHER also appears as
// an expense. A record counted twice makes every total in the user's pivot
// table wrong by exactly the amount they were trying to check.
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/money/money_total.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/backup/domain/csv/csv_writer.dart';
import 'package:odova/features/backup/domain/csv/fillups_csv.dart';

/// §6 §8.1's header, exactly.
const List<String> kCostsCsvHeader = [
  'date',
  'vehicle',
  'type',
  'category',
  'label',
  'vendor',
  'odometer',
  'odometer_unit',
  'amount',
  'currency',
  'notes',
];

/// Which columns of [kCostsCsvHeader] hold numbers this code produced.
///
/// `amount` is the one that matters: §10's refund switch makes an expense the
/// one money field in the app that may be negative, and `-` is a formula
/// leader — so without this every refund row exported as the text `'-25.00`
/// and the column stopped adding up.
const Set<int> kCostsCsvNumericColumns = {6, 8};

/// The three values `type` can take.
///
/// Not the expense CATEGORY enum: a fuel row's type is `fuel` whatever the
/// user calls it, and conflating the two is how a pivot table on `type` ends
/// up with eleven values instead of three.
const List<String> kCostTypes = ['fuel', 'service', 'expense'];

/// One row per cost event, across all three sources, sorted by date.
///
/// `vehiclesById` maps vehicle id to the vehicle. NAMES reach the file and
/// not ids, because §8.1 calls this "the file someone opens to build a pivot
/// table" and nobody pivots on a ULID.
List<List<String>> costCsvRows({
  required Map<String, Vehicle> vehiclesById,
  required List<FillUp> fillUps,
  required List<ServiceRecord> services,
  required List<Expense> expenses,
  required CsvUnits Function(Vehicle) unitsFor,
}) {
  // Resolved once per VEHICLE, not once per row. A 12,000-row export over a
  // two-vehicle household resolved the same units 11,998 times.
  final units = <String, CsvUnits>{
    for (final entry in vehiclesById.entries) entry.key: unitsFor(entry.value),
  };

  final rows = <(String, String, List<String>)>[];

  for (final fill in fillUps) {
    final vehicle = vehiclesById[fill.vehicleId.toString()];
    if (vehicle == null) continue;
    rows.add((
      fill.occurredOn,
      fill.id.toString(),
      _row(
        date: fill.occurredOn,
        vehicle: vehicle,
        type: 'fuel',
        // A fill has no category and no label of its own; the fuel kind is
        // what a pivot table would group by, so it goes in `category` where
        // that grouping lives.
        category: fill.fuelKind.wire,
        label: fill.grade ?? '',
        vendor: fill.station ?? '',
        odometerMetres: fill.odometer?.metres,
        minor: fill.totalCost.amountMinor,
        currency: fill.totalCost.currency.code,
        exponent: fill.totalCost.currency.exponent,
        notes: fill.notes ?? '',
        units: units[vehicle.id.toString()]!,
      ),
    ));
  }

  for (final service in services) {
    final vehicle = vehiclesById[service.vehicleId.toString()];
    if (vehicle == null) continue;
    // The cost is the SUM OF LINES and never a stored total — §6 §7, and the
    // same rule the backup follows. A service with lines in two currencies
    // produces no single amount, because §2 forbids summing across them.
    final total = MoneyTotal([for (final line in service.lines) line.amount]);
    // A service with lines in TWO currencies produces no single amount. §2
    // forbids summing across them, and a cell that picked one would be a
    // number the user's pivot table adds to a different currency's column.
    final single = total.isEmpty || total.isMixed
        ? null
        : total.inCurrency(total.dominantCurrency!);
    rows.add((
      service.occurredOn,
      service.id.toString(),
      _row(
        date: service.occurredOn,
        vehicle: vehicle,
        type: 'service',
        category: '',
        label: service.lines.isEmpty
            ? ''
            : service.lines.map((l) => l.label).join('; '),
        vendor: service.vendor ?? '',
        odometerMetres: service.odometer?.metres,
        minor: single?.amountMinor,
        currency: single?.currency.code ?? '',
        exponent: single?.currency.exponent ?? 2,
        notes: service.notes ?? '',
        units: units[vehicle.id.toString()]!,
      ),
    ));
  }

  for (final expense in expenses) {
    final vehicle = vehiclesById[expense.vehicleId.toString()];
    if (vehicle == null) continue;
    rows.add((
      expense.occurredOn,
      expense.id.toString(),
      _row(
        date: expense.occurredOn,
        vehicle: vehicle,
        type: 'expense',
        category: expense.category.wire,
        label: expense.label ?? '',
        vendor: expense.vendor ?? '',
        odometerMetres: expense.odometer?.metres,
        minor: expense.amount.amountMinor,
        currency: expense.amount.currency.code,
        exponent: expense.amount.currency.exponent,
        notes: expense.notes ?? '',
        units: units[vehicle.id.toString()]!,
      ),
    ));
  }

  // By date, then by id. The id tiebreak is what makes two exports of the same
  // store byte-identical — the same promise §6 §2.6 makes about the backup,
  // and for the same reason: `diff` between two exports is a real answer only
  // if the order is not the query planner's.
  rows.sort((a, b) {
    final byDate = a.$1.compareTo(b.$1);
    return byDate != 0 ? byDate : a.$2.compareTo(b.$2);
  });

  return [for (final row in rows) row.$3];
}

List<String> _row({
  required String date,
  required Vehicle vehicle,
  required String type,
  required String category,
  required String label,
  required String vendor,
  required int? odometerMetres,
  required int? minor,
  required String currency,
  required int exponent,
  required String notes,
  required CsvUnits units,
}) {
  // Locals, then a flat literal — an `if` element would drop a column and
  // shift every cell after it into the wrong header for that one row.
  final odometer = odometerMetres == null
      ? ''
      : csvNumber(
          Distance(odometerMetres).inUnit(units.distance),
          decimals: 1,
        );
  final amount = minor == null
      ? ''
      : csvNumber(minor / _minorPer(exponent), decimals: exponent);

  return [
    date,
    vehicle.name,
    type,
    category,
    label,
    vendor,
    odometer,
    units.distance.wire,
    amount,
    currency,
    notes,
  ];
}

int _minorPer(int exponent) => switch (exponent) {
  0 => 1,
  3 => 1000,
  _ => 100,
};
