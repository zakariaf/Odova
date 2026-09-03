# EPIC-08 — App shell, navigation and the global dialogs

| | |
|---|---|
| **Epic** | EPIC-08 — App shell, navigation and the global dialogs |
| **Depends on** | EPIC-03, EPIC-07 |
| **Estimate** | **9 h (CC) · ~9 weeks (human)** over 10 tasks |
| **Spec sections** | §7 *Screen map and navigation* — in full: the screen list, the tab bar, the active vehicle, the navigation graph, the notification deep links, *After an import*, *One editor per thing* · §2 *Non-negotiables* (`start`/`end` only, one ICU message per sentence, storage is canonical) · §9 *Home* (what Home requires of the shell: the vehicle title, the deep-link landing, the re-tap) |
| **Screens** | `dialog.discard`, `dialog.confirmDelete`, `dialog.snooze` |

§7 is cited by ten epics and until now was owned by none. EPIC-01 deferred the router in a
single parenthesis — *"`MaterialApp` (router wiring lands in the navigation epic)"* — and the
navigation epic did not exist, so `go_router` is in no `pubspec.yaml`, there is no tab bar, no
navigation graph, no modal convention and no deep link. Everything from EPIC-09 on assumes a
shell to attach a screen to. **This epic is that shell.**

It builds almost no product surface of its own. What it produces is a place to put the other
twenty-five screens, a set of rules about how you get between them, and the three dialogs §7
groups together because they belong to no feature: `dialog.discard`, `dialog.confirmDelete`
and `dialog.snooze`. Those three are the only referenced screens here, and they are gated like
any other.

The rules every epic inherits — TDD without exception, tests run per task, `/simplify` then
`/code-review` at the end, a screen is not done until it matches its reference, `SPEC.md` wins
— are stated once in `epics/README.md` and are binding here.

---

## Where we are now

The repo before EPIC-01 held `SPEC.md`, the design systems, the Calm reference PNGs under
`design/reference/calm/`, `tools/` and `.claude/skills/`, and **no Flutter app at all** — no
`pubspec.yaml`, no `lib/`. EPIC-01 created it; everything since inherits it.

At the moment this epic starts:

- `pubspec.yaml`, `lib/`, `test/` exist; `flutter analyze --fatal-infos --fatal-warnings` is
  clean and `flutter test` is green. `lib/` holds the seven directories EPIC-01 fixed —
  `app/`, `core/`, `data/`, `features/`, `l10n/`, `theme/`, `ui/` — and `test/policy/structure_test.dart`
  asserts there is no eighth. `lib/main.dart` installs two error handlers and awaits
  `bootstrap()`; `lib/app/app.dart` builds a **`MaterialApp`, not `MaterialApp.router`**, and
  its home is a placeholder showing `AppLocalizations.of(context).appTitle`.
  `lib/app/lifecycle_observer.dart` exists with nothing to flush.
- The Calm theme is in `lib/theme/calm/` (EPIC-02): `CalmColors`, `CalmType`, `CalmSpace`,
  `CalmShapes`, `CalmMotion`, and `calm_status.dart` with the one `DueState` / `DueDriver` /
  `CalmStatusStyle`.
- **EPIC-03 delivered `lib/ui/calm/`** — and this epic is its first real consumer.
  `CalmScaffold` (fixed metrics `appbarH` 56, `tabbarH` 62, `homebarH` 34), `CalmAppBar` in
  its four shapes including `vehicle` and `modal`, **`CalmTabBar` — 62 tall, five equal slots,
  the 62pt `+` pulled 18pt above the bar, order mirroring under RTL with the `+` staying
  centred** — plus `CalmSheet` with its `show<T>()` entry point, `CalmDialog`, `CalmSnackbar`,
  `CalmRowGroup`/`CalmListRow`, `CalmField`, `CalmButton`, `CalmStatusDot`. This epic
  *composes* those. A `BoxDecoration` or a raw colour in `lib/app/routing/` is a review
  failure.
- **EPIC-04 delivered the six-locale ARB pipeline** — `l10n.yaml`, `gen_l10n`, `en de fr fa ar
  ckb`, the numeral and calendar display transforms, and the FSI/PDI isolate helper. It is not
  in this epic's declared dependency row and it must be, because every string in the three
  dialogs is an ARB key and the tab labels are five more (finding F-8.7).
- **EPIC-05 delivered persistence**: the §3 entities as Drift tables, forward-only migrations,
  and repositories that are the single write path with `.watch` streams. The `Settings`
  singleton row (`id = "settings"`) exists and carries `active_vehicle_id` and
  `onboarding_done`; `SettingsRepository` is real.
- **EPIC-06** delivered canonical units, `Money`, the zoneless `CivilDate` with `addMonths`
  clamping to the last day of the target month, and the injected `Clock`. The snooze dialog's
  three date options are `CivilDate` arithmetic and nothing else.
- **EPIC-07** delivered the pure due engine — `estimateOdometer`, `computeDueState`,
  `projectDueDate`, `nextDue`, `dueSummary`. This epic reads none of it directly; the snooze
  dialog is handed an odometer figure by its caller rather than computing one.

Deliberately still missing when this epic starts, and still missing when it ends:

- **Every feature screen.** There is no `home`, no `history`, no `costs`, no `settings`, no
  first run, no garage, no `log.*`. This epic registers all twenty-five of them as routes with
  **named placeholders** so the graph is complete and testable, and each later epic replaces
  its own placeholder. A test in task 8.1 asserts every `data-screen` id in
  `design/calm/screens.html` resolves; it does not assert what the destination renders, because
  nothing renders yet.
- **`VehicleRepository`.** EPIC-09 task 9.1 writes it. The launch gate here needs a live
  vehicle count, so task 8.6 defines one `liveVehicleCountProvider` over EPIC-05's vehicles
  table and EPIC-09 re-points it at `VehicleRepository.watchGarage()` — one provider, one
  query path, never a second count.
- **Notification scheduling.** EPIC-16 owns `flutter_local_notifications`, the gateway port,
  the payload type and the whole scheduler. This epic owns the *landing*: the pure
  payload-fields → location mapping and the synthesised back stacks of §7. Task 8.7 defines
  the seam; EPIC-16 calls it.
- **Anything that writes.** The three dialogs return a choice and persist nothing. Discard
  drops drafts the caller owns; delete is performed by the caller; snooze fields are written by
  EPIC-16's `complete`/snooze path. A repository call from `lib/ui/dialogs/` is a review
  failure.

## What we will have when this is done

- `flutter run` opens the app on a working shell: four tabs — **Home · History · [+] · Costs ·
  Settings** — with the docked `+` in the centre slot, each tab keeping its own stack across
  switches, and in a Persian build the whole bar mirrored with the `+` still centred.
- Every one of the 28 screen ids in `design/calm/screens.html` is addressable. `Routes.home` is
  `/`, `Routes.costsFuel` is `/costs/fuel`, `Routes.vehicleEdit('veh_01J…')` is
  `/settings/vehicles/veh_01J…`, and an unknown URL lands on a designed 404 rather than a red
  box.
- The four kinds of §7 behave differently and visibly: a **push** keeps the tab bar and gets a
  back button; a **modal** covers it and has one exit; a **sheet** is partial-height and
  tap-out dismissible; a **dialog** is blocking with at most two decisions. Dismissing a dirty
  modal opens `dialog.discard`; dismissing a clean one is silent — one implementation, shared
  by every modal in the app.
- Tapping a notification lands where §7's table says, with `activeVehicleId` set *before* the
  route resolves, and Back from a deep-linked modal reaching Home rather than the launcher.
- `bash .claude/skills/navigation-and-routing/scripts/check_routing.sh` is clean, and
  `flutter test test/app/routing/` is green — including one test per row of §7's launch table
  and one per row of its deep-link table.
