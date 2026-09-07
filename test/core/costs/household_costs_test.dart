// SPEC.md §12's all-vehicles comparison: the household view for someone with
// a second car.
//
// The rule that shapes it is the same one that shapes every total on these
// screens — "Money never mixes." A household with a euro car and a pound car
// has two subtotals, not one sum, because there is no rate and no network to
// fetch one.
@TestOn('vm')
library;

import 'package:odova/core/costs/household_costs.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:test/test.dart';

final Currency eur = Currency.tryParse('EUR')!;
final Currency gbp = Currency.tryParse('GBP')!;

HouseholdVehicle vehicle(
  String id,
  int perMonthMinor, {
  Currency? currency,
  bool isArchived = false,
  bool isSold = false,
}) => HouseholdVehicle(
  vehicleId: id,
  name: 'Car $id',
  perMonth: Money(perMonthMinor, currency ?? eur),
  isArchived: isArchived,
  isSold: isSold,
);

void main() {
  group('the rows', () {
    test('sort by cost per month, descending', () {
      final household = buildHousehold(
        vehicles: [
          vehicle('a', 12000),
          vehicle('b', 30000),
          vehicle('c', 20000),
        ],
        includeInactive: false,
      );

      expect(
        household.rows.map((r) => r.vehicleId).toList(),
        ['b', 'c', 'a'],
      );
    });

    test('a tie breaks by name, so the order does not flicker', () {
      final household = buildHousehold(
        vehicles: [vehicle('z', 10000), vehicle('a', 10000)],
        includeInactive: false,
      );

      expect(household.rows.first.vehicleId, 'a');
    });

    test('vehicles in another currency sort within their own subtotal', () {
      // Comparing 30,000 minor EUR against 30,000 minor GBP as though they
      // were the same quantity is the sum this spec forbids, wearing a sort
      // instead of an addition.
      final household = buildHousehold(
        vehicles: [
          vehicle('eur-small', 10000),
          vehicle('gbp-big', 90000, currency: gbp),
        ],
        includeInactive: false,
      );

      expect(household.totals.byCurrency.keys.length, 2);
      expect(
        household.rows.map((r) => r.perMonth.currency).toSet(),
        {eur, gbp},
      );
    });
  });

  group('sold and archived', () {
    test('are excluded by default, and counted in the trailing line', () {
      final household = buildHousehold(
        vehicles: [
          vehicle('live', 20000),
          vehicle('sold', 15000, isSold: true),
          vehicle('archived', 10000, isArchived: true),
        ],
        includeInactive: false,
      );

      expect(household.rows.map((r) => r.vehicleId), ['live']);
      expect(household.hiddenCount, 2);
    });

    test('join the list and the totals when included', () {
      final household = buildHousehold(
        vehicles: [
          vehicle('live', 20000),
          vehicle('sold', 15000, isSold: true),
        ],
        includeInactive: true,
      );

      expect(household.rows, hasLength(2));
      expect(household.hiddenCount, 0);
      expect(household.totals.byCurrency[eur], 35000);
    });

    test('and carry their status, so a row is never mistaken for live', () {
      final household = buildHousehold(
        vehicles: [vehicle('sold', 15000, isSold: true)],
        includeInactive: true,
      );

      expect(household.rows.single.isSold, isTrue);
    });
  });

  test('the household total groups per currency and never sums across', () {
    final household = buildHousehold(
      vehicles: [
        vehicle('a', 20000),
        vehicle('b', 30000),
        vehicle('c', 8000, currency: gbp),
      ],
      includeInactive: false,
    );

    expect(household.totals.byCurrency[eur], 50000);
    expect(household.totals.byCurrency[gbp], 8000);
  });

  test('an empty household is empty rather than a zero row', () {
    final household = buildHousehold(vehicles: const [], includeInactive: true);

    expect(household.rows, isEmpty);
    expect(household.totals.byCurrency, isEmpty);
  });
}
