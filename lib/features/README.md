# `lib/features` — one directory per feature

**Owner:** screens and their state. **Skills:** `scaffold-feature-module`,
`widget-composition`, `state-management-riverpod`, `ui-states-and-feedback`.

One directory per feature, each holding its screens, its widgets and its one
`Notifier`. A feature never imports another feature: they share code by lifting
it down into `lib/core` or `lib/data`, or they meet via a route.

Feature code composes; it does not style. Every colour, radius, duration and
size comes from `lib/ui/calm/`, which reads `lib/theme/calm/`.
