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
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:meta/meta.dart';
import 'package:odova/core/fuel/fuel_segment.dart';
import 'package:odova/core/history/history_cursor.dart';
import 'package:odova/core/history/history_entry.dart';
import 'package:odova/core/history/history_filter.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/history_repository.dart';

/// §11's page size.
const int kHistoryPageSize = 60;

/// §11's memory cap.
const int kHistoryWindowCap = 400;

/// Above how many entries §11 shows the year scrubber.
///
/// "Scrubber appears above 150 rows, the search affordance above 200 — below
/// that, filters beat typing." Two thresholds and not one, because they answer
/// different questions: a scrubber is for reaching 2019, and search is for
/// "what did that garage in Ingolstadt charge me".
const int kHistoryScrubberThreshold = 150;

/// Above how many entries §11 shows the search affordance.
const int kHistorySearchThreshold = 200;

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
    this.segments,
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

  /// The vehicle's fuel segments, or null before they are known.
  ///
  /// §11's trailing consumption figure comes from these and from nothing else:
  /// "renders only where `buildFuelSegments` returns one for the segment ending
  /// at that fill." A row cannot compute its own — a segment spans two fills,
  /// and the one that closes it is not the one that opened it.
  ///
  /// **Null today, and deliberately.** Filling it needs the correction-aware
  /// cumulative for each fill's own derived reading, which is the fuel
  /// pipeline EPIC-13 builds for `costs.fuel`. Writing a second copy of it
  /// here is the thing CLAUDE.md names first among the don'ts, and null is not
  /// a broken state: §11 says the slot is "blank; never `0.0`", so a timeline
  /// with no segments draws exactly what a timeline with no closed segment
  /// draws. EPIC-13 supplies the provider and this reads it.
  final FuelSegmentSet? segments;

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
    FuelSegmentSet? segments,
  }) => HistoryState(
    entries: entries ?? this.entries,
    filter: filter ?? this.filter,
    months: months ?? this.months,
    hasMore: hasMore ?? this.hasMore,
    isLoading: isLoading ?? this.isLoading,
    failure: clearFailure ? null : (failure ?? this.failure),
    segments: segments ?? this.segments,
  );
}

/// Reads the timeline for one scope.
class HistoryNotifier extends Notifier<HistoryState> {
  /// Creates the notifier for [_scope].
  HistoryNotifier(this._scope);

  final HistoryScope _scope;

  @override
  HistoryState build() => const HistoryState();

  bool _started = false;

  /// Loads the first page, once, however many times it is called.
  ///
  /// The screen calls this on every build and it acts on the first. It is NOT
  /// done inside [build]: `load` reads `state`, and reading it before `build`
  /// has returned is a provider depending on itself — Riverpod says so in
  /// those words, and the first version of this got exactly that error.
  ///
  /// §7 resets this tab's stack on a vehicle switch, which disposes the
  /// provider; the next screen build gets a fresh notifier with `_started`
  /// false, so the reload arrives without a second trigger.
  Future<void> ensureLoaded() async {
    if (_started) return;
    _started = true;
    // A MICROTASK, so the first state write lands after the frame that asked
    // for it. `load` sets `isLoading` before its first await, and doing that
    // inside a widget's build is "tried to modify a provider while the widget
    // tree was building" — which Riverpod asserts on rather than tolerating.
    await Future<void>.microtask(load);
  }

  HistoryRepository get _repository => ref.read(historyRepositoryProvider);

  /// The calendar the month index groups by.
  ///
  /// Settable so a screen can hand down the resolved setting — §5's calendar
  /// is a user preference and this layer has no `BuildContext` to read it
  /// from. Changing it rebuilds the index rather than remapping it, per §11.
  CalmCalendar calendar = CalmCalendar.gregorian;

  /// Re-groups the index under [next], if it differs.
  Future<void> useCalendar(CalmCalendar next) async {
    if (next == calendar) return;
    calendar = next;
    await _loadIndex();
  }

  /// Loads the first page and the month index together.
  ///
  /// Both, because §11's headers, scrubber and empty state all read the index
  /// and none of them reads the loaded window — a page without an index draws
  /// a list with no subtotals, which is the screen's whole reason for existing
  /// during the anxious check.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final page = await _repository.page(
      vehicleId: _scope.vehicleId,
      filter: state.filter,
    );
    _absorb(page, replaceWindow: true);
    await _loadIndex();
  }

  Future<void> _loadIndex() async {
    final index = await _repository.monthIndex(
      vehicleId: _scope.vehicleId,
      filter: state.filter,
      calendar: calendar,
    );
    if (index case Ok(:final value)) {
      state = state.copyWith(months: value);
    }
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
