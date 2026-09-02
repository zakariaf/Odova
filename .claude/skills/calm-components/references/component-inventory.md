# Component inventory

Every widget in `lib/ui/calm/`, its variants, its states, the slots it reads and its hit floor. Token names are the Dart form: `--color-ink-2` → `colors.ink2`, `--space-4` → `space.s4`, `--radius-2xl` → `shapes.radius2xl`, `--dur-base` → `motion.base`, `--fs-body-lg`/`--lh-body-lg` → `type.bodyLg`. A status family is one `CalmRamp`, so `--color-overdue-tint` → `colors.overdue.tint`, never `colors.overdueTint`; the four slots are `base` · `ink` · `tint` · `edge`. `--elev-sheen` is `colors.sheen` — a Color on `CalmColors`, never on `CalmShapes`, because Flutter has no inset shadow and the token is painted as a 1px top highlight. **Min hit** is the gesture target, which is often larger than the painted box (rule 6).

## Actions

| Widget | Variants | States | Slots read | Min hit / RTL |
|---|---|---|---|---|
| `CalmButton` | `primary` `secondary` `tonal` `quiet` `danger` `dangerSolid` `onState` `icon`; sizes `sm` 42 / `md` 52 / `lg` 60; `block` | rest, hover, pressed (scale .98 + `brandStrong`, shadow off), focus, disabled, loading | `brand`/`onBrand`/`elev1`; `brandSoft`/`brandSoftInk`; `surface2`/`ink`; `dangerTint`/`danger`; disabled `surface2`/`ink4`; `radiusPill`, `space.s6` inline (`s7` lg, `s4` sm), `type.bodyLg` semi | 52 (`sm` paints 42, hit 52). Icon+label order mirrors free in a `Row`; only a directional glyph flips. |
| `CalmButtonExplain` | — | — | `type.caption`, `ink3`, centred | Mandatory under any disabled `CalmButton` (SPEC §10). |
| `CalmChip` | filter, `selected`, `business` | rest `surface2`/`ink2`, hover `surface3`, pressed scale .97, selected `brand`/`onBrand` + semi, disabled 45% | `radiusPill`, `space.s4` inline, `type.label` medium, `motion.quick` + `easeOut` | Paints 40, hit **52**. Chip bar scrolls horizontally and starts at the `start` edge. |
| `CalmStepper` | — | rest, hover `surface3`, disabled `ink4` no shadow | track `surface2` + `radiusPill` + `space.s1` pad; buttons `surface` + `elev1`; value `type.bodyLg` semi, tabular | Buttons paint 48, hit **52**. Glyphs never mirror; the − + order mirrors with the `Row`. |
| `CalmSwitch` | — | off `surface3`, on `brand`, thumb `surface` + `elev1`, disabled 40%, focus ring | `motion.base` + `easeStandard` track, `motion.base` + `easeSettle` thumb | Paints 56×34, hit **52** tall. Thumb travel is `EdgeInsetsDirectional` so it slides toward the `end` edge in both directions. |
| `CalmSegmented` | `md` 46, `lg` 54, `stack` 66 (icon over label) | rest `ink2`, hover `ink`, active `surface` + `elev1` + semi, disabled `ink4` | track `surface2` + `radiusPill` + `s1` pad, `type.label` medium, `motion.base` + `easeStandard` | Options paint 46, hit **52**. Option order mirrors free (it is a `Row`). |

## Surfaces