- `bash .claude/skills/calm-visual-parity/scripts/check_parity.sh` reports the three dialogs
  matching in all four combinations, and the side-by-side sheets in `design/reference/_parity/`
  have been opened and looked at.
- `grep -rn "Navigator.push\|Navigator.pushNamed\|WillPopScope" lib/` returns nothing, and
  `grep -rn "GoRouter(" lib/ | grep -v app/routing/app_router.dart` returns nothing.

## Skills to load

Open `flutter-conventions-index` first — it is the front door and it routes the rest.

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The house rules every task inherits: feature-first layering, dumb widgets, one Notifier per screen, single write path, injected `Clock`, typed failures. |
| `navigation-and-routing` | **The governing skill of this epic.** One `GoRouter`, identity in path params and never `state.extra`, `go` versus `push`, pure `redirect` with a `refreshListenable`, `StatefulShellRoute.indexedStack` for the tab shell, `CustomTransitionPage` respecting reduced motion, `PopScope` for unsaved changes, and a real `errorBuilder`. |
| `app-startup-and-bootstrap` | Where `MaterialApp.router` is mounted and in what order. The launch gate reads settings **before** `runApp` so frame one is the right screen — a flash of Home before a redirect to first run is a visible defect, not a cosmetic one. |
| `state-management-riverpod` | `routerProvider`, the `activeVehicleIdProvider` the whole app scopes on, and the Riverpod→`Listenable` bridge the router's `refreshListenable` needs. |
| `calm-components` | `CalmTabBar`, `CalmScaffold`, `CalmSheet.show<T>()`, `CalmDialog`, `CalmSnackbar` — and the substitution table that forbids `NavigationBar`, `showModalBottomSheet`, `AlertDialog` and `showDialog`'s Material default anywhere in this epic. |
| `calm-visual-parity` | **Required.** Three referenced screens × four combinations = 12 gates. It is also why no task here tells anyone to chase a pixel diff to zero: the reference is Chrome and the app is Skia, 25–45% of pixels differ on a correct screen, and what is decided mechanically is theme, Calm-token colour and the horizontal band profile. |
| `calm-typography-and-rtl` | The tab bar mirrors and the `+` does not; the six directional glyphs (the back chevron among them); German and Sorani tab labels wrapping rather than truncating; the vehicle name and the odometer figure inside bidi isolates in the dialog titles. |
| `ui-states-and-feedback` | The surface ladder — inline, snackbar, banner, dialog — and the rule that a modal is earned only by a decision that must resolve now. It also owns `showDialog`'s null dismissal as its own outcome, which is exactly §7's "tap-outside and system back are always the negative action". |
| `local-notifications-scheduler` | Only its payload contract: three fields, serialisable, mapped to a location by a pure function. This epic writes that function and nothing else from the skill; the gateway, the scheduler and `tz.local` are EPIC-16's. |

---

## Tasks

### Task 8.1 — Register every screen: the route table, the single router and the 404

- **Goal** — every screen in `SPEC.md` §7 has a URL, one router owns all of them, and an unknown link lands somewhere designed.
- **Spec** — §7 *Screen map and navigation → Screen list* (all 23 ids plus the three dialogs, plus the two firstRun references); §7 *Shape of the app in one look* (no stack more than two pushes deep).
- **Skills** — `navigation-and-routing`, `app-startup-and-bootstrap`, `state-management-riverpod`, `flutter-conventions-index`.
- **Write these tests first** — `test/app/routing/route_table_test.dart`:
  - `every data-screen id in design/calm/screens.html is in kScreenRoutes` — the test reads the design file, extracts the 28 ids with a regex, and asserts the map covers all 28 with no extras. Fails the day a designer adds an artboard nobody routed.
  - `every route in kScreenRoutes resolves to a non-error match` — walks the map and asserts `router.configuration.findMatch(location)` produces a match whose last route is not the error route. A typo in a path is caught here, not in a feature epic three months later.
  - `the three global dialogs are declared as dialogs, not as locations` — `dialog.discard`, `dialog.confirmDelete` and `dialog.snooze` map to `ScreenRoute.dialog(id)` and have no URL. A dialog returns a decision to its caller; a URL cannot carry one back, and a deep link into "discard changes?" is meaningless. These three are the **only** ids allowed on that side of the map and the test names them.
  - `no path is more than two segments deep below its tab root` — §7's architectural limit, asserted over the table so a third push is a red test rather than a design review comment.
  - `an id-bearing route reads its id from pathParameters` — `/settings/vehicles/:vehicleId`, `/reminders/:reminderId`, `/costs/trips/:tripId`, `/log/:type/:entryId`: each builder is called with a synthetic match and asserted to read `state.pathParameters`, never `state.extra`. A cold start from a deep link has a null `extra`.
  - `an unknown location renders the error screen and not a red box` — `/nope` lands on `RouteNotFoundScreen`.
  - `the error screen offers one way back to Home` — a dead end is worse than a wrong turn.
  - `there is exactly one GoRouter in lib/` — a grep policy test over `lib/**`, in the shape EPIC-01's `test/policy/` tests already use.
- **Then build** — `lib/app/routing/routes.dart` and `lib/app/routing/app_router.dart`.

  `abstract final class Routes` holds a `static const` per fixed location and a `static String`
  builder per id-bearing one:

  ```
  /                              home                  (tab 1 root)
  /vehicle-switcher              vehicle.switcher      (sheet)
  /reminders                     reminders.list
  /reminders/:reminderId         reminders.edit        (modal; /reminders/new to create)
  /log/:type                     log.fillup|service|expense|odometer   (modal)
  /log/:type/:entryId            the same four in edit mode
  /history                       history               (tab 2 root)
  /history/report                report.service
  /costs                         costs                 (tab 3 root)
  /costs/fuel                    costs.fuel
  /costs/trips                   trips.list
  /costs/trips/:tripId           trips.edit            (modal)
  /costs/history                 history, the filtered instance inside the Costs stack
  /settings                      settings              (tab 4 root)
  /settings/vehicles             vehicles
  /settings/vehicles/:vehicleId  vehicle.edit          (modal; /new to create)
  /settings/language             settings.language
  /settings/units                settings.units
  /settings/notifications        settings.notifications
  /settings/backup               settings.backup
  /settings/backup/import        settings.import       (modal)
  /settings/about                settings.about
  /first-run/language            firstrun.language
  /first-run/vehicle             firstrun.vehicle
  ```

  `/costs/history` is a second `history` instance, deliberately: §7 says a cross-tab data jump
  pushes into the **current** tab and the app never switches tabs under the user's finger.

  `const Map<String, ScreenRoute> kScreenRoutes` maps every `data-screen` id to either
  `ScreenRoute.location(path)` or `ScreenRoute.dialog(id)`. It is the single registry, and
  EPIC-18's `kParityScreens` reads it rather than keeping a second list.

  `app_router.dart` holds the only `GoRouter(...)` in the app, behind `routerProvider`, with
  `errorBuilder` → `lib/app/routing/route_not_found_screen.dart` (a `CalmScaffold`, a
  `CalmAppBar`, one sentence and one `CalmButton` back to Home). Every destination that a later
  epic owns is registered now as `PlaceholderScreen(screenId: …)` — one widget, naming its own
  id on screen, so a wrong route is obvious in a manual run.

  **Routing lives in `lib/app/routing/`, not `lib/routing/`.** EPIC-01 folded the router into
  `lib/app/` and its structure test asserts `lib/` has exactly seven directories; a top-level
  `lib/routing/` fails that test. Tests mirror it at `test/app/routing/` (finding F-8.5).

  Add `go_router` to `pubspec.yaml` at an exact caret range, and run EPIC-01's dependency gate
  over it — `go_router` opens no network and must pass unchanged.
