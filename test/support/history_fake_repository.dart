/// A `HistoryRepository` with rows and no database.
///
/// The notifier's tests are about the WINDOW and the cursor, not about SQL —
/// `history_repository_test.dart` owns the query. Driving them through a real
/// store would make every window assertion depend on a fixture of 540 seeded
/// rows, and a drift stream does not deliver under `testWidgets` anyway.
///
/// It also does two things a real repository cannot be asked to do on demand:
/// pause mid-load, so "the list keeps its previous content" is assertable, and
/// count its own calls, so "prefetch does not fire twice" is not a guess.
library;

import 'dart:async';

import 'package:odova/core/history/history_cursor.dart';
import 'package:odova/core/history/history_entry.dart';
import 'package:odova/core/history/history_filter.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/history_repository.dart';

/// A repository over a generated list of entries.
class FakeHistoryRepository implements HistoryRepository {
  /// Creates a fake holding [totalRows] entries.
  FakeHistoryRepository({required this.totalRows});

  /// How many rows the whole "vehicle" has.
  final int totalRows;

  /// How many times a page has been asked for.
  int pageCalls = 0;

  Completer<void>? _gate;

  /// Holds the next load open until [resume].
  void pause() => _gate = Completer<void>();

  /// Lets a paused load finish.
  void resume() {
    _gate?.complete();
    _gate = null;
  }

  /// A gate per in-flight call, so responses can be released OUT OF ORDER.
  ///
  /// `pause`/`resume` hold every call behind one latch, which is enough to
  /// test "the list keeps its content while loading" but cannot reproduce the
  /// race that matters: request A issued first, request B issued second, and
  /// A's response landing LAST. That is the ordering a slow query and a fast
  /// one produce on a real device, and it is the one the generation guard
  /// exists for.
  final List<Completer<void>> holds = [];

  /// Holds every subsequent call until its entry in [holds] is completed.
  bool holdEachCall = false;

  /// Releases the [index]th held call.
  void release(int index) {
    if (index < holds.length && !holds[index].isCompleted) {
      holds[index].complete();
    }
  }

  /// The id of the entry at [index], newest first.
  String idAt(int index) => 'ent_${index.toString().padLeft(6, '0')}';

  HistoryEntry _entry(int index, {HistoryEntryKind? kind}) => HistoryEntry(
    kind: kind ?? HistoryEntryKind.fillUp,
    id: idAt(index),
    // Descending days from a fixed start, so the order is unambiguous and the
    // cursor has something real to compare.
    occurredOn: _dayBefore(index),
    createdAtUtcMs: 1000000 - index,
  );

  static String _dayBefore(int index) {
    final day = DateTime.utc(2026, 12, 31).subtract(Duration(days: index));
    return '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<Result<HistoryPage, PersistFailure>> page({
    required String vehicleId,
    required HistoryFilter filter,
    HistoryCursor? after,
    int limit = 60,
  }) async {
    pageCalls++;
    if (holdEachCall) {
      final hold = Completer<void>();
      holds.add(hold);
      await hold.future;
    }
    if (_gate != null) await _gate!.future;

    final start = after == null ? 0 : int.parse(after.id.split('_').last) + 1;
    final end = (start + limit).clamp(0, totalRows);
    return Ok(
      HistoryPage(
        // The rows CARRY the filter they were fetched for.
        //
        // Without this the fake returns identical entries whatever was asked
        // for, so a stale response and a fresh one are indistinguishable and
        // no test can tell whether the wrong one was committed. That is the
        // whole point of the generation guard, and it is exactly the property
        // a fake this convenient hides.
        entries: [
          for (var i = start; i < end; i++) _entry(i, kind: _kindOf(filter)),
        ],
        hasMore: end < totalRows,
      ),
    );
  }

  static HistoryEntryKind _kindOf(HistoryFilter filter) =>
      filter.kinds.length == 1 ? filter.kinds.first : HistoryEntryKind.fillUp;

  @override
  Future<Result<HistoryPage, PersistFailure>> pageAnchoredAt({
    required String vehicleId,
    required HistoryFilter filter,
    required MonthKey month,
    int limit = 60,
  }) async {
    pageCalls++;
    if (holdEachCall) {
      final hold = Completer<void>();
      holds.add(hold);
      await hold.future;
    }
    return Ok(
      HistoryPage(
        entries: [for (var i = 0; i < limit; i++) _entry(i)],
        hasMore: true,
      ),
    );
  }

  @override
  Future<Result<List<MonthIndexEntry>, PersistFailure>> monthIndex({
    required String vehicleId,
    required HistoryFilter filter,
    required CalmCalendar calendar,
  }) async => Ok([
    // The index counts the WHOLE vehicle, not the loaded window — which is
    // what §11's scrubber and search thresholds are measured against. A fake
    // returning an empty list made those thresholds untestable: the count was
    // zero however many rows the repository held.
    if (totalRows > 0)
      MonthIndexEntry(
        monthKey: MonthKey(calendar: calendar, year: 2026, month: 12),
        count: totalRows,
        totals: const {'EUR': 1000},
      ),
  ]);
}

/// A repository whose every read fails.
///
/// §11's store-read failure is a whole-screen state with one act, and the only
/// way to reach it in a test is a store that refuses. A real one cannot be
/// asked to break on demand.
class FailingHistoryRepository implements HistoryRepository {
  /// Creates the fake.
  const FailingHistoryRepository();

  @override
  Future<Result<HistoryPage, PersistFailure>> page({
    required String vehicleId,
    required HistoryFilter filter,
    HistoryCursor? after,
    int limit = 60,
  }) async => const Err(WriteFailed('the store will not open'));

  @override
  Future<Result<HistoryPage, PersistFailure>> pageAnchoredAt({
    required String vehicleId,
    required HistoryFilter filter,
    required MonthKey month,
    int limit = 60,
  }) async => const Err(WriteFailed('the store will not open'));

  @override
  Future<Result<List<MonthIndexEntry>, PersistFailure>> monthIndex({
    required String vehicleId,
    required HistoryFilter filter,
    required CalmCalendar calendar,
  }) async => const Err(WriteFailed('the store will not open'));
}
