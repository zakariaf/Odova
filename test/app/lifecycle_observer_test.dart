// The one lifecycle observer.
//
// Android can kill a backgrounded process without another callback, so
// `inactive`/`paused` is the last moment anything held in memory can be
// written. Registering twice writes twice; failing to unregister writes after
// the app is gone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/app.dart';
import 'package:odova/app/providers.dart';

void main() {
  testWidgets('the flush runs once per background transition, and not at all '
      'once the app is disposed', (tester) async {
    var flushes = 0;

    await tester.pumpWidget(
      OdovaRoot(
        overrides: [
          durableFlushProvider.overrideWithValue(() async => flushes++),
        ],
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(flushes, 1, reason: 'registered exactly once');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(flushes, 2);

    // Replacing the tree disposes the scope; a still-registered observer would
    // keep calling a flush whose provider container is gone.
    await tester.pumpWidget(const SizedBox.shrink());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(flushes, 2, reason: 'the observer outlived the widget that owns it');
  });
}
