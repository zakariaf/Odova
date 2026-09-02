---
name: calm-design-system
description: The front door to Calm, Odova's design system — a warm earthy palette (clay, sand, sage, terracotta on a #F8F2E9 off-white, dusk #1D1815 in dark, never blue-black), few large rounded surfaces at 16–36px radius, one primary thing per screen, state carried by tone rather than alarm, a 52px touch floor and a 13px type floor, no monospace anywhere, and elevation instead of hairlines; owns the lib/theme/calm → lib/ui/calm → feature-code layering, the rule that feature code never reads a raw value, the product rules Calm exists to serve (never guess in a way that looks like fact, the two-notifications-per-seven-days budget, "nothing is due" as the good state), and the routing table to calm-tokens, calm-typography-and-rtl, calm-components, calm-due-state-and-status and calm-layout-and-motion. Use when starting a new Odova screen or feature, wiring buildCalmTheme or lib/ui/calm, asking "which Calm skill covers this", picking a colour/radius/duration/type size for Odova, porting a mockup from design/calm/screens.html or system.html, reviewing a widget for Calm compliance, reaching for a Material default (ElevatedButton, Card, ListTile, Scaffold, AppBar, TextField, Switch, Divider), reaching for Colors.red / a monospace face / a 1px border / ColorScheme.fromSeed, or deciding what the empty, all-clear, unknown or needs-odometer state should look like.
---

# calm-design-system

Calm is reassurance in a small number of large things. It is the design language for a driver who does not enjoy this task and wants to be told the car is handled: warm earth colour, few big rounded surfaces, one primary thing per screen sized much larger than everything else, state carried by tone rather than alarm. Where a dense system shows eight rows, Calm shows three and a clear next action. This skill is the front door — it owns *what Calm is*, the `lib/theme/calm/` → `lib/ui/calm/` → feature-code pipeline, the product rules the visual language exists to serve, and the routing table that sends every other task to one of the five sibling skills. It does not own token mechanics, type, components, status or layout; each of those has its own skill and this one names them all.

Read the reference for the task at hand:
- `references/what-calm-rejects.md` — the anti-brief. Dense tables, hairline rules, monospace figures, dark chrome and instrument-panel metaphors, gauges and dyno charts, siren red, all-caps, sub-13px type, pastel-fintech weightlessness, and "nothing is due" as an empty box — each with the Calm token or widget that replaces it.
- `references/build-order.md` — how to build a screen in this system, in order: the one answer, the primary surface, the secondaries, the cap-and-link, the states, the RTL pass, the motion pass, the gates.

Run `scripts/check_calm_layering.sh` and `scripts/check_calm_rejects.sh` before a PR, in addition to the general `design-system-structure/scripts/check_raw_values.sh`.

## Routing table — which Calm skill owns this task

| You are about to… | Skill |
|---|---|
| Add/rename a token, write a `ThemeExtension`, hand-author a `ColorScheme`, fix a `lerp`, wire `buildCalmTheme` | `calm-tokens` |
| Pick a type size, set a weight or tracking, bundle Vazirmatn, handle fa/ar/ckb, per-locale numerals, the Jalali calendar, text expansion, decide what mirrors | `calm-typography-and-rtl` |
| Build or change anything under `lib/ui/calm/` — `CalmButton`, `CalmCard`, `CalmListRow`, `CalmField`, `CalmSheet`, `CalmNumberPad`, … and their states | `calm-components` |
| Render a due status, a status dot, a badge, an estimate, `unknown`, or `needsOdometer` | `calm-due-state-and-status` |
| Lay out a screen, choose spacing, honour the 52px floor, build the empty/all-clear state, pick a duration or curve, handle reduced motion | `calm-layout-and-motion` |
| Structure tokens as tiers, decide `ThemeExtension` vs static class, asserting `of()`, the no-raw-values gate | `design-system-structure` (general library — Calm does not restate it) |
| Read a11y flags, target sizes, never-colour-alone floor, `textScaler` | `accessibility-as-code` (general library) |

