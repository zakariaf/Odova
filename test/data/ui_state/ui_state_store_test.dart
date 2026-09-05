// Local UI state, and the one property that matters about it.
//
// SPEC.md §9: "`home.staleness_dismissed_until.<vehicle_id>`,
// `home.digest_shown_at`, `home.first_run_hint_dismissed` — lives in a
// key-value store that is **not** in the backup file. A restore should bring
// back the car's history, not the fact that someone dismissed a banner in
// 2024."
//
// So the store is a FILE beside the database rather than a table inside it.
// That makes "not in the backup" structural: every backup and every migration
// safety copy is produced by reading the database, and this is not in it. A
// table excluded by a reader's list is one edit away from being included.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/data/db/schema_readers/schema_reader.dart';
import 'package:odova/data/ui_state/ui_state_store.dart';

Directory _scratch() {
  final dir = Directory.systemTemp.createTempSync('odova_ui_state');
  addTearDown(() => dir.deleteSync(recursive: true));
  return dir;
}

void main() {
  test('a value written is a value read back, in a new store', () async {
    final dir = _scratch();

    final first = await UiStateStore.open(dir);
    await first.write('home.digest_shown_at', '2026-09-05');

    final second = await UiStateStore.open(dir);
    expect(second.read('home.digest_shown_at'), '2026-09-05');
  });

  test('an absent key reads null rather than an empty string', () async {
    // The difference is load-bearing: "never dismissed" and "dismissed until
    // the empty string" are different facts, and only the first may show the
    // strip.
    final store = await UiStateStore.open(_scratch());
    expect(store.read('home.first_run_hint_dismissed'), isNull);
  });

  test('a missing file is an empty store, not a crash', () async {
    // The first launch on a new phone, every time.
    final store = await UiStateStore.open(_scratch());
    expect(store.snapshot, isEmpty);
  });

  test('a corrupt file is an empty store, not a crash', () async {
    // This file is never the user's history. Losing it costs a dismissed
    // banner; refusing to launch over it costs the app. SPEC.md §2's
    // survival rule is about the DATABASE, and this is deliberately not in it.
    final dir = _scratch();
    File('${dir.path}/$kUiStateFileName').writeAsStringSync('{not json');

    final store = await UiStateStore.open(dir);
    expect(store.snapshot, isEmpty);

    // And it recovers: the next write replaces the rubbish.
    await store.write('home.digest_shown_at', '2026-09-05');
    expect(
      (await UiStateStore.open(dir)).read('home.digest_shown_at'),
      '2026-09-05',
    );
  });

  test('a file whose JSON is not a string map is an empty store', () async {
    // A hand-edited file, or a future version's shape. Same rule.
    final dir = _scratch();
    File(
      '${dir.path}/$kUiStateFileName',
    ).writeAsStringSync(jsonEncode([1, 2, 3]));

    expect((await UiStateStore.open(dir)).snapshot, isEmpty);
  });

  test('removing a key removes it from the file', () async {
    final dir = _scratch();
    final store = await UiStateStore.open(dir);
    await store.write('home.digest_shown_at', '2026-09-05');
    await store.remove('home.digest_shown_at');

    expect((await UiStateStore.open(dir)).read('home.digest_shown_at'), isNull);
  });

  test('no UI-state key is a table any schema reader copies', () {
    // The backup and the migration safety copy are both produced by reading
    // the DATABASE, table by table from a declared list. This asserts the list
    // has nothing UI-shaped in it — so §9's "not in the backup file" holds by
    // construction rather than by somebody remembering.
    for (final reader in [const SchemaReaderV1()]) {
      for (final table in reader.tables) {
        expect(
          table,
          isNot(anyOf(contains('ui_'), contains('home'), contains('dismiss'))),
          reason: '${reader.runtimeType} copies $table',
        );
      }
    }
  });

  test('bootstrap injects the FILE store, not the in-memory default', () {
    // Over the source, because `bootstrap()` opens a real database and asks
    // the platform for a directory — neither of which a unit test has. The
    // default is in-memory so that every widget harness works without an
    // override; the cost of that convenience is that nothing would notice
    // production keeping its dismissals in RAM, so this is what notices.
    final source = File('lib/app/bootstrap.dart').readAsStringSync();
    expect(source, contains('uiStateProviderStore.overrideWithValue'));
    expect(source, contains('UiStateStore.open'));
    expect(
      source,
      contains('getApplicationSupportDirectory'),
      reason: 'Documents is user-visible and iCloud-backed on iOS',
    );
  });

  test('the keys are the three SPEC.md §9 names, spelled its way', () {
    // Spelled out here because they are a WIRE format: a file written by
    // today's build is read by tomorrow's, and a renamed key silently
    // un-dismisses every banner on the next update.
    expect(kUiKeyDigestShownAt, 'home.digest_shown_at');
    expect(kUiKeyFirstRunHintDismissed, 'home.first_run_hint_dismissed');
    expect(
      uiKeyStalenessDismissedUntil('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA'),
      'home.staleness_dismissed_until.veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA',
    );
  });
}
