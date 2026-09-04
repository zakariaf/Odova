// "Take me to the top of the tab I am already on."
//
// SPEC.md §7: a second tap on the active tab pops that tab to its root AND
// scrolls the root to the top. The pop is `goBranch(initialLocation: true)` and
// belongs to the shell; the scroll belongs to whichever screen is at the root,
// and none of them exist yet. This is the seam between the two.
//
// A tick rather than a bool: a screen already at offset 0 that gets a second
// request has to see a second event, and a bool that is already true is not
// one.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A request to scroll one tab's root to the top.
typedef TabReselection = ({int index, int tick});

/// Broadcasts a re-tap on the active tab.
class TabReselected extends Notifier<TabReselection?> {
  @override
  TabReselection? build() => null;

  /// Announces that tab [index] was tapped while it was already active.
  void reselect(int index) =>
      state = (index: index, tick: (state?.tick ?? 0) + 1);
}

/// The last re-tap, or null before any.
///
/// A tab root watches this, checks the index is its own, and scrolls. EPIC-10
/// wires Home's `ScrollController` to it; until then nothing listens, and the
/// tick is asserted directly so the seam is proven before it has a consumer.
final tabReselectedProvider = NotifierProvider<TabReselected, TabReselection?>(
  TabReselected.new,
);
