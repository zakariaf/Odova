// The timeline's state: what is loaded, what it is filtered to, and how much
// of it is allowed to be in memory.
//
// SPEC.md §11 *Pagination* fixes three numbers and gives a reason for each:
//
//     page size  = 60 rows
//     prefetch   = when the last rendered row is within 20 of the loaded tail
//     window cap = 400 rows in memory; loading past it drops from the far end
//
// The cap is the interesting one. §11: "memory stays flat at 40 records or
// 4,000." An eight-year history is the case this screen exists for — the week
// before selling, the day after a restore — so an unbounded list is not a
// theoretical leak here, it is the ordinary path.
//
// The provider is a FAMILY on `HistoryScope` and not a singleton, because
// EPIC-13 pushes a filtered instance of this timeline into the Costs stack.
// Two instances, two filters; a shared one would have the cost drill-down
// change what tab 2 is showing.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:meta/meta.dart';
import 'package:odova/core/history/history_cursor.dart';
import 'package:odova/core/history/history_entry.dart';
import 'package:odova/core/history/history_filter.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/history_repository.dart';

/// §11's page size.
const int kHistoryPageSize = 60;

/// §11's memory cap.
const int kHistoryWindowCap = 400;

/// Which timeline this is.
///
/// [label] distinguishes the tab-2 instance from one EPIC-13 pushes for the
/// same vehicle. Without it the two would share a provider and the cost
/// drill-down would silently re-filter tab 2.
@immutable
class HistoryScope {
  /// Creates a scope.
  const HistoryScope({required this.vehicleId, this.label = 'tab'});

  /// The vehicle whose timeline this is.
  final String vehicleId;

  /// What opened it.
  final String label;

  @override
  bool operator ==(Object other) =>
      other is HistoryScope &&
      other.vehicleId == vehicleId &&
      other.label == label;

  @override
  int get hashCode => Object.hash(vehicleId, label);
}

/// Everything the timeline draws.
@immutable
class HistoryState {
  /// Creates a state.
  const HistoryState({
    this.entries = const [],
    this.filter = HistoryFilter.all,
    this.months = const [],
    this.hasMore = true,
    this.isLoading = false,
    this.failure,
  });

  /// The loaded window, newest first.
  final List<HistoryEntry> entries;

  /// What the list is narrowed to.
  final HistoryFilter filter;

  /// The month index, for headers, the scrubber and the empty state.
  final List<MonthIndexEntry> months;

  /// Whether another page exists below the window.
  final bool hasMore;

  /// Whether a load is in flight.
  ///
  /// Beside the rows and never instead of them. §11's budget note: "the list
  /// keeps its previous content, never a spinner over existing rows."
  final bool isLoading;

  /// The last read failure, or null.
  final PersistFailure? failure;

  /// Where the next page resumes.
  HistoryCursor? get cursor => entries.isEmpty ? null : entries.last.cursor;

  /// A copy with the named fields replaced.
  HistoryState copyWith({
    List<HistoryEntry>? entries,
    HistoryFilter? filter,
    List<MonthIndexEntry>? months,
    bool? hasMore,
    bool? isLoading,
    PersistFailure? failure,
    bool clearFailure = false,
  }) => HistoryState(
    entries: entries ?? this.entries,
    filter: filter ?? this.filter,
    months: months ?? this.months,
    hasMore: hasMore ?? this.hasMore,
    isLoading: isLoading ?? this.isLoading,
    failure: clearFailure ? null : (failure ?? this.failure),
  );
}

/// Reads the timeline for one scope.
class HistoryNotifier extends Notifier<HistoryState> {
  /// Creates the notifier for [_scope].
  HistoryNotifier(this._scope);

  final HistoryScope _scope;

  @override
  HistoryState build() => const HistoryState();

  HistoryRepository get _repository => ref.read(historyRepositoryProvider);

  /// Loads the first page, discarding anything already loaded.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.page(
      vehicleId: _scope.vehicleId,
      filter: state.filter,
    );
    _absorb(result, replaceWindow: true);
  }

  /// Loads the next page onto the end of the window.
  ///
  /// Does nothing when a load is already in flight or the end has been
  /// reached. §11 prefetches "when the last rendered row is within 20 of the
  /// loaded tail", and a fast scroll crosses that line several times before
  /// the first response lands — without the guard each crossing queues another
  /// identical query.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.page(
      vehicleId: _scope.vehicleId,
      filter: state.filter,
      after: state.cursor,
    );
    _absorb(result, replaceWindow: false);
  }

  /// Narrows the list, and reloads from the top.
  ///
  /// From the TOP and not from the cursor: a filter change makes the loaded
  /// window a page of the wrong list, and resuming from its last row would
  /// start the new list two hundred entries down.
  Future<void> applyFilter(HistoryFilter filter) async {
    state = state.copyWith(filter: filter);
    await load();
  }

  /// Re-anchors the list at [month], discarding the loaded window.
  ///
  /// §11: "release runs a fresh keyset query anchored there and DISCARDS the
  /// loaded window, so memory stays flat at 40 records or 4,000."
  Future<void> jumpTo(MonthKey month) async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.pageAnchoredAt(
      vehicleId: _scope.vehicleId,
      filter: state.filter,
      year: month.year,
      month: month.month,
    );
    _absorb(result, replaceWindow: true);
  }

  void _absorb(
    Result<HistoryPage, PersistFailure> result, {
    required bool replaceWindow,
  }) {
    switch (result) {
      case Ok(:final value):
        final combined = replaceWindow
            ? value.entries
            : [...state.entries, ...value.entries];
        state = state.copyWith(
          // Dropped from the FAR end — the oldest loaded rows — so the user
          // keeps what they are looking at. Trimming the near end instead
          // would scroll the list out from under them mid-gesture.
          entries: combined.length <= kHistoryWindowCap
              ? combined
              : combined.sublist(combined.length - kHistoryWindowCap),
          hasMore: value.hasMore,
          isLoading: false,
          clearFailure: true,
        );
      case Err(:final failure):
        // The rows STAY. §11: "the list keeps its previous content, never a
        // spinner over existing rows" — and a read that failed is even less of
        // a reason to throw away what the user is reading.
        state = state.copyWith(isLoading: false, failure: failure);
    }
  }
}

/// The timeline, one instance per scope.
final NotifierProviderFamily<HistoryNotifier, HistoryState, HistoryScope>
historyProvider =
    NotifierProvider.family<HistoryNotifier, HistoryState, HistoryScope>(
      HistoryNotifier.new,
    );

/// The store this feature reads through.
final Provider<HistoryRepository> historyRepositoryProvider =
    Provider<HistoryRepository>(
      (ref) => HistoryRepository(ref.watch(appDatabaseProvider)),
    );
