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
    this.isSearching = false,
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

  /// Whether the app bar is showing the search field.
  ///
  /// Separate from `filter.query` being empty, because §11 opens the field
  /// BEFORE anything is typed: "Tapping `⌕` replaces the app bar title with a
  /// text field in place — no push, no modal, no route change." An empty query
  /// while searching shows the unfiltered list, not the no-match state.
  final bool isSearching;

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
    bool? isSearching,
  }) => HistoryState(
    entries: entries ?? this.entries,
    filter: filter ?? this.filter,
    months: months ?? this.months,
    hasMore: hasMore ?? this.hasMore,
    isLoading: isLoading ?? this.isLoading,
    failure: clearFailure ? null : (failure ?? this.failure),
    segments: segments ?? this.segments,
    isSearching: isSearching ?? this.isSearching,
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

  /// Opens the search field, keeping the chips as they are.
  ///
  /// §11: search "composes with the chips (AND), so 'Fuel · 2024 · shell' is
  /// expressible." Entering search therefore changes nothing about the list —
  /// only what the app bar shows.
  void enterSearch() {
    if (state.isSearching) return;
    state = state.copyWith(isSearching: true);
  }

  /// Closes the field and restores the filter as it was.
  ///
  /// §11: "System back and the `✕` exit search and restore the previous filter
  /// state." That means the QUERY goes and the chips stay — a user who
  /// narrowed to Fuel · 2024 and then searched has not asked to lose the
  /// narrowing.
  ///
  /// An earlier version snapshotted the whole filter on entering search and
  /// put it back on leaving, so that chips changed DURING a search were also
  /// undone. It was removed rather than kept: §11 does not ask for it, no test
  /// could tell the two apart, and undoing a selection the user made
  /// deliberately is the more surprising of the two behaviours.
  Future<void> exitSearch() async {
    if (!state.isSearching) return;
    _debounce?.cancel();
    _debounce = null;
    state = state.copyWith(isSearching: false);
    await applyFilter(state.filter.withQuery(''));
  }

  /// Types [query] into the search field, running it after [debounce].
  ///
  /// The interval is passed in rather than held here, and it comes from
  /// `CalmMotion.searchDebounce`. §11's 200 ms is a UI-timing decision, not a
  /// domain rule — and every other duration in this app lives on that
  /// extension, for the reason its own doc comment gives: a gate cannot tell a
  /// debounce from an animation, so nothing constructs a `Duration` outside
  /// `lib/theme/`.
  ///
  /// Debounced at all because every keystroke otherwise runs a `LIKE` over
  /// every text column of every row — measured at ~18 ms over 3,000 rows,
  /// which is fine once and is not fine eight times while a word is typed.
  void search(String query, {required Duration debounce}) {
    _debounce?.cancel();
    _debounce = Timer(
      debounce,
      () => unawaited(applyFilter(state.filter.withQuery(query))),
    );
  }

  Timer? _debounce;

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
          // Dropped from the HEAD, which on a newest-first list is the most
          // recent rows. That reads backwards until you remember which way
          // this list paginates: `loadMore` only ever fetches OLDER pages, so
          // the user is travelling towards the tail and the rows under their
          // thumb are the oldest ones. The head is the far end.
          //
          // The wording matters because the previous comment said "the oldest
          // loaded rows", which is the opposite of what this line does, and a
          // reader trusting it would 'fix' the code and scroll the list out
          // from under the user mid-gesture. `history_notifier_test.dart`
          // pins the direction: ten pages of 60 keep indices 200–599.
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