- **Verify**
  ```bash
  flutter pub get
  flutter test test/app/routing/route_table_test.dart
  bash .claude/skills/navigation-and-routing/scripts/check_routing.sh
  bash tools/check_dependencies.sh          # go_router passes the no-network policy
  flutter analyze --fatal-infos --fatal-warnings
  ```
  A pass is 8 green tests and a clean routing script. Then delete one entry from
  `kScreenRoutes` by hand and confirm the coverage test goes red naming the missing id;
  restore it.
- **Done when**
  - [ ] All 28 `data-screen` ids are covered by `kScreenRoutes`, proven by a test that reads the design file rather than a hand-copied list.
  - [ ] Every location resolves; every id-bearing route reads `pathParameters`.
  - [ ] No stack is more than two pushes deep, asserted over the table.
  - [ ] Exactly one `GoRouter` exists in `lib/`, in `lib/app/routing/app_router.dart`.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 8.2 — Build the shell: four tab roots and the docked central `+`

- **Goal** — the app has a frame: four tabs that each keep their own stack, and a `+` in the middle that opens the log modal from anywhere.
- **Spec** — §7 *Tab bar* (why four, why `+` is a button and not a fifth tab, why it sits in the centre slot rather than floating, labels always visible, RTL); §7 *Shape of the app in one look*.
- **Skills** — `navigation-and-routing`, `calm-components`, `calm-typography-and-rtl`, `state-management-riverpod`, `app-startup-and-bootstrap`.
- **Write these tests first** — `test/app/routing/app_shell_test.dart`:
  - `the shell has exactly four branches, rooted at home, history, costs and settings` — asserts the `StatefulShellRoute`'s branch count and each branch's initial location. Fails if anyone adds a fifth.
  - `the + is not a branch` — walks the shell's branches and asserts none is rooted at a `log.*` location. §7: a tab is a place you can be; logging is an act that finishes and returns you.
  - `tapping + pushes log.fillup as a modal from every one of the four tabs` — four cases, each asserting the resulting location is `/log/fillup` and that the tab bar is **not** in the tree afterwards.
  - `the + opens on the Fill-up segment` — the default segment, asserted as the route's `type` parameter, not as a widget state.
  - `each branch keeps its own stack across a tab switch` — push `/settings/units`, switch to History, switch back, and assert the location is still `/settings/units`. This is the whole reason for `indexedStack`.
  - `the tab bar renders five slots in the order home, history, +, costs, settings` — a `getRect` sweep left to right in LTR.
  - `the tab order mirrors in RTL and the + stays at the horizontal centre` — the same sweep under `Directionality.rtl`: Settings is leftmost and the `+`'s centre is within a pixel of the frame's centre. §7 states both halves and they fail independently.
  - `labels are always visible under the icons` — no icon-only mode exists to fall into.
  - `German and Sorani labels wrap to two lines rather than truncating` — pump `de` and `ckb` at text scale 1.3 and assert no `TextOverflow.ellipsis` and no clipped slot.
  - `the active tab is signalled by colour and weight together` — `brand` + semi, so the bar survives a grayscale render.
  - `every tab item and the + report a hit area of at least 52` — including where the `+` overhangs the bar.
  - `MaterialApp.router is mounted exactly once` — a widget test over `App`, plus a grep test asserting `MaterialApp(` no longer appears in `lib/app/app.dart`.
- **Then build** — `lib/app/routing/app_shell.dart` (`AppShell`, a `StatefulNavigationShell`
  consumer composing `CalmTabBar` with four `labels` and the `+`), and the
  `StatefulShellRoute.indexedStack` in `app_router.dart` with one `StatefulShellBranch` per
  tab. Branch switching is `navigationShell.goBranch(index)`; the `+` is `context.push` of
  `Routes.log(LogType.fillup)` on the **root** navigator, which is what makes it cover the tab
  bar.

  Then rewrite `lib/app/app.dart` to `MaterialApp.router` reading `routerProvider`, keeping the
  localizations delegates and the Calm themes exactly as they are. EPIC-01's placeholder home
  is deleted here — this is the epic its parenthesis was waiting for.
- **Verify**
  ```bash
  flutter test test/app/routing/app_shell_test.dart
  bash .claude/skills/calm-layout-and-motion/scripts/check_touch_targets.sh lib test
  bash .claude/skills/calm-design-system/scripts/check_calm_layering.sh lib
  flutter run                       # four tabs, a centred +, and Home's placeholder under it
  ```
  A pass is 12 green tests, and a manual run where switching tabs and coming back leaves you
  exactly where you were.
- **Done when**
  - [ ] Four branches, four stacks, state preserved across switches by `indexedStack`.
  - [ ] The `+` is a root-navigator push, not a branch, and opens on Fill-up from all four tabs.
  - [ ] Order mirrors under RTL and the `+` stays centred, asserted by geometry.
  - [ ] `MaterialApp.router` is mounted once and EPIC-01's placeholder home is gone.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 8.3 — Tab-root behaviour, back, and the two stack resets

- **Goal** — the back button and a second tap on the current tab do what §7 says, everywhere, including under a deep link.
- **Spec** — §7 *Tab bar → Tab-root behaviour*, *All stacks reset to their roots*; §7 *After an import*; §9 *Home → Interactions* (re-tap Home scrolls to top).
- **Skills** — `navigation-and-routing`, `state-management-riverpod`, `flutter-conventions-index`.
- **Write these tests first** — `test/app/routing/tab_behaviour_test.dart`:
  - `re-tapping the active tab pops to its root` — from `/settings/units`, tapping Settings lands on `/settings`.
  - `re-tapping a tab already at its root scrolls it to top and does not navigate` — the location is unchanged and the branch's `ScrollController` reports offset 0. Both halves of §7's sentence, and they are two different failures.
  - `Android system back on a non-Home tab root goes to the Home tab` — from `/history`, `/costs` and `/settings`, three cases, each landing on `/` with the Home tab selected.
  - `Android system back on home exits the app` — asserts `didPop` is allowed to reach the platform rather than being swallowed.
  - `Android system back inside a branch pops that branch, not the app` — from `/costs/fuel`, back lands on `/costs`.
  - `a deep-link-synthesised stack obeys the same back rule` — land on `/settings/backup` by deep link, press back twice: `/settings`, then the Home tab. §7 says the synthesised stack obeys the tab rule and does not get its own.
  - `test/app/routing/stack_reset_test.dart`:
  - `switching the active vehicle resets all four tab stacks to their roots` — push a child into all four branches, switch vehicle, assert all four locations are the roots.
  - `an import resets all four tab stacks and selects the Home tab` — §7's `settings.import` → `home` row.
  - `nothing else resets a stack` — a table-driven test over every other write the app makes today (a settings change, a locale change, a snooze): none of them touches a branch stack. This is the test that stops a reset being scattered per caller.
  - `changing the language keeps the whole navigation state` — §7's `settings` row: it re-renders in place and flips direction if needed. Push three deep, change to `fa`, assert the location and the branch index are unchanged and `Directionality` is now `rtl`.
- **Then build** — `lib/app/routing/tab_stack_reset.dart` with a single
  `void resetAllTabStacks(Ref ref, {required bool selectHome})`, called by **exactly two**
  events, and a policy test that greps for its call sites and asserts there are two. Back
  handling is one `PopScope` on the shell (`navigation-and-routing` rule 10 — never
  `WillPopScope`), reading the branch index and the branch's stack depth.

  Re-tap is `navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex)`
  for the pop, plus a `tabReselectedProvider` tick the root of each branch listens to for the
  scroll-to-top. Home's own `ScrollController` is EPIC-10's; the tick is the seam, and this
  task's test asserts the tick fires rather than that Home scrolled.
- **Verify**
  ```bash
  flutter test test/app/routing/tab_behaviour_test.dart test/app/routing/stack_reset_test.dart
  grep -rn "resetAllTabStacks" lib/ | grep -v tab_stack_reset.dart    # exactly two call sites
  ```