| Widget | Variants | States | Slots read | Min hit / RTL |
|---|---|---|---|---|
| `CalmCard` | default `radius2xl`/`s6`; `lg` `radius3xl`/`s7`; `sm` `radiusXl`/`s5`; `tinted` `surface2` flat; `flat`; `raised` `elev2`; `quiet` `bgSunk` flat; `inverse` `surfaceInverse`/`inkInverse`/`elev2` | rest; pressed only when `onTap` is given | `surface`, `elev1` + `sheen`, `space.s3` gap; `card__eyebrow` `type.caption` semi `ink3`; `card__title` `type.headline` semi; `card__text` `type.body` `ink2` | n/a. **Never a border.** Inside `inverse`, secondary ink is `inkInverse` at 66% — the ink ramp does not invert with the surface. |
| `CalmRowGroup` | default, `tinted`, `flat`; optional header/footer | — | `surface`, `radius2xl`, `elev1` + `sheen`, `divider` hairline between rows; header `s4 s5 s2` `type.caption` semi `ink2` | n/a. One outer radius; `ClipRRect` so the first and last rows inherit it. |
| `CalmListRow` | `md` 64, `lg` 76, `compact` 56, `standalone` (`radiusXl` + `elev1`), `nav`, `switchRow`, `selected`, `danger` | rest transparent, hover `surface2`, pressed `surface3`, disabled 42%, selected `brandSoft` | padding `s4 s5`, gap `s4`; title `type.bodyLg` medium `ink`; sub `type.caption` `ink3`; value `type.body` medium `ink2` end-aligned; chevron `ink4` | 64 (56 compact) ≥ 52. Lead/main/end are start/centre/end — the whole row mirrors; only the disclosure chevron flips. `switchRow` is not tappable-as-navigation. |
| `CalmTile` | default, `brand` | non-interactive | `surface2` (`brandSoft`), `radiusXl`, `s4` pad; value `type.title` semi tabular; label `type.caption` `ink3` | n/a. Three across a `Row`; order mirrors. |
| `CalmIconTile` | `brand` `overdue` `dueSoon` `ok` `business`, `round` | static | 44 square, `radiusMd` (`radiusPill` when `round`), `<state>.tint`/`<state>.ink`, default `surface2`/`ink2` | Decorative; it is the `lead` slot of a row, not a target. |
| `CalmDueCard` | `primary` (`radius3xl`, tint→surface gradient, `elev2`), `secondary` (72, `radiusXl`); ×6 `DueState` | rest, pressed, snoozed (fourth line) | `CalmStatusStyle.of(context, state)` → `.base`/`.ink`/`.tint`; `surface`; progress track `surface3`, fill animates width over `motion.slow` + `easeStandard` | 72 ≥ 52. Owned jointly with `calm-due-state-and-status`. |
| `CalmBadge` | `overdue` `due` `dueSoon` `ok` `unknown` `needsOdometer` `business` `brand` `neutral` `count` `dot` | static | one `(tint, ink)` pair each, read off the state's `CalmRamp`: `overdue.tint`/`overdue.ink`, `due.tint`/`due.ink`, `dueSoon.tint`/`dueSoon.ink`, `ok.tint`/`ok.ink`, `unknown.tint`/`unknown.ink`, `needsOdometer.tint`/`needsOdometer.ink`, `business.tint`/`business.ink`, `brandSoft`/`brandSoftInk`, `surface2`/`ink2`; `count` is `brand`/`onBrand`. `radiusPill`, `type.caption` semi, 26 tall | Non-interactive; never the only signal. |
| `CalmStatusDot` | 12pt and 8pt; shape per state | static | `CalmStatusStyle.of(context, state).base`; **shape is normative**: filled ● overdue, ring ◉ due, small ● dueSoon, filled ● ok, 2px outline unknown at 70%, hollow ◌ needsOdometer | Decorative — `ExcludeSemantics`; the wording carries the meaning. |

## Input

| Widget | Variants | States | Slots read | Min hit / RTL |
|---|---|---|---|---|
| `CalmField` | `md` 56, `lg` 72 (`type.hero`), `numeric` (semi + tabular), `multiline` 108, `select`, with `affix`/`lead`, `computed` | rest `surface2` + 1.5 transparent ring, hover `surface3`, focus `surface` + 2 `brand`, error `overdue.tint` + 2 `overdue.base`, disabled `ink4` on `bgSunk` | `radiusLg`, `s4 s5` pad, `type.bodyLg` medium; label `type.label` semi `ink2`; hint `type.caption` `ink3`; error `type.caption` medium `overdue.ink`; placeholder `ink4` regular | 56 ≥ 52. Affix sits on the **end** edge (`inputgroup__affix`), lead on the start edge; both are `EdgeInsetsDirectional`. |

## Chrome and overlays

