# `lib/app` — the composition root

**Owner:** application wiring. **Skills:** `app-startup-and-bootstrap`,
`navigation-and-routing`, `service-boundary-and-native`,
`state-management-riverpod`.

`bootstrap.dart` builds the real infrastructure once and injects it into the
root `ProviderScope` with `overrideWithValue`; `app.dart` is the root widget;
`error_handlers.dart` holds exactly two handlers and no zone; the `go_router`
configuration and the injectable service ports live here too.

Nothing in here holds business rules. If a decision can be made without a
`BuildContext`, it belongs in `lib/core`.

## Deviation from `project-structure-and-packages`, recorded once

The skill puts `main.dart`, `bootstrap.dart` and `app.dart` at the `lib/` root
and adds top-level `routing/` and `services/`. Odova folds `bootstrap.dart`,
`app.dart`, the router configuration and the service ports into **`lib/app/`**,
and adds **`lib/ui/`** for the design-system component layer.

Two reasons, both specific to this product:

1. The seven-directory rule in `test/policy/structure_test.dart` is only worth
   having if the list is short enough that adding to it is a visible decision.
   Three more top-level names for one feature's worth of code is not that.
2. The `calm-*` skills are written against `lib/ui/calm/`, and that layer is
   the only one allowed to style anything. It needs a name of its own, at the
   top level, so the no-raw-values gate has a boundary to draw.

Everything else is the skill verbatim.
