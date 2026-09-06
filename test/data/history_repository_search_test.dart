// Search, as a query over the store.
//
// SPEC.md §11: "Search is a query — SQL `LIKE` over the normalised expression
// of each text column — not a stored `search_blob`; a stale index surviving a
// Replace import would be a nasty bug."
//
// The normalisation is `normaliseForSearch`, on BOTH sides: the query string
// in Dart, and each column through the `odova_search_fold` function
// `applyPragmas` registers. One implementation, so the two cannot drift.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/history/history_entry.dart';
import 'package:odova/core/history/history_filter.dart';
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

  Future<List<HistoryEntry>> search(String query) async {
    final result = await history.page(
      vehicleId: historyVehicleId,
      filter: HistoryFilter(query: query),
    );
    return (result as Ok<HistoryPage, PersistFailure>).value.entries;
  }

  test('matches a station, case-insensitively', () async {
    await insertFillUp(
      harness.db,
      id: 'fil_01K1C4V2H9B8N3Q7ZE5RY6TMS1',
    );
    await harness.db.customStatement(
      "UPDATE fill_ups SET station = 'Shell A61' WHERE id = ?",
      ['fil_01K1C4V2H9B8N3Q7ZE5RY6TMS1'],
    );

    expect(await search('shell'), hasLength(1));
    expect(await search('SHELL'), hasLength(1));
    expect(await search('a61'), hasLength(1));
  });

  test('folds an accent on the COLUMN side, not only the query', () async {
    // The half that proves both sides are normalised. `Süd` is stored; `sud`
    // is typed. Only the column-side fold can make that match.
    await insertFillUp(
      harness.db,
      id: 'fil_01K1C4V2H9B8N3Q7ZE5RY6TMS2',
    );
    await harness.db.customStatement(
      "UPDATE fill_ups SET station = 'Südstraße' WHERE id = ?",
      ['fil_01K1C4V2H9B8N3Q7ZE5RY6TMS2'],
    );

    expect(await search('sud'), hasLength(1));
  });

  test('a Persian numeral query finds a Latin invoice reference', () async {
    // §11's own example for why digits are folded.
    await insertServiceRecord(
      harness.db,
      id: 'srv_01K1C4V2H9B8N3Q7ZE5RY6TMS3',
    );
    await insertServiceLine(
      harness.db,
      id: 'lin_01K1C4V2H9B8N3Q7ZE5RY6TMS3',
      serviceRecordId: 'srv_01K1C4V2H9B8N3Q7ZE5RY6TMS3',
    );
    await harness.db.customStatement(
      "UPDATE service_records SET invoice_ref = 'RE-2026' WHERE id = ?",
      ['srv_01K1C4V2H9B8N3Q7ZE5RY6TMS3'],
    );

    expect(await search('۲۰۲۶'), hasLength(1));
  });

  test('does not match a category enum name', () async {
    // §11 lists the searchable fields and `category` is not among them. An
    // expense whose category is `insurance` must not answer a search for
    // "insurance" that the user meant as a vendor.
    await insertExpense(
      harness.db,
      id: 'exp_01K1C4V2H9B8N3Q7ZE5RY6TMS4',
    );

    expect(await search('insurance'), isEmpty);
  });

  test('a query under two characters returns the unfiltered list', () async {
    // §11: "min = 2 characters". One character over three thousand rows
    // matches most of them, which is a slower way of showing everything.
    await insertFillUp(
      harness.db,
      id: 'fil_01K1C4V2H9B8N3Q7ZE5RY6TMS5',
    );

    expect(await search('s'), hasLength(1));
    expect(await search(''), hasLength(1));
  });

  test('search composes with the chips as AND', () async {
    // "Fuel · shell" is expressible: a matching expense is excluded by the
    // type chip, not by the query.
    await insertFillUp(
      harness.db,
      id: 'fil_01K1C4V2H9B8N3Q7ZE5RY6TMS6',
    );
    await harness.db.customStatement(
      "UPDATE fill_ups SET station = 'Shell' WHERE id = ?",
      ['fil_01K1C4V2H9B8N3Q7ZE5RY6TMS6'],
    );
    await insertExpense(
      harness.db,
      id: 'exp_01K1C4V2H9B8N3Q7ZE5RY6TMS7',
      label: 'Shell car wash',
      category: 'other',
    );

    expect(await search('shell'), hasLength(2));

    final fuelOnly = await history.page(
      vehicleId: historyVehicleId,
      filter: const HistoryFilter(
        kinds: {HistoryEntryKind.fillUp},
        query: 'shell',
      ),
    );
    expect(
      (fuelOnly as Ok<HistoryPage, PersistFailure>).value.entries,
      hasLength(1),
    );
  });

  test('results keep reverse-chronological order — no ranking', () async {
    // §11: "Results keep the same reverse-chronological order and month
    // grouping. A ranked list would be a second list widget with second
    // rules."
    for (final (i, on) in ['2026-01-10', '2026-05-10', '2026-09-10'].indexed) {
      await insertFillUp(
        harness.db,
        id: 'fil_01K1C4V2H9B8N3Q7ZE5RY6TMR$i',
        occurredOn: on,
      );
      await harness.db.customStatement(
        "UPDATE fill_ups SET station = 'Shell' WHERE id = ?",
        ['fil_01K1C4V2H9B8N3Q7ZE5RY6TMR$i'],
      );
    }

    final rows = await search('shell');

    expect(
      rows.map((e) => e.occurredOn).toList(),
      ['2026-09-10', '2026-05-10', '2026-01-10'],
    );
  });
}
