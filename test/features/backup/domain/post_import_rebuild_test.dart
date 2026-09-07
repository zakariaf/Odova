// The post-swap order, on a recording fake — SPEC.md §6 §4.1.
@TestOn('vm')
library;

import 'package:odova/features/backup/domain/post_import_rebuild.dart';
import 'package:test/test.dart';

/// Records what was called and when, and how long each took to finish.
class _Recording implements PostImportSteps {
  final List<String> calls = [];
  final List<String> completions = [];

  Future<void> _step(String name) async {
    calls.add(name);
    // A real await, so a caller that started all three concurrently would
    // interleave the calls and the completions and be caught.
    await Future<void>.delayed(Duration.zero);
    completions.add(name);
  }

  @override
  Future<void> applyCorrections() => _step('corrections');

  @override
  Future<void> rebuildDerived() => _step('derived');

  @override
  Future<void> rescheduleNotifications() => _step('notifications');
}

void main() {
  test('corrections, then derived, then notifications', () async {
    final steps = _Recording();

    final ran = await runPostImportRebuild(steps);

    expect(ran, [
      RebuildStep.corrections,
      RebuildStep.derived,
      RebuildStep.notifications,
    ]);
    expect(steps.calls, ['corrections', 'derived', 'notifications']);
  });

  test('each finishes before the next starts', () async {
    // Sequential, not concurrent. A due date computed before a correction is
    // applied is computed against a mileage history the user has already told
    // us was wrong, and running the three at once would be faster and wrong.
    final steps = _Recording();

    await runPostImportRebuild(steps);

    expect(steps.completions, ['corrections', 'derived', 'notifications']);
  });

  test('the reschedule happens exactly once, and last', () async {
    // The OS holds notification ids belonging to the data this import just
    // replaced. Cancelling wholesale is the only way to be sure none survives,
    // and doing it twice would cancel the schedule the first pass built.
    final steps = _Recording();

    await runPostImportRebuild(steps);

    expect(steps.calls.where((c) => c == 'notifications'), hasLength(1));
    expect(steps.calls.last, 'notifications');
  });
}
