// The reschedule port's one contract: it is not there until somebody wires it.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/notifications/schedule_rebuilder.dart';

void main() {
  test('the port throws, and says who is meant to override it', () {
    // Throwing rather than defaulting to a no-op. SPEC.md §13's rule 2 exists
    // because notification bodies are baked into the OS at schedule time, so
    // an unwired scheduler means a language change leaves German text arriving
    // on a Persian phone for four months — and a silent no-op is exactly the
    // failure nobody notices until a user reports it half a year later.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(scheduleRebuilderProvider),
      throwsA(
        predicate<Object>(
          (e) => e.toString().contains('scheduleRebuilderProvider'),
        ),
      ),
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
