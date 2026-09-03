# `lib/ui` — the only layer that styles

**Owner:** the Calm component library. **Skills:** `calm-components`,
`calm-layout-and-motion`, `calm-due-state-and-status`, `accessibility-as-code`.

`calm/` holds every Odova widget — `CalmButton`, `CalmCard`, `CalmListRow`,
`CalmDueCard` and the rest — each reading its values through
`CalmColors`/`CalmType`/`CalmSpace`/`CalmShapes`/`CalmMotion.of(context)`.
`dialogs/` holds the three global dialogs that belong to no feature.

Feature code never reads a raw value; it reaches for a component here. That is
the boundary the no-raw-values gate draws, and it is why this layer is a
top-level directory rather than a folder inside `theme/`.
