// Where a tapped notification lands, for all six payload kinds — including
// when the thing it names is gone.
//
// SPEC.md §7 *Notification deep links*. `locationFor` is pure and total: the
// "deleted vehicle" and "deleted reminder" rows are decided by a function over
// facts rather than by a repository call inside a router, so they can be tested
// without a database and cannot answer differently on a second frame.
//
// EPIC-16 owns the PAYLOAD — the sealed `NotificationPayload`, its JSON
// round-trip and its per-kind `reminderId` validation — and maps it onto
// `DeepLinkRequest` at the boundary (finding F-8.3).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/deep_link.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/result.dart';

import 'shell_harness.dart';

const _golf = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA';
const _oil = 'rem_01JV7B5X4G2K9M6P0S3D8FNRTC';

/// Everything the named records still exist.
const _present = DeepLinkFacts(vehicleExists: true, reminderExists: true);

DeepLinkTarget _target(
  DeepLinkKind kind, {
  String? reminderId,
  DeepLinkFacts facts = _present,
}) {
  final result = locationFor(
    DeepLinkRequest(kind: kind, vehicleId: _golf, reminderId: reminderId),
    facts,
  );
  return (result as Ok<DeepLinkTarget, DeepLinkFailure>).value;
}

void main() {
  group('the six kinds', () {
    test('reminder.due and reminder.overdue are one destination', () {
      // Two kinds, one answer: the difference between "due" and "overdue" is
      // what the CARD says, and Home already knows it from the due engine.
      for (final kind in [
        DeepLinkKind.reminderDue,
        DeepLinkKind.reminderOverdue,
      ]) {
        final target = _target(kind, reminderId: _oil);
        expect(target.location, Routes.home, reason: kind.name);
        expect(target.activateVehicleId, _golf, reason: kind.name);
        expect(target.pinnedReminderId, _oil, reason: kind.name);
      }
    });

    test('reminder.grouped sets the vehicle and pins no card', () {
      final target = _target(DeepLinkKind.reminderGrouped);
      expect(target.location, Routes.home);
      expect(target.activateVehicleId, _golf);
      expect(target.pinnedReminderId, isNull);
    });

    test('reminder.grouped pins nothing even when handed a reminderId', () {
      // The version that catches something. §7 says `reminderId` is absent for
      // every kind but the two single-reminder ones, so a grouped payload
      // carrying one is a payload from a build that disagreed — and pinning it
      // would highlight one of several items and quietly imply the others are
      // fine. Reading the FIELD rather than the kind is the mutation; passing
      // no id at all cannot catch it, because null pins nothing either way.
      final target = _target(DeepLinkKind.reminderGrouped, reminderId: _oil);
      expect(target.pinnedReminderId, isNull);
      expect(target.location, Routes.home);
    });

    test('odometer.nudge opens the odometer form on Home', () {
      final target = _target(DeepLinkKind.odometerNudge);
      expect(target.location, Routes.log(LogType.odometer));
      expect(target.activateVehicleId, _golf);
      expect(target.backStack, [Routes.home]);
    });

    test('odometer.nudge never opens vehicle.switcher', () {
      // §7 says so explicitly: a nudge that asks "which car?" has failed at its
      // one job. The vehicle is in the payload.
      final target = _target(DeepLinkKind.odometerNudge);
      expect(target.location, isNot(Routes.vehicleSwitcher));
      expect(target.backStack, isNot(contains(Routes.vehicleSwitcher)));
    });

    test('keeper lands on Home and leaves the active vehicle alone', () {
      final target = _target(DeepLinkKind.keeper);
      expect(target.location, Routes.home);
      expect(target.activateVehicleId, isNull);
    });

    test('backup.nudge walks out through Settings', () {
      // §7 names the synthesised stack: [home, settings, settings.backup], so
      // Back goes to Settings rather than out of the app.
      final target = _target(DeepLinkKind.backupNudge);
      expect(target.location, Routes.settingsBackup);
      expect(target.activateVehicleId, isNull);
      expect(target.backStack, [Routes.home, Routes.settings]);
    });

    test('every other kind synthesises a [home] back stack', () {
      for (final kind in DeepLinkKind.values) {
        if (kind == DeepLinkKind.backupNudge) continue;
        expect(
          _target(kind, reminderId: _oil).backStack,
          [Routes.home],
          reason: kind.name,
        );
      }
    });
  });

  group('a reminder tap opens no form', () {
    test('none of the three reminder kinds lands on a log route', () {
      // §7: a lock-screen tap is often exploratory, and a prefilled form one
      // thumb-slip from Save is a data-integrity hazard. **Done** exists for
      // people who mean it and records without opening a form at all.
      //
      // This is about the three REMINDER kinds. `odometer.nudge` opens
      // `log.odometer` by design — see SPEC.md §7, where the bullet was
      // unqualified and is corrected in this PR.
      for (final kind in [
        DeepLinkKind.reminderDue,
        DeepLinkKind.reminderOverdue,
        DeepLinkKind.reminderGrouped,
      ]) {
        expect(
          _target(kind, reminderId: _oil).location,
          isNot(startsWith('/log')),
          reason: kind.name,
        );
      }
    });
  });

  group('the vehicle is set BEFORE the route resolves', () {
    // Asserted as ORDER, not as end state. Setting the vehicle after the route
    // means Home renders the previous car for a frame, and the odometer modal
    // prefills the previous car's last reading — which is a wrong number the
    // user is one tap from saving. It fails silently on device and an end-state
    // assertion cannot see it.
    test('every kind that names a vehicle carries it on the target', () {
      for (final kind in [
        DeepLinkKind.reminderDue,
        DeepLinkKind.reminderOverdue,
        DeepLinkKind.reminderGrouped,
        DeepLinkKind.odometerNudge,
      ]) {
        expect(
          _target(kind, reminderId: _oil).activateVehicleId,
          _golf,
          reason: kind.name,
        );
      }
    });

    test('handleDeepLink applies the vehicle, then navigates', () {
      final log = <String>[];
      handleDeepLink(
        _target(DeepLinkKind.odometerNudge),
        activateVehicle: (id) => log.add('vehicle:$id'),
        navigate: (location, {required backStack}) =>
            log.add('navigate:$location'),
      );

      expect(log, [
        'vehicle:$_golf',
        'navigate:${Routes.log(LogType.odometer)}',
      ]);
    });

    test('a target with no vehicle does not touch the active one', () {
      final log = <String>[];
      handleDeepLink(
        _target(DeepLinkKind.keeper),
        activateVehicle: (id) => log.add('vehicle:$id'),
        navigate: (location, {required backStack}) =>
            log.add('navigate:$location'),
      );

      expect(log, ['navigate:${Routes.home}']);
    });
  });

  group('the thing it names is gone', () {
    // §7: no error for something the user already dealt with. A user who
    // deleted a car and then tapped its three-day-old notification does not
    // need to be told the car is gone; they know.
    const deletedVehicle = DeepLinkFacts(
      vehicleExists: false,
      reminderExists: true,
    );
    const deletedReminder = DeepLinkFacts(
      vehicleExists: true,
      reminderExists: false,
    );

    test('a deleted vehicle lands on plain Home and switches nothing', () {
      final target = _target(
        DeepLinkKind.reminderDue,
        reminderId: _oil,
        facts: deletedVehicle,
      );
      expect(target.location, Routes.home);
      expect(target.activateVehicleId, isNull);
      expect(target.pinnedReminderId, isNull);
    });

    test('a deleted reminder lands on plain Home and pins nothing', () {
      final target = _target(
        DeepLinkKind.reminderDue,
        reminderId: _oil,
        facts: deletedReminder,
      );
      expect(target.location, Routes.home);
      // The car is still there, so the payload's vehicle is still right.
      expect(target.activateVehicleId, _golf);
      expect(target.pinnedReminderId, isNull);
    });

    test('a deleted vehicle turns a nudge into plain Home, not a form', () {
      // The modal would open on the wrong car otherwise, prefilled with its
      // last reading.
      final target = _target(
        DeepLinkKind.odometerNudge,
        facts: deletedVehicle,
      );
      expect(target.location, Routes.home);
      expect(target.activateVehicleId, isNull);
    });

    test('backup.nudge is unaffected: it names no vehicle', () {
      final target = _target(DeepLinkKind.backupNudge, facts: deletedVehicle);
      expect(target.location, Routes.settingsBackup);
    });
  });

  group('what it refuses', () {
    test('a reminder kind with no reminderId is a typed failure', () {
      // §7: `reminderId` is absent for every kind except the two reminder ones.
      // A payload from an older build that lost it is refused rather than
      // silently landing on an unpinned Home that looks correct.
      for (final kind in [
        DeepLinkKind.reminderDue,
        DeepLinkKind.reminderOverdue,
      ]) {
        final result = locationFor(
          DeepLinkRequest(kind: kind, vehicleId: _golf),
          _present,
        );
        expect(result, isA<Err<DeepLinkTarget, DeepLinkFailure>>());
      }
    });

    test('a malformed vehicle id is a typed failure', () {
      final result = locationFor(
        const DeepLinkRequest(
          kind: DeepLinkKind.keeper,
          vehicleId: 'not-an-id',
        ),
        _present,
      );
      expect(result, isA<Err<DeepLinkTarget, DeepLinkFailure>>());
    });

    test('a failure is dropped silently, never routed to a default', () {
      // The caller's contract. An app-update-stale payload that fell through to
      // `home` would look like a working link and hide the real problem.
      final result = locationFor(
        const DeepLinkRequest(
          kind: DeepLinkKind.reminderDue,
          vehicleId: _golf,
        ),
        _present,
      );
      expect(result, isA<Err<DeepLinkTarget, DeepLinkFailure>>());
      expect(
        (result as Err<DeepLinkTarget, DeepLinkFailure>).failure,
        isA<DeepLinkFailure>(),
      );
    });

    test('locationFor is total over every kind', () {
      // No kind throws, and every kind that is well-formed produces a target.
      for (final kind in DeepLinkKind.values) {
        final result = locationFor(
          DeepLinkRequest(kind: kind, vehicleId: _golf, reminderId: _oil),
          _present,
        );
        expect(
          result,
          isA<Ok<DeepLinkTarget, DeepLinkFailure>>(),
          reason: kind.name,
        );
      }
    });
  });

  group('in the running app', () {
    testWidgets('back from a deep-linked modal lands on Home', (tester) async {
      // §7: "Back from a deep-linked modal lands on Home, never straight out of
      // the app." Pumped, because the claim is about the Navigator's stack and
      // not about the function that produced the location.
      await pumpShell(tester, Routes.home);
      final target = _target(DeepLinkKind.odometerNudge);

      goTo(tester, target.location, backStack: target.backStack);
      await tester.pumpAndSettle();
      expect(locationOf(tester), Routes.log(LogType.odometer));

      await systemBack();
      await tester.pumpAndSettle();
      expect(locationOf(tester), Routes.home);
    });

    testWidgets('back from backup.nudge walks out through Settings', (
      tester,
    ) async {
      await pumpShell(tester, Routes.home);
      final target = _target(DeepLinkKind.backupNudge);

      goTo(tester, target.location, backStack: target.backStack);
      await tester.pumpAndSettle();
      expect(locationOf(tester), Routes.settingsBackup);

      await systemBack();
      await tester.pumpAndSettle();
      expect(locationOf(tester), Routes.settings);

      await systemBack();
      await tester.pumpAndSettle();
      expect(locationOf(tester), Routes.home);
    });
  });

  test('a payload is never a live Dart object', () {
    // `check_routing.sh` asserts this over `lib/` as a whole; here it is over
    // the file that would be most tempted. A notification payload crosses a
    // process boundary, so identity that travels in `state.extra` is identity
    // that is null on a cold start — the exact case a notification tap IS.
    expect(
      File('lib/app/routing/deep_link.dart').readAsStringSync(),
      isNot(contains('state.extra')),
    );
  });
}
