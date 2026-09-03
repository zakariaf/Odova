# The reference set

## Naming

```
design/reference/calm/<screen>-<theme>-<direction>.png     390x844 @2x  -> 780x1688
design/reference/calm-contact-<theme>-<locale>.png          all 27 on one sheet
design/reference/_parity/<screen>-<theme>-<direction>.png   written by the comparison tool
```

`<theme>` is `light|dark`, `<direction>` is `ltr|rtl`. 28 screens × 4 = 112 images per system.

The `_parity/` directory is build output — it is regenerated on every comparison and is not
committed.

## The 28 screens

`firstrun.language`, `firstrun.vehicle`, `home`, `vehicle.switcher`, `reminders.list`,
`reminders.edit`, `log.fillup`, `log.service`, `log.expense`, `log.odometer`, `history`,
`report.service`, `costs`, `costs.fuel`, `trips.list`, `trips.edit`, `settings`, `vehicles`,
`vehicle.edit`, `settings.language`, `settings.units`, `settings.notifications`,
`settings.backup`, `settings.import`, `settings.about`, `dialog.discard`,
`dialog.confirmDelete`.

The `data-screen` attribute in `design/calm/screens.html` is the same string, and it is what
the shooter names the file after. If you add a screen to the app, add an artboard with that
`data-screen` and re-shoot; a screen with no reference cannot be parity-checked.

## The RTL images are real

`*-rtl.png` are not mirrored English. They are real Persian with Extended Arabic-Indic digits
(`۱۸۷٬۴۱۲`), the Jalali calendar (`۲۴ اسفند` for 14 March), toman rather than euro, and a
Latin licence plate (`M-AB 1234`) deliberately left unmirrored. That is deliberate: a layout
that only survives English is not a layout for this app, and a mirrored-Latin mockup would
hide exactly the bugs the RTL pass exists to find.

## The quantisation caveat — read this before comparing colours

The committed PNGs are palette-quantised by `tools/optimise_png.mjs` (256-colour palette,
58 MB → 19 MB, because 336 images live in this repo forever). They are visually identical and
**not colour-exact**: `#F8F2E9` may be stored as `#F9F3EA`.

Consequences:

- Never sample a colour from a reference PNG and treat it as a token value. Read
  `design/calm/odova.css`.
- Never compare app pixels to reference pixels for colour. Compare app pixels to the token
  list.
- The Δ24 tolerance in the comparison tool exists because of this step, and for no other
  reason.

## Regenerating, after a deliberate design change

```bash
FRAG_DIR=<fragments> node tools/build_screens.mjs   # rebuild design/calm/screens.html
node tools/shoot_design.mjs calm                    # 108 screens + 4 contact sheets
node tools/optimise_png.mjs                         # palette-quantise
```

About four minutes. Do it in the **same PR** as the design change, and say in the PR what
changed and why. A reference set that lags the design fails honest work, and a team that
learns to ignore a failing check has lost the check.

Regenerating to clear a failure you did not intend is the anti-pattern this whole skill
exists to prevent.
