// Home's due stack, decided once before any widget exists.
//
// SPEC.md §9 *Ordering* and *The unknown-anchor card*. Everything here is
// PRESENTATION over facts `lib/core/due/` already computed: this file adds no
// arithmetic, persists nothing, and does not second-guess the engine about
// whether an item is due. What it does decide is what Home SHOWS, and the two
// are not the same thing — §9's unknown-anchor rule is exactly a case where a
// correct `overdue` is the wrong thing to draw.
//
// Pure Dart, no Flutter import, so it tests in milliseconds and the sort can be
// reasoned about without a widget harness.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_order.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/due/resolve_anchor.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/time/civil_date.dart';

/// How many cards the stack ever shows. SPEC.md §9: "1 primary + up to 2
/// secondary. Never more."
const int kHomeCardCap = 3;

/// How many items the unknown-anchor card names before it counts the rest.
const int kUnknownNamedCap = 3;

/// Whether an item anchored on [rung] is `unknown` ON HOME.
///
/// PRESENTATION ONLY, and the due engine is untouched by it. SPEC.md §9: "When
/// `resolveAnchor` falls back to `purchase_date` or the earliest reading, a
/// 2019 car entered today shows eleven seeded items instantly `overdue`. Home
/// renders any item anchored on the `purchase` or `first_reading` rung as
/// `unknown`, whatever the due engine returns."
///
/// The engine is right and Home is right: the arithmetic really does say the
/// oil is overdue if you measure from the day the car was bought. What the app
/// does not know is when it was last CHANGED, and an app that shouts OVERDUE
/// eleven times on day one gets its notifications turned off on day two.
bool isUnknownOnHome(AnchorRung? rung) =>
    rung == AnchorRung.purchase || rung == AnchorRung.firstReading;

/// One card in the stack.
@immutable
class DueCardModel {
  /// Creates a card.
  const DueCardModel({
    required this.item,
    required this.assessment,
    this.snoozedUntil,
  });

  /// What the card is about.
  final ServiceItem item;

  /// What the engine concluded about it.
  final DueAssessment assessment;

  /// The day a snooze runs out, or null.
  ///
  /// §9: "A snoozed item stays on Home, stays red, and gains a fourth line."
  /// It is not a state — it is a line — which is why it sits beside the
  /// assessment rather than inside it.
  final CivilDate? snoozedUntil;

  /// The state the card draws.
  DueState get state => assessment.state;
}

/// The one card every unknown-anchored item collapses into.
///
/// §9 draws it at the FOOT of the stack, names three items and counts the rest:
/// "When were these last done? … Telling me turns them into reminders."
@immutable
class UnknownAnchorCard {
  /// Creates the card.
  const UnknownAnchorCard({required this.items, required this.labels});

  /// Every item behind the card, so a tap can open the right one.
  final List<ServiceItem> items;

  /// The first [kUnknownNamedCap] labels, in stack order.
  final List<String> labels;

  /// How many are not named. Rendered as `+ n more`.
  int get moreCount => items.length - labels.length;
}

/// What Home draws, in the order it draws it.
@immutable
class HomeStack {
  /// Creates a stack.
  const HomeStack({
    required this.cards,
    required this.trackedCount,
    required this.moreDueCount,
    this.unknown,
  });

  /// At most [kHomeCardCap]: one primary and up to two secondaries.
  final List<DueCardModel> cards;

  /// Every tracked item on the vehicle, due or not.
  ///
  /// §9: the see-all row reads "See all reminders (14)" — "all tracked items,
  /// not just due ones". Counting the due ones there would make the row
  /// disagree with the screen it opens.
  final int trackedCount;

  /// How many due or overdue items did not fit. Rendered as the red see-all
  /// row.
  final int moreDueCount;

  /// The collapsed unknown-anchor card, or null when nothing is unknown.
  final UnknownAnchorCard? unknown;
}

/// Builds the stack SPEC.md §9 describes, from what the engine concluded.
///
/// PURE: no clock, no repository, no `BuildContext`. [today] is an argument
/// because §3 says time is one, and because a stack that read the clock could
/// not be tested at a boundary.
HomeStack buildHomeStack({
  required List<AssessedItem> items,
  required CivilDate today,
  ServiceItemId? pinnedItemId,
}) {
  final unknownItems = <ServiceItem>[];
  final due = <DueCardModel>[];
  var tracked = 0;

  for (final (item, assessment) in items) {
    if (item.isTracked) tracked++;

    // §9's *The unknown-anchor card*: "Only tracked items appear; untracked
    // catalogue rows live on `reminders.list`." The engine only assesses
    // eligible items, so an untracked one should not be here at all — but the
    // guard is what makes that a property of THIS function rather than a
    // promise the engine keeps on its behalf, and an untracked row in the
    // unknown card is a catalogue entry the user never asked to be reminded
    // about.
    if (!item.isTracked) continue;

    // §9's "not on Home at all", and a paused item is not a state the engine
    // reports — it is `is_active == false`, which the engine assesses anyway.
    if (!item.isActive) continue;
    if (assessment.state == DueState.ok) continue;

    if (assessment.state == DueState.unknown ||
        isUnknownOnHome(assessment.anchor.dateRung) ||
        isUnknownOnHome(assessment.anchor.odometerRung)) {
      unknownItems.add(item);
      continue;
    }

    due.add(
      DueCardModel(
        item: item,
        assessment: assessment,
        snoozedUntil: CivilDate.tryParseOrNull(item.snoozedUntil),
      ),
    );
  }

  // §9's ordering, from `lib/core/due/due_order.dart` — the same comparator
  // `reminders.list` sorts its first group with, because §9 says that screen is
  // sorted "exactly as Home sorts" and two comparators would be two orders.
  due.sort(
    (a, b) => compareAssessedItems(
      (a.item, a.assessment),
      (b.item, b.assessment),
    ),
  );
  _floatPinned(due, pinnedItemId);
  _demoteNeedsOdometer(due);

  return HomeStack(
    cards: List.unmodifiable(due.take(kHomeCardCap)),
    trackedCount: tracked,
    moreDueCount: due.length > kHomeCardCap ? due.length - kHomeCardCap : 0,
    unknown: unknownItems.isEmpty
        ? null
        : UnknownAnchorCard(
            items: List.unmodifiable(unknownItems),
            labels: List.unmodifiable(
              unknownItems
                  .take(kUnknownNamedCap)
                  .map((i) => i.label ?? '')
                  .toList(),
            ),
          ),
  );
}

/// §9 rule 5: "A deep-linked item is pinned to the primary slot for that one
/// appearance of Home."
void _floatPinned(List<DueCardModel> due, ServiceItemId? pinnedItemId) {
  if (pinnedItemId == null) return;
  final at = due.indexWhere((c) => c.item.id == pinnedItemId);
  if (at <= 0) return;
  due.insert(0, due.removeAt(at));
}

/// §9 rule 2: `needs_odometer` "never takes the primary slot while a `due` or
/// `overdue` time-driven item exists".
///
/// An accusation the app can support beats one it cannot: a time-driven due
/// date is calendar arithmetic, and a distance one the app has lost track of is
/// a question. The item stays in the stack and stays in date order behind the
/// swap — this moves ONE card, not the sort.
void _demoteNeedsOdometer(List<DueCardModel> due) {
  if (due.isEmpty || due.first.state != DueState.needsOdometer) return;
  final supported = due.indexWhere(
    (c) =>
        c.assessment.driver == DueDriver.time &&
        (c.state == DueState.due || c.state == DueState.overdue),
  );
  if (supported <= 0) return;
  due.insert(0, due.removeAt(supported));
}
