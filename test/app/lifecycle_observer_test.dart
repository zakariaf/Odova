// The one lifecycle observer.
//
// Android can kill a backgrounded process without another callback, so the
// walk down to `paused` is the last moment anything held in memory can be
// written. Registering twice writes twice; failing to unregister writes after
// the app is gone; and flushing on every state in the sequence writes three
// times for one backgrounding.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/app.dart';
import 'package:odova/app/providers.dart';

void main() {
  /// Pumps the root with a counting flush and returns a reader for the count.
  Future<int Function()> pumpCountingRoot(WidgetTester tester) async {
    var flushes = 0;
    await tester.pumpWidget(
      OdovaRoot(
        overrides: [
          durableFlushProvider.overrideWithValue(() async => flushes++),
        ],
      ),
    );
    return () => flushes;
  }

  Future<void> send(WidgetTester tester, List<AppLifecycleState> states) async {
    states.forEach(tester.binding.handleAppLifecycleStateChanged);
    await tester.pump();
  }

  testWidgets('one backgrounding flushes once, not once per state', (
    tester,
  ) async {
    final flushes = await pumpCountingRoot(tester);

    // The real sequence Flutter delivers. Flushing on each of inactive, hidden
    // and paused would write three times for one trip to the home screen —
    // invisible today because durableFlushProvider is a no-op, and a
    // duplicated database write the moment EPIC-05 attaches a real one.
    await send(tester, [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]);

    expect(flushes(), 1);
  });

  testWidgets('a second backgrounding flushes again', (tester) async {
    final flushes = await pumpCountingRoot(tester);

    await send(tester, [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]);
    await send(tester, [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);
    await send(tester, [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]);

    expect(flushes(), 2, reason: 'resumed must re-arm the latch');
  });

  testWidgets('an iOS banner interruption flushes at most once', (
    tester,
  ) async {
    final flushes = await pumpCountingRoot(tester);

    // iOS sends inactive -> resumed for a notification banner, a Control Centre
    // pull-down or an incoming call, and it can happen many times a minute. The
    // app may still be killed from that state, so the first one writes; the
    // point is that ten of them do not write ten times.
    for (var i = 0; i < 5; i++) {
      await send(tester, [
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]);
    }

    expect(flushes(), 5, reason: 'each interruption is its own episode');
  });

  testWidgets('registered exactly once, and removed on dispose', (
    tester,
  ) async {
    final flushes = await pumpCountingRoot(tester);

    await send(tester, [AppLifecycleState.paused]);
    expect(flushes(), 1, reason: 'registered exactly once');

    // Replacing the tree disposes the scope; a still-registered observer would
    // keep calling a flush whose provider container is gone.
    await tester.pumpWidget(const SizedBox.shrink());
    await send(tester, [AppLifecycleState.paused]);
    expect(
      flushes(),
      1,
      reason: 'the observer outlived the widget that owns it',
    );
  });
}