| Widget | Variants | States | Slots read | Min hit / RTL |
|---|---|---|---|---|
| `CalmScaffold` | `sunk` `bg-sunk`, `brand` | — | `bg`, `space.screenPad`, `space.appbarH`/`tabbarH`/`homebarH` | Body padding is inline, so it mirrors. |
| `CalmAppBar` | default 56, `large` (title at `type.titleLg`, subtitle), `vehicle` (title + chevron as one target), `modal` (Cancel · title · Save grid) | button rest `ink2`, hover/pressed `surface2` + `ink` | `bg`, `type.title` semi at `trackingTight`, `radiusPill` on buttons; `modal` actions are `radiusSm`; `motion.quick` | Buttons 52. Leading is at the `start` edge; the back chevron mirrors. |
| `CalmTabBar` | 5 slots, centre `+` | item rest `ink3`, active `brand` + semi label; fab pressed scale .94 | `bg`, top hairline `divider`, `space.tabbarH` 62; fab 62 `brand`/`onBrand` + `elev2`, offset −18 | Items ≥52. Slot order mirrors; the `+` stays centre. |
| `CalmSheet` | default (max 88% height), `full` | enter: rise 24 + fade over `motion.sheet` 420ms `easeStandard` | `surface`, `radius3xl` **top corners only** (`borderStartStart`/`borderStartEnd`), `elev4`, `scrim`; grip 44×5 `ink` at 18% | Actions are stacked full-width. Top corners are logical, so they are correct in RTL by construction. |
| `CalmDialog` | default, `danger` icon | enter: scale .96 → 1 + fade over `motion.base` `easeSettle` | `surface`, `radius3xl`, `elev4`, `s7 s6 s6` pad, `scrim`; icon 56 `brandSoft`/`brandSoftInk` (`dangerTint`/`danger`) | Actions stacked, full-width, ≥52. Text is `start`-aligned, not centred. |
| `CalmSnackbar` | with action (always Undo on a destructive op) | enter/exit `motion.base` | `surfaceInverse`/`inkInverse`, `radiusXl`, `elev3`, inset `s5`, sits above `tabbarH + homebarH + s3` | Action ≥52; it is the only undo path (SPEC §10). |
| `CalmNumberPad` | digit, `action` (`surface2`, no shadow), `confirm` (`brand`, spans 2) | pressed `surface3` + scale .96 + shadow off over `motion.instant` | keys 68 `surface` + `radiusXl` + `elev1` + `sheen`, `type.titleLg` medium tabular lining; display `surface2` + `radius2xl` + `type.display` | Keys 68. The grid does **not** mirror — digit order is fixed; only backspace flips. |
| `CalmEmptyState` | — | static | `s8` block padding, art 104 `surface2`/`ink3`, `type.title` semi at `trackingTight`, `type.bodyLg` `ink2` capped at 28ch | Action button ≥52, centred. |
| `CalmAllClear` | — | static | `ok.tint` → `surface` radial wash, `radius3xl`, `s8 s6 s7` padding, `elev2` + `sheen`; mark 92 `ok.tint`/`ok.ink` with a 12pt halo; `type.titleLg` semi at `trackingTight`; the `since` block is `surface2` + `radiusXl` | The best screen in the set — never a grey icon in a box (SPEC §9). |

## Constructor parameters

The signature is the contract, and it lives here. A screen that composes Calm widgets does not get to invent a shorter parameter list: `CalmRowGroup` takes `rows`, not `children`, and a consumer example that says otherwise does not compile against the widget it names. Each signature below is the one the shipped reference implementation declares; the **From** column names that file, so a change to a signature is a change to that file and to this table together.

