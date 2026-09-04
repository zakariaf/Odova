// Every way the app can open, and where it lands.
//
// SPEC.md §7 calls its launch table "the launch-state contract: every way the
// app can open is a row here", so every row is a named test below. The gate is
// a pure function of three facts and a location, which is why these run in
// microseconds against `appRedirect` rather than against a pumped app — and why
// the two properties at the bottom can be checked over the WHOLE route table
// rather than over the handful of locations somebody thought to list.
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/launch_gate.dart';
import 'package:odova/app/routing/routes.dart';

/// A returning user with a car and a healthy database.
const _returning = LaunchFacts(
  onboardingDone: true,
  liveVehicleCount: 1,
  migrationFailed: false,
);

/// A fresh install.
const _fresh = LaunchFacts(
  onboardingDone: false,
  liveVehicleCount: 0,
  migrationFailed: false,
);

/// Someone who deleted their last vehicle.
const _emptyGarage = LaunchFacts(
  onboardingDone: true,
  liveVehicleCount: 0,
  migrationFailed: false,
);

/// Every combination the gate can be asked about.
Iterable<LaunchFacts> get _allFacts sync* {
  for (final onboardingDone in [false, true]) {
    for (final count in [0, 1, 2]) {
      for (final migrationFailed in [false, true]) {
        yield LaunchFacts(
          onboardingDone: onboardingDone,
          liveVehicleCount: count,
          migrationFailed: migrationFailed,
        );
      }
    }
  }
}

/// Every location the route table can produce, with its `:params` filled in.
Iterable<String> get _allLocations sync* {
  for (final route in kScreenRoutes.values) {
    if (route is! ScreenLocation) continue;
    yield route.path
        .replaceAll(RegExp(':[A-Za-z]+Id'), 'x')
        .replaceAll(':type', LogType.fillUp.wire);
  }
}

