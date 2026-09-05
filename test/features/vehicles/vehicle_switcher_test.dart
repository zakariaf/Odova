// `vehicle.switcher` — the sheet that does not exist for most users.
//
// SPEC.md §8: "Change the active vehicle. **Does not exist below two
// vehicles** — with one car, Home's title is plain, non-tappable text with no
// chevron and no '1 of 1'. Opened daily by a two-car household, never by anyone
// else."
//
// It writes exactly one field. Everything else it does — dismissing, resetting
// four tab stacks, resetting the history filters and the Costs range — follows
// from `setActiveVehicle`, which is the one sanctioned way to switch and the
// only thing this sheet calls.
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/tab_stack_reset.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/data/repositories/settings_repository.dart';
import 'package:odova/features/vehicles/due_snapshot_provider.dart';
import 'package:odova/features/vehicles/presentation/vehicle_switcher_sheet.dart';
import 'package:odova/ui/calm/calm_disclosure.dart';
import 'package:odova/ui/calm/calm_list_row.dart';

import '../../data/support/rows.dart';
import '../../support/pump_app.dart';

final VehicleId _golf = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA')!;
final VehicleId _transit = VehicleId.tryParse(
  'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVB',
)!;
final VehicleId _yamaha = VehicleId.tryParse(
  'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVC',
)!;

Vehicle _vehicle(
  VehicleId id,
  String name, {
  VehicleStatus status = VehicleStatus.active,
  int sortOrder = 0,
  bool business = false,
}) => Vehicle(
  id: id,
  name: name,
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: status,
  isBusiness: business,
  sortOrder: sortOrder,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// A settings repository whose one write always refuses.
///
/// The switcher's whole job is to have switched, so "the write failed" is a
/// state it has to be able to draw. Subclassed rather than faked wholesale:
/// everything else on the real repository still behaves, so the test is about
/// the one call that fails.
class _RefusingSettings extends SettingsRepository {
  // `super.db` is what one lint wants and another refuses: the field it
  // forwards to is private, so a super parameter cannot share its name from
  // another library.
  // ignore: use_super_parameters
  const _RefusingSettings(AppDatabase db) : super(db);

  @override
  Future<Result<void, PersistFailure>> setActiveVehicle(
    VehicleId? id, {
    required int updatedAtUtcMs,
  }) async => const Err(WriteFailed('disk full'));
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  List<Vehicle>? vehicles,
  VehicleId? active,
  bool writesFail = false,
}) async {
  // A REAL in-memory database for the WRITE. Tapping a row goes through
  // `setActiveVehicle`, which asks the repository to update one column — and a
  // sheet whose write throws never reaches its own `pop`, so "did it dismiss"
  // and "did it write" are one question here.
  //
  // The READ still comes from the override: `settingsProvider` is a drift
  // stream and drift streams do not deliver under `testWidgets`.
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  await insertSettings(db, activeVehicleId: (active ?? _golf).toString());
  final garage =
      vehicles ??
      [
        _vehicle(_golf, 'The Golf'),
        _vehicle(_transit, 'Transit', sortOrder: 1, business: true),
      ];
  late ProviderContainer container;
  await pumpApp(
    tester,
    // Opened as a ROUTE, not pumped as the root. Half of what this sheet does
    // is DISMISS, and a sheet that is the whole tree has nothing to pop.
    Builder(
      builder: (context) {
        container = ProviderScope.containerOf(context);
        // A SCAFFOLD under it, because `ScaffoldMessenger.showSnackBar` has
        // nothing to present to without one — so a bare `Center` here silently
        // swallows every snackbar the sheet tries to show, and the failure
        // path would look tested while asserting nothing.
        return Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showVehicleSwitcher(context),
              child: const Text('open'),
            ),
          ),
        );
      },
    ),
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(
        Clock.fixed(DateTime.utc(2026, 11, 20, 9, 41)),
      ),
      vehiclesProvider.overrideWith((ref) => Stream.value(garage)),
      settingsProvider.overrideWith(
        (ref) => Stream.value(
          AppSettings(
            schemaVersion: 1,
            currencyDefault: Currency.tryParse('EUR')!,
            activeVehicleId: active ?? _golf,
            createdAtUtcMs: 1000,
            updatedAtUtcMs: 1000,
          ),
        ),
      ),
      for (final v in garage)
        vehicleDueSnapshotProvider(v.id).overrideWithValue(null),
      if (writesFail)
        settingsRepositoryProvider.overrideWith((ref) => _RefusingSettings(db)),
    ],
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return container;
}

CalmListRow _row(WidgetTester tester, String name) => tester
    .widgetList<CalmListRow>(find.byType(CalmListRow))
    .firstWhere((r) => r.title == name);