- **Done when**
  - [ ] Every sentence of §7's *Tab-root behaviour* paragraph has its own named test.
  - [ ] `resetAllTabStacks` has one implementation and exactly two callers, proven by grep.
  - [ ] A language change is proven not to reset anything.
  - [ ] No `WillPopScope` anywhere in `lib/`.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

---

### Task 8.4 — The four page kinds, and the dismissal contract

- **Goal** — push, modal, sheet and dialog are four visibly different things with four different exits, defined once instead of re-decided per screen.
- **Spec** — §7 *Screen list* (the `kind` paragraph: "binding and not restated in the edge tables below"); §7 *Navigation graph* (the two rules that hold everywhere); §7 *Global dialogs* (tap-outside and system back are always the negative action).
- **Skills** — `navigation-and-routing`, `calm-components`, `ui-states-and-feedback`, `state-management-riverpod`.
- **Write these tests first** — `test/app/routing/page_kinds_test.dart`:
  - `a push keeps the tab bar and gets a back button` — `/costs/fuel` still has `CalmTabBar` in the tree and a `CalmAppBar` leading control.
  - `a modal covers the tab bar` — `/log/fillup` has no `CalmTabBar` in the tree. This is the mechanical difference, and it is produced by the modal being a root-navigator route, not by a flag on the screen.
  - `a modal is dismissible by swipe-down and by system back, and both are the same event` — two pumps, one assertion each, both routed through the same `onDismiss` callback. §7: "Dismiss means swipe-down, Cancel or system back — all three are one event."
  - `a sheet is partial height and dismisses on tap-out` — the sheet's top edge is below the frame's top, and a tap on the scrim pops it.
  - `a dialog is blocking: tap-out and system back both return the negative outcome` — `showDialog`'s null result is mapped to the negative decision explicitly, never to `Cancel`-by-accident. `ui-states-and-feedback` rule: a null dismissal is its own outcome.
  - `no dialog can be dismissed into a destructive outcome` — a table test over the three dialog builders asserting the value returned on barrier dismissal is never the destructive branch.
  - `dismissing a dirty modal opens dialog.discard` and `dismissing a clean one is silent` — against a `_ProbeModal` fixture with a settable dirty flag, exercised through all three dismissal gestures. Six cases.
  - `a modal that saves returns to the exact screen it was opened from` — open `/log/fillup` from `/costs/fuel`, save, assert the location is `/costs/fuel` again.
  - `a modal that saves restores the caller's scroll position` — the same fixture with the caller scrolled to offset 900; §7 promises the position, not only the screen.
  - `transitions collapse to Duration.zero under disableAnimations` — all four kinds, per `navigation-and-routing` rule 9 and `calm-components`' exit-motion rule.
  - `a modal stacked over a sheet dismisses both on save` — the `vehicle.switcher` → `vehicle.edit` edge of §7, asserted here as a mechanism so EPIC-09 does not have to invent it.
- **Then build** — `lib/app/routing/page_kinds.dart`: four `Page` factories over
  `CustomTransitionPage` — `calmPushPage`, `calmModalPage`, `calmSheetPage`, `calmDialogPage` —
  each reading `CalmMotion` for its curve and duration and collapsing to zero under
  `MediaQuery.disableAnimationsOf`. Modals and sheets carry
  `parentNavigatorKey: rootNavigatorKey`; pushes do not, which is precisely what keeps the tab
  bar under a push and hides it under a modal.

  Then `lib/app/routing/dirty_modal_guard.dart`: a `DirtyModalGuard` widget wrapping a modal's
  body, holding a `PopScope(canPop: false, onPopInvokedWithResult: …)`, and calling
  `showDiscardDialog` from task 8.8 when its `isDirty` callback returns true. Every modal in
  the app wraps in this one widget; a second `PopScope` in a feature is a review failure and a
  grep test says so.
- **Verify**
  ```bash
  flutter test test/app/routing/page_kinds_test.dart
  grep -rn "PopScope" lib/features/                     # empty — the guard owns it
  grep -rn "showModalBottomSheet\|showDialog(" lib/ | grep -v ui/calm/ | grep -v ui/dialogs/
  ```
  The last grep is empty: features reach for `CalmSheet.show<T>()` and the three dialog
  builders, never the Material entry points.
- **Done when**
  - [ ] The four kinds differ mechanically, and the modal/tab-bar difference is proven by tree membership rather than by a flag.
  - [ ] All three dismissal gestures route through one event, asserted for each.
  - [ ] The dirty guard has one implementation, and `lib/features/` contains no `PopScope`.
  - [ ] Every transition collapses to zero under reduced motion.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 8.5 — The active vehicle, and never taxing the one-car user

- **Goal** — one app-wide active vehicle that scopes three tabs, and a multi-vehicle feature that is invisible until a second vehicle exists.
- **Spec** — §7 *Active vehicle* (all six bullets); §9 *Home → Interactions* (title with one vehicle is not a tap target); §3 *Scope: global vs per vehicle*.
- **Skills** — `state-management-riverpod`, `navigation-and-routing`, `calm-components`, `flutter-conventions-index`.
- **Write these tests first** — `test/app/active_vehicle_test.dart`:
  - `activeVehicleId is read from Settings on launch and is not re-derived` — one persisted field, restored, per §7.
  - `setting the active vehicle writes exactly one Settings field` — nothing else is touched, and the write goes through `SettingsRepository`.
  - `setting the active vehicle resets all four tab stacks` — calls task 8.3's single function; asserted by the reset test double, not by re-implementing the reset.
  - `with one vehicle showsVehicleSwitcher is false` — and the `vehicle.switcher` route is unreachable: navigating to it with one vehicle redirects to `home` rather than opening an empty sheet.
  - `with one vehicle the app-bar title is plain text with no chevron and no "1 of 1"` — a widget test over `CalmAppBar.vehicle` with the chevron callback null, which is the shape EPIC-03 already built for this.
  - `with two vehicles the title becomes a tappable 52pt control with a chevron`.
  - `selection happens only in vehicle.switcher or via a deep link` — a policy test: `grep` for writers of `active_vehicle_id` across `lib/` and assert the set is exactly the switcher's notifier and the deep-link handler. §7 is explicit that `vehicles` under Settings never switches.
  - `the costs tab's All vehicles toggle never changes activeVehicleId` — the one exception in §7, asserted as an absence: the toggle's provider is a separate, tab-scoped flag.
  - `deleting the active vehicle promotes the next by sort_order` and `deleting the last leaves it null and routes to firstrun.vehicle` — asserted as route intent; EPIC-09 owns the delete itself.
- **Then build** — `lib/app/active_vehicle.dart`: `activeVehicleIdProvider` (a `Notifier<String?>`
  over `Settings.active_vehicle_id`), `showsVehicleSwitcherProvider` (`liveVehicleCount >= 2`),
  and `setActiveVehicle(String id)` which writes the field and calls `resetAllTabStacks`. The
  switcher redirect goes into the router's `redirect` as one more pure clause, not as a check
  inside the sheet.

  The `costs` All-vehicles toggle is declared here as `costsAllVehiclesProvider`, scoped to that
  branch and explicitly *not* persisted into `Settings`, so EPIC-13 inherits the decision rather
  than making it again.
- **Verify**
  ```bash
  flutter test test/app/active_vehicle_test.dart
  grep -rn "active_vehicle_id\|activeVehicleId" lib/ | grep -v app/active_vehicle.dart
  ```
  The grep lists readers only; the two writers named in the policy test are the sole exceptions.
- **Done when**
  - [ ] One persisted field, one setter, and a proven-by-grep list of writers.
  - [ ] The one-vehicle case has no switcher, no chevron and no reachable route.
  - [ ] The Costs All-vehicles toggle is proven not to touch the active vehicle.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

---

### Task 8.6 — The launch-state gate

