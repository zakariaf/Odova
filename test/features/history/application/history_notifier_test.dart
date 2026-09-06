// The timeline's state: filters, the window, and the jump that discards it.
//
// SPEC.md §11 *Filters*, *Pagination*, *Interactions*. Two assertions here are
// really about memory rather than behaviour — §11 fixes the window at 400 rows
// "so memory stays flat at 40 records or 4,000", and a list that grows without
// bound is the failure this screen is most likely to have on an eight-year
// history.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/history/history_entry.dart';
import 'package:odova/core/history/history_filter.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/features/history/application/history_notifier.dart';

import '../../../support/history_fake_repository.dart';
import '../../../support/provider_harness.dart';

void main() {
  group('the filter composes', () {
    test('kinds are OR within the chip and AND across chips', () {
      // Fuel + 2024 means fills in 2024 — not fills OR 2024.
      const filter = HistoryFilter(
        kinds: {HistoryEntryKind.fillUp, HistoryEntryKind.service},
        year: 2024,
      );

      expect(filter.allows(HistoryEntryKind.fillUp), isTrue);
      expect(filter.allows(HistoryEntryKind.service), isTrue);
      expect(filter.allows(HistoryEntryKind.expense), isFalse);
      expect(filter.year, 2024);
    });

    test('leaving Expense clears the category selection', () {
      // §11 shows the category chip only while the type is Expense. A category
      // still applied behind a Fuel chip narrows a list the user cannot
      // explain.
      const expenses = HistoryFilter(
        kinds: {HistoryEntryKind.expense},
        categories: {ExpenseCategory.parking},
      );

      final fuel = expenses.withKinds({HistoryEntryKind.fillUp});

      expect(fuel.categories, isEmpty);
    });

    test('and staying on Expense keeps it', () {
      const expenses = HistoryFilter(
        kinds: {HistoryEntryKind.expense},
        categories: {ExpenseCategory.parking},
      );

      final still = expenses.withKinds({
        HistoryEntryKind.expense,
        HistoryEntryKind.service,
      });

      expect(still.categories, {ExpenseCategory.parking});
    });

    test('two filters with the same content are equal', () {
      // Load-bearing: the index is memoised per filter and the notifier
      // reloads when the filter changes. With identity equality every rebuild
      // would look like a new filter and re-run both queries.
      const a = HistoryFilter(
        kinds: {HistoryEntryKind.fillUp},
        categories: {ExpenseCategory.parking},
        year: 2026,
      );
      const b = HistoryFilter(
        kinds: {HistoryEntryKind.fillUp},
        categories: {ExpenseCategory.parking},
        year: 2026,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      // Built rather than written as a literal: the analyzer can see two equal
      // constants in `{a, b}` and warns, which is the very property under
      // test.
      expect(<HistoryFilter>{}..addAll([a, b]), hasLength(1));
    });

    test('inYear(null) clears the year rather than keeping it', () {
      const filter = HistoryFilter(year: 2026);
      expect(filter.inYear(null).year, isNull);
    });

    test('the preset constructor is the contract EPIC-13 calls', () {
      const preset = HistoryFilter.preset(
        kinds: {HistoryEntryKind.expense},
        year: 2026,
        categories: {ExpenseCategory.insurance},
      );

      expect(preset.kinds, {HistoryEntryKind.expense});
      expect(preset.year, 2026);
      expect(preset.categories, {ExpenseCategory.insurance});
    });
  });

  group('the loaded window', () {
    late FakeHistoryRepository fake;
    late DatabaseHarness harness;

    setUp(() {
      fake = FakeHistoryRepository(totalRows: 1000);
      harness = containerWithDatabase(
        overrides: [historyRepositoryProvider.overrideWithValue(fake)],
      );
    });

    HistoryNotifier notifierFor(HistoryScope scope) =>
        harness.container.read(historyProvider(scope).notifier);

    test('caps at 400 rows and drops from the far end', () async {
      // §11: "window cap = 400 rows in memory; loading past it drops from the
      // far end." Nine pages of 60 is 540; the state holds 400.
      final notifier = notifierFor(const HistoryScope(vehicleId: 'veh_A'));
      await notifier.load();
      for (var i = 0; i < 9; i++) {
        await notifier.loadMore();
      }

      expect(notifier.state.entries, hasLength(400));
    });

    test('and the rows it keeps are the ones nearest the tail', () async {
      // Dropping from the far END means the user keeps what they are looking
      // at. Dropping from the near end would scroll the list out from under
      // them.
      final notifier = notifierFor(const HistoryScope(vehicleId: 'veh_B'));
      await notifier.load();
      for (var i = 0; i < 9; i++) {
        await notifier.loadMore();
      }

      // One `load` plus nine `loadMore`s is ten pages of 60 — 600 rows, of
      // which the window keeps the last 400: indices 200 through 599.
      expect(notifier.state.entries.last.id, fake.idAt(599));
      expect(notifier.state.entries.first.id, fake.idAt(200));
    });

    test('a stale page is discarded rather than absorbed', () async {
      // The `isLoading` guard cannot close this: `_absorb` lowers it when
      // WHICHEVER request lands first does, not when the newest one does.
      //
      // Tap Fuel, then Service one frame later. The Fuel page lands first and
      // used to be committed — 60 Fuel rows, `isLoading: false`, a Fuel cursor
      // — under a Service filter. The next prefetch then appended Service rows
      // after a Fuel row's cursor: duplicates, or a silent gap, with
      // `state.cursor` wrong for every page after.
      final notifier = notifierFor(const HistoryScope(vehicleId: 'veh_R'));
      await notifier.load();

      // Both in flight, then released in REVERSE order — a slow first query
      // and a fast second one, which is what a real device produces and what
      // a single latch cannot reproduce.
      fake
        ..holdEachCall = true
        ..pageCalls = 0;
      final first = notifier.applyFilter(
        const HistoryFilter(kinds: {HistoryEntryKind.fillUp}),
      );
      final second = notifier.applyFilter(
        const HistoryFilter(kinds: {HistoryEntryKind.service}),
      );
      await Future<void>.delayed(Duration.zero);

      fake.release(1);
      await Future<void>.delayed(Duration.zero);
      final afterNewest = notifier.state.entries.length;

      fake.release(0);
      await Future.wait([first, second]);

      // The KIND is the assertion that matters. Length and filter are the
      // same whichever response won — the fake returns 60 rows either way and
      // `applyFilter` sets the filter synchronously — so a test asserting only
      // those passes against no guard at all. It did.
      expect(
        notifier.state.entries.map((e) => e.kind).toSet(),
        {HistoryEntryKind.service},
        reason: 'the older FUEL response did not overwrite the newer one',
      );
      expect(notifier.state.entries, hasLength(afterNewest));
      expect(notifier.state.filter.kinds, {HistoryEntryKind.service});
    });

    test('a pending debounce does not outlive the provider', () async {
      // `search()` arms a Timer whose callback reads AND writes `state`. In
      // Riverpod 3 both throw after disposal — an unhandled error inside a
      // timer callback, which reaches the crash sink in production and fails
      // the NEXT test under `testWidgets`.
      final notifier = notifierFor(const HistoryScope(vehicleId: 'veh_D'));
      await notifier.load();

      notifier.search('shell', debounce: const Duration(milliseconds: 5));
      harness.container.dispose();

      // Where the timer would fire into a disposed ref, if it survived.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(true, isTrue, reason: 'no unhandled error escaped disposal');
    });

    test('a jump discards the window and reloads from the anchor', () async {
      // §11: "release runs a fresh keyset query anchored there and DISCARDS
      // the loaded window, so memory stays flat at 40 records or 4,000."
      final notifier = notifierFor(const HistoryScope(vehicleId: 'veh_C'));
      await notifier.load();
      for (var i = 0; i < 5; i++) {
        await notifier.loadMore();
      }
      expect(notifier.state.entries.length, greaterThan(60));

      await notifier.jumpTo(
        const MonthKey(
          calendar: CalmCalendar.gregorian,
          year: 2026,
          month: 3,
        ),
      );

      expect(
        notifier.state.entries,
        hasLength(60),
        reason: 'one page, not the window plus one page',
      );
    });
  });

  group('the notifier', () {
    late FakeHistoryRepository fake;
    late DatabaseHarness harness;

    setUp(() {
      fake = FakeHistoryRepository(totalRows: 200);
      harness = containerWithDatabase(
        overrides: [historyRepositoryProvider.overrideWithValue(fake)],
      );
    });

    test(
      'filter state is per scope, which is what lets EPIC-13 push one',
      () async {
        final tab = harness.container.read(
          historyProvider(const HistoryScope(vehicleId: 'veh_A')).notifier,
        );
        final pushed = harness.container.read(
          historyProvider(
            const HistoryScope(vehicleId: 'veh_A', label: 'costs'),
          ).notifier,
        );

        await tab.load();
        await pushed.load();
        await tab.applyFilter(
          const HistoryFilter(kinds: {HistoryEntryKind.fillUp}),
        );

        expect(tab.state.filter.kinds, {HistoryEntryKind.fillUp});
        expect(
          pushed.state.filter.kinds,
          isEmpty,
          reason: 'the pushed instance keeps its own filter',
        );
      },
    );

    test('a filter change reloads from the top, not from the cursor', () async {
      final notifier = harness.container.read(
        historyProvider(const HistoryScope(vehicleId: 'veh_D')).notifier,
      );
      await notifier.load();
      await notifier.loadMore();
      expect(notifier.state.entries, hasLength(120));

      await notifier.applyFilter(
        const HistoryFilter(kinds: {HistoryEntryKind.fillUp}),
      );

      expect(notifier.state.entries, hasLength(60));
    });

    test(
      'a load keeps the previous rows rather than emptying the list',
      () async {
        // §11's budget note: "the list keeps its previous content, never a
        // spinner over existing rows."
        final notifier = harness.container.read(
          historyProvider(const HistoryScope(vehicleId: 'veh_E')).notifier,
        );
        await notifier.load();
        final before = notifier.state.entries.length;

        fake.pause();
        final pending = notifier.loadMore();
        expect(notifier.state.entries, hasLength(before));
        expect(notifier.state.isLoading, isTrue);
        fake.resume();
        await pending;

        expect(notifier.state.entries.length, greaterThan(before));
        expect(notifier.state.isLoading, isFalse);
      },
    );

    test('prefetch does not fire twice for the same tail', () async {
      final notifier = harness.container.read(
        historyProvider(const HistoryScope(vehicleId: 'veh_F')).notifier,
      );
      await notifier.load();
      final calls = fake.pageCalls;

      await Future.wait([notifier.loadMore(), notifier.loadMore()]);

      expect(
        fake.pageCalls,
        calls + 1,
        reason: 'a second request for the same tail is dropped, not queued',
      );
    });

    test('reaching the end stops asking', () async {
      final notifier = harness.container.read(
        historyProvider(const HistoryScope(vehicleId: 'veh_G')).notifier,
      );
      await notifier.load();
      for (var i = 0; i < 5; i++) {
        await notifier.loadMore();
      }
      final calls = fake.pageCalls;

      await notifier.loadMore();

      expect(notifier.state.hasMore, isFalse);
      expect(fake.pageCalls, calls, reason: 'no request past the end');
    });
  });
}
