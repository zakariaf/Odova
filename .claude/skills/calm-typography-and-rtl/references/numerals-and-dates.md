# Numerals, calendars and dates in Calm

`i18n-rtl-l10n` owns the machinery — `NumberFormat`, ARB plurals, `normalizeToAscii`, FSI/PDI, the vendored `ckb` delegates. This file owns only what Calm and `SPEC.md` §5 decided, and where those decisions touch a rendered line of type.

## The six locales

| Locale | Dir | Default digits | Default calendar | Week starts |
|---|---|---|---|---|
| `en` | LTR | `latn` `0-9` | Gregorian | Sunday (`en-US`) / Monday (`en-GB`, `en-AU`…) |
| `de` | LTR | `latn` | Gregorian | Monday |
| `fr` | LTR | `latn` | Gregorian | Monday |
| `fa` | **RTL** | `extarab` `۰۱۲۳۴۵۶۷۸۹` U+06F0–06F9 | **Jalali** | Saturday |
| `ar` | **RTL** | `arab` `٠١٢٣٤٥٦٧٨٩` U+0660–0669 | Gregorian | Saturday (Sunday `ar-SA`, Monday `ar-MA`) |
| `ckb` | **RTL** | `extarab` | Gregorian (**Jalali in `ckb-IR`**) | Saturday |

**These resolve from the device REGION, not the language subtag**, and each is an independent user setting. The cases that catch people:

- `ar-MA`, `ar-DZ`, `ar-TN`, `ar-LY` → **Latin digits** and Maghrebi separators (`1.234,56`). Arabic-Indic digits read as foreign there.
- `ckb-IR` → Jalali and toman; `ckb-IQ` and unknown region → Gregorian and IQD. `fa-AF` (Dari) → Persian strings, Jalali, AFN.
- `ku`, `kmr`, `ku-TR` → **`en`, LTR**. Kurmanji is a different language in Latin script; Sorani Arabic script is worse for them than English.
- CLDR's default numbering system for `ckb` is `arab`; Calm ships `extarab`, because Sorani letterforms follow Persian conventions and two digit shapes inside one script read as a font bug.

## The four stored numeral values

```
numerals = auto | latin | arabic_indic | extended_arabic_indic
calendar = gregorian | persian
language = en | de | fr | fa | ar | ckb   (plus the sentinel `system`)
```

The Settings screen shows **three rows against four values**: `Automatic` stores `auto`; `Latin (0-9)` stores `latin`; `Local (۰-۹ / ٠-٩)` resolves by language and stores `extended_arabic_indic` for `fa`/`ckb`, `arabic_indic` for `ar`. The `Local` row appears only where the locale's default is not `latn` — nowhere else has a local digit set to name. **The old value name `persian` for a numeral system is dead and must appear nowhere**; `persian` is a *calendar* value only. There is no `hijri` in v1. Resolution code: `examples/numeral_formatting.dart`.

## One numbering system per screen

Never mix two digit sets on one screen. One system is active app-wide, resolved once, and every formatter reads it. The failure this prevents is subtle: a hard-coded `100` in the consumption label sits next to `۶٫۴` and looks like a rendering bug, which is why `SPEC.md` §5 forbids baking a digit into a translated string — `"ل/{n} کم"` with `n = 100`, so the hundred is shaped like every other number. `scripts/check_type_floor.sh` greps the ARB files for it.

## Shaping is the last step

```
value (num) → NumberFormat for the locale (grouping, separators, decimals) → shape digits → isolate → render
```

Shaping is a pure display transform, **1:1 by codepoint**, so the string length never changes and a field echoing input live needs no caret adjustment. Numbers are stored as numbers, never as digit strings; normalise back to ASCII before any comparison, sort or search (`i18n-rtl-l10n` → `normalizeToAscii`).

Separators come from the locale, not the digit set: `fa-IR` uses `٫` U+066B decimal and `٬` U+066C grouping; `fr-FR` a narrow NBSP U+202F for grouping; `de-DE` and `ar-MA` `.` for grouping and `,` for decimals.

