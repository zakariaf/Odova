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