- **Goal** — every way the app can open lands on the right screen, on the first frame, without a flash of the wrong one.
- **Spec** — §7 *Navigation graph → Launch and first run* — the whole table, which §7 calls "the launch-state contract: every way the app can open is a row here"; §7 *After an import*; §2 *Data survives app updates*.
- **Skills** — `app-startup-and-bootstrap`, `navigation-and-routing`, `state-management-riverpod`, `ui-states-and-feedback`.
- **Write these tests first** — `test/app/routing/launch_gate_test.dart`, one case per §7 row. The gate is a pure function, so these run against `appRedirect(LaunchFacts, GoRouterState)` and not against a pumped app:
  - `no prior run redirects to firstrun.language`.
  - `onboarding done with one or more vehicles allows home` — and returns `null`, not a redirect to `/`, so the gate cannot loop.
  - `onboarding done with zero vehicles redirects to firstrun.vehicle and never back to the language step` — §7: "Language is already chosen; do not ask again."
  - `a failed migration redirects to settings.backup regardless of vehicle count` — §7's app-update row: the data must be able to leave the building before anything else is attempted. Asserted with the banner flag set, so EPIC-15 renders it.
  - `a failed migration outranks the first-run redirect` — a corrupt install with no vehicles goes to Backup, not to first run, because first run's Start button would write into a broken database.
  - `the gate never redirects a location to itself` — a property test over every location in `kScreenRoutes` × every `LaunchFacts` combination: no fixed point, no `A→B→A` pair. `navigation-and-routing` rule 7.
  - `the gate is pure` — called twice with the same facts it returns the same answer and performs no read; the test passes a `LaunchFacts` record and a repository double that fails the test if touched.
  - `launch always selects the Home tab, never the last-used tab` — §7's reasoning is in the spec and the test name says it: sessions are days apart.
  - `modal state is never restored across a cold start` — a persisted location of `/log/fillup` opens on `/`.
  - `a firstRun import routes to home with onboarding_done set by the import` — not read from the file.
  - `test/app/bootstrap_launch_test.dart`:
  - `the first frame is the destination screen, not Home followed by a redirect` — `LaunchFacts` are read inside `bootstrap()` before `runApp` and passed into the router's `initialLocation`. A flash of Home before first run is a visible defect (`app-startup-and-bootstrap` rule 5), so this test pumps one frame and asserts the destination directly.
  - `the router refreshes when onboarding_done or the vehicle count changes` — the `refreshListenable` bridge fires and the gate is re-evaluated; asserted by completing first run in a pumped app and watching the redirect release.
- **Then build** — `lib/app/routing/launch_gate.dart`:
  `String? appRedirect(LaunchFacts facts, GoRouterState state)` over
  `LaunchFacts({required bool onboardingDone, required int liveVehicleCount, required bool migrationFailed})`,
  wired as the router's `redirect` with a `ValueNotifier` `refreshListenable` bridged from
  Riverpod (`navigation-and-routing` rule 6). `bootstrap()` gains one synchronous read that
  produces the initial `LaunchFacts` and hands the router its `initialLocation`.

  `liveVehicleCountProvider` is defined here as a `Stream<int>` over EPIC-05's vehicles table.
  **EPIC-09 re-points it at `VehicleRepository.watchGarage()` and deletes the direct query** —
  one line, recorded in this epic's progress file so EPIC-09 finds it.
- **Verify**
  ```bash
  flutter test test/app/routing/launch_gate_test.dart test/app/bootstrap_launch_test.dart
  flutter analyze --fatal-infos --fatal-warnings
  ```
  A pass is one green test per row of §7's launch table plus the two purity/loop properties.
  Then run the app with a wiped database and confirm the first painted frame is the language
  screen's placeholder, not Home.
- **Done when**
  - [ ] Every row of §7's launch-and-first-run table has a named test.
  - [ ] The gate is pure, loop-free and proven so by a property test over the whole route table.
  - [ ] The first frame is the destination; there is no visible redirect.
  - [ ] `liveVehicleCountProvider` exists in one place and its EPIC-09 replacement is written down.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 8.7 — Notification deep links, and the seam EPIC-16 calls