If two rows could apply, the more specific wins: a status colour on a card is `calm-due-state-and-status`, not `calm-components`.

## Non-negotiable rules

1. **Three layers, one direction: `lib/theme/calm/` → `lib/ui/calm/` → feature code.** Feature code imports widgets from `lib/ui/calm/` and may read `CalmSpace`/`CalmType`/`CalmColors` for layout, but never imports a Calm palette/primitive file, never writes a hex, a `fontSize`, a `BorderRadius.circular(n)`, a `Duration`, or a `Curve`. `scripts/check_calm_layering.sh` fails on the import; `design-system-structure/scripts/check_raw_values.sh` fails on the literal. WHY: a reskin must be `diff lib/theme/calm/`, and a stray opinion in a feature file is invisible until it is in front of a user.
2. **A value that is not in `design/calm/odova.css` does not exist.** The 124 light tokens and 63 dark overrides in that file are the whole vocabulary. Needing a new one is a two-file commit — `odova.css` **and** the matching `CalmColors`/`CalmSpace`/`CalmShapes`/`CalmMotion` field — never a literal in a widget and never a `// ignore`. WHY: the CSS specimen (`design/calm/system.html`) is what design review looks at; a value only Dart knows about is a value nobody ever approved.
3. **No monospace, anywhere, ever.** `--font-latin` and `--font-arabic` are the only two families in the system. Aligned figures come from `FontFeature.tabularFigures()` + `FontFeature.liningFigures()` on the humanist face, not from a mono fallback. `scripts/check_calm_rejects.sh` greps for it. WHY: a mono digit is the instrument-panel/dyno-chart metaphor Calm exists to reject — the user is not an enthusiast and this is not a diagnostic tool.
4. **Nothing tappable is under `--touch-min` (52px); no text is under `--fs-caption` (13px).** Buttons are 52px minimum, list rows 64px, number-pad keys 68px, and the primary action is full-width at the bottom of the thumb's reach. WHY: this app is used one-handed, at a fuel pump, in the rain, in a basement. A 44px target is an Apple minimum for a calm indoor tap, not for a wet glove.
5. **One primary thing per screen.** Decide the single answer the screen exists to give, build it at `--fs-title-lg` (27px) or larger inside a `CalmCard` at `--radius-3xl` (36px) with `--space-6` (24px) padding, and make everything else quieter and smaller. If two things look equally important the screen is not finished. WHY: `SPEC.md` §9 — Home answers exactly one question, and ~70% of sessions never leave it.
6. **State is three signals, never colour alone, and it resolves through `CalmStatusStyle`.** Dot shape is normative (filled ● overdue, ring ◉ due, small ● due-soon, hollow ◌ needs-odometer, outlined unknown), plus the state tone, plus wording that says the same thing. A widget never reads `CalmColors.of(c).overdue` directly. WHY: the encoding must survive greyscale and colour-blind rendering; going through one resolver is what keeps dot, word and tone from drifting apart. Detail: `calm-due-state-and-status`.
7. **Overdue is terracotta `--color-overdue` `#B4573E` (dark `#E39172`), at most once per screen — never `Colors.red`.** Do not stack red on red, do not add an exclamation glyph to an already-red card, and never render eleven overdue items on a used car's first launch: those collapse into one unknown card. WHY: `SPEC.md` §9 — an app that shouts OVERDUE eleven times on day one gets its notifications turned off on day two. Grace bands exist so that `due` is amber and actionable and `overdue` means you have been ignoring it.
8. **"Nothing is due" is the good state and gets the best card in the app.** It renders `CalmAllClear` — the sage `--color-ok-tint` wash, the largest mark on any screen, a real second sentence (`Next: Inspection, 14 March`) and a since-last-service line — never `CalmEmptyState`, never a grey icon in a box, never a nag. WHY: `SPEC.md` §9 calls it *the most common state, and the one most apps waste*; it also saves enough height to pull the cost tiles above the fold, so a user with nothing due still leaves knowing what the car costs.
9. **Never guess in a way that looks like fact.** `~187,400 km` in `--color-ink-2` with the tilde inside the visible string; a projected date fuzzy (`around mid-October`); at `confidence = default` no figure and no date at all. `DueState.unknown` and `DueState.needsOdometer` are distinct states and **both are non-alarming** — `--color-unknown` `#8A7C6D` and `--color-needs-odometer` `#736A5F`, warm stone, not amber and not red. WHY: `SPEC.md` §1 — the app would rather show a dash than a plausible lie, and rendering "we do not know" as either "you are fine" or "you are late" is the one way this rule gets broken in the UI.
10. **The notification budget is a layout constraint, not a settings screen.** At most 2 notifications in any rolling 7 days, at most 1 per calendar day, across every vehicle (`SPEC.md` §4.3). Home therefore carries everything the notification could not: the away digest, the done-from-notification confirmation, the stale-odometer strip — capped at **two** conditional strips, and the primary card is never displaced. WHY: the screen is the only high-bandwidth channel this app has, so it is designed to be sufficient on its own.
11. **Elevation, never a border.** Surfaces separate with `--elev-1` … `--elev-4` plus `--elev-sheen`, warm-tinted (`rgba(76, 50, 32, …)` in light, black in dark). `--color-divider` is a *grouping* device inside a row group, never an outline around a card, and Calm has no hairline rule token at all. WHY: a 1px line is the dense-spreadsheet vocabulary Calm rejects; light and air do the separating.
12. **Logical direction only — `start`/`end`, never `left`/`right`.** Six locales ship on day one, three of them RTL. Only directional glyphs (back chevron, disclosure chevron, backspace, swap, undo, prev/next) flip; a car, a pump, a wrench, a clock and a check keep one canonical asset. WHY: `SPEC.md` §2 makes this a CI failure; it is the only rule that keeps RTL correct as the app grows past the screens in the spec. Owned jointly by `calm-typography-and-rtl` and the general `i18n-rtl-l10n`.

