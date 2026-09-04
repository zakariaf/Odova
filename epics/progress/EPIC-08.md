# EPIC-08 — app shell and navigation

## Task 8.1 — the route table, the single router and the 404 ✅

`lib/app/routing/{routes,app_router,route_not_found_screen,placeholder_screen}.dart`,
`test/app/routing/route_table_test.dart` (9 tests), `go_router: ^17.5.0`.

- All 28 `data-screen` ids covered by `kScreenRoutes`, proven against
  `design/calm/screens.html` itself rather than a copied list.
- `/costs/history` is registered as a second `history` instance and has no
  `kScreenRoutes` entry of its own — the registry maps a design id to its
  canonical location, and `history` already has one.
- **`tools/check_dependencies.sh` does not exist.** The epic's Verify step for
  8.1 names it; the dependency gate in this repo is `tools/audit_deps.sh`, which
  is what was run (clean). Correct the epic's Verify block in this PR.
- **A tenth test was added that the epic does not list**: `the four log segments
  are the four log screens, and nothing else`. `test/policy/one_money_type_test.dart`
  refused `LogType.fillUp('fillup')` on its first run because `OdometerSource`
  already declares `fillup`/`service`/`expense`. `LogType.wire` is now
  `name.toLowerCase()`, and the new test pins that derivation against the
  registry so a camelCase member cannot reach a URL. Nine mutations plus four on
  the new test, all seen red.
- Three ARB keys added in all six locales (`routeNotFoundTitle`,
  `routeNotFoundBody`, `routeNotFoundGoHome`); pseudo-locales regenerated with
  `dart run tool/build_pseudo_locales.dart`.
- `PlaceholderScreen` is deliberately unlocalised — it renders a `data-screen`
  id for a developer, and putting it in the ARBs would make six translators
  translate a screen id. It is deleted a screen at a time by the feature epics.

## Task 8.2 — the shell: four tab roots and the docked central `+` ✅

`lib/app/routing/app_shell.dart`, the `StatefulShellRoute.indexedStack` in
`app_router.dart`, `MaterialApp.router` in `lib/app/app.dart`,
`test/app/routing/app_shell_test.dart` (12 tests). Twelve mutations seen red.

- **`OdovaApp.home` is gone, replaced by `OdovaApp.router`.** `MaterialApp.router`
  has no `home:`. `test/support/pump_app.dart` gained `singleScreenRouter(child)`
  so every existing component test still pumps one widget inside the real themes
  and locales. `example/calm_gallery.dart` and
  `test/l10n/supported_locales_test.dart` were the other two callers.
- **The widget harness was reusing the first router.** `MaterialApp.router`
  builds its `RouterDelegate` once and keeps it, so a second `pumpWidget` of
  `OdovaApp` left the FIRST router driving the tree. Any test in a later epic
  that pumps the app twice must unmount between pumps — `_pumpApp` in
  `app_shell_test.dart` shows the shape.
- **A tap-target test that measured a `CalmPressable` proves nothing.**
  `CalmTapTarget` sizes to `max(child, 52)` unconditionally, so the assertion
  passes whatever the control does. Hit area is asserted by tapping the extremes.
- **FINDING for EPIC-17's design pass — 5pt of inert tab bar.** `CalmTabSlot` is
  62pt and centres a 52pt target in it, so the outermost 5pt at the top and
  bottom of every tab slot takes no tap. It meets Calm's own 52 floor, so it is
  recorded rather than changed here.
- **FINDING for EPIC-09 — the Costs tab icon is a euro sign.**
  `design/calm/screens.html` draws it as an arc with two horizontal strokes,
  which is €, in an app that ships six locales and stores an ISO 4217 code per
  vehicle. `CalmTabIcons.costs` is `Icons.payments_outlined`, currency-neutral
  and deliberately NOT the reference's shape. The first parity check on a tab
  root will fail on all four glyphs; EPIC-09 either re-shoots the artboard with
  a neutral Costs glyph or the design decides the euro is intended.
- Tab-root behaviour on a tap of the CURRENT tab is task 8.3's; until then
  `goBranch` keeps the branch where it is rather than resetting.

## Task 8.3 — tab-root behaviour, back, and the two stack resets ✅

