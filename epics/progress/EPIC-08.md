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
- ~~**`bootstrap()` is unchanged.** It returns overrides and does not read the
  facts: `routerProvider` reads them itself on first build, which is before the
  first frame and is the same guarantee with one fewer moving part.~~
  **THIS WAS WRONG, and `/code-review` proved it against a real database.** A
  synchronous read of a StreamProvider that has not delivered returns NO VALUE,
  so the first facts on every cold start were `(false, 0)` and every returning
  user opened on the language step. `bootstrap()` now does what this task
  originally specified: it opens the database, reads `onboarding_done` and the
  live vehicle count, and supplies `initialLaunchFactsProvider`. Each fact falls
  back to that when its stream has none — which also covers an ERRORED stream,
  where the old code would have parked an established user in onboarding and let
  first run overwrite their settings row.
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

## Task 8.8 — `dialog.discard` and the dirty-modal wiring ✅ (parity blocked)

`lib/ui/dialogs/discard_dialog.dart`, `CalmDialog.actions`,
`test/ui/dialogs/discard_dialog_test.dart` (11), the parity harness
(`test/parity/support/{parity_capture,dialog_backdrop}.dart`) and
`test/parity/dialog_discard_parity_test.dart`.

### Three real defects the parity gate found

- **Every Calm overlay rendered in `WidgetsApp`'s error text style.** No
  `Material` ancestor → 48pt bold red monospace with a double yellow underline.
  `CalmType` overrode the size and colour and left the FAMILY, so it looked
  almost right. `CalmDialog` and `CalmSheet` now wrap in
  `Material(type: transparency)`.
- **All 88 committed goldens had it baked in.** `CalmSpecimenFont` patched only
  the family. **76 goldens re-baselined.** `calm_overlay_typography_test.dart`
  is the gate that keeps it fixed — it fails on family, underline and 48pt
  independently.
- **`loadAppFonts` renders Latin in Vazirmatn**, ~2× the platform width, because
  Calm's Latin styles set no family and the fallback is the FIRST family
  registered. Fine for goldens (deterministic), wrong for parity. Use
  `loadParityFonts` for any capture — it registers SDK Roboto first, then
  Vazirmatn, then MaterialIcons.

### Harness traps, for the next screen epic

- A `dart:io` write inside a widget test's fake-async zone **never completes**.
  Wrap it in `tester.runAsync`.
- `MaterialApp` mounts an `AnimatedTheme` whose ticker stops `runAsync`
  returning. `themeAnimationStyle: AnimationStyle.noAnimation`.
- `toImage` must come from a **keyed** boundary; `MaterialApp` inserts its own
  and one that was never painted hangs with no output.
- The capture's MediaQuery needs `padding: top 54, bottom 34` — the artboards
  draw a status bar and a home indicator, and without them every band shifts.

### ⚠️ The band check does NOT pass, and EPIC-09/EPIC-10 own the fix

`dialog.discard` scores **53/80 band edges (66%)** against a 75% floor. Colour
and theme pass in light. Nothing was widened and no reference was regenerated.