| Widget | Parameters | From |
|---|---|---|
| `CalmPressable` | `{required Widget child, required double borderRadius, VoidCallback? onTap, VoidCallback? onLongPress, double pressScale = kCalmPressScaleButton, bool enabled = true, String? semanticLabel, bool isButton = true, FocusNode? focusNode, bool expandTapTarget = false}` | `calm-components/examples/calm_pressable.dart` |
| `CalmDirectionalIcon` | `(IconData icon, {required double size, required Color color})` — positional glyph | `calm-components/examples/calm_pressable.dart` |
| `CalmButton` | `{required String label, required VoidCallback? onPressed, CalmButtonVariant variant = CalmButtonVariant.primary, CalmButtonSize size = CalmButtonSize.md, IconData? icon, bool block = false, bool loading = false, DueState? dueState}` — one unnamed constructor. There is no `CalmButton.primary()`: `primary` is the default `variant`, and `icon` is `CalmButtonVariant.icon`. `onPressed: null` is the disabled state and obliges a `CalmButtonExplain` beneath it. | `calm-components/examples/calm_button.dart` |
| `CalmButtonExplain` | `{required String reason}` | `calm-components/examples/calm_button.dart` |
| `CalmSurface` | `{required Widget child, required Color color, required double radius, List<BoxShadow> shadow = const [], bool sheen = true, EdgeInsetsGeometry padding = EdgeInsets.zero}` | `calm-components/examples/calm_card.dart` |
| `CalmCard` | `{required Widget child, CalmCardVariant variant = CalmCardVariant.standard, VoidCallback? onTap, String? semanticLabel}` | `calm-components/examples/calm_card.dart` |
| `CalmRowGroup` | `{required List<Widget> rows, String? header, String? footer, bool tinted = false, bool flat = false}` — the list is **`rows`**. | `calm-components/examples/calm_rows.dart` |
| `CalmListRow` | `{required String title, String? subtitle, String? value, Widget? lead, Widget? end, VoidCallback? onTap, CalmRowSize size = CalmRowSize.md, bool enabled = true, bool selected = false, bool danger = false, bool standalone = false, bool showChevron = false}` — the disclosure flag is **`showChevron`**. There is no estimate flag: the `~` is already inside the formatted `title` string, which is what keeps the distinction alive in a grayscale golden. | `calm-components/examples/calm_rows.dart` |
| `CalmField` | `{required String label, required TextEditingController controller, String? hint, String? errorText, String? placeholder, Widget? affix, Widget? lead, CalmFieldSize size = CalmFieldSize.md, bool numeric = false, bool computed = false, bool enabled = true, FocusNode? focusNode, TextInputType? keyboardType, TextInputAction? textInputAction, List<TextInputFormatter>? inputFormatters, ValueChanged<String>? onSubmitted}` | `calm-components/examples/calm_field.dart` |
| `CalmNumberPad` | `{required String value, required String unit, required String hint, required ValueChanged<String> onDigit, required VoidCallback onDecimal, required VoidCallback onBackspace, required VoidCallback onConfirm, required String confirmLabel, required String decimalLabel, required String secondaryLabel, required VoidCallback onSecondary, required String backspaceSemanticLabel}` | `calm-components/examples/calm_number_pad.dart` |
| `CalmNumberPadKey` | `{required CalmKeyKind kind, required VoidCallback onTap, String? label, IconData? icon, String? semanticLabel}` | `calm-components/examples/calm_number_pad.dart` |
| `CalmDueCard` | `{required CalmDueView view, required CalmDueDensity density, required VoidCallback onTap, required VoidCallback onAction}` — one constructor taking a view object, not `.primary()`/`.secondary()` named constructors and not loose strings. `CalmDueView` is `{required DueState state, required DueDriver driver, required DueConfidence confidence, required String title, required String statusLine, required String actionLabel, String? anchorLine, String? snoozeLine, double? progress}`. | `calm-due-state-and-status/examples/calm_due_card.dart` |
| `CalmStatusDot` | `{required CalmStatusStyle style}` — it takes the resolved style, not a `DueState`. | `calm-due-state-and-status/examples/calm_status_dot.dart` |
| `CalmScaffold` | `{required CalmAppBar appBar, required List<Widget> children, Widget? tabBar, Widget? footer}` — the body is **`children`**, a list the scaffold scrolls and spaces; there is no `body`. | `calm-layout-and-motion/examples/calm_scaffold.dart` |
| `CalmAppBar` | `{required String title, bool showVehicleChevron = false, VoidCallback? onTapVehicle, List<Widget> actions = const []}` | `calm-layout-and-motion/examples/calm_scaffold.dart` |
| `CalmTabBar` | `{required int index, required ValueChanged<int> onChanged, required VoidCallback onAdd, required String addLabel, required List<String> labels}` — exactly four labels plus the `+`. | `calm-layout-and-motion/examples/calm_scaffold.dart` |
| `CalmAllClear` | `{required String headline, required String nextLine, String? fuzzLine, CalmSinceLine? since}` — the title parameter is **`headline`**, and the since block is a `CalmSinceLine{label, figure}`, not a pre-joined sentence. | `calm-layout-and-motion/examples/calm_all_clear.dart` |
| `CalmEmptyState` | `{required IconData icon, required String title, required String body, Widget? action}` | `calm-layout-and-motion/examples/calm_all_clear.dart` |
| `CalmTile` | `{required String value, required String label, bool brand = false}` | `calm-components/examples/calm_tile.dart` |

## Tokens with no consumer

Three groups in `tokens.json` are declared and used by nothing in `odova.css`. Do not invent uses for them; they are reported as findings against the design, not licence to improvise.

- `--color-<state>-edge` — all seven (`overdue`, `due`, `dueSoon`, `ok`, `unknown`, `needsOdometer`, `business`), in both themes. They have a slot (`CalmRamp.edge`, surfaced as `CalmStatusStyle.edge`) and are carried through resolution, but fourteen values with no rule referencing them. They read like the outline a badge or a tinted card was meant to carry before the no-border rule landed.
- `--radius-xs` (8) — zero uses. The smallest radius Calm actually draws is `--radius-sm` (12), on the modal-head action.
- `--ease-in` — zero uses. Every transition in the sheet uses `--ease-standard`, `--ease-out` or `--ease-settle`; if an exit curve is wanted, `--ease-in` is the slot, but nothing has claimed it yet.
