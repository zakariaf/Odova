// One row on the timeline, whatever kind of row it is.
//
// SPEC.md §11: "One reverse-chronological list of every fill-up, service,
// expense, trip and standalone odometer reading for the active vehicle." Five
// row types plus one divider, and §11's layout draws them through "one row
// widget for all five types" — so they are one sealed type here, and the
// widget switches on it once.
//
// Two exclusions the QUERY makes, not the UI, because a filter applied after
// the page is a page of the wrong size:
//
//   1. **A derived odometer reading gets no row.** §3 says every record
//      carrying an odometer emits one, so a fill-up would otherwise appear
//      twice — once as itself and once as the reading it implied. Only
//      `source: manual` is a timeline entry.
//   2. **Deleted rows are absent.** §3's soft delete is "immediate and
//      permanent to the user", and a row filtered out in Dart still costs a
//      page slot.
//
// Pure Dart, no Flutter import.
import 'package:meta/meta.dart';
import 'package:odova/core/history/history_cursor.dart';

/// What kind of row this is. The filter chips of §11 select over it.
enum HistoryEntryKind {
  /// A fill-up.
  fillUp,

  /// A service record.
  service,

  /// A non-fuel, non-service cost.
  expense,

  /// A trip.
  trip,

  /// A reading the user typed, never one a record implied.
  odometer,

  /// A cluster swap, drawn as a divider rather than as an entry.
  ///
  /// §11 gives it "a divider entry at their from_reading position": it is not
  /// something that happened to the car, it is a change in how the numbers
  /// either side of it are read, and drawing it as a row would put it in the
  /// month's entry count and its subtotal.
  correction,
}

/// One row on the timeline.
@immutable
class HistoryEntry {
  /// Creates an entry.
  const HistoryEntry({
    required this.kind,
    required this.id,
    required this.occurredOn,
    required this.createdAtUtcMs,
    this.minorUnits,
    this.currency,
    this.odometerM,
    this.quantity,
    this.quantityForm,
    this.label,
    this.secondaryLabel,
    this.isFullTank = true,
    this.chainBroken = false,
    this.odometerEstimated = false,
  });

  /// Which of §11's row types this is.
  final HistoryEntryKind kind;

  /// The source row's id, prefix and all.
  final String id;

  /// The day it happened, as `YYYY-MM-DD`.
  ///
  /// For a [HistoryEntryKind.correction] this is the date of the reading it
  /// corrects, which is what puts the divider in the right place rather than
  /// at the date the swap was recorded.
  final String occurredOn;

  /// When the row was written.
  final int createdAtUtcMs;

  /// The row's money, in minor units, or null where the type has none.
  ///
  /// Beside its [currency] and never without it. An odometer row has no amount
  /// at all — §11's table prints nothing in the column — so this is nullable
  /// rather than a zero, because zero is a real price a warranty job can have.
  final int? minorUnits;

  /// The ISO 4217 code [minorUnits] is in.
  final String? currency;

  /// The odometer this row carries, in metres, or null.
  final int? odometerM;

  /// How much fuel, in the canonical integer of [quantityForm].
  final int? quantity;

  /// Which of §3's three quantity columns [quantity] came from.
  ///
  /// `ml`, `g` or `wh`. Carried rather than inferred from the fuel kind,
  /// because the row that was WRITTEN is the authority on which column holds
  /// it — a vehicle whose default fuel changed would otherwise re-read its own
  /// history in the wrong unit.
  final String? quantityForm;

  /// The row's own name: a station, a vendor, a category, a trip title.
  final String? label;

  /// A second name where §11's table shows one — a grade, a coverage window.
  final String? secondaryLabel;

  /// Whether a fill-up filled the tank. False draws §11's partial badge.
  final bool isFullTank;

  /// Whether the chain before this fill was broken.
  final bool chainBroken;

  /// Whether the odometer was projected rather than entered.
  final bool odometerEstimated;

  /// This entry's position in the timeline's order.
  HistoryCursor get cursor => HistoryCursor(
    occurredOn: occurredOn,
    createdAtUtcMs: createdAtUtcMs,
    id: id,
  );

  @override
  String toString() => 'HistoryEntry(${kind.name}, $occurredOn, $id)';
}

/// One page of the timeline, and where it stopped.
@immutable
class HistoryPage {
  /// Creates a page.
  const HistoryPage({required this.entries, required this.hasMore});

  /// The rows, in §11's order.
  final List<HistoryEntry> entries;

  /// Whether another page exists below this one.
  ///
  /// Answered by asking for one row MORE than the page size and discarding it,
  /// rather than by comparing the page's length to the limit — a page that
  /// happens to end exactly on the boundary is not the end of the list, and
  /// treating it as one silently truncates a user's history at row 60.
  final bool hasMore;

  /// Where the next page resumes, or null at the end.
  HistoryCursor? get nextCursor =>
      entries.isEmpty || !hasMore ? null : entries.last.cursor;
}
