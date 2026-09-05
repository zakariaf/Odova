// The reminders provider, and the difference between "not yet" and "none".
//
// A plain `test` with a `ProviderContainer`, not `testWidgets`: these are the
// two null cases, and a widget harness would only make them slower to state.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/data/repositories/due_snapshot_provider.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/reminders/application/reminders_list_notifier.dart';

import '../../home/home_fixture.dart';

ProviderContainer _container(List<Override> overrides) {
  final container = ProviderContainer(
    retry: noProviderRetry,
    overrides: overrides,
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('null items is null groups, not empty groups', () {
    // "The catalogue has not arrived" and "there is no catalogue" are different
    // facts, and only the second draws `No reminders yet.` A provider that
    // collapsed them would flash the empty state on every cold open.
    final container = _container([
      serviceItemsProvider(golfId).overrideWith((ref) => const Stream.empty()),
      vehicleDueSnapshotProvider(golfId).overrideWithValue(null),
    ]);

    expect(container.read(remindersListProvider(golfId)), isNull);
  });

  test(
    'items with no snapshot still group, with no assessment attached',
    () async {
      // The catalogue arrives before the engine does, and §9 still lists every
      // row — the STATUS is what waits, not the list.
      final oil = homeItem('Oil and filter');
      final container = _container([
        serviceItemsProvider(golfId).overrideWith((ref) => Stream.value([oil])),
        vehicleDueSnapshotProvider(golfId).overrideWithValue(null),
      ]);

      final subscription = container.listen(
        serviceItemsProvider(golfId),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await pumpEventQueue();

      final groups = container.read(remindersListProvider(golfId));
      expect(groups, isNotNull);
      expect(groups!.active.single.item.label, 'Oil and filter');
      expect(groups.active.single.assessment, isNull);
    },
  );
}
