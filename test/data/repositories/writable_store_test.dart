// After a failed migration, reads work and writes do not.
//
// SPEC.md §6.3.3 and §14 (*Migration fails on launch*). A crash loop is the
// worst available outcome: the user cannot open the app to export their data,
// and the only remedy left is uninstalling, which deletes it. So the app comes
// up read-only, and this is the seam that makes that true rather than a
// promise in a banner.
@TestOn('vm')
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/degraded_mode.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/guard.dart';
import 'package:odova/data/repositories/writable_store.dart';

void main() {
  test('a healthy store refuses nothing', () {
    expect(writeRefusalFor(const Healthy()), isNull);
  });

  test('a failed migration refuses every write, naming both versions', () {
    // The banner says "your data is safe and it is still on version 1"; both
    // numbers come from here, and a failure carrying only a code would leave
    // the user with "something is wrong" and nothing to act on.
    final refusal =
        writeRefusalFor(
              const MigrationFailed(atVersion: 1, expectedVersion: 2),
            )!
            as StoreReadOnly;

    expect(refusal.code, 'store_read_only');
    expect(refusal.atVersion, 1);
    expect(refusal.expectedVersion, 2);
  });

  test('the refusal happens BEFORE the body runs', () async {
    // A write that reached the database and was then rolled back is a write
    // that touched a file the app has already decided it does not understand.
    var bodyRan = false;

    final result = await guardPersist<int>(() async {
      bodyRan = true;
      return const Ok(1);
    }, refuseWith: const StoreReadOnly(atVersion: 1, expectedVersion: 2));

    expect(result, isA<Err<int, PersistFailure>>());
    expect(bodyRan, isFalse, reason: 'the body must not have been reached');
  });

  test('with no refusal the body runs normally', () async {
    final result = await guardPersist<int>(() async => const Ok(7));
    expect(result, const Ok<int, PersistFailure>(7));
  });

  test('the provider follows the degraded mode', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // One fact, one provider. `storeIsWritableProvider` computed `mode is
    // Healthy` beside this computing `writeRefusalFor(mode) == null` — two
    // derivations of one boolean, in two files, and the typed one is the only
    // one that can carry the versions the banner needs. A caller wanting the
    // bool reads `writeRefusalProvider != null`.
    expect(container.read(writeRefusalProvider), isNull);

    container
        .read(degradedModeProvider.notifier)
        .migrationFailed(atVersion: 1, expectedVersion: 2);

    expect(container.read(writeRefusalProvider), isA<StoreReadOnly>());
  });

  // Removed: a test that looped both modes asserting `returnsNormally`.
  // Exhaustiveness over a sealed type is a COMPILE-time property — the fact
  // that `writeRefusalFor` compiles at all is the proof, and adding a third
  // mode breaks the build rather than the test. Both modes are already
  // asserted above with their actual answers, so the loop could not fail for
  // any reason the other tests would not catch first.
}
