# Fields and the rest of the input kit

The **mechanics** of a form — `Form` + `GlobalKey<FormState>`, `TextFormField`, localized `String?` validators, `AutovalidateMode.onUserInteraction`, `FocusNode` traversal, `TextInputAction`, `keyboardType`, controller disposal — belong to `forms-and-input`. This file covers only what Calm changes: the look, the four states, and the product rules `SPEC.md` §10 attaches to them.

## The field is filled, not outlined

`CalmField` is a label, a filled box, and one helper line. There is no floating label, no underline, no `OutlineInputBorder`. Labels sit **above** the field (`type.label` semi, `ink2`, `s1` of start inset so it optically aligns with the field's text) because German `Kraftstoffart` and Sorani labels blow up a side label, and a stacked label survives 200% text scale (SPEC §10).

Build the `TextField` with `InputDecoration` fully neutralised — `border: InputBorder.none`, `isDense: true`, `contentPadding: EdgeInsets.zero`, `filled: false` — and let the wrapping container own fill, radius, padding and ring. Half-configuring `InputDecoration` is how a Material underline reappears in dark mode three sprints later.

## Four states, three (ring, fill) pairs

| State | Fill | Ring | Text |
|---|---|---|---|
| rest | `surface2` | transparent, 1.5 | `ink`, `type.bodyLg` medium |
| hover | `surface3` | transparent, 1.5 | `ink` |
| focus | `surface` | `brand`, 2.0 | `ink` |
| error | `overdue.tint` | `overdue.base`, 2.0 | `ink` |
| disabled | `bgSunk` | none | `ink4` |
| computed | `bgSunk` | none | `ink2` medium + an italic `ƒ` badge |

The ring is drawn **inside** the box (`BoxDecoration.border` paints inward), which reproduces the CSS `inset 0 0 0 2px` exactly and keeps the 56pt height stable across states. Keep the transparent 1.5 ring at rest rather than omitting it: the box then does not resize by 4pt when it gains focus.

Error text is `overdue.ink`, not `danger`. Calm's error voice is the same confident terracotta as an overdue item; `danger` (`#A5402B` / `#E68C72`) is reserved for destructive **actions** — `CalmButton.danger`, the delete row at the foot of an edit form. A field that failed validation is not a destructive act.

`computed` is a real state, not a disabled one: on `log.fillup` the third of {total, quantity, price per unit} is derived from the other two. It reads as a lighter ground plus secondary ink plus the `ƒ` badge — three signals, never colour alone — and it stays editable, because typing in it recomputes a different sibling.

## The helper line is one line and it is never a dialog

Hint (`type.caption`, `ink3`) and error (`type.caption` medium, `overdue.ink`, with a leading glyph) occupy the same slot; the error replaces the hint. One plain sentence. SPEC §10: validation runs on tap-Save and on blur, never on keystroke — `"1"` is a prefix of `"187412"` — and Save on the five `log.*` forms is never disabled; it validates, scrolls to the first failing field, focuses it and shows its error.

## Affixes are logical, not left/right

`CalmField.affix` sits on the **end** edge (`--space-5` inset, `ink3`, `type.body` medium) and the field reserves 76pt of end padding for it; `CalmField.lead` sits on the start edge and reserves 56pt. Both are `PositionedDirectional` inside a `Stack`, so they mirror with the layout and the odometer's `km ▾` chip lands on the correct side in fa/ar/ckb without a second code path.

The unit affix on the odometer field is **tappable** — it switches the unit for that entry only (SPEC §10) — so it is a `CalmChip`, not a label, and it carries the 52pt hit floor even though it paints ~40. The `~` estimate prefix and the `+432 km` delta are each one isolate-wrapped atom so the sign never detaches from the number; that wrapping is owned by `calm-typography-and-rtl`.

## Numeric fields

`CalmField.numeric` sets `fontWeight` semi and tabular lining figures (`FontFeature.tabularFigures()`, `FontFeature.liningFigures()`) so a column of readings aligns and a digit change does not reflow the string. `CalmField.lg` is the 72pt, `type.hero` variant used for the odometer on `log.odometer` — the one number on that screen, sized like it.

Odometer entry proper is `CalmNumberPad`, not the OS keyboard; see `references/overlays-and-chrome.md`.

## `CalmSegmented`, `CalmSwitch`, `CalmStepper`

- **`CalmSegmented`** is a tinted `radiusPill` track with `s1` of padding and options that flex equally. Selection is the raised `surface` pill **plus** `fw-semi` **plus** the `Semantics(selected: true)` flag — three signals, because `surface` on `surface2` is 1.16:1 and the pill is otherwise carried by `elev1` alone. It transitions over `motion.base` with `easeStandard`. Order mirrors free; it is a `Row`.
- **`CalmSwitch`** is 56×34 with a 28pt `surface` thumb on `elev1`, travelling 22pt toward the `end` edge over `motion.base` with `easeSettle`. Track off `surface3`, on `brand`. It goes **through `CalmPressable`** with `toggled:` set, not around it: a hand-assembled `Semantics` + `CalmTapTarget` + `GestureDetector` is a strict subset of the primitive that silently drops the `FocusableActionDetector`, so the switch has no Tab stop, no focus ring and no keyboard activation — and the traversal matrix, which enumerates `CalmPressable`, is exactly the gate that cannot see it. Never use it as the row's tap target: `CalmListRow.switchRow` is not navigable, the whole row toggles, and the pair is one `MergeSemantics` node labelled by the row title.
- **`CalmStepper`** is a `radiusPill` `surface2` track with two 48pt raised buttons and an 84pt-min tabular value between them. The − and + glyphs never mirror; their order does, for free, because it is a `Row`.

## Pickers

Dates open a picker from a read-only row — never a text field the user types a date into. Category and item choices are chips or a `CalmSheet`, never a dropdown spinner (SPEC §10). `CalmField.select` exists for the rare enumerated value and is a read-only field with a trailing chevron on the end edge; tapping it opens a sheet.

## Text scale, and what a field owes semantics

Nothing in `CalmField` has a fixed height — 56/72/108 are `minHeight` constraints, never `SizedBox`es — so at 200% text scale the box grows and the label above it wraps instead of clipping. Never reach for `FittedBox`, `TextOverflow.ellipsis` or `MediaQuery.withClampedTextScaling` to keep a German label on one line; that rule belongs to `accessibility-as-code` and it is not negotiable here either.

The field, its label, its hint and its error are **one** semantics node: the `TextField` already exposes `label`/`value`/`hint`, so pass the label and error text through `InputDecoration`-equivalent `Semantics` rather than leaving four sibling nodes for a screen reader to read out in layout order. An error that only exists as a coloured `Text` below the box is an error a blind user never hears.
