// The third line of a garage row, as a decision.
//
// SPEC.md §8's status table. This picks WHICH sentence; the screen says it in
// the user's language. Splitting them that way is what lets the five cases be
// five assertions rather than five widget pumps — and what keeps the decision
// out of a `build()` where nobody can see it.
//
// "Colour is never the only signal" (§8), so every one of these has words. The
// dot is the second channel, never the first.
//
// In `lib/core/`, and the gate is what put it there. `check_status_encoding.sh`
// allows the DOMAIN to switch on a `DueState` and forbids presentation from
// doing it — "what a state IS belongs to the domain, what it LOOKS LIKE belongs
// to the theme" — and it draws that line at `lib/core/`, because a file there is
// provably Flutter-free and so provably cannot resolve a colour. This function
// picks a SENTENCE, never a colour, so it belongs on the domain side of that
// line and was sitting on the wrong one.
//
// Pure Dart, no Flutter import.
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';

/// Which sentence a garage row's third line says.
enum GarageStatus {
  /// `{item} overdue` — the worst item is past due.
  overdue,

  /// `{item} due in {n} days` — the worst item has a countdown.
  dueInDays,

  /// `All good` — everything tracked is fine.
  allGood,

  /// `Odometer needs updating` — too little history to project from.
  needsOdometer,

  /// `No reminders yet` — nothing is being tracked at all.
  noReminders,

  /// `Couldn't work out what's due` — the engine could not answer.
  unknown,

  /// `—` — a sold vehicle computes nothing.
  sold,
}

/// Which line [summary] deserves.
///
/// [summary] is nullable because the due engine can fail: §8 says the row still
/// renders, with a hollow dot and an admission. A null here is that failure
/// arriving as data rather than as an exception nobody caught.
GarageStatus garageStatusOf(DueSummary? summary, {bool sold = false}) {
  // Checked FIRST, before anything is computed. §8: "a sold vehicle computes no
  // reminders and its card shows —". Saying "All good" about a car the user no
  // longer owns is claiming an answer nobody asked for.
  if (sold) return GarageStatus.sold;
  if (summary == null) return GarageStatus.unknown;

  final worst = summary.worst;
  if (worst == null) return GarageStatus.noReminders;

  return switch (worst.state) {
    DueState.unknown => GarageStatus.unknown,
    DueState.needsOdometer => GarageStatus.needsOdometer,
    DueState.ok => GarageStatus.allGood,
    // A countdown needs a NUMBER. Without one, "due in ? days" is worse than
    // naming the item and leaving it at that — SPEC.md §2 forbids guessing in a
    // way that looks like fact, and a missing day count is exactly that gap.
    DueState.due || DueState.dueSoon || DueState.overdue =>
      worst.remainingDays == null
          ? GarageStatus.overdue
          : GarageStatus.dueInDays,
  };
}