`lib/app/routing/tab_stack_reset.dart`, `lib/app/routing/tab_reselected.dart`,
a `PopScope` on `AppShell`, `test/app/routing/{tab_behaviour,stack_reset}_test.dart`
(8 + 6 tests), `test/app/routing/shell_harness.dart`. 33 mutations across tasks
8.1–8.3 re-run against the shared harness, all red.

- **`resetAllTabStacks` has ZERO callers today, not two.** SPEC.md §7's two are
  the vehicle switcher (EPIC-09) and the importer (EPIC-13). The grep test in
  `stack_reset_test.dart` asserts zero and names both epics — **whichever lands
  first must update that expectation** rather than deleting the test.
- **`GoRouter.go` to a branch root does NOT reset that branch.** go_router keeps
  a match list per branch and restores it. The reset API is
  `StatefulNavigationShell.goBranch(i, initialLocation: true)`, and it needs a
  frame between each branch or all four collapse into the last one.
- **The reset is a request the shell applies**, not a direct call: only the live
  shell can empty a branch. `tabStackResetProvider` carries `(selectHome, tick)`;
  the tick is why two identical requests are two events.
- **`tabReselectedProvider` is the scroll-to-top seam.** EPIC-10 wires Home's
  `ScrollController` to it: watch it, check `index == 0`, scroll. Nothing listens
  yet.
- **Every routing test goes through `test/app/routing/shell_harness.dart`.**
  It owns the unmount-first rule (`MaterialApp.router` keeps its first delegate),
  the `ProviderContainer` and its teardown, `locationOf`, `shellOf`, `tapTab`,
  `goTo`, `setLocale`, `directionOf`, `shellGuard` and `systemBack`. A new
  routing test uses it rather than pumping its own app.
- `systemBack()` is copied from the Flutter SDK's own test utility because
  `flutter_test` does not export it. `Navigator.pop` is not a substitute — it
  bypasses `PopScope`.

## Task 8.4 — the four page kinds, and the dismissal contract ✅

`lib/app/routing/page_kinds.dart` (`PageKind`, four `Page` factories),
`lib/app/routing/dirty_modal_guard.dart`, `test/app/routing/page_kinds_test.dart`
(13 tests). 14 mutations, all red.

- **`parentNavigatorKey: rootNavigatorKey` on a top-level route is a no-op** and
  was removed from five routes after a mutation proved it. The LEVEL a route is
  declared at is the mechanism. The key matters only for a route that lives
  inside a branch and must still cover the tab bar.
- **`DirtyModalGuard.confirmDiscard` is injected.** Task 8.8 supplies
  `showDiscardDialog` as the app's answer; nothing wires it yet, so no modal in
  the app is guarded today — there are no modals yet either.
- **`DirtyModalGuard.of(context)` needs a context BELOW the guard.** A Cancel
  built from the context that created the guard asserts rather than silently
  popping. Every modal's Cancel goes through `requestDismiss()`, never
  `Navigator.pop`.
