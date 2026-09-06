// §11's Undo, and how long it lives.
//
// "Undo re-applies the pre-write snapshot and re-runs the same pipeline. It is
// live until the snackbar dismisses — 6 seconds, or the next navigation."
//
// Two clauses. A `SnackBar`'s own duration handles the first one for free,
// which is exactly why the second gets dropped: everything looks correct until
// someone taps a row, leaves, and finds an Undo still armed for a write they
// have stopped thinking about — offered from a screen that no longer shows
// what it would revert.
//
// So the window is a thing rather than a side effect of a widget. It is also
// the reason this is not simply a `VoidCallback` held in state: an undo has a
// LIFETIME, and a callback with no lifetime is one that fires late.
import 'dart:async';

/// One live Undo, or none.
///
/// Never two. §11 allows a single Undo, and two in memory is worse than two on
/// screen: the older one silently reverts a write from two edits back.
class UndoWindow {
  Timer? _timer;
  Future<void> Function()? _undo;

  /// Whether an Undo is armed and would do something.
  bool get isLive => _undo != null;

  /// Arms [undo] for [window], replacing whatever was armed before it.
  ///
  /// [window] comes from `CalmMotion.undoWindow` — §11's six seconds, or
  /// §10's ten for a destructive one — and is passed in rather than read here
  /// so this stays free of a `BuildContext`.
  ///
  /// The replacement gets a FULL window. Inheriting the remainder of the
  /// previous one would give the second of two quick edits a one-second Undo,
  /// which is an Undo the user cannot reach.
  void offer({
    required Duration window,
    required Future<void> Function() undo,
  }) {
    _timer?.cancel();
    _undo = undo;
    _timer = Timer(window, _expire);
  }

  /// Runs the armed Undo, once.
  ///
  /// A second call does nothing. A snackbar action is a tap target, and a tap
  /// target on a phone in the rain gets hit twice — re-applying a pre-write
  /// snapshot on top of itself is a second write nobody asked for.
  Future<void> invoke() async {
    final undo = _undo;
    if (undo == null) return;
    _expire();
    await undo();
  }

  /// Drops the armed Undo without running it — §11's "or the next
  /// navigation".
  void cancel() => _expire();

  /// Drops it and stops the timer.
  void dispose() => _expire();

  void _expire() {
    _timer?.cancel();
    _timer = null;
    _undo = null;
  }
}
