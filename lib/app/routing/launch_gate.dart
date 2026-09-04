// Every way the app can open, and where it lands.
//
// SPEC.md §7 calls its launch table "the launch-state contract: every way the
// app can open is a row here". This is that table as one pure function.
//
// Pure on purpose, and the purity is what makes it safe. A `redirect` runs on
// EVERY navigation, so one that reads a repository would run a query on every
// tap and could answer differently on the second frame than the first — which
// go_router turns into a redirect loop and a crash rather than a wrong screen.
// The three facts come in as an argument; `bootstrap()` reads them once before
// the first frame and a `refreshListenable` re-evaluates the gate when they
// change.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/value_equality.dart';
import 'package:odova/data/db/degraded_mode.dart';
import 'package:odova/data/repositories/providers.dart';

/// The three things that decide where the app opens.
///
/// A record-shaped class rather than three loose parameters, so a caller cannot
/// swap `onboardingDone` for `migrationFailed` at a call site and get a
/// plausible wrong answer.
class LaunchFacts with ValueEquality {
  /// Creates the facts.
  const LaunchFacts({
    required this.onboardingDone,
    required this.liveVehicleCount,
    required this.migrationFailed,
  });

  /// Whether first run has completed.
  ///
  /// Set by first run's Save AND by a successful import — SPEC.md §7 is
  /// explicit that the importer sets it rather than reading it from the file,
  /// because a backup written by a build that did not have the flag would
  /// otherwise send a restored user back through onboarding.
  final bool onboardingDone;

  /// How many vehicles exist, tombstones excluded.
  final int liveVehicleCount;

  /// Whether a migration failed on this launch.
  final bool migrationFailed;

  /// Whether the multi-vehicle interface exists at all.
  ///
  /// SPEC.md §7: with one vehicle there is no switcher — no chevron, no tap
  /// target, no "1 of 1". The rule lives HERE and both readers take it from
  /// here: the redirect below, which makes the route unreachable, and
  /// `showsVehicleSwitcherProvider`, which hides the chevron. It was written
  /// twice, and only the redirect was load-bearing — changing the provider's
  /// copy would have silently changed nothing.
  bool get showsVehicleSwitcher => liveVehicleCount >= 2;

  /// Value equality, and it is load-bearing rather than tidy.
  ///
  /// `launchFactsProvider` watches two drift streams, which re-emit on ANY
  /// write to `settings` or `vehicles` — a theme change, a units change, an
  /// active-vehicle write. Without `==`, every one of those produced a new
  /// identity, Riverpod's `previous != next` said "changed", the
  /// `refreshListenable` fired, and go_router re-ran the redirect chain,
  /// re-matched the route table and rebuilt the shell and its four branch
  /// navigators — for three fields that had not moved.
  @override
  List<Object?> get props => [
    onboardingDone,
    liveVehicleCount,
    migrationFailed,
  ];

  @override
  String toString() =>
      'LaunchFacts(onboardingDone: $onboardingDone, '
      'liveVehicleCount: $liveVehicleCount, '
      'migrationFailed: $migrationFailed)';
}

/// Where the app should go instead of [location], or null to allow it.
///
/// Takes the location as a String rather than a `GoRouterState`. The epic's
/// signature was `(LaunchFacts, GoRouterState)`, and a `GoRouterState` is a
/// large object a test cannot construct — which would have made the one
/// function in the app that must be provably loop-free the hardest one to
/// write a property test over. The router passes `state.matchedLocation`.
String? appRedirect(LaunchFacts facts, String location) {
  // 1. A failed migration outranks everything, including first run. SPEC.md
  //    §7's app-update row: the data has to be able to leave the building
  //    before anything else is attempted — and first run's Save would write
  //    into the broken database.
  if (facts.migrationFailed) {
    return location == Routes.settingsBackup ? null : Routes.settingsBackup;
  }

  // 2. The restore path is open from anywhere, including before a vehicle
  //    exists. §7: "The restore path must exist before a vehicle does, or the
  //    user invents a fake car and then discovers Replace, which wipes it."
  if (location == Routes.settingsImport) return null;

  final onFirstRun =
      location == Routes.firstRunLanguage || location == Routes.firstRunVehicle;

  // 3. No prior run: the language step, which is also the RTL decision. §7
  //    shows it even when the device locale is one of the six, because a
  //    hand-me-down phone in the wrong language is a silent disaster.
  if (!facts.onboardingDone) {
    return onFirstRun ? null : Routes.firstRunLanguage;
  }

  // 4. Onboarding is done and every vehicle is gone. §7: "Language is already
  //    chosen; do not ask again."
  if (facts.liveVehicleCount == 0) {
    return location == Routes.firstRunVehicle ? null : Routes.firstRunVehicle;
  }

  // 5. Onboarding is done and a vehicle exists, so the first-run screens have
  //    nothing left to do. Leaving a user on one after a successful import
  //    would look like the import failed.
  if (onFirstRun) return Routes.home;

  // 6. SPEC.md §7: with one vehicle there is no switcher. Enforced here rather
  //    than inside the sheet, because a check inside the sheet means the sheet
  //    has already opened.
  if (location == Routes.vehicleSwitcher && !facts.showsVehicleSwitcher) {
    return Routes.home;
  }

  return null;
}

