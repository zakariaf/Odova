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
import 'package:odova/core/result.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/history_repository.dart';

import '../support/history_fixture.dart';
import '../support/provider_harness.dart';

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
      year: 2026,
      month: 3,
    );
    final rows = (result as Ok<HistoryPage, PersistFailure>).value.entries;

    expect(rows, isNotEmpty);
    expect(
      rows.every((e) => e.occurredOn.compareTo('2026-04-01') < 0),
      isTrue,
      reason: 'nothing newer than the anchored month',
    );
  });

  test('a kind filter is applied by the query, not by the caller', () async {
    await seedMixedKinds(harness.db);
    final rows = (await page(
      filter: const HistoryFilter(kinds: {HistoryEntryKind.expense}),
    )).entries;

    expect(rows, isNotEmpty);
    expect(rows.every((e) => e.kind == HistoryEntryKind.expense), isTrue);
  });
}
