// Deleting a vehicle from the garage, end to end.
//
// SPEC.md §8's Delete section. EPIC-08's `confirm_delete_dialog_test.dart`
// already proves the dialog: the typed confirmation, the five counts, the
// isolate, the three stacked actions at 200%. None of that is repeated here.
//
// What is NOT covered anywhere else is the SCREEN: that it hands the dialog
// this vehicle's name and this vehicle's counts, that it acts on each of the
// three outcomes, that Undo gets ten seconds rather than six, and that the last
// vehicle leaving routes into first run instead of onto an empty garage.
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/app.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/due_snapshot_provider.dart';
import 'package:odova/features/vehicles/entry_counts_provider.dart';
import 'package:odova/features/vehicles/presentation/vehicles_screen.dart';
import 'package:odova/features/vehicles/vehicles_notifier.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_swipe_actions.dart';

import '../../../parity/support/parity_capture.dart'
    show kReferenceDpr, kReferencePhysical;
import '../../../support/due_case.dart';

final VehicleId _golf = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA')!;
final VehicleId _polo = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVB')!;

Vehicle _vehicle(VehicleId id, String name) => Vehicle(
  id: id,
  name: name,
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// Records what the screen asked for, and answers without a database.
class _RecordingNotifier extends VehiclesNotifier {
  final deleted = <VehicleId>[];
  final undone = <VehicleDeletion>[];
  final sold = <({VehicleId id, String soldOn, int? minor})>[];
  bool wasLast = false;

  @override
  Future<Result<VehicleDeletion, PersistFailure>> delete(VehicleId id) async {
    deleted.add(id);
    return Ok((
      deletedAtUtcMs: 1700000000000,
      deleted: id,
      previousActive: id,
      promoted: null,
      wasLast: wasLast,
    ));
  }

  @override
  Future<Result<void, PersistFailure>> undoDelete(
    VehicleDeletion deletion,
  ) async {
    undone.add(deletion);
    return const Ok(null);
  }

  @override
  Future<Result<void, PersistFailure>> markSold(
    VehicleId id, {
    required String soldOn,
    Money? soldPrice,
  }) async {
    sold.add((id: id, soldOn: soldOn, minor: soldPrice?.amountMinor));
    return const Ok(null);
  }
}

/// The garage inside a router that HAS somewhere to route to.
///
/// `singleScreenRouter` knows only `/`, so `context.go('/first-run/vehicle')`
/// throws there — and the last-vehicle route is the half of this flow most
/// worth pinning.
Future<_RecordingNotifier> _pump(
  WidgetTester tester, {
  List<Vehicle>? vehicles,
  DeleteCountsData counts = (
    fillUps: 96,
    services: 14,
    costs: 22,
    trips: 8,
    reminders: 16,
  ),
  bool wasLast = false,
}) async {
  // The reference device, not the 800x600 default. `dialog.confirmDelete` with
  // a safe alternative stacks THREE actions above a typed field, and on the
  // default viewport Cancel sat outside the hit-testable area — the tap missed
  // and the dialog simply stayed open, which reads in a test exactly like
  // "cancelling deleted nothing".
  tester.view.physicalSize = kReferencePhysical;
  tester.view.devicePixelRatio = kReferenceDpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final notifier = _RecordingNotifier()..wasLast = wasLast;
  final garage =
      vehicles ?? [_vehicle(_golf, 'The Golf'), _vehicle(_polo, 'The Polo')];

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 11, 20, 9, 41)),
        ),
        vehiclesProvider.overrideWith((ref) => Stream.value(garage)),
        settingsProvider.overrideWith(
          (ref) => Stream.value(dueFixtureSettings),
        ),
        for (final v in garage) ...[
          vehicleDueSnapshotProvider(v.id).overrideWithValue(null),
          vehicleEntryCountsProvider(v.id).overrideWith((ref) async => counts),
        ],
        vehiclesNotifierProvider.overrideWith(() => notifier),
      ],
      child: OdovaApp(
        router: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const VehiclesScreen()),
            GoRoute(
              path: Routes.firstRunVehicle,
              builder: (_, _) => const Scaffold(body: Text('first run')),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return notifier;
}