The gap is the **backdrop**, per F-8.2: the three dialog references were shot
over `home` (discard, snooze) and `vehicles` (confirmDelete), and **the `home`
artboard overrides `.screen__body`'s own spacing inline — `padding-block: 8 12;
gap: 12` against the stylesheet's `20 24 / 20`.** So the reference picture of
`home` is not what a standard `CalmScaffold` produces, and **EPIC-10 will hit
this building the real Home.** It has to be decided deliberately: re-shoot
`home`'s artboard at `.screen__body`'s spacing, or give `CalmScaffold` the
density the artboard uses.

**EPIC-09 (`vehicles`) and EPIC-10 (`home`) must replace
`test/parity/support/dialog_backdrop.dart` with the real screens and re-run all
three dialog captures.** If the numbers do not improve, the stand-in was lying
and that is a finding then.

Also recorded: the **dark** captures fail the colour check on the scrim
COMPOSITE — `--scrim` over `--color-bg` is #050403, not a token and unable to
be, because `compare_to_reference.mjs` cannot see alpha. The scrim values match
`odova.css` exactly. That is a blind spot in the checker, not a wrong colour.

## Tasks 8.9 and 8.10 — `dialog.confirmDelete` and `dialog.snooze` ✅ (parity blocked)

`lib/ui/dialogs/{confirm_delete_dialog,snooze_dialog}.dart`, their tests
(16 + 18), `test/parity/support/dialog_overlays.dart` and two more capture
tests. 13 mutations, all red.

- **F-8.8 is SETTLED, and the epic's premise was wrong.** The reference's
  snooze sentence is "This quiets the reminder. It does not change when the job
  is due" — already state-neutral. No ICU `select` over `DueState`, and the
  dialog takes no `DueState` at all; a test asserts the type never appears in
  the file.
- **F-8.9 is raised and not worked around**: `kSnoozeDistanceMetres = 500000`,
  because §4.7.2 and §7 both write 500 km and name no mile equivalent. §4.8 says
  defaults are per unit system rather than converted; that is still unsettled.
- **F-8.6 stands**: the snooze title interpolates the item label AS STORED, so
  the built screen reads "Snooze Oil and filter" where the reference lower-cases
  it. One capital letter, recorded rather than chased.
- **`CalmDialog` now scrolls.** It overflowed by 35px at scale 1 with a field
  and three actions. EPIC-11's log forms inherit the fix.
- **A disabled `CalmButton` must carry a `CalmButtonExplain`** — EPIC-03 asserts
  it. The delete dialog's explanation repeats the field label above it: one
  sentence twice where the reference draws it once. **For EPIC-17's design pass.**
- **`AppSettings` still has no `copyWith`** and the dialogs need none — every
  one of them writes nothing.
- **Callers must inject their formatters.** `showConfirmDeleteDialog` takes
  `formatCount`, `showSnoozeDialog` takes `formatDate` and `formatDistance`.
  SPEC.md §5 has one numbering system app-wide and a dialog that formatted its
  own would put Latin digits in a Persian sentence.

### ⚠️ Band check, same blocker as 8.8

`confirmDelete` 34/81, `snooze` 34/72 (light LTR), against a 75% floor. Both
backdrops are stand-ins — `vehicles` is EPIC-09's screen and `home` is
EPIC-10's — and **both artboards override `.screen__body`'s spacing inline**
(`vehicles` uses `padding-block: 4 12`). **EPIC-09 and EPIC-10 replace
`test/parity/support/dialog_backdrop.dart` and re-run all three captures.**

### Two l10n gates were wrong for long messages, and are fixed

- `tool/build_pseudo_locales.dart` padded by 40% of the RAW length **clamped to
  40 characters**, so a message that is mostly ICU syntax expanded by 28%. Now
  40% of the LITERAL length, unclamped.
- `pseudo_locales_test.dart` compared raw string lengths, counting braces and
  category names as copy. Now measures through the generator's own
  `transformIcu` callback.

### ARB rules the gates enforce, for every later epic

- Every locale needs CLDR's `one`, not only `=1`.
- **Arabic's `zero` IS n=0** — an explicit `=0` beside it is dead and gen-l10n
  refuses it.
- Arabic's six branches must read DISTINCTLY, or they prove nothing.
- **No literal digit in any ARB value**, including a fixed "3" in "3 days".

---

## Handover — what the next epics inherit

### EPIC-09 (first run, garage, vehicles)
- **`onboarding_done` must be set explicitly** by first run's Save. The launch
  gate reads that flag, not "a settings row exists" — first run writes the row
  on the LANGUAGE step.
- **Replace `VehiclesBackdrop`** in `test/parity/support/dialog_backdrop.dart`
  with the real `vehicles` screen and re-run
  `test/parity/dialog_confirm_delete_parity_test.dart`. Current: 34/81 bands.
- **The vehicle switcher is `resetAllTabStacks`'s second caller.** Add it to the
  list in `test/app/routing/stack_reset_test.dart`.
- Call `showConfirmDeleteDialog` and `showDiscardDialog`; build neither.
- The `vehicle.switcher` route is already gated by the launch gate: unreachable
  below two live vehicles.

### EPIC-10 (home, reminders)
- **`tabReselectedProvider` is the scroll-to-top seam.** Watch it, check
  `index == 0`, scroll. Nothing listens yet.
- **`DeepLinkTarget.pinnedReminderId`** is the card to scroll to and highlight
  for ~2s. The timer is Home's; nothing in routing holds one.
- **Replace `HomeBackdrop`** and re-run the discard and snooze captures.
  Current: 53/80 and 34/72 bands.
- **`home`'s artboard uses spacing `.screen__body` does not** (`padding-block:
  8 12; gap: 12` against `20 24 / 20`). Decide it deliberately: re-shoot the
  artboard, or give `CalmScaffold` the density.
- Call `showSnoozeDialog`; build nothing.

### EPIC-11 (logging)
- **Every modal wraps in `DirtyModalGuard`** and passes `showDiscardDialog` as
  its `confirmDiscard`. `onDiscard` is ONE callback for all four segments.
- A Cancel control calls `DirtyModalGuard.of(context).requestDismiss()`, never
  `Navigator.pop` — and its `context` must be BELOW the guard.
- `CalmDialog` scrolls now, so a tall form's dialog will not overflow.

### EPIC-13 (costs, trips)
- **`costsAllVehiclesProvider` already exists** in `lib/app/active_vehicle.dart`:
  tab-scoped, never persisted, never the active vehicle.

### EPIC-15 (backup, import)
- **The importer is `resetAllTabStacks`'s other caller**, with
  `selectHome: true`. Add it to the list in `stack_reset_test.dart`.
- Call `showConfirmDeleteDialog` for delete-all.

### EPIC-16 (notifications)
- **Extend `lib/app/routing/deep_link.dart`; do not write a second
  `locationFor`.** Own the payload, its JSON and its validation; map onto
  `DeepLinkRequest`. `DeepLinkKind.wire` already holds §7's six strings.
- **Nothing calls `handleDeepLink` yet.** Wire the notification tap to it with
  `setActiveVehicle` and a router `go`/`push`. The order is its contract.

### EPIC-17 (accessibility)
- **5pt of inert tab bar** at the top and bottom of every tab slot (52 centred
  in 62). Meets Calm's floor; recorded as a design question.
- **The delete dialog shows its confirmation sentence twice** — as the field's
  label and as the disabled button's required explanation.
- The `ink3` / `focus` contrast findings from EPIC-02 are unchanged.

### EPIC-18 (parity sweep)
- **`kParityScreens` should read `kScreenRoutes`** in `lib/app/routing/routes.dart`
  rather than keeping a second list of screens.
- `test/parity/support/parity_capture.dart` is the capture harness: 390×844 @2x,
  status-bar and home-bar insets, `loadParityFonts`, a keyed boundary, and the
  `runAsync` file write. Reuse it; do not write a second one.

### Anyone writing a test
- `addTearDown` is LIFO: dispose the `ProviderContainer` BEFORE closing the
  database, or the file times out silently.
- A drift stream never delivers under `testWidgets` — ask database questions in
  a plain `test`.
- `test/data/support/rows.dart` now calls `markTablesUpdated`; a raw
  `customStatement` never invalidates a watching query.
- `OdovaRoot` needs a database. `pumpApp`'s `noLaunchGate()` is the escape.
- Every routing test goes through `test/app/routing/shell_harness.dart`.


---

## What `/simplify` and `/code-review` changed, and what the next epic inherits

Both passes ran before the PR, as CLAUDE.md §6 steps 7 and 8 require. Between
them they found nineteen real defects; the commits `simplify:` and
`code-review:` carry the full accounting. What outlives this epic:

### Rules the reviews established

- **A widget test cannot hold a live drift stream.** Ask database questions in a
  plain `test`; inject the answer into widget tests.
- **A "double" a function is never handed proves nothing.** If a function takes
  no side-effect port, assert THAT — over the signature and the imports.
- **A test that enumerates the cases it knows about cannot fail on the case
  nobody thought of.** Derive the set (from `kScreenRoutes`, from the ARB, from
  the router) rather than listing it.
- **`text.overflow` is null unless somebody set it**, so `isNot(ellipsis)` can
  never fail. Measure the rendered height instead.
- **`findsWidgets` means "at least one".** Count.

### Still open, for the epics that own them

- **EPIC-05 / EPIC-15: `migrationFailed` can never be true in a shipped build.**
  `appDatabaseProvider` constructs `AppDatabase()` directly;
  `openMigratedDatabase` — the safety copy, the snapshot, the rollback — has
  callers only in `test/migration/`, and nothing in `lib/` ever calls
  `DegradedModeController.migrationFailed`. So the launch gate's
  highest-priority branch is dead code in production: a failed migration
  surfaces as a query error, both streams fail, and the app opens on first run
  over a half-migrated database. The gate, its tests and its mutations are all
  correct; the WIRING is missing. **SPEC.md §14 *Migration fails on launch*
  depends on it.**
- **EPIC-09: `setActiveVehicle` now returns `Result<void, PersistFailure>`.**
  The switcher must show something when it is an `Err` — a silent failure closes
  the sheet on a vehicle that did not change.
- **EPIC-16: `handleDeepLink`'s `activateVehicle` is a `Future` and is awaited.**
  Pass `setActiveVehicle` directly; do not wrap it in a `void` callback.
- **EPIC-17: `CalmDialog`'s two-action constructor has no production caller.**
  All three global dialogs use `.actions`. Collapsing it would remove four
  nullable fields and two `!` de-references; it survives because it is the right
  shape for a dialog with no safe alternative, and because collapsing it
  re-baselines specimens.
- **EPIC-17: `CalmDialog` inserts a uniform gap before every `actions` element**,
  and the delete dialog passes a field and an explanation through that slot with
  a one-token nudge. A `content` slot with its own spacing is the real fix.
