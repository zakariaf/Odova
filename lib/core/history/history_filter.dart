// Which rows the timeline is showing.
//
// SPEC.md §11's chip row: All · Fuel · Service · … · a year. EPIC-13 pushes a
// FILTERED instance of `history` into its own stack — the costs screens drill
// into "these entries" — so this type is a public contract between two
// features rather than an internal detail of one.
//
// Pure Dart, no Flutter import.
import 'package:meta/meta.dart';
import 'package:odova/core/history/history_entry.dart';

/// What the timeline is narrowed to.
@immutable
class HistoryFilter {
  /// Creates a filter.
  const HistoryFilter({this.kinds = const {}, this.year});

  /// Everything, unfiltered.
  static const HistoryFilter all = HistoryFilter();

  /// The kinds to show. EMPTY means all of them.
  ///
  /// Empty and not "every value", so that adding a sixth row type does not
  /// silently exclude it from every previously-constructed filter.
  final Set<HistoryEntryKind> kinds;

  /// The year to show, or null for every year.
  final int? year;

  /// Whether [kind] passes this filter.
  bool allows(HistoryEntryKind kind) => kinds.isEmpty || kinds.contains(kind);

  /// A copy showing only [kinds].
  HistoryFilter withKinds(Set<HistoryEntryKind> kinds) =>
      HistoryFilter(kinds: kinds, year: year);

  /// A copy showing [year], or every year when it is null.
  HistoryFilter inYear(int? year) => HistoryFilter(kinds: kinds, year: year);

  @override
  String toString() => 'HistoryFilter(${kinds.map((k) => k.name)}, $year)';
}
