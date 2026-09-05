// What deleting a vehicle would take with it.
//
// In `lib/core/` and in neither of the two places that wanted to own it. The
// repository counts them and `dialog.confirmDelete` states them out loud, and
// each declared its own identical typedef — which compiled only because Dart
// records are structural.
//
// It cannot live in the data layer: `dialogs_write_nothing_test.dart` asserts
// that `confirm_delete_dialog.dart` "imports nothing outside the UI layer",
// which is how "the dialog cannot delete anything" is a property of the code
// rather than a promise in a comment. And it cannot live with the dialog:
// `entry_counts_provider.dart` was importing `lib/ui/dialogs/` into a Riverpod
// provider purely to name a return type.
//
// Pure Dart, no Flutter import.

/// The five per-type counts SPEC.md §8's dialog names.
///
/// A record rather than five parameters, so no caller can pass a headline that
/// disagrees with its own breakdown — the count is computed by
/// [DeleteCountsEntries.entries] and cannot be supplied.
typedef DeleteCounts = ({
  int fillUps,
  int services,
  int costs,
  int trips,
  int reminders,
});

/// Everything that would be deleted.
extension DeleteCountsEntries on DeleteCounts {
  /// How many ENTRIES the user would lose — the number in the dialog's title.
  ///
  /// Four of the five, and reminders are the one left out, because an entry is
  /// something the user entered and a reminder is a setting the app put there.
  /// SPEC.md §4.8.3 seeds a set on every vehicle at creation, so a count that
  /// included them would never be zero and §8's "Zero entries: one-tap Delete"
  /// would be a rule with no reachable case — a car added by mistake would
  /// demand its own name typed back twenty seconds later, to protect eight
  /// reminders the next car gets for free.
  ///
  /// A decision about SPEC.md §8 rather than a reading of it: the section asks
  /// for both rules and seeding puts them in tension. Recorded as F-9.26.
  ///
  /// Reminders stay in [DeleteCounts] and in the dialog's body, because they
  /// are still destroyed and the body says what dies.
  int get entries => fillUps + services + costs + trips;
}