void main() {
  testWidgets('the head counts the vehicles it is offering', (tester) async {
    // `.sheet__sub` in the artboard. It is the only number on the sheet and it
    // is what tells a user with four cars that the list scrolls.
    await _pump(tester);
    expect(find.text('Switch vehicle'), findsOneWidget);
    expect(find.text('2 vehicles'), findsOneWidget);
  });

  testWidgets('the rows are in sort_order, not the order they arrived', (
    tester,
  ) async {
    await _pump(
      tester,
      vehicles: [
        _vehicle(_transit, 'Transit', sortOrder: 2),
        _vehicle(_golf, 'The Golf'),
        _vehicle(_yamaha, 'CB500X', sortOrder: 1),
      ],
    );
    final titles = tester
        .widgetList<CalmListRow>(find.byType(CalmListRow))
        .map((r) => r.title)
        .toList();
    expect(titles.take(3), ['The Golf', 'CB500X', 'Transit']);
  });

  testWidgets('the active vehicle is marked, and only by the mark', (
    tester,
  ) async {
    // SPEC.md §8: "the active one marked with a checkmark on the end edge and
    // nothing else." Not a bolder name, not a tint the other rows lack — a
    // second signal would make the list read as two kinds of row.
    await _pump(tester, active: _transit);
    expect(_row(tester, 'Transit').selected, isTrue);
    expect(_row(tester, 'The Golf').selected, isFalse);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('sold and archived sit behind a collapsed disclosure', (
    tester,
  ) async {
    // "Reachable, out of the way" — §8. The rows are not BUILT until it opens,
    // which is what keeps a sold car out of a screen-reader's traversal of the
    // live list.
    await _pump(
      tester,
      vehicles: [
        _vehicle(_golf, 'The Golf'),
        _vehicle(_transit, 'Transit', sortOrder: 1),
        _vehicle(
          _yamaha,
          'Yamaha MT-07',
          status: VehicleStatus.sold,
          sortOrder: 2,
        ),
      ],
    );
    expect(find.byType(CalmDisclosure), findsOneWidget);
    expect(find.text('Yamaha MT-07'), findsNothing);
    expect(find.text('2 vehicles'), findsOneWidget, reason: 'LIVE ones');

    await tester.tap(find.text('Sold and archived'));
    await tester.pumpAndSettle();
    expect(find.text('Yamaha MT-07'), findsOneWidget);
  });

  testWidgets('a garage with nothing sold has no disclosure at all', (
    tester,
  ) async {
    // An empty collapsed group is a control that opens on nothing.
    await _pump(tester);
    expect(find.byType(CalmDisclosure), findsNothing);
  });

  testWidgets('tapping a vehicle writes ONE field and dismisses', (
    tester,
  ) async {
    // §8's Data out: "`Settings.active_vehicle_id` only." Everything else the
    // tap causes — the four tab stacks, the history filters, the Costs range —
    // is `setActiveVehicle`'s doing, and this sheet calling anything else would
    // be a second answer to what switching means.
    final container = await _pump(tester);
    expect(container.read(tabStackResetProvider), isNull);

    await tester.tap(find.text('Transit'));
    await tester.pumpAndSettle();

    expect(find.byType(VehicleSwitcherSheet), findsNothing);
    // The tab-stack reset is `setActiveVehicle`'s second effect and the proof
    // the sheet went through it rather than writing the column itself.
    expect(container.read(tabStackResetProvider), isNotNull);
  });

  testWidgets('a refused write keeps the sheet open and says so', (
    tester,
  ) async {
    // The sheet's whole purpose is to have switched. It used to discard
    // `setActiveVehicle`'s `Result` and pop regardless, so a write that never
    // happened looked exactly like one that did — the user watched the tick
    // move, the sheet closed, and the app was still on the old car.
    final container = await _pump(tester, writesFail: true);

    await tester.tap(find.text('Transit'));
    await tester.pumpAndSettle();

    expect(find.byType(VehicleSwitcherSheet), findsOneWidget);
    expect(
      container.read(tabStackResetProvider),
      isNull,
      reason: 'nothing was switched, so nothing was reset',
    );
    expect(find.byType(SnackBar), findsOneWidget, reason: 'and it says so');
  });

  testWidgets('tapping the ACTIVE vehicle changes nothing and dismisses', (
    tester,
  ) async {
    // A write that sets the field to what it already holds still resets four
    // tab stacks, which throws away the user's place for no reason.
    final container = await _pump(tester);
    await tester.tap(find.text('The Golf'));
    await tester.pumpAndSettle();
    expect(container.read(tabStackResetProvider), isNull);
  });

  testWidgets('the two footer actions are always there, in order', (
    tester,
  ) async {
    // §8: "Two footer actions, always visible", Add before Manage.
    await _pump(tester);
    final titles = tester
        .widgetList<CalmListRow>(find.byType(CalmListRow))
        .map((r) => r.title)
        .toList();
    expect(titles.sublist(titles.length - 2), [
      'Add vehicle',
      'Manage vehicles',
    ]);
  });

  testWidgets('a business vehicle carries its badge on the end edge', (
    tester,
  ) async {
    // The artboard puts `.badge--business` beside the status dot. It is the
    // only per-vehicle fact the sheet has room for beyond the status line.
    await _pump(tester);
    expect(find.text('Business'), findsOneWidget);
  });
}
