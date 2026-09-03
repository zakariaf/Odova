import 'dart:async';

import 'package:flutter/widgets.dart';

/// Flushes durable state when the OS is about to stop giving us frames.
///
/// Android can kill a backgrounded process without another callback, and iOS
/// suspends one, so the walk down out of `resumed` is the last moment anything
/// held only in memory can be written.
///
/// **Once per episode.** Flutter delivers `resumed → inactive → hidden →
/// paused` for one trip to the home screen, so flushing on each state writes
/// three times for one backgrounding. A latch makes it once, and `resumed` is
/// what re-arms it. The earliest state still wins — on iOS, `inactive` arrives
/// for a notification banner or an incoming call and the app can be killed from
/// there, so the write happens then rather than waiting for a `paused` that may
/// not come.
class LifecycleObserver extends WidgetsBindingObserver {
  /// Creates an observer that calls [flush] once per background episode.
  LifecycleObserver(this.flush);

  /// Persists whatever is only in memory. Must not throw.
  final Future<void> Function() flush;

  bool _flushedThisEpisode = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // A new episode. Nothing to write: we are gaining frames, not losing
        // them.
        _flushedThisEpisode = false;

      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_flushedThisEpisode) return;
        _flushedThisEpisode = true;
        // Not awaited: the framework gives us no way to hold the transition,
        // and an await here would only delay a frame we are not getting. The
        // catch is what stops a failed flush becoming an unhandled rejection
        // on a path nobody is watching.
        unawaited(flush().catchError((Object _) {}));
    }
  }
}
