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

  /// The id of the entry at [index], newest first.
  String idAt(int index) => 'ent_${index.toString().padLeft(6, '0')}';

  HistoryEntry _entry(int index) => HistoryEntry(
    kind: HistoryEntryKind.fillUp,
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
    if (_gate != null) await _gate!.future;

    final start = after == null ? 0 : int.parse(after.id.split('_').last) + 1;
    final end = (start + limit).clamp(0, totalRows);
    return Ok(
      HistoryPage(
        entries: [for (var i = start; i < end; i++) _entry(i)],
        hasMore: end < totalRows,
      ),
    );
  }

  @override
  Future<Result<HistoryPage, PersistFailure>> pageAnchoredAt({
    required String vehicleId,
    required HistoryFilter filter,
    required int year,
    required int month,
    int limit = 60,
  }) async {
    pageCalls++;
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
    required int year,
    required int month,
    int limit = 60,
  }) async => const Err(WriteFailed('the store will not open'));

  @override
  Future<Result<List<MonthIndexEntry>, PersistFailure>> monthIndex({
    required String vehicleId,
    required HistoryFilter filter,
    required CalmCalendar calendar,
  }) async => const Err(WriteFailed('the store will not open'));
}