/// Where the app opens, given [facts].
///
/// `bootstrap()` reads the facts once and hands this to the router as its
/// `initialLocation`, so the FIRST painted frame is the destination. A flash of
/// Home before first run is a visible defect (`app-startup-and-bootstrap` rule
/// 5), and it is what happens when the app always opens on `/` and lets the
/// redirect sort it out.
///
/// Nothing here reads a persisted location, and that is deliberate rather than
/// unfinished: SPEC.md §7 says launch always selects the Home tab, never the
/// last-used one, because sessions are days apart and a three-week-old Costs
/// tab is noise. Modal state is never restored for the same reason — a cold
/// start into a half-filled fill-up form is a form the user cannot trust.
String initialLocationFor(LaunchFacts facts) =>
    appRedirect(facts, Routes.home) ?? Routes.home;

/// What `bootstrap()` read before the first frame.
///
/// **Overridden in `bootstrap()`, and the default is deliberately unreachable
/// in a shipping build.** A returning user's facts are on disk, and reading
/// them is a database open plus two queries — real work that cannot happen
/// inside a synchronous provider.
///
/// Without this the gate derived its facts from two drift streams that had not
/// delivered yet, so the FIRST answer on every cold start was
/// `(onboardingDone: false, liveVehicleCount: 0)` — a returning user with a car
/// and eight years of history opened on the language step and was corrected
/// only when the streams landed, which on a slow phone with a large file is
/// many frames later. That is the flash `app-startup-and-bootstrap` rule 5
/// forbids, and this epic's progress file claimed it did not happen. It did.
///
/// It is also what makes an ERRORED stream safe: `AsyncError` carries no value
/// either, so the fallback below is the last thing actually read from disk
/// rather than "definitely a fresh install".
final initialLaunchFactsProvider = Provider<LaunchFacts>(
  (ref) => throw StateError(
    'initialLaunchFactsProvider was read before bootstrap() overrode it. The '
    'launch gate cannot guess: "we have not read the database yet" and "this '
    'is a fresh install" are different facts and SPEC.md §7 sends them to '
    'different screens.',
  ),
);

/// The three facts, read from the app's state.
///
/// One provider so the router, `bootstrap()` and any screen that has to explain
/// itself all read the SAME answer. Three separate reads at three call sites is
/// three chances to disagree about whether onboarding is finished.
///
/// Each fact falls back to what `bootstrap()` read when the live source has no
/// value — which is true on the first frame and true again if a stream errors.
/// `?? initial.x` rather than `?? false`: the absence of a value is not the
/// value `false`.
final launchFactsProvider = Provider<LaunchFacts>((ref) {
  final initial = ref.watch(initialLaunchFactsProvider);
  final settings = ref.watch(settingsProvider);
  final vehicles = ref.watch(vehiclesProvider);

  return LaunchFacts(
    onboardingDone: settings.value?.onboardingDone ?? initial.onboardingDone,
    liveVehicleCount: vehicles.value?.length ?? initial.liveVehicleCount,
    migrationFailed: ref.watch(degradedModeProvider) is MigrationFailed,
  );
});

/// Ticks whenever the launch facts change.
///
/// go_router re-evaluates `redirect` when its `refreshListenable` notifies, and
/// nothing else tells it that first run just finished. Without this bridge the
/// user would complete onboarding and stay on the first-run screen until they
/// navigated somewhere by hand — `navigation-and-routing` rule 6.
///
/// A `ValueNotifier<LaunchFacts>` rather than a bare `ChangeNotifier`, so the
/// value it carries is the same object the redirect will read and a debug
/// session can see what the router was told.
ValueNotifier<LaunchFacts> launchFactsListenable(Ref ref) {
  final notifier = ValueNotifier(ref.read(launchFactsProvider));
  ref
    ..listen<LaunchFacts>(
      launchFactsProvider,
      (previous, next) => notifier.value = next,
    )
    ..onDispose(notifier.dispose);
  return notifier;
}
