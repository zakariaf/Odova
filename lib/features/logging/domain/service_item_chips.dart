// The service form's item chips, and the order they are offered in.
//
// SPEC.md §10 `log.service`: "item chips are the vehicle's active items,
// sorted overdue → due → due soon → ok — paused items excluded, `+ Other`
// last."
//
// The ORDER is not this file's invention and must not become one.
// `compareAssessedItems` is what Home's three cards and `reminders.list`
// already sort by, and `due_order.dart` says exactly why a second comparator
// is a bug: "Two orders that disagree about which item to name first is the
// bug that rule exists to prevent." So this filters and maps; it does not
// decide.
//
// It has no opinion about due STATE either — no colour, no badge, no rank of
// its own — which is what keeps `check_status_encoding.sh` satisfied that one
// place resolves that.
import 'package:odova/core/due/due_order.dart';
import 'package:odova/core/due/due_summary.dart';

/// One chip on §10's *What was done* row.
typedef ServiceItemChipData = ({String id, String label, bool ticked});

/// The chips for [assessments], in §9's order.
///
/// Paused items are excluded because ticking one would re-anchor a reminder
/// the user has deliberately turned off. An item with no label is excluded
/// too: a chip with no text is a control the user can neither read nor
/// describe to a screen reader.
List<ServiceItemChipData> serviceItemChips({
  required List<AssessedItem> assessments,
  required Set<String> ticked,
}) {
  final offered =
      assessments
          .where((a) => a.$1.isActive && (a.$1.label ?? '').trim().isNotEmpty)
          .toList()
        ..sort(compareAssessedItems);

  return [
    for (final assessed in offered)
      (
        id: assessed.$1.id.toString(),
        label: assessed.$1.label!,
        ticked: ticked.contains(assessed.$1.id.toString()),
      ),
  ];
}
