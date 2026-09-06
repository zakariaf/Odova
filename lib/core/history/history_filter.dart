// Which rows the timeline is showing.
//
// SPEC.md §11's chip row: All · Fuel · Service · … · a year. EPIC-13 pushes a
// FILTERED instance of `history` into its own stack — the costs screens drill
// into "these entries" — so this type is a public contract between two
// features rather than an internal detail of one.
//
// Pure Dart, no Flutter import.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/history/history_entry.dart';

/// What the timeline is narrowed to.
@immutable
class HistoryFilter {
  /// Creates a filter.
  const HistoryFilter({
    this.kinds = const {},
    this.year,
    this.categories = const {},
    this.needsAttention = false,
    this.query = '',
  });

  /// The filter EPIC-13's cost screens push this timeline in with.
  ///
  /// A named constructor rather than a builder chain, because it is the
  /// CONTRACT between two features: a cost card drills into "these entries",
  /// and the set of things it can narrow by has to be visible in one signature
  /// rather than discovered from six `with*` calls.
  const HistoryFilter.preset({
    required Set<HistoryEntryKind> kinds,
    int? year,
    Set<ExpenseCategory> categories = const {},
  }) : this(kinds: kinds, year: year, categories: categories);

  /// Everything, unfiltered.
  static const HistoryFilter all = HistoryFilter();

  /// The kinds to show. EMPTY means all of them.
  ///
  /// Empty and not "every value", so that adding a sixth row type does not
  /// silently exclude it from every previously-constructed filter.
  final Set<HistoryEntryKind> kinds;

  /// The year to show, or null for every year.
  final int? year;

  /// Which expense categories to show. EMPTY means all of them.
  ///
  /// §11 gives this chip only while the type chip is Expense, and switching
  /// away CLEARS it rather than leaving it applied invisibly — a filter the
  /// user cannot see is a list they cannot explain.
  final Set<ExpenseCategory> categories;

  /// Only rows carrying one of §11's flag badges.
  ///
  /// §11 hides this chip when the count is zero, so a vehicle with nothing
  /// wrong never sees a control that would return an empty list.
  final bool needsAttention;

  /// The search text, or empty when search is not open.
  final String query;

  /// Whether [kind] passes this filter.
  bool allows(HistoryEntryKind kind) => kinds.isEmpty || kinds.contains(kind);

  /// Whether this filter narrows anything at all.
  bool get isEmpty =>
      kinds.isEmpty &&
      year == null &&
      categories.isEmpty &&
      !needsAttention &&
      query.isEmpty;

  /// A copy showing only [kinds].
  ///
  /// Leaving Expense DROPS the category selection. §11 shows that chip only
  /// while the type is Expense, and a category still applied behind a Fuel
  /// chip is a filter the user cannot see narrowing a list they cannot
  /// explain.
  HistoryFilter withKinds(Set<HistoryEntryKind> next) => _copy(
    kinds: next,
    categories: next.contains(HistoryEntryKind.expense) ? categories : const {},
  );

  /// A copy showing [year], or every year when it is null.
  HistoryFilter inYear(int? year) => _copy(year: year, clearYear: year == null);

  /// A copy narrowed to [categories].
  HistoryFilter withCategories(Set<ExpenseCategory> categories) =>
      _copy(categories: categories);

  /// A copy showing only flagged rows, or all of them.
  HistoryFilter withNeedsAttention({required bool only}) =>
      _copy(needsAttention: only);

  /// A copy searching for [query].
  HistoryFilter withQuery(String query) => _copy(query: query);

  HistoryFilter _copy({
    Set<HistoryEntryKind>? kinds,
    int? year,
    bool clearYear = false,
    Set<ExpenseCategory>? categories,
    bool? needsAttention,
    String? query,
  }) => HistoryFilter(
    kinds: kinds ?? this.kinds,
    year: clearYear ? null : (year ?? this.year),
    categories: categories ?? this.categories,
    needsAttention: needsAttention ?? this.needsAttention,
    query: query ?? this.query,
  );

  // VALUE equality, and it is load-bearing. The month index is memoised per
  // filter and the notifier reloads when the filter changes; with identity
  // equality every rebuild would look like a new filter and re-run both
  // queries.
  @override
  bool operator ==(Object other) =>
      other is HistoryFilter &&
      _sameSet(other.kinds, kinds) &&
      other.year == year &&
      _sameSet(other.categories, categories) &&
      other.needsAttention == needsAttention &&
      other.query == query;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(kinds),
    year,
    Object.hashAllUnordered(categories),
    needsAttention,
    query,
  );

  static bool _sameSet<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  String toString() =>
      'HistoryFilter(${kinds.map((k) => k.name)}, $year, '
      '${categories.map((c) => c.wire)}, $needsAttention, "$query")';
}
