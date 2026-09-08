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
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/due/due_order.dart';
import 'package:odova/core/due/due_summary.dart';

/// One chip on §10's *What was done* row.
///
/// The `kind` travels with the `label` because a SEED has no label — SPEC.md
/// §8 gives `ServiceItem.label` meaning only for `kind = custom` — and the
/// presentation
/// edge resolves the name from the kind. This file stays free of
/// `AppLocalizations`: a domain function that took one would need a
/// `BuildContext` to be tested.
typedef ServiceItemChipData = ({
  String id,
  ServiceKind kind,
  String? label,
  bool ticked,
});

/// The chips for [assessments], in §9's order.
///
/// Paused items are excluded because ticking one would re-anchor a reminder
/// the user has deliberately turned off.
///
/// **A blank label is no longer an exclusion**, and that filter is why the
/// form offered `+ Other` and nothing else on every vehicle: every seeded item
/// has a null label by construction, so the rule "an item with no label is
/// excluded" excluded the entire catalogue. The chip's text comes from its
/// kind now, so there is no such thing as a chip with no text.
List<ServiceItemChipData> serviceItemChips({
  required List<AssessedItem> assessments,
  required Set<String> ticked,
}) {
  final offered = assessments.where((a) => a.$1.isActive).toList()
    ..sort(compareAssessedItems);

  return [
    for (final assessed in offered)
      (
        id: assessed.$1.id.toString(),
        kind: assessed.$1.kind,
        label: assessed.$1.label,
        ticked: ticked.contains(assessed.$1.id.toString()),
      ),
  ];
}