void main() {
  group("SPEC.md §7's launch table, one row per test", () {
    test('launch, no prior run, goes to the language step', () {
      expect(appRedirect(_fresh, Routes.home), Routes.firstRunLanguage);
    });

    test('launch with a vehicle allows Home, and returns null', () {
      // Null, not a redirect to `/`. A gate that answers with the location it
      // was asked about is a gate that redirects forever, and go_router's loop
      // detector turns that into a crash rather than a wrong screen.
      expect(appRedirect(_returning, Routes.home), isNull);
    });

    test('launch with zero vehicles goes to the vehicle step', () {
      // §7: "Language is already chosen; do not ask again." The user deleted
      // their last car; being asked to pick a language again would read as the
      // app having forgotten them.
      expect(
        appRedirect(_emptyGarage, Routes.home),
        Routes.firstRunVehicle,
      );
      expect(
        appRedirect(_emptyGarage, Routes.firstRunLanguage),
        Routes.firstRunVehicle,
      );
    });

    test('the language step is reachable while onboarding is unfinished', () {
      expect(appRedirect(_fresh, Routes.firstRunLanguage), isNull);
      expect(appRedirect(_fresh, Routes.firstRunVehicle), isNull);
    });

    test('a failed migration goes to Backup whatever else is true', () {
      // §7's app-update row. The data must be able to leave the building
      // before anything else is attempted.
      for (final facts in _allFacts.where((f) => f.migrationFailed)) {
        expect(
          appRedirect(facts, Routes.home),
          Routes.settingsBackup,
          reason: '$facts',
        );
      }
    });

    test('a failed migration outranks the first-run redirect', () {
      // A corrupt install with no vehicles goes to Backup, not to first run:
      // first run's Save would write into a broken database, and SPEC.md §2
      // calls losing history the worst bug this app can have.
      const broken = LaunchFacts(
        onboardingDone: false,
        liveVehicleCount: 0,
        migrationFailed: true,
      );
      expect(appRedirect(broken, Routes.home), Routes.settingsBackup);
      expect(
        appRedirect(broken, Routes.firstRunLanguage),
        Routes.settingsBackup,
      );
    });

    test('the restore path is open from first run', () {
      // §7: "The restore path must exist before a vehicle does, or the user
      // invents a fake car and then discovers Replace, which wipes it."
      for (final facts in _allFacts.where((f) => !f.migrationFailed)) {
        expect(
          appRedirect(facts, Routes.settingsImport),
          isNull,
          reason: '$facts',
        );
      }
    });

    test('a finished first run does not sit on a first-run screen', () {
      // The import row: "Onboarding is skipped entirely." Once
      // `onboarding_done` is true and a vehicle exists, the first-run screens
      // are locations with nothing to do, and leaving the user on one after a
      // successful import would look like the import failed.
      expect(appRedirect(_returning, Routes.firstRunLanguage), Routes.home);
      expect(appRedirect(_returning, Routes.firstRunVehicle), Routes.home);
    });

    test('vehicle.switcher is unreachable below two vehicles', () {
      // EPIC-08 task 8.5's rule, enforced here rather than inside the sheet:
      // §7 says the one-car user has no switcher, and a check inside the sheet
      // would mean the sheet had already opened.
      for (final facts in _allFacts.where(
        (f) => !f.migrationFailed && f.onboardingDone,
      )) {
        // Two or more: allowed. Exactly one: home, because there is nothing to
        // switch between. Zero: the empty-garage row wins and sends the user to
        // the vehicle step, which is a different answer for a better reason.
        expect(
          appRedirect(facts, Routes.vehicleSwitcher),
          switch (facts.liveVehicleCount) {
            0 => Routes.firstRunVehicle,
            1 => Routes.home,
            _ => isNull,
          },
          reason: '$facts',
        );
      }
    });
  });

  group('the launch location', () {
    test('is always the Home TAB, never the last-used one', () {
      // §7: sessions are days apart and a three-week-old Costs tab is noise.
      // Nothing persists a location, so this holds by construction — and the
      // test is what stops somebody adding the persistence later and calling
      // it a convenience.
      expect(initialLocationFor(_returning), Routes.home);
    });

    test('is never a modal', () {
      // §7: "Modal state is never restored." A cold start into a half-filled
      // fill-up form is a form the user cannot trust.
      for (final facts in _allFacts) {
        final location = initialLocationFor(facts);
        expect(location, isNot(startsWith('/log')), reason: '$facts');
        expect(location, isNot(Routes.vehicleSwitcher), reason: '$facts');
      }
    });

    test('is a location the gate then leaves alone', () {
      // The two halves have to agree. A `bootstrap()` that opens the app on a
      // location the gate immediately redirects away from is the flash of the
      // wrong screen that `app-startup-and-bootstrap` rule 5 forbids.
      for (final facts in _allFacts) {
        expect(
          appRedirect(facts, initialLocationFor(facts)),
          isNull,
          reason: '$facts',
        );
      }
    });
  });

  group('the properties that keep it from looping', () {
    test('it never redirects a location to itself', () {
      for (final facts in _allFacts) {
        for (final location in _allLocations) {
          expect(
            appRedirect(facts, location),
            isNot(location),
            reason: '$facts at $location',
          );
        }
      }
    });

    test('one redirect is always enough', () {
      // No A→B→A, and no A→B→C either: whatever the gate answers, asking again
      // about the answer returns null. `navigation-and-routing` rule 7.
      for (final facts in _allFacts) {
        for (final location in _allLocations) {
          final first = appRedirect(facts, location);
          if (first == null) continue;
          expect(
            appRedirect(facts, first),
            isNull,
            reason:
                '$facts: $location -> $first -> ${appRedirect(facts, first)}',
          );
        }
      }
    });

    test('it is pure: same facts, same answer, no reads', () {
      // A `LaunchFacts` record and a String go in; a String? comes out. There
      // is no repository to touch, which is the strongest form this assertion
      // can take — a gate that could read is a gate that can answer differently
      // on the second frame.
      for (final facts in _allFacts) {
        for (final location in _allLocations) {
          expect(appRedirect(facts, location), appRedirect(facts, location));
        }
      }
    });
  });
}
