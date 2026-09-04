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
/// A record rather than five parameters, so no caller can pass a total that
/// disagrees with its own breakdown — the total is computed by
/// [DeleteCountsTotal.total] and cannot be supplied.
typedef DeleteCounts = ({
  int fillUps,
  int services,
  int costs,
  int trips,
  int reminders,
});

/// Everything that would be deleted.
extension DeleteCountsTotal on DeleteCounts {
  /// The number in the title.
  int get total => fillUps + services + costs + trips + reminders;
}
