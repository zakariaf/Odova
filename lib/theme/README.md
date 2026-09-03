# `lib/theme` — Calm's values

**Owner:** the token set. **Skills:** `calm-tokens`, `design-system-structure`,
`calm-typography-and-rtl`.

`calm/` holds the two token tiers as Dart — primitives named by measured value,
semantic slots named by role — exposed as five `ThemeExtension`s with asserting
`of(context)` accessors, plus the hand-authored light and dark `ColorScheme`s.

This directory holds values and nothing else. It is also the only place in the
app where a raw hex, duration, radius or font size may be written down.