## The pipeline: token → theme → widget → screen

```
design/calm/odova.css      124 light tokens + 63 dark overrides   ← the source of truth
        ↓ transcribed, one field per token, no renaming beyond the naming contract
lib/theme/calm/            CalmColors CalmType CalmSpace CalmShapes CalmMotion
                           buildCalmTheme(Brightness) attaches all five to BOTH ThemeData
        ↓ the ONLY layer that reads a Calm extension for appearance
lib/ui/calm/               CalmButton CalmCard CalmDueCard CalmAllClear CalmScaffold …
        ↓ composition only
lib/features/**            reads CalmSpace/CalmType for layout; renders Calm widgets
```

The naming contract is mechanical, so a token can be found from either end — `--color-ink-2` → `CalmColors.of(c).ink2`, `--space-4` → `CalmSpace.of(c).s4`, `--radius-2xl` → `CalmShapes.of(c).radius2xl`, `--dur-base` → `CalmMotion.of(c).base`, and `--fs-title` + `--lh-title` collapse into one `CalmType.of(c).title` `TextStyle`. `calm-tokens` owns the classes; `design-system-structure` owns why they are `ThemeExtension`s with an asserting `of()` at all.

```dart
// Feature code. Layout values are slot reads; appearance comes from a Calm widget.
final space = CalmSpace.of(context);
final type = CalmType.of(context);

return Padding(
  padding: EdgeInsetsDirectional.symmetric(horizontal: space.screenPad), // 22px token
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l10n.homeNextUp, style: type.headline),   // --fs-headline 19 / --lh-headline 1.32
      SizedBox(height: space.s5),                    // --space-5 20px
      CalmDueCard(                                   // status tone lives INSIDE the widget
        density: CalmDueDensity.primary,
        view: item,                                  // a CalmDueView, formatted upstream
        onTap: onOpenItem,
        onAction: onActOnItem,
      ),
    ],
  ),
);
```

What is *not* allowed here: `Theme.of(context).colorScheme.error`, `CalmColors.of(context).overdue`, `const SizedBox(height: 20)`, `Card(...)`, `ElevatedButton(...)`.