## Always Latin, whatever the setting

| Field | Why |
|---|---|
| VIN | An identifier matched character by character against papers and databases |
| Backup / export JSON — every number, every date | RFC 8259 permits ASCII digits only. A JSON number containing `۴` is not JSON. |
| Export filenames, app version, build strings | Not user data |
| **Licence plate** | **Verbatim as typed**, never shaped either way — an Iranian plate legitimately contains Persian digits and a Persian letter. Transcribed, not computed. |

Free text — notes, workshop names — is likewise verbatim: we never rewrite someone's own characters.

## Money and units are one atomic run

A number and its unit are a single isolate: `۴۵٫۲ لیتر` split in two puts the unit on the wrong side. Never hard-code a currency symbol next to a number in a translation string — placement, spacing and any RLM belong to the formatter. A negative sign goes before the digits **inside** the same isolate, or it migrates to the other end in RTL.

Unit *abbreviations* come from our ARB files, not the platform unit formatter: ICU renders 45.2 L in `fa-IR` as `۴۵٫۲L` (Latin L, no space) and km in `ckb-IQ` as Latin `km`. ICU formats the number; the label is ours.

**Toman is display only.** Iranian amounts are stored and exported as IRR minor units; with `currency_display = toman` the formatter divides by 10, renders 0 decimals and appends `تومان`. Decimals from CLDR: JPY 0, KWD/IQD 3, EUR/USD 2.

## Calendars

Storage is Gregorian and calendar-agnostic — a civil date `"2026-03-14"` or an RFC 3339 UTC timestamp. **Jalali dates are never stored:** Solar Hijri leap rules have real implementation variance, and a backup a technical user can read has to contain dates they recognise.

Display calendar: `fa` and `ckb-IR` → Jalali; `ckb` elsewhere → Gregorian; `ar` → **Gregorian**, because every Arab country runs civil life on it and nobody books an oil change by the Hijri calendar.

Use the platform ICU `persian` calendar where available, otherwise pin one implementation of the Khayyam/Borkowski arithmetic and never swap it. ICU-verified anchors to keep in the round-trip test: 1 Farvardin 1403 = 2024-03-20; 1404 = 2025-03-21; 1405 = 2026-03-21; 30 Esfand 1403 (leap) = 2025-03-20.

**Ship our own month-grid picker** — neither platform has a reliable Solar Hijri picker with Persian month names across the OS versions we support. One picker driven by the active calendar: Jalali month names (فروردین، اردیبهشت، خرداد، تیر، مرداد، شهریور، مهر، آبان، آذر، دی، بهمن، اسفند), the region's first day of week, a today marker, and a hard "no future dates" rule for fill-ups and completed services. Arabic Gregorian month names fork by region — default to the Gulf/Egypt set (يناير/فبراير/مارس); `IQ SY LB JO PS` use كانون الثاني/شباط/آذار.

## Relative dates are bucketed before they are formatted

"in 47 days" is data; "in about 7 weeks" is an answer. Bucket first, then format with an ICU plural message — never a formatter call with a suffix glued on:

| Delta | Rendered |
|---|---|
| today | "Today" |
| ±1 day | "Tomorrow" / "Yesterday" |
| 2–13 days | "in {n} days" |
| 14–55 days | "in about {n} weeks" |
| ≥ 56 days | "in about {n} months" |
| overdue | a **separate string** — "{n} days overdue", never a negative relative time |

Overdue being its own string matters to `calm-due-state-and-status`: the overdue line is `titleLg` in terracotta and must read as a statement, not as a negative number.

## Screen-reader consequences

- Each text run exposes its language, so a Latin workshop name inside a Persian card is tagged `en` and the voice switches; numbers are announced in the display digit set, in spoken form, never as a glyph string.
- `~` is never read as "tilde": an estimated value carries `semanticsLabel` = "estimated, about {value}" (`common.estimated.a11y`), and the `~` stays in the visible string as the non-colour marker of an estimate.
- Bidi isolate controls never reach a semantics label, storage or export. Strip them at the boundary.
