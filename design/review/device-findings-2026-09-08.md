
---

## Verified on a device, 2026-09-08

Rebuilt and re-run on the Pixel 8a emulator (Android 15) and the iPhone 16 Pro
simulator (iOS 18), from a fresh install through first run.

| | Was | Now |
|---|---|---|
| A-2 save error | every unclassified failure said "out of space" | a refusal names its own reason: "That reading is lower than the one before it" |
| A-1 save | reported a full disk | **saves** — History shows the row, the recompute and reschedule run |
| B-1 sheet bottom | last row under the home indicator | clear space below it |
| B-3 sheet grip | a line across the whole sheet | the 44pt centred pill `.sheet__grip` specifies |
| B-2 More sheet | opened empty on three forms | not offered where it has nothing behind it |
| C-1 tab bar | About unreachable on `settings` | About fully visible above the bar |
| D-1 dark mode | tapping Dark did nothing | the whole app repaints, and the choice survives |
| D-2 permission | no OS dialog, ever | **"Allow Odova to send you notifications?"**, and Notifications flips Off → On |
| D-3 service chips | `+ Other` only | the catalogue, named |
| E-1 names | seven rows reading "Service" | Oil and filter, Brake pad check, Inspection, Insurance renewal, Air filter, New tyres, Coolant |

**Still open.** A-3, the Fuel field showing `0` after `10` was typed, did not
reproduce: the trio holds `10` in every test, including the odometer-blur-fuel
sequence the device was in. It needs the value off a device that is in that
state, not another guess.

**The More section for `service` and `expense` is a feature, not a fix.**
`ServiceRecord` has `vendor`, `invoiceRef` and `notes` and the modal collects
none of them; `ExpenseDraft` has no such fields at all. The row is hidden rather
than lying, and `log_more_sheet.dart` says in the code what building it needs.

---

## Second pass, 2026-09-08

Six more from the same session, after the fixes above were installed.

| | What was reported | Root cause | Fix |
|---|---|---|---|
| A-3 | "I added 10 L and I can see just the 0" — reopened, with a second sighting at 50 | **Not the trio.** `CalmField` reserved a flat 76pt of end padding for *any* affix — the figure `.inputgroup` measures for the odometer's tappable unit chip. On `log.fillup`'s three-up row each field gets about a third of a 390pt screen, so 76 of roughly 106 points went to a one-letter `L` and the number had about thirty left. The value was correct throughout; the glyph was clipped by its own suffix. | `affixExtent`, with `kCalmCompactAffixExtent = 28` for a one- or two-character label |
| F-1 | "I clicked on one of them to edit and the name is empty" | §8 gives `ServiceItem.label` meaning only for `kind = custom`, so all 28 seeded items have a null label **by construction** and the field bound it straight through | the kind's name as a *placeholder*, not a prefill — see below |
| F-2 | "the confirmation below, most of it is hidden behind the menu" | the snackbar was laid out against the raw viewport, so on a shell screen it came up under the tab bar with its Undo unreachable | `calmSnackbarBottomInset` adds `tabbarH` when there is a bar, and takes an `overTabBar` override for `log.*` |
| F-3 | "the input for fuel is too small, we need to make it wider" | same as A-3 | same as A-3 |
| F-4 | "I'm clicking on the language and it's not possible to change it" | `LocaleController.build()` returned `systemLanguage` unconditionally and never read the row §13's screen had just written | it reads `settingsProvider`, falling back when the value is one this build does not ship |
| F-5 | "maybe we should show the icon for the money" | every money field shipped as a bare number, on all three forms | `currencySymbolFor(currency, formatsTag)` as the affix, from the *stored* code |
| F-6 | "I pressed Save and got this screen — a Save at the top right, a Save Service below, and Close" | §10 says a mark-done save replaces the body with the panel; the modal replaced only the **body** and left the app bar Save, the segmented control and the footer live over it. The row is written by then, so a second Save writes it twice. | `_showingConfirmation` gates all three |

### Why F-1 is a placeholder and not a prefill

The obvious fix is to prefill the field with the kind's name, and it is wrong.
The moment a prefilled value is saved the item *has* a label, and a labelled
item stops following the locale — so a user who opened a reminder once in
English would keep "Oil and filter" after switching to German, while every
reminder they never opened became "Öl und Filter". A placeholder shows the name,
leaves `label` null, and makes typing the deliberate act it is.

### The shape these keep having

Two, and both are about where a thing was tested rather than what it does.

**A seam declared, tested, and never connected.** `canonicalDisplay`'s `grouped`
flag, `OdovaApp.themeMode`, `LocaleController`, the notification permission port,
the 28 kind names and the More sheet's fields were each written, each had a
passing unit test, and none was wired to the thing that reads it. A unit test
over a function nobody calls is green forever.

**A widget tested only in isolation.** `LogMoreSheet` through `pumpApp` and never
through `CalmSheet.show`; `ServiceConfirmationPanel` through `pumpApp` and never
through `LogModal`; `CalmTabBar` always under a `MaterialApp` that supplies the
`Material` the shell does not. Each test was true about the widget and silent
about its surroundings, which is where all three defects were.

**Still open.** iOS shows its notification permission dialog once. After a
denial `requestPermissions` is a no-op and "Turn on Reminders" does nothing
visible — the remedy is a deep link to OS Settings, which needs a platform
channel whose transitive tree has to be audited against §2's no-network rule
first. Android re-prompts and works today.