## Build order for a new screen

1. Write the one sentence the screen answers. If you cannot, it is not a screen.
2. Choose the primary surface for that sentence and size it far above everything else.
3. Add at most two secondaries, then a cap-and-link row (`See all reminders (14) ›`) — never a longer list.
4. Enumerate every state before styling one: loaded, empty/all-clear, first-run, single-item, over-cap, unknown-anchor, stale-odometer, error.
5. Only then reach for components, and only from `lib/ui/calm/`.

Full step-by-step with the token to use at each step: `references/build-order.md`. A full worked Home screen — the scaffold, the odometer strip, the primary card, two secondaries, the cap-and-link row and the glance tiles, with every state branch: `examples/calm_screen_skeleton.dart`.

## The product rules Calm exists to serve

Calm is not a mood board; each of its visual decisions is a `SPEC.md` rule made visible.

| `SPEC.md` rule | How Calm renders it |
|---|---|
| §1 *never guess in a way that looks like fact* | `~` inside the string, fuzzy dates, `—` over a plausible number, and two separate non-alarming states (`unknown`, `needsOdometer`) instead of a confident `overdue` |
| §4.3 *≤2 notifications per rolling 7 days, ≤1 per day, all vehicles* | Home is designed to be sufficient without notifications: away digest, done-confirmation and stale-odometer strips, capped at two, primary card never displaced |
| §9 *"nothing due" is the most common state* | `CalmAllClear` is the best-looking card in the system, with a real second sentence, and it is short enough to pull the cost tiles above the fold |
| §9 *the answer is above the fold on 375 × 667* | `--appbar-h` 56 + odometer strip 64 + primary 148 + 2 × 72 + see-all 48 = 460, under a `--tabbar-h` 62 tab bar |
| §2 *six languages, RTL first-class* | logical properties only; one directional-icon set; Vazirmatn leads for everything under `fa` |
| §1 *logs at a pump in the rain, one-handed* | `--touch-min` 52px floor, 64px rows, 68px number-pad keys, primary action full-width at the bottom |

## Anti-patterns

- **Reaching for a Material default** — `ElevatedButton`, `Card`, `ListTile`, `Scaffold`, `AppBar`, `TextField`, `Switch`, `Divider`, `SnackBar` — instead of the `Calm*` equivalent. It ships Material's radius, Material's ripple and Material's 48px density into a 52px, 36px-radius, no-ripple system, and it will not follow the next token change. `scripts/check_calm_layering.sh` fails it outside `lib/ui/calm/`.
- **`Colors.red` / `Colors.orange` / a `#D32F2F`-class hex for overdue.** Calm's overdue is `#B4573E`. A siren red next to clay and sage reads as a system error, not as "book the garage this month".
- **A monospace face, or `FontFeature`-less digits in a column.** Mono is rejected outright; alignment is `tabularFigures()` on the humanist face.
- **A `Border.all` / 1px outline to separate cards.** Use `--elev-1`; `--color-divider` groups rows, it does not fence surfaces.
- **Treating "nothing is due" as an empty state.** `CalmEmptyState` is for a list the user has not filled yet (no trips, no expenses). The all-clear is a *reward*, and it is the most common screen in the app.
- **Rendering `unknown` or `needsOdometer` in an alarm tone**, or collapsing them into one state. They are two different sentences — "we have no history" and "your reading is too old to accuse you with" — and `SPEC.md` §1 forbids either being dressed as fact.
- **Eleven red cards on a used car's first launch.** Items anchored on the `purchase` or `first_reading` rung render as `unknown` and collapse into one card, whatever the due engine returned.
- **Shrinking padding to fit another row in.** Air is the design. The fix is a cap and a link, not `--space-3` where `--space-6` belongs.
- **`ColorScheme.fromSeed` for the Calm palette.** The warm neutral ramp cannot be expressed by one seed, and per-role overrides do not propagate — see `design-system-structure` rule 4.
- **Adding a token in Dart only.** `odova.css` is what design review reads; a Dart-only value is unapproved and will be gone at the next re-export.
- **Using `EdgeInsets.only(left:` / `right:` anywhere outside the icon-asset layer.** It is a CI failure per `SPEC.md` §2, and it fails silently for half the user base.

