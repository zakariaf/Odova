import 'dart:async';

import 'package:flutter/widgets.dart';

/// Flushes durable state when the OS is about to stop giving us frames.
///
/// Android can kill a backgrounded process without another callback, and iOS
/// suspends one. `inactive` and `paused` are the last moments anything can be
/// written, so anything held only in memory is written there — not on a timer,
/// and not on the way back.
class LifecycleObserver extends WidgetsBindingObserver {
  /// Creates an observer that calls [flush] on `inactive` and `paused`.
  LifecycleObserver(this.flush);

  /// Persists whatever is only in memory. Must not throw.
  final Future<void> Function() flush;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // Not awaited: the framework gives us no way to hold the transition,
        // and an await here would only delay a frame we are not getting. The
        // catch is what stops a failed flush becoming an unhandled rejection
        // on a path nobody is watching.
        unawaited(flush().catchError((Object _) {}));
      case AppLifecycleState.detached:
      case AppLifecycleState.resumed:
      case AppLifecycleState.hidden:
        break;
    }
  }
}
