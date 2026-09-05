// The providers, and the two properties that are easy to get wrong.
//
// A scoped family that is not `autoDispose` leaves a live query on the
// database for every vehicle anybody ever opened, for the rest of the launch.
// And a repository provider that builds its own database instead of watching
// `appDatabaseProvider` would give the app two connections to one file.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/repositories/providers.dart';

import '../../support/source_tree.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });
  tearDown(() {
    container.dispose();
    return db.close();
  });

  test('every repository reads the one database', () async {
    // Two connections to one file is how a WAL ends up with a reader that
    // cannot see a writer's committed row, and the symptom is a screen that
    // does not update until relaunch.
    final vehicleId = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD')!;
    await container
        .read(vehicleRepositoryProvider)
        .save(
          Vehicle(
            id: vehicleId,
            name: 'The Golf',
            vehicleType: VehicleType.car,
            fuelKindDefault: FuelKind.diesel,
            status: VehicleStatus.active,
            createdAtUtcMs: 1000,
            updatedAtUtcMs: 1000,
          ),
        );

    // Read back through a DIFFERENT repository's database handle.
    final rows = await container
        .read(appDatabaseProvider)
        .customSelect('SELECT COUNT(*) AS n FROM vehicles;')
        .getSingle();
    expect(rows.read<int>('n'), 1);
  });

  test('the vehicles stream emits through the provider', () async {
    // `container.read(provider.future)` hangs here: nothing is listening, so
    // Riverpod keeps the element in its loading state and tearDown disposes it
    // before drift's first emission arrives. A subscription is what starts the
    // query, which is also how the app uses it.
    final states = <AsyncValue<List<Vehicle>>>[];
    final subscription = container.listen(
      vehiclesProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await pumpEventQueue();
    expect(states.first, isA<AsyncLoading<List<Vehicle>>>());
    expect(states.last.value, isEmpty);

    await container
        .read(vehicleRepositoryProvider)
        .save(
          Vehicle(
            id: VehicleId.tryParse('veh_01JV7B5X4G2K9M6P0S3D8FNRTC')!,
            name: 'Van',
            vehicleType: VehicleType.van,
            fuelKindDefault: FuelKind.diesel,
            status: VehicleStatus.active,
            createdAtUtcMs: 1000,
            updatedAtUtcMs: 1000,
          ),
        );
    await pumpEventQueue();

    expect(states.last.value, hasLength(1));
  });

  /// Every `final … = StreamProvider…;` declaration in providers.dart, by name.
  ///
  /// Split on the declaration keyword rather than matched with one regex: the
  /// type arguments nest (`StreamProviderFamily<List<ServiceItem>, VehicleId>`)
  /// so a `[^>]+` stops at the inner `>`, and `dart format` wraps a long
  /// declaration so the name lands on the next line. The first version of this
  /// test did both and matched nothing, which passed as "no families to check".
  Map<String, String> streamProviderDeclarations() {
    final source = sourceWithoutLineComments(
      dartFilesUnder(
        'lib/data/repositories',
      ).firstWhere((f) => f.path.endsWith('providers.dart')),
    );

    final declarations = <String, String>{};
    for (final chunk in source.split(RegExp('^final ', multiLine: true))) {
      final name = RegExp(r'(\w+Provider)\s*=').firstMatch(chunk)?.group(1);
      if (name == null) continue;
      final body = chunk.substring(chunk.indexOf('='));
      if (!body.contains('StreamProvider')) continue;
      declarations[name] = body;
    }
    return declarations;
  }

  test('every vehicle-scoped family is autoDispose', () {
    // Read from the SOURCE rather than from the runtime, because Riverpod 3
    // folds autoDispose into the provider type and there is no flag to ask
    // for. A family that is not autoDispose keeps its query alive for the
    // whole launch, once per vehicle anybody opened.
    final declarations = streamProviderDeclarations();
    final families = {
      for (final entry in declarations.entries)
        if (entry.value.contains('.family')) entry.key: entry.value,
    };

    // EIGHT: seven per-vehicle lists plus `latestFillUpProvider`, which is a
    // `LIMIT 1` over the same table as `fillUpsProvider` because Home draws one
    // fill-up and reading the whole history to find it was both the wrong row
    // and an unbounded read on the first frame.
    expect(families, hasLength(8), reason: 'one per vehicle-scoped stream');
    for (final MapEntry(key: name, value: body) in families.entries) {
      expect(
        body,
        contains('autoDispose'),
        reason: '$name is not autoDispose',
      );
    }
  });

  test('the garage list and the settings are NOT autoDispose', () {
    // Deliberate, and the opposite decision to the families above. Both are
    // read by the app shell for the whole session, so disposing them would
    // tear the query down and rebuild it on every tab change.
    final declarations = streamProviderDeclarations();

    for (final name in ['vehiclesProvider', 'settingsProvider']) {
      expect(declarations, contains(name));
      expect(declarations[name], isNot(contains('autoDispose')), reason: name);
    }
  });
}