## Definition of done

- [ ] `scripts/check_calm_layering.sh` and `scripts/check_calm_rejects.sh` are clean over `lib/`, alongside the general `check_raw_values.sh`.
- [ ] Every colour, size, radius, duration and curve rendered traces to a token in `design/calm/odova.css`; nothing was invented in Dart.
- [ ] The screen answers exactly one question, and its primary surface is unmistakably the largest thing on it.
- [ ] Every tappable target is ≥ 52px; no text below 13px; no monospace anywhere.
- [ ] Every due status carries dot shape + wording + tone, resolved through `CalmStatusStyle`.
- [ ] The "nothing is due" state is `CalmAllClear` with a next-item line and a since-last-service line, not an empty state.
- [ ] `unknown` and `needsOdometer` render distinctly and non-alarmingly; no estimated number appears without its `~` or its fuzzy wording.
- [ ] Every state from step 4 of `references/build-order.md` has a golden in both themes and both directions.
- [ ] No `left`/`right`; RTL golden verified; directional icons flip, canonical icons do not.
- [ ] Both themes pass AA independently (`calm-tokens` owns the contrast test; see Findings on `--color-ink-3` before using it for text).

## Related skills

- See `calm-tokens` for the five `ThemeExtension`s, the hand-authored light/dark `ColorScheme`, the asserting `of()`, honest `lerp`, and the no-raw-values gate applied to Calm.
- See `calm-typography-and-rtl` for the nine-step type scale, the 13px floor, Vazirmatn bundling, the six locales, numerals, the Jalali calendar and what mirrors.
- See `calm-components` for every widget in `lib/ui/calm/` and every state it must render.
- See `calm-due-state-and-status` for `DueState`, `CalmStatusStyle`, redundant encoding, and how "we do not know" is drawn.
- See `calm-layout-and-motion` for the spacing rhythm, the 52px floor, screen scaffolding, the all-clear state, and the duration/curve/reduced-motion contract.
- See `design-system-structure` for token *structure* — two tiers, `ThemeExtension` mechanics, why not `fromSeed`, the raw-values gate. Calm supplies the content; that skill supplies the shape.
- See `accessibility-as-code` for reading a11y flags from `MediaQuery`, the never-colour-alone floor, and never clamping `textScaler`.
- See `i18n-rtl-l10n` for ICU messages, directional geometry and RTL goldens.
- See `ui-states-and-feedback` for the loading/empty/error state taxonomy Calm's states plug into.
- See `widget-golden-and-a11y-testing` for the both-themes/both-directions golden sweep the definition of done asks for.
- See `design-review-workflow` for the once-per-app screenshot sweep against `design/calm/screens.html`.

## References

- Odova specimen sheet — `design/calm/system.html` (every component in every state) and `design/calm/odova.css` (the tokens as shipped).
- Odova screen set — `design/calm/screens.html`, PNGs in `design/reference/calm/`.
- `SPEC.md` §1 (who it is for), §2 (non-negotiables), §4.3 (the notification cap), §9 (Home, the card, every state).
- Flutter API — `ThemeExtension`: https://api.flutter.dev/flutter/material/ThemeExtension-class.html
- Flutter API — `FontFeature.tabularFigures`: https://api.flutter.dev/flutter/dart-ui/FontFeature/FontFeature.tabularFigures.html
- Flutter API — `Cubic` (maps a CSS `cubic-bezier` directly): https://api.flutter.dev/flutter/animation/Cubic-class.html
- Flutter API — `EdgeInsetsDirectional`: https://api.flutter.dev/flutter/painting/EdgeInsetsDirectional-class.html
- W3C WAI — WCAG 2.2 SC 1.4.3 Contrast (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- W3C WAI — WCAG 2.2 SC 1.4.1 Use of Color: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html
- W3C WAI — WCAG 2.2 SC 2.5.8 Target Size (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
