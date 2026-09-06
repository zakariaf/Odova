// One page of the timeline, in §11's order, resuming without a gap.
//
// SPEC.md §11 *Pagination*: "Keyset, never offset … Offset pagination would
// renumber the list the moment a backdated 2019 entry is saved." Every
// assertion here is either about that order or about a row that must not be in
// the page at all — and both are the QUERY's job, because a row filtered out
// in Dart has still cost a page slot.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/history/history_cursor.dart';
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

  Future<HistoryPage> page({
    HistoryFilter filter = HistoryFilter.all,
    int limit = 60,
  }) async {
    final result = await history.page(
      vehicleId: historyVehicleId,
      filter: filter,
      limit: limit,
    );
    return (result as Ok<HistoryPage, PersistFailure>).value;
  }

  test('orders by occurred_on, then created_at, then id — all descending', () {
    // The ULID tiebreak, asserted across two calls: two fills on the same day
    // at the same station keep the same order on every rebuild, which is what
    // stops the list flickering between two orderings.
    return expectLater(
      Future(() async {
        await seedSameDayFills(harness.db);
        final first = await page();
        final second = await page();
        return [
          first.entries.map((e) => e.id).toList(),
          second.entries.map((e) => e.id).toList(),
        ];
      }),
      completion(
        predicate<List<List<String>>>(
          (both) =>
              both[0].isNotEmpty && both[0].toString() == both[1].toString(),
          'is stable across two identical calls',
        ),
      ),
    );
  });

  test('the order is descending on the sort key', () async {
    await seedSameDayFills(harness.db);
    final rows = (await page()).entries;

    for (var i = 1; i < rows.length; i++) {
      expect(
        rows[i].cursor.sortsBelow(rows[i - 1].cursor),
        isTrue,
        reason: '${rows[i]} should sort below ${rows[i - 1]}',
      );
    }
  });

  test(
    '60-row pages yield every id once, in order, over three calls',
    () async {
      // The test that fails if anyone reaches for LIMIT/OFFSET. 130 rows, three
      // pages, no duplicate and no gap.
      await seedManyEntries(harness.db, count: 130);

      final seen = <String>[];
      var calls = 0;
      HistoryCursor? cursor;

      // Bounded, so a cursor that fails to advance fails the test rather than
      // hanging the suite — which is what a `<=` in the tuple comparison does.
      while (calls < 5) {
        final result = await history.page(
          vehicleId: historyVehicleId,
          filter: HistoryFilter.all,
          after: cursor,
        );
        final current = (result as Ok<HistoryPage, PersistFailure>).value;
        seen.addAll(current.entries.map((e) => e.id));
        calls++;
        cursor = current.nextCursor;
        if (cursor == null) break;
      }

      expect(seen.length, 130);
      expect(seen.toSet().length, 130, reason: 'no id appears twice');
      expect(calls, 3, reason: '130 rows is three pages of 60');
    },
  );

  test('a derived odometer reading gets no row', () async {
    // §3: every record carrying an odometer emits one. A fill-up would appear
    // twice — once as itself, once as the reading it implied.
    await seedFillUpWithOdometer(harness.db);
    final kinds = (await page()).entries.map((e) => e.kind).toList();

    expect(kinds, contains(HistoryEntryKind.fillUp));
    expect(kinds, isNot(contains(HistoryEntryKind.odometer)));
  });

  test('a manual odometer reading DOES get a row', () async {
    await seedManualReading(harness.db);
    final kinds = (await page()).entries.map((e) => e.kind).toList();

    expect(kinds, contains(HistoryEntryKind.odometer));
  });

  test('deleted rows are absent from every page', () async {
    await seedDeletedFillUp(harness.db);
    expect((await page()).entries, isEmpty);
  });

  test(
    'a correction appears at the position of the reading it corrects',
    () async {
      // Not at the date the swap was recorded. §11 draws it as a divider "at
      // their from_reading position", because it is not something that happened
      // to the car — it changes how the numbers either side of it are read.
      await seedCorrectionOverReading(harness.db);
      final rows = (await page()).entries;
      final divider = rows.firstWhere(
        (e) => e.kind == HistoryEntryKind.correction,
      );

      expect(divider.occurredOn, '2026-03-12');
    },
  );

  test('a page is scoped to one vehicle', () async {
    await seedSecondVehicleEntries(harness.db);
    final rows = (await page()).entries;

    expect(rows, isNotEmpty);
    expect(
      rows.every((e) => !e.id.contains('OTHER')),
      isTrue,
      reason: "a second vehicle's rows never leak in",
    );
  });

  test('pageAnchoredAt returns that month down and nothing newer', () async {
    await seedAcrossMonths(harness.db);
    final result = await history.pageAnchoredAt(
      vehicleId: historyVehicleId,
      filter: HistoryFilter.all,
      month: const MonthKey(
        calendar: CalmCalendar.gregorian,
        year: 2026,
        month: 3,
      ),
    );
    final rows = (result as Ok<HistoryPage, PersistFailure>).value.entries;

    expect(rows, isNotEmpty);
    expect(
      rows.every((e) => e.occurredOn.compareTo('2026-04-01') < 0),
      isTrue,
      reason: 'nothing newer than the anchored month',
    );
  });

  test('a fill-up row carries the facts its line is built from', () async {
    // The union widened to §11's type table, and a UNION matches by POSITION
    // rather than by name — six arms drifting by one column is a silent type
    // error that reads back as a station in the currency slot. This asserts
    // the fill-up arm lands in the right slots.
    await seedFillUpWithOdometer(harness.db);
    final row = (await page()).entries.single;

    expect(row.kind, HistoryEntryKind.fillUp);
    expect(row.minorUnits, 7845);
    expect(row.currency, 'EUR');
    expect(row.odometerM, 186512000);
    expect(row.quantity, 45200);
    expect(row.quantityForm, 'ml');
    expect(row.isFullTank, isTrue);
  });

  test('an expense row falls back from label to category', () async {
    // §11: "category name, or `label` for `other`". The COALESCE is what makes
    // a row with no custom name still say what it was for.
    await insertExpense(
      harness.db,
      id: 'exp_01K1C4V2H9B8N3Q7ZE5RY6TMZ1',
      category: 'parking',
    );
    final row = (await page()).entries.single;

    expect(row.label, 'parking');
    expect(row.minorUnits, isNotNull);
  });

  test('an odometer row carries no money at all', () async {
    // Not a zero. §11's table prints nothing in the column, and zero is a real
    // price a warranty job can have.
    await seedManualReading(harness.db);
    final row = (await page()).entries.single;

    expect(row.minorUnits, isNull);
    expect(row.currency, isNull);
    expect(row.odometerM, isNotNull);
  });

  test('a kind filter is applied by the query, not by the caller', () async {
    await seedMixedKinds(harness.db);
    final rows = (await page(
      filter: const HistoryFilter(kinds: {HistoryEntryKind.expense}),
    )).entries;

    expect(rows, isNotEmpty);
    expect(rows.every((e) => e.kind == HistoryEntryKind.expense), isTrue);
  });

  test('a Jalali anchor is converted before it reaches the query', () async {
    // `MonthKey.year`/`.month` are numbered in the USER's calendar.
    // `pageAnchoredAt` used to take two bare ints and format them as a
    // Gregorian ISO string, so releasing the scrubber on Mehr 1403 produced
    // the anchor '1403-07-31' — which sorts below every real '2024-…' row.
    // Zero rows back, `hasMore: false`, and the notifier discards the loaded
    // window: the user's entire history vanished with no gesture to recover
    // it. Three of the six shipped locales read a Jalali calendar.
    await seedAcrossMonths(harness.db);

    // Mehr 1405 begins 23 September 2026 — inside the seeded range.
    final result = await history.pageAnchoredAt(
      vehicleId: historyVehicleId,
      filter: HistoryFilter.all,
      month: const MonthKey(
        calendar: CalmCalendar.persian,
        year: 1405,
        month: 7,
      ),
    );

    expect(
      (result as Ok<HistoryPage, PersistFailure>).value.entries,
      isNotEmpty,
      reason: 'the anchor landed in 2026, not in the year 1405',
    );
  });
}