- **Two of the epic's listed tests are deferred to 8.8–8.10**: `no dialog can be
  dismissed into a destructive outcome` (a table over the three dialog builders,
  which do not exist yet) and `a modal stacked over a sheet dismisses both on
  save` (needs `vehicle.switcher`, EPIC-09).
- `shell_harness.dart` now resolves the shell with `skipOffstage: false`, because
  an opaque modal puts the whole shell offstage.

## Task 8.5 — the active vehicle, and never taxing the one-car user ✅

`lib/app/active_vehicle.dart`, `SettingsRepository.setActiveVehicle`,
`test/app/active_vehicle_test.dart` (11 tests). 12 mutations, all red.

- **`liveVehicleCountProvider` lives here, over `vehiclesProvider`** — not the
  direct query task 8.6 planned. EPIC-09 has nothing to re-point: it already
  reads the repository's own stream, which filters tombstones.
- **`resetAllTabStacks` now has one caller** (`lib/app/active_vehicle.dart`) and
  `stack_reset_test.dart` names it. **EPIC-13's importer is the second and must
  add itself to that list.**
- **`costsAllVehiclesProvider` is declared here for EPIC-13 to inherit**: a
  tab-scoped view flag, never persisted, never the active vehicle.
- **Deferred to task 8.6**: the `vehicle.switcher` redirect that makes the route
  unreachable with one vehicle. `showsVehicleSwitcherProvider` is the predicate;
  the redirect clause belongs with the launch gate.
- **`AppSettings` has no `copyWith`.** EPIC-14's settings screens will want one;
  until then every partial write is a targeted repository method like
  `setActiveVehicle`, which is the safer shape anyway.
- **Two test-infrastructure traps, both worth knowing before writing any
  data-layer test**: `addTearDown` is LIFO, so dispose the `ProviderContainer`
  BEFORE closing the database or every test in the file times out silently in
  tear-down; and `customStatement` does not invalidate a drift stream — use
  `customUpdate(..., updates: {table})` or the watcher keeps the stale answer.

## Task 8.6 — the launch-state gate ✅

`lib/app/routing/launch_gate.dart` (`LaunchFacts`, `appRedirect`,
`initialLocationFor`, `launchFactsProvider`, `launchFactsListenable`), wired into
`routerProvider`. `test/app/routing/launch_gate_test.dart` (15) and
`test/app/bootstrap_launch_test.dart` (14). 16 mutations, all red.

- **`appRedirect` takes a `String`, not a `GoRouterState`.** A `GoRouterState`
  cannot be constructed in a test, and the loop-freedom property has to run over
  the whole route table. The router passes `state.matchedLocation`.
- **`onboardingDone` is NOT "a settings row exists".** First run writes the row
  on the language step and sets the flag on the vehicle step's Save. EPIC-09
  must set `onboarding_done` explicitly; writing the settings row is not enough.
- **`liveVehicleCountProvider` was task 8.5's and needs no EPIC-09 rework** —
  it already reads `vehiclesProvider`, which filters tombstones. The epic's note
  to re-point it at `VehicleRepository.watchGarage()` is obsolete.
- **The `vehicle.switcher` redirect deferred from 8.5 landed here**, as one
  clause in the gate.
- **`bootstrap()` is unchanged.** It returns overrides and does not read the
  facts: `routerProvider` reads them itself on first build, which is before the
  first frame and is the same guarantee with one fewer moving part. If EPIC-16
  needs facts earlier (a notification cold start), that is where to add it.
- **Three test-infrastructure repairs that every later epic inherits:**
  - `test/data/support/rows.dart` now calls `markTablesUpdated` — raw
    `customStatement` never invalidates a watching drift query.
  - **A drift stream does not deliver under `testWidgets`** (fake async, real
    timers); it hangs for ten minutes rather than failing. Ask database
    questions in a plain `test`, widget questions with data injected.
  - `OdovaRoot` needs a database now. `pumpApp`'s `noLaunchGate()` is the escape
    for tests that are not about routing.

## Task 8.7 — notification deep links ✅

`lib/app/routing/deep_link.dart` (`DeepLinkKind`, `DeepLinkRequest`,
`DeepLinkFacts`, `DeepLinkTarget`, `DeepLinkFailure`, `locationFor`,
`handleDeepLink`), `test/app/routing/deep_link_test.dart` (23 tests).
16 mutations, all red.

- **`SPEC.md` §7 was corrected in this PR.** Its `odometer.nudge` row opens
  `log.odometer`; its bullet said "Tapping the body never opens a form",
  unqualified. The bullet now says "the body of a **reminder** notification" and
  names the nudge as the exception, with the reason.
- **EPIC-16 extends this file rather than writing `lib/routing/
  notification_deep_link.dart`** (F-8.3). It owns `NotificationPayload`, its
  JSON round-trip and its per-kind validation, and maps onto `DeepLinkRequest`.
  `DeepLinkKind.wire` already holds §7's six strings.
- **`DeepLinkTarget.pinnedReminderId` is the seam for EPIC-10's Home**: scroll
  the card into view and highlight it for ~2s. The 2-second expiry is Home's, not
  the router's — nothing here holds a timer.
- **Nothing calls `handleDeepLink` yet.** EPIC-16 wires the notification tap to
  it, passing `setActiveVehicle` and a router `go`/`push` pair. The order —
  vehicle first, then route — is the function's contract and is tested.
- `shell_harness.goTo` now takes a `backStack`, which any test about a
  deep-linked destination needs.
