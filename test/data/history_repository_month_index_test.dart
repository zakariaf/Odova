// The month index, over the store.
//
// SPEC.md §11: the index "drives the header subtotal, the year scrubber and
// the 'no entries in 2021' empty state without loading an entry row." Every
// assertion here is about a total that must not move, or a row that must not
// contribute to one.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/history/history_entry.dart';
import 'package:odova/core/history/history_filter.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/history_repository.dart';

import '../support/history_fixture.dart';
import '../support/provider_harness.dart';
import 'support/rows.dart';

void main() {
  late DatabaseHarness harness;
  late HistoryRepository history;

  setUp(() async {
    harness = containerWithDatabase();
    history = HistoryRepository(harness.db);
    await seedHistoryVehicle(harness.db);
  });

  Future<List<MonthIndexEntry>> index({
    CalmCalendar calendar = CalmCalendar.gregorian,
    HistoryFilter filter = HistoryFilter.all,
  }) async {
    final result = await history.monthIndex(
      vehicleId: historyVehicleId,
      filter: filter,
      calendar: calendar,
    );
    return (result as Ok<List<MonthIndexEntry>, PersistFailure>).value;
  }

  test('totals group per currency and are never summed across them', () async {
    // A month holding €412.80 and £30.00 has two subtotals. 442.80 is not a
    // number about anything.
    await insertExpense(
      harness.db,
      id: 'exp_01K1C4V2H9B8N3Q7ZE5RY6TMA1',
      occurredOn: '2026-08-04',
      amountMinor: 41280,
    );
    await insertExpense(
      harness.db,
      id: 'exp_01K1C4V2H9B8N3Q7ZE5RY6TMA2',
      occurredOn: '2026-08-09',
      amountMinor: 3000,
      currency: 'GBP',
    );

    final august = (await index()).single;

    expect(august.count, 2);
    expect(august.totals, {'EUR': 41280, 'GBP': 3000});
  });

  test('a trip contributes no money to a month total', () async {
    // §11: a trip's costs are the fills and expenses already counted under it.
    // Adding them again would double every business month.
    await insertTrip(
      harness.db,
      id: 'trp_01K1C4V2H9B8N3Q7ZE5RY6TMB1',
      startedOn: '2026-08-02',
    );
    await insertExpense(
      harness.db,
      id: 'exp_01K1C4V2H9B8N3Q7ZE5RY6TMB2',
      occurredOn: '2026-08-04',
      amountMinor: 5000,
    );

    final august = (await index()).single;

    expect(august.count, 2, reason: 'the trip is still an entry');
    expect(august.totals, {'EUR': 5000}, reason: 'and contributes no money');
  });

  test('an expense counts in the month it was PAID', () async {
    // History is cash, not accrual. The coverage window spreads a policy over
    // months on the cost dashboard; letting that leak here would make a
    // September total disagree with the September rows under it.
    await insertExpense(
      harness.db,
      id: 'exp_01K1C4V2H9B8N3Q7ZE5RY6TMC1',
      occurredOn: '2026-09-02',
      amountMinor: 64000,
      coversFrom: '2026-09-02',
      coversTo: '2027-09-01',
    );

    final months = await index();

    expect(months, hasLength(1));
    expect(months.single.monthKey.month, 9);
    expect(months.single.totals, {'EUR': 64000});
  });

  test('months with no entries are absent from the index', () async {
    await insertExpense(
      harness.db,
      id: 'exp_01K1C4V2H9B8N3Q7ZE5RY6TMD1',
      occurredOn: '2026-01-10',
    );
    await insertExpense(
      harness.db,
      id: 'exp_01K1C4V2H9B8N3Q7ZE5RY6TMD2',
      occurredOn: '2026-06-10',
    );

    final months = await index();

    expect(months, hasLength(2), reason: 'January and June, not six months');
    expect(months.map((m) => m.monthKey.month).toList(), [6, 1]);
  });

  test('the index groups by the display calendar', () async {
    // 22 and 24 September 2026 are Shahrivar and Mehr. Under Gregorian they
    // are one month; under Persian they are two.
    await insertExpense(
      harness.db,
      id: 'exp_01K1C4V2H9B8N3Q7ZE5RY6TME1',
      occurredOn: '2026-09-22',
    );
    await insertExpense(
      harness.db,
      id: 'exp_01K1C4V2H9B8N3Q7ZE5RY6TME2',
      occurredOn: '2026-09-24',
    );

    expect(await index(), hasLength(1));
    expect(await index(calendar: CalmCalendar.persian), hasLength(2));
  });

  test('the subtotal is the same at 60 rows loaded and at 400', () async {
    // The regression guard §11 names: the index is an aggregate, so it cannot
    // move as more of the list is paged in. Asserted by reading it before and
    // after walking every page.
    await seedManyEntries(harness.db, count: 130);

    final before = await index();
    var cursor =
        (await history.page(
                  vehicleId: historyVehicleId,
                  filter: HistoryFilter.all,
                )
                as Ok<HistoryPage, PersistFailure>)
            .value
            .nextCursor;
    while (cursor != null) {
      final next = await history.page(
        vehicleId: historyVehicleId,
        filter: HistoryFilter.all,
        after: cursor,
      );
      cursor = (next as Ok<HistoryPage, PersistFailure>).value.nextCursor;
    }
    final after = await index();

    expect(before.length, after.length);
    expect(
      before.map((m) => m.totals).toList(),
      after.map((m) => m.totals).toList(),
    );
  });

  test('a filter narrows the index the same way it narrows the page', () async {
    await seedMixedKinds(harness.db);

    final all = await index();
    final expensesOnly = await index(
      filter: const HistoryFilter(kinds: {HistoryEntryKind.expense}),
    );

    expect(all.single.count, 3);
    expect(expensesOnly.single.count, 1);
  });
}