- **Goal** — a tapped notification lands where §7's table says, for all six payload kinds, including when the thing it names is gone.
- **Spec** — §7 *Notification deep links* (the table and the four bullets under it); §9 *Home → From a notification*; §4 *Reminders and notifications → The payload* (the three fields; the payload type itself is EPIC-16's).
- **Skills** — `navigation-and-routing`, `local-notifications-scheduler`, `state-management-riverpod`, `error-handling-typed-results` *(via the conventions index's routing table)*.
- **Write these tests first** — `test/app/routing/deep_link_test.dart`. These are pure-function tests over `locationFor` plus a small set of pumped cases for the ordering rules:
  - `reminder.due lands on home` and `reminder.overdue resolves to the same location` — two kinds, one destination.
  - `a reminder link sets activeVehicleId before the route resolves` — asserted on **order**, not on end state: the fake router records the sequence, and a vehicle set after the route is a failing test. It is the same hazard as the nudge below and it fails silently on device.
  - `a reminder link pins the target card and highlights it for about two seconds` — asserted as a `pinnedReminderId` handed to the Home route, with a 2 s expiry; Home renders it in EPIC-10.
  - `a reminder link opens no modal` — §7's last bullet: a lock-screen tap is often exploratory, and a prefilled form one thumb-slip from Save is a data-integrity hazard.
  - `reminder.grouped sets the vehicle and pins no card`.
  - `odometer.nudge sets the vehicle first, then opens log.odometer prefilled with the last reading and today` — the order assertion again: setting the vehicle after the modal opens prefills the wrong car.
  - `odometer.nudge never opens vehicle.switcher` — §7 says so explicitly, because a nudge that asks "which car?" has failed at its one job.
  - `keeper lands on home and leaves activeVehicleId untouched`.
  - `backup.nudge lands on settings.backup with Export focused, and Back walks out through Settings` — the synthesised stack is `[home, settings, settings.backup]`, and the test asserts it falls out of the path hierarchy plus task 8.3's tab rule rather than being hand-assembled.
  - `every other kind synthesises a [home] back stack` — five cases.
  - `back from a deep-linked modal lands on home, never out of the app` — pumped: land on `log.odometer` by nudge, press system back, assert the location is `/` and the app did not pop to the platform.
  - `a payload naming a deleted vehicle lands on plain home for the current active vehicle, with no error surface` — and the test asserts **no** snackbar, banner or toast was shown. §7: no error for something the user already dealt with.
  - `a payload naming a deleted reminder lands on plain home and pins nothing`.
  - `a cold start from a notification never shows onboarding` — §7's bullet: a notification cannot exist unless a vehicle exists, so the launch gate must not fire over it.
  - `an unknown kind is a typed failure, never a default route` — an app-update-stale payload is refused; `locationFor` returns `Err`, and the caller drops it silently.
- **Then build** — `lib/app/routing/deep_link.dart`:

  ```dart
  enum DeepLinkKind { reminderDue, reminderOverdue, reminderGrouped, odometerNudge, keeper, backupNudge }

  final class DeepLinkRequest {
    final DeepLinkKind kind;
    final String vehicleId;
    final String? reminderId;   // present only on reminderDue and reminderOverdue
  }

  Result<DeepLinkTarget, DeepLinkFailure> locationFor(DeepLinkRequest request, DeepLinkFacts facts);
  ```

  `DeepLinkTarget` carries the location, the vehicle to activate, and an optional
  `pinnedReminderId`. `DeepLinkFacts` carries whether the named vehicle and reminder still
  exist, so the "deleted" rows of the table are decided by a pure function rather than by a
  repository call inside a router.

  `handleDeepLink(Ref, DeepLinkRequest)` is the seam: it applies the vehicle, then navigates,
  in that order, and is the **only** entry point. **EPIC-16 owns the payload** — the sealed
  `NotificationPayload`, its JSON round-trip and its per-kind `reminderId` validation — and maps
  it onto `DeepLinkRequest` at the boundary. EPIC-16 task 16.3 currently plans to write
  `lib/routing/notification_deep_link.dart` itself; it extends and gates this file instead
  (finding F-8.3), and its own deep-link tests still hold — a function that already exists
  should still pass them.
- **Verify**
  ```bash
  flutter test test/app/routing/deep_link_test.dart
  bash .claude/skills/navigation-and-routing/scripts/check_routing.sh
  grep -rn "state.extra" lib/app/routing/     # empty — a payload is never a live Dart object
  ```
- **Done when**
  - [ ] All six kinds have a test, and both "the thing is gone" rows land on plain Home with nothing shown.
  - [ ] The vehicle-before-route ordering is asserted as an order, not as an end state, for both kinds that set it.
  - [ ] Back from a deep-linked modal reaches Home, proven in a pumped test.
  - [ ] `locationFor` is pure and total; an unknown kind is a typed failure.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 8.8 — Build `dialog.discard` and wire the dirty-modal guard

- **Goal** — no modal in the app can lose a user's typing silently, and the dialog that guarantees it exists exactly once.
- **Spec** — §7 *Navigation graph* (the two rules that hold everywhere: "dismissing a dirty modal opens `dialog.discard`; dismissing a clean one is silent"); §7 *Global dialogs*; §10 *Logging* (Discard drops every segment's draft, not just the visible one).
- **Skills** — `calm-components`, `calm-visual-parity`, `calm-typography-and-rtl`, `ui-states-and-feedback`, `navigation-and-routing`, `i18n-rtl-l10n` *(via the conventions index)*.
- **Write these tests first** — `test/ui/dialogs/discard_dialog_test.dart`:
  - `the title reads "Discard changes?"` — the ARB key, asserted against the reference's string.
  - `the body names what would be lost` — "Your edits to {subject} — {summary} — have not been saved." with `subject` and `summary` supplied by the caller. A generic "you have unsaved changes" is not what the reference says and is not what makes the decision answerable.
  - `Keep editing is the primary action and sits above Discard` — the reference orders them safe-first; `calm-components` says "destructive first", and the reference wins (finding F-8.4).
  - `Discard returns the discard outcome; Keep editing returns keep`.
  - `tap-out returns keep` and `system back returns keep` — §7: tap-outside and system back are always the negative action, and `showDialog`'s null is mapped explicitly rather than falling through.
  - `Keep editing restores focus to the field that had it` — the caller's focus node is captured before the dialog opens and requested after it closes.
  - `Discard drops every segment's draft, not only the visible one` — asserted against the guard's `onDiscard` contract, so EPIC-11's four-segment log modal inherits it rather than re-deciding it.
  - `both action labels are ARB keys present in all six locales` — and the two buttons stack full-width, so German's "Änderungen verwerfen?" wraps rather than shrinking.
  - `the dialog is one shared widget` — a grep test asserting no second discard dialog exists in `lib/features/`.
  - `test/app/routing/dirty_modal_guard_test.dart` — the guard's six cases from task 8.4 re-run against the real dialog rather than the probe.
- **Then build** — `lib/ui/dialogs/discard_dialog.dart`:
  `Future<DiscardChoice> showDiscardDialog(BuildContext context, {required String subject, required String summary})`
  composing `CalmDialog` with its 56pt icon disc, `start`-aligned body and stacked full-width
  actions. It returns a choice and **writes nothing**; the caller owns the draft. EPIC-09's
  task 8.5 plans to build this file — it uses this one instead (finding F-8.1).

  Then the parity harness. All three dialogs in this epic are shot **over a backdrop**, because
  that is how the references were shot: `dialog.discard` and `dialog.snooze` over `home`,
  `dialog.confirmDelete` over `vehicles` — and neither screen exists yet. So this task also
  builds `test/parity/support/dialog_backdrop.dart`: a static, non-interactive composition of
  EPIC-03's `CalmScaffold`, `CalmAppBar`, `CalmCard`, `CalmRowGroup` and `CalmTabBar` that
  reproduces the reference backdrop's band profile. It is a **test fixture and is never
  shipped**; `test/policy/structure_test.dart` gains a case asserting nothing under `lib/`
  imports it. EPIC-09 and EPIC-10 replace it with the real screen and re-run these captures; if
  the parity result changes when they do, the stand-in was lying and that is a finding then,
  recorded here so they know to look (finding F-8.2).

  Then `test/parity/dialog_discard_parity_test.dart`, capturing all four combinations at
  390×844 @2x to `build/parity/dialog.discard-<theme>-<dir>.png`. The test file uses
  underscores; the **capture filename is the screen id**, dot included, or the comparison tool
  cannot find its reference.
- **Verify**
  ```bash
  flutter test test/ui/dialogs/discard_dialog_test.dart test/app/routing/dirty_modal_guard_test.dart
  flutter test test/parity/dialog_discard_parity_test.dart   # captures 4 PNGs to build/parity/
  node tools/compare_to_reference.mjs build/parity/dialog.discard-light-ltr.png dialog.discard \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/dialog.discard-light-ltr.png    # look at the side-by-side
  ```
  A pass is the three mechanical checks green — the ground is a token of the requested theme,
  every surface over 0.5% is within Δ24 of a Calm token, and ≥75% of the reference's band edges
  have an app edge within 4px. The differing-pixel percentage is informational and reads 25–45%
  on a correct screen; it is not a score and no tolerance is widened. If the band check fails on
  the backdrop rather than the dialog, the harness fixture is wrong, not the dialog — fix the
  fixture, never the tolerance.
- **Done when**
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight, icon shape or optical alignment.
  - [ ] Tap-out and system back both return *Keep editing*, asserted separately.
  - [ ] The dialog is one shared widget with no copy in `lib/features/`, and it writes nothing.
  - [ ] The backdrop fixture lives under `test/` only, proven by a structure test.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 8.9 — Build `dialog.confirmDelete`

- **Goal** — every destructive action in the app is guarded by one dialog that names exactly what dies.
- **Spec** — §7 *Screen list* (`dialog.confirmDelete`: "naming what dies"); §7 *Global dialogs*; §2 *Delete is immediate, with Undo in the moment* (no trash, no bin); §8 *`vehicles` → Delete* (the typed confirmation and the sold alternative).
- **Skills** — `calm-components`, `calm-visual-parity`, `calm-typography-and-rtl`, `ui-states-and-feedback`, `i18n-rtl-l10n` *(via the conventions index)*, `forms-and-input` *(likewise, for the typed-confirmation field)*.
- **Write these tests first** — `test/ui/dialogs/confirm_delete_dialog_test.dart`:
  - `the title names the subject and its entry count` — "Delete The Golf and its 412 entries?", one ICU message with a plural and an explicit `=0` case.
  - `the body names the five per-type counts in one sentence` — "96 fill-ups, 14 services, 22 costs, 8 trips and 16 reminders go permanently." One ICU message with five plural arguments; §2 forbids concatenation, and five plurals in one message is legal ICU and translatable. Each count gets an explicit `=0`.
  - `zero entries gives a one-tap Delete with no typed confirmation` — the field is absent from the tree, not merely disabled.
  - `one or more entries requires typing the subject name, and Delete stays disabled until it matches` — the reference shows Delete disabled with the field empty.
  - `the typed confirmation compares the name as entered, after digit normalisation` — EPIC-04's `normalizeNumericInput` applies, so a Persian-keyboard user typing a name containing digits is not locked out.
  - `the safe alternative sits above Delete when the caller supplies one` — "Keep it — mark it sold" is offered before Delete because it is usually what people mean; a caller with no alternative gets two actions, not a stub.
  - `Cancel is last, and tap-out and system back both return cancel` — no dialog is ever dismissed into a destructive outcome.
  - `the dialog performs no delete` — it returns a decision; the caller deletes. Asserted with a repository double that fails the test if touched.
  - `the subject name is wrapped in a first-strong isolate` — a vehicle called "The Golf" inside a Persian sentence renders LTR and does not reorder the sentence around it. §2's bidi rule, and the title is where it breaks first.
  - `it is one shared widget` — a grep test asserting no second confirm-delete dialog exists in `lib/features/`.
- **Then build** — `lib/ui/dialogs/confirm_delete_dialog.dart`:
  `Future<ConfirmDeleteChoice> showConfirmDeleteDialog(BuildContext, {required String subject, required DeleteCounts counts, String? safeAlternativeLabel, bool requireTypedConfirmation = …})`
  composing `CalmDialog` with the danger icon disc, an optional `CalmField` and stacked
  full-width actions in the reference's order. `DeleteCounts` is a record of the five numbers
  §8's dialog names; the total in the title is their sum, computed here so no caller can pass a
  total that disagrees with its own breakdown.

  EPIC-09 task 9.6 and EPIC-12 task 12.9 both plan to build this dialog, and EPIC-15 task 15.6
  plans to reuse EPIC-12's. All three call this one (finding F-8.1).

  Then `test/parity/dialog_confirm_delete_parity_test.dart`, over the `vehicles` backdrop
  fixture from task 8.8.
- **Verify**
  ```bash
  flutter test test/ui/dialogs/confirm_delete_dialog_test.dart
  flutter test test/parity/dialog_confirm_delete_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/dialog.confirmDelete-light-ltr.png dialog.confirmDelete \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/dialog.confirmDelete-light-ltr.png    # look at the side-by-side
  ```
  Then pump the German and Sorani locales at 200% text scale and confirm the three stacked
  actions wrap rather than clip — the parity tool shoots at scale 1 and cannot see it.
- **Done when**
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight, icon shape or optical alignment.
  - [ ] The typed confirmation is required exactly when the entry count is non-zero, proven by two tests.
  - [ ] The dialog deletes nothing, proven by an untouched repository double.
  - [ ] Both count messages are single ICU messages with explicit `=0` cases in all six locales.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 8.10 — Build `dialog.snooze`

- **Goal** — a user can quiet one reminder for a while, and the dialog says out loud that quieting it does not change the truth.
- **Spec** — §7 *Screen list* (`dialog.snooze`: 3 days / 1 week / 1 month / after another 500 km, the distance option only when the item has a distance interval); §7 *Global dialogs*; §4.7.2 *Snooze* (the effect, and the four things it does **not** change); §1 (the app never guesses in a way that looks like fact).
- **Skills** — `calm-components`, `calm-visual-parity`, `calm-typography-and-rtl`, `ui-states-and-feedback`, `i18n-rtl-l10n` *(via the conventions index)*, `value-objects-money-and-units` *(likewise, for `CivilDate` arithmetic)*.
- **Write these tests first** — `test/ui/dialogs/snooze_dialog_test.dart`:
  - `the title names the item` — "Snooze {item}", the label interpolated as stored. The reference lower-cases it ("Snooze oil and filter"); an ICU message cannot case-fold a noun, and German capitalises all of them (finding F-8.6).
  - `the body says the item stays overdue on Home and that this only quiets the reminders` — the reference's sentence pair verbatim: "It stays overdue on Home. This only quiets the reminders." This is §1's "never guess in a way that looks like fact" applied to a dialog: snoozing changes the notification schedule and nothing else, and the dialog is the only place the user can be told so.
  - `a due or due_soon item does not claim to be overdue` — the body is an ICU `select` over the item's `DueState`, and the non-overdue branch is settled in `SPEC.md` §4.7.2 in this PR before the task closes (finding F-8.8). Nothing is invented in code.
  - `three days from 3 September 2026 reads until 6 Sep` — the trailing value on each row is computed from the injected `Clock`, not from `DateTime.now()`.
  - `one week reads until 10 Sep` and `one month reads until 3 Oct` — a calendar month via EPIC-06's `addMonths`, which clamps to the last day of the target month. 31 January + 1 month is 28 February, not 3 March.
  - `the distance option reads "After another 500 km" and "at 187,912 km"` — the current cumulative reading (187,412 km in the reference) plus `kSnoozeDistanceMetres = 500000`. The figure is the caller's entered reading, never a projection: a snooze target computed from an estimate would move every time the estimate did.
  - `the distance option is absent when the item has no distance interval` — absent from the tree, not disabled. §7 states the condition and it is the only conditional row.
  - `the dialog writes nothing` — it returns a `SnoozeChoice`; EPIC-16 applies it. Asserted with a repository double that fails the test if touched.
  - `Cancel, tap-out and system back all return no choice` — three cases; §7's *Global dialogs* row says tap-out does nothing.
  - `every date renders in the active calendar and numerals` — pumped in `fa`: Jalali dates in Extended Arabic-Indic digits, per §5.
  - `the odometer figure and its unit are one atomic run in both directions` — a bidi isolate, so "187,912 km" does not split across a Persian sentence.
  - `the four rows and both sentences are ARB keys present in all six locales`.
- **Then build** — `lib/ui/dialogs/snooze_dialog.dart`:
  `Future<SnoozeChoice?> showSnoozeDialog(BuildContext, {required String itemLabel, required DueState state, required CivilDate today, required bool hasDistanceInterval, int? currentOdometerMetres})`
  composing `CalmDialog` with its icon disc, the two-sentence body, a flat `CalmRowGroup` of
  three or four `CalmListRow`s with the resolved value at the `end`, and a single quiet
  full-width **Cancel**. `SnoozeChoice` is
  `enum SnoozeChoice { threeDays, oneWeek, oneMonth, fiveHundredKilometres }`.

  It returns a choice and persists nothing. **EPIC-16 owns the application** — writing
  `snoozed_until` / `snooze_until_odometer_m`, converting the distance option to a date through
  the projection, the three-consecutive-snooze limit and the fourth-offer escalation of §4.7.2.
  EPIC-16 task 16.7 already says "`dialog.snooze` already exists; this task wires its four
  options to the same code path the notification action uses" — this is that dialog. EPIC-10
  says the dialog is owned by the notifications epic; it is not, it is owned here and *called*
  from Home's card overflow and from a `reminders.list` swipe (finding F-8.1).

  Then `test/parity/dialog_snooze_parity_test.dart`, over the `home` backdrop fixture from
  task 8.8.
- **Verify**
  ```bash
  flutter test test/ui/dialogs/snooze_dialog_test.dart
  flutter test test/parity/dialog_snooze_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/dialog.snooze-light-ltr.png dialog.snooze \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/dialog.snooze-light-ltr.png    # look at the side-by-side
  ```
  `design/reference/calm/` holds `dialog.snooze-{light,dark}-{ltr,rtl}.png` — the artboard was
  added to `design/calm/screens.html` and the set re-shot, which is why it is **28 screens and
  112 images**, not 27 and 108. This dialog is gated like every other and has no carve-out.
- **Done when**
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight, icon shape or optical alignment.
  - [ ] The body states that the item stays on Home in its real state, and the non-overdue wording is settled in `SPEC.md` before the task closes.
  - [ ] The three dates come from the injected `Clock` and `addMonths`, with the month-end clamp asserted.
  - [ ] The distance row is absent — not disabled — on an item with no distance interval.
  - [ ] The dialog writes nothing, proven by an untouched repository double.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

## Spec and epic-set findings raised by this epic

These are recorded here because the tasks above act on them. Each is either fixed in this
epic's PR or carried as a written answer.

| Id | Finding | Handling |
|---|---|---|
| F-8.1 | **The three global dialogs are claimed by four epics.** EPIC-09 lists `dialog.discard` and `dialog.confirmDelete` in its Screens row and builds both (tasks 8.5, 8.6); EPIC-12 task 12.9 builds `dialog.confirmDelete` again; EPIC-15 says it reuses "the existing widget from EPIC-12"; EPIC-10 says `dialog.snooze` "is owned by the reminders/notifications epic". §7 groups all three as **global** dialogs belonging to no feature. | This epic builds all three, once, in `lib/ui/dialogs/`, at the paths EPIC-09 already names. EPIC-09, EPIC-10, EPIC-12, EPIC-15 and EPIC-16 **call** them; none builds one. Remove the two dialog ids from EPIC-09's Screens row, drop `dialog.confirmDelete` from EPIC-12 task 12.9's build step, and correct EPIC-10's sentence. Their *behavioural* tests stay — a shared dialog should still pass every caller's assertions. |
| F-8.2 | All three dialog references are shot over a backdrop screen (`home`, `home`, `vehicles`) and **none of those screens exists when this epic runs**. The band check compares against the whole 390×844 frame, so a missing backdrop fails the gate for a reason that is not the dialog. | Task 8.8 builds `test/parity/support/dialog_backdrop.dart` — a test-only static composition of EPIC-03 widgets reproducing the reference's band profile. EPIC-09 and EPIC-10 swap it for the real screen and re-run the three captures. Written into this epic's progress file so they do it. |
| F-8.3 | EPIC-16 task 16.3 plans to write `lib/routing/notification_deep_link.dart` with its own `locationFor` and back-stack synthesis — the same function task 8.7 builds. | Task 8.7 owns the mapping and the back stacks; EPIC-16 owns the payload type, its JSON round-trip and its per-kind `reminderId` validation, and maps onto `DeepLinkRequest` at the boundary. EPIC-16's deep-link tests are kept and run against this function. |
| F-8.4 | `calm-components` says dialog actions are "stacked and full-width, **destructive first**, `Cancel` last". All three references order them safe-first: *Keep editing* above *Discard*; *Keep it — mark it sold* above *Delete* above *Cancel*. | The reference is the authority (`calm-visual-parity` rule 1), and safe-first is also what §7's "no dialog is ever dismissed into a destructive outcome" implies. Amend `calm-components` to "the safe alternative first where one exists, then the destructive action, then Cancel" in this PR. |
| F-8.5 | `navigation-and-routing` puts the router in `lib/routing/`; EPIC-01 folded it into `lib/app/` and its `test/policy/structure_test.dart` asserts `lib/` has exactly seven top-level directories. EPIC-09 and EPIC-16 both write tests to `test/routing/`, which mirrors a directory that cannot exist. | Routing lives in `lib/app/routing/`, tests in `test/app/routing/`. EPIC-01's recorded deviation stands; the skill bends (`epics/README.md` rule 5). Correct the paths in EPIC-09 task 9.8 and EPIC-16 task 16.3. |
| F-8.6 | The `dialog.snooze` reference title reads "Snooze oil and filter" — the item label lower-cased inside the sentence. An ICU message cannot case-fold a placeholder, and German capitalises every noun, so `{item}` must interpolate the label as stored. | The built title reads "Snooze Oil and filter". One capital letter differs from the reference; the band check cannot see it and the human pass will. Recorded rather than chased, and raised as a one-line copy fix to the artboard. |
| F-8.7 | This epic's declared dependencies are EPIC-03 and EPIC-07, but every string in the three dialogs and all five tab labels are ARB keys, which EPIC-04 delivers. | The recommended order puts EPIC-04 before this epic, so it is a documentation gap rather than a build-order problem. Add EPIC-04 to this epic's dependency row in `epics/README.md`. |
| F-8.8 | §7 and §4.7.2 give `dialog.snooze` one supporting sentence, and the reference shows only the overdue case. A `due` or `due_soon` item told "It stays overdue on Home" would be shown a statement that is false — the exact failure §1 forbids. | **Blocks task 8.10's body test.** Settle the non-overdue wording in `SPEC.md` §4.7.2 in the same PR, as an ICU `select` branch beside the reference's verbatim overdue sentence. Nothing is invented in code. |
| F-8.9 | §7 and §4.7.2 both write the distance snooze as "another **500 km**", with no mile equivalent, and the reference renders km. §4.8's rule that defaults are "defined per unit system, not converted" would give a miles user a round number instead. | Not blocking: task 8.10 implements `kSnoozeDistanceMetres = 500000` as written, because inventing "300 mi" is exactly the kind of unsourced value this document forbids. Raised for §4.7.2 to settle alongside F-8.8. |
| F-8.10 | The epic set is numbered inconsistently. `epics/README.md` numbers the epics 01–18 while the files run EPIC-01–EPIC-19 with a hole at 08; every epic from EPIC-09 on numbers its tasks one lower than its file (EPIC-09 has tasks 8.N, EPIC-12 has 11.N, EPIC-16 has 15.N); and EPIC-10 and EPIC-14 both credit **"EPIC-07"** with delivering the `go_router` and the tab roots, which is the due engine. EPIC-16 credits the route graph to EPIC-10. | Inserting this epic at 08 makes file number and display number agree for the whole set. Renumber `epics/README.md`'s table to 01–19, add this row, and correct the three misattributed credits to **EPIC-08**. Task numbers in EPIC-09 onward are renumbered to match their files in the same PR; this epic's tasks are `8.N` and collide with EPIC-09's until that happens. |
| F-8.11 | `epics/README.md` and the contract say **27 screens / 108 images**; `design/reference/calm/` holds **112 images for 28 screens** since `dialog.snooze` was added. EPIC-17 says 28, EPIC-18's front matter says 27 while its own body says 28. | Correct `epics/README.md` (rule 4, the epic table, the "seven epics build the 27 screens" line) and EPIC-18's Screens row to 28 and 112 in this PR. |

## Definition of done

- [ ] `go_router` is in `pubspec.yaml`, `lib/app/routing/` holds `routes.dart`, `app_router.dart`, `app_shell.dart`, `page_kinds.dart`, `dirty_modal_guard.dart`, `tab_stack_reset.dart`, `launch_gate.dart`, `deep_link.dart` and `route_not_found_screen.dart`, and `test/app/routing/` mirrors it.
- [ ] `lib/app/app.dart` mounts `MaterialApp.router` once, and there is exactly one `GoRouter` in `lib/`.
- [ ] All 28 `data-screen` ids in `design/calm/screens.html` are covered by `kScreenRoutes`, every location resolves, and the coverage test reads the design file rather than a copied list.
- [ ] Four tab roots plus the docked central `+`; each branch keeps its stack; the order mirrors under RTL with the `+` centred.
- [ ] Every row of §7's launch table and every row of its deep-link table has a passing test.
- [ ] `resetAllTabStacks` has one implementation and exactly two callers.
- [ ] The three global dialogs live in `lib/ui/dialogs/`, are built once, write nothing, and every user-visible string in this epic is an ARB key present in `en de fr fa ar ckb` with an explicit `=0` on every count.
- [ ] `grep -rn "Navigator.push\|Navigator.pushNamed\|WillPopScope\|showModalBottomSheet" lib/` is empty, and `lib/features/` contains no `PopScope`.
- [ ] `bash .claude/skills/navigation-and-routing/scripts/check_routing.sh` passes.
- [ ] The findings above are fixed in `SPEC.md`, in the skills or in the sibling epics in this PR, or answered in writing in the PR body; F-8.8 is settled before task 8.10 is called done.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.
- [ ] Every screen in this epic matches its reference in `design/reference/calm/` in all four
      combinations, checked with `calm-visual-parity`.

## Progress file

**Before starting, create the empty progress file `epics/progress/EPIC-08.md`.** It starts
empty. Append one line per task as it completes — what was built, what was deferred, and
anything the next epic needs to know. It is the running log for this epic and the handover to
the next one.
