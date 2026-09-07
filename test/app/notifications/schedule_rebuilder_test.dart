// The reschedule port's one contract: it is not there until somebody wires it.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/notifications/schedule_rebuilder.dart';

void main() {
  test('the port resolves without an override', () {
    // It threw until overridden, and `bootstrap()` never overrode it: every
    // text-affecting settings write committed to the database and then threw
    // out of an `unawaited()` tap handler. Every test passed, because every
    // test supplied its own fake.
    //
    // A port that throws is only safe when something in PRODUCTION satisfies
    // it, so the default is the honest implementation of "EPIC-16 has not
    // landed, therefore nothing is scheduled".
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(scheduleRebuilderProvider),
      isA<NoScheduledNotifications>(),
    );
  });

  test('an override satisfies it', () {
    final container = ProviderContainer(
      overrides: [scheduleRebuilderProvider.overrideWithValue(_Noop())],
    );
    addTearDown(container.dispose);

    expect(container.read(scheduleRebuilderProvider), isA<ScheduleRebuilder>());
  });
}

class _Noop implements ScheduleRebuilder {
  @override
  Future<void> rebuildAll() async {}
}