typedef DeleteCountsData = ({
  int fillUps,
  int services,
  int costs,
  int trips,
  int reminders,
});

/// Swipes the named row open and taps its Delete action.
///
/// Taps the BUTTON rather than calling the action's callback: the callback
/// skips the row's own close, which leaves a second "Delete" in the tree and
/// makes every finder after it ambiguous — and, on a real device, leaves a row
/// ajar under the dialog for the user's next tap to land on.
Future<void> _swipeDelete(WidgetTester tester, String name) async {
  await tester.drag(find.text(name), const Offset(-250, 0));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(CalmSwipeActionButton).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the dialog names THIS vehicle and THIS vehicle is counted', (
    tester,
  ) async {
    // The screen's whole job at this moment: hand the shared dialog the right
    // subject and the right counts. A row that passed the active vehicle's
    // name, or a fixed count, would look identical on screen until somebody
    // deleted the wrong car.
    await _pump(tester);
    await _swipeDelete(tester, 'The Polo');
    expect(find.textContaining('The Polo'), findsWidgets);
    expect(find.textContaining('140'), findsWidgets, reason: '96+14+22+8');
    // The OTHER vehicle's name appears exactly once — in its own row, and not
    // in the dialog. Asserting only that "The Polo" is on screen cannot fail:
    // its row is behind the dialog either way, which is how a hard-coded
    // subject passed the first version of this test.
    expect(find.text('The Golf'), findsOneWidget);
  });

  testWidgets('cancelling closes the dialog and deletes nothing', (
    tester,
  ) async {
    // Both halves. "Nothing was deleted" is also true of a dialog that never
    // closed, so the first version of this test passed against an
    // implementation that deleted on cancel — the tap was not landing and the
    // assertion could not tell the difference.
    final notifier = await _pump(tester);
    await _swipeDelete(tester, 'The Golf');
    expect(find.text('Cancel'), findsOneWidget, reason: 'the dialog is open');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsNothing, reason: 'and now closed');
    expect(notifier.deleted, isEmpty);
  });

  testWidgets('a zero-count vehicle deletes in one tap, and Undo has 10s', (
    tester,
  ) async {
    // SPEC.md §8: zero entries is a one-tap Delete; and the snackbar offers
    // Undo for 10 seconds rather than the usual 6, "because this destroys more
    // than one row".
    final notifier = await _pump(
      tester,
      counts: (fillUps: 0, services: 0, costs: 0, trips: 0, reminders: 0),
    );
    await _swipeDelete(tester, 'The Golf');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(notifier.deleted, [_golf]);
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).duration,
      kCalmDestructiveUndoWindow,
    );
  });

  testWidgets('Undo restores exactly what the delete reported', (tester) async {
    final notifier = await _pump(
      tester,
      counts: (fillUps: 0, services: 0, costs: 0, trips: 0, reminders: 0),
    );
    await _swipeDelete(tester, 'The Golf');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(notifier.undone, hasLength(1));
    expect(notifier.undone.single.deleted, _golf);
    expect(
      notifier.undone.single.deletedAtUtcMs,
      1700000000000,
      reason: 'the STAMP, so a row deleted earlier stays deleted',
    );
  });

  testWidgets('deleting the last vehicle routes into first run', (
    tester,
  ) async {
    // SPEC.md §8: "Deleting the last vehicle routes to `vehicle.edit`
    // (firstRun) with the Undo snackbar above the modal." Leaving the user on
    // an empty garage is the state §8 says is unreachable by design.
    final notifier = await _pump(
      tester,
      vehicles: [_vehicle(_golf, 'The Golf')],
      counts: (fillUps: 0, services: 0, costs: 0, trips: 0, reminders: 0),
      wasLast: true,
    );
    await _swipeDelete(tester, 'The Golf');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(notifier.deleted, [_golf]);
    expect(find.text('first run'), findsOneWidget);
    // ABOVE the modal, not consumed by the route change: `ScaffoldMessenger`
    // is what makes an Undo survive navigation, and a snackbar shown on the
    // old route's messenger would vanish with it.
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('the only vehicle is warned about, and still deletable', (
    tester,
  ) async {
    // SPEC.md §8: "The delete row reads 'Delete The Golf' and its dialog
    // carries the extra line 'This is your only vehicle. Deleting it starts
    // Odova over.'" It WARNS without forbidding — §8 has a route for what
    // happens next, so the line is information, not a gate.
    await _pump(
      tester,
      vehicles: [_vehicle(_golf, 'The Golf')],
      counts: (fillUps: 0, services: 0, costs: 0, trips: 0, reminders: 0),
      wasLast: true,
    );
    await _swipeDelete(tester, 'The Golf');
    expect(
      find.textContaining('starts Odova over'),
      findsOneWidget,
      reason: 'the extra line',
    );
    // Enabled, not merely present: a zero-entry vehicle deletes in one tap and
    // the warning must not have quietly become a gate.
    expect(
      tester
          .widgetList<CalmButton>(find.byType(CalmButton))
          .firstWhere((b) => b.label == 'Delete')
          .onPressed,
      isNotNull,
      reason: 'warned, not forbidden',
    );
  });

  testWidgets('a garage of two carries no only-vehicle warning', (
    tester,
  ) async {
    // The other arm. Two cars means deleting one starts nothing over, and a
    // warning that is always on is a warning nobody reads.
    await _pump(
      tester,
      counts: (fillUps: 0, services: 0, costs: 0, trips: 0, reminders: 0),
    );
    await _swipeDelete(tester, 'The Golf');
    expect(find.textContaining('starts Odova over'), findsNothing);
  });

  testWidgets('a delete that is NOT the last one stays on the garage', (
    tester,
  ) async {
    await _pump(
      tester,
      counts: (fillUps: 0, services: 0, costs: 0, trips: 0, reminders: 0),
    );
    await _swipeDelete(tester, 'The Golf');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('first run'), findsNothing);
  });

  testWidgets('"Keep it — mark it sold" opens the form and deletes nothing', (
    tester,
  ) async {
    // SPEC.md §8: the sale is offered ABOVE Delete "because 'I sold the car' is
    // what people mean most of the time they reach for Delete, and the history
    // they are about to destroy is what made the sale worth more". A dialog
    // that offered it and then deleted anyway would be the worst version of
    // this screen.
    final notifier = await _pump(tester);
    await _swipeDelete(tester, 'The Golf');
    // §8 quotes the button verbatim, and the "Keep it —" half is the point:
    // "Mark as sold" alone says what the button does without saying why it is
    // being offered in a delete dialog.
    expect(find.text('Keep it — mark it sold'), findsOneWidget);

    await tester.tap(find.text('Keep it — mark it sold'));
    await tester.pumpAndSettle();

    expect(notifier.deleted, isEmpty);
    // The sale FORM, not a silent sale: SPEC.md §8 asks for a date and a price.
    expect(find.text('Sold on'), findsOneWidget);
    expect(notifier.sold, isEmpty, reason: 'nothing until the form is saved');
  });

  testWidgets('a SOLD vehicle is offered no sale in its delete dialog', (
    tester,
  ) async {
    // There is no sale left to make, and offering one would put a second sale
    // date over the one the user entered.
    await _pump(
      tester,
      vehicles: [
        Vehicle(
          id: _golf,
          name: 'The Golf',
          vehicleType: VehicleType.car,
          fuelKindDefault: FuelKind.diesel,
          status: VehicleStatus.sold,
          soldOn: '2024-03-12',
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
      ],
      counts: (fillUps: 0, services: 0, costs: 0, trips: 0, reminders: 0),
    );
    await _swipeDelete(tester, 'The Golf');
    expect(find.text('Delete'), findsOneWidget, reason: 'the dialog is open');
    expect(find.text('Mark as sold'), findsNothing);
  });
}
