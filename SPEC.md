*Your car, handled.*

Odova is an offline maintenance and running-cost log for people who keep a car for years and would rather not think about it. It tracks service intervals by distance and by date, fuel and consumption, the odometer, trips, and every euro the vehicle costs — for one vehicle or for a household of four. The home screen answers one question: **what does my car need next?** Everything else in the app exists to make that answer correct.

This specification is platform-agnostic. Nothing in it assumes Flutter, Swift, Kotlin or React Native; the reference implementation happens to be Flutter, but any statement that depends on that is a bug in this document.

## 1. Who it is for

A commuter, a family, a used-car owner, a rideshare or delivery driver, a plumber with two vans. They keep a vehicle five years or more. They do not enjoy this task and they are not enthusiasts — nobody here wants a dyno chart. They want the app to take under a minute a month and to tell them things rather than ask them things.

Four facts about this user drive every decision that follows.

**They will not maintain a database.** So the app persists facts and derives everything else. The user enters what happened — a fill-up, a service, a reading — and never enters a due date, a consumption figure, a monthly total or a "next service at". Every screen that shows a number that was not typed by a human recomputes it at read time.

**They open the app rarely and log in bad conditions** — at a pump, in the rain, one-handed, in a basement with no signal. So the log form is one modal with four segments, the odometer is a required field on every fill-up and service (it is the only thing keeping projections honest), Save is never disabled without an explanation, and confirmation is a snackbar with Undo rather than a dialog.

**They forget.** Most of what the app knows will be incomplete: a service book from a previous owner, three months of missed fill-ups, an odometer last updated in March. So the app never guesses in a way that looks like fact. An estimated odometer is prefixed `~`, a projected date is fuzzy ("around mid-October"), a broken fuel segment is discarded rather than averaged, and an item whose history is unknown says `unknown` instead of `overdue`. The app would rather show a dash than a plausible lie.

**Their history is worth money and there is no server holding a copy.** Eight years of service records is the most valuable object in the app and the second-most-valuable thing they own after the car. So data survives every app update, every delete is undoable in the moment, a safety copy is written before every destructive operation, and the backup file is a plain JSON file the user can read in a text editor and keep anywhere.

## 2. Non-negotiables

These are settled. Everything in the body of this spec is built on top of them; nothing in the body may contradict them.

| Rule | Why |
|---|---|
| **No account, no server, no sync, no analytics, no network call of any kind.** The app ships with no networking code and no network permission it can avoid. | The product promise is "nothing leaves your phone". A promise you can only keep by policy is not a promise; one you keep by having no client is. Also: it works in a car park with aeroplane mode on, forever. |
| **The backup is one plain, unencrypted JSON file.** Export hands it to the OS share sheet; import reads it back. No password, no key, no account recovery. | The user must be able to restore on a new phone in five years with no help from us and no memory of a credential. The file is deliberately human-readable: a technical user can open it and see their own history. |
| **Six languages from day one, in both directions.** en, de, fr (LTR); fa, ar, ckb (RTL). RTL is a first-class target, not a port. | Mirroring, numerals, calendars, fonts and plural rules are structural. Retrofitting them means rewriting every screen; there is no cheap later. |
| **Local notifications only.** No push infrastructure exists or ever will. | Follows from "no server". It also caps what notifications can ever be: at most two in any rolling seven days, one per day, all vehicles combined. |
| **Data survives app updates.** Every schema migration writes a safety backup first, using the *old* schema's writer, before the new code touches anything. | Losing eight years of service history is the worst bug this app can have. It outranks every feature. |
| **Storage is canonical.** Distance in integer metres, volume in integer millilitres, energy in watt-hours, gas by mass in grams, money in integer minor units plus an ISO 4217 code. Each record also keeps the unit and currency it was *entered* in, for display fidelity. Never store a converted or rounded value. | A household runs a van in miles and a bike in km. Converting on write loses the user's number; converting on read loses nothing. Changing a display unit must never rewrite stored data. |
| **Derived values are never persisted.** Consumption, cost per km, monthly totals, next-due dates and due status are computed by named pure functions at read time, and cached only in memory. | Two sources of truth diverge the moment a record is edited. A stored due date survives an import and is then wrong forever. |
| **Facts are dates; bookkeeping is instants.** Event dates are zoneless Gregorian `YYYY-MM-DD`. `created_at` / `updated_at` are RFC 3339 UTC. Persian (Jalali) is display-only; Hijri is not offered in v1. | Storing an instant for "the day I filled up" produces off-by-one-day bugs the first time someone drives across a border. |
| **Identity is `<prefix>_<ULID>`** (`veh_`, `rem_`, `srv_`, `lin_`, `fil_`, `exp_`, `trp_`, `odo_`, `cor_`), generated on device, never reused, never renumbered. This is the id in the database, in the export file, and in every notification payload. | One scheme, everywhere. It is time-sortable (which the history pagination relies on) and self-describing when a human opens the file. UUIDv7 is withdrawn. |
| **Import replaces everything. There is no merge in v1.** Pick file → validate → mandatory preview → confirm → atomic swap. Nothing is written before Confirm; a crash mid-import leaves the old data intact. | Merge means conflict resolution, which means a UI no ordinary driver can operate. Replace is one sentence the user understands: *everything now in Odova will be replaced by this file.* The merge branch is deleted from the navigation graph. |
| **Delete is immediate, with Undo in the moment.** `deleted_at` exists in the schema as the mechanism behind Undo and is always null once the snackbar expires. No trash, no 30-day bin, no tombstones in the export. | Two deletion models cannot both be right. A bin is a second inbox the user must learn. The safety net is the pre-operation backup, not a wastebasket. |
| **One projection engine, one lead-time formula.** Daily distance = two-endpoint slope over the last 180 days (≥2 readings, ≥14 days, ≥100 km), falling back to all history, then `expected_annual_m`, then 12,000 km/yr; clamped 5–500 km/day; confidence reported as `measured \| assumed \| default`. Notice window = `clamp(10% of interval, 200 km, 1000 km)` and `clamp(10% of interval in days, 7, 30)`. | The tiered A/B/C model and the 0.6/0.4 blend are withdrawn. Two engines produce two different due dates for the same car depending on which paragraph the engineer read. |
| **`whichever_first` is the only combining rule.** Compute the distance axis and the time axis separately; the worse status wins; `DueState` reports which axis drove it. Mode is derived from which interval fields are non-null. No `rule` enum, no `mode` field. | Three of the four proposed enum values had no defined semantics. An interval that is set is an axis that counts. |
| **No layout code uses left or right.** Padding, alignment, insets and swipe actions are `start`/`end`. A hard-coded `left`/`right` outside the icon-asset layer fails CI. | It is the only rule that keeps RTL correct as the app grows past the screens in this document. |
| **Every user-visible sentence is one ICU message** with named placeholders, plurals with CLDR categories, and punctuation inside the translated string. No concatenation, no `if (n == 1)`. Interpolated values are wrapped in first-strong isolates at render time; bidi control characters are never stored. | Arabic needs all six plural categories and French needs three. Concatenation cannot be translated, and stored control characters poison the export. |
| **Machine-readable output is always English, ASCII and Gregorian.** JSON keys, CSV headers, digits, dates, decimals and filenames, regardless of the user's language, numerals or calendar. Localisation applies to the UI and to the service-history PDF only. | A backup that only opens correctly on a Persian-locale device is not a backup. |
| **v1 has no photos and no attachments anywhere.** No receipt scans, no invoice PDFs, no vehicle photo — a colour swatch and a silhouette only. | An attachment store is a second data-durability problem, a second export format and a second privacy conversation. The `Attachment` entity and `photo_id` are withdrawn from the model. |

---

---

## Contents

1. [1. Who it is for](#1-who-it-is-for)
2. [2. Non-negotiables](#2-non-negotiables)
3. [3. Domain model and rules](#3-domain-model-and-rules)
4. [4. Reminders and notifications](#4-reminders-and-notifications)
5. [5. Languages, RTL and formats](#5-languages-rtl-and-formats)
6. [6. Backup, export and import](#6-backup-export-and-import)
7. [7. Screen map and navigation](#7-screen-map-and-navigation)
8. [8. First run, the garage, and vehicles](#8-first-run-the-garage-and-vehicles)
9. [9. Home — what does my car need next](#9-home-what-does-my-car-need-next)
10. [10. Logging — fill-up, service, expense, odometer, trip](#10-logging-fill-up-service-expense-odometer-trip)
11. [11. History, timeline, entry detail and search](#11-history-timeline-entry-detail-and-search)
12. [12. Fuel insights, costs and reports](#12-fuel-insights-costs-and-reports)
13. [13. Settings, language, units, notifications, backup and restore](#13-settings-language-units-notifications-backup-and-restore)
14. [14. Edge cases v1 must handle](#14-edge-cases-v1-must-handle)
15. [15. Explicitly out of v1](#15-explicitly-out-of-v1)
16. [16. Version two](#16-version-two)
17. [17. Definition of done for v1](#17-definition-of-done-for-v1)
18. [18. Decisions still open](#18-decisions-still-open)

---

## 3. Domain model and rules

The entity definitions here are canonical. Every other section — the export file included — is a projection of them, not a second model.

A fact is what the driver observed or paid: a reading, a volume, a date, an amount. Everything else — consumption, cost per kilometre, "next due", "overdue" — is a pure function computed on read. And where the data can't support a number, the answer is `—` plus one sentence saying why, never a plausible figure: a wrong consumption number is worse than none, because the user will believe it.

### Canonical units

| Dimension | Stored as | Type | Notes |
|---|---|---|---|
| Distance | metres | int64 | No float drift over 300,000 km; whole km and whole miles both round-trip exactly (1 mi = 1609.344 m). |
| Liquid volume | millilitres | int64 | 1 L = 1000 mL, 1 US gal = 3785.411784 mL, 1 imp gal = 4546.09 mL. |
| Energy (EV) | watt-hours | int64 | kWh × 1000. |
| Gas by mass (CNG/LPG) | grams | int64 | Sold by kg where it is sold at all. |
| Money | minor units + ISO 4217 code | int64 + string(3) | `{amount_minor: 4599, currency: "EUR"}`. Exponent from a shipped ISO 4217 table — JPY/KRW 0, KWD/BHD/OMR/TND 3. Never a float. |
| Interval (time) | calendar months | int | Manuals say "12 months". Calendar addition stops a 12-month service creeping earlier every year. |
| Event date | `YYYY-MM-DD`, no time, no zone | string | A fill-up happened *on the 3rd* wherever you were. Always Gregorian; Persian (Jalali) is display-only; Hijri is not offered in v1. |
| Bookkeeping time | RFC 3339 UTC, ms | string | `created_at`, `updated_at`, `deleted_at`. Machine time, not user time. |

### Identity, timestamps, deletion

```
Record {
  id          string        # <prefix>_<ULID>: 26 Crockford base-32 chars,
                            # veh_ rem_ srv_ lin_ fil_ exp_ trp_ odo_ cor_
  created_at  instant
  updated_at  instant       # >= created_at, bumped on every field write
  deleted_at  instant?      # null = live
}
```

Ids are the same string in the database, in the export file and in every notification payload (`veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD`); being time-sortable, they give history pagination a free deterministic tiebreak. v1 import is replace-only — ids exist so that a v2 merge is possible.

**Delete is immediate and permanent to the user; soft in storage only for the length of the snackbar.** Delete stamps `deleted_at` and Undo clears it; deleted rows are excluded from every query and every derived value, and no screen ever lists them. When the snackbar expires the row is purged, so `deleted_at` is null on everything that remains — no bin, no tombstones, nothing deleted in the export.

Deleting a vehicle cascades to every child row with that `vehicle_id`, stamped with the same `deleted_at`; Undo restores the set. "Erase vehicle permanently" is the one hard delete, behind a typed confirmation. Deleting a `ServiceItem` never touches history: every referencing `ServiceLine` is rewritten to `service_item_id = null`, keeping its label and amount.

Every non-global entity carries `vehicle_id` directly, including rows that could infer it from a parent (an expense inside a trip carries both `trip_id` and `vehicle_id`). Every query here is scoped to the active vehicle, and denormalising makes orphan detection on import a single pass.

### Entities

```
Vehicle : Record {
  name                 string            # required: "The Golf", "Van"
  make, model          string?
  year                 int?
  plate, vin           string?
  vehicle_type         car|van|motorcycle|truck|other      # icon + seeded set
  is_business          bool              # default false; drives the cost split
  fuel_kind_default    FuelKind
  tank_capacity_ml     int?              # sanity-check only, never used in maths
  purchase_date        date?
  purchase_odometer_m  int?
  purchase_price       Money?
  status               active|archived|sold
  sold_on              date?
  sold_price           Money?
  expected_annual_m    int?              # asked once at onboarding; feeds the rate fallback
  colour               string?           # swatch key; v1 has no vehicle photo
  notes                string?
  sort_order           int
  notifications_muted  bool              # default false
  # per-vehicle overrides of Settings; null = inherit
  currency             string(3)?
  distance_unit        DistanceUnit?
  volume_unit          VolumeUnit?
  consumption_unit     ConsumptionUnit?
  notice_distance_m    int?
  notice_days          int?
}

ServiceItem : Record {                   # the reminder definition
  vehicle_id           string
  kind                 ServiceKind       # catalogue enum, or `custom`
  label                string?           # required when kind = custom, else an optional override
  interval_distance_m  int?              # null = not distance-based
  interval_distance_unit DistanceUnit?   # the unit the interval was entered in
  interval_months      int?              # null = not time-based
  target_odometer_m    int?              # one-off items only (cambelt at 120,000 km)
  target_date          date?             # one-off items only (registration renewal)
  baseline_date        date?             # "last done March 2024", set at item creation
  baseline_odometer_m  int?
  notice_distance_m    int?              # null = computed default (below)
  notice_days          int?
  is_tracked           bool              # false = seeded but not adopted; invisible to the engine
  is_active            bool              # false = user paused it; never notifies, greys out
  notify               bool              # default true
  priority             safety|normal|low
  rollover             from_actual|from_due   # default from_actual
  repeats              bool              # default true; false = completes once and retires
  snoozed_until        date?
  snooze_until_odometer_m int?
  snooze_count         int               # reset to 0 on completion or interval edit
  notes                string?
}
# No `mode` field and no `rule` enum: which axes apply is derived from which interval fields
# are non-null, and combination is always whichever-comes-first.
# `notice_distance_m` / `notice_days` ARE the per-item lead override reminders.edit writes;
# there are no separate lead_* fields. `notice_months` is withdrawn — the time notice window
# clamps to 7–30 days and cannot be expressed in months.

ServiceRecord : Record {                 # a job that was actually done
  vehicle_id           string
  occurred_on          date
  odometer_m           int?              # strongly encouraged; see degradation rules
  odometer_unit        DistanceUnit      # the unit this reading was entered in
  odometer_estimated   bool              # default false; true = the app filled it in
  cost_estimated       bool              # default false; true = no cost was recorded (notification Done)
  vendor               string?
  invoice_ref          string?
  warranty_until       date?             # optional: the day the workshop's warranty on this job expires
  notes                string?
  lines                [ServiceLine]     # >= 1
}
ServiceLine {
  id                   string
  service_item_id      string?           # null = a one-off job, or a deleted item
  label                string            # "Oil and filter", "Front pads", "Labour"
  amount               Money             # >= 0
  part_number          string?
  notes                string?
}
# Cost is ALWAYS the sum of lines; there is no second total field. Quick entry writes one
# unlabelled line. One record resets several items — a major service resets oil, filter and
# inspection — by carrying one line per item, at the record's date and odometer.

FillUp : Record {
  vehicle_id           string
  occurred_on          date
  odometer_m           int?              # null only from import; the entry form requires it
  odometer_unit        DistanceUnit      # the unit this reading was entered in
  fuel_kind            FuelKind
  quantity_ml          int?              # exactly one of these three is non-null,
  quantity_g           int?              #   discriminated by fuel_kind
  energy_wh            int?
  quantity_unit        VolumeUnit        # the unit the quantity was entered in
  total_cost           Money             # >= 0
  is_full_tank         bool              # default true
  chain_broken         bool              # "I forgot to log one before this"; default false
  grade                string?           # "95", "Diesel B7", "DC 150kW"
  station              string?
  trip_id              string?
  notes                string?
}
# Unit price is NOT stored. The form takes any two of {total, quantity, price per unit} and
# computes the third; only total and quantity persist. Store all three and they will one day
# disagree, and then no one knows which is the receipt.

Expense : Record {
  vehicle_id           string
  trip_id              string?
  occurred_on          date              # the day it was PAID
  category             ExpenseCategory
  label                string?           # required for `other`
  amount               Money             # may be negative: refunds, warranty reimbursement
  covers_from          date?             # optional coverage window, for amortisation
  covers_to            date?
  odometer_m           int?
  odometer_unit        DistanceUnit      # the unit this reading was entered in
  vendor               string?
  notes                string?
}
# No recurrence engine. One payment is one row: an annual premium is one expense with a
# 12-month window, amortised by the monthly cost view.

Trip : Record {
  vehicle_id           string
  title                string?
  purpose              business|commute|personal|other
  started_on           date
  ended_on             date?             # null = open trip
  start_odometer_m     int?
  end_odometer_m       int?
  manual_distance_m    int?              # used only when odometer endpoints are absent
  odometer_unit        DistanceUnit
  notes                string?
}
# Trips are never the source of truth for total distance — people log some trips, not all.
# The odometer is; trip distance exists only to attribute cost.

OdometerReading : Record {
  vehicle_id           string
  occurred_on          date
  odometer_m           int
  odometer_unit        DistanceUnit      # the unit this reading was entered in
  source               manual|fillup|service|expense|trip_start|trip_end|import
  source_id            string?           # the row that produced it
  notes                string?           # carried by import and by derived readings; `log.odometer` offers no notes field
}
# EVERY record carrying an odometer emits a reading: one table computes distance history and
# enforces monotonicity. Derived readings follow their parent and are not directly editable.

OdometerCorrection : Record {
  vehicle_id           string
  from_reading_id      string            # the first reading on the new scale
  previous_m           int               # what the old cluster last showed, in metres
  new_m                int               # what the new cluster shows, in metres
  odometer_unit        DistanceUnit
  reason               cluster_replaced|rollover|unit_mixup|typo_fix
  notes                string?
}

Settings {                               # singleton, id = "settings"
  schema_version       int
  language             system|en|de|fr|fa|ar|ckb   # default system
  calendar             gregorian|persian
  numerals             auto|latin|arabic_indic|extended_arabic_indic   # auto = the locale's CLDR default
  first_day_of_week    int
  theme                system|light|dark
  currency_default     string(3)
  currency_display     none|toman        # default none; toman for fa-IR. Storage stays IRR.
  distance_unit        km|mi
  volume_unit          l|gal_us|gal_uk
  consumption_unit     l_100km|km_l|mpg_us|mpg_uk|kwh_100km|mi_kwh
  notice_distance_m    int?              # null = use the computed default
  notice_days          int?
  notification_time    local time-of-day # when the daily due check fires
  quiet_hours_from     local time-of-day # default 21:00
  quiet_hours_to       local time-of-day # default 08:00
  weekdays_only        bool
  notify_service       bool
  notify_odometer      bool
  notify_backup        bool
  active_vehicle_id    string?
  onboarding_done      bool
  last_backup_at       instant?
  last_backup_reminder_at instant?
}
```

Provenance units are display fidelity only and never enter arithmetic.

v1 has no photos and no attachments: no `Attachment` entity, no `photo_id`, no `attachment_ids`, and nothing referencing a media directory.

### Enums

```
DistanceUnit     km|mi
VolumeUnit       l|gal_us|gal_uk
ConsumptionUnit  l_100km|km_l|mpg_us|mpg_uk|kwh_100km|mi_kwh
FuelKind         petrol|diesel|lpg|cng|electric|hybrid|other
ExpenseCategory  insurance|tax_registration|parking|toll|fine|wash|
                 tyre_storage|accessories|finance|other          # ten values, no more
ServiceKind      oil_and_filter|air_filter|cabin_filter|fuel_filter|spark_plugs|timing_belt|
                 brake_pads_check|brake_pads_front|brake_pads_rear|brake_fluid|coolant|
                 transmission_fluid|
                 wheel_alignment|tyre_rotate|tyre_replace|battery|wipers|inspection|
                 registration|insurance_renewal|ac_service|
                 chain_lube|chain_and_sprockets|valve_clearance|fork_oil|
                 reduction_gearbox_oil|battery_12v|custom
```

These spellings are canonical everywhere: database, export, CSV headers, notification payloads. Registration and insurance are service items, not expenses, because the user thinks of them as *things that come due*; paying them is a separate `Expense` row.

Catalogue defaults are **copied** into real `ServiceItem` rows at vehicle creation, filtered by `fuel_kind_default` and `vehicle_type` — an EV gets no oil, no plugs, no timing belt. The catalogue is a seed, not a live reference: an app update must never move an existing vehicle's intervals. Which items seed on, and with what intervals, is in *Reminders and notifications*.

**Notice window** — the default when `notice_*` is null on the item, the vehicle and Settings:

```
notice_distance_m = clamp(0.10 × interval_distance_m, 200 km, 1000 km)
notice_days       = clamp(0.10 × interval_months × 30.44, 7 d, 30 d)
```

For a one-off item (`target_odometer_m` or `target_date` set with no matching interval) there is no percentage to take, so the window is the clamp ceiling: `notice_distance_m = 1000 km`, `notice_days = 30 d`. An explicitly set `notice_distance_m` or `notice_days` — on the item, the vehicle or Settings — is used as written and is **not** clamped; the clamp defines the computed default only, which is why `settings.notifications` may offer 2,000 km.

### Scope: global vs per vehicle

Language, calendar, numerals, theme, notification settings, unit and currency defaults, the active vehicle and backup state are global. Everything else hangs off a vehicle, and vehicles never share service items, intervals, fuel history or costs. Nothing is aggregated across vehicles except Home's other-vehicles row, the Costs tab's All-vehicles toggle, and the backup file.

### The odometer: continuity and corrections

All distance maths runs on a **cumulative** odometer, never the raw dash number.

```
cumulative_m(reading) = reading.odometer_m
                      + Σ (c.previous_m − c.new_m) for every correction c whose
                        from_reading_id sorts at or before `reading`
```

Readings sort by `(occurred_on, created_at)`. A cluster swapped for one showing 0 at a real 187,412 km gives an offset of +187,412 km; a 999,999 rollover gives +1,000,000 km. A `unit_mixup` — a km cluster fitted to a miles car — is the same arithmetic once both sides are in metres: `previous_m − new_m` with each side converted first. The dash number is what the app *displays*; the cumulative number is what it *computes with*.

**Monotonicity.** Readings must be non-decreasing in cumulative terms.

| Situation | Resolution |
|---|---|
| Typo | Edit the number. Nothing else changes. |
| Cluster replaced, rollover, or unit change | Create an `OdometerCorrection` from this reading. History is preserved; the offset carries forward. A correction can be deleted from its divider row in `history`; deleting it removes the offset and re-runs the vehicle recompute, which may re-expose a monotonicity violation on the readings it was covering. |
| Backdated entry that fits between two existing readings | Allowed silently. |
| Backdated entry that doesn't fit | Same three-way dialogue. |
| Entry dated before the earliest reading | Allowed if its cumulative value is ≤ the earliest existing reading and ≥ `purchase_odometer_m` when set. It becomes the new earliest reading and re-anchors any item falling through to `first_reading`. If it is *higher*, block: "Your earliest reading is 140,000 km on 2 September. A reading from May 2019 has to be lower than that." |

A vehicle's readings need not begin at purchase: backfilling a second-hand car's service book is expected and must never require a correction event.

**Soft warnings** (warn, never block): an implied rate above 2,000 km/day since the previous reading; a single jump above 100,000 km; a reading 1.5–1.7× its predecessor on a miles vehicle (a probable km/mi mix-up), evaluated after any per-entry unit conversion.

A vehicle must have at least one odometer reading. Onboarding requires it, and everything else is anchored to it.

### The due engine

**Daily distance** is specified once, in *Reminders and notifications*. `dailyDistance(readings, today)` returns `{metres_per_day, confidence}` with `confidence ∈ measured | assumed | default`; the UI may not present a projected date as a firm date unless confidence is `measured`.

#### Current odometer

```
estimateOdometer(vehicle, today) -> { metres, as_of, is_projected, stale_days }
  last = latest reading
  stale_days = days_since(last.occurred_on)
  if stale_days > 180:
      metres = cumulative(last); as_of = last.occurred_on; is_projected = expired
  else:
      metres = cumulative(last) + rate × stale_days
      as_of = today; is_projected = stale_days > 0
```

After six months of silence the app stops guessing rather than rendering 10,000 km of invention as a number the user can act on. An expired estimate is never shown with `~`: it shows the entered figure and its date (`187,412 km · last entered 12 Jul 2025`), and every distance axis on that vehicle reports `needs_odometer` at any severity.

#### Due state per item

```
anchor = resolveAnchor(item, serviceRecords)
  = the newest ServiceRecord line referencing this item → (its occurred_on, its cumulative odometer)
  ↳ else (item.baseline_date, item.baseline_odometer_m)
  ↳ else (vehicle.purchase_date, vehicle.purchase_odometer_m)
  ↳ else the earliest odometer reading and its date
  ↳ else none → status = unknown

DISTANCE AXIS (only if interval_distance_m or target_odometer_m is set)
  due_at_odo  = target_odometer_m ?? anchor.odometer + interval_distance_m
  remaining_m = due_at_odo − estimateOdometer().metres
  grace_m     = the notice-window distance formula, same clamp

  remaining_m >  notice_distance_m      → ok
  0 < remaining_m <= notice_distance_m  → due_soon
  −grace_m <= remaining_m <= 0          → due
  remaining_m < −grace_m                → overdue

TIME AXIS (only if interval_months or target_date is set)
  due_on         = target_date ?? addMonths(anchor.date, interval_months)
  remaining_days = due_on − today
  grace_days     = the notice-window days formula, same clamp
  same four bands, against notice_days and grace_days

COMBINE  ("whichever comes first")
  status = max severity of the two axes
  severity: ok < due_soon < due < overdue
  driver  = the axis that produced the worst status (distance | time | both | none)
```

**`from_due` anchoring.** For `rollover = from_due`, the anchor *date* is not the record's date: walk the cycle forward from the item's baseline rung — `anchor.date = addMonths(base.date, interval_months × k)` for the smallest k ≥ 1 whose result is after the newest completing record's `occurred_on`, where `base` is the `baseline_date`, else `purchase_date`, else the earliest reading. The anchor odometer stays the record's. `from_actual` anchors on the record's own date and odometer.

`rollover = from_actual` anchors the next cycle on the date and odometer the job was actually done; `from_due` anchors it on the date it *was* due — registration falls in June whenever you paid.

**Grace exists on purpose.** Nobody books a garage the afternoon the counter ticks over. `due` is amber and actionable; `overdue` is red and means you have been ignoring it. Shouting "overdue" on day zero teaches people to ignore the app, and then the timing belt goes.

**Stale odometer.** If `stale_days > 60`, the distance axis is the driver, and its status would be `due` or `overdue`, the status becomes **`needs_odometer`** — ask for a reading rather than make an accusation supportable only by arithmetic. `due_soon` still shows normally. If the time axis independently reaches `due` or `overdue`, that wins and shows as itself; time never needs an odometer.

`snoozed` (`snoozed_until` in the future, or the odometer below `snooze_until_odometer_m`) suppresses notifications but not the card. `paused` (`is_active = false`) outranks everything and is silent.

```
DueState {
  status              paused|unknown|ok|due_soon|due|overdue|needs_odometer
  driver              distance|time|both|none
  remaining_m         int?
  remaining_days      int?
  due_at_odometer_m   int?
  due_on              date?
  projected_due_date  date?    # single sort key across both axes
  confidence          measured|assumed|default
  progress            float    # 0..1+, the max of the two axes' fractions
}

projected_due_date = min(
    due_on,
    last_reading.occurred_on + (due_at_odo − cumulative(last_reading)) / rate
)
```

`projected_due_date` is the only sort key the home screen uses. It makes "10,000 km" and "12 months" comparable on one axis, which is the whole point of the app.

### Fuel maths

**Full tank to full tank. Nothing else is computed, ever.**

A *segment* runs from one full fill to the next; its distance is the odometer difference between them. Its volume is the sum of every fill **after** the opening fill up to and including the closing one — the opening fill's own fuel is consumed in the segment that follows it. Getting this off by one fill is the most common bug in this category.

```
buildFuelSegments(fills_of_one_fuel_kind_sorted_by (occurred_on, odometer, created_at)):
  segments = []; open = null; pending = []
  for f in fills:
      if f.chain_broken or f.odometer_m is null:
          open = (f.is_full_tank and f.odometer_m != null) ? f : null
          pending = []
          continue
      if open == null:
          open = f.is_full_tank ? f : null
          pending = []
          continue
      pending.append(f)
      if f.is_full_tank:
          d = cumulative(f) − cumulative(open)
          v = Σ quantity(x) for x in pending
          if d > 0 and v > 0:
              segments.append({ from: open, to: f, distance_m: d, volume: v,
                                partial_count: len(pending) − 1 })
          else:
              flag both fills for the user; emit nothing
          open = f; pending = []
  return segments
```

The hard cases, decided:

| Case | Rule |
|---|---|
| **The very first fill** | No consumption figure. Ever. It opens a segment and nothing more: "your first figure arrives at your next full fill" beats a number derived from an unknown starting tank level. |
| **Partial fill** | `is_full_tank = false`. Its volume joins the enclosing segment; it never opens or closes one. Two partials then a full still yields one correct segment. |
| **Missed fill** | The user sets `chain_broken` on the fill after the gap. The segment that would have closed there is **discarded entirely** — not averaged, not pro-rated. A new segment opens there if that fill was full. |
| **Fill with no odometer** | Treated as a chain break, same consequence. |
| **Two fills at the same odometer, or negative distance** | Segment discarded, both fills flagged. A data error, not a 0 L/100 km. |
| **Volume > tank capacity × 1.15** | Saved, with a warning. Some people carry a jerrycan. |
| **Fuel kinds** | Segments are built per `fuel_kind` independently. A bi-fuel LPG car has two consumption series and the app never merges them. |
| **Electric** | Identical rules with `energy_wh`. "Full" means the driver's usual charge target. If they never mark a charge full, the app shows cost per distance only and says so; it does not invent an energy figure from partial charges. |

```
segmentConsumption(s)      = s.volume / s.distance_m        # canonical, converted for display
averageConsumption(segs)   = Σ volume(segs) / Σ distance_m(segs)
```

The lifetime average is a **total-over-total**, never the mean of per-segment figures. A mean of means over-weights a 40 km segment against a 900 km one and drifts a few percent high for anyone who tops up in town.

**Trend.** `consumptionTrend` compares the mean of the last 3 segments against the 6 before them and reports `thirstier` / `leaner` / `steady` at a ±8% threshold. Under 9 valid segments it returns `insufficient_data` and the UI shows nothing — three data points is not a trend, and a false "getting thirsty" is an alarm they will remember.

`unitPrice(fill) = total_cost / quantity` — derived at display time, to 3 decimals.

### Currency

**Per vehicle, with a global default for new vehicles** — a work van bought abroad and a household's main car can each have their own. Every money row stores the currency it was entered in, as a fact that is never rewritten. Changing a vehicle's currency changes only what new entries default to; no historical row is touched, and no exchange rate is applied, ever, because a made-up rate silently rewrites the resale value of someone's service history.

Where a total would mix currencies the app does not sum, it groups: `€1,240 · £80`, and every per-distance and per-month figure is computed once per currency present. A bulk "set currency on these N records" tool exists; it does not convert the amounts.

**Presentation-only special case:** Iranian users price in toman and bank in rial. Storage and export stay IRR minor units; `Settings.currency_display = toman` divides by 10 at render. `IRT` is not an ISO 4217 code and is never written anywhere.

### Display conversion and rounding

Conversion happens once, at render, by dividing the canonical integer by the factor in the units table. Never round before storing; never round a rounded value.

```
l_100km   = (ml/1000) / (m/1000) × 100      km_l   = (m/1000) / (ml/1000)
mpg_us    = (m/1609.344) / gal_us           mpg_uk = (m/1609.344) / gal_uk
kwh_100km = (wh/1000) / (m/1000) × 100      mi_kwh = (m/1609.344) / (wh/1000)
```

| Value | Decimals | Note |
|---|---|---|
| Odometer | 0 | Cars show whole units. |
| Trip / segment distance | 0 at ≥100, else 1 | |
| Volume, energy | 2 | |
| L/100km, km/L, MPG, kWh/100km | 1 | The measurement isn't good enough for two. |
| Money | currency exponent | 2 for most, 0 for JPY, 3 for KWD. |
| Price per litre/gallon/kWh | 3 | Fuel is priced to the tenth of a cent in most markets. |
| Cost per km/mi | 3 | 0.089 €/km rounds to 0.09 and loses the comparison. |
| Percentages | 0 | |

Rounding is **half away from zero**, on the absolute value. Half-even is more correct and looks broken to a user checking against their phone calculator.

Distance and volume units are chosen independently of the consumption unit: the app suggests a pairing (km+L→L/100km, mi+gal_us→MPG US) and then lets the user pick anything. Plenty of people log in litres and think in MPG.

### Invariants and validation

| Rule | On violation |
|---|---|
| Cumulative odometer is non-decreasing per vehicle | Block; offer typo / correction / backdate (above) |
| `occurred_on` ≤ today for FillUp, ServiceRecord, OdometerReading, Trip | Block. These record the past. |
| `ServiceItem.baseline_date` ≤ today | Block. It is a last-done anchor. |
| Future dates allowed | `Expense.occurred_on` (prepaid), `Expense.covers_to`, `ServiceItem.target_date` |
| `FillUp.odometer_m` present | Block on entry. Nullable only from import, where the fill is treated as a chain break. |
| `FillUp.quantity` > 0 | Block |
| `FillUp.total_cost` ≥ 0 | Block negatives. A free fill is 0. |
| `ServiceLine.amount` ≥ 0 | Block negatives. A warranty job is 0. |
| `Expense.amount` may be negative | Allowed — refunds, warranty reimbursement, parts sold on |
| `ServiceItem` has at least one of `interval_distance_m`, `interval_months`, `target_odometer_m`, `target_date` | Block |
| `interval_*` > 0 | Block |
| Exactly one of `quantity_ml` / `quantity_g` / `energy_wh`, matching `fuel_kind` | Block |
| `ServiceRecord` has ≥ 1 line | Block; quick entry auto-creates one |
| `Trip.ended_on` ≥ `started_on`; `end_odometer_m` ≥ `start_odometer_m` | Block |
| `covers_to` ≥ `covers_from` | Block |
| `vehicle_id` and `trip_id` resolve to a live row; `service_item_id` is null or resolves to a live row | Block on write. Orphan handling on import is in *Backup, export and import*. |
| `updated_at` ≥ `created_at` | Repair on read |
| Duplicate fill-up: same vehicle, same date, odometer within 1 km, volume within 0.1 L | Warn on entry |

**The device clock is not trusted.** `today` is validated on every resume against `[build_date, build_date + 10 years]`. Outside that range the app enters **clock-suspect mode**: a non-dismissible banner ("Your phone's date looks wrong — {date}. Odova can't work out what's due until it's fixed." + **Open date settings**), every due state renders `unknown`, no notification is scheduled, and every logging form defaults its date to the newest `occurred_on` in the database with Save blocked and the reason inline. Without this, a phone that reset to 1970 writes records whose dates are indistinguishable from real ones afterwards.

A record whose `occurred_on` is more than 1 day after both the newest existing `occurred_on` and `created_at`'s date is warned about, not blocked: "That's {n} days after anything else you've logged. Is the date right?"

### Derived values

Every derived value is a pure function: deterministic, no I/O, no clock except an injected `today`. Results may be memoised in-process, invalidated by any write to the vehicle; nothing is written to storage. The engines above define `cumulative`, `estimateOdometer`, `resolveAnchor`, `computeDueState`, `projectDueDate`, `buildFuelSegments`, `segmentConsumption`, `averageConsumption`, `consumptionTrend` and `unitPrice`; `dailyDistance` is defined in *Reminders and notifications*. The rest:

| Derived value | Function |
|---|---|
| Next thing due, per vehicle | `nextDue(vehicle)` = min `projected_due_date` over tracked, active items |
| Status counts for Home | `dueSummary(vehicle)` |
| Fuel cost per distance | `fuelCostPerDistance(segments)` → per currency |
| Lifetime distance | `lifetimeDistance(vehicle)` = max cumulative − purchase odometer |
| Distance in a period | `distanceBetween(vehicle, from, to)` |
| Service record total | `recordTotal(record)` = Σ lines |
| Amortised expense share | `monthlyShare(expense, month)` — spread across `covers_from..covers_to`, else charged in full to `occurred_on`'s month |
| Total cost of ownership | `totalCost(vehicle, from, to)` → `Map<currency, minor>` over fills + service lines + expenses |
| Cost per distance | `costPerDistance(vehicle, from, to)` = `totalCost` / `distanceBetween` |
| Cost per month | `monthlyCost(vehicle, month)`, incl. amortisation |
| Cost breakdown by category | `costByCategory(vehicle, from, to)` |
| Trip distance | `tripDistance(trip)` = end − start, else `manual_distance_m` |
| Trip cost | `tripCost(trip)` = its fills + its expenses, per currency |
| Vehicle age, distance since purchase | `vehicleAge()`, `distanceSincePurchase()` |

### Durability

The store carries a `schema_version`; the export carries an independent `format_version`. Migrations are forward-only, numbered, additive by default, and run in a single transaction; no migration deletes a column holding user-entered data, it stops reading it. Mechanics, safety copies, failure recovery and time budgets are in *Backup, export and import*.

---

## 4. Reminders and notifications

A reminder is due at "10,000 km **or** 12 months, whichever comes first". The date half is trivial. The distance half is impossible as stated: the phone has no odometer, only readings the user typed in and a guess about what has happened since. So the whole system is one move — **convert distance into a date**: estimate how far this vehicle travels per day, project when it crosses the threshold, schedule against that date.

Due/soon/overdue status and the whichever-comes-first combination belong to the due engine in *Domain model and rules*; this section owns the number it consumes — metres per day — and everything that keeps the projection from going stale or going loud.

---

### 1. Projecting distance into a date

#### 1.1 The reading series

Every source of odometer truth merges into one per-vehicle series of `(date, odometer)`:

| Source | Contributes a reading | Note |
|---|---|---|
| Manual odometer entry | Yes | The canonical source |
| Fill-up | Yes | The form requires an odometer — which is why active fuel users never see a nudge. Nullable only on imported rows, and such a row is a chain break |
| Service record | Yes | Including records created by marking a reminder done |
| Trip with an end odometer | Yes | |
| Trip with only a distance | **No** | Trip distances are partial and would double-count against fill-ups |
| Expense, insurance, tax entries | No | |

Normalisation, in order, before any rate is computed:

1. Sort ascending by date; two readings on the same date collapse to the highest odometer.
2. A reading lower than its predecessor is not a rate endpoint — typo or odometer replacement. The data layer owns the correction event; the projection restarts the series there.
3. A reading is a *rate endpoint* only if it is ≥1 day from the previous endpoint. Same-day pairs produce meaningless rates.

#### 1.2 Rate estimation

Two-endpoint slope over a window, **not** the mean of per-segment rates: averaging gives a one-day gap the same weight as a two-month one, so one short segment during a holiday week can double the estimate.

```
dailyDistance(vehicle) -> { metres_per_day, confidence }

  window = readings in the last 180 days
  a = earliest endpoint in window, b = latest endpoint overall
  if endpoints >= 2 and (b.date - a.date) >= 14 d and (b.odo - a.odo) >= 100 km:
      return { (b.odo - a.odo) / (b.date - a.date), measured }

  same test over all history                     -> measured
  if vehicle.expected_annual_m:                  -> { expected_annual_m / 365, assumed }
  return { 12,000 km / 365 ≈ 33 km/day, default }
```

Clamped to **5–500 km/day** — a rate outside that came from a typo, not from driving. `expected_annual_m` comes from the first-run question about yearly distance; the 12,000 km fallback exists so a vehicle added five minutes ago still shows something on the home screen.

Seasonality and a job change are the same signal and indistinguishable under two years of data, so we do not try to separate them. The 180-day window leans recent on purpose: *an estimate that overshoots is corrected at the next reading; a lagging one silently misses the due point.*

#### 1.3 From a rate to a projected date

```
odo_now       = last.odo + rate × (today − last.date)
threshold     = last_done_odo + interval_km
projected_due = today + ceil((threshold − odo_now) / rate)
```

That is the distance axis's date; the time axis is exact and the engine takes the worse of the two.

**The projection expires.** If `today − last.date > 180 days` the window is empty and `odo_now` is invention. The projection then returns the last **entered** reading unprojected, `as_of = last.date`; every distance axis on that vehicle reports `needs_odometer` regardless of severity, and no `~` figure appears anywhere — the strip reads `187,412 km · last entered 12 Jul 2025`. Tapping it: *Your last reading is over six months old, so Odova has stopped guessing. Enter what the dash says now.* + **Update odometer**.

Worked example — Passat, oil every 10,000 km / 12 months, last done 2026-02-10 at 108,200 km:

```
readings give rate = 41 km/day, confidence = measured
last reading 2026-08-20 @ 116,050 km;  today 2026-09-02
odo_now       = 116,050 + 41×13   = 116,583
threshold     = 108,200 + 10,000  = 118,200
remaining     = 1,617 km → 40 days → projected_due = 2026-10-12
time axis     = 2027-02-10        → distance wins
notice        = 30 days → early notification 2026-09-12, delivered 09:00
UI reads: "Oil and filter — due around 12 October, at about 118,200 km"
```

#### 1.4 Showing an estimate as an estimate

| Confidence | Date precision allowed | Odometer precision allowed |
|---|---|---|
| `measured` | "around 12 October" | "~118,200 km" |
| `assumed` | "around mid-October" | "~118,000 km" |
| `default` | **none — the surface reads `Odova needs a reading to say when`** | **none — no figure at all, in the app or in a notification** |

Binding on every screen:

- Projected odometers are prefixed `~` and rounded to the nearest 100 km / 50 mi. Never a raw figure like 116,583.
- Remaining-distance figures (`In about 5,000 km`) follow the same rules: rounded to the nearest 100 km / 50 mi, hedged by the surrounding ICU message rather than by a `~` prefix, and never shown at `confidence = default`.
- Projected dates never carry a weekday or a time of day.
- Estimated values use the *estimated* text treatment (lighter weight, distinct from entered values), so a user can tell at a glance which numbers the app knows and which it guessed.
- Tapping any estimated value opens a one-sentence explanation and one action: **Update odometer**.
- Never show a confidence percentage, a bar, or the word `measured`. The hedging is in the words — under the no-analytics rule the real error will never be measured, so it must never be implied by a number.

---

### 2. Re-projection

#### 2.1 Triggers

| Trigger | Scope |
|---|---|
| New/edited/deleted odometer reading, fill-up, service record, trip with end odometer | That vehicle |
| Reminder created, edited, deleted, muted, marked done, snoozed | That reminder + that vehicle's schedule slots |
| Vehicle added, archived, deleted, unit system changed | That vehicle |
| App foreground after ≥6 h, or day rollover while foregrounded | All vehicles |
| Everything in §6.2 | All vehicles, full rebuild |

Reprojection is a pure function over the local database, and five vehicles × 16 reminders is 80 rows of arithmetic. Recompute everything, always; there is no incremental-invalidation cleverness to get wrong.

#### 2.2 Avoiding churn

Undamped, the app would cancel and reschedule every notification every time the user buys fuel.

1. **Stable identity.** Key = `<vehicle_id>:<reminder_id>:<stage>`, stage ∈ `early | due | overdue1 | overdue2 | nudge`. Rescheduling is cancel-then-add on the same key, so the OS never accumulates duplicates. Android needs a 31-bit int id: hash the key, persist the key→id mapping in `scheduled_notifications`, linear-probe on collision.
2. **Hysteresis.** If a pending notification's recomputed fire time moves by **less than 7 days**, do not touch it. A projection wandering ±2 days never reaches the threshold.
3. **No retroactive firing.** A pending notification whose recomputed time is in the past goes to the *next* delivery slot, never to "now". Waking a phone the instant the user logs a fill-up is how an app gets uninstalled.
4. **Once fired, done.** A fired stage is never rescheduled; the reminder advances. Re-projection moves future stages only.
5. **Debounce.** Coalesce reprojection requests within a 2-second window. During an import, suppress entirely and rebuild once after commit.
6. **Text is re-baked on reschedule.** Bodies are frozen into the OS at schedule time (§6.2), so a reschedule regenerates the body from current numbers.

---

### 3. The nudge for a reading

`odo_now`'s error grows linearly with the age of the last reading. At some point the app has to ask.

#### 3.1 When it is warranted

```
drift = rate × days_since_last_reading
stale = drift > 0.15 × (smallest active interval_km on this vehicle)
```

Warranted when `stale` **and** the vehicle has at least one active distance-driven reminder projected due within 120 days. Escalated: if any reminder is projected due within 21 days and the last reading is older than 21 days, warranted regardless of the formula.

#### 3.2 Two channels

**In-app (always on, no permission needed, primary).** One line at the top of the vehicle screen:

> Odometer last updated 8 weeks ago. The estimates below are getting rough. **[Update]**

Tapping opens the number pad with the projected value prefilled and selected; dismissing hides it for 7 days. This card is the whole feature.

**Notification (backstop).** Sent only when the card has been visible-and-unactioned across at least two app opens, or the app has not been opened in 21 days.

#### 3.3 Cadence limits — hard

| Limit | Value |
|---|---|
| Nudge notifications per vehicle | Max 1 per 30 days |
| Nudge notifications across all vehicles | Max 1 per 14 days — pick the vehicle with the largest `drift` |
| Counts against the weekly cap (§4.3) | Yes |
| Never nudge | Within 14 days of the vehicle being created; on an archived or off-the-road vehicle; on a vehicle with no distance-driven reminders |
| Give-up rule | 3 consecutive nudges with no reading logged within 7 days of each → **stop nudge notifications for that vehicle for 180 days.** The in-app card stays. |

The give-up rule matters most: a user who ignores three requests has answered, and the app degrades gracefully anyway — it drops to hedged language and keeps working.

---

### 4. Notification content and cadence

#### 4.1 Stages

| Stage | Fires at | Repeats |
|---|---|---|
| `early` | `projected_due_date − notice` | once |
| `due` | `projected_due_date` | once |
| `overdue1` | `projected_due_date + 14 d` | once |
| `overdue2` | `projected_due_date + 45 d` | once |
| — | **nothing after that, ever** | The item stays red at the top of the home screen indefinitely. Two overdue pings is the entire budget for being ignored. |

`notice` is the `due_soon` band defined in *Domain model and rules* — `clamp(10% of interval, 200 km, 1000 km)` and `clamp(10% of interval in days, 7, 30)`, whichever axis produces the earlier date. One window drives both the card colour and the `early` notification, so they can never disagree.

#### 4.2 What it says

Vehicle name is the title, the thing is the body: one sentence, no emoji, no exclamation mark, no "Don't forget!". **Absolute anchors, not countdowns** — "due in 3 weeks" is a lie if delivery drifts (§6.3). An `assumed` body is hedged and carries no km figure; a `default` body carries **neither a date nor a figure** — §1.4 binds notification copy exactly as it binds a screen.

| Situation | Title | Body |
|---|---|---|
| Early, distance-driven, `measured` | Passat | Oil and filter due around 12 October, at about 118,200 km. |
| Early, distance-driven, `assumed` | Passat | Oil and filter is coming up — probably in the next few weeks. |
| Early, distance-driven, `default` | Passat | Oil and filter may be coming up. Odova needs a reading to say when. |
| Early, date-driven | Passat | Insurance renews on 14 March. |
| Due | Passat | Oil and filter is due now. Last done 10,100 km ago. |
| Overdue (`overdue1`) | Passat | Brake pads check was due 2 weeks ago. |
| Overdue (`overdue2`) | Passat | Brake pads check is still open — due 45 days ago. |
| Grouped (≥2 items, one vehicle) | Passat | 3 things due this month: oil and filter, tyre rotation, inspection. |
| Grouped (≥2 vehicles) | Odova | 4 things due across Passat and the van. |
| Nudge | Passat | What's the odometer? Last reading was 8 weeks ago. |

Tap targets are the deep-link table in *Screen map and navigation*: an item notification opens `home` with its card pinned to the primary slot and highlighted for ~2 s, and no modal; a grouped one opens `home` for `payload.vehicleId` — the first vehicle named in the body when several are grouped — with no card pinned; a nudge opens `log.odometer`, nothing focused. Actions on the notification itself: **Done** and **Snooze** only — iOS allows four, but two stay legible in six languages, three of them RTL and two verbose. **Done** is the zero-typing write of §7.3 and never launches the app; **Snooze** applies §7.2's default in the background.

**The payload.** Every notification the app schedules carries the same three-field object, and routing reads nothing else:

```
NotificationPayload {
  kind        reminder.due | reminder.overdue | reminder.grouped |
              odometer.nudge | keeper | backup.nudge   # required, one of exactly six
  vehicleId   string (veh_…)                   # required on every kind
  reminderId  string (rem_…)                   # optional — see the table
}
```

| `kind` | Carries `reminderId` | What `vehicleId` names | Scheduled by |
|---|---|---|---|
| `reminder.due` | **yes, required** | the item's vehicle | the `due` stage (§4.1) |
| `reminder.overdue` | **yes, required** | the item's vehicle | the `overdue1` and `overdue2` stages — both use this one `kind`, and the body distinguishes them |
| `reminder.grouped` | **no — absent** | the first vehicle named in the body when several are grouped; the only vehicle when one | coalescing in §4.3 step 1 |
| `odometer.nudge` | **no — absent** | the vehicle being asked about | §3 |
| `keeper` | **no — absent** | the vehicle named in the keeper body | §6.2 |
| `backup.nudge` | **no — absent** | the vehicle named first in the body; ignored by routing | *Backup, export and import* — at most one per 90 days, and only with 20+ new records since the last export |

The `early` stage of an item ships as `kind = reminder.due`; `early` is a schedule stage, not a payload kind, and nothing outside the scheduler needs to tell them apart. The backup nudge ships as `kind = backup.nudge`; it is scheduled by the export bookkeeping in *Backup, export and import*, not by the due engine, but it is a notification like any other and **it counts against the cap below**. A payload naming a vehicle or reminder that no longer exists is not an error — see *Screen map and navigation*, which owns routing for all six kinds and is the authority on where each lands. Payload shape is versioned with the app: an app update invalidates every pending payload and forces a full rebuild (§6.2).

#### 4.3 The cap — a hard rule

> **Never more than 2 notifications in any rolling 7 days, and never more than 1 in a calendar day, across every vehicle and every reminder combined — nudges included.**

Not a preference — the product. It is also what keeps the app inside the OS pending limit (§6.1). Overflow policy:

1. **Coalesce first.** Items in the same delivery slot merge into one grouped notification (§4.2). One notification carrying five items is one notification.
2. **Then prioritise.** `overdue2 > overdue1 > due > nudge > early`; within a tier `safety > normal > low`, then nearest projected due date.
3. **Then defer.** Losers move to the next free slot. Deferred more than 21 days past its stage date, an item is **dropped**, not queued forever — the home screen still shows it. A notification arriving a month late is noise.
4. **Reserved slots.** Two of the next four weeks' slots are held for `overdue*` and `nudge`, so early warnings can never starve an urgent item.

#### 4.4 Overrides and their defaults

The fields live on `ServiceItem`, `Vehicle` and `Settings`; the screens that set them are in *Settings*. What matters here is the default each carries into the scheduler:

| Setting | Level | Default |
|---|---|---|
| `notify` on/off | reminder | on for every item seeded on (§8) |
| `notice_distance_m` / `notice_days` | reminder | unset — the notice window of §4.1. These two fields **are** the per-item notice override the scheduler reads, on the item, the vehicle and Settings alike; nothing else overrides the window |
| `priority` safety / normal / low | reminder | per §8 |
| `notifications_muted` ("Mute reminders for this vehicle") | vehicle | off |

There is no app-level mute: the three category switches on `settings.notifications` are the app-level control.

Delivery time, quiet hours and weekdays-only are app-level and specified in §5.

`low` priority items get **one** notification (at `due`) and never claim a slot from a `safety` item.

#### 4.5 The permission pre-prompt

A sheet, never an addressable screen — presentable from anywhere at a moment of intent — shown before the OS dialog so that a reflex **Don't allow** does not end the conversation permanently. On both platforms the OS permission dialog can be raised exactly once; the pre-prompt is what keeps that one shot for a moment when the answer means something.

> **Shall Odova tell you when something's due?**
> At most two notifications a week, never more than one a day. Everything stays on this phone.
> [ **Turn on reminders** ]  [ **Not now** ]

Only **Turn on reminders** raises the OS dialog. **Not now** dismisses the sheet and writes nothing but the decline counter; it is not a refusal to be re-asked, and nothing in the app becomes unavailable — §6.4's rule that the in-app due list must be fully useful with zero notifications delivered is what makes a cheap **Not now** affordable. The body is the promise of §4.3 stated as a fact, not a setting, so the cap and this copy must never drift apart.

**Triggers** — each at a moment of intent, never at launch and never on the onboarding path:

| Trigger | Why it is the right moment |
|---|---|
| The first `ServiceRecord` is saved | The user has just proved they want to keep track of something |
| The first item on any vehicle reaches `due_soon` | There is now a real thing to be told about |
| **Turn on reminders** on `settings.notifications` | The user asked; the sheet still runs, because the OS dialog is the same one shot |

**Cadence:** at most one pre-prompt per **30 days**, and at most **three ever**, counted across all triggers and all vehicles. After the third **Not now** the sheet never appears again on any trigger, and `settings.notifications` is the only remaining door — which is the *Declined in-app three times* state that screen already carries. The counter and the last-shown date survive an import (they are device state, not file state) and are not reset by a vehicle delete. Granting permission stops the sheet permanently; a later OS-level revoke does not restart it.

---

### 5. Quiet hours and delivery time

- **One delivery time for the whole app, default 09:00 local.** *Why 09:00:* the user is awake, not yet driving, and booking a garage is a daytime act. Per-reminder times would be a settings screen nobody wants.
- **Quiet hours default 21:00–08:00.** Anything that would fire inside them moves to the next day's delivery slot — never released as a batch at 08:00.
- **Wall-clock, not instants.** A scheduled notification is stored as `(local_date, delivery_time)` and resolved in the *current* zone at schedule time, so a user who flies Berlin → Tehran still gets 09:00 local (§6.2).
- **Optional weekdays-only.** Off by default. On, weekend fire dates move to the following working day. "Weekend" is locale-dependent and owned by *Languages, RTL and formats* (see **Weekend days** under Calendars and dates — Fri+Sat in several target markets); the scheduler asks and never hard-codes Sat/Sun.
- **Minimum spacing 30 minutes** between delivered notifications. Only matters when the OS releases a batch after a reboot.

---

### 6. OS realities

#### 6.1 The pending-notification cap

iOS keeps only the **64** soonest pending local notifications and silently discards the rest; Android has no hard cap but an increasingly hostile alarm policy. One cross-platform budget: **48 pending**.

Two clamps apply *before* anything reaches the OS, which is why 5 vehicles × 12 reminders × 4 stages never approaches 240 pending:

1. **Horizon: 120 days.** Nothing further out is scheduled; a date 8 months away will be recomputed dozens of times before it arrives. Beyond-horizon reminders live in the database with a computed fire date and enter the schedule at the next rebuild.
2. **The 2-per-week cap (§4.3).** 120 days × 2/week ≈ **34 slots maximum**, whatever the household owns.

The pending cap is therefore a consequence of the product rule, not a separate mechanism. The build:

```
candidates = all (reminder, stage) with fire_date within 120 days
           + warranted nudges
sort by fire_date
apply quiet hours / weekday shift  → slot
coalesce candidates sharing a slot → grouped notification
apply rate cap, prioritise, defer  → §4.3
reserve 2 slots for overdue/nudge
take first 46 (48 budget − 2 reserve); mark the remainder scheduled=false
```

`scheduled_notifications` persists what the app *believes* is pending: `(key, os_id, vehicle_id, reminder_id, stage, fire_at_local, body_hash, state)`, reconciled against the OS's pending list on every rebuild. **The OS is the truth for "is it pending"; the table is the truth for "why".** Without it there is no telling a notification the user dismissed from one the OS dropped for cap.

#### 6.2 Rebuild triggers

A *full rebuild* = cancel every app-owned pending notification, recompute all projections, reschedule from scratch. Cheap; when in doubt, rebuild.

| Event | Action |
|---|---|
| Device reboot | Android: rebuild on boot-completed. iOS: pending notifications survive reboot, but rebuild on next launch anyway. |
| App update | Rebuild on first launch after a version change (persisted `last_build_version`). Bodies and payload schema may have changed; stale payloads must not be trusted. |
| Time-zone change | Full rebuild — wall-clock storage (§5) means every fire time re-resolves to the new zone. |
| DST transition | No action — wall-clock storage handles it. |
| Locale change | **Full rebuild.** Bodies are baked into the OS at schedule time; without this the user switches to Arabic and keeps receiving German notifications for months. |
| Data import | Cancel all → import in a transaction → rebuild after commit. Never schedule from a half-imported database; imported `fired` states are honoured so an import does not re-fire history. |
| Permission granted / revoked-then-granted | Full rebuild. |
| Vehicle archived or deleted | Cancel that vehicle's keys, then rebuild. |
| Clock moved backwards by the user | Detect (`now < last_seen_now − 1 h`), full rebuild, suppress anything that would fire within 1 h. |

**Delivery is itself a rebuild trigger.** Otherwise a user who does not open Odova for eight months — precisely the user reminders exist for — exhausts the 120-day queue and then receives nothing, forever, with no signal. So: on Android a `WorkManager` periodic job (14 days, no network) plus a re-arm in `onReceive` of each fired alarm; on iOS a `BGAppRefreshTask` requested at every schedule build, plus a permanently-scheduled *keeper* notification at horizon−7 days whose delivery re-arms the queue on next launch. The keeper is silent where the platform allows and otherwise reads: "Odova is still tracking {vehicle}. Open it when you get a chance." It counts against the weekly cap. Its payload is `{kind: "keeper", vehicleId}` with **no `reminderId`** (§4.2); tapping it lands on `home` without changing the active vehicle, and it is the delivery — not the tap — that re-arms the queue on the next launch.

If the app has not run for longer than the horizon, first launch performs a full rebuild before the first frame of `home` and shows the away digest **regardless of permission state**, listing what went due while the app was closed.

#### 6.3 Android alarm policy

Do **not** request exact-alarm privileges. Nothing here needs minute precision, and asking is a review risk and a trust cost. Use inexact/windowed scheduling and accept about an hour of drift — which is why bodies use absolute anchors (§4.2). A notification the OS defers into quiet hours is acceptable drift; do not correct it.

#### 6.4 Background restriction

Xiaomi, Huawei, Oppo, Vivo and Samsung drop scheduled alarms for apps that are not whitelisted, and those OEMs dominate Iran, Iraq and the Gulf — the same devices already flagged as the font-fallback risk.

After the third consecutive notification whose delivery cannot be confirmed (its `scheduled_notifications` row still `pending` more than 48 h past `fire_at_local`, with the app foregrounded since), show a one-time card on `settings.notifications`:

> Your phone may be stopping Odova's reminders. Allow Odova to run in the background to fix it. **[Open settings]**

The button opens the OEM autostart/battery screen via the documented intents, falling back to the app-info screen. Record the outcome so it is asked once. The card never appears on Home. Release testing covers one Xiaomi or Huawei device with a 7-day background-delivery soak.

**The in-app due list is the primary channel and must be fully useful with zero notifications ever delivered.** Notifications are an accelerant; no feature may depend on delivery.

---

### 7. Snooze, dismiss, and done

#### 7.1 Dismiss

Swiping a notification away changes **nothing**: the reminder stays due, later stages still fire, nothing is recorded. *Why:* a swipe means "not now", not "handled", and inferring intent from a dismissal is how apps lose service records.

#### 7.2 Snooze

| Property | Value |
|---|---|
| Default | 7 days from the moment of snoozing — the job usually needs a booking |
| In-app options | 3 days · 1 week · 1 month · "when I've driven another 500 km" (the distance option is offered only when the item has a distance interval) |
| Effect | Suppresses **all** stages of that reminder until expiry, then resumes at whichever stage is current by then |
| Does not change | The due date, the interval, the overdue state, or the item's red treatment on the home screen |
| Distance snooze | Converted to a date by the projection (§1.3) and re-projected like anything else |
| Limit | 3 consecutive snoozes. The 4th offer replaces "Snooze" with three choices: **Snooze again · Change the interval · Turn this reminder off.** Someone snoozing four times has an interval problem, not a memory problem. |

#### 7.3 Done

**Done from the notification** must not require typing. It writes a service record dated today with `odometer = round(odo_now)`, `odometer_estimated = true`, `cost_estimated = true`, and one `ServiceLine{service_item_id, label = the item's label, amount = 0}` in the vehicle's currency — the model requires at least one line, so zero is the only representable "not recorded". A `cost_estimated` record contributes 0 to the cost dashboard and prints its cost cell as `—` in `report.service`, footnoted "— cost not recorded."

It then queues a confirmation strip for the next app open, prefilled and editable: *You marked Oil and filter done on 12 September. I recorded ~187,400 km and no cost. Add the real numbers?* *Why:* the one-tap path stays one tap, but an estimated odometer must never enter the service history claiming to be a fact. Both flags travel into the JSON export and show in the service history.

**Done in the app** asks for the actual odometer (prefilled with the projection, not locked), and optionally date, cost, notes and place.

#### 7.4 The rollover rule — exact

```
complete(reminder R, vehicle V, done_date D, done_odometer O):

  1. write ServiceRecord {V, D, O, odometer_estimated, cost_estimated,
       lines[] including one ServiceLine{service_item_id: R.id, ...}}
  2. clear R.snoozed_until and R.snooze_until_odometer_m; R.snooze_count = 0
  3. cancel every pending notification key for R
  4. reproject V
```

Nothing is written to R but the snooze fields. The anchor is the ServiceLine just written: `resolveAnchor(R, serviceRecords)` recomputes it on every read (*Domain model and rules*).

**The next interval is measured from what actually happened, not from what was supposed to happen.** Oil due at 115,000 km but done at 118,400 km → next due at **128,400**, not 125,000. *Why:* the wear clock restarts at the service. Rolling from the due value creates a permanent debt — the user is "3,400 km behind" forever and the next reminder fires while the oil is still fresh.

The exception is **anchored items**: inspection, insurance and road tax are tied to a calendar anchor no matter when the paperwork was done. `ServiceItem.rollover` is `from_actual` by default and `from_due` (next due date = previous due date + interval) for exactly those three built-in kinds — `inspection`, `insurance_renewal` and `registration` (§8). If an anchored item is completed **more than 60 days after** its due date, ask once — *keep the old renewal date, or move it to today?* — because a genuinely lapsed registration does re-anchor. Never ask otherwise.

- **Done early.** Roll from actual regardless, but the confirmation shows the new due figures, so a user changing oil at 5,000 km on a 10,000 interval sees what it did rather than discovering it later.
- **Single-dimension reminders.** If only the distance interval is set, only the distance rolls. Never invent the missing dimension.
- **Back-dated completion.** Rolls from that past date and odometer, and reprojection may immediately mark the item due again. Correct — and the confirmation says so rather than silently producing a red item.
- **Retro-fitting history.** Adding an old service record recomputes that item's anchor from the **most recent** record, not the newly added one.

---

### 8. The seeded default set

A new vehicle is created with these. The header on `reminders.list` reads:

> **Starting points, not manufacturer advice.** Your handbook wins — edit anything here.

Never present these as recommended, correct or manufacturer-derived: they are round numbers approximately right for a lot of cars, which is a different claim. Defaults are defined **per unit system, not converted** — a miles user gets 6,000 mi, not 9,656 km rendered as 6,000.

Every seeded row is a real `ServiceItem` copied out of the catalogue at vehicle creation (*Domain model and rules*), and the `Kind` column below is its `ServiceKind` value — the canonical spelling used by the database, the export, the CSV headers and the notification payloads. The `Kind` column is what the seeder is written from; the **Item** column is the English display label, which is an ARB key like every other string and is *not* an identifier. Where `Kind` is not `custom`, `ServiceItem.label` is left null and the label is rendered from the kind, so a seeded vehicle reads correctly in all six languages without a migration.

`Seeded on` names `Vehicle.vehicle_type` values (`car | van | motorcycle | truck | other`). `truck` and `other` take the car set unchanged. The `fuel_kind_default` filter is a second, independent pass and lives in §8.3.

#### 8.1 Car / van — seeded on

| Kind | Item | Distance | Time | Default | Seeded on | Priority | Rollover |
|---|---|---|---|---|---|---|---|
| `oil_and_filter` | Engine oil and filter | 10,000 km / 6,000 mi | 12 mo | **on** | car, van, motorcycle, truck, other — not `electric` | safety | from_actual |
| `brake_pads_check` | Brake pads — check | 20,000 km / 12,000 mi | 12 mo | **on** | car, van, motorcycle, truck, other, `electric` included | safety | from_actual |
| `tyre_replace` | Tyres — replace | 50,000 km / 30,000 mi | 72 mo | **on** | car, van, motorcycle, truck, other, `electric` included | safety | from_actual |
| `air_filter` | Engine air filter | 20,000 km / 12,000 mi | 24 mo | **on** | car, van, motorcycle, truck, other — not `electric` | normal | from_actual |
| `coolant` | Coolant | 60,000 km / 36,000 mi | 48 mo | **on** | car, van, truck, other; motorcycle on liquid-cooled only | normal | from_actual |
| `inspection` | Inspection / roadworthiness | — | 12 mo | **on** | car, van, motorcycle, truck, other, `electric` included | safety | **from_due** |
| `insurance_renewal` | Insurance renewal | — | 12 mo | **on** | car, van, motorcycle, truck, other, `electric` included | normal | **from_due** |

#### 8.2 Car / van — seeded off, one tap to enable

Seeded off means `is_tracked = false`: the row exists, appears greyed in `reminders.list`, and is invisible to the due engine until the user enables it.

| Kind | Item | Distance | Time | Default | Seeded on | Priority | Rollover | Note shown |
|---|---|---|---|---|---|---|---|---|
| `timing_belt` | Timing belt | 100,000 km / 60,000 mi | 96 mo | off | car, van, truck, other — not `electric` | safety | from_actual | "Belt or chain? Chains don't need this — your handbook says which you have." |
| `tyre_rotate` | Tyre rotation | 10,000 km / 6,000 mi | 12 mo | off (**on** when `is_business`, §8.4) | car, van, truck, other | normal | from_actual | |
| `cabin_filter` | Cabin / pollen filter | 20,000 km / 12,000 mi | 12 mo | off (**on** on `electric`, §8.3) | car, van, truck, other | low | from_actual | |
| `brake_fluid` | Brake fluid | 60,000 km / 36,000 mi | 24 mo | off (**on** on `electric`, §8.3) | car, van, motorcycle, truck, other | safety | from_actual | |
| `spark_plugs` | Spark plugs | 40,000 km / 24,000 mi | 48 mo | off | car, van, motorcycle, truck, other — petrol, LPG, CNG and hybrid only | normal | from_actual | Petrol only |
| `transmission_fluid` | Transmission fluid | 60,000 km / 36,000 mi | 60 mo | off | car, van, truck, other — not `electric` | normal | from_actual | |
| `battery` | Battery — check / replace | — | 48 mo | off | car, van, truck, other — replaced by `battery_12v` on `electric`; never on motorcycle | normal | from_actual | |
| `wipers` | Wiper blades | — | 12 mo | off | car, van, truck, other | low | from_actual | |
| `registration` | Road tax / registration | — | 12 mo | off | car, van, motorcycle, truck, other, `electric` included | normal | **from_due** | not universal, hence off |

Timing belt is created-but-off rather than omitted: it is the most expensive thing to miss, and a disabled row with an honest note gets a user to look it up. Enabling it on a chain-driven car would teach them the app makes things up.

#### 8.3 Variants

Keyed on `(vehicle_type, fuel_kind_default)` — electric is a fuel kind, not a vehicle type, so the two filters compose: an electric motorcycle gets the motorcycle deltas and then the electric ones.

| Variant | Differences from the car set |
|---|---|
| **Motorcycle** (`vehicle_type = motorcycle`) | `oil_and_filter` 6,000 km / 3,600 mi, 12 mo (on). Adds on: `chain_lube` (chain clean and lube) 800 km / 500 mi, no time interval, priority low. Adds off: `chain_and_sprockets` 25,000 km / 15,000 mi, `valve_clearance` 25,000 km / 15,000 mi, `fork_oil` 30,000 km / 18,000 mi — all priority normal, all from_actual. Drops `cabin_filter`, `tyre_rotate`, `wipers`, `transmission_fluid`, `timing_belt`, `battery` and `battery_12v` entirely; `coolant` is seeded only on liquid-cooled and never on air-cooled. |
| **Van** (`vehicle_type = van`) | Car set, `oil_and_filter` at 15,000 km / 9,000 mi, 12 mo — vans are usually diesel with a longer interval — plus `tyre_replace` at 40,000 km / 24,000 mi. |
| **`fuel_kind_default = electric`** | Drops `oil_and_filter`, `air_filter`, `spark_plugs`, `transmission_fluid` and `timing_belt`; `coolant` is not seeded at all. Seeded **on**: `brake_fluid` 24 mo, `tyre_replace`, `cabin_filter` 12 mo, `inspection`, `insurance_renewal`, `brake_pads_check` 20,000 km / 12,000 mi. Adds off: `reduction_gearbox_oil` (reduction gearbox oil) 100,000 km / 60,000 mi, priority normal; `battery_12v` (12 V battery) 48 mo, priority normal. |

**`battery` versus `battery_12v` — settled.** `battery` is the seeded row on `car`, `van`, `truck` and `other`; `battery_12v` replaces it — never joins it — on `fuel_kind_default = electric`, where "the battery" otherwise reads as the traction pack, which Odova does not track; `motorcycle` seeds neither. No vehicle is ever seeded with both. Both kinds stay in the catalogue picker for every vehicle type, so a user who wants the other one can add it by hand.

**`brake_pads_check` versus front and rear.** The seeded row is always `brake_pads_check` — an inspection that recurs. `brake_pads_front` and `brake_pads_rear` are **never seeded**; they exist so that the replacement job a user actually pays for can be recorded and can carry its own interval, and they are what `log.service` writes when the user picks front or rear pads from the catalogue.

#### 8.4 Heavy use

When `Vehicle.is_business` is true the seed changes: `oil_and_filter` → **7,500 km / 4,500 mi, 6 months**, `air_filter` → 15,000 km / 9,000 mi, `tyre_rotate` seeded **on**. That is the shape of a severe-service schedule; the multipliers are our judgement, not a manufacturer table, and the disclaimer above covers it.

#### 8.5 Catalogue kinds that are never seeded

These six `ServiceKind` values are seeded on no vehicle type at all. They ship in the catalogue picker on `reminders.edit` for every vehicle type, so a user can add them in one tap:

| Kind | Why it is available but not seeded |
|---|---|
| `fuel_filter` | Interval varies by an order of magnitude between petrol and diesel; a wrong default here is worse than no default |
| `wheel_alignment` | Event-driven — a kerb, a new set of tyres — not interval-driven |
| `ac_service` | Not fitted to every vehicle and not serviced on a schedule most owners recognise |
| `brake_pads_front` | Replacement job; the seeded row is `brake_pads_check` (§8.3) |
| `brake_pads_rear` | Replacement job; the seeded row is `brake_pads_check` (§8.3) |
| `custom` | The user's own item. `ServiceItem.label` is required when `kind = custom` and is the only case where the label carries meaning |

That accounts for all 28 values of `ServiceKind`: seven seeded on in §8.1, nine seeded off in §8.2, six introduced by §8.3's variants (`chain_lube`, `chain_and_sprockets`, `valve_clearance`, `fork_oil`, `reduction_gearbox_oil`, `battery_12v`), and the six above. A value that appears in *Domain model and rules* without a row in this section is a bug in this section.

---

## 5. Languages, RTL and formats

Six locales ship in v1. RTL is half the audience, so every layout, chart, formatter and font decision below assumes both directions from the first commit.

### The six locales

| Locale | Language | Dir | Default digits | Default calendar | Distance | Consumption | Currency | Week starts |
|---|---|---|---|---|---|---|---|---|
| `en` | English | LTR | Latin `0-9` | Gregorian | mi | mpg (US) | USD | Sunday |
| `de` | German | LTR | Latin `0-9` | Gregorian | km | L/100 km | EUR | Monday |
| `fr` | French | LTR | Latin `0-9` | Gregorian | km | L/100 km | EUR | Monday |
| `fa` | Persian | **RTL** | Ext. Arabic-Indic `۰۱۲۳۴۵۶۷۸۹` | **Jalali** | km | L/100 km | IRR (shown as toman) | Saturday |
| `ar` | Arabic | **RTL** | Arabic-Indic `٠١٢٣٤٥٦٧٨٩` | Gregorian | km | L/100 km | region (SAR/AED/EGP…) | Saturday |
| `ckb` | Kurdish Sorani | **RTL** | Ext. Arabic-Indic `۰۱۲۳۴۵۶۷۸۹` | Gregorian | km | L/100 km | IQD | Saturday |

The last five columns are **defaults, not properties of the language**: they resolve from the device *region*, and each is a separate setting.

- `en-US` → mi / mpg (US) / USD / Sunday. `en-GB` → mi / mpg (imperial) / GBP / Monday. `en-AU`, `en-IN`, `en-ZA`, `en-IE` → km / L100 / local currency / Monday.
- `ar-MA`, `ar-DZ`, `ar-TN`, `ar-LY` → **Latin digits**, Maghrebi separators (`1.234,56`); Arabic-Indic digits read as foreign there.
- Week start from CLDR region data, never per language: `ar-SA` Sunday; `ar-MA`, `ar-LB`, `ar-TN` Monday; the rest Saturday.
- `ckb-IR` → Jalali and toman; Sorani speakers in Iran live on the Iranian civil calendar. `ckb-IQ` and unknown region → Gregorian, IQD.
- `fa-AF` (Dari) → Persian strings, Jalali, AFN.

CLDR's default numbering system for `ckb` is `arab` (`٠١٢٣`); we ship `extarab` (`۰۱۲۳`), because Sorani letterforms follow Persian conventions and mixed digit shapes inside one script read as a font bug. `ckb-IQ` users who want `٠١٢٣` flip one setting.

### Locale selection

```
1. settings.language != "system" -> use it
2. device locale list, in order  -> first tag whose language subtag is one of
                                    en de fr fa ar ckb
3. otherwise                     -> en strings + region-derived formats
```

Match the **language subtag only** for strings, the full tag for formats: `de-AT` gets German strings and Austrian formats; `pt-BR` gets English strings but km, L/100 km, BRL and Monday.

| Device reports | We use | Why |
|---|---|---|
| `ckb`, `ckb-IQ`, `ckb-IR`, `sd-Arab`-style Sorani tags | `ckb` | — |
| `ku`, `kmr`, `ku-TR` | **`en`**, LTR | `ku` is Kurmanji: a different language in Latin script. Sorani Arabic script is worse for them than English. |
| `fa-AF`, `prs`, `prs-AF` | `fa` | Dari is mutually intelligible in writing. |
| `ar-*` (any region) | `ar` | One MSA string set; region affects only digits, month names, currency, week start. |

**Override.** Seven rows: `System (English)` — the parenthesis naming what `system` resolves to right now, updated live — plus the six, each in its own language and script (`English`, `Deutsch`, `Français`, `فارسی`, `العربية`, `کوردیی ناوەندی`), never translated into the current UI language, because someone stuck in the wrong language has to find their own. `system` is a value of `settings.language`, not a seventh string set. When the device language is none of the six, `System (English)` is preselected and one line sits under the list: *"Odova isn't translated into {device_language} yet. Numbers, dates, units and money will still follow your region."* — an ICU message with the language name in its own language. The screen is in *Settings*.

Six independent settings — language, numerals, calendar, first day of week, units, currency display — typed in *Domain model*, edited in *Settings*. Separate because they vary independently: an Iranian in Berlin wants Persian text, Persian digits, Jalali, km and euros.

**No restart.** Changing language, direction, digits, calendar, units or currency rebuilds the tree from the root and re-renders in place, preserving in-progress form input. Two consequences: notification bodies are baked into the OS at schedule time, so on any such change cancel all, re-render, re-schedule (scheduling itself is *Reminders and notifications*); and cached layouts, measured text widths and pre-rendered charts are invalidated when direction flips.

### Direction: what mirrors

**Mirror anything that encodes reading order or forward progress; keep anything that depicts a physical object or a rotating instrument.**

No layout code says `left` or `right` — `start`/`end` for padding, margins, insets, alignment, borders, corner radii, positioning. A grep for `left:`/`right:`/`Alignment.centerLeft` outside the icon-asset layer fails CI.

| Thing | RTL behaviour |
|---|---|
| Page layout, padding, insets | `start` = right edge |
| Text alignment | start-aligned |
| List rows | label at start, value + chevron at end |
| Back / navigation-up chevron | points **right** |
| Disclosure / "more" chevron | points **left** |
| Page push transition | enters from the left, pops to the right |
| Drawer, side sheet | anchored right |
| Bottom-nav / tab order | reversed (first tab sits rightmost) |
| Segmented control order | reversed |
| Linear progress ("72% of the oil interval used") | fills right → left |
| Sliders | minimum at right, filled track on the right |
| Swipe actions on a list row | declared `startActions`/`endActions`; physical direction flips |
| Stepper `−`/`+` pair | order reversed; glyphs unchanged |
| Chart time and category axes | run right → left; oldest datum at the right |
| Chart value axis + labels | move to the right edge; bars grow from the right |
| Chart legend, table column order | reversed |
| Sparklines | oldest at right, newest at left |
| Tooltip / popover anchoring | mirrored |
| Ellipsis on truncation | falls at the visual end |
| Undo / redo, previous / next month arrows | mirrored |
| Snackbar action button, badge dots | mirrored |

The time axis mirrors deliberately: Persian and Arabic print media draw it right-to-left, and a chart running against the page reads as backwards.

**Never mirrors, one canonical asset:** logo and wordmark · car, van and motorbike silhouettes · fuel pump · oil can and droplet · spanner · battery · tyre · brake disc · coolant · key · clock face · calendar · stopwatch · speedometer and gauge dials, including the needle sweep · **circular progress rings — clockwise everywhere** · pie/donut slices — clockwise from 12 o'clock · checkmark · plus · close · magnifier · gear · bell · camera · trash · pencil · filter · share · up/down trend arrows.

A vehicle glyph is a picture of an object, not a directional cue; mirroring it makes an accidental statement about right-hand drive. Dials do not run backwards in Tehran.

### Bidi text

The hard case is a Persian or Arabic sentence containing a Latin model name, a number, or both.

```
Template (fa):  «سرویس بعدی {vehicle} در {km} کیلومتر»
vehicle = "VW Golf TDI 2.0",  km = ۱۲۳٬۴۵۶
```

Left alone, the Bidi Algorithm resolves the neutrals — space `.` `,` `(` `)` `-` `/` — against the *paragraph* direction, so the trailing `2.0` or a closing bracket jumps to the wrong side of the Latin run and looks like data corruption.

1. **Wrap every interpolated value in a first-strong isolate at render time**: `U+2068 FSI` … `U+2069 PDI`. FSI infers direction from the first strong character, so one code path handles `VW Golf` and `پژو ۲۰۶`. LRE/RLE/PDF are deprecated.
2. **Never store bidi controls.** A `⁨` in a backup JSON breaks search, sorting, CSV round-trips and the "readable in a text editor" constraint.
3. **Never concatenate a sentence.** No `label + ": " + value`; one ICU message per sentence, so the translator controls word order and owns the punctuation.
4. **A number and its unit are one atomic run.** `۴۵٫۲ لیتر` is a single isolate; split it and the unit lands on the wrong side.
5. **UI chrome takes direction from the locale; free text takes it from the content.** Notes, workshop names and nicknames run first-strong-per-paragraph, so an English note in a Persian app is LTR and left-aligned inside its card. Store raw text, decide at render.
6. **Force LTR on codes.** VIN, plate, and any field whose character order is significant: explicit LTR paragraph direction, LTR isolate, left alignment even on an RTL screen, LTR-preferring keyboard hint.
7. **Punctuation comes from the translation file** — `،` `؛` `؟`, Persian `٪`. Code never appends `:` or `?` to a translated string.
8. **Bidi-aware truncation**: the ellipsis lands at the logical end, and truncating mid-run must not reorder what remains.

### Numerals

| Locale | Default numbering system | Codepoints |
|---|---|---|
| en, de, fr | `latn` | `0-9` |
| fa, ckb | `extarab` | U+06F0–U+06F9 `۰۱۲۳۴۵۶۷۸۹` |
| ar (except Maghreb) | `arab` | U+0660–U+0669 `٠١٢٣٤٥٦٧٨٩` |
| ar-MA, ar-DZ, ar-TN, ar-LY | `latn` | `0-9` |

Persian and Arabic digits are different codepoints and shapes (`۴۵۶` vs `٤٥٦`). **Never mix two digit sets on one screen** — one numbering system is active app-wide. The Numerals setting offers three rows against four stored values: `Automatic` stores `auto` (the locale's CLDR default from the table above), `Latin (0-9)` stores `latin`, and `Local (۰-۹ / ٠-٩)` resolves by language — it stores `extended_arabic_indic` (۰-۹) for `fa` and `ckb`, and `arabic_indic` (٠-٩) for `ar`. `Local` is offered only where the locale's default numbering system is not `latn` — `fa`, `ckb` and `ar` outside the Maghreb — because nowhere else has a local digit set to name. The old value name `persian` for a numeral system is dead and must not appear anywhere. Younger Persian and Gulf users often prefer Latin digits for money and odometer readings.

**Digit shaping is a display transform only** — numbers are stored as numbers, never digit strings, and the transform is the last step of formatting, after grouping and separators.

**Always Latin, whatever the setting:**

| Field | Reason |
|---|---|
| VIN | An identifier, matched character by character against papers and databases. |
| Backup/export JSON — every number, every date | RFC 8259 permits ASCII digits only. A JSON number containing `۴` is not JSON. |
| Export filenames, app version and build strings | Not user data. |
| Licence plate | **Verbatim as typed**, never shaped either way. An Iranian plate legitimately contains Persian digits and a Persian letter. Transcribed, not computed. |

Free text — notes, workshop names — is likewise verbatim. We never rewrite someone's own characters.

**Input.** Persian keyboards emit `٫` (U+066B) for the decimal point and `٬` (U+066C) for grouping, and the OS may emit anything:

```
normalizeNumericInput(s):
  strip  U+200E U+200F U+061C U+2066..U+2069        # bidi controls
  strip  U+00A0 U+202F U+2009 ' '                    # spaces used as groupers
  map    U+0660..U+0669 -> '0'..'9'                  # Arabic-Indic
  map    U+06F0..U+06F9 -> '0'..'9'                  # Extended Arabic-Indic
  map    U+066B -> ',' ; U+066C -> '.' ; U+060C -> ','   # Arabic separators
  # disambiguate '.' vs ','
  if both '.' and ',' present:  rightmost = decimal point, remove the other
  elif one separator char appears more than once:  it is grouping, remove all
  elif exactly 3 digits follow it and the locale uses it as a grouper:  remove
  else:  it is the decimal point
  reject if anything outside [0-9 . -] remains, or more than one '.'
  return Decimal(s)
```

Still ambiguous → **reject with an inline error rather than guess**; a misparsed fuel price silently corrupts the consumption history. On blur the field re-renders the canonical value in the display digits. While typing, echo ASCII digits into the display set live — 1:1 by codepoint, so length never changes and the caret needs no adjustment. Normalise to ASCII before any comparison, sort or search.

### Calendars and dates

Storage is Gregorian and calendar-agnostic — two shapes only:

```jsonc
// A civil date: when a service or fill-up happened, when something is due.
"date": "2026-03-14"

// A machine timestamp: record created/modified. RFC 3339, UTC.
"createdAt": "2026-03-14T09:12:04Z"
```

Jalali dates are **never** stored: Solar Hijri leap rules have real implementation variance, and a backup a technical user can read has to contain dates they recognise.

**Display calendar:** `fa` and `ckb-IR` → Jalali; `ckb` elsewhere → Gregorian; `ar` → **Gregorian**, because every Arab country runs its civil life on it and nobody books an oil change by the Hijri calendar. **No Hijri in v1.** The Calendar setting offers Gregorian and Jalali regardless of language.

**Stored values.** This section owns the allowed values for the three locale settings; *Backup, export and import* admits exactly these in the file, and *Domain model and rules* types the fields that hold them.

```
calendar  = gregorian | persian
numerals  = auto | latin | arabic_indic | extended_arabic_indic
language  = en | de | fr | fa | ar | ckb
```

`persian` is the Jalali / Solar Hijri display calendar; there is no `hijri` value in v1. `auto` is the locale's CLDR default from the Numerals table above, and the withdrawn numeral value name `persian` must appear nowhere. `Settings.language` additionally admits the sentinel `system` — the default, resolving to one of the six by the *Locale selection* rules — which is a value of the setting, not a seventh string set.

**Conversion.** Platform ICU `persian` calendar where available; otherwise pin one implementation of the Khayyam/Borkowski arithmetic and never swap it. ICU-verified anchors:

| Jalali | Gregorian |
|---|---|
| 1 Farvardin 1403 | 2024-03-20 |
| 1 Farvardin 1404 | 2025-03-21 |
| 1 Farvardin 1405 | 2026-03-21 |
| 30 Esfand 1403 (leap) | 2025-03-20 |

**Date picker.** Ship our own; neither platform has a reliable Solar Hijri picker with Persian month names across the OS versions we support. One month-grid picker driven by the active calendar: Jalali month names (فروردین، اردیبهشت، خرداد، تیر، مرداد، شهریور، مهر، آبان، آذر، دی، بهمن، اسفند), correct first day of week, today marker, and a hard "no future dates" rule for fill-ups and completed services.

**Arabic Gregorian month names fork by region:** Egypt and the Gulf use يناير/فبراير/مارس; `IQ SY LB JO PS` use كانون الثاني/شباط/آذار. Default to the Gulf/Egypt set. Sorani month names follow the Levantine pattern (ئەیلوول for September), from CLDR.

**First day of week** from CLDR region data (`fa-IR` Sat, `ckb-IQ` Sat, `ar-EG` Sat, `ar-SA` Sun, `ar-MA` Mon, `de`/`fr`/`en-GB` Mon, `en-US` Sun), overridable. It drives the picker grid and weekly cost aggregation, nothing else.

**Weekend days** likewise come from CLDR region data, never from the language: `fa-IR`, `ar-SA`, `ar-EG`, `ar-AE`, `ckb-IQ` → Thursday-evening/Friday–Saturday, taken as Fri+Sat; `ar-MA`, `ar-TN`, `ar-LB`, `de`, `fr`, `en-*` → Sat+Sun. This drives `weekdays_only` in *Reminders and notifications* §5 and nothing else.

**Relative dates.** ICU relative-time formatting, but bucket the value first — "in 47 days" is data, "in about 7 weeks" is an answer:

| Delta | Rendered as |
|---|---|
| today | "Today" |
| ±1 day | "Tomorrow" / "Yesterday" |
| 2–13 days | "in {n} days" |
| 14–55 days | "in about {n} weeks" |
| ≥ 56 days | "in about {n} months" |
| overdue | a **separate string** — "{n} days overdue", never a negative relative time |

Each is an ICU plural message, not a formatter call with a suffix glued on.

### Plurals

**ICU MessageFormat `{count, plural, …}` with CLDR categories**, resolved at runtime for the active locale. No `if (n == 1)` anywhere.

| Locale | Categories | Notes that bite |
|---|---|---|
| `en` | one, other | 0 → other |
| `de` | one, other | 0 → other |
| `fr` | one, **many**, other | 0 → **one**. `many` covers large/compact values (1 000 000). All three authored. |
| `fa` | one, other | **0 → one.** A translator who writes "۱ یادآوری" in `one` produces it for zero too. |
| `ckb` | one, other | 0 → **other** (unlike Persian) |
| `ar` | **zero, one, two, few, many, other** | `few` = n%100 ∈ 3–10; `many` = n%100 ∈ 11–99; `other` = 100, 101, 102, 1000…; 103 is `few` again. All six mandatory. |

Zero differs across all six, so **always author an explicit `=0` case** wherever the zero copy differs from "0 things".

```jsonc
// app_en.arb
"remindersDueCount": "{count, plural, =0{Nothing due} one{# reminder due} other{# reminders due}}",
"@remindersDueCount": {
  "description": "Home screen header. Count of reminders past due or due soon.",
  "placeholders": { "count": { "type": "int" } }
}

// app_de.arb
"{count, plural, =0{Nichts fällig} one{# Erinnerung fällig} other{# Erinnerungen fällig}}"

// app_fr.arb
"{count, plural, =0{Rien à prévoir} one{# rappel à échéance} many{# rappels à échéance} other{# rappels à échéance}}"

// app_fa.arb
"{count, plural, =0{چیزی سررسید نشده} one{# یادآوری سررسید شده} other{# یادآوری سررسید شده}}"

// app_ckb.arb
"{count, plural, =0{هیچ شتێک نەگەیشتووە} one{# بیرخەرەوە گەیشتووە} other{# بیرخەرەوە گەیشتوون}}"

// app_ar.arb
"{count, plural, =0{لا شيء مستحق} zero{لا تذكيرات مستحقة} one{تذكير مستحق} two{تذكيران مستحقان} few{# تذكيرات مستحقة} many{# تذكيرًا مستحقًا} other{# تذكير مستحق}}"
```

`#` renders through the locale number formatter, picking up grouping and digit shaping; use `{count, number}` only when the displayed value needs different formatting from the selector.

Interval strings need plurals too — "every {n} km", "every {n} months" — because Arabic inflects the unit against the count. Units are not invariant suffixes. The intervals themselves are in *Reminders and notifications*.

### Fonts

The system font is not enough. On Android, Arabic coverage is OEM-dependent — Xiaomi, Samsung, Oppo and Vivo substitute or trim AOSP's Noto Naskh Arabic, the Sorani letters `ڕ ڵ ۆ ێ ھ` go missing first, and a letter that falls back mid-word cannot be joined by the shaper: ransom-note text, unreadable rather than merely ugly. On iOS, SF Arabic's metrics differ from SF Pro (different baselines at one type scale) and older devices fall back to Geeza Pro, whose `ک` U+06A9 and `ی` U+06CC carry Arabic shapes.

**Bundle one Arabic-script family and use it for the whole app in `fa`, `ar` and `ckb`, including Latin runs inside those locales.** `en`, `de`, `fr` use the platform font.

- **Vazirmatn** (SIL OFL, variable): drawn for Persian, covers Arabic and Sorani, weight-matched Latin, both digit sets. Using it for Latin runs kills the weight and baseline jump when a model name appears inside a Persian sentence.
- Fallback if licensing or look changes: **Noto Sans Arabic** or **Estedad**. Not IRANSans — the licence forbids app embedding.
- Ship Regular / Medium / Bold, or the variable font subset to those axes.
- **Subset to base ranges only:** Latin-1, U+0600–06FF, U+0750–077F, U+08A0–08FF, U+FDF2, U+200C ZWNJ. **Exclude U+FB50–U+FEFF presentation forms** — HarfBuzz applies `init/medi/fina/isol/rlig` from base characters.
- **Verify real glyphs with all four joining forms**, not fallback boxes: `ڕ` U+0695, `ڵ` U+06B5, `ۆ` U+06C6, `ێ` U+06CE, `ھ` U+06BE, `ە` U+06D5, `چ` U+0686, `ژ` U+0698, `گ` U+06AF, `پ` U+067E, `ک` U+06A9, `ی` U+06CC. Medial `ڵ` and the `ھ` variant are what most Arabic fonts get wrong.

Arabic script stacks dots above and drops `ج ح خ ر ز ی` tails well below the baseline. A Latin-tuned line height clips them, silently.

| | LTR locales | RTL locales |
|---|---|---|
| Body line-height multiplier | 1.25–1.35 | **1.55–1.70** |
| Headline line-height | 1.15–1.2 | 1.35–1.45 |
| Body size | base | base **+6–8%** (Arabic script reads smaller at equal point size) |

In Arabic-script locales: **`letter-spacing: 0`, always** — tracking breaks the joins. No italics or synthetic obliques; use weight. No text-transform or small-caps. No underlines for emphasis — they collide with descenders. Never fix a pixel height on a text container; give rows a minimum height and let them grow. Disable leading-trim and any font-metric override that crops to the Latin cap-height box.

### Number, currency and unit formats

Grouping, separators and digit shaping come from the platform/ICU formatter for the active locale and numbering system. Verified outputs for `1234.56`:

| Locale | Number | Decimal sep | Group sep | Money |
|---|---|---|---|---|
| `en-US` | `1,234.56` | `.` | `,` | `$1,234.56` (symbol before) |
| `en-GB` | `1,234.56` | `.` | `,` | `£1,234.56` |
| `de-DE` | `1.234,56` | `,` | `.` | `1.234,56 €` (symbol after, NBSP U+00A0) |
| `fr-FR` | `1 234,56` | `,` | narrow NBSP **U+202F** | `1 234,56 €` (symbol after, NBSP) |
| `fa-IR` | `۱٬۲۳۴٫۵۶` | `٫` U+066B | `٬` U+066C | `۱٬۲۳۵ تومان` (label after) |
| `ar-EG` | `١٬٢٣٤٫٥٦` | `٫` U+066B | `٬` U+066C | `١٬٢٣٤٫٥٦ ج.م.` (symbol after) |
| `ar-MA` | `1.234,56` | `,` | `.` | `1.234,56 د.م.` |
| `ckb-IQ` | `۱٬۲۳۴٫۵۶` | `٫` | `٬` | `۱٬۲۳۵ د.ع.` |

- **Never hard-code a currency symbol next to a number in a translation string.** Money is one atomic, isolate-wrapped unit; placement, spacing and any RLM belong to the formatter.
- Negative amounts put the minus before the digits, inside the same isolate, so it cannot migrate to the other end in RTL.
- Decimal places from CLDR: JPY 0, KWD/IQD 3, EUR/USD 2. Currency is per vehicle with a global default for new vehicles; the field and its ISO 4217 enum are in *Domain model*.
- **Toman is display only.** Iranian amounts are stored and exported as IRR minor units; with `currency_display = toman` the formatter divides by 10, renders 0 decimals and appends تومان. Nobody quotes a service in rials, but a non-ISO code in the file would fail the backup's own validation.
- **Unit abbreviations come from our translation files, not the platform unit formatter.** CLDR short forms for `fa` and `ckb` are wrong in places — ICU renders 45.2 L in `fa-IR` as `۴۵٫۲L` (Latin L, no space) and km in `ckb-IQ` as Latin `km`. ICU formats the number; the label is ours.

| | en | de | fr | fa | ar | ckb |
|---|---|---|---|---|---|---|
| distance | km / mi | km / mi | km / mi | کیلومتر / مایل | كم / ميل | کم / مایل |
| volume | L / gal | l / gal | l / gal | لیتر | لتر | لیتر |
| consumption | L/{n} km · mpg | l/{n} km | l/{n} km | ل/{n} کم | ل/{n} كم | ل/{n} کم |
| per distance | /km · /mi | /km | /km | در هر کیلومتر | لكل كم | بۆ هەر کم |

The consumption label carries `{n} = 100` as a placeholder, not a literal, so the hundred is shaped by the active numbering system like every other number. Never bake digits into a translated string.

Unit systems: distance km / mi; volume L / US gal / imp gal; consumption L/100 km, km/L, mpg (US), mpg (imp). `mpg (US)` and `mpg (imp)` are different units, never conflated in storage or on a chart axis.

### Translation workflow

**Keys are namespaced identifiers, not English sentences:** `reminders.dueCount`, `fuel.fillUp.pricePerLitre.label`, `settings.backup.export.cta`. Editing English copy must not invalidate five translations.

**One ARB file per locale** — `l10n/app_en.arb` … `app_ckb.arb`; plain JSON with sibling `@key` metadata, so it is tool-agnostic and diffable. `app_en.arb` is the source of truth: every key carries a `description`, typed `placeholders`, and `maxChars` where length is constrained. Ship a screenshot pack per screen with keys annotated — nobody can tell whether "Due" is a noun or an adjective from the key alone.

CI fails the build on:

| Check | Severity |
|---|---|
| Key present in a translation but absent from `en` (dead key) | error |
| Placeholder names/types differ between `en` and any translation | error |
| ICU message fails to parse | error |
| Missing CLDR plural category for the locale (all six for `ar`, `many` for `fr`) | error |
| Key missing from a translation | warning on `main`, **error on a release build** |
| Hard-coded user-visible string literal in UI code | error |

**Untranslated keys fall back to English text — never to the raw key.** Debug builds wrap missing translations in `‹ ›` and log a MISSING report. No runtime machine translation; there is no network.

**Text expansion.** German runs ~30% longer than English, French ~20%; Persian and Arabic are shorter in characters but taller in line box.

- Buttons size to content with a minimum width and **wrap to two lines rather than truncate or auto-shrink**. The only shrink exception is large numeric readouts (odometer, cost).
- Field labels sit **above** inputs, never beside them — side-by-side labels are where expansion breaks first.
- Bottom-nav and tab labels carry an explicit `maxChars`: 12 characters at the largest system text scale. If a locale cannot fit, the fix is a shorter translation, not an ellipsis.
- Two-column label/value rows give the label at most 60% and let it wrap.
- Every layout survives **200% text scale × the longest of the six translations** with no truncation and no overlap.

Copy rules for translators: imperative mood, no exclamation marks, no idioms, no jokes. Write RTL strings in logical (typing) order, never visually reordered.

### Accessibility of text and numbers

Screen-reader strings are ICU messages like any other, authored in all six locales and covered by the CI checks above.

- **Each text run exposes its language** so TalkBack and VoiceOver switch voice mid-screen: a Latin workshop name inside a Persian card is tagged `en`.
- **Numbers are announced in the display digit set**, in spoken form, never as a glyph string.
- **`~` is never read as "tilde".** Every estimated value carries `semanticsLabel` = *"estimated, about {value}"* (key `common.estimated.a11y`), and the `~` stays part of the visible string as the non-colour marker of an estimate.
- **Bidi controls never reach a semantics label.** Isolates are a rendering device; a reader voicing `U+2068` — or silently swallowing it — is a bug either way. Strip them in the accessibility layer, as the export layer does.

### Testing

1. **Screenshot goldens: 6 locales × 8 screens** — home, vehicle detail, add fill-up, reminder detail, service history, cost summary, settings, export/import. A diff is a review gate, not an auto-accept.
2. **Two pseudo-locales** from `app_en.arb`: `en-XA`, accented and bracketed at +40% — `[Ħǿḿḗ ŝƈřḗḗǹ ǃǃǃ]` — catches hard-coded strings and truncation; `ar-XB`, forced RTL with reversed Latin, catches hard-coded `left`/`right` without reading Arabic.
3. **Longest-string pass.** A synthetic locale taking the longest of the six translations per key, through the golden suite at 100% and 200% text scale.
4. **RTL pass reviewed by a native reader** of `fa` and `ar` (`ckb` if reachable): back chevron, drawer side, tab order, chart axis, slider fill, swipe-action side, progress fill, numbers not stranded on the wrong side of a card, no LTR-aligned text in an RTL row.
5. **Bidi corpus.** Goldens in all three RTL locales for vehicle `BMW ۳۲۰i`, note `قبض از Shell — €۵۲٫۳۰ (A2)`, workshop `Autohaus Müller`; assert no bidi controls in the export of the same fixtures.
6. **Font coverage, automated.** Every codepoint in each RTL locale's ARB plus the Sorani letter list has a real glyph — no `.notdef`, no fallback. This is what stops the ransom-note bug reaching a device.
7. **Glyph clipping.** RTL goldens at 100% and 200% scale, including a single-line row of `ژ چ گ ج ح خ ڕ ڵ`.
8. **Plural matrix.** Every count-bearing string for n ∈ {0, 1, 2, 3, 10, 11, 20, 99, 100, 101, 102, 103, 110, 1000}, all six locales. Arabic must give six visibly distinct forms; Persian must read correctly at 0.
9. **Number round-trip.** Per locale × numbering system: format, feed back through `normalizeNumericInput`, assert equality. Include `1.234,56`, `1,234.56`, `۱٬۲۳۴٫۵۶`, `١٢٣٤٫٥٦`.
10. **Calendar round-trip.** Gregorian → Jalali → Gregorian identity for every day 1300–1500 AP, plus the four anchors and a Nowruz table.
11. **Locale switch mid-form.** Form state survives, direction flips, notifications are rescheduled in the new language, no cached layout leaks.
12. **Export/import cross-locale.** Export from `fa` with Jalali display and Persian digits: ASCII digits and ISO dates only. Import on `en-US`: every value, date and amount identical.
13. **Device matrix.** One non-Google Android build (Samsung or Xiaomi) per release, where font fallback breaks, and one older iOS device for the Geeza Pro path.
14. **Screen-reader pass** on home, the log modal and the import screen, one LTR and one RTL locale: language tagging, digit announcement, the estimate label.

---

## 6. Backup, export and import

One file stands between a user and eight years of history. So it is plain, self-describing, versioned, and small enough to email.

### 1. Canonical model and the export mapping

The entity definitions in *Domain model and rules* are canonical. The export is a projection of them: §2.4 is a field-by-field mapping, not a second model. Names, enums and validation rules are the domain's; this section never redefines one.

Quantities in the file are the canonical integers the app stores — `odometer_m`, `quantity_ml` / `quantity_g` / `energy_wh`, `amount_minor` + `currency` — never a converted or rounded display value. Beside each sits a provenance field (`odometer_unit`, `quantity_unit`, `interval_distance_unit`) recording the unit the user typed; it never enters arithmetic.

### 2. The file format

One JSON document, UTF-8, no BOM, real UTF-8 characters rather than `\uXXXX` escapes — a Persian user must be able to read their own notes in a text editor. Pretty-printed, 2-space indent: the ~18% size cost buys a readable file. Keys are `snake_case` English regardless of app language; values are the user's own text in their own script. Digits are always ASCII `0-9` — the file is interchange, not display.

#### 2.1 Envelope

| Key | Type | Notes |
|---|---|---|
| `format` | string | Always `"odova.backup"`. Identification is a string compare, not a guess. |
| `format_version` | int | Currently `1`. Bumps **only** on a breaking change; additive fields never bump it. |
| `app_version` | string | `"1.4.2"`. Informational — never used for branching logic. |
| `app_build` | int | For bug reports. |
| `platform` | string | `"android"` \| `"ios"`. Informational. |
| `exported_at` | string | RFC 3339 UTC instant. |
| `exported_at_local` | string | Same instant with the writer's offset — this is what the UI shows, because "18:41" is what the user remembers. |
| `units` | object | `{"distance":"m","volume":"ml","mass":"g","energy":"wh","money":"minor"}`. Says what every `*_m` / `*_ml` / `*_minor` field is in, so a human opening the file is not guessing at `215104000`. |
| `derived_fields` | array | Dotted paths written for a human reader and **ignored on import** (§4.2). |
| `record_counts` | object | Per-array counts plus `total`. Catches truncation and clumsy hand-editing. |
| `content_hash` | string | `"sha256:<64 hex>"` over the file's own bytes (§2.6). Mismatch is a **warning**, never a refusal. |

#### 2.2 Identifiers, dates, numbers, money

**IDs** are `<prefix>_<ULID>` — 26 Crockford base-32 chars, e.g. `veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD` — in the database, in the file and in every notification payload. Prefixes are the domain's, nine of them: `veh_` vehicle, `rem_` service item/reminder, `srv_` service record, `lin_` service line, `fil_` fill-up, `exp_` expense, `trp_` trip, `odo_` odometer reading, `cor_` odometer correction. UUIDv7 is not used.

**Dates**, three kinds, never mixed: event dates the user picked, `"occurred_on": "2026-08-14"`, zoneless proleptic Gregorian, so a fill-up on 14 August stays 14 August after the user flies to another continent; machine instants, `"created_at": "2026-08-14T16:22:03Z"`, always UTC with `Z`; clock times, `"time": "18:22"`, 24-hour. ASCII digits and Gregorian even on a Jalali or Hijri device.

**Numbers** are JSON numbers, never strings, never `NaN`/`Infinity`, and every quantity is an integer in the canonical unit. **Money** is always the object `{"amount_minor": 7351, "currency": "EUR"}`, currency an uppercase ISO 4217 code; the `"45.99 EUR"` decimal-string form is withdrawn. Iranian amounts are stored and exported as **IRR** minor units — toman is a display setting (`settings.currency_display`), never a stored currency, and `IRT` never appears in a file. Conversion for display is exact (1 mi = 1.609344 km, 1 US gal = 3.785411784 L). Allowed unit and enum values live in *Domain model and rules*; the file admits those and no others.

#### 2.3 Entities

Every record carries `id`, `created_at`, `updated_at`, `deleted_at`. Every child carries exactly one parent link, `<parent>_id`. **A relationship is stored once, on the child, and never mirrored on the parent** — mirrored links are how two halves of a file end up disagreeing.

Deleted rows are not exported, so `deleted_at` is present on every record and always `null` in a v1 file. It is written anyway so a future merge mode needs no format bump.

#### 2.4 The mapping

**vehicles** — required: `id`, `name`, `vehicle_type`, `fuel_kind_default`, `is_business`, `status`, `notifications_muted`, `sort_order`. Optional: `make`, `model`, `year`, `plate`, `vin`, `colour`, `notes`, `tank_capacity_ml`, `purchase_date`, `purchase_odometer_m`, `purchase_price`, `sold_on`, `sold_price`, `expected_annual_m`, `notice_distance_m`, `notice_days`.

Three export-specific rules:

- `status` is `active | archived | sold` and replaces the old `archived` boolean. A sold car must come back sold, or its ownership span and its report header are wrong.
- `distance_unit`, `volume_unit`, `consumption_unit` and `currency` are optional, and **absent or null means inherit the global setting**. A writer must not materialise the inherited value, or after a round trip every vehicle is pinned to whatever the defaults happened to be at export time.
- `vehicle_type`, `is_business` and `expected_annual_m` are in the file because a restore without them degrades silently: every motorbike returns as a car with a car's seeded reminders, the business/private cost split disappears, and the projection drops to the global default.

**reminders** — the `ServiceItem` projection. Required: `vehicle_id`, `kind`, `notify`, `repeats`, `is_tracked`, `is_active`, `priority`, `rollover`, `snooze_count`. Optional: `label` (required iff `kind == "custom"`), `interval_distance_m`, `interval_distance_unit` (provenance, required iff the interval is set), `interval_months`, `target_odometer_m`, `target_date`, `baseline_date`, `baseline_odometer_m`, `notice_distance_m`, `notice_days`, `snoozed_until`, `snooze_until_odometer_m`, `notes`.

`last_done_date`, `last_done_odometer_m` and `last_done_service_id` are **derived**: written so the file reads sensibly, listed in `derived_fields`, ignored on import — the anchor is recomputed by `resolveAnchor` (§4.2).

There is no `rule` field and no `mode` field: which axes exist follows from which interval fields are non-null, and combination is always whichever-comes-first (*Domain model and rules*). Next due is not stored either — a stored derived value can disagree with its own inputs.

**odometer_readings** — standalone readings only: `vehicle_id`, `occurred_on`, `odometer_m`, `odometer_unit` (required), `source` (always `manual` in v1), `notes`. `source_id` is null on every exported reading, since only standalone readings are written, and it is therefore omitted from the file. Fill-ups, services and expenses already carry an odometer; the mileage log is a view over all four sources, and this array holds only the readings with no other home.

**odometer_corrections** — `vehicle_id`, `from_reading_id`, `previous_m`, `new_m`, `odometer_unit`, `reason` (required), `notes`.

Every cumulative distance in the app is `odometer_m + Σ(previous_m − new_m)` over the corrections at or before that reading (*Domain model and rules* → The odometer). Leave corrections out of the file and a user whose cluster was replaced gets a restore in which lifetime distance, every fuel segment spanning the correction, the daily-distance rate and every projected due date are silently wrong — and the raw readings fail the monotonicity invariant with nothing to explain them.

**fillups** — required: `vehicle_id`, `occurred_on`, exactly one of `quantity_ml` / `quantity_g` / `energy_wh` by the vehicle's fuel kind, `quantity_unit` (provenance — a fill is litres, gallons *or* kWh, so it is a quantity, not a volume), `total_cost`, `is_full_tank`, `chain_broken`. Optional: `fuel_kind` (defaults to the vehicle's), `station`, `grade`, `notes`, `trip_id`. `odometer_m` and `odometer_unit` are required by the entry form but **nullable on import**, for legacy and hand-made files; such a fill is treated as a chain break.

Unit price is not in the file; it is derived from quantity and total at display time, exactly as the domain stores it, so the two can never disagree with a third. It appears as a computed CSV column (§8.1) and nowhere else.

**services** — required: `vehicle_id`, `occurred_on`, `odometer_m`, `odometer_unit`, `odometer_estimated`, `cost_estimated`, `lines[]`. Optional: `vendor`, `invoice_ref`, `warranty_until`, `notes`. Each line is `{id, service_item_id, label, amount_minor, currency, part_number, notes}`, where `service_item_id` is the reminder that line reset, or null.

**The record's cost is the sum of its lines.** No `total_cost`, `parts_cost` or `labour_cost`: a second cost field is a number that can disagree with the rows above it. Lines carry their own id and label because two custom items of the same kind on one invoice are ordinary, and because search matches on `part_number`. `cost_estimated` is false by default and true when the notification **Done** action wrote the record with no cost; it is exported because it is the only thing keeping "cost not recorded" distinct from "cost was zero", and dropping it turns every estimated service cost into a real one on restore.

**expenses** — everything that is not fuel and not a service: `vehicle_id`, `occurred_on`, `category`, `amount` required; `label`, `vendor`, `notes`, `odometer_m` + `odometer_unit`, `trip_id` optional; `covers_from` / `covers_to` spread an annual premium across months so cost-per-month is not a spike. **Fuel and services are never expenses** — they live in their own arrays and the cost engine unions all three; anything else double-counts.

**trips** — `vehicle_id`, `purpose` required; `title` optional (the list falls back to a date range); `started_on` and nullable `ended_on`, both zoneless `YYYY-MM-DD` like every other event date; `start_odometer_m`, `end_odometer_m`, `odometer_unit`; `manual_distance_m` present **only** when the odometers are absent; `notes`. Trip expenses and trip fill-ups point at the trip, not the reverse.

**settings** — a single object, not an array.

```
language, theme, currency_default, currency_display, distance_unit,
volume_unit, consumption_unit, first_day_of_week, calendar,
numerals, notification_time, quiet_hours_from, quiet_hours_to, weekdays_only,
notify_service, notify_odometer, notify_backup, notice_days, notice_distance_m,
active_vehicle_id, last_backup_at
```

Storage keys are fixed here. `Settings.volume_unit` is a display default and keeps that name; the per-fill provenance field is `quantity_unit`. `first_day_of_week` is an ISO-8601 weekday, 1 = Monday, never a string like `"mon"`; `notice_days` is a whole number of days, clamped 7–30. Allowed values for `language`, `calendar` and `numerals` belong to *Languages, RTL and formats*.

#### 2.5 Worked example

A German user's file, one vehicle, seven records: German free text under English keys, ASCII digits, canonical integers.

```json
{
  "format": "odova.backup",
  "format_version": 1,
  "app_version": "1.4.2",
  "app_build": 1402,
  "platform": "android",
  "exported_at": "2026-09-02T16:41:07Z",
  "exported_at_local": "2026-09-02T18:41:07+02:00",
  "units": { "distance": "m", "volume": "ml", "mass": "g", "energy": "wh", "money": "minor" },
  "derived_fields": [
    "reminders.last_done_date",
    "reminders.last_done_odometer_m",
    "reminders.last_done_service_id"
  ],
  "record_counts": {
    "vehicles": 1, "reminders": 1, "odometer_readings": 1, "odometer_corrections": 0,
    "fillups": 1, "services": 1, "expenses": 1, "trips": 1, "total": 7
  },
  "content_hash": "sha256:0f7e1d0d3a6c9e2b4f8a1c5d7e9b0a2c4d6e8f0a1b3c5d7e9f1a3b5c7d9e1f30",

  "settings": {
    "language": "de",
    "theme": "system",
    "currency_default": "EUR",
    "currency_display": "none",
    "distance_unit": "km",
    "volume_unit": "l",
    "consumption_unit": "l_100km",
    "first_day_of_week": 1,
    "calendar": "gregorian",
    "numerals": "latin",
    "notification_time": "09:00",
    "quiet_hours_from": "21:00",
    "quiet_hours_to": "08:00",
    "weekdays_only": false,
    "notify_service": true,
    "notify_odometer": true,
    "notify_backup": true,
    "notice_days": 14,
    "notice_distance_m": 500000,
    "active_vehicle_id": "veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD",
    "last_backup_at": "2026-06-11T15:02:44Z"
  },

  "vehicles": [
    {
      "id": "veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD",
      "name": "Golf",
      "make": "Volkswagen",
      "model": "Golf VII 1.6 TDI",
      "year": 2016,
      "plate": "M-AB 1234",
      "vin": "WVWZZZ1KZGW123456",
      "vehicle_type": "car",
      "fuel_kind_default": "diesel",
      "is_business": false,
      "tank_capacity_ml": 50000,
      "distance_unit": null,
      "volume_unit": null,
      "consumption_unit": null,
      "currency": null,
      "expected_annual_m": 18000000,
      "notice_distance_m": null,
      "notice_days": null,
      "status": "active",
      "sold_on": null,
      "sold_price": null,
      "purchase_date": "2019-04-06",
      "purchase_odometer_m": 86450000,
      "purchase_price": { "amount_minor": 1290000, "currency": "EUR" },
      "notifications_muted": false,
      "sort_order": 0,
      "colour": "#2F6FB2",
      "notes": "Zahnriemen laut Werkstatt bei ca. 210.000 km fällig.",
      "created_at": "2019-04-08T09:12:44Z",
      "updated_at": "2026-08-30T07:03:19Z",
      "deleted_at": null
    }
  ],

  "reminders": [
    {
      "id": "rem_01JV7B5X4G2K9M6P0S3D8FNRTC",
      "vehicle_id": "veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD",
      "kind": "oil_and_filter",
      "label": null,
      "interval_distance_m": 15000000,
      "interval_distance_unit": "km",
      "interval_months": 12,
      "target_odometer_m": null,
      "target_date": null,
      "baseline_date": null,
      "baseline_odometer_m": null,
      "notify": true,
      "priority": "normal",
      "rollover": "from_actual",
      "repeats": true,
      "is_tracked": true,
      "is_active": true,
      "notice_distance_m": 500000,
      "notice_days": 14,
      "snoozed_until": null,
      "snooze_until_odometer_m": null,
      "snooze_count": 0,
      "last_done_date": "2026-05-22",
      "last_done_odometer_m": 208940000,
      "last_done_service_id": "srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX",
      "notes": null,
      "created_at": "2019-04-08T09:19:02Z",
      "updated_at": "2026-05-22T15:41:10Z",
      "deleted_at": null
    }
  ],

  "odometer_readings": [
    {
      "id": "odo_01K2S1D9F4H7J0L3N6Q9T2W5YB",
      "vehicle_id": "veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD",
      "occurred_on": "2026-09-01",
      "odometer_m": 215104000,
      "odometer_unit": "km",
      "source": "manual",
      "notes": "Monatsablesung",
      "created_at": "2026-09-01T07:55:12Z",
      "updated_at": "2026-09-01T07:55:12Z",
      "deleted_at": null
    }
  ],

  "odometer_corrections": [],

  "fillups": [
    {
      "id": "fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH",
      "vehicle_id": "veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD",
      "occurred_on": "2026-07-29",
      "odometer_m": 214256000,
      "odometer_unit": "km",
      "quantity_ml": 44020,
      "quantity_unit": "l",
      "total_cost": { "amount_minor": 7351, "currency": "EUR" },
      "is_full_tank": true,
      "chain_broken": false,
      "fuel_kind": "diesel",
      "station": "Shell Rosenheimer Str.",
      "grade": "Diesel B7",
      "notes": "",
      "trip_id": null,
      "created_at": "2026-07-29T05:15:38Z",
      "updated_at": "2026-07-29T05:15:38Z",
      "deleted_at": null
    }
  ],

  "services": [
    {
      "id": "srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX",
      "vehicle_id": "veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD",
      "occurred_on": "2026-05-22",
      "odometer_m": 208940000,
      "odometer_unit": "km",
      "odometer_estimated": false,
      "cost_estimated": false,
      "lines": [
        {
          "id": "lin_01K0C4V2H9B8N3Q7ZE5RY6TMX1",
          "service_item_id": "rem_01JV7B5X4G2K9M6P0S3D8FNRTC",
          "label": "Ölwechsel",
          "amount_minor": 9820,
          "currency": "EUR",
          "part_number": "Castrol Edge 5W-30",
          "notes": "4,3 l"
        },
        {
          "id": "lin_01K0C4V2H9B8N3Q7ZE5RY6TMX2",
          "service_item_id": null,
          "label": "Innenraumfilter",
          "amount_minor": 4700,
          "currency": "EUR",
          "part_number": "Mann CU 2939",
          "notes": ""
        }
      ],
      "vendor": "Kfz-Werkstatt Reiter, München",
      "invoice_ref": "R-2026-0488",
      "warranty_until": "2027-05-22",
      "notes": "Bremsbeläge vorne bei der nächsten Inspektion prüfen.",
      "created_at": "2026-05-22T15:41:10Z",
      "updated_at": "2026-05-22T15:41:10Z",
      "deleted_at": null
    }
  ],

  "expenses": [
    {
      "id": "exp_01K1R9T6Y2W5Q8Z3E7B0N4MJDF",
      "vehicle_id": "veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD",
      "occurred_on": "2026-01-03",
      "odometer_m": 201430000,
      "odometer_unit": "km",
      "category": "insurance",
      "label": "Kfz-Haftpflicht + Teilkasko 2026",
      "amount": { "amount_minor": 61200, "currency": "EUR" },
      "vendor": "HUK-Coburg",
      "notes": "SF-Klasse 22, 300 € Selbstbeteiligung.",
      "covers_from": "2026-01-01",
      "covers_to": "2026-12-31",
      "trip_id": null,
      "created_at": "2026-01-03T10:02:51Z",
      "updated_at": "2026-01-03T10:02:51Z",
      "deleted_at": null
    }
  ],

  "trips": [
    {
      "id": "trp_01K2P0M4A7C1V9X6H2L5S8GQZR",
      "vehicle_id": "veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD",
      "title": "Kundenbesuch Nürnberg",
      "purpose": "business",
      "started_on": "2026-08-21",
      "ended_on": "2026-08-21",
      "start_odometer_m": 214438000,
      "end_odometer_m": 214870000,
      "odometer_unit": "km",
      "manual_distance_m": null,
      "notes": "",
      "created_at": "2026-08-21T17:10:44Z",
      "updated_at": "2026-08-21T17:10:44Z",
      "deleted_at": null
    }
  ]
}
```

#### 2.6 Array order, unknown keys, content_hash

Arrays are written `settings, vehicles, reminders, odometer_readings, odometer_corrections, fillups, services, expenses, trips` — parents before children, so a streaming reader resolves links in one pass. Records inside an array are sorted by `id`, which for ULIDs means creation order.

Two exports of unchanged data differ only in `exported_at`, `exported_at_local`, `app_version`, `app_build` and `content_hash`. Everything below `settings` is byte-identical, which makes `diff` past the envelope a real answer to "did anything change?" — and the CI corpus test asserts exactly that: export twice, strip the envelope, compare bytes.

A reader **ignores keys it does not recognise**, at every level, and does not preserve them. That is what lets v1.4 add `fillups[].tyre_pressure_kpa` without a format bump, and a v1.4 file open in v1.2 with nothing worse than a missing column.

`content_hash`: serialise the document with the hash field set to 64 `0` characters, SHA-256 those exact bytes, overwrite the zeros in place — same length, so no offsets shift. A verifier does the reverse. It catches truncated downloads and half-written files, not tampering: there is no secret, so anyone who edits the file can recompute it. A mismatch means "not byte-for-byte what Odova wrote", which is also true of a legitimate hand-edit, so it is a warning the user can wave through.

### 3. Versioning and migration

**`format_version`** is the shape of the JSON file, currently `1`, and bumps only when an existing key changes meaning or type or disappears. The on-device **`schema_version`** is internal, bumps freely, and never appears in the file — so a database refactor does not invalidate every backup in the world. The number the user can quote is `format_version`, which is why Settings → About shows "Backup format 1".

#### 3.1 Reading an old file

Migration is a chain of pure `json → json` functions applied in memory **before** anything touches the database:

```
import(doc):
  if doc.format == null or doc.format != "odova.backup": reject(NOT_ODOVA)
  v = doc.format_version
  if v is not int or v < 1:                               reject(CORRUPT_VERSION)
  if v > SUPPORTED_FORMAT_VERSION:                        reject(TOO_NEW)
  while v < SUPPORTED_FORMAT_VERSION:
     doc = MIGRATIONS[v](doc)     # pure, in memory, no I/O
     v  += 1
     doc.format_version = v
  return validate(doc)
```

A v1 file opened by a v4 app runs `1→2→3→4` and then follows the ordinary import path. There is no special case for "old file"; there is only the chain.

Three rules for writing a migration, which are the whole reason this works:

1. It never deletes a user value. If a field is retired, its content moves somewhere — worst case, appended to the record's `notes`.
2. It never fails on missing data. A field added in v2 gets a default; a field made required gets a synthesised value with an explicit rule.
3. It ships with a real file from the previous version in the test corpus, checked into the repo. The corpus only grows; CI imports every file in it on every build, and a red corpus blocks release.

Filling in absent fields is what the chain mostly does:

| Absent field | Filled with |
|---|---|
| `vehicles[].status` | `archived ? "archived" : "active"` (the old boolean is read, then dropped) |
| `vehicles[].vehicle_type` | `"car"` |
| `vehicles[].is_business`, `notifications_muted` | `false` |
| `reminders[].notify`, `repeats`, `is_active` | `true` |
| `reminders[].is_tracked` | `true` |
| `reminders[].priority` / `rollover` / `snooze_count` | `"normal"` / `"from_actual"` / `0` |
| `services[].odometer_estimated` | `false` |
| `services[].cost_estimated` | `false` |
| `settings.quiet_hours_from` / `_to` | `21:00` / `08:00` |
| `settings.weekdays_only` | `false` |
| `settings.notify_*` | `true` |
| `settings.currency_display` | `"toman"` when `language == "fa"`, else `"none"` |

`reminders[].rule` is dropped on read: `distance_only` clears `interval_months`, `date_only` clears `interval_distance_m`, and `whichever_last` becomes an ordinary whichever-comes-first reminder, listed in the import warning — *"{n} reminders used a setting Odova no longer has. They now warn you at whichever comes first — check them under Reminders."*

#### 3.2 Reading a newer file — the refusal

If `format_version` exceeds what the running app supports, the import is **refused outright**. No partial read, no "import what we understand": a bump exists precisely because something means a different thing now, and guessing at it is how you silently corrupt someone's history.

> **This backup was made with a newer version of Odova.**
> Update Odova from the app store, then import again. Your file has not been changed.

The file is never modified, moved, or deleted by a refusal. Downgrade is not supported and never will be.

#### 3.3 Surviving app updates

- Before any on-device schema migration runs, the app writes a full JSON backup to app-private storage using the **old** schema's reader — one of the three safety copies in §4.4.
- A migration failure **restores the pre-migration copy before showing any UI**, and the app then runs on the old schema read-only: logging is disabled, and Export, CSV and PDF run through the retained reader for that `schema_version`. Readers for every shipped schema version are kept forever; that is why they are numbered. Banner: *"Odova couldn't finish updating and has gone back to your previous data. You can't add new entries until this is fixed — back up now."* Recovery must not depend on the code that just failed: exporting through current-schema readers after a migration crash is exporting through the crash.
- The app's data directory stays inside the OS's own app-backup mechanism (Android auto-backup, iOS container backup) — the OS moving the user's own bytes for the user, not our server, so it does not touch the no-network constraint, and it catches the phone that fell in a canal.

The migration time budget for the floor device is in *Domain model and rules* → Durability.

### 4. Import semantics

**Import replaces everything. There is no merge in v1.**

There is no sync, so a backup file is a complete snapshot of one device at one moment, not a stream of changes. The two real scenarios are *new phone* and *something went wrong*; in both, the file should win entirely and the result should be exactly the phone the file came from. Every merge design we sketched ends in duplicate fill-ups two days apart with slightly different odometers, quietly poisoning every consumption figure downstream — and needs a UI in which a driver who does not enjoy this task adjudicates 400 of them. Replace is the one behaviour that fits in a single true sentence on the confirm screen.

The cost is real and mitigated, not denied: importing a three-month-old file loses three months. That is what the preview (§4.3) and the safety copy (§4.4) are for.

**v2, not built:** a separate, explicitly-labelled "Add a vehicle from a file" action, never a mode toggle on Restore. Recorded so v1 does not foreclose it: identity is `id`, an existing `id` is skipped rather than overwritten, a new `id` is inserted, vehicles keep both copies. Nothing merges by content.

#### 4.1 Transactional write

Parse and migrate in memory, write into a fresh empty database file, verify counts, then swap it into place with a single atomic rename. A process kill at any instant leaves either the old data or the new data, never a mixture. *Why a rename rather than one big transaction:* it is atomic on every filesystem we ship to and does not depend on the storage engine's crash behaviour under a multi-megabyte commit.

After the swap, in order: corrections are applied, then every derived value is rebuilt — consumption, cost roll-ups, next-due dates — then all local notifications are cancelled wholesale and rescheduled, because the notification IDs held by the OS belong to the old data.

#### 4.2 What the file does not get to decide

`derived_fields` are read for display of the file itself and then discarded. Anchors are recomputed by `resolveAnchor` (*Domain model and rules* → Due state per item), which reads `services[].lines[].service_item_id` first and falls back to the item's imported `baseline_date` / `baseline_odometer_m`, then the vehicle's purchase pair, then the earliest reading; cost comes from the sum of lines, due dates from the engine. A file that disagrees with its own inputs loses.

#### 4.3 The preview — nothing is written before this

Pick file → read and validate → **preview** → confirm → write. The preview is mandatory, cannot be skipped, and reaching it has changed nothing on the device. Its layout is in *Settings*; what it must carry is:

- File name and export date in the user's own format — *"odova-backup-2026-09-02-1841.json, exported 2 September 2026 at 18:41"* — plus the app version that wrote it.
- The vehicles in the file, by name, each with its record count. Names are what the user recognises; totals are not.
- A two-column comparison, **now** vs **after import**, for every record type and the total.
- Every validation warning in plain language, each with its record count.
- One unambiguous sentence: **"Everything now in Odova will be replaced by this file."**
- One line of reassurance, because it is true: *"A copy of your current data is saved first, so you can undo this."*

Buttons: **Replace my data** / **Cancel**. On an empty device the sentence becomes *"Odova is empty, so nothing will be replaced."* and the button becomes **Import**.

When the file's `content_hash` equals that of the last successful import and nothing has been written since, the comparison block is replaced by **"This is the backup you already restored. Nothing on this phone will change."**, the primary button becomes **Done**, and **Replace anyway** sits beneath it as a text button.

The preview never shows a technical term. "Records", "fill-ups", "services" — never "rows", "entities", "schema", "parse".

#### 4.4 The automatic safety copy

Odova keeps **one safety copy per destructive operation kind**, three files at most, in app-private storage:

```
odova-safety-migration-<version>.json
odova-safety-import-<timestamp>.json
odova-safety-wipe-<timestamp>.json
```

Each is overwritten only by the next operation of the *same* kind, so an import can never eat the copy a wipe left. Any operation that destroys data writes its file first — import, *Delete all data*, every schema migration. No exceptions.

One exception, because it is the commonest recovery panic: a copy is **not** overwritten by an import whose `content_hash` and `record_counts` match the currently-loaded import. Otherwise importing the same file twice replaces the user's real data with the file's own contents, and the three months they were trying to get back are gone.

Settings gains **Undo last import**, live for 30 days, showing what it would restore ("your data as it was on 2 September at 18:41 — 2 vehicles, 431 records"). Undo is itself a replace and takes its own safety copy first, so a user can bounce back and forth without reaching a state they cannot leave.

Safety copies live in app-private storage, so uninstalling deletes them. Settings says so, once, next to the button — a seatbelt, not a vault; the user's own exported file remains the real backup.

### 5. Validation and errors

Two tiers, and the distinction is the whole design: **document-level failures abort the import** — nothing is written, the file is untouched; **record-level problems never abort** — a bad record is skipped, counted and listed, and the rest imports.

**Type errors reject a record. Odd values do not.** A `quantity_ml` of `"forty"` is unreadable and the record is skipped. A 312-litre fill in a 50-litre tank is the user's data — imported, and mentioned in the report. We are not the arbiter of what happened to someone's van.

#### 5.1 Order of checks

1. **Size** — over 64 MB, reject before opening. (A ten-year backup is around 4 MB; §9.)
2. **Bytes** — gzip/zip magic → the "unzip it first" message. Not valid UTF-8 → reject. A leading BOM is stripped silently.
3. **JSON parse** — a parse error at the very end of the file is reported as *truncated*, anywhere else as *not valid*.
4. **Magic** — `format == "odova.backup"`, else reject.
5. **`format_version`** — integer ≥ 1 and ≤ supported, else reject.
6. **Migrate** to the current version.
7. **Shape** — top-level arrays present and actually arrays. A missing array is treated as empty and warned about; a `fillups` that is a string is a document-level failure.
8. **`content_hash`** and **`record_counts`** — mismatch is a warning shown in the preview.
9. **Records** — required fields present and correctly typed, dates parseable, enums recognised. An unknown enum value keeps the record and coerces to `other` / `custom` with a warning — an unknown category must not cost a user their €612 insurance row.
10. **Dates** — a record dated before 1990, or more than two years after `exported_at`, is imported and warned about, never dropped. A phone whose clock was wrong is still the user's history.
11. **Links** — every `vehicle_id` resolves (orphans: §5.3); `trip_id` and `service_item_id` resolve or are nulled with a warning; a correction whose `from_reading_id` does not resolve is **skipped and warned about, never applied to an arbitrary reading**.
12. **Duplicate IDs within the file** — first occurrence wins, the rest are counted and warned about.
13. **Blast radius** — if more than 5% of records, or more than 50 records, are unreadable, the import is refused as too damaged. Below that it proceeds with a report.

#### 5.2 The messages

Written for someone who has never heard the word "JSON": what happened, and what to do next. English source strings; *Languages, RTL and formats* owns the translations.

| Condition | Message |
|---|---|
| Not JSON at all (a PDF, a photo) | **That file isn't an Odova backup.** Odova backups are `.json` files made from Settings → Export. Pick a different file. |
| Valid JSON, no `format` key | **This file wasn't made by Odova.** It's a valid file, but not one Odova can read. Nothing on your phone has changed. |
| Truncated (parse fails at EOF) | **This file is incomplete.** It may not have finished downloading or copying. Get the file again and try once more. |
| `format_version` too new | **This backup was made with a newer version of Odova.** Update Odova, then import again. Your file hasn't been changed. |
| `format_version` missing / not a number | **This backup file is damaged** and Odova can't tell which version it is. If you have another copy or an older backup, try that one. |
| Gzip/zip detected | **This file is compressed.** Unzip it first, then import the `.json` file inside. |
| Not UTF-8 | **Odova can't read the text in this file.** It may have been changed by another program. Try the original file you exported. |
| Over 64 MB | **This file is too large to be an Odova backup** (it's 203 MB). Even ten years of records comes to a few megabytes, so this is probably a different file. |
| More than 5% of records unreadable | **Too much of this backup is damaged to import safely.** Odova could read 812 of your 1,204 records, and importing part of your history would leave gaps. Try an older backup if you have one. Nothing on your phone has changed. |
| `content_hash` mismatch (warning) | **This file has been edited since Odova saved it.** That's fine if you changed it on purpose. Check the numbers below before you continue. |
| `record_counts` mismatch (warning) | **This file doesn't contain everything it says it should** — it lists 1,204 records and 1,180 were found. It may have been cut short. Check the numbers below. |
| Records skipped (warning) | **7 records couldn't be read and won't be imported.** Everything else will. Tap to see which ones. |
| Orphan records (warning) | **12 records don't say which vehicle they belong to.** They'll be imported under a vehicle called "Recovered records" so you can sort them out or delete them. |
| Unmatched odometer corrections (warning) | **3 odometer corrections couldn't be matched to a reading.** Your mileage history may look wrong where the odometer was replaced. Tap to see which. |
| Dropped `rule` values (warning) | **4 reminders used a setting Odova no longer has.** They now warn you at whichever comes first — check them under Reminders. |
| Out-of-range dates (warning) | **9 records have dates that look wrong** (before 1990, or after this backup was made). They've been imported so you can fix them. |
| Duplicate IDs (warning) | **This file lists 3 records twice.** Odova will import the first copy of each. |
| Cannot read the file (permission, provider error) | **Odova couldn't open that file.** Try copying it to your phone's Files app first, then import it from there. |
| Not enough storage to import | **Not enough space on your phone to import this backup.** Free up about 40 MB and try again. |
| Success | **Imported.** 3 vehicles and 1,204 records restored. Your reminders have been recalculated. |

The skipped-records detail view lists each one as type, date and plain reason — *"Fill-up, 14 August 2026 — the amount of fuel was missing"* — because a user who knows exactly what was lost can retype three rows.

#### 5.3 Orphans and the never-silently-drop rule

A record whose `vehicle_id` matches no vehicle in the file is not deleted. The import creates a vehicle named **"Recovered records"** (`import.recoveredVehicleName`, localised) and attaches every orphan to it; the user can rename it, reassign the records, or delete it. Losing data is the worst possible bug, and a placeholder the user can see beats a number in a report they will not read.

#### 5.4 Memory and hostile input

Files over 4 MB are parsed incrementally, array element by array element, so peak memory stays under roughly 3× the file size whatever shape the file is. Nesting depth is capped at 32 (the real format uses 4). Strings longer than 1 MB are truncated with a warning. A "backup" is any file the user picked, including one they downloaded by accident.

### 6. File naming and delivery

**Backup filename:** `odova-backup-YYYY-MM-DD-HHmm.json`, from **local** time — `odova-backup-2026-09-02-1841.json`.

ASCII lowercase, hyphens, no spaces, no translated app name, no vehicle names: this passes through email, Windows, USB sticks and every cloud drive unmangled, it sorts chronologically, and an RTL filename in an LTR file manager renders in ways nobody enjoys. Where we control the destination a collision appends `-2`, `-3`; otherwise the OS handles it.

Other exports, same convention: `odova-fillups-golf-2026-09-02.csv`, `odova-costs-all-2026-09-02.csv`, `odova-service-history-golf-2026-09-02.pdf`, `odova-reminders-2026-09-02.ics`. The vehicle part is transliterated to `[a-z0-9-]`; if nothing survives (a name written only in Arabic script) it falls back to `vehicle-2` by list position.

**Export delivery.** The app writes the file to its own temporary directory and hands it to the OS's standard "share or save this file" mechanism. It does not choose a destination, ask for storage permissions, or remember where the file went; temporary copies are deleted on the next launch. Nothing is exported automatically, on a schedule, or in the background — every file leaving the app is a thing the user tapped.

**Import delivery.** The app opens the OS document picker, filtered loosely (JSON plus "all files"), because providers routinely hand back `.json` as `application/octet-stream` or `text/plain` and a strict filter greys out the very file the user is selecting. **Identification is by content (`format` key), never by MIME type or extension.** The picker is reachable from first run as well as from Settings — restoring eight years onto a new phone must not require inventing a fake vehicle first (*First run, the garage, and vehicles*).

Odova does **not** register as a system handler for `.json`; claiming that type makes it the suggested app for every JSON file on the phone. Import starts inside the app.

**The backup nudge**, because a backup nobody takes is not a backup: Settings shows the date of the last export as a quiet line, amber after 90 days. At most one notification every 90 days, and only with 20 or more new records since the last export — *"It's been three months since you saved a backup of Golf and the van."* Never exported and fewer than 20 records: silence.

### 7. What is deliberately not in the backup

| Not included | Why |
|---|---|
| Anything derived — consumption, cost per km, monthly totals, next-due dates, unit price | Recomputed from the source records on import. A stored derived value can disagree with its own inputs. |
| Deleted rows and tombstones | v1 exports live rows only. `deleted_at` is written as `null` and reserved for the day merge exists. |
| Scheduled notification IDs and their OS state | They belong to the operating system on that device; everything is cancelled and rescheduled after import. |
| Photos, receipt scans, PDF invoices | v1 has no attachments; `photo_id` and `attachment_ids` are reserved, always null/empty, and omitted from the file. Base64 multiplies size by 1.37 and destroys the "open it in a text editor" property. When attachments arrive they get a companion `.zip` (backup plus a `files/` folder), not embedded blobs. |
| UI state — last open tab, scroll positions, dismissed tips, onboarding completion | Not the user's data. Restoring it onto a new phone would be strange rather than helpful. `onboarding_done` is not carried in the file at all: a successful import sets it true, and no importer reads it from the file. |
| `settings.last_backup_reminder_at` | Nudge bookkeeping, not user data; a restored phone starts its 90-day clock fresh. |
| Any device or install identifier | None exists, and an unencrypted file is a bad place to start. |
| Analytics, crash logs, usage counters | None exist. |
| Built-in reference data — task catalogue, default intervals, currency list | Ships with the app; a newer app has a better copy. Only *user-modified* reminders are in the file, and they are full records. |
| Half-finished entries the user is still typing | Not saved data. |

### 8. Other exports

Five files come out of the app, all generated on-device, offline, through the same share mechanism — four from the Export screen (backup JSON, fill-ups CSV, all-costs CSV, service-history PDF) plus the `.ics` snapshot on `settings.notifications`.

| Export | Format | v1? |
|---|---|---|
| Backup | JSON, this document | Yes |
| Fill-ups | CSV | Yes |
| All costs | CSV | Yes |
| Service history | PDF | Yes |
| Reminder snapshot | `.ics` | Yes — offered on `settings.notifications`, not on the Export screen |

#### 8.1 CSV — for the spreadsheet people

Two exports, each per-vehicle or all-vehicles.

**Fill-ups** — `date, vehicle, odometer, odometer_unit, quantity, quantity_unit, price_per_unit, total_cost, currency, is_full_tank, chain_broken, grade, distance_since_last, consumption, consumption_unit, station, notes`

**All costs** — `date, vehicle, type, category, label, vendor, odometer, odometer_unit, amount, currency, notes`, where `type` is `fuel` / `service` / `expense`. One row per cost event across all three sources, sorted by date — the file someone opens to build a pivot table.

Unlike the backup, the CSV writes numbers in the user's own units and prints derived columns (`price_per_unit`, `distance_since_last`, `consumption`): the point of a CSV is having the numbers without rewriting the formula.

Mechanics: UTF-8 **with** BOM (Excel needs it to detect UTF-8, and half this audience opens CSVs in Excel), CRLF, RFC 4180 quoting, comma separator, dot decimal, ASCII digits, ISO dates, English headers. One deterministic format that every spreadsheet, Google Sheets, LibreOffice and pandas read identically beats one convenient in Excel-with-a-German-locale and broken everywhere else; the export screen carries one line telling those users to pick comma in Excel's import dialog.

CSV is export-only. **There is no CSV import in v1** — a column-mapping UI is a whole feature, and the round-trip path is the JSON backup.

#### 8.2 Service history PDF

Generated on-device from an internal template, with a font subset covering Latin and Arabic script embedded so it renders on the buyer's machine too. Page size follows the locale (A4 or Letter); the document mirrors for RTL, and numbers and dates use the user's own numerals and calendar, unlike the machine-readable exports. Contents, the identity toggle and the export screen are in *Fuel insights, costs and reports* → `report.service`. Two things are fixed here because they are not presentation choices: plate and VIN are **off by default**, and the footer appears on every page and is not optional — *"Generated by Odova on 2 September 2026 from records kept by the owner. Not verified by a third party."* A document that looked like a certified vehicle report and was not one would be a lie.

### 9. Size and performance

Per pretty-printed record, keys and whitespace included: fill-up ~330 B, service ~700 B (two lines), expense ~300 B, trip ~380 B, odometer reading ~240 B, correction ~250 B, reminder ~600 B, vehicle ~800 B.

| Profile | 8 years | Records | File |
|---|---|---|---|
| One commuter car, fortnightly fill-ups | 210 fill-ups, 24 services, 60 expenses, 90 readings, 12 reminders | ~400 | **~160 KB** |
| Two-car household | | ~1,100 | **~420 KB** |
| Rideshare driver logging trips daily | 1,600 fill-ups, 2,900 trips, 200 services/expenses | ~4,800 | **~1.8 MB** |
| Trades, three vans, ten years, heavy trip logging | | ~12,000 | **~4.5 MB** |

The 64 MB refusal sits more than an order of magnitude beyond anything a real user can produce. It emails.

Targets on the floor device (a 2019 mid-range Android), with 5,000 records:

| Operation | Target | Hard limit |
|---|---|---|
| Export: serialise + hash + write | < 1.0 s | 3 s |
| Import: read, parse, migrate, validate, build preview | < 2.0 s | 5 s |
| Import: write the new database and swap | < 3.0 s | 8 s |
| Recompute derived data + reschedule notifications | < 1.5 s | 4 s |
| Peak memory during import | < 3× file size | 96 MB |

All of it runs off the UI thread. A progress indicator appears only past 500 ms; below that a spinner is flicker. Import is cancellable up to the swap, and cancelling leaves the device exactly as it was.

### 10. Why there is no encryption

Encryption needs a key, and with no account there is nowhere to keep one but in the user's head. The honest version of an encrypted backup is a password prompt three years later, on a new phone, for a password chosen once and never typed since — whose realistic outcome is not stolen data but a person staring at eight years of service history they can no longer open. Plain JSON is also repairable: a technical friend can open it in a text editor, and the format outlives the app.

The cost is real and the user is told once, plainly, on the export screen: **anyone who gets this file can read it.** It holds your mileage, what you paid, your plate and VIN if you entered them, and where and when your car was serviced — a rough sketch of where you have been. The phone's own encryption protects it while it stays there; the moment it is emailed or uploaded it is only as private as that mailbox or drive. Don't paste it into a forum when asking for help, delete old exports before handing on a device, and encrypt the archive yourself if you want that — Odova expects plain JSON coming back in. Because the file is readable, it is also minimal: what the user typed, and nothing else.

---

## 7. Screen map and navigation

### Shape of the app in one look

```
Odova
├─ first run ─────────────────────────────────────────────
│    settings.language (firstRun) → vehicle.edit (firstRun) → home
│    either firstRun screen → "Restore a backup" → settings.import → home
│
├─ TAB 1  home ───────────────────────────────────────────
│    ├─ vehicle.switcher            [sheet, only if >1 vehicle]
│    ├─ reminders.list              [push]
│    │    └─ reminders.edit         [modal]
│    ├─ reminders.edit              [modal]  ← tap a due card
│    └─ log.*                       [modal]  ← "Log it" on a due card
│
├─  ( + )  central button → log.* ─────────────────────────
│    log.fillup │ log.service │ log.expense │ log.odometer
│    one modal, four segments, opens on Fill-up
│
├─ TAB 2  history ────────────────────────────────────────
│    ├─ log.* (edit mode)           [modal]  ← tap any row
│    └─ report.service              [push]   → OS share sheet
│
├─ TAB 3  costs ──────────────────────────────────────────
│    ├─ costs.fuel                  [push]
│    │    └─ log.fillup (edit)      [modal]
│    ├─ trips.list                  [push]
│    │    └─ trips.edit             [modal] → log.expense (tagged)
│    └─ history (filtered instance) [push]   ← tap a cost category
│
├─ TAB 4  settings ───────────────────────────────────────
│    ├─ vehicles                    [push] → vehicle.edit [modal]
│    ├─ settings.language           [push]
│    ├─ settings.units              [push]
│    ├─ settings.notifications      [push]
│    ├─ settings.backup             [push] → settings.import [modal]
│    └─ settings.about              [push]
│
└─ dialogs (global) ──────────────────────────────────────
     dialog.discard · dialog.confirmDelete · dialog.snooze
```

Twenty-three addressable screens, four of which are tab roots, plus three global dialogs. Every stack is at most **two pushes deep** under its root. If a screen needs a third push, the architecture is wrong — fix the architecture, not the stack.

### Screen list

`kind` is binding and is not restated in the edge tables below: **tab root** (persistent stack, tab bar visible), **push** (child of a tab stack, tab bar visible, back button), **modal** (full-height, covers the tab bar, Cancel/Save, dismissible by swipe-down and system back), **sheet** (partial-height, tap-out to dismiss), **dialog** (centred, blocking, ≤2 actions).

| ID | Name | Kind | Purpose |
|---|---|---|---|
| `home` | Home | tab root | What this car needs next: due/overdue items, odometer strip, last fill-up. Specified in *Home*. |
| `vehicle.switcher` | Switch vehicle | sheet | Pick the active vehicle. Exists only with ≥2 vehicles. |
| `reminders.list` | Reminders | push | All service items for the active vehicle. Specified in *Home*. |
| `reminders.edit` | Reminder | modal | Create or edit one service item. Specified in *Home*. |
| `log.fillup` | Fill-up | modal | Log a fuel fill-up. Default segment of the log modal. |
| `log.service` | Service | modal | Log work done; satisfies one or more reminders. |
| `log.expense` | Expense | modal | Log a non-fuel, non-service cost: insurance, tax, parking, toll, fine, wash, accessory. |
| `log.odometer` | Odometer | modal | Reading + date. The fastest possible mileage update. |
| `history` | History | tab root | One reverse-chronological timeline of everything for the active vehicle, with inline filter chips. |
| `report.service` | Service report | push | Service history formatted for a buyer. Specified in *Fuel insights, costs and reports*. |
| `costs` | Costs | tab root | Running cost of ownership by category, with a business split and an All-vehicles toggle. |
| `costs.fuel` | Fuel & consumption | push | Consumption over time, price trend, best/worst tanks. |
| `trips.list` | Trips | push | Trips with distance, purpose and attached expenses. |
| `trips.edit` | Trip | modal | Create or edit a trip. |
| `settings` | Settings | tab root | Everything configurable, plus the front door to backup. |
| `vehicles` | Vehicles | push | The garage: list, reorder, add, delete. Management only — *not* where you switch cars. |
| `vehicle.edit` | Vehicle | modal | Create or edit a vehicle. Full-screen with no Cancel in `firstRun` mode. |
| `settings.language` | Language | push | Pick one of the six. In `firstRun` mode it is the app's first screen, with Continue instead of back. |
| `settings.units` | Units & formats | push | Units, currency and format preferences. |
| `settings.notifications` | Notifications | push | Lead times, quiet hours, per-category on/off, OS permission state. |
| `settings.backup` | Backup & restore | push | Export, import, app reset. First row in Settings, not last. |
| `settings.import` | Import | modal | What the chosen file contains — vehicles, entries, date span, export date — and one action: Replace. Blocking, because import is the only irreversible action in the app. |
| `settings.about` | About | push | Version, schema version, licences, the "no account, no server, no analytics" statement in plain words. |
| `dialog.discard` | Discard changes? | dialog | Guards dismissal of any dirty modal. Keep editing / Discard. |
| `dialog.confirmDelete` | Delete? | dialog | Guards every destructive action, naming what dies ("Delete Golf and its 412 entries?"). |
| `dialog.snooze` | Snooze | dialog | Push one reminder's notifications out by 3 days / 1 week / 1 month / after another 500 km (the distance option only when the item has a distance interval). |

**Not screens, deliberately.** OS file pickers, share sheets, date pickers and the notification-permission prompt are system UI; they are never wrapped in a screen of ours.

### What does not get a screen, and why

| Not built | Instead | Why |
|---|---|---|
| Entry detail (read-only) | history row opens `log.*` prefilled, edit mode | Six fields. A detail page you must tap "Edit" on is ceremony for zero information. |
| "Log type" picker screen | Segmented selector atop the log modal, default Fill-up | Fuel is logged 10× more than anything else; don't tax the common case. |
| Reminder-template catalogue | Untracked standard items below the tracked ones on `reminders.list`; tapping one opens `reminders.edit` prefilled | Kills an empty-form problem and a screen at once. |
| Onboarding carousel / tour | Nothing | Two screens, then the car. |
| Garage tab | `vehicles` under Settings, `vehicle.switcher` on Home | Most users have one vehicle forever. |
| Trip-expense form | `log.expense` with a `tripId` | A second form drifts out of sync with the first. |
| Cost-category breakdown screen | Filtered `history` instance in the Costs stack | Same rows, same widget, same edit path. |
| Search screen | Filter chips inline on `history` | Type + year beats free-text over a few thousand rows, and needs no keyboard. |
| Per-vehicle dashboard | `home` is the active vehicle's detail; `vehicle.edit` holds the facts | Two screens claiming to be "the car" confuses people. |
| Notification inbox / feed | The notification tray is the inbox | We don't own the user's attention twice. |
| Anything account-shaped | — | There is no account. |

### Tab bar

Four tab roots plus a docked central **+**: `home · history · [+] · costs · settings`.

- **Why four.** A centre-docked button needs an even tab count to sit symmetrically, so the choice is 2 or 4. Home, History and Costs are what the app produces; Settings is fourth because **Export lives in it**, and the person who needs Export is on a new phone, mildly panicking, and must find it without a tutorial. A gear in a header fails that test.
- **Why + is a button, not a tab.** A tab is a place you can be; logging is an act that finishes and returns you. As a modal it has one exit, always returns to the screen you left, behaves identically from all four tabs, and stays one tap away everywhere.
- The + sits in the bar's centre slot, not as a floating circle: an overlay covers the last row of every list, and in RTL it either mirrors into the wrong corner or looks bolted on.
- Labels always visible under icons. German and Sorani labels wrap or truncate; that is a typography problem for *Languages, RTL and formats*, not a reason to ship icon-only tabs.
- **Tab-root behaviour.** Each tab keeps its own stack across switches. Re-tapping the active tab pops to its root, then scrolls to top. Android back on a non-Home tab root goes to the Home tab; back on `home` exits. Deep-link-synthesised stacks obey the same rule.
- **All stacks reset to their roots** on exactly two events: switching the active vehicle, and an import.
- **RTL.** Tab order mirrors (Settings leftmost); the + stays centred; push animations and the back-swipe edge mirror. Nothing else changes — the stack model is direction-agnostic.

### Active vehicle

One app-wide `activeVehicleId`, persisted, restored on launch. It scopes `home`, `history` and `costs`, and prefills the vehicle field of every log form.

- **With one vehicle there is no switcher.** Home's title is the vehicle name as plain, non-tappable text — no chevron, no "1 of 1". The multi-vehicle feature is invisible until a second vehicle exists.
- **With two or more**, that title becomes a tappable control with a chevron opening `vehicle.switcher`: vehicles with their due-status dot, plus "Add vehicle" and "Manage vehicles".
- Selection happens **only** in `vehicle.switcher`, or implicitly via a notification deep link, which sets the vehicle from its payload before routing. `vehicles` under Settings is management; a row there opens `vehicle.edit` and never switches.
- **`costs` is the one exception to the scope**: an in-page **All vehicles** toggle for household running cost, affecting that tab only and never changing `activeVehicleId`.
- Deleting the active vehicle promotes the next one in list order. Deleting the last routes to `vehicle.edit` (firstRun).

### Navigation graph

Every edge in the app. "Dismiss" means swipe-down, Cancel or system back — all three are one event. Two rules hold everywhere and are not repeated per row: **dismissing a dirty modal opens `dialog.discard`; dismissing a clean one is silent**, and a modal that saves or cancels returns to the exact screen and scroll position it was opened from.

**Launch and first run.** This table is also the launch-state contract: every way the app can open is a row here.

| From | To | Trigger | Notes |
|---|---|---|---|
| launch, no prior run | `settings.language` (firstRun) | cold start | Preselects the device locale if it is one of the six, else English. Shown anyway: it is also the RTL decision, and a hand-me-down phone in the wrong language is a silent disaster. |
| `settings.language` (firstRun) | `vehicle.edit` (firstRun) | Continue | Sets language, direction, and that locale's default units/calendar/numerals. |
| `vehicle.edit` (firstRun) | `home` | Save | No Cancel, no back, no skip. Requires name + current odometer; the rest is optional. |
| either firstRun screen | OS document picker | text button **"Moving from another phone? Restore a backup"** — under Continue, and as a third row below Start | The restore path must exist before a vehicle does, or the user invents a fake car and then discovers Replace, which wipes it. Offered on the language screen too, since language is restored from the file anyway. |
| OS document picker (firstRun) | `settings.import`, empty-device variant | valid file | "Odova is empty, so nothing will be replaced"; primary button **Import**. |
| OS document picker (firstRun) | back to the firstRun screen | cancelled or file rejected | Nothing written. |
| `settings.import` (firstRun) | `home` | Import | Onboarding is skipped entirely: restored active vehicle and preferences; `onboarding_done` is set to true by the successful import, not read from the file. |
| launch, ≥1 vehicle | `home` | cold or warm start | Home tab, active vehicle restored, never the last-used tab — sessions are days apart and a three-week-old Costs tab is noise. Modal state is never restored. |
| launch, 0 vehicles, not first run | `vehicle.edit` (firstRun) | cold start, incl. post-reset | User deleted their last vehicle. Language is already chosen; do not ask again. |
| launch after an app update | `home` | cold start | Migrations run before the first frame; if one fails the app opens on `settings.backup` instead, with an explanatory banner and Export enabled, so the data can leave the building before anything else is attempted. |
| launch from a notification | see *Notification deep links* | — | |

**`home`**

| From → To | Trigger | Notes |
|---|---|---|
| `home` → `vehicle.switcher` | tap title (≥2 vehicles) | tap-out → no change |
| `home` → `reminders.edit` | tap a reminder card | |
| `home` → `log.service` | "Log it" on a due card | prefilled with that item, today, last known odometer; on Save the reminder re-anchors and the card recomputes |
| `home` → `dialog.snooze` | card overflow → Snooze | |
| `home` → `reminders.list` | "See all" | |
| `home` → `log.odometer` | tap the odometer strip | |
| `home` → `vehicle.edit` | "Add details" on a thin new vehicle | |

**`vehicle.switcher`**

| From → To | Trigger | Result |
|---|---|---|
| → `home` | tap a vehicle | sets `activeVehicleId`, dismisses, resets all four tab stacks |
| → `vehicle.edit` | "Add vehicle" | modal over the sheet; on Save the new vehicle becomes active and both dismiss |
| → `vehicles` | "Manage vehicles" | sheet dismisses, pushes into the **current** tab's stack |
| dismiss | tap-out / back | no change |

**Reminders** — fields, validation, states, and what deleting a reminder does to logged services are in *Home*.

| From → To | Trigger | Notes |
|---|---|---|
| `reminders.list` → `reminders.edit` | tap a tracked row | |
| `reminders.list` → `reminders.edit` | tap an untracked standard row | prefilled with that item's default intervals |
| `reminders.list` → `log.service` | row action "Done today" | |
| `reminders.edit` → `log.service` | "Mark as done" | stacked above; on Save both dismiss together and return to the original caller |
| `reminders.edit` → `dialog.confirmDelete` | Delete | confirm → modal dismisses to caller |
| `reminders.edit` → caller | Save | reschedules that item's notifications immediately |

**Log modal (`log.fillup` / `log.service` / `log.expense` / `log.odometer`)**

| From → To | Trigger | Behaviour |
|---|---|---|
| any screen → `log.fillup` | central **+** | Opens on the Fill-up segment. |
| `log.*` → `log.*` | tap another segment | Swaps the form body. Per-segment drafts live in memory for the life of the modal, so a mis-tap costs nothing. Drafts are **never** written to the database. |
| `log.*` → caller | Save | Snackbar with **Undo**. Undo is the only "are you sure" logging gets. |
| `log.*` → `dialog.discard` | dismiss while dirty | Discard drops every segment's draft, not just the visible one. |
| `log.*` (edit mode) → `dialog.confirmDelete` | Delete | Confirm dismisses the modal. |

In edit mode (opened from a row rather than from **+**) the segment selector is hidden — an entry cannot change type.

**`history`**

| From → To | Trigger | Notes |
|---|---|---|
| `history` → `log.*` | tap any entry row (the odometer-correction divider row is not tappable) | edit mode, the form matching the row's type |
| `history` → `report.service` | app bar "Service report" | back returns with filters and scroll intact |
| `report.service` → OS share sheet | Share / Export | system UI |
| `history` → filter state | filter chips | not navigation; filters persist per tab-stack instance and reset on tab-stack reset |
| `history` → `dialog.confirmDelete` | swipe **Delete** on any row, including an odometer-correction divider row | confirm deletes and shows an Undo snackbar; a correction delete re-runs the recompute contract |

**`costs`**

| From → To | Trigger | Notes |
|---|---|---|
| `costs` → `costs.fuel` | Fuel & consumption card | |
| `costs` → `trips.list` | Trips card | |
| `costs` → `history` (filtered) | tap a cost category row | pushed **inside the Costs stack**, type filter preset |
| `costs.fuel` → `log.fillup` | tap a fill-up row | edit mode |
| `trips.list` → `trips.edit` | tap row, or **+** | |
| `trips.edit` → `log.expense` | "Add expense" | stacked above, `tripId` prefilled and locked |
| `trips.edit` → `dialog.confirmDelete` | Delete | |

Cross-tab data jumps push a filtered instance into the **current** tab; the app never switches tabs under the user's finger. Two instances of `history` in two stacks is cheaper than a user who has lost their place.

**`settings`**

| From → To | Trigger | Notes |
|---|---|---|
| `settings` → `vehicles` | row | |
| `settings` → `settings.language` | row | Changing language re-renders in place, flips direction if needed, and keeps the whole navigation state. |
| `settings` → `settings.units` | row | |
| `settings` → `settings.notifications` | row | If OS permission is denied, the only action is a button opening the OS settings page for the app. |
| `settings` → `settings.backup` | row | First row in the list. |
| `settings` → `settings.about` | row | |
| `vehicles` → `vehicle.edit` | tap row, or **+** | |
| `vehicles` → `dialog.confirmDelete` | swipe/overflow Delete | Names the entry count that will be destroyed. |
| `settings.backup` → OS save/share sheet | Export | system UI |
| `settings.backup` → OS file picker → `settings.import` | Import | A cancelled picker returns to `settings.backup` with nothing changed. |
| `settings.import` → `home` | Confirm Replace | Dismisses, resets every tab stack, switches to the Home tab, reschedules all notifications, shows a snackbar with counts. |
| `settings.import` → `settings.backup` | Cancel / back | Nothing is written until Confirm. |
| `settings.backup` → `dialog.confirmDelete` | Reset app | Type-to-confirm; wipes everything and routes to `vehicle.edit` (firstRun). |

**Global dialogs**

| Dialog | Positive | Negative / dismiss |
|---|---|---|
| `dialog.discard` | Discard → parent modal dismisses, drafts dropped | Keep editing → back to the modal, focus restored |
| `dialog.confirmDelete` | Delete → performs it, snackbar with Undo where the delete is reversible | Cancel / tap-out → nothing happens |
| `dialog.snooze` | any of the four options listed in the screen table | tap-out → nothing happens |

Tap-outside and system back are always the *negative* action. No dialog is ever dismissed into a destructive outcome.

### Notification deep links

Routing reads three payload fields — `kind` (`reminder.due` / `reminder.overdue` / `reminder.grouped` / `odometer.nudge` / `keeper` / `backup.nudge`), `vehicleId`, and `reminderId` (absent for every kind except `reminder.due` and `reminder.overdue`). The payload itself is specified in *Reminders and notifications*.

| Notification | Interaction | Lands on | State |
|---|---|---|---|
| `reminder.due` / `reminder.overdue` | tap body | `home` | `activeVehicleId := payload.vehicleId`; Home tab selected; the target card scrolled into view and highlighted ~2s. No modal opens. |
| `reminder.due` / `reminder.overdue` | action **Done** | nowhere | Writes the estimated service record in the background (`odometer_estimated` and `cost_estimated` both true); the app is not launched. A confirmation strip is queued for the next appearance of `home`. |
| `reminder.due` / `reminder.overdue` | action **Snooze** | nowhere | Handled in the background; the app is not launched. |
| `reminder.grouped` | tap body | `home` | `activeVehicleId := payload.vehicleId` (the first vehicle named when several); Home tab; no card pinned. |
| `odometer.nudge` | tap body | `home` + `log.odometer` | `activeVehicleId := payload.vehicleId` first, then the modal, prefilled with the last reading and today. Never opens `vehicle.switcher`. |
| `keeper` | tap body | `home` | Active vehicle unchanged; the queue re-arms on launch. |
| `backup.nudge` | tap body | `settings.backup` | Active vehicle unchanged. Opens the Backup & restore screen with the Export button focused; the synthesised stack is `[home, settings, settings.backup]` so Back walks out through Settings. |

- A cold start from a notification **never** shows onboarding — a notification cannot exist unless a vehicle exists.
- The back stack under any deep link is synthesised as `[home]`. Back from a deep-linked modal lands on Home, never straight out of the app.
- A link naming a vehicle or reminder that no longer exists (deleted, or wiped by an import) lands on plain `home` for the current active vehicle and shows nothing — no error toast for something the user already dealt with.
- Tapping the body never opens a form, because a lock-screen tap is often exploratory and a prefilled form one thumb-slip from Save is a data-integrity hazard. **Done** exists for people who mean it, and it records without opening a form at all.

### After an import

Import lands on `home` with the file's active vehicle and every tab stack reset. If `active_vehicle_id` names no vehicle in the file, the first by `sort_order` becomes active. Preferences from the file **are** applied, including language and direction, so restoring onto a new phone restores the app you had — this is why the firstRun restore path can skip the language screen's outcome without losing it.

### One editor per thing

Duplicate paths are fine; duplicate *implementations* are not. The edges above give a fill-up three doors (`history` row, `costs.fuel` row, snackbar Undo), an expense two (**+**, `trips.edit` → Add expense), a reminder three (Home card, `reminders.list` row, notification tap) — but each opens the same single editor: `log.*` in edit mode, `reminders.edit`, or `vehicle.edit`. No screen may reimplement a form another screen owns. `report.service` is the one read-only view of data `history` owns; it never edits.

---

## 8. First run, the garage, and vehicles

Onboarding is two screens and **one field the user actually types**. Everything else is prefilled with an answer that is right most of the time and harmless when wrong. The facts we skip — make, model, plate, tank size, purchase price — are worth real money later, so we ask for them later, on the one screen where the user has already chosen to think about their car.

Two `Vehicle` fields carry the weight. `vehicle_type` decides the row icon, which fields appear at all, and — with `fuel_kind_default` and `is_business` — which reminder set is seeded; a motorbike has no cabin filter and no wipers, and offering them is how an app tells the user it does not know what a motorbike is. `is_business` answers "do you drive this for work?": it defaults `Trip.purpose` to `business` and turns on the business cost row on `costs`, shown when trips are logged in the range. Field definitions are in *Domain model and rules*; the seeded set and its intervals are in *Reminders and notifications*.

---

### `settings.language` — first-run mode

**Purpose.** Choose the UI language and, with it, the writing direction. Opened once per install, before anything else exists. It is screen one because the failure it prevents — a hand-me-down phone in a language its new owner cannot read — has no recovery path: every escape route is written in that language.

```
┌────────────────────────────────────┐
│                                    │
│          Odova                     │
│                                    │
│   System (English)             ✓   │
│   English                          │
│   Deutsch                          │
│   Français                         │
│   فارسی                            │
│   العربية                          │
│   کوردیی ناوەندی                   │
│                                    │
│           [    Continue    ]       │
│                                    │
│   Moving from another phone?       │
│   Restore a backup                 │
└────────────────────────────────────┘
```

**Layout.** Wordmark, seven rows, one button, one text link. No app-bar, no back, no skip, no explanatory paragraph. `System (English)` names in its parenthesis whatever `system` resolves to right now; when the device language is none of the six it is preselected, and one line sits beneath the list: **"Odova isn't translated into {deviceLanguage} yet. Numbers, dates, units and money will still follow your region."**

**Interactions.**

| Control | Behaviour |
|---|---|
| A language row | Sets `Settings.language` in memory and **re-renders the app from the root immediately**, this screen included. Choosing فارسی flips the layout, the checkmark and the button label before the finger lifts — the only proof of RTL support the user will ever need. |
| Continue | Commits `Settings`, pushes `vehicle.edit` (firstRun). Label in the selected language: Continue / Weiter / Continuer / ادامه / متابعة / بەردەوام بە. |
| Restore a backup | OS document picker, then `settings.import`. Offered here too because language is restored from the file anyway. |

**States.** Loaded only. Row order is fixed (system, en, de, fr, fa, ar, ckb) and never floats the device match to the top — a list that rearranges itself is disorienting for zero gain.

**Data out.** On Continue, one write:

```
Settings {
  language, calendar, numerals, first_day_of_week,
  distance_unit, volume_unit, consumption_unit, currency_default,
  theme: system, onboarding_done: false
}
```

Language comes from the tapped row; everything else from the device region, not the language (*Languages, RTL and formats*). `onboarding_done` stays false until a vehicle exists, so a kill between the two screens replays from here.

**Navigation.** In: cold start, no prior run. Out: `vehicle.edit` (firstRun); `settings.import` via Restore a backup. No back edge; Android system back exits the app.

**RTL and l10n.** Language names are always in their own script and never translated — a user looking for their language cannot read the current one. Rows start-aligned, checkmark on the end edge. The button sizes to content and wraps to two lines; "بەردەوام بە" and "Weiter" have very different widths and neither may shrink.

---

### `vehicle.edit` — first-run mode

**Purpose.** One vehicle and one odometer reading into the database in under thirty seconds. Opened once per install, and again only if the user deletes their last vehicle. Highest drop-off screen in the app; every field is a tax.

```
┌────────────────────────────────────┐
│  Your vehicle                      │   no back · no Cancel · no Skip
├────────────────────────────────────┤
│    ┌─────┐  ┌─────┐  ┌─────┐       │
│    │ car │  │ moto│  │ van │       │
│    └─────┘  └─────┘  └─────┘       │
│     ▔▔▔▔▔                          │
│                                    │
│  Name                              │
│  ┌──────────────────────────────┐  │
│  │ My car                       │  │  prefilled, pre-selected
│  └──────────────────────────────┘  │
│                                    │
│  Fuel                              │
│  [ Petrol ][ Diesel ][ Electric ]  │
│  [ More… ]                         │
│                                    │
│  Odometer now                      │
│  ┌────────────────────┬─────────┐  │
│  │ 187412             │  km  ▾  │  │  ← the only thing they must type
│  └────────────────────┴─────────┘  │
│  Read it off the dash.             │
│                                    │
│  About how far a year?             │
│  [<10k][10–20k][20–30k][30k+]      │
│         ▔▔▔▔▔▔▔                    │
│                                    │
│  Do you drive this for work?  ( ○) │
│                                    │
│           [      Start      ]      │
│                                    │
│  Moving from another phone?        │
│  Restore a backup                  │
└────────────────────────────────────┘
```

| Field | Control | Prefilled with |
|---|---|---|
| `vehicle_type` | 3 icon tiles + "Other" in the overflow | `car` |
| `name` | text, pre-selected so typing replaces it | "My car" / "My motorbike" / "My van", following the type tile |
| `fuel_kind_default` | 3 chips + **More…** (LPG, CNG, Hybrid, Other) | `petrol` |
| `odometer_m` | numeric keypad + unit chip | empty — the whole tax, about six digits |
| `expected_annual_m` | 4 bands | 10–20k |
| `is_business` | switch | off; **on** when type = van |

Six controls, one required entry, nine interactions on a realistic path. Everything else in `Vehicle` is nullable and asked later.

The odometer is required because every projection hangs off the series: with no readings every reminder is `unknown`, and day one is a home screen full of dashes. It is also the one number every driver can read without leaving the car. The annual band is what the projection falls back on until there is enough history to measure — without it a delivery driver and a pensioner get the same guess — and four preselected bands buy `confidence = assumed` instead of `default`. We do not ask "when was the last oil change?": the most valuable question available and the most likely to end the session. Seeded items carry an assumed anchor until a service record or a baseline lands (*Reminders and notifications*).

**States.**

| State | Behaviour |
|---|---|
| Loaded (the only entry state) | As drawn. Focus is **not** auto-placed in the odometer field — a keyboard over two thirds of the screen reads as a form to fill, not a question to answer. |
| Save disabled | Until the odometer parses to a positive integer; visibly disabled, and tapping it flashes the odometer hint. The deliberate exception to "Save is never disabled", which scopes to the four `log.*` segments: one required field, hint always visible. |
| Invalid odometer | Inline under the field. Empty on Save: **"Enter the number on your dash."** Unparseable: **"That doesn't look like a number. Digits only."** Zero: allowed — new cars exist. Above 3,000,000 km: **"That's higher than any car has driven. Check the number."** — a warning with a "Use it anyway" affordance, never a block. |
| Backgrounded mid-entry | Form state survives in memory; nothing is written. A cold kill loses it and replays this screen — six digits is an acceptable loss, a draft row for a vehicle that does not exist is not. |
| Error | Only a disk write can fail: **"Couldn't save. Your phone may be out of space."** with Retry. The screen never advances. |

**Data out — one transaction on Save.**

```
INSERT Vehicle { vehicle_type, name, fuel_kind_default, is_business,
                 expected_annual_m, status: active, sort_order: 0 }
INSERT OdometerReading { vehicle_id, occurred_on: today,
                         odometer_m, odometer_unit, source: manual }
INSERT ServiceItem × n           # the seeded set, per Reminders
UPDATE Settings { active_vehicle_id, onboarding_done: true }
```

All or nothing: a crash between the vehicle row and the reading row leaves a vehicle with no odometer, which the domain contract forbids. The unit chip writes `Settings.distance_unit` rather than a per-vehicle override — with exactly one vehicle, a global is the honest place for it. In normal add-vehicle mode the same control writes `Vehicle.distance_unit`, and only when it differs from the global.

**Restore a backup.** A text button below Start, because the second-most-likely reason a stranger is on this screen is a new phone — without it, restoring eight years would mean inventing a fake vehicle and then wiping it. It opens the OS document picker; on a valid file, `settings.import` in its empty-device variant ("Odova is empty, so nothing will be replaced", primary button **Import**). On confirm it dismisses to `home` with the restored active vehicle and `onboarding_done` set to true by the successful import, not read from the file; on cancel it returns here with nothing written.

**Navigation.** In: `settings.language` (firstRun) via Continue; cold start with zero vehicles; deleting the last vehicle. Out: `home`, only via Start; `settings.import` via Restore a backup. No Cancel, no back, no swipe-to-dismiss, and Android system back is swallowed — a modal you can dismiss into an app with no data is a bug with a nice animation.

**RTL and l10n.** The type tiles mirror; the silhouettes inside them never do. The odometer keeps its unit affix on the **end** edge in both directions, and number plus unit is one atomic run — `۱۸۷٬۴۱۲ کیلومتر` never splits. The field accepts every numbering system the app supports and normalises on blur. German is the long case: "Ungefähre Jahresfahrleistung" and "Fahren Sie damit beruflich?" sit above their controls and wrap to two lines; band chips carry a `maxChars` budget and read "<10 Tsd." rather than truncating.

---

### `vehicle.edit` — normal mode

**Purpose.** Every fact about one vehicle. Opened rarely — once shortly after first run, then on a plate change or a sale.

```
┌ ✕  Van                        Save ┐
│  ┌────┐                            │
│  │ 🚐 │  ◯ ◯ ◉ ◯ ◯ ◯ ◯ ◯ ◯ ◯      │  type icon + colour swatches
│  └────┘                            │
│  Name        [ Van              ]  │
│  Type        [car][moto][van][…]   │
│  Fuel        [ Diesel        ▾ ]   │
│  Make        [ Ford             ]  │
│  Model       [ Transit Custom   ]  │
│  Year        [ 2019             ]  │
│  Plate       [ B-ZJ 4471        ]  │
│  VIN         [ WF0YXXTTGYKR…    ]  │
│  ──────────────────────────────    │
│  Odometer    92,050 km  ·  3 d ago │  ← read-only, opens log.odometer
│  ──────────────────────────────    │
│  ▸ Purchase and sale               │
│  ▸ This vehicle's units & currency │
│  ──────────────────────────────    │
│  Mark as sold                      │
│  Delete vehicle                    │  destructive
└────────────────────────────────────┘
```

**Odometer is read-only here.** In create mode it is an input; in edit mode a row showing the latest reading and its age, tapping into `log.odometer`. A facts form is the wrong place to write a dated reading — someone correcting the plate would stamp today's date on a number they last checked in March, and that corrupts the series the whole app depends on.

Controls that need no explanation: `name` (text, required), `vehicle_type` (segmented), `fuel_kind_default` (dropdown), `make`, `model`, `notes` (multiline, content-direction), `colour` (10 swatches — white, silver, grey, black, red, blue, green, yellow, brown, other), `expected_annual_m` (4 bands), `is_business` (switch), `notifications_muted` (switch, "Mute reminders for this vehicle"), `purchase_date` (calendar picker, ≤ today), `purchase_price` (money + currency), and `status`/`sold_on`/`sold_price` via **Mark as sold**. Under **Units & currency**, six overrides — `currency`, `distance_unit`, `volume_unit`, `consumption_unit`, `notice_distance_m`, `notice_days` — each with an **Automatic** option that writes null. The rest carry text:

| Field | Control | What the screen says |
|---|---|---|
| `name` | text | duplicates allowed, with the note "You already have a vehicle called Van" |
| `year` | numeric | out of range → **"Enter a year between 1900 and 2027."** |
| `plate` | text, forced LTR | stored verbatim, never digit-shaped, never uppercased |
| `vin` | text, forced LTR, mono | length ≠ 17 → **"A VIN is usually 17 characters."**, never a block |
| `tank_capacity_ml` | numeric + unit | its only consumer is the over-tank volume warning; null disables it |
| `purchase_odometer_m` | numeric | above the earliest reading → **"Your earliest logged reading is 92,050 km, which is lower. Distance since purchase will show as —."** |

`purchase_odometer_m` does **not** emit an `OdometerReading` — it is a vehicle fact, not an observation. Distance since purchase is `max cumulative − purchase_odometer_m`, which needs no reading.

**Changing `currency`** shows a permanent inline line under the control: **"Only new entries use this. Nothing already saved changes."** No rate is applied, ever.

**Changing `vehicle_type` or `fuel_kind_default`** never touches existing `ServiceItem` rows; a one-time snackbar offers it — **"Switched to Diesel. Add diesel reminders?"** → `reminders.list`. Silently deleting someone's spark-plug history because they fixed a typo is not a trade we make.

**Where the skipped facts get asked.** Make, model and year: Home's dismissible **"Add details"** card, shown when `make` is null and the vehicle is at least three days old, returning once after 30 days and then never. Purchase date and odometer: the `report.service` header row **"Ownership: not set — add it"**, because a service report is the moment an ownership span is worth something. Tank capacity, plate and VIN are never asked proactively — nagging for a field that enables one warning is worse than the missing warning.

**Navigation.** In: `vehicles` row or **+**; `vehicle.switcher` → Add vehicle; Home's "Add details". Out: caller on Save or clean dismiss; `dialog.discard` when dirty; `dialog.confirmDelete`; `log.odometer` from the odometer row. Add-from-switcher is the special case: on Save the new vehicle becomes active, modal and sheet both dismiss, all four tab stacks reset.

**RTL and l10n.** Plate and VIN are forced LTR and start-aligned inside their own fields even on an RTL screen, and are never digit-shaped — a plate is a string, not a number. `name` and `notes` take direction from their content, so "The Golf" reads LTR inside a Persian form. German labels ("Kilometerstand", "Voraussichtliche Jahresfahrleistung", "Als verkauft markieren") sit above their controls and wrap; nothing auto-shrinks except large numeric readouts.

---

### `vehicles` — the garage

**Purpose.** Manage the garage: add, rename, reorder, sell, delete. **Not** where you switch cars. Opened a handful of times ever.

```
┌ ←  Vehicles                     +  ┐
│                                    │
│  ┌────┐  The Golf              ●   │
│  │ 🚗 │  VW Golf VII · 2016        │
│  └────┘  ~187,400 km · oil due     │
│  ┌────┐  Van                   ●   │
│  │ 🚐 │  Ford Transit · 2019       │
│  └────┘  92,050 km · all good      │
│                                    │
│  ── Sold and archived (1) ──────   │
│  ┌────┐  Yamaha MT-07              │
│  │ 🏍 │  Sold 12 March 2024        │
│  └────┘  1,204 entries kept        │
└────────────────────────────────────┘
```

The name wins the eye; the avatar — a silhouette from `vehicle_type` on the vehicle's colour — anchors the row; the status dot sits on the end edge. Odometer and one-line status share the third line because that is the pair people scan for. The active vehicle gets no mark: marking it here invites the tap this screen refuses to honour.

**Status dot.** Colour is never the only signal; the third line always spells it out.

| `dueSummary` | Dot | Third line |
|---|---|---|
| any `overdue` | filled red | "Oil and filter overdue" |
| any `due` / `due_soon` | filled amber | "Oil due in 3 days" |
| all `ok` | small grey | "All good" |
| any `needs_odometer` | hollow ring | "Odometer needs updating" |
| all `unknown` / no items | hollow ring | "No reminders yet" |

**States.**

| State | Behaviour |
|---|---|
| Empty | **Unreachable.** You cannot arrive without a vehicle, and deleting the last one routes straight to `vehicle.edit` (firstRun). No empty state is designed, deliberately. |
| One vehicle | No drag handles, no section header. The delete row reads "Delete The Golf" and its dialog carries the extra line **"This is your only vehicle. Deleting it starts Odova over."** |
| Loaded, 2–6 | As drawn. Long-press to drag, writing `sort_order`. |
| Many (tested to 50) | No cap; a plain scroller. "Sold and archived" collapses to a header with a count above five. |
| Stale estimate | Latest reading over 60 days old: `~187,400 km` in the estimate treatment, rounded to the nearest 100 km / 50 mi, third line "Odometer last updated 4 months ago". |
| Expired estimate | Past 180 days Odova stops guessing: the entered figure and its date, `187,412 km · last entered 12 Jul 2025`, no approximation marker, hollow dot, and every distance axis on that vehicle reporting `needs_odometer`. |
| Error | None. If a derived summary throws, the row still renders with a hollow dot and "Couldn't work out what's due" — the row never disappears. |

**Interactions.**

| Control | Result |
|---|---|
| Tap a row | `vehicle.edit`, edit mode. **Never switches the active vehicle.** |
| **+** in the app bar | `vehicle.edit`, create mode. On Save the vehicle is appended, does **not** become active, and a snackbar offers **Switch to it**. |
| Long-press drag | Reorders, writes `sort_order`. Sold and archived sort to the bottom regardless. |
| Swipe (end actions) | **Mark as sold** (amber), **Delete** (red). Declared as `endActions`; the physical direction flips in RTL. |
| Row overflow | Edit · Mark as sold · Archive · Delete |

**Sold and archived.** `sold` means gone; `archived` means off the road — stored, SORN, winter bike. A sold vehicle computes no reminders and its card shows `—`; an archived one still computes them and shows them in-app. Neither ever notifies, odometer nudges included, and neither is counted in the Costs all-vehicles view unless the user turns on **Include sold and archived** there. Both still accept new entries — late invoices arrive — and both are exported in full. An archived vehicle can be active; a sold one only by explicit selection, and Home then shows a banner.

**Mark as sold** opens a small form: sale date (default today, ≤ today) and sale price (optional). It is offered before Delete everywhere, because "I sold the car" is what people mean most of the time they reach for Delete, and the history they are about to destroy is what made the sale worth more.

**Delete.** Immediate and permanent, through `dialog.confirmDelete`.

> **Delete The Golf and its 412 entries?**
> 96 fill-ups, 14 services, 22 costs, 8 trips and 16 reminders will be removed permanently.
>
> `[ Keep it — mark it sold ]`
> `[ Cancel ]`  `[ Delete ]`

- **Zero entries:** one-tap Delete, then the Undo snackbar.
- **One or more entries:** a type-the-name field appears — *"Type The Golf to confirm."*, mismatch reads *"That doesn't match The Golf."* Delete stays disabled until it matches.
- On confirm the rows go and a snackbar offers Undo for 10 seconds — longer than the usual 6 because this destroys more than one row. Deleting a vehicle writes no safety copy (there are three kinds only — migration, import, wipe: *Backup, export and import* §4.4); after the snackbar expires the recovery path is the user's own exported backup.
- Deleting the **active** vehicle promotes the next live vehicle in `sort_order` and resets all four tab stacks.
- Deleting the **last** vehicle routes to `vehicle.edit` (firstRun) with the Undo snackbar above the modal; Undo restores everything and returns to `vehicles`.

**Data in.** `Vehicle`, `dueSummary(vehicle)`, `estimateOdometer(vehicle, today)`, entry counts per type for the delete dialog. **Data out.** `sort_order` on drag; `status`/`sold_on`/`sold_price` on sell or archive; row deletion.

**Navigation.** In: `settings` row; `vehicle.switcher` → Manage vehicles, which pushes into the **current** tab's stack rather than jumping to Settings. Out: `vehicle.edit`, `dialog.confirmDelete`, `vehicle.edit` (firstRun) on last-vehicle deletion.

**RTL and l10n.** Rows mirror; silhouettes and the "+" never mirror. Swipe actions are `startActions`/`endActions`. Odometer and unit are one atomic run at the end of the third line; the approximation marker is `~` in every locale (*Reminders and notifications* §1.4) and sits inside that run. Entry counts need an explicit `=0` plural case. German rows ("Als verkauft markieren", "Fahrzeug löschen") wrap rather than truncate.

---

### `vehicle.switcher`

**Purpose.** Change the active vehicle. **Does not exist below two vehicles** — with one car, Home's title is plain, non-tappable text with no chevron and no "1 of 1". Opened daily by a two-car household, never by anyone else.

```
╭──────────────────────────────────────╮
│  Switch vehicle                      │
│  ┌────┐ The Golf      ~187,400 km  ✓ │
│  │ 🚗 │ ● Oil and filter due in 3 d  │
│  ┌────┐ Van             92,050 km    │
│  │ 🚐 │ ● All good                   │
│  ────────────────────────────────    │
│  ▸ Sold and archived (1)             │
│  ────────────────────────────────    │
│  +  Add vehicle                      │
│  ⚙  Manage vehicles                  │
╰──────────────────────────────────────╯
```

**Layout.** Partial-height sheet, tap-out to dismiss. Live vehicles in `sort_order`, silhouettes from `vehicle_type`, the active one marked with a checkmark on the end edge and nothing else. Sold and archived sit behind a collapsed disclosure — reachable, out of the way. Two footer actions, always visible. Each vehicle's odometer renders in that vehicle's own `distance_unit`, not the active one's.

**States.** Never empty. Above eight vehicles the list scrolls and the footer actions pin to the bottom. Stale and expired odometers use the `vehicles` treatment.

**Interactions.**

| Control | Result |
|---|---|
| Tap a vehicle | Sets `Settings.active_vehicle_id`, dismisses, **resets all four tab stacks to their roots**. `history` filters and the Costs range reset with them. |
| Add vehicle | `vehicle.edit` (create) stacked over the sheet. On Save the new vehicle becomes active and both dismiss. |
| Manage vehicles | Dismisses, pushes `vehicles` into the current tab's stack. |
| Tap-out / back | Nothing changes. |

**Data in.** `Vehicle.name`, `colour`, `vehicle_type`, `status`; `dueSummary`; `estimateOdometer`. **Data out.** `Settings.active_vehicle_id` only.

**Navigation.** In: `home` title tap and Home's other-vehicles row, and nothing else — a notification deep link switches the vehicle from its own payload and opens its target screen directly. Out: `home`, `vehicle.edit`, `vehicles`.

**RTL and l10n.** Sheet content mirrors; the checkmark and the "+" never mirror. Vehicle names take content direction. "Fahrzeuge verwalten" and "Add vehicle" both wrap rather than truncate.

---

## 9. Home — what does my car need next

### `home`

**Purpose.** Answer "what does this car need next?" at a glance and let the user act in one tap. The most-opened screen in the app: 2–6 opens a month, ~70% of which never leave it. One hard layout rule — **the answer is above the fold, always**: on the floor screen (375 × 667 pt, default text scale) the primary card and both secondary cards are fully visible without scrolling.

#### Anatomy

```
┌────────────────────────────────────────────┐  56pt app bar
│  Der Golf  ⌄                               │  title = vehicle name
├────────────────────────────────────────────┤
│ ⓘ Odometer last updated 68 days ago.    ✕  │  conditional strip (0–2)
│   [ 187412        ] km   [ Save ]          │  inline number pad
├────────────────────────────────────────────┤
│  ~187,400 km        last entered 12 Sept ›  │  odometer strip, 64pt
├────────────────────────────────────────────┤
│  ●  Oil and filter                         │
│     Overdue by 1,400 km                    │  PRIMARY CARD, 148pt
│     Was due at 186,000 km · 12 August      │  wins the eye
│     ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░                │  progress line
│     [ Log it ]                          ⋯  │
├────────────────────────────────────────────┤
│  ●  Inspection             in about 3 weeks │  secondary card, 72pt
│  ●  Front brake pads    in about 5,000 km › │  secondary card, 72pt
├────────────────────────────────────────────┤
│  See all reminders (14)                   › │  48pt
├────────────────────────────────────────────┤
│  6.4         0.142 €        218 €          │  at-a-glance, 3 tiles
│  L/100 km    per km         per month      │  96pt, non-interactive
├────────────────────────────────────────────┤
│  Last fill-up   3 Sept · 42.18 L · 74.20 € │  56pt
├────────────────────────────────────────────┤
│  Van · 1 overdue                          › │  only if another vehicle
└────────────────────────────────────────────┘  needs attention
   home    history    (+)    costs   settings
```

Budget on 375 × 667: 56 + 64 + 148 + 2 × 72 + 48 = 460, leaving the first tile row visible under a 56pt tab bar. A conditional strip pushes the tiles below the fold, never the cards — **strips are capped at two, and the primary card is never displaced.**

| Zone | Rule |
|---|---|
| App bar | Vehicle name. Chevron and tap target only when ≥ 2 vehicles exist; otherwise plain text — the garage is invisible until it is real. No overflow menu, no gear. |
| Conditional strips | Max 2, priority: (1) done-from-notification confirmation, (2) away digest, (3) stale odometer. Overflow queues to the next appearance. |
| Odometer strip | Current odometer and how fresh it is, full-width tappable. Above the cards: it is the most valuable thing a user can give the app. |
| Due stack | 1 primary + up to 2 secondary. Never more. |
| See-all row | `See all reminders (14)` — all tracked items, not just due ones. Present whenever the vehicle has ≥ 1 tracked item. |
| Other-vehicles row | One line, only when another vehicle has a `due` or `overdue` item; opens `vehicle.switcher`. Home shows *whose* problem it is, not *what* it is. |

#### The card

Primary and secondary are the same widget at two densities.

```
Primary                             Secondary
● status dot (12pt)                 ● status dot (8pt)
Title  17pt semibold                Title  15pt medium
Status line  15pt, status colour    Status line  13pt, end-aligned
Anchor line  13pt secondary         —
Progress line 2pt                   —
[ Log it ]                    ⋯     chevron ›
```

Status is carried by **three** signals — dot shape, colour, wording — never colour alone. Dot shape is normative.

| `status` | Dot | Colour | Status line | Anchor line |
|---|---|---|---|---|
| `overdue`, distance drove it | filled ● | red | `Overdue by 1,400 km` | `Was due at 186,000 km` |
| `overdue`, time drove it | filled ● | red | `Overdue by 3 weeks` | `Was due 12 August` |
| `overdue`, both | filled ● | red | `Overdue by 1,400 km and 3 weeks` | both |
| `due` | ring ◉ | amber | `Due now` | `At 192,000 km · 10 October` |
| `due_soon`, time | small ● | blue | `In about 3 weeks` | `10 October` |
| `due_soon`, distance | small ● | blue | `In about 5,000 km` (only at `measured` or `assumed`; at `default`, `Odova needs a reading to say when`) | `around 22 October`, only at `confidence = measured` |
| `needs_odometer` | hollow ◌ | slate | `Needs an odometer reading` | `Last entered 12 July`; button is **Update odometer**, not Log it |
| `unknown` | — | grey | collapses into one card (below) | — |
| `ok`, `paused` | — | — | **not on Home at all** | — |

Which axis drove the status comes from `DueState`. Overdue uses its own positive string, never "in −21 days"; distance phrasing wins when both axes are overdue, because a kilometre figure is checkable against the dash and a date is not. A snoozed item stays on Home, stays red, and gains a fourth line, `Snoozed until 12 October`.

#### The unknown-anchor card — why a used car does not open on a wall of red

When `resolveAnchor` falls back to `purchase_date` or the earliest reading, a 2019 car entered today shows eleven seeded items instantly `overdue`. **Home renders any item anchored on the `purchase` or `first_reading` rung as `unknown`, whatever the due engine returns** — presentation only; the engine is untouched. Those items leave the sort and collapse into one card at the foot of the stack:

```
┌────────────────────────────────────────────┐
│  When were these last done?                │
│  Oil and filter · Air filter · Inspection  │
│  Telling me turns them into reminders.     │
│  + 6 more                                › │
└────────────────────────────────────────────┘
```

Only tracked items appear; untracked catalogue rows live on `reminders.list`. The card opens `reminders.list`, a named item opens `reminders.edit`. An app that shouts "OVERDUE" eleven times on day one gets its notifications turned off on day two.

#### Marking an estimate as an estimate

| Value | Treatment |
|---|---|
| Entered odometer | `187,412 km`, primary colour, normal weight |
| Projected odometer, while `estimateOdometer` is still projecting (last entered reading under 180 days old) | `~187,400 km`, secondary colour, rounded to 100 km / 50 mi. The `~` sits inside the isolated numeric run so it hugs the number in both directions. |
| Expired estimate — `estimateOdometer` has stopped projecting | No `~`, no projection: `187,412 km · last entered 12 Jul 2025`. Ten thousand kilometres of invented number is worse than a blank. |
| Date from the time axis (`due_on`) | Exact and plain: `10 October`. Calendar arithmetic, not a guess. |
| Date from the distance axis, `confidence = measured` | Fuzzy, secondary: `around 22 October`; `around mid-October` beyond 8 weeks |
| Date from the distance axis, `confidence = assumed` | Fuzzy month only: `around mid-October`, with the distance as `~5,000 km` |
| Date from the distance axis, `confidence = default` | **No date and no figure.** The card reads `Odova needs a reading to say when` and its action is **Update odometer** |
| Not computable | `—`, tappable |

Tapping an estimated value or a `—` opens a transient popover anchored to it — one sentence, one action:

- `Estimated from about 41 km a day since 12 July.` → **Update odometer**
- `Your last reading is too old, so Odova has stopped guessing. Enter what the dash says now.` → **Update odometer**
- `Your first consumption figure arrives at your next full fill-up.` → dismissal only.

No percentage, no bar, no tier name: the tilde and the word "about" are the whole vocabulary. Every estimated value carries the accessibility label `about 187,400 kilometres, estimated`, and the `~` is part of the visible string — the distinction must survive colour and weight being stripped out, and the secondary treatment still meets 4.5:1.

#### Ordering

1. Sort by `projected_due_date` ascending. Overdue items have past dates and float without a special case; that is the point of a single sort key.
2. `needs_odometer` sorts by its own projected date but never takes the primary slot while a `due` or `overdue` time-driven item exists — an accusation the app can support beats one it cannot.
3. `unknown` items collapse into the card above, always last.
4. Ties break by severity, then `label` under the locale collator.
5. A deep-linked item is pinned to the primary slot for that one appearance of Home.

#### Every state

**Nothing due** — the most common state, and the one most apps waste.

```
┌────────────────────────────────────────────┐
│  Der Golf  ⌄                               │
├────────────────────────────────────────────┤
│  187,412 km             entered 12 Sept  › │
├────────────────────────────────────────────┤
│  ✓  Nothing due                            │
│     Next: Inspection, 14 March             │
│     in about 5 months                      │
│                                            │
│     Since the last oil change:             │
│     3,120 km · 4 months                    │
├────────────────────────────────────────────┤
│  See all reminders (14)                  › │
├────────────────────────────────────────────┤
│  6.4         0.142 €        218 €          │
│  L/100 km    per km         per month      │
├────────────────────────────────────────────┤
│  Last fill-up   3 Sept · 42.18 L · 74.20 € │
└────────────────────────────────────────────┘
```

The all-clear card is a primary card's height and carries the next item with its date, plus a since-last-service line (distance and time since the most recent `ServiceRecord`, whatever it was). It saves enough height to pull the tiles above the fold: whoever finds nothing due should still leave knowing what the car costs and what it drinks. With service history but no fill-ups, the consumption tile shows `—` and the reward line is the service one alone.

**First run / no history.** Odometer strip (entered, not projected), the unknown-anchor card in the primary slot reading `Set up your reminders — tell me when things were last done`, the see-all row, tiles showing `—`. No fake numbers, no zeroes. Below the tiles one line, `Log a fill-up and your consumption starts here.` — a statement, not a button, because the **+** is already one tap away.

**One item.** One primary card, no secondaries, see-all row still present (item count, not due count). No layout special-casing.

**Hundreds of items.** Hard-capped at three cards however many are overdue; past three the see-all row becomes a red count, `See all — 9 more due or overdue ›`. Nine red cards say less than three plus a number.

**Stale odometer.** Strip reads `~187,400 km` with `last entered 68 days ago`, or the expired treatment above once projection has stopped. The conditional strip appears when `stale_days ≥ 60`, or `stale_days ≥ 30` **and** projected drift exceeds 500 km / 300 mi. It carries a number field, a unit label and **Save**, writing an `OdometerReading` without leaving Home; `✕` hides it for 7 days on that vehicle. Distance-driven items that would read `due`/`overdue` render as `needs_odometer`; `due_soon` still shows normally.

**Done-from-notification confirmation.** Highest-priority strip, not dismissible, appears once:

```
⓵ You marked Oil and filter done on 12 September.
   I recorded ~187,400 km and no cost.
   Next due at 202,400 km · 12 September 2026.
   [ Add the real numbers ]   [ That's right ]
```

**Add the real numbers** opens `log.service` in edit mode on that record; **That's right** clears `odometer_estimated` and `cost_estimated`.

**Away digest.** One dismissible card, at most three lines: `Oil and filter went overdue on 12 August`, `Inspection is due 14 March`. Shown once per absence when notifications are off or denied and the app has not been opened for 7+ days — and also, regardless of permission state, on the first launch after an absence longer than the notification horizon, because then the queue ran dry and the user genuinely was not told.

**Archived or sold vehicle active.** The due stack is replaced entirely; History and Costs stay fully available, no reminders, no notifications, no nudges.

```
This vehicle is marked sold (14 June).
Owned 6 years 2 months · 132,900 km driven
Total spent  8,412 €
```

**Error.** If the store cannot be read, Home renders no cards and one full-width message, `Odova can't read your data.`, with one button, **Open Backup & restore** → `settings.backup`: get the data out of the building before anything else. A single item whose derived state throws renders as a grey card, `Something's wrong with this reminder`, with a chevron to `reminders.edit` — one bad row never blanks the screen.

#### Interactions

| Control | Action |
|---|---|
| Title, ≥ 2 vehicles | Opens `vehicle.switcher` |
| Title, 1 vehicle | Nothing. Not a tap target. |
| Odometer strip | Opens `log.odometer`, prefilled with the last reading and today |
| Strip **Save** | Writes `OdometerReading{source: manual}`, validates monotonicity, snackbar with **Undo**. On a violation the strip yields to the full `log.odometer` modal, which owns the typo/correction/backdate dialogue. |
| Strip **✕** | Hides for 7 days, this vehicle |
| Card body | Opens `reminders.edit` for that item |
| **Log it** | Opens `log.service` prefilled with this item, today, last known odometer. On save the reminder re-anchors and the card recomputes in place. |
| **Update odometer** | Opens `log.odometer` |
| Card **⋯** | **Log it** · **Snooze** (→ `dialog.snooze`) · **Edit reminder** (→ `reminders.edit`) · **Turn this off** (`is_active = false`, snackbar with **Undo**) |
| Estimated value or `—` | Anchored popover, one sentence, one action |
| See-all row | Pushes `reminders.list` |
| Tile with a value | Nothing. Costs is one tap away and the app never switches tabs under the user's finger. |
| Tile showing `—` | Popover explaining why |
| Last fill-up row | Nothing (read-out) |
| Other-vehicles row | Opens `vehicle.switcher` |
| Pull to refresh | Not implemented. No network; recompute is automatic. |
| Re-tap Home tab | Scrolls to top |

Every control here, the card `⋯` and the strip `✕` included, has a 48 × 48 dp minimum target.

**Recompute triggers:** screen focus, any write to the active vehicle, vehicle switch, local midnight crossing, app resume, locale/unit/calendar change, import commit. The model is one pure build over the vehicle's rows, memoised and invalidated by any write; budget under 16 ms for 2,000 rows on the floor device. A skeleton appears only past 150 ms, to avoid a flash on the common path.

#### Data in / data out

Reads: `Settings` (`active_vehicle_id`, language, calendar, numerals, units, `currency_default`, notification permission state) · `Vehicle` (`name`, `vehicle_type`, `status`, `sold_on`, `purchase_date`, `purchase_odometer_m`, unit and currency overrides, `colour`) · `ServiceItem` (`is_tracked = true` and `is_active = true`) · `ServiceRecord` + lines · `OdometerReading` + `OdometerCorrection` · `FillUp` (latest, plus segments) · `Expense`.

Derived at read time: `estimateOdometer`, `dailyDistance`, `resolveAnchor`, `computeDueState`, `projectDueDate`, `nextDue`, `dueSummary`, `averageConsumption`, `costPerDistance`, `monthlyCost`, `unitPrice`.

Writes: `OdometerReading` (strip Save) · `ServiceItem.is_active` · `ServiceItem` snooze fields (via `dialog.snooze`) · `ServiceRecord.odometer_estimated` and `cost_estimated` cleared (confirmation strip) · `Settings.active_vehicle_id` (via the switcher). Nothing derived is persisted.

Local UI state — `home.staleness_dismissed_until.<vehicle_id>`, `home.digest_shown_at`, `home.first_run_hint_dismissed` — lives in a key-value store that is **not** in the backup file. A restore should bring back the car's history, not the fact that someone dismissed a banner in 2024.

#### Navigation edges

Reaches: `vehicle.switcher` (sheet) · `reminders.list` (push) · `reminders.edit` (modal) · `log.service` (modal) · `log.odometer` (modal) · `vehicle.edit` (modal, "Add details") · `dialog.snooze` · `settings.backup` (error state only).

Reached by: app launch (always the Home tab) · every tab-stack reset · `vehicle.switcher` selection · `settings.import` confirm · notification deep links · Save/Cancel of any modal opened from Home.

**From a notification.** A `reminder.due` / `reminder.overdue` body tap sets `active_vehicle_id` from the payload, selects the Home tab, pins the target card to the primary slot and tints it for ~2 s. No modal opens: a lock-screen tap is often exploratory, and a prefilled form one thumb-slip from Save is a data hazard — the notification's **Done** action is there for people who mean it, and it writes the estimated record without launching the app (the confirmation strip above then reports what it recorded). An `odometer.nudge` body tap switches vehicle the same way and opens `log.odometer`. A payload naming a deleted vehicle or reminder lands on plain Home, no error message. Back from any deep-linked modal lands on Home; the synthesised stack is `[home]`.

#### RTL and localisation

Rows mirror: dot and title lead at the **start**, status line and chevron at the **end**.

```
┌────────────────────────────────────────────┐
│                               ⌄  گلف من    │
├────────────────────────────────────────────┤
│ ‹ وارد شده ۱۲ شهریور        ~۱۸۷٬۴۰۰ کیلومتر│
├────────────────────────────────────────────┤
│                        روغن و فیلتر  ●      │
│                    ۱٬۴۰۰ کیلومتر گذشته      │
│                       ░░░▓▓▓▓▓▓▓▓▓▓▓▓       │
│  ⋯                            [ ثبت شد ]    │
└────────────────────────────────────────────┘
```

- The progress line grows from the **end** edge. The dot never mirrors shape; the chevron does. Never-mirror list: green tick, info glyph, `⋯`, `✕`, `+`, oil-can and spanner icons.
- Numerals and calendar follow the app-wide settings (`۱۸۷٬۴۰۰`, `۲۲ مهر`); `due_on` stays Gregorian in storage.
- Every number+unit pair (`187,412 km`, `6.4 L/100 km`, `74.20 €`) is one atomic isolate-wrapped run from the formatter, never two placeholders. The `~` and the minus sign live inside the isolate.
- Counts are ICU plurals with an explicit `=0` case: `reminders.seeAll`, `home.moreDue`, `home.unknownMore`. `home.dueSoonRelative` uses the bucketed relative formatter (Today / Tomorrow / in n days ≤ 13 / in about n weeks ≤ 55 days / in about n months). `home.dueSoonNoConfidence` carries `Odova needs a reading to say when` — one message, no placeholders.
- German breaks lengths: `Alle Erinnerungen anzeigen (14)`, `Kilometerstand aktualisieren`, `Durchschnittsverbrauch`. Tile labels reserve **two lines** always so a German or Sorani label cannot change tile height; `Log it` → `Erledigt eintragen` fits because the card action row may go full-width and stack above `⋯`.
- At 200% text scale the fold guarantee is void: the screen scrolls in reading order, primary card first, nothing clipped, no card at a fixed height. Nicknames, custom labels and workshop names take first-strong direction from their content; the chrome stays in locale direction.

#### What is deliberately not on Home

| Not here | Why |
|---|---|
| Charts, sparklines, trend lines | Costs owns them. Nobody opens Home to study a curve. |
| All-vehicles cost totals | Home is one car; `costs` has the household toggle. |
| A floating action button | The **+** is docked in the tab bar; a second one covers the last row of every list. |
| Quick-action chips ("Add fuel") | Duplicate the **+**, save zero taps, cost a row above the fold. |
| Backup nag banner | Export lives in Settings. Home is not a nagging surface. |
| Persistent "notifications are off" banner | One dismissible line in Settings. The app is fully useful without permission and must not sulk. |
| Confidence bars, percentages, tier names | Numbers about the quality of numbers are noise. |
| Greeting, name, avatar, streaks, tips, rating prompt, promo | No account exists, and this screen has one job. |
| Fuel prices, nearby stations, weather, recalls | Each needs a network. There is none. |
| A "no vehicle" state | Cannot happen; zero vehicles routes to `vehicle.edit (firstRun)` before Home is built. |

---

### `reminders.list`

**Purpose.** The full catalogue for one vehicle: what Home's three cards left out, plus untracked items the user can switch on. One push under the Home tab root, from the see-all row or the unknown-anchor card.

```
┌────────────────────────────────────────────┐
│ ‹  Reminders            Der Golf        +  │
├────────────────────────────────────────────┤
│  Starting points, not manufacturer advice. │
├────────────────────────────────────────────┤
│  ● Oil and filter      Overdue by 1,400 km›│
│  ◉ Inspection                    Due now  ›│
│  ● Front brake pads     in about 5,000 km ›│
│  ◌ Air filter    Needs an odometer reading›│
│  ○ Brake fluid     When was this last done›│
│  ✓ Tyre rotation        in about 8 months ›│
├─ Paused ───────────────────────────────────┤
│    Timing belt                    Paused  ›│
├─ Not tracked ──────────────────────────────┤
│    Spark plugs                    + Track  │
│    Coolant                        + Track  │
└────────────────────────────────────────────┘
```

The header is the same ICU message as the first-run catalogue (`reminders.disclaimer`) — one string, one place to fix it.

**Groups, in order.** Tracked and active, sorted by `projected_due_date` exactly as Home sorts and in the same dot/colour/wording vocabulary, so no legend is needed; `ok` items appear here with their next due, which is the difference between this screen and Home. Then **Paused** (`is_active = false`), greyed, no status. Then **Not tracked** (`is_tracked = false`), greyed, `+ Track` in place of a status — excluded from the due engine, from Home and from notifications.

**Interactions.** Row tap → `reminders.edit`. `+ Track` sets `is_tracked = true` and opens `reminders.edit`, because a tracked item with no anchor is just another `unknown`. App-bar `+` → `reminders.edit` in create mode. Swipe from the `end`, or long-press, reveals **Done today** (writes a `ServiceRecord` through the logging mark-done path, snackbar with **Undo**) · **Snooze** (→ `dialog.snooze`) · **Turn off**.

**States.** All items deleted: one line, `No reminders yet.`, and the `+`. One item: a one-row list, no group headers. 26 items: scrolls, group headers pinned as sticky separators. All paused: the Paused group alone under `Nothing is being tracked on this vehicle.`

**Data.** Reads `ServiceItem` (all, including untracked), `computeDueState` and `projectDueDate` per tracked item, `estimateOdometer` once. Writes `is_tracked`, `is_active`, and snooze fields via the dialog. Status wording, counts and group headers reuse Home's ICU keys; `+ Track` → `+ Verfolgen` wraps to two lines rather than truncating.

### `reminders.edit`

**Purpose.** The one place a reminder's rules are set. Modal, opened from a Home card, a `reminders.list` row, the unknown-anchor card, the snooze escalation, or `+` in create mode.

| Field | Control | Notes |
|---|---|---|
| Kind / label | Catalogue picker in create mode; free text for a custom item | Catalogue kinds keep their icon and default intervals |
| Every … distance | Number + unit | Vehicle's distance unit; blank turns the distance axis off |
| Every … months | Number | Blank turns the time axis off. Months, never days. |
| Or once, at odometer | Number + unit | One-off item |
| Or once, on date | Date picker in the active calendar | One-off; a future date is allowed here |
| Last done — date | Date picker | The baseline; prefilled from the newest `ServiceRecord` for this item |
| Last done — odometer | Number + unit | The other half of the baseline |
| Notify me | Switch | Off still shows on Home and still goes red; it just never posts |
| Tell me this far ahead | Two optional overrides, distance and days | Blank = the automatic notice window from the due engine, shown as placeholder: `Automatic — 1,000 km / 30 days` |
| Priority | Segmented: Safety · Normal · Low | Breaks ties when the notification cap coalesces |
| When it repeats, count from | Segmented: the day it was done · the day it was due | `from_actual` by default; `from_due` suits an anniversary |
| Repeats | Switch | Off makes it a one-off that goes `ok` after completion |
| Notes | Free text, 500 chars | First-strong direction from content |

**Validation.** Save blocks with an inline message under the interval block when none of the four scheduling fields is set: `Set an interval or a target date — otherwise there's nothing to remind you about.` A baseline odometer below the vehicle's first reading, or a baseline date in the future, is rejected inline. Save is never silently disabled.

**Last done.** A read-only list of the last five `ServiceRecord`s referencing this item — date, odometer, cost — each a row into the history entry detail. It is the evidence behind the anchor, so a user who thinks the app is wrong can check instead of argue.

**Delete.** An item never referenced by a `ServiceLine` deletes outright, Undo in the snackbar. An item that has been referenced is not deletable: the destructive control becomes **Turn this reminder off**, with one line — `Two services are recorded against this. Turning it off keeps them.`

**States.** Create (empty, catalogue picker focused) · edit tracked · edit untracked (banner `Not tracked — you won't be reminded`, with **Start tracking**) · edit paused (banner with **Turn back on**).

**Data.** Reads and writes one `ServiceItem`; reads its `ServiceRecord`s and `estimateOdometer` for placeholders. Editing any interval or baseline resets `snooze_count` to 0 and reschedules that item's notifications. A dirty dismiss reaches `dialog.discard`. Labels sit above inputs, never beside them, so German (`Wie weit im Voraus soll ich Bescheid sagen?`) and Sorani wrap freely; unit suffixes sit at the `end` inside the field's own ICU message.

---

### Screens Home opens but does not own

`vehicle.switcher` is specified in *First run, the garage, and vehicles*; `dialog.snooze` in *Reminders and notifications*. Two rules exist only because Home is the caller: selecting a vehicle in the switcher resets all four tab stacks to their roots, and every switcher row renders its odometer in that vehicle's own `distance_unit` — a household running a van in miles and a bike in km sees `~52,300 mi` and `12,880 km` in the same sheet, which is correct and must not be normalised.

---

## 10. Logging — fill-up, service, expense, odometer, trip

Five forms carry the whole app; everything else is arithmetic over what they write. The design target is a fill-up logged one-handed at a pump, in the rain: **four taps and two numbers, under fifteen seconds**. Entity shapes, units, currency and invariants live in *Domain model and rules*; this section specifies the screens that write them.

### The log modal shell

The four `log.*` screens are one modal with four bodies. `trips.edit` is a separate modal with the same chrome.

```
┌──────────────────────────────────────┐
│ ✕        Fill-up               Save  │  ✕ at start, Save at end
│ ┌────────┬───────┬───────┬────────┐  │
│ │Fill-up │Service│Expense│Odometer│  │  create mode only
│ └────────┴───────┴───────┴────────┘  │
│   one column, labels above fields    │
│                                      │
│ [            Save             ]      │  full-width, pinned
└──────────────────────────────────────┘     above the keyboard
```

| Rule | Why |
|---|---|
| One column, labels above inputs | German `Kraftstoffart` and Sorani labels blow up a side label; stacked labels survive 200% text scale |
| Segment bar in create mode only | An entry cannot change type |
| Opens on **Fill-up** from the central **+**, whatever the caller | The common case pays no tap |
| Per-segment drafts live in memory for the life of the modal, never in the database | A mis-tap on the segment bar costs nothing |
| Save appears twice — app bar, and a full-width primary button pinned above the keyboard | The top-end corner is unreachable one-handed on a large phone |
| **Save is never disabled on the four `log.*` segments or `trips.edit`.** On tap it validates, scrolls to the first failing field, focuses it, shows one inline error beneath it | A greyed-out Save tells the user nothing. (`vehicle.edit` is a deliberate exception — see *First run*) |
| Validates on tap-Save and on blur, never on keystroke | "1" is a prefix of "187412" |
| First field autofocused, keyboard up — except when opened prefilled (mark-done, deep link), where nothing is focused | Prefilled + focused + one thumb-slip from Save loses data |
| Errors are one plain sentence under the field, in the error colour, never a dialog. Return advances; the last field's key is Done | The field already has the user's attention |
| Save failure (disk full, write error): modal stays open with everything intact, snackbar **"Couldn't save. Your phone may be out of space."** | Never lose typed input |

**Cancel.** ✕, swipe-down and system back are one event. Clean → dismiss silently. Dirty (any field differs from its prefill) → `dialog.discard` ("Discard changes?" · *Keep editing* / *Discard*), which drops **every** segment's draft.

**Save.** One transaction: the record, its `OdometerReading` if it carries one, then a recompute of due states and a notification reschedule. Dismiss to the caller's exact scroll position, snackbar with **Undo** for 6 seconds. Undo is the only "are you sure" logging gets; it soft-deletes the new record and its reading. A wrong entry costs one tap to fix; a confirmation dialog is paid for on every correct entry.

**Delete** (edit mode only) is the last row of the form, in the destructive colour: *"Delete this fill-up"* / *"…this service record"* / *"…this expense"* / *"…this reading"* / *"…this trip"*. It opens `dialog.confirmDelete` naming what dies ("Delete this fill-up from 12 March?"), then dismisses with an Undo snackbar.

**Dates and a suspect clock.** In clock-suspect mode (*Domain model and rules*) every date field defaults to the newest `occurred_on` in the database rather than today, and Save is blocked with the reason inline. Otherwise a date more than a day after both the newest `occurred_on` and today warns without blocking: **"That's 412 days after anything else you've logged. Is the date right?"**

#### Field kit

| Control | Keyboard | Notes |
|---|---|---|
| Odometer | number pad, no decimal | Unit affix on the **end** side; see below |
| Volume, energy, mass, price, money | decimal pad | Accepts `.` `,` space `U+066B` `U+066C` `U+060C` and Latin/Arabic-Indic/Extended-Arabic-Indic digits, normalised to one canonical decimal. Ambiguous input is rejected inline: **"That number isn't clear. Try 42.61."** On blur the field re-renders canonically in the active numbering system |
| Money amount | decimal pad | Decimal places = the ISO 4217 exponent (2 EUR, 0 JPY, 3 KWD). A currency chip on the end side shows the code; tapping it changes the currency **on this record only** |
| Date | none — read-only row opening the calendar picker | Correct first day of week per locale; future dates disabled where the entity forbids them |
| Free text (station, workshop, notes) | text, sentence case | Direction is first-strong from the content, not the UI locale |
| Category / item pickers | none | Chips or a sheet, never a spinner |

No attach button anywhere: v1 has no photos or receipt scans.

#### The odometer field, everywhere it appears

This one field feeds the due engine, so it behaves identically on `log.fillup`, `log.service` and `log.odometer`.

```
Odometer
┌──────────────────────────┐  km ▾
│ 187,412                  │
└──────────────────────────┘
Last entered 186,980 km on 12 Mar   [~187,700 now ▸]
+432 km since 12 Mar
```

- **Never prefilled from an estimate.** The helper line shows the last *entered* reading and its date; the projection is a **tappable chip** (`~187,700 now`) that fills the field. An estimate that arrives as a default gets saved unread; one that takes a tap was chosen.
- Above the last reading, a live delta appears: **"+432 km since 12 Mar"** — the cheapest possible check on a dropped digit.
- **The unit affix is a tappable chip.** Tapping `km`/`mi` switches the unit **for this entry only** and records it as the entry's `odometer_unit`; the vehicle's display unit is untouched. A garage that fits a kilometre cluster to a miles car is logged without re-rendering eight years of history. The delta and the soft warnings are computed after conversion, so they stop firing spuriously.
- **Required on fill-ups and service records.** Empty → **"Enter the odometer reading."** The column is nullable only for imported rows.
- **Below the last reading → blocked at Save**, with a three-way sheet, never a bare error:

```
This reading is lower than your last one
Last entered: 186,980 km on 12 Mar.

  It's a typo — let me fix it
  The odometer was replaced or rolled over
  It's an older entry I'm adding now
  Cancel
```

  *Typo* returns focus with the text selected. *Replaced or rolled over* opens the correction sheet — old and new reading, each with its own unit chip, plus a reason (cluster replaced · rollover · the cluster now reads in different units) — and writes an `OdometerCorrection`; the offset arithmetic is in *Domain model and rules*. A unit change offers a follow-up: *"Show all your readings in kilometres from now on?"* *Older entry* appears only when the date is in the past; if the value fits between its date-neighbours the save proceeds silently, otherwise the sheet repeats.
- **Dated before the earliest reading** — allowed, and expected on a second-hand car. The helper line becomes *"Older than anything logged. This becomes your earliest reading."* and the delta is suppressed. A value higher than the current earliest reading is blocked: **"Your earliest reading is 140,000 km on 2 September. A reading from May 2019 has to be lower than that."**
- **Soft warnings** — amber line, Save still works: implied rate over 2,000 km/day (**"That's about 2,900 km a day since 12 March. Is that right?"**), a jump over 100,000 km, or a value 1.5–1.7× the last one on a miles vehicle (**"Did you mean 116,400 mi? This looks like kilometres."**).

**RTL.** The unit chip sits on the end side and mirrors with the layout. The `~` prefix and the `+432 km` delta are each one isolate-wrapped atom, so the sign never detaches from the number.

---

### `log.fillup` — Fill-up

One visit to a pump or a charger. 2–6× a month per vehicle, ten times more often than anything else — hence the default segment.

```
✕            Fill-up                Save
┌────────┬───────┬───────┬────────┐
│Fill-up │Service│Expense│Odometer│
└────────┴───────┴───────┴────────┘

  Odometer
  [ 187,412            ]  km ▾
  Last entered 186,980 km on 12 Mar
                        [~187,700 now ▸]

  ( ●  Filled it up  )(  Part fill    )

  Fuel                Price/L   Total
  [ 42.61 ] L      [ 1.799 ] € [ 76.66 ] €
                    ƒ computed

  Date            Wed 2 Sep 2026        ▸

  ── More ──────────────────────────  ▾
  Station   [ Shell A61            ]
  Grade     [ 95                   ]
  Trip      [ none                 ] ▸
  Notes     [                      ]
  [ ] I missed logging a fill-up before this
```

**More** is collapsed by default and collapsed again next time: nothing inside it changes a consumption figure.

| # | Field | Prefill | Keyboard | Req. | Validation / exact error |
|---|---|---|---|---|---|
| 1 | Odometer | empty; estimate chip offered | number pad | **yes** | Shared rules. Empty → "Enter the odometer reading." |
| 2 | Full / part fill | **Filled it up** | — | yes | — |
| 3 | Quantity (`L`/`gal`/`kg`/`kWh` by fuel kind) | empty | decimal | trio | `≤ 0` → "Fuel must be more than zero." Over tank capacity × 1.15 → amber, saves anyway: "That's more than your tank holds. Saving it as entered." |
| 4 | Price per unit | empty | decimal | trio | `< 0` → "Price can't be negative." |
| 5 | Total paid | empty | decimal | trio | `< 0` → "Total can't be negative. A free fill-up is 0." |
| 6 | Date | today | picker | yes | Future → "Pick today or a day in the past." |
| 7 | Fuel kind | the vehicle's default | — | yes | Shown only when the vehicle is `hybrid`/`other` or its history holds more than one kind; otherwise inherited silently |
| 8 | Station | up to 5 recent chips, never auto-filled | text | no | — |
| 9 | Grade | last grade for this fuel kind, as a chip | text | no | — |
| 10 | Trip | none; locked when opened from an open trip | picker | no | Only open trips and trips whose range contains the fill date |
| 11 | Notes | empty | text | no | — |
| 12 | "I missed logging a fill-up before this" | off | checkbox | no | — |

Two of the three money/volume fields must carry a value → **"Enter how much fuel you put in, and either the price per litre or the total."**

#### The price trio

Users have a receipt with a total, a pump display with a price per litre, or both. Support all three, store two.

```
onEdit(field f, value v):
  touched.moveToFront(f)                  # most-recently-edited first
  target = the field not in touched[0..1] # the one the user didn't just touch
  if two of the three have values:
      target.value = compute(target)      # display-rounded, marked ƒ
      target.style = computed             # lighter text + a small ƒ badge
  # never recompute an edited field: no feedback loops, no cursor jumps

compute:  quantity = total / price        (2 dp)
          price    = total / quantity     (3 dp)
          total    = quantity × price     (currency exponent)
```

- The computed field looks computed: lighter text plus a `ƒ` badge whose accessible name is "calculated from the other two". Tapping it clears the badge and hands over the keyboard; the least-recently-touched of the other two becomes computed.
- **The rounded, displayed value is what gets stored.** 76.66 € ÷ 1.799 shows 42.61 L and stores 42 610 mL, not 42 613.7 — a hidden extra decimal makes the app's own price-per-litre disagree with the receipt, and then nothing on screen is trusted.
- Only quantity and total are persisted; price per unit is re-derived for display (*Domain model and rules*).
- Electric: labels become **kWh**, **Price/kWh**, **Total**, and *Station* becomes *Charge point*. CNG/LPG by mass: **kg**, **Price/kg**.

#### Full versus part fill

A two-option segmented control, **not** a checkbox — "Not a full tank" as a negative checkbox is misread by a meaningful fraction of people, and this flag decides whether a consumption figure exists at all.

- **Part fill** → *"Part fills don't produce a figure on their own. This one gets added to your next full tank."*
- **"I missed logging a fill-up before this"** → *"Your consumption figures start fresh from this fill-up."* It sits under **More**: rare, and ticking it discards a segment.
- Electric with no charge ever marked full → the Fuel card on `costs.fuel` carries *"Mark a charge as full to see kWh per 100 km."*

| State | What the user sees |
|---|---|
| **First ever fill-up for this vehicle** | One line above the form: *"Your first consumption figure arrives at your next full fill-up."* No empty chart, no zero, no placeholder |
| **Create, normal** | As sketched; estimate chip only when the last reading predates today |
| **Stale odometer** (last reading > 60 days) | *"Last entered 186,980 km on 12 Mar — 174 days ago"*, no estimate chip. A 174-day-old estimate offered as a default would launder itself into a fact |
| **No prior reading** (imported vehicle) | No helper line, no chip, no delta; the field is simply required |
| **Edit mode** (`history`, `costs.fuel`) | Title *"Edit fill-up"*, no segment bar, Delete row; monotonicity checked against both neighbours |
| **Duplicate suspected** (same vehicle and date, odometer within 1 km, volume within 0.1 L) | On Save: *"You logged a fill-up on 2 September at 187,412 km for 42.61 L. Add this one too?"* · *Add it* / *Cancel* |
| **Vehicle sold or archived** | Not in the switcher; **+** targets the active vehicle, so the form is unreachable for it |

**Reads:** `Vehicle` (units, currency, default fuel kind, tank capacity), latest reading and corrections, recent fill-ups for the station and grade chips, open trips. **Writes:** one `FillUp` plus its `OdometerReading` (`source: fillup`); one of quantity-by-volume, quantity-by-mass or energy is written by fuel kind, the other two null. Recompute, then reschedule.

**After saving**, a 6 s snackbar with **Undo**. A fill that closed a fuel segment reports the result — the reward for logging at all:

- **"Fill-up saved — 7.2 L/100 km since 12 March"** · Undo
- Part fill or broken chain: **"Fill-up saved"** · Undo
- Segment discarded as a data error: **"Fill-up saved. No figure this time — the odometer didn't move."** · Undo

**Navigation.** From **+** (any screen), a `history` row, a `costs.fuel` row, the fuel path of `trips.edit → Add expense`. Reaches `dialog.discard`, `dialog.confirmDelete`, the date picker. Returns to its caller.

**RTL.** The three-field money row is a `start → end` sequence and mirrors as a whole: in RTL the quantity sits rightmost. Unit and currency affixes sit on the end side and are never concatenated into a translated string. German needs *Getankte Menge*, *Preis pro Liter*, *Gesamtbetrag* above the fields, so the row stacks labels over fields and wraps to two lines rather than truncating. The full/part control mirrors its option order.

---

### `log.service` — Service

Work that was done, and the reminders it resets. 2–4× a year, plus every mark-done.

```
✕            Service                Save

  Date            Wed 2 Sep 2026        ▸
  Odometer
  [ 187,412            ]  km ▾
  Last entered 186,980 km on 12 Mar

  What was done
  [✓ Oil & filter] [✓ Air filter]
  [ Brake fluid ] [ Inspection ] [ + Other ]
  Ticking an item resets its reminder.

  Cost
  Total           [ 92.50 ]  €
  ⌄ Split the cost by item

  ── More ──────────────────────────  ▾
  Workshop    [ Bosch Car Service   ]
  Invoice no. [                     ]
  Notes       [                     ]
```

| # | Field | Prefill | Keyboard | Req. | Validation / exact error |
|---|---|---|---|---|---|
| 1 | Date | today | picker | yes | Future → "Pick today or a day in the past." |
| 2 | Odometer | empty; last entered reading on a mark-done path | number pad | **yes** | Shared rules |
| 3 | What was done | none; originating item ticked on mark-done | chips | no | — |
| 4 | Total | empty | decimal | yes | `< 0` → "Cost can't be negative. A warranty job is 0." Empty → "Enter what it cost, or 0." |
| 5 | Per-item amounts (behind *Split the cost by item*) | empty | decimal | no | `< 0` → same text; the sum replaces Total |
| 6 | Workshop | up to 5 recent chips | text | no | — |
| 7 | Invoice no. | empty | text | no | Forced LTR, start-aligned, never digit-shaped — an identifier, not a quantity |
| 8 | Notes | empty | text | no | — |

**Item chips** are the vehicle's active service items, sorted overdue → due → due soon → ok, paused items excluded, `+ Other` last. `+ Other` opens a one-field sheet ("What was done?") producing a line with no item link — a job that resets nothing. Unticking a chip whose amount was typed keeps the money as a plain line and states the consequence: *"Air filter won't be reset."*

**Cost model.** One **Total** by default, because most people hold one invoice with one number; splitting is opt-in. Un-split, the record is one line labelled with the ticked item, or the localised *"Service"* when several or none are ticked. Split on, Total is read-only and equals the sum. Record cost is always Σ lines — there is no second cost field.

| State | What the user sees |
|---|---|
| **Create, from +** | Nothing ticked, empty total, keyboard on the odometer |
| **Mark-done** | Originating item ticked and pinned first, date today, odometer prefilled with the **last entered** reading and selected so typing replaces it, under *"From your entry on 12 Mar. Correct it if you've driven since."* |
| **New vehicle, one item** | Same layout; a one-chip row does not look broken |
| **Many items** (a van with 26) | Chip row two lines tall, then horizontal scroll with a *See all* chip opening a full-height sheet with a filter field |
| **Stale odometer** | Helper line names the age; no estimate chip |
| **Backfilling old work** | Date precedes the earliest reading → helper line *"Older than anything logged. This becomes your earliest reading."*, delta suppressed |
| **Edit mode** | Title *"Edit service"*, chips reflect the stored lines, Delete row. Unticking an item re-opens the previous anchor and recomputes that reminder |
| **Estimated record** (from a notification's *Done*) | Odometer `~187,700`, cost `—`, amber line *"We estimated this. What did the odometer actually read, and what did it cost?"*; Save clears `odometer_estimated` and `cost_estimated` |
| **Error** | Inline; a monotonicity conflict uses the three-way sheet |

**Reads:** service items and their due states, latest readings and corrections, recent workshops, `Vehicle` units and currency. **Writes:** one `ServiceRecord` with ≥1 line plus its `OdometerReading` (`source: service`); every ticked item is then re-anchored, recomputed and its notifications rebuilt.

**After saving:** **"Service saved"** · Undo — except mark-done saves, which show the confirmation panel below.

**Navigation.** From **+**, `home` due card → *Log it*, `reminders.list` row → *Done today*, `reminders.edit` → *Mark as done* (stacked; Save dismisses both to the original caller), a `history` row, the notification action **Done**. Reaches `dialog.discard`, `dialog.confirmDelete`, the date picker, the item sheet.

**RTL.** Chips wrap in the paragraph direction and mirror as a set. German labels are long (*Zahnriemenwechsel*, *Innenraumfilter*) — chips size to content and wrap rather than truncate. The invoice number is the only forced-LTR field here. Split money is a column of atoms aligned to the **end** edge in both directions.

---

### Marking a reminder done → a service record

Four entry points, one outcome: a service record. There is no "just mark it done" state anywhere — a reminder resets because work was recorded, never because a switch was flipped. That rule is what makes `report.service` worth money at resale.

| Entry point | Behaviour |
|---|---|
| `home` due card → **Log it** | Opens `log.service` prefilled: item ticked, today, last entered odometer |
| `reminders.list` row → **Done today** | Same |
| `reminders.edit` → **Mark as done** | Opens `log.service` stacked above; Save dismisses both to the original caller |
| Notification action **Done** | No UI. Writes the record with `odometer_estimated` and `cost_estimated` both true and one line carrying the item at amount 0; the payload and the rollover it triggers are in *Reminders and notifications*. It returns here later in the **Estimated record** edit state |

**The confirmation panel.** Opened from a mark-done path, Save does not dismiss straight away; the body is replaced for 5 seconds, or until *Close*, by:

```
   ✓  Oil & filter done
      2 September 2026 · 187,412 km · 92.50 €

      Next due at 197,412 km
      or September 2027 — whichever comes first

                              [ Close ]
```

A panel and not a snackbar because both the resulting due date and the due odometer have to be visible: the consequence of finishing 3,000 km early is what a user needs to see once. Saves from **+** skip it — nothing was reset. A distance-only or time-only item names one axis; if the projection's confidence is not `measured`, the projected half is fuzzy (*"around September 2027"*) in the estimate treatment. The rollover rules behind these numbers are in *Reminders and notifications*.

---

### `log.expense` — Expense

Every cost that is not fuel and not a service job. 1–2× a month.

```
✕            Expense                Save

  Category
  [Insurance][Road tax][Parking][Toll]
  [Fine][Wash][Tyre storage][Accessory]
  [Finance][Other]

  Amount          [ 612.00 ]  €
  ( ) This is a refund

  Date paid       Wed 2 Sep 2026        ▸

  ⌄ Covers a period                  ON
    From          1 Sep 2026           ▸
    To            31 Aug 2027          ▸
    Spread across 12 months in your
    monthly costs.

  ── More ──────────────────────────  ▾
  Paid to    [ Allianz              ]
  Odometer   [                      ] km ▾
  Trip       [ none                 ] ▸
  Notes      [                      ]
```

Category first: it is the only field that changes the rest of the form.

| # | Field | Prefill | Keyboard | Req. | Validation / exact error |
|---|---|---|---|---|---|
| 1 | Category | none | chips | yes | Not chosen → "Pick what this was for." |
| 2 | Label | empty | text | **Other only** | Empty → "Give this expense a name." |
| 3 | Amount | empty | decimal | yes | Empty → "Enter what you paid." `0` is allowed |
| 4 | This is a refund | off | switch | no | Flips the stored sign. A minus key on a numeric pad is inconsistent across platforms and reverses badly in RTL; a switch reads the same in six languages |
| 5 | Date paid | today | picker | yes | Future dates **allowed** — prepaid insurance is real |
| 6 | Covers a period | ON for Insurance and Road tax | switch | no | — |
| 7 | From / To | From = date paid; To = From + 12 months − 1 day | pickers | when on | `To < From` → "The end date is before the start date." |
| 8 | Paid to | recent chips | text | no | — |
| 9 | Odometer | empty | number pad | no | Optional — an expense is not a driving event. If entered, shared rules apply |
| 10 | Trip | none; locked and greyed from `trips.edit` | picker | no | — |
| 11 | Notes | empty | text | no | — |

No recurrence engine, no "repeat yearly" switch. One payment is one row with a coverage window, which the cost dashboard spreads over the months it covers; twelve generated rows would be twelve rows to maintain, edit and delete.

| State | What the user sees |
|---|---|
| **Create** | Category chips, nothing selected, no keyboard until one is picked |
| **Insurance / Road tax picked** | Period switch flips on, 12-month window prefilled, explanatory line under it |
| **Other picked** | A *What was it?* field appears under the chips and takes focus |
| **From `trips.edit`** | Trip prefilled and locked with the trip title; Save returns to `trips.edit` with the expense in its list |
| **Refund on** | Amount renders with the locale's minus sign inside the currency atom; preview line *"−80.00 € will be subtracted from your costs."* |
| **Edit mode** | Title *"Edit expense"*, Delete row |
| **Error** | Inline, per field |

**Reads:** `Vehicle` currency and units, recent vendors per category, trips whose range contains the date. **Writes:** one `Expense`, plus an `OdometerReading` (`source: expense`) only when an odometer was entered.

**After saving:** **"Expense saved"** · Undo. From a trip: **"Added to Munich run"** · Undo.

**Navigation.** From **+** and `trips.edit → Add expense`; `history` and the filtered `history` instance in the Costs stack open it in edit mode. Reaches `dialog.discard`, `dialog.confirmDelete`, the date pickers.

**RTL.** Category chips carry the longest strings in the app (`Reifeneinlagerung`, `Zulassung und Steuer`, `پارکینگ`); they wrap to three rows in German at large text scales and must never truncate. The refund minus sign is placed by the locale money formatter inside the isolate, never prefixed in code.

---

### `log.odometer` — Odometer

The fastest possible mileage update. A few times a year unprompted; more often after a staleness line on `home` or an odometer nudge.

```
✕           Odometer                Save

  ┌──────────────────────────┐  km ▾
  │ 187,412                  │
  └──────────────────────────┘
  Last entered 186,980 km on 12 Mar
  +432 km since 12 Mar

  Date            Wed 2 Sep 2026        ▸
```

Two fields. No notes, no category, no More section — this screen exists to be finished before the user changes their mind; one more optional field would be a net loss.

| # | Field | Prefill | Keyboard | Req. | Validation / exact error |
|---|---|---|---|---|---|
| 1 | Odometer | empty; estimate chip when the last reading is under 60 days old | number pad, autofocused | yes | Shared rules. Empty → "Enter the odometer reading." — 60 days is the prefill-conservatism boundary, deliberately shorter than `estimateOdometer`'s 180-day projection lifetime; a form must not hand the user a number it would only hedge on a card |
| 2 | Date | today | picker | yes | Future → "Pick today or a day in the past." |

| State | What the user sees |
|---|---|
| **From the home odometer strip** | As sketched, keypad up |
| **From an odometer nudge** | Prefilled with today, last reading in the helper line, nothing focused — a lock-screen tap is often exploratory |
| **First reading of a vehicle's life** | No helper line, no delta, just the field. This is the anchor the whole app hangs from |
| **Stale, 174 days** | Helper line names the age; no estimate chip |
| **Below the last reading** | Three-way sheet |
| **Edit mode** (a manual reading tapped in `history`) | Title *"Edit reading"*, Delete row. Readings derived from a fill-up, service or expense are **not** editable here — tapping one opens its parent record |

**Reads:** latest reading, corrections, the daily-distance projection for the estimate chip. **Writes:** one `OdometerReading` (`source: manual`); recompute, then reschedule.

**After saving** the snackbar reports the consequence, because clearing a stale-odometer state is the point of the screen:

- **"Odometer updated — 2 reminders recalculated"** · Undo
- Nothing changed status: **"Odometer updated"** · Undo
- The home staleness line disappears immediately, and any card reading *"needs an odometer reading"* re-renders with a real status.

**Navigation.** From **+**, the `home` odometer strip, the `home` staleness line's inline action, the odometer-nudge notification body. Reaches `dialog.discard`, `dialog.confirmDelete`, the date picker, the correction sheet.

**RTL.** One numeric field, one unit chip on the end side, one date row whose chevron mirrors. The `+432 km` delta is one isolate-wrapped atom; the stored value stays an integer count of metres whatever numbering system renders it.

---

### `trips.edit` — Trip

Brackets a journey so its fuel and expenses can be attributed to it. Near zero for a commuter; several times a day for a delivery or rideshare driver — the only reason this screen has to be as fast as the fill-up form.

```
✕              Trip                 Save

  ( Business )( Commute )( Personal )( Other )

  Title       [ Munich run          ]

  Starts      Mon 1 Sep 2026         ▸
  Ends        Wed 3 Sep 2026         ▸
              [ ] Still going

  Start odometer  [ 186,980 ]  km ▾
  End odometer    [ 187,412 ]  km ▾
  Distance                    432 km  ƒ

  ── Expenses ─────────────────────────
  Fuel   2 Sep   42.61 L      76.66 €
  Toll   3 Sep                12.00 €
  + Add expense
  Total                       88.66 €

  ── More ──────────────────────────  ▾
  Notes       [                      ]
```

| # | Field | Prefill | Keyboard | Req. | Validation / exact error |
|---|---|---|---|---|---|
| 1 | Purpose | **Business** if the vehicle answered yes to "do you drive this for work?", else **Personal** | segmented | yes | — |
| 2 | Title | empty | text | no | Falls back to the date range in lists |
| 3 | Starts | today | picker | yes | Future → "Pick today or a day in the past." |
| 4 | Ends | today; hidden while *Still going* is ticked | picker | no | `< Starts` → "The end date is before the start date." |
| 5 | Still going | off | checkbox | no | Ticking clears the end date and end odometer |
| 6 | Start odometer | last entered reading as a tappable chip, not filled | number pad | no | Shared rules |
| 7 | End odometer | empty | number pad | no | `< Start odometer` → "The end reading is lower than the start reading." |
| 8 | Distance | computed from the odometer pair, `ƒ` badge; editable only when **both** odometer fields are empty | decimal | no | `≤ 0` → "Distance must be more than zero." |
| 9 | Expenses list | live query, not a draft | — | — | Rows open `log.expense` / `log.fillup` in edit mode |
| 10 | Notes | empty | text | no | — |

**Distance rule.** A manual distance is written *only* when both odometer endpoints are absent, and a bare-distance trip contributes **nothing** to the odometer series. An odometer pair emits two readings (`source: trip_start`, `source: trip_end`). Trips are never the source of truth for total distance — people log some trips and not others; the odometer is the only honest cumulative record.

| State | What the user sees |
|---|---|
| **Create** | Purpose preselected, dates today, *Still going* unticked, expenses section replaced by a single **+ Add expense** row |
| **Open trip** (no end date) | *Still going* ticked, end fields hidden, a primary **End this trip** button revealing the end date and odometer and focusing the odometer |
| **One expense** | One row plus the total; the total still shows, because a single-row total is where people check the currency |
| **Dozens of expenses** (a week of tolls) | Caps at 8 rows with *See all 34*, opening the filtered `history` instance in the Costs stack |
| **Mixed currencies** | The total does not sum. It groups: **"612.00 € · 80.00 £"**. No rate is ever applied |
| **Edit mode** | Title *"Edit trip"*, Delete row. Deleting a trip does **not** delete its expenses or fill-ups — they lose the trip link and stay in history, and the dialog says so: *"Delete this trip? Its 3 entries stay in your history."* |
| **Error** | Inline, per field |

**Reads:** `Vehicle` units and currency, latest reading, the fill-ups and expenses carrying this trip's id. **Writes:** one `Trip`, plus up to two `OdometerReading` rows, one per endpoint entered.

**After saving:** **"Trip saved"** · Undo, returning to `trips.list`.

**Navigation.** From `trips.list` (row tap or **+**). Reaches `log.expense` (stacked, trip prefilled and locked), `log.fillup` in edit mode from a fuel row, `dialog.confirmDelete`, `dialog.discard`, the date pickers, the filtered `history` instance.

**RTL.** The purpose control mirrors its order. `Geschäftlich` / `Arbeitsweg` / `Privat` / `Sonstiges` do not fit four abreast in German at large text scales — it wraps to a 2×2 grid rather than shrinking its text. Start and end odometer mirror as a pair. The expenses list uses start/end swipe actions, never left/right.

---

Every save is a single transaction ending in the same two steps: recompute the vehicle's due states from facts, then cancel and rebuild that vehicle's pending notifications. Nothing derived is written to storage at any point.

---

## 11. History, timeline, entry detail and search

Two things live here: the **timeline** (`history`, tab 2) and the **entry detail**, which is not a screen but a read-only band at the top of `log.*` in edit mode. Search is a mode inside `history`. `report.service` is specified in *Fuel insights, costs and reports*.

The governing rule: **history is the only place a past record can be corrected, and correcting the past silently changes the future.** Every edit path here ends in the recompute contract below.

---

### `history` — the timeline

**Purpose.** One reverse-chronological list of every fill-up, service, expense, trip and standalone odometer reading for the active vehicle, filterable by type and year, each row one tap from being corrected. Design for the anxious check — the week before selling, the day after restoring a backup — not the browse.

#### Layout

```
┌──────────────────────────────────────────────┐
│ History                    [⌕]  [Report]     │  app bar
│ ┌────┐┌──────┐┌────────┐┌─────────────────┐  │
│ │All ││Fuel  ││Service ││ 2026 ▾          │  │  chip row, scrolls from start
│ └────┘└──────┘└────────┘└─────────────────┘  │
├──────────────────────────────────────────────┤
│ ▸ September 2026        3 entries · €148.30  │  sticky month header
│                                              │
│ ⛽  Tue 1 Sep      52.10 L · 189,204 km      │
│     Shell A5 Nord              €  89.30      │
│                                     6.1 L/100│
│ ─────────────────────────────────────────────│
│ 🔧  Thu 27 Aug     Oil and filter, air filter│
│     Bosch Service · 188,940 km   € 214.00    │
│ ─────────────────────────────────────────────│
│ 🅿  Sat 22 Aug     Parking — Flughafen        │
│                                  €  45.00    │
├──────────────────────────────────────────────┤
│ ▸ August 2026          9 entries · €412.80   │
│ …                                            │
└──────────────────────────────────────────────┘
```

Eye order: sticky **month header**, then **type icon and date** at the start edge, then **money** at the end edge in a fixed-width column so amounts stack. Consumption, odometer and vendor are secondary weight; it is a ledger, not a call to action. One row widget for all five types:

| Type | Icon | Primary line | Secondary line | Amount |
|---|---|---|---|---|
| Fill-up | fuel pump | `52.10 L · 189,204 km` | station, then grade | `€ 89.30` |
| Fill-up, partial | fuel pump + half-fill badge | `20.00 L · partial` | station | `€ 34.10` |
| Service | spanner | line labels joined by `·`, max 2 then `+2 more` | vendor · odometer | `€ 214.00` |
| Expense | category icon | category name, or `label` for `other` | vendor, or coverage window `1 Jan – 31 Dec 2026` | `€ 45.00` |
| Trip | route glyph | title, else the date range (`1–3 Sep 2026`) | `412 km · business` | trip cost, per currency |
| Odometer | gauge | `189,204 km` | `Reading` | — |

The trailing consumption figure (`6.1 L/100 km`) renders only where `buildFuelSegments` returns one for the segment ending at that fill — see *Domain model and rules*. Otherwise the slot is blank; never `0.0`.

**Flag badges**, at the end of the primary line, small and monochrome. The fuel engine discards data silently, and a discarded segment with no visible cause is a bug report we can never answer.

| Badge | Meaning | Tap |
|---|---|---|
| `~` before an odometer | Projected, not entered (`odometer_estimated`) | One-sentence explanation, single action **Update odometer** |
| chain-break glyph | `chain_broken` — the segment before this fill was discarded | "The tank before this one wasn't logged, so no consumption figure could be worked out." |
| warning triangle | This row is why a segment was thrown away: same odometer as its neighbour, negative distance, implausible volume | Opens the row in edit mode with the offending field focused |
| duplicate glyph | Same vehicle, same date, odometer within 1 km, volume within 0.1 L as another row | "Looks like the same fill-up as 1 Sep. Open both?" |

#### Grouping and month headers

Rows group by **month in the user's display calendar**, not by Gregorian month: a Jalali user's headers read `مهر ۱۴۰۴` and break at ~23 September. A reading aid in the wrong calendar is worse than none. The index is keyed by `(calendar, year, month)` and rebuilt from scratch when Settings changes calendar.

Header format is `LLLL y` in the active locale (`September 2026`, `septembre 2026`, `مهر ۱۴۰۴`), then entry count and subtotal. The subtotal is **per currency, grouped, never summed across currencies**: `9 entries · € 412.80 · £ 30.00`. Trips contribute nothing — their costs are the fills and expenses already counted.

It comes from a separate **month index** query run once per filter state, not from the loaded rows:

```
monthIndex(vehicle_id, filters) ->
  [ { month_key, calendar, count, totals: Map<currency, minor>, first_key, last_key } ]
```

Eight years is ~96 rows, and it drives the header subtotal, the year scrubber and the "no entries in 2021" empty state without loading an entry row. Folding totals out of the loaded window instead would give a subtotal that grows as you scroll, because the bottom month is half-loaded.

#### Pagination

Keyset, never offset.

```
sort key   = (occurred_on DESC, created_at DESC, id DESC)
page size  = 60 rows
prefetch   = when the last rendered row is within 20 of the loaded tail
window cap = 400 rows in memory; loading past it drops from the far end
```

`id` is a ULID, so the third key is a free deterministic tiebreak: two fills on the same day at the same station keep a stable order across rebuilds. Offset pagination would renumber the list the moment a backdated 2019 entry is saved.

**Jump.** A year scrubber on the end edge, derived from the month index. Press and drag shows a bubble with the month under the finger; release runs a fresh keyset query anchored there and **discards the loaded window**, so memory stays flat at 40 records or 4,000. Scroll position is not persisted between visits — the list opens at the top, which answers "what did I log most recently".

**Budget.** First page painted under 120 ms on a mid-range 2021 Android with 5,000 rows. A page query over 16 ms runs off the UI thread; the list keeps its previous content, never a spinner over existing rows.

#### Filters

One horizontally scrolling chip row, from the start edge, under the app bar and above the sticky headers.

| Chip | Values | Default |
|---|---|---|
| Type | All · Fuel · Service · Expense · Trips · Odometer | All |
| Year | All years · 2026 · 2025 · … (from the month index; years with zero entries are absent) | All years |
| Category | appears only when Type = Expense; the ten fixed expense categories, multi-select | none |
| Needs attention | count badge; shows only rows carrying a flag badge | off, hidden when the count is 0 |

OR within a chip, AND across chips. Filter state persists **per stack instance** and resets on a tab-stack reset — vehicle switch and import — so tab 2 and the instance pushed into the Costs stack filter independently. That is the point of pushing an instance rather than switching tabs.

Chip labels never truncate and never auto-shrink; the row scrolls instead. German `Betriebskosten` and Sorani `چاککردنەوە` fit at 200% text scale because the only constraint on the row is vertical.

#### States

| State | What is shown |
|---|---|
| **Empty, new vehicle** | Centred: "Nothing logged yet." / "Your first fill-up starts the record." Primary button **Log a fill-up** → `log.fillup`. No illustration, no tour. |
| **Empty after import of a settings-only file** | Same, plus: "Your backup was restored, but it had no entries for this car." |
| **One item** | Normal list — one header, one row, real subtotal. No "add more" prompt. |
| **Loaded, typical (200–600 rows)** | As sketched. |
| **Thousands (8 years, ~2,800 rows)** | Identical. Scrubber appears above 150 rows, the search affordance above 200 — below that, filters beat typing. |
| **Filtered to nothing** | In-list, below the chip row: "No fuel entries in 2021." + text button **Clear filters**. The chip row stays visible and interactive — never strand the user in a filter they can't see. |
| **Search, no match** | "Nothing matches \"shell\"." + **Clear search**. |
| **Stale data** | No staleness banner; the timeline shows facts, not projections. The only stale thing here is a `~` estimated odometer, badged per row. |
| **Unreadable row** | Warning icon, its date if parseable else "Unknown date", "This entry couldn't be read." Tapping offers **Export a backup** (→ `settings.backup`) and nothing else. Never hidden, never auto-deleted. |
| **Store read failure** | Full-screen: "Odova couldn't open your records." One button, **Go to Backup & restore** (→ `settings.backup`, Export enabled). Get the data out of the building first. |
| **Archived or sold vehicle** | Fully readable and editable, with one muted line under the app bar: "Sold on 14 Mar 2026." Buyers ask questions weeks later. |

#### Interactions

| Control | Action |
|---|---|
| Tap a row | Opens `log.fillup` / `log.service` / `log.expense` / `log.odometer` in edit mode, or `trips.edit` for a trip. Segment selector hidden — an entry cannot change type. |
| Swipe a row (declared `endActions`) | Reveals **Delete**; physical direction flips in RTL. → `dialog.confirmDelete`. |
| Long-press a row | Nothing in v1. No multi-select, no bulk delete. |
| Tap a month header | Collapses/expands that month. Per-session, not persisted. |
| Tap a chip | Applies the filter, re-runs the month index, scrolls to top. |
| Tap `⌕` (app bar, >200 rows) | Enters search mode in place. |
| Tap **Report** (app bar) | → `report.service` (push). |
| Pull to refresh | Absent. A rebuild is triggered by writes, not by gestures. |

#### Data in / data out

**Reads:** `FillUp` (`occurred_on`, `odometer_m`, `fuel_kind`, `quantity_*`, `total_cost`, `is_full_tank`, `chain_broken`, `station`, `grade`, `trip_id`), `ServiceRecord` + `ServiceLine` (`occurred_on`, `odometer_m`, `vendor`, `lines[].label`, `lines[].amount`), `Expense` (`occurred_on`, `category`, `label`, `amount`, `covers_from/to`, `vendor`), `Trip` (`started_on`, `ended_on`, `title`, `purpose`, odometer endpoints, `manual_distance_m`), `OdometerReading` where `source = manual` only, `OdometerCorrection` (a non-editable divider row: "Odometer replaced — 12 Mar 2023 — cluster showed 0, car had done 187,412 km"), and `Vehicle` for units, currency and name.

**Derived, read-only:** `buildFuelSegments` for the per-row consumption figure, `cumulative()` for corrected odometers, `monthIndex` for headers.

**Writes:** none directly, except the delete confirmed through `dialog.confirmDelete`, executed here and reported by snackbar. Everything else is written by the modal a row opens.

Derived odometer readings (`source ≠ manual`) get **no** row: a fill-up already shows its odometer, and listing both would double the list for no information.

#### Navigation edges

Reached from: tab 2; `costs` → tap a cost category (a filtered instance pushed into the Costs stack). No deep link lands here.
Reaches: `log.fillup` · `log.service` · `log.expense` · `log.odometer` (modal, edit mode) · `trips.edit` (modal, edit mode) · `report.service` (push, tab 2 stack only) · `dialog.confirmDelete`.
Back from `report.service` returns to `history` with filters and scroll position intact.

#### RTL and localisation

- Row layout is start/end throughout: icon and date at the start, amount at the end, aligned to the end of its fixed-width column so digits stack in both directions.
- The year scrubber sits on the **end** edge, so it moves to the left in RTL; the scrub bubble mirrors with it.
- Swipe-to-delete is declared `endActions`; the physical gesture flips.
- Month headers and dates follow the active calendar and numbering system: `Tue 1 Sep` becomes `سه‌شنبه ۱۰ شهریور` under Jalali + extarab.
- Amounts and consumption figures are each one atomic, isolate-wrapped run — `€ 89.30`, `89,30 €`, `‏٨٩٫٣٠ €`, `6.1 L/100 km`; the minus on a refunded expense sits inside the isolate.
- Station, vendor and note text is free text: first-strong direction per paragraph, so a German station name in an Arabic UI aligns correctly on its own line.
- Longest strings to design against: de `Fahrzeugsteuer` and `Versicherungsbeitrag` in the expense primary line, and the "no entries in year" empty state (`{type}`, `{year}`, explicit `=0` case). Header count is `history.monthEntryCount`.

---

### `history` — the filtered instance in the Costs stack

Same screen, same widget, same code path; only the arrival and the opening state differ.

- Pushed from `costs` on tapping a cost category row (Fuel, Service, Insurance, Parking…), arriving with Type — and for expenses Category — preset, and Year preset to the period Costs was showing.
- App bar title is the category plus period, "Insurance · 2026", so the user knows this is a slice and not the whole ledger.
- The chip row is fully live: presets can be cleared, at which point the title reverts to "History". Filters from Costs are a starting point, not a cage.
- **No Report action** — the report covers the whole vehicle, and offering it from a slice invites a report that silently omits half the jobs.
- Editing a row here recomputes, and Costs updates on pop. The totals the user tapped through from will have changed, and that is correct.
- States, pagination and RTL are identical.

---

### Search inside `history`

**Not a screen.** Chips stay the primary way to narrow the list; search exists for the one thing chips cannot do — "what did that garage in Ingolstadt charge me". The `⌕` appears in the app bar **only above 200 entries for the active vehicle**; below that the list is faster to scroll than the keyboard is to open.

**Behaviour.** Tapping `⌕` replaces the app bar title with a text field in place — no push, no modal, no route change. System back and the `✕` exit search and restore the previous filter state. Search composes with the chips (AND), so "Fuel · 2024 · shell" is expressible.

**Matching.**

```
fields = fillup.station, fillup.grade, fillup.notes
       | service.vendor, service.invoice_ref, service.notes, line.label, line.part_number
       | expense.label, expense.vendor, expense.notes
       | trip.title, trip.notes
match  = normalised substring, case-insensitive, any field
min    = 2 characters, debounced 200 ms
```

Normalisation before comparison, on both sides: Unicode NFKC; case folding; strip combining marks so `Süd` matches `sud`; Arabic-script folding (`أ إ آ ٱ → ا`, `ى → ي`, `ة → ه`, `ک/ك` and `ی/ي/ے` unified, tatweel and harakat removed); digit folding of Arabic-Indic and Extended Arabic-Indic to ASCII so typing `۱۲۳` finds a `123` invoice reference.

**No fuzzy matching, no ranking, no saved searches.** Results keep the same reverse-chronological order and month grouping. A ranked list would be a second list widget with second rules, and fuzzy matching over 3,000 rows produces confident nonsense.

**No persisted index.** Search is a query — SQL `LIKE` over the normalised expression of each text column — not a stored `search_blob`; a stale index surviving a Replace import would be a nasty bug. Measured ~18 ms over 3,000 rows on a 2021 mid-range device, inside the debounce window.

**States.** Under 2 characters shows the unfiltered list. No matches shows "Nothing matches \"shell\"." + **Clear search**. Matched substrings are **not** highlighted: highlighting inside bidi text with isolates mangles rendering in exactly the locales we care most about, and the vendor line already says why the row matched.

**RTL.** The field takes paragraph direction from its content, first-strong, so a Latin query in an Arabic UI reads left-to-right in a right-aligned field. The `⌕` never mirrors. The clear `✕` sits at the field's end edge.

---

### Entry detail — `log.*` in edit mode

There is no read-only detail screen. Tapping a history row opens the same form that created the record, prefilled, segment selector hidden, with a **context band** pinned above the fields carrying what the form cannot: the derived numbers this record participates in, and what it is attached to.

```
┌──────────────────────────────────────────────┐
│ ✕  Fill-up                            Save   │
├──────────────────────────────────────────────┤
│  1 Sep 2026 · 189,204 km                     │  context band
│  6.1 L/100 km over 854 km since 18 Aug       │  (read-only, muted)
│  € 1.714 / L                                 │
├──────────────────────────────────────────────┤
│  Date            [ 1 Sep 2026            ]   │
│  Odometer        [ 189,204            km ]   │  the log.fillup form,
│  …                                           │  unchanged, prefilled
├──────────────────────────────────────────────┤
│                     Delete this fill-up      │
└──────────────────────────────────────────────┘
```

Field layout and validation belong to *Logging*; the band is what edit mode adds.

| Type | Band shows |
|---|---|
| `log.fillup` | Segment consumption with the distance and dates it covers; unit price to 3 decimals; or, where no figure exists, the reason in one sentence: "First fill-up — your first consumption figure arrives at the next full tank." / "No figure: the tank before this wasn't logged." / "No figure: partial fill." |
| `log.service` | Record total; which reminders this record resets and their resulting next-due — "Resets Oil and filter → next due 189,000 km or Aug 2027". If the odometer was estimated, "Odometer estimated from your driving — tap to correct" is the band's first line. |
| `log.expense` | Coverage window and monthly share when `covers_from/to` are set: "€ 480.00 over 12 months = € 40.00 a month." |
| `log.odometer` | Distance and days since the previous reading, and the implied rate: "1,240 km in 31 days — 40 km a day." |
| `trips.edit` | Trip distance and attached costs, per currency, with a count: "412 km · 2 entries · € 71.40". |

*Why a band and not a screen:* the numbers are the reason someone opened the row, and they are three lines. A page that shows three lines and an Edit button costs a tap and teaches nothing.

**Delete** sits at the bottom of the form, destructive-styled, never in the app bar where Save is. It opens `dialog.confirmDelete`, which names what dies and what it takes with it.

**Attachments.** None anywhere in v1: no attach button on any form, no paperclip on any row.

---

### Editing the past: the recompute contract

**A record's odometer or date is an input to every derived number after it.** Correcting a 2019 fill-up from 89,204 to 98,204 km changes two segments, the lifetime average, every cost-per-km figure since, the daily-distance estimate, the projected odometer, and every reminder's projected due date — which changes what the OS has scheduled.

**Invalidate whole vehicles, not dependency subgraphs.**

```
onWrite(record) | onDelete(record) | onRestore(record):
  1. write, bump updated_at            (single transaction)
  2. drop the entire derived cache for record.vehicle_id
  3. recompute, in dependency order:
       odometer series → cumulative() → dailyDistance() → estimateOdometer()
       → buildFuelSegments() per fuel_kind → consumption, trend, unit prices
       → resolveAnchor() → computeDueState() → projectDueDate()
       → monthIndex, costByCategory, costPerDistance, monthlyCost
  4. diff the due states against the pre-write snapshot; if any status, due_on or
     due_at_odometer_m changed → rebuild that vehicle's notification schedule
     (per *Reminders and notifications*)
  5. dismiss the modal, return to the exact scroll position, show the snackbar
```

*Why the blunt instrument:* the fine-grained "which segments does this touch" graph is forty lines of subtle code guarding a recompute that costs single-digit milliseconds, and a cache that is wrong is worse than one that is cold. Budget: full recompute for 5,000 rows under **150 ms**; above 16 ms it runs off the UI thread with previous values held on screen, never a spinner.

**The snackbar names the consequence.** One line, one Undo, no dialog:

| Edit | Snackbar |
|---|---|
| Fill-up odometer changed | "Fill-up updated · 14 later fuel figures recalculated" · **Undo** |
| Fill-up date moved across another fill | "Fill-up moved to 18 Aug · fuel figures recalculated" · **Undo** |
| Service record deleted | "Service deleted · Oil and filter is now due since 12 Mar 2024" · **Undo** |
| Expense edited | "Expense updated" · **Undo** |
| Nothing derived changed | "Saved" · **Undo** |

Undo re-applies the pre-write snapshot and re-runs the same pipeline. It is live until the snackbar dismisses — 6 seconds, or the next navigation.

**Monotonicity on an edit is harder than on a new entry**, because an edited reading has neighbours on both sides. The invariant lives in *Domain model and rules*; edit mode adds the two-sided comparison:

| Case | Resolution |
|---|---|
| Fits between both neighbours | Saves silently. |
| Breaks against the earlier neighbour, and this is the newest reading | The new-entry three-way dialogue, unchanged. |
| Breaks against a later neighbour (a mid-history row) | Two options only: **Fix the number** / **Cancel**. A correction can only start at the newest reading; inserting one mid-history would rewrite every cumulative value after it. Error text: "This is lower than your reading on 12 Oct 2024 (191,400 km). Odometers only go up." |
| The row is `from_reading_id` of an existing correction | Delete and odometer edits are blocked. *"This reading starts an odometer correction from 12 Mar 2023. Delete the correction first."* The correction's own divider row in this list carries the swipe **Delete** that removes it (with Undo); deleting a correction re-runs the recompute contract for the vehicle. |

**What a delete takes with it.** `dialog.confirmDelete` names it explicitly:

| Deleting | Dialog body |
|---|---|
| A fill-up mid-chain | "Delete this fill-up? The consumption figure for 18 Aug – 1 Sep will be recalculated." |
| A fill-up that opens a chain | "Delete this fill-up? Two consumption figures will be removed." |
| A service record that reset reminders | "Delete this service? Oil and filter and Inspection will go back to being due from the job before this one." |
| A trip with attached costs | "Delete this trip? Its 2 expenses stay — they'll just stop being attached to a trip." Costs are never deleted as a side effect of deleting the thing they were grouped under. |
| A standalone odometer reading | "Delete this reading?" Blocked outright if it is the vehicle's only reading: "This is the only odometer reading for the Golf. Every car needs one." |

**Delete is immediate; the undo is in the moment.** `deleted_at` is written so Undo is a field write rather than a resurrection, and is null again once the snackbar expires. No screen lists deleted rows, there is no bin, and the safety net past the snackbar is the pre-operation backup.

---

## 12. Fuel insights, costs and reports

Three screens: `costs` (tab root), `costs.fuel` (push), `report.service` (push). `trips.list` closes the section because it feeds cost attribution; `trips.edit` belongs to *Logging*.

All three are read-only. They write nothing but per-stack UI state — range, fuel kind, report toggles — which dies with the tab-stack reset. Every figure is a pure function of the record tables plus an injected `today`, so fixing a 2019 odometer typo changes every number here on the next frame.

### Ground rules for every number on these screens

**Completed months only.** A range ends on the last day of the previous calendar month: on 2 September 2026, "Last 12 months" is 1 Sep 2025 – 31 Aug 2026. The current month is out of numerator and denominator alike, reported separately as `This month so far: 64 €`. An average including a two-day-old month halves itself on the 2nd of every month.

| Range chip | Definition |
|---|---|
| `3 months` | last 3 completed calendar months |
| `12 months` | last 12 completed calendar months — **default** |
| `This year` | 1 Jan → end of last completed month; hidden during January |
| `All` | month of the vehicle's first record → end of last completed month |

**Costs are accrual; History is cash.** An `Expense` with `covers_from`/`covers_to` is spread over the months it covers; everything else is charged to the month it was paid. One line under the headline says so: *"Yearly costs like insurance are spread over the months they cover."* Fill-ups and service lines are point costs.

```
monthlyShare(e, m) =
  if e.covers_from and e.covers_to and covers_to >= covers_from:
      overlap_days(m, covers_from..covers_to)
        / total_days(covers_from..covers_to) × e.amount
  else:
      e.amount if m contains e.occurred_on else 0
```

Allocation runs in minor units with largest-remainder distribution, so 1,200.00 EUR over 365 days never becomes 1,199.99.

**Money never mixes.** Every total is a `Map<currency, minor>`. With two or more currencies in range, the dominant one (most rows) is the headline and the rest stack beneath: `2,244 €` then `+ £80`. Shares, cost per distance and cost per month are computed once per currency. No conversion — there is no network.

**Estimated values look estimated**, in the treatment defined in *Reminders and notifications*; cost per distance is the only figure here that can be estimated. Otherwise refuse rather than guess: `—` plus a one-sentence reason on tap.

---

### `costs` — Costs (tab root, tab 3)

**Purpose.** What the car costs per month and per distance, and where the money goes. Opened roughly monthly out of curiosity, and once hard at tax time.

```
┌───────────────────────────────────────────────┐
│ Costs                        All vehicles ( ) │  ← toggle only if ≥2 vehicles
│ [ 3 months ][ 12 months ][ This year ][ All ] │  ← horizontally scrollable chips
├───────────────────────────────────────────────┤
│                                               │
│      187 €                 0.121 €/km         │  ← headline pair, largest type
│      per month                                │
│      Sep 2025 – Aug 2026 · 2,244 € total      │
│      This month so far: 64 €                  │
│      Yearly costs are spread over the         │
│      months they cover.                       │
│                                               │
│   ▁ ▃ ▂ ▅ ▂ ▂ ▇ ▃ ▂ ▄ ▂ ▃    stacked by group │
│   S O N D J F M A M J J A                     │
│                                               │
│   Fuel                 1,180 €  53% ▓▓▓▓▓▓▓ › │
│   Service & repairs      642 €  29% ▓▓▓▓    › │
│   Insurance & tax        310 €  14% ▓▓      › │
│   Parking & tolls         72 €   3% ▓       › │
│   Other                   40 €   2% ▏       › │
│                                               │
│ ┌ Fuel & consumption                        ›┐│
│ │ 6.4 L/100 km · 1.712 €/L last paid         ││
│ └────────────────────────────────────────────┘│
│ ┌ Trips                                      ›┐│
│ │ 14 trips · 3,120 km · 62% business         ││
│ └────────────────────────────────────────────┘│
└───────────────────────────────────────────────┘
```

The headline pair wins the eye: cost per month is what people quote to each other, cost per distance makes two cars comparable.

#### The numbers, exactly

```
totalCost(v, from, to) -> Map<currency, minor>
    Σ FillUp.total_cost          where occurred_on in [from, to]
  + Σ ServiceLine.amount         of ServiceRecords with occurred_on in [from, to]
  + Σ monthlyShare(e, m)         for every month m in [from, to],
                                 every Expense e overlapping the range
  (live rows only)

costPerMonth = totalCost / completedMonths
completedMonths = whole calendar months in [from, to] during which the vehicle
                  was owned (clipped by purchase_date and sold_on when set)

costPerDistance = totalCost / distanceBetween(v, from, to)

distanceBetween(v, from, to):
    a = last OdometerReading with occurred_on <= from  (else the earliest reading)
    b = last OdometerReading with occurred_on <= to
    return cumulative(b) − cumulative(a)
```

`cumulative()` applies `OdometerCorrection` offsets. Cost per distance uses **measured readings only**, never the projected odometer: a projection grows while the app sits unopened, so yesterday's cost per kilometre would differ from today's with no new data.

| Condition | Behaviour |
|---|---|
| A boundary reading is >45 days from its boundary date | Estimated treatment; tap → *"Worked out from odometer readings 62 days apart from the dates shown."* + **Update odometer** → `log.odometer` |
| `distanceBetween` < 100 km | `—`; tap → *"Not enough distance logged in this period to work out a cost per kilometre."* + **Update odometer** |
| `completedMonths` < 1 | Per-month figure `—`; tap → *"Come back after the end of the month — there isn't a full month to average yet."* (no action) |

#### Category groups

The ten `ExpenseCategory` values plus fuel and service collapse to at most six rows.

| Row | Sources |
|---|---|
| Fuel | `FillUp.total_cost` |
| Service & repairs | `ServiceLine.amount` |
| Insurance & tax | `insurance`, `tax_registration` |
| Finance | `finance` |
| Parking & tolls | `parking`, `toll` |
| Other | `fine`, `wash`, `tyre_storage`, `accessories`, `other` |

Zero rows are hidden, not shown as `0 €`. Shares are per currency at 0 dp, the largest row absorbing the remainder so the column reads 100%. Tapping a row pushes a filtered `history` **inside the Costs stack**, type/category preset.

**Business split.** When `Vehicle.is_business` is true, one row sits under the category list: `Business 62% · 1,391 € — from logged trips`, computed as `businessShare` (*trips.list*) applied to `totalCost` for the range, with the caption *"Worked out from the trips you logged, not from all your driving."* It is hidden when the vehicle is not a business vehicle or no trips fall in the range.

**Not shown, deliberately.** Depreciation or market value — no valuation feed, and a made-up number on someone's car is worse than silence. Cost per day, year or trip; budgets; "12% more than last month" — a comparison against an arbitrary baseline is an accusation. A pie or donut: six bars carry label, amount and share on one line and mirror trivially. Projected annual cost: multiplying two months by six is the confident wrongness this spec exists to avoid.

#### The monthly chart

Stacked columns, one per calendar month, coloured by the groups above; one baseline, no value-axis labels — columns for shape, list for figures. Tooltip: `Mar 2026 · 214 €`. The chart exposes an accessible summary node reading the same figures as the list; no figure exists only inside a chart.

| Data volume | What renders |
|---|---|
| 0 months with cost | No chart |
| 1–2 months | No chart; rows instead: `Aug 2026 · 214 €`. Two columns are not a shape. |
| 3–36 months | One per month; x labels every month to 12, then every third |
| > 36 months | One column per **year** — 96 columns on a phone is a texture |
| Mixed currencies | Dominant currency only, caption `Chart shows € only.` |

#### All-vehicles comparison

Appears only with ≥2 non-archived vehicles; affects this tab only, never `activeVehicleId`.

```
Household · Sep 2025 – Aug 2026
   412 € per month · 4,944 € total

   Golf        187 €/mo    0.121 €/km    14,300 km
   Van         198 €/mo    0.164 €/km     9,800 km
   CB500        27 €/mo    0.061 €/km     3,100 km

   ( ) Include sold and archived        1 vehicle hidden
```

Sorted by cost per month, descending. **Include sold and archived** is off by default: off, the trailing line names the hidden count; on, those vehicles join the list and the household totals, each labelled with its `status`. A vehicle in another currency sits under its own subtotal, unsummed. Rows are **not tappable** — vehicle selection lives only in `vehicle.switcher`. The category list and chart below aggregate across the included vehicles.

#### States

| State | Screen |
|---|---|
| **First run / empty** | *"No costs yet."* / *"Log a fill-up or a service and this fills itself in."* + **Log something** → log modal on Fill-up. Chips hidden. |
| **One record** | Total shown; both headline figures `—` with their explanations; one category row; no chart. |
| **Loaded, typical** | As sketched. |
| **Hundreds of records** | Identical — one pass per table, 8 years ≈ 3,000 rows in milliseconds, memoised until the next write. No pagination. |
| **Stale odometer** | Cost per distance in estimated treatment. Money does not go stale. |
| **Range with no data** | `0 €` per month, cost/km `—`, empty list, *"Nothing logged between June and August."* Chips stay usable. |
| **Error** | No fetch to fail; a corrupt store is caught at launch and routed to `settings.backup`. |

#### Interactions

| Control | Result |
|---|---|
| Range chip | Recomputes in place; selection lives for this tab stack |
| All vehicles toggle | Switches aggregation; range preserved |
| Include sold and archived | Re-aggregates the household list in place |
| Category row | Push filtered `history` in the Costs stack |
| Fuel card / Trips card | Push `costs.fuel` / `trips.list` |
| Estimated or `—` value | Bottom sheet: one sentence + **Update odometer** → `log.odometer` |
| Overflow → **Export costs (CSV)** | `odova-costs-<vehicle\|all>-YYYY-MM-DD.csv` from the shared generator to the OS share sheet — the same output the Export screen owns; this overflow entry is a second door to it, not a fifth export |
| Re-tap tab 3 | Pop to `costs`, then scroll to top |

**Data in:** `Vehicle{name, status, purchase_date, sold_on, currency, is_business}`, `Settings{currency_default, distance_unit, language, numerals, calendar}`, `FillUp{occurred_on, total_cost}`, `ServiceRecord` + `ServiceLine{amount}`, `Expense{occurred_on, category, amount, covers_from, covers_to}`, `OdometerReading`, `OdometerCorrection`, `Trip`. **Data out:** nothing persisted; a CSV handed to the OS.

**Navigation edges.** From tab 3. To `costs.fuel`, `trips.list`, `history` (filtered, in-stack), `log.odometer`, OS share sheet.

#### RTL and localisation

- Category rows: label at the **start** edge, amount and share at the **end**, share bar growing from the **start**.
- The chart's time axis runs **right to left** in fa/ar/ckb — oldest month at the right, value axis and ticks on the right edge; columns still grow upward, stack order unchanged, legend and colour key mirrored. Ticks and tooltips are real text, so Persian and Arabic-Indic digits appear in the chart; no digits baked into images.
- `0.121 €/km` follows the vehicle's `distance_unit`: a miles vehicle shows `€/mi` from the same canonical metres.
- German is the length case (`Versicherung und Steuer`, `Alle Fahrzeuge`): rows wrap to two lines with the amount end-aligned on the first, chips scroll rather than shrink (`Letzte 12 Monate`).

---

### `costs.fuel` — Fuel & consumption (push, from `costs`)

**Purpose.** What the car drinks, what fuel costs, and whether that is changing. Opened every few weeks by the minority who care, and once by everyone after a tank that felt expensive.

```
┌ ‹  Fuel & consumption               12 months ▾ ┐
│  [ Petrol ]  [ LPG ]        ← only if 2+ kinds  │
├─────────────────────────────────────────────────┤
│                                                 │
│            6.4 L/100 km                         │
│            average over 23 tanks                │
│   Last tank 6.9  ·  Best 5.8  ·  Worst 8.1      │
│                                                 │
│   ⚠ Using more fuel lately                      │
│     Last 3 tanks 7.1, the 6 before 6.5          │
│                                                 │
│   ▁▂▁▃▂▂▄▃▂▅▃▂▃▄▂▃▅▃▂▃▄▂▃   per tank            │
│   ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   average 6.4        │
│   Sep            Feb            Aug             │
│                                                 │
│   1.712 €/L last paid · 1.684 €/L average       │
│   ╱‾╲╱╲__╱‾╲╱                                   │
│                                                 │
│   Fuel cost   0.109 €/km   ·   118 €/month      │
│   1,180 € over 690.4 L                          │
│                                                 │
│   Recent fill-ups                      See all ›│
│   3 Sep   41.2 L   70.55 €   1.712 €/L   6.9    │
│   19 Aug  38.7 L   65.10 €   1.682 €/L   6.1    │
│   4 Aug   40.1 L   68.94 €   1.719 €/L   7.4    │
└─────────────────────────────────────────────────┘
```

The largest thing on the screen is average consumption — the one number people quote about their own car.

#### The numbers, exactly

Segments, partial fills and `consumptionTrend` come from the domain model, per `fuel_kind`, unchanged. Everything here is total-over-total:

```
averageConsumption(segs) = Σ volume(segs) / Σ distance_m(segs)     # never a mean of means
lastTank                 = segmentConsumption(segs.last)
best / worst             = min / max segmentConsumption(segs), with the closing fill's date
avgPricePaid(range)      = Σ total_cost / Σ quantity               # not the mean of unit prices
lastPricePaid            = unitPrice(newest fill in range)
fuelSpend(range)         = Σ FillUp.total_cost
fuelVolume(range)        = Σ quantity of those fills
fuelCostPerDistance      = Σ cost(pending fills of each segment) / Σ distance_m(segments)
fuelCostPerMonth         = fuelSpend(range) / completedMonths(range)
```

Every money-bearing figure is computed **per currency**, as in `costs`: `avgPricePaid`, `lastPricePaid`, `fuelSpend`, `fuelCostPerDistance` and `fuelCostPerMonth` return `Map<currency, …>`, dominant currency (most fills in range) as the headline, the rest stacked beneath. `fuelCostPerDistance` for a currency uses only segments whose contributing fills are all in that currency; a segment mixing currencies is excluded from every per-distance figure, contributes volume and distance only, and is counted by the data-quality row: *"1 tank spanned two currencies — no cost per kilometre for it."* The same grouping governs `1.712 €/L last paid` on the `costs` fuel card. Without it, the driver who fills up abroad gets a price per litre that adds euros to pounds and divides by litres.

`fuelCostPerDistance` sums the cost of **exactly the fills whose volume built the segment** — those after the opening fill up to and including the closing one. Every fill in the date range would charge fuel from an open, unmeasured segment against a distance that excludes it.

Unit price is derived at display time to 3 dp, never stored. Consumption renders to 1 dp; the measurement is not good enough for two.

| `consumptionTrend` | Line |
|---|---|
| `thirstier` | **Using more fuel lately** — *Last 3 tanks 7.1, the 6 before 6.5* |
| `leaner` | **Using less fuel lately** — *Last 3 tanks 6.0, the 6 before 6.5* |
| `steady` | Nothing. "Your consumption is normal" occupies space and changes no behaviour. |
| `insufficient_data` | Nothing. |

Both figures appear in the copy so the claim is checkable. No cause is suggested: the app cannot tell winter from a roof box from a failing sensor, and guessing wrong sends someone to a garage for nothing.

**Not shown, deliberately.** Average distance per tank; fill-up count as a headline; CO₂ estimates; remaining range (the tank level is unknown); "money saved" against any baseline; per-station price comparison — a handful of fills per station is noise.

#### Charts

**1. Consumption per tank.** Columns, one per closed segment, ordered by the closing fill's date, with a dashed average line. Columns not a line: segments are discrete measurements at irregular intervals, and a line asserts values on days that were never measured. Tap → `19 Aug · 6.1 L/100 km · 612 km · 37.3 L`; a second tap on the tooltip opens `log.fillup` in edit mode for the closing fill.

**2. Price per unit.** Line with points, one per fill-up in range — pump prices genuinely move between fills. Y axis starts at the range minimum minus 5%; the variation is a few percent and a zero baseline flattens it to nothing.

Both expose an accessible summary node with the same figures as the text around them; each column or point exposes `{value} on {date}`.

| Data volume | Consumption chart | Price chart |
|---|---|---|
| 0 segments | Hidden. *"Your first figure arrives at your next full fill."* | Hidden if <2 fills |
| 1 segment | Hidden; as text: *"One full tank so far: 6.9 L/100 km."* | 2 points render as a two-point line |
| 2 segments | Rendered, no average line, no best/worst | Rendered |
| 3–60 segments | Rendered with average line; x labels at 3 evenly spaced dates | Rendered |
| > 60 segments | Columns bucket to **one per month** (that month's volume over distance) | Points thin to one per month (that month's `avgPricePaid`) |

#### Fuel kinds and electric

- The segmented control appears only with fills of ≥2 `fuel_kind` values. Series are per kind and never merged; a bi-fuel LPG car has two consumption series and two averages.
- Electric: same maths on `energy_wh`, shown as `kWh/100 km` or `mi/kWh`. If no charge in range is marked full, the consumption block is replaced by cost figures plus *"Mark a charge as full when you charge to your usual limit, and consumption figures start here."*
- Mass-sold gas (`quantity_g`) displays in kg; consumption in kg/100 km.

#### Data-quality banner

When a segment is discarded (same odometer, negative distance, zero volume), a fill carries `chain_broken`, or a segment mixes currencies, one row sits under the app bar:

```
  2 fill-ups need a look — their figures were skipped     ›
```

Tapping pushes a filtered `history` in the Costs stack, type = fill-up, flagged rows only. Never a modal, never red: housekeeping, not an emergency. Fills missing an odometer reach this state only via import — the entry form requires it.

#### States

| State | Screen |
|---|---|
| **Empty** | *"No fill-ups yet."* / *"Log one and your real consumption starts building."* + **Log a fill-up** → `log.fillup`. Range selector hidden. |
| **One fill** | *"Your first figure arrives at your next full fill."* Price paid and total spend show — known from one receipt. No consumption block. |
| **Two fills, one segment** | Single figure as text; no chart, no trend, no best/worst. |
| **Loaded** | As sketched. |
| **Hundreds of fills** | Aggregates unchanged; charts bucket per the table; "Recent fill-ups" shows 5 rows and defers to `history`. |
| **Range empty, history is not** | *"No fill-ups between June and August."* Chips stay usable; ranges never jump silently — except on first entry, where the default falls back to `All` if `12 months` holds fewer than 3 segments. |
| **Stale odometer** | Consumption is measured between two real readings, so it is unaffected and **not** dimmed. Only `fuelCostPerMonth` and per-distance take the estimated treatment, when the boundaries are poorly bracketed. |
| **Error** | None; see `costs`. |

**Data in:** `FillUp{occurred_on, odometer_m, fuel_kind, quantity_ml|quantity_g|energy_wh, total_cost, is_full_tank, chain_broken, station, grade}`, `OdometerCorrection`, `Vehicle{tank_capacity_ml, currency, consumption_unit, volume_unit, distance_unit}`, `Settings` unit defaults. **Data out:** nothing.

**Navigation edges.** From the `costs` fuel card. To `log.fillup` (edit mode, from a chart tooltip or a recent-fill row), `history` (filtered, in-stack, via "See all" and the data-quality row), `log.odometer` (from an estimate explanation). Back → `costs`.

#### RTL and localisation

- Both charts run **right to left**: oldest tank at the right edge, value axis on the right. The dashed average line is unchanged; the price line's slope reverses with the axis, which is what RTL readers expect.
- The fuel-kind control mirrors (first kind at the start edge). Recent-fill rows put the date at the start and consumption at the end; swipes are `startActions`/`endActions`.
- Consumption units come from our ARB files — CLDR short units are wrong for `L/100 km` in fa and ckb, so we ship `لیتر/۱۰۰ کیلومتر` ourselves. `mpg (US)` and `mpg (imp)` are distinct strings and distinct units.
- German (`Kraftstoffkosten`, `Durchschnittsverbrauch`, `Verbrauch pro Tankfüllung`): labels wrap to two lines rather than truncate, and the "Last tank · Best · Worst" strip becomes a two-column grid below 380 dp or at ≥150% text scale rather than shrinking type.

---

### `report.service` — Service report (push, from `history`)

**Purpose.** Turn eight years of records into one document a buyer will believe. Opened once or twice in the life of the car, at the moment of highest stakes and lowest patience. It ships in v1: the data is already there, the layout is a table, sharing is the OS's job.

```
┌ ‹  Service report                               ┐
│                                                 │
│   ┌───────────────────────────────────────────┐ │
│   │  VW Golf 1.6 TDI · 2016                   │ │
│   │  Owned Mar 2018 – today · 8 years 6 months│ │
│   │  62,400 km → 187,412 km   (125,012 km)    │ │
│   │  34 services · 6,842 € spent              │ │
│   └───────────────────────────────────────────┘ │
│                                                 │
│   Include                                       │
│   ▢ Plate and VIN                    (off)      │
│   ▣ Costs                             (on)      │
│   ▣ Fuel consumption summary          (on)      │
│   ▢ My private notes                  (off)     │
│      Your notes may say things you don't        │
│      want a buyer to read.                      │
│                                                 │
│   ─── Preview ────────────────────────────────  │
│   2026                          1,240 €         │
│   14 Jun 2026   174,300 km                      │
│   Oil and filter, cabin filter        184.50 €  │
│   Werkstatt Krüger                              │
│                                                 │
│   2 Feb 2026    168,110 km                      │
│   Front brake pads and discs          412.00 €  │
│   ... (scrolls, all 34)                         │
│                                                 │
├─────────────────────────────────────────────────┤
│   [        Share PDF        ]   [ ⋯ ]           │
└─────────────────────────────────────────────────┘
```

The preview *is* the document, rendered as native list rows, and the toggles change it live. A PDF viewer in the app would be a second renderer to keep in sync with the first.

#### What the document contains

1. **Header** — vehicle name, make/model/year, colour; ownership span; odometer at purchase and the latest **entered** reading with its date; distance under this owner. Never a projection: a document handed to a buyer contains no estimates.
2. **Summary line** — `34 services · 6,842 €` (per currency if mixed), hidden when Costs is off.
3. **Maintenance at a glance** — every tracked `ServiceItem` with at least one completion: name, date and odometer last done at, distance since — *"Timing belt — 100,300 km, 12 Apr 2023, 87,000 km ago."* Items never done are listed under *"No record in this app"*, because an absent row reads as a hidden row.
4. **Full history** — every `ServiceRecord`, newest first, **grouped by year with a per-year subtotal in the year heading** (`2026 — 1,240 €`; dropped when Costs is off). Each row: date, odometer, its line labels, vendor, invoice reference, line costs, record total.
5. **Fuel consumption summary** (toggle) — `Average 6.4 L/100 km over 231 tanks and 118,400 km`.
6. **Footer, unremovable** — *"Generated by Odova on 2 September 2026 from records kept by the owner. Not verified by a third party."*

Records with `odometer_estimated` carry a `~` before the figure and one footnote: *"~ odometer estimated at the time, not read from the car."* Hiding that in a document handed to a buyer is a small lie the app has no business telling.

**My private notes** is off by default and its toggle carries the warning shown above — notes say things like "cheaper than the dealer wanted".

**Never in the document:** fines, parking, tolls, washes, fuel receipts, insurance premiums, trip logs; notes and plate/VIN unless toggled on. A fine on a sales document is an own goal, and the identity fields are the buyer's to ask for, not the app's to leak into a group chat.

#### Production and sharing

- Rendered on-device with the platform's PDF canvas. **A4** everywhere except regions US/CA/MX/PH, which get **US Letter**, from the resolved region, overridable in the overflow menu.
- Multi-page, repeating table header, `Page 2 of 4` in the footer. 34 services is 2–3 pages; ~200 services about 12.
- Arabic-script locales embed the same Vazirmatn subset the app ships — embedded, not referenced, because the file must render on a stranger's phone.
- Filename `odova-service-history-<vehicle>-YYYY-MM-DD.pdf`, ASCII, vehicle name transliterated to `[a-z0-9-]` with a positional fallback (`odova-service-history-vehicle-2-2026-09-02.pdf`).
- Written to a temp file and handed to the **OS share sheet**. The app never picks a destination, asks for storage permission, remembers where the file went, or generates in the background.
- Overflow `⋯`: **Copy as text** — the same content as plain text on the clipboard, for pasting into a classifieds listing, which is how cars are actually sold on Divar, Willhaben, Leboncoin and Marketplace. **Paper size**. Nothing else.

#### States

| State | Screen |
|---|---|
| **No service records** | Header card still renders. Preview replaced by *"No services logged yet. This report gets valuable the moment you start adding them."* **Share PDF** disabled, reason under it, not in a toast. |
| **One record** | Full document, one row. No apology: one documented cambelt change is worth printing. |
| **Loaded** | As sketched. |
| **Hundreds of records** | Preview virtualised. Over 200 records, generation shows a blocking *"Building your report…"* with a Cancel instead of a frozen button; under 200 it is synchronous. |
| **Stale odometer** | Header uses the last entered reading and its date: `187,412 km (read 14 Jun 2026)`. No projection in screen or document. |
| **Mixed currencies** | Totals group: `6,842 € · £310`. Line costs print in their own currency. |
| **Error (generation or share)** | Inline under the button: *"Couldn't build the file. There may not be enough space on the device."* + **Try again**. No dialog — the user is already stressed. |
| **Sold vehicle** | Span ends at `sold_on`: `Owned Mar 2018 – Aug 2026`. Available for archived and sold vehicles forever. |

**Data in:** `Vehicle` (identity, purchase and sale), `ServiceRecord` + `ServiceLine`, `ServiceItem{kind, label}`, `OdometerReading`, `OdometerCorrection`, `FillUp` (summary only), `Settings{language, calendar, numerals, currency}`. **Data out:** a temp PDF or a clipboard string; nothing in the database changes.

**Navigation edges.** From `history` app bar → **Service report** (push); back returns to `history` with filters and scroll intact. To the OS share sheet and clipboard. Not reachable from `costs` — one door is enough for a screen opened twice a decade.

#### RTL and localisation

- The document mirrors completely in fa/ar/ckb: page direction RTL, table columns reversed (date at the right edge), header block right-aligned.
- Document dates and numerals follow the app's display settings — a Persian seller hands a Persian buyer a Jalali document with Persian digits — and the footer's generation date also carries the ISO Gregorian date in brackets: *"… on ۱۱ شهریور ۱۴۰۵ (2026-09-02) …"*. Filenames stay ASCII Latin and Gregorian regardless of language.
- **VIN is forced LTR with start-of-line alignment even on an RTL page.** Plates print verbatim as typed and are never digit-shaped in either direction — a plate is a picture of a plate, not a number.
- The *"What was done"* column holds free text and takes direction from its own content, first-strong per paragraph: a German workshop name inside a Persian document renders LTR inside an RTL cell, isolated.
- German (`Serviceverlauf`, `Kennzeichen und Fahrgestellnummer`): toggle labels wrap to two lines with the switch pinned at the end edge and centred on the first; the action button sizes to content with a minimum width and wraps rather than shrinks.

---

### `trips.list` — Trips (push, from `costs`)

Here because it is a cost-attribution view; `trips.edit` is specified with the entry forms.

**Purpose.** What each journey cost and how much of the driving was business. Opened weekly by rideshare, delivery and trades users; never by everyone else.

Reverse-chronological rows: title or date range, distance, purpose chip, cost. Header strip over the range: `14 trips · 3,120 km · 62% business · 486 €`. The business percentage is the only aggregate worth computing here — it is the number that goes on a tax form.

```
tripDistance(t) = cumulative(end_odometer) − cumulative(start_odometer)
                  ?? t.manual_distance_m
tripCost(t)     = Σ FillUp.total_cost where trip_id = t
                + Σ Expense.amount    where trip_id = t          # per currency
businessShare   = Σ tripDistance(purpose = business) / Σ tripDistance(all trips in range)
```

Trip distances are never summed into vehicle distance — people log some trips, not all. The odometer is the source of truth, and the header says `3,120 km across logged trips` to make that explicit.

**States:** empty → *"No trips yet. Log one to see what a journey costs."* + **Add trip**; an open trip (`ended_on` null) pinned at the top with an `Open` chip and a **Finish** action; hundreds → virtualised list with a year separator every January. **Interactions:** row → `trips.edit` (modal); **+** → `trips.edit`; `trips.edit` → `log.expense` with `trip_id` prefilled and locked. **RTL:** distance and cost at the end edge, purpose chip after the title, open-trip badge mirrors. German: `Geschäftlich`, `Arbeitsweg`, `Privat` as purpose chips; chips scroll, so wrapping is never required.

---

## 13. Settings, language, units, notifications, backup and restore

Settings is the fourth tab for one reason: **Export lives here, and the person who needs Export is standing in a phone shop with a dead handset in their pocket.** The tree is shallow, the destructive things are guarded, and Backup is visible without scrolling on the smallest screen in the longest of the six languages.

The file format, import validation and its message catalogue, safety-copy retention and export filenames are in *Backup, export and import*. This section specifies the screens that drive them.

---

### `settings` — Settings (tab root)

**Purpose.** The front door to backup, and the six preferences a real person changes.

```
┌──────────────────────────────────────┐
│ Settings                             │
├──────────────────────────────────────┤
│ Backup & restore                  ›  │
│ Last backup 12 days ago              │
├──────────────────────────────────────┤
│ Vehicles                          ›  │
│ 3 vehicles                           │
├──────────────────────────────────────┤
│ Language                English   ›  │
│ Units & formats     km · L · €    ›  │
│ Notifications          On · 09:00 ›  │
├──────────────────────────────────────┤
│ Appearance                           │
│   [ System ] [ Light ] [ Dark ]      │
├──────────────────────────────────────┤
│ About                     1.4.0   ›  │
└──────────────────────────────────────┘
```

Backup is first, in its own group, with a live subtitle — the only row that ever changes colour. Appearance is inline: one three-valued setting with an instantly visible result.

| State | Backup subtitle | Treatment |
|---|---|---|
| Never exported | "You've never made a backup." | Amber text, amber dot |
| Exported ≤ 90 days | "Last backup 12 days ago" | Secondary text |
| Exported > 90 days | "Last backup 4 months ago" | Amber text, amber dot |
| Migration failed at launch | "Odova couldn't finish updating." | Red; app opened on `settings.backup` |
| One vehicle | Vehicles subtitle reads "The Golf" | — |
| Zero vehicles | Unreachable — the app is in `vehicle.edit` (firstRun) | — |

No empty state and no loading state: every value is a constant or one indexed read.

**Interactions.** Each row pushes. Appearance applies on tap, no confirmation: `Settings.theme` is written and the root rebuilds.

**Data in.** `Settings.theme`, `last_backup_at`, live vehicle count, display names of `language`, `distance_unit`, `volume_unit`, `currency_default`, `notification_time`, OS permission state for the "On / Off" word. **Data out.** `Settings.theme`.

**Navigation.** From tab 4, and from `vehicle.switcher` → "Manage vehicles" (which pushes `vehicles` into the *current* tab's stack, not this one). Pushes `settings.backup`, `vehicles`, `settings.language`, `settings.units`, `settings.notifications`, `settings.about`. Re-tapping tab 4 pops here; again scrolls to top. Android back goes to the Home tab.

**RTL and l10n.** Rows are `start: label, end: value + chevron`; the chevron mirrors. Values are isolate-wrapped — "km · L · €" otherwise drags the currency symbol to the wrong end. German is the width constraint ("Sicherung & Wiederherstellung", "Einheiten & Formate"): rows wrap the label to two lines and drop the value to a third rather than truncate, and at 200% scale every row is two or three lines. "1.4.0" stays Latin digits regardless of `numerals` — a version string, not a number.

---

### `settings.language` — Language (push; also the app's first screen in firstRun)

**Purpose.** Choose one of six. Opened once ever by almost everyone — and in a panic by whoever's second-hand phone boots in a language they can't read.

```
┌──────────────────────────────────────┐
│ ‹  Language                          │
├──────────────────────────────────────┤
│   System (English)                ✓  │
│   English                            │
│   Deutsch                            │
│   Français                           │
│   فارسی                              │
│   العربية                            │
│   کوردیی ناوەندی                     │
├──────────────────────────────────────┤
│ Odova is translated into these six.  │
│ Numbers, dates and units are set     │
│ separately under Units & formats.    │
└──────────────────────────────────────┘
```

No search, no flags — flags are wrong for ar (twenty-two countries), fa (two) and ckb (no state). Each name is in its own script and **never translated**: people scan for the shape of their own writing, not for "Persian" in German. The first row is `language = system`, the parenthesis naming what it resolves to, updated live. Subtag resolution is in *Languages, RTL and formats*.

**States.** Loaded only. In **firstRun**: no back affordance, a full-width **Continue** pinned to the bottom, and beneath it a text button **"Moving from another phone? Restore a backup"** → OS document picker → `settings.import`, empty-device variant — offered here as well as on `vehicle.edit` because language is restored from the file anyway. The trailing paragraph is omitted; there is no Units screen to point at yet. When the device language is none of the six, `System (English)` is preselected with one line beneath the list: "Odova isn't translated into {device_language} yet. Numbers, dates, units and money will still follow your region." — an ICU message with the language name in its own language.

**Interactions.** Tapping a row applies the language **immediately** in both modes — strings, direction, font stack, notification bodies. Not on Continue, not on back: the user must see the result while the list is still on screen. Applying also:

1. Rebuilds from the root, preserving the navigation stack and any in-progress form input in a modal underneath. The app never restarts.
2. Cancels every pending notification, re-renders each body, reschedules — bodies are baked into the OS at schedule time, so a switch otherwise leaves German text arriving on a Persian phone for four months.
3. In **firstRun only**, seeds the seven format defaults (`numerals`, `calendar`, `first_day_of_week`, the three units, `currency_default`) from the resolved *region*, not the language — the region table is in *Languages, RTL and formats*. Afterwards they are independent settings and a language change never touches them: someone in Berlin switching to Arabic still wants kilometres, euros and Monday.

**Data in.** `Settings.language`. **Data out.** `Settings.language`; in firstRun the seven seeded defaults. `onboarding_done` is set on `vehicle.edit` Save, or set to true by the successful import, not read from the file; never here.

**Navigation.** From `settings` (push, back returns); or launch in firstRun → Continue → `vehicle.edit` (firstRun), or → `settings.import` via Restore a backup. A later launch with zero vehicles goes straight to `vehicle.edit`.

**RTL and l10n.** Each name is isolate-wrapped so فارسی in an English list does not pull the tick to the wrong side, and renders in its own font (Vazirmatn for the Arabic-script three) so the list is legible before you can read a word of it. Rows follow the *current* UI direction and do not each flip their own alignment. Crossing between LTR and RTL cross-fades — a slide in the direction that is about to reverse is nauseating.

---

### `settings.units` — Units & formats (push)

**Purpose.** Distance, volume, consumption, currency, calendar, numerals, week start.

```
┌──────────────────────────────────────┐
│ ‹  Units & formats                   │
├──────────────────────────────────────┤
│  PREVIEW                             │
│  12 Mar 2026 · 142,380 km            │
│  38.42 L · €68.90 · 6.4 L/100 km     │
├──────────────────────────────────────┤
│ MEASUREMENT                          │
│ Distance          Kilometres (km) ›  │
│ Volume                Litres (L)  ›  │
│ Consumption           L/100 km    ›  │
│ Currency              Euro (EUR)  ›  │
├──────────────────────────────────────┤
│ DATES AND NUMBERS                    │
│ Calendar              Gregorian   ›  │
│ Numerals              Automatic   ›  │
│ First day of week        Monday   ›  │
├──────────────────────────────────────┤
│ These change how Odova shows your    │
│ records. Nothing you've already      │
│ entered is altered.                  │
└──────────────────────────────────────┘
```

The preview is the whole design: nobody knows what "km/L" looks like beside a Jalali date in Persian numerals until they see it. The options behind each row and their region defaults are in *Languages, RTL and formats*; the unit enums are in *Domain model and rules*. Calendar offers exactly two rows, **Gregorian** and **Jalali** (`gregorian` | `persian`) — Hijri is not offered in v1 and is not a storable value. Numerals offers exactly three rows over the four stored values: **Automatic** (`auto`), **Latin (0-9)** (`latin`), and **Local**, which resolves to `extended_arabic_indic` (۰-۹) for fa and ckb and `arabic_indic` (٠-٩) for ar.

**States.** Loaded only. The currency row opens a searchable sheet, scrolled to the current selection, up to three "Recent" entries above the full A–Z list, matching on code and localised name ("EUR", "Euro", "يورو"). A sheet, not a push, so no branch reaches three deep.

**Interactions.** Every row applies on selection; the preview updates in the same frame. A distance + volume pair *suggests* a consumption unit (km + L → L/100 km; mi + gal US → MPG US) with the note "Suggested for kilometres and litres", and never overrides an explicit choice again. Changing `currency_default` affects **what new vehicles and new money entries default to, and nothing else** — no stored amount is rewritten, no exchange rate is ever applied; the currency sheet's own footer repeats it: "Amounts you've already entered keep the currency you entered them in." Changing units, numerals or calendar triggers the same cancel-and-reschedule as a language change.

Per-vehicle overrides are **not** here; they live on `vehicle.edit`. The footer does not mention them — the 95% of users with one vehicle should never learn the concept.

**Data in / out.** `distance_unit`, `volume_unit`, `consumption_unit`, `currency_default`, `currency_display`, `calendar`, `numerals`, `first_day_of_week`. Writes no records, ever.

**RTL and l10n.** The preview is the hardest bidi in the app. Each value is one atomic isolate-wrapped run — number and unit never split across placeholders — and the separators (`·`) live in the translated string. In fa with Local numerals: `۱۲ اسفند ۱۴۰۴ · ۱۴۲٬۳۸۰ کیلومتر`. Currency codes stay Latin and LTR inside their isolate; unit abbreviations come from our ARB files, not the platform unit formatter. "Maßeinheiten und Formate" is the two-line German title.

---

### `settings.notifications` — Notifications (push)

**Purpose.** Delivery time, quiet hours, the three categories, lead times, the calendar export.

```
┌──────────────────────────────────────┐
│ ‹  Notifications                     │
├──────────────────────────────────────┤
│ WHAT ODOVA SENDS                     │
│ Service reminders             [ ● ]  │
│ Odometer check-ins            [ ● ]  │
│ Backup reminders              [ ● ]  │
├──────────────────────────────────────┤
│ WHEN                                 │
│ Time of day               09:00   ›  │
│ Quiet hours         21:00–08:00   ›  │
│ Weekdays only                 [ ○ ]  │
├──────────────────────────────────────┤
│ HOW FAR AHEAD                        │
│ By distance            Automatic  ›  │
│ By time                Automatic  ›  │
├──────────────────────────────────────┤
│ Add reminders to my calendar      ›  │
├──────────────────────────────────────┤
│ Odova sends at most two              │
│ notifications a week, and never      │
│ more than one a day.                 │
└──────────────────────────────────────┘
```

The footer states the cap as a fact, not a setting — it is the promise made in the pre-prompt. Scheduling, the cap, snooze and done-rollover are in *Reminders and notifications*.

| State | What changes |
|---|---|
| Permission never asked | Card: "Reminders are off." + **Turn on reminders** → the pre-prompt. Rows below stay live: a user may set 07:00 before granting. |
| Permission denied (OS) | Card: "Odova can't send reminders because notifications are turned off for Odova in your phone's settings." + **Open phone settings**. Rows stay editable; the calendar row moves *above* WHEN, now the useful thing here. |
| Declined in-app three times | As denied, and no prompt appears anywhere again. This screen is the only remaining door. |
| Three deliveries unconfirmed in a row | One-time card: "Your phone may be stopping Odova's reminders. Allow Odova to run in the background to fix it." + a button opening the OEM autostart/battery screen, falling back to app info. Outcome recorded so it is asked once; never on Home. |
| All three categories off | Footer becomes "Odova won't send you anything. What's due still shows on the home screen." No nag, no banner elsewhere. |

**Interactions.**

- **Service reminders / Odometer check-ins / Backup reminders** — three channels, three switches. Off cancels that channel's pending notifications; on triggers a full schedule rebuild. Per-*reminder* on/off lives on `reminders.edit`; this screen does not list eighteen service items.
- **Time of day** — one app-wide time, default 09:00, written to `notification_time` as local wall-clock.
- **Quiet hours** — from/to pair, default 21:00–08:00. from = to disables them and the row reads "Off".
- **Weekdays only** — off by default; uses the locale's weekend definition, and the subtitle names the days it will skip so the user sees which one it picked.
- **How far ahead** — `Automatic` means `notice_distance_m` / `notice_days` are null and each item computes its own notice window. Explicit: 500 km / 1,000 km / 2,000 km (300 / 600 / 1,200 mi for a miles user, defined per unit system, never converted) and 7 / 14 / 30 days. Both rows carry "Automatic: about 10% before it's due."
- **Add reminders to my calendar** — an offline `.ics` snapshot of every active reminder's projected due date as all-day events with a 14-day alarm, handed to the share sheet. Beneath the row: "A snapshot, not a live calendar. Export again after you log a service." It sits here, not on `settings.backup`, because it substitutes for notifications — and because the Export screen offers exactly four outputs.

**The permission pre-prompt** is a sheet owned by this screen, not an addressable screen, presentable from anywhere at a moment of intent. Its copy, triggers and re-show cadence are in *Reminders and notifications*; only **Turn on reminders** ever raises the OS dialog.

**Data in.** `notification_time`, `notice_distance_m`, `notice_days`, `notify_service`, `notify_odometer`, `notify_backup`, `quiet_hours_from`, `quiet_hours_to`, `weekdays_only`, OS permission state. The `scheduled_notifications` table is never displayed — an inbox of "notifications you will get in March" is a debugging tool. **Data out.** All of the above, plus a schedule rebuild on every write.

**RTL and l10n.** "21:00–08:00" is one isolate-wrapped run so the en-dash does not fly to the other end; in Persian numerals `۲۱:۰۰–۰۸:۰۰`, same visual order — clock times are LTR sequences even in RTL. Switches sit at the row **end** and mirror. "Nur an Wochentagen" and "Benachrichtigungszeit" wrap to two lines; the three category labels carry a 22-character budget in ARB metadata.

---

### `settings.backup` — Backup & restore (push)

**Purpose.** Get your data out, get it back in, and destroy it deliberately. The most important screen after Home.

```
┌──────────────────────────────────────┐
│ ‹  Backup & restore                  │
├──────────────────────────────────────┤
│  Last backup                         │
│  11 April 2026 — 4 months ago    ⚠   │
│  You've added 214 entries since.     │
│                                      │
│  [        Back up now         ]      │
├──────────────────────────────────────┤
│ Your backup file is not password-    │
│ protected. Anyone who opens it can   │
│ read everything in it.               │
├──────────────────────────────────────┤
│ ALSO EXPORT                          │
│ Fill-ups (CSV)                    ›  │
│ All costs (CSV)                   ›  │
│ Service history (PDF)             ›  │
├──────────────────────────────────────┤
│ RESTORE                              │
│ Restore from a backup             ›  │
│ Undo last import                  ›  │
│ Until 3 October                      │
├──────────────────────────────────────┤
│ Odova is using 4.2 MB on this phone. │
├──────────────────────────────────────┤
│ Delete all data                   ›  │
└──────────────────────────────────────┘
```

"Back up now" is the only filled button and it clears the fold at 200% text scale in German. The unencrypted warning sits directly beneath it — not in a footnote, not behind an info icon.

| State | Presentation |
|---|---|
| Never backed up | "You've never made a backup." + "68 entries are only on this phone." Amber. |
| Backed up ≤ 90 days | "Last backup 11 April 2026 — 12 days ago". Neutral. Count line hidden below 20 new entries. |
| Backed up > 90 days | Amber, ⚠ glyph, count line always shown. |
| No safety copy of a kind | That Undo row is absent entirely, not greyed. |
| Safety copy from a wipe | Row reads "Undo delete all data", 30-day expiry, beside "Undo last import" when both exist. |
| Migration failed at launch | Red banner above everything: "Odova couldn't finish updating and has gone back to your previous data. You can't add new entries until this is fixed — back up now." Only **Back up now** and the CSV/PDF rows are enabled; Restore and Delete are disabled, and export runs through the retained reader for the old `schema_version`, never the code that just failed. The one screen the app may open on instead of `home`. |
| Zero entries | "Back up now" disabled, subtitle "Nothing to back up yet." CSV and PDF rows hidden. |

One Undo row per safety copy that exists, each showing its expiry, plus the line that safety copies go when Odova is uninstalled.

**Export flow.** **Back up now** → an inline progress state replaces the button ("Preparing your backup…") → the file goes to a temp path → the OS share/save sheet opens. `last_backup_at` is stamped on the sheet's completion or dismissal — **on hand-off, not on confirmed save**, because the OS never tells us what the user did with the file. Nothing is ever exported automatically or in the background.

CSV and PDF rows behave identically, each preceded by a vehicle picker sheet when there is more than one vehicle (plus "All vehicles" for the costs CSV). The PDF is the only output rendered in the user's language, calendar and numerals; it hides plate and VIN behind an explicit toggle.

| Export error | Message | Actions |
|---|---|---|
| Not enough free space | "There isn't enough free space to make a backup. It needs about 6 MB. Free up some space and try again." | OK |
| Write failed, any other cause | "Odova couldn't finish the backup. Nothing on this phone has changed. Try again in a moment." | Try again · Cancel |
| No share mechanism available | "This phone won't let Odova hand the file to another app. Your data is safe — try again after restarting your phone." | OK |

**Delete all data.** Last row, separated, in the destructive colour. Tapping writes the wipe safety copy first, then opens `dialog.confirmDelete` in its typed variant:

```
┌──────────────────────────────────────┐
│  Delete everything?                  │
│                                      │
│  This removes 3 vehicles and 3,006   │
│  entries, going back to March 2018.  │
│                                      │
│  A copy is saved on this phone for   │
│  30 days, so you can undo this.      │
│  It is removed if you uninstall      │
│  Odova.                              │
│                                      │
│  Type DELETE to confirm              │
│  ┌────────────────────────────────┐  │
│  │                                │  │
│  └────────────────────────────────┘  │
│                                      │
│      [ Cancel ]   [ Delete ]         │
└──────────────────────────────────────┘
```

The word to type is the localised imperative shown verbatim in the sentence above the field (`LÖSCHEN`, `SUPPRIMER`, `حذف`, `سڕینەوە`), matched case-insensitively after Unicode normalisation; **Delete** stays disabled until it matches. On confirm the store is wiped, notifications are cancelled, and the app routes to `vehicle.edit` (firstRun). Language, and only language, survives — we are not asking someone who just wiped their data to find their alphabet again.

**Data in.** `last_backup_at`, `last_backup_reminder_at`, live counts by type, on-disk size, which safety copies exist and when they expire. **Data out.** `last_backup_at`; the safety copy; on delete-all, everything.

**Navigation.** From `settings`. Reaches the OS share sheet, the OS document picker → `settings.import`, and `dialog.confirmDelete`. Reached by launch when a migration fails.

**RTL and l10n.** Filenames are ASCII Latin, forced LTR, start-aligned inside an RTL layout, monospace, so `odova-backup-2026-09-02-1412.json` never reverses. Sizes and counts are digit-shaped per `numerals`; the date follows `calendar` (`۲۲ فروردین ۱۴۰۵` in fa). The unencrypted-file line and "Everything now in Odova will be replaced by this file" are the two most heavily reviewed strings in the app — single ICU messages, no concatenation. "Sicherung & Wiederherstellung" is the two-line German title.

---

### `settings.import` — Import (modal, blocking)

**Purpose.** Show exactly what is in the chosen file and what it will do, then do it.

Import **replaces everything**. No merge, no append, no per-record picker in v1. One sentence on this screen says so and it is not softened.

**Flow.** `settings.backup` → Restore from a backup, or either firstRun screen → Restore a backup → OS document picker → this modal. A cancelled picker returns to its caller with nothing changed. **Nothing is written before Confirm.** The preview cannot be skipped and has no "don't show this again".

```
┌──────────────────────────────────────┐
│ ✕   Restore                          │
├──────────────────────────────────────┤
│ odova-backup-2026-04-11-0930.json    │
│ Made on 11 April 2026 at 09:30       │
├──────────────────────────────────────┤
│ WHAT'S IN THIS FILE                  │
│   Golf                   214 entries │
│   Van                    388 entries │
│   Recovered records        3 entries │
│   Entries from Mar 2018 to Apr 2026  │
├──────────────────────────────────────┤
│ NOW              →              AFTER│
│   Vehicles          1     →        3 │
│   Fill-ups        412     →      388 │
│   Services         37     →       41 │
│   Expenses         58     →       96 │
│   Trips             9     →       14 │
│   Reminders        18     →       22 │
├──────────────────────────────────────┤
│ ⚠  3 entries can't be read and will  │
│    be left out.        See which  ›  │
│ ⚠  3 entries aren't attached to any  │
│    vehicle. They'll go into a        │
│    vehicle called "Recovered         │
│    records".                         │
├──────────────────────────────────────┤
│ Everything now in Odova will be      │
│ replaced by this file.               │
│ A copy of what you have now is saved │
│ first. You can undo this for 30 days.│
├──────────────────────────────────────┤
│  [      Replace my data      ]       │
│  [         Cancel            ]       │
└──────────────────────────────────────┘
```

Numbers that go **down** render amber — losing 24 fill-ups must not look like the other rows. "Recovered records" is `import.recoveredVehicleName`, localised.

**Three variants of the preview.**

- **Empty device** (fresh install, post-reset, either firstRun screen): the comparison collapses to a single "After" column, the sentence becomes "Odova is empty, so nothing will be replaced." and the button reads **Import**. On confirm it dismisses to `home` with the restored active vehicle; `onboarding_done` is set to true by the successful import, not read from the file.
- **Already restored this file** — `content_hash` matches the last successful import and nothing has been written since: the comparison becomes "**This is the backup you already restored.** Nothing on this phone will change.", the primary button becomes **Done**, **Replace anyway** sits beneath as a text button. Re-importing in a panic must not spend the safety copy holding the user's real data.
- **Undo last import / Undo delete all data** — the same flow against a safety copy, header "The data you had before 2 September 2026, 14:12", same Replace/Cancel pair, expiring after 30 days.

Warnings are advisory and never block. "See which" opens an inline disclosure listing each skipped entry as type, date and plain reason — "Fill-up · 12 Jan 2021 · the date is missing". Validation order and every message are in *Backup, export and import*; none shows an identifier or the words JSON, schema, parse or row.

**Confirming.** **Replace my data** raises no second dialog — the preview *is* the confirmation. The modal switches to a non-cancellable progress state and swipe-down dismissal is disabled from here:

```
        Restoring

   Saving a copy of your data…
   ▓▓▓▓▓▓▓▓░░░░░░░░░░░  1,240 / 3,006

   Don't close Odova.
```

The write is atomic (*Backup, export and import* §4.1), so a crash mid-import leaves the old data intact; the next launch opens on `home` with a snackbar: "Your last restore didn't finish. Nothing was changed."

**Result.** With zero skipped entries the modal dismisses itself, every tab stack resets, Home is selected, notifications are rescheduled from the imported data, and a snackbar reads "Restored. 3 vehicles, 3,006 entries." Preferences from the file **are** applied — language, direction, units, calendar, numerals, notification time — restoring onto a new phone should give you back the app you had, not a German one.

With skipped entries the modal holds on a result state instead — "Restored. 3,003 entries. 3 were left out." with the same list and a **Done** button: a snackbar cannot carry a list, and a count that quietly dropped three things must be acknowledged by a tap.

**Data in.** The chosen file (read-only) and live counts for the comparison. **Data out.** On confirm: the whole store, `Settings` from the file, the safety copy, the notification schedule.

**Navigation.** From `settings.backup` or either firstRun screen via the OS picker. Cancel / back / swipe-down returns to the caller with nothing written, until the progress state begins. Confirm exits to `home` with all four stacks reset.

**RTL and l10n.** The NOW → AFTER arrow mirrors to ← and the columns swap; labels stay at the start edge. Counts are digit-shaped; the filename and its timestamp are forced LTR. "3 entries can't be read" is an ICU plural with all six Arabic categories authored and an explicit `=0` never rendered here. German pushes "Alles, was jetzt in Odova ist, wird durch diese Datei ersetzt" to three lines at 200% scale — no fixed height on the sentence block, buttons pinned below a scrollable body.

---

### `settings.about` — About (push)

**Purpose.** Version, the privacy statement in plain words, licences.

```
┌──────────────────────────────────────┐
│ ‹  About                             │
├──────────────────────────────────────┤
│              Odova                   │
│         Version 1.4.0 (312)          │
│           Backup format 1            │
├──────────────────────────────────────┤
│ No account. No sign-up.              │
│ No server. Nothing is uploaded.      │
│ No tracking, no analytics, no ads.   │
│ Odova has no way to reach the        │
│ internet and never asks for it.      │
│                                      │
│ Everything you enter stays on this   │
│ phone until you export it yourself.  │
│ If you lose the phone without a      │
│ backup, the records are gone — that  │
│ is the trade for keeping them        │
│ private.                             │
├──────────────────────────────────────┤
│ Open source licences              ›  │
├──────────────────────────────────────┤
│ Made for people who keep their cars. │
└──────────────────────────────────────┘
```

The sentence about losing the phone stays in: an app that promises privacy without naming its cost is selling something.

"Backup format 1" is `SUPPORTED_FORMAT_VERSION` — the number that actually appears in the file, so a user asked which format their backup is can read it here and find it there. The store's internal schema version is not shown; the user cannot act on it.

**States.** Loaded only. Licences pushes an offline scrolling text view (Vazirmatn — SIL Open Font License 1.1, plus platform dependencies) from a bundled file. No network, no links out, no "check for updates".

**Deliberately absent:** rate this app, share Odova, contact support, privacy policy link, terms, restore purchases, debug menu. Each needs a network or a business model, and Odova has neither.

**Data in.** Build constants and `SUPPORTED_FORMAT_VERSION`. **Data out.** Nothing.

**RTL and l10n.** Version and build numbers are Latin digits, forced LTR. The privacy paragraph is the longest translated block in the app: no fixed height, and the 1.55–1.70 line-height multiplier in RTL locales. Licence text is English by convention and renders LTR-forced inside an RTL screen.

---

### What is not in Settings, and why

Every row added pushes Export further from the eye. The rule: **a setting earns a row only if a real user would change it more than once and there is no correct default.**

| Not in Settings | Where instead | Why |
|---|---|---|
| Account, profile, sign-in, sync, cloud backup | Nowhere | No account, no server. "Sync (coming soon)" is a promise we decided not to make. |
| Analytics / crash-reporting toggle | Nowhere | Nothing to toggle; a switch implies the capability exists. |
| Per-vehicle currency, units, notice defaults | `vehicle.edit` | They belong to the car, and here they would need a vehicle picker atop Settings. |
| Which reminders are on, and their intervals | `reminders.list` → `reminders.edit` | Per vehicle, and there are eighteen. A defaults editor here would be a second source of truth. |
| Default fuel grade, default station, "remember last odometer" | The log forms, which prefill from the last entry | A preference for what the app can observe is one the user shouldn't have to set. |
| Text size, bold text, reduce motion, high contrast | OS accessibility settings | We honour them, we do not duplicate them. |
| Home screen layout, card ordering | Nowhere | Home answers one question. If its order needs configuring, its order is wrong. |
| Exchange rates, currency conversion | Nowhere | No network, ever. A hand-entered rate silently rewrites the value of someone's service history. |
| Import history, past backups, a file browser | Nowhere | We don't know where the user's files are. The OS picker is the file browser. |
| "Recently deleted" / trash | Nowhere in v1 | Delete is immediate with an in-the-moment undo; safety copies cover the three whole-store operations — migration, import, wipe. |
| Advanced, Experimental, Developer, Labs | Nowhere in release builds | Debug tools are compiled out, not hidden behind seven taps on the version number. |

---

### Cross-cutting rules for this section

1. **Every write on every settings screen applies immediately.** No Save button exists in Settings, so `dialog.discard` never fires from a settings screen — it belongs to `vehicle.edit` and the log modals.
2. **Settings changes that alter text force a notification rebuild:** language, numerals, calendar, units, delivery time, quiet hours, weekdays-only, any channel switch. Bodies are baked into the OS at schedule time, so a setting that changes text must reschedule or it lies.
3. **Only four things destroy data:** a Replace import, Delete all data, a vehicle delete, and a per-entry delete. The first two live on `settings.backup` and each writes a safety copy first; the last two are covered by the in-the-moment Undo only.
4. **No settings or error string is assembled by concatenation.** Every sentence quoted above is one ICU message with named placeholders and its own punctuation.
5. **Every row, switch, chip and sheet item here is at least 48×48 dp (44×44 pt on iOS)**, Appearance segments and currency-sheet rows included.

---

## 14. Edge cases v1 must handle
Decisive rules. Each is a situation the app will meet in its first month.

### Vehicle lifecycle

**Vehicle sold.** `status = sold` plus `sold_on`. It leaves the due engine, all notification scheduling and the staleness nudge immediately; it stays in History, in the export and in `costs` when *All vehicles* is on. Its ownership span ends at `sold_on`, and its row reads "Sold 14 June".

**Vehicle stored or off the road** (winter bike, van between jobs). `status = archived`: same silence as sold, but it can be reactivated and it keeps earning reminders from the day it returns — intervals are not back-dated to cover the storage period.

**Vehicle deleted by accident.** Delete is immediate behind a typed confirmation naming the vehicle and its entry count. Undo lives in the snackbar for 10 seconds. After that, recovery is Settings → Backup & restore → **Undo last change**, live for 30 days — one row that covers import, delete-all *and* vehicle delete. The last three safety copies are kept, not one, so a second mistake does not overwrite the escape route.

**Last vehicle deleted.** Next launch routes straight to `vehicle.edit` in firstRun mode. The language step is not repeated.

**Second-hand car with a service book.** The buyer enters `purchase_odometer` and back-dated service records. Seeded reminders with no anchor report `unknown`, never `overdue`, and never notify — the app does not accuse a new owner of neglect on day one.

**Reminder the user wants gone.** An item that has never been referenced by a service line deletes outright. An item that *has* been is never deletable — the destructive control becomes **Turn this off**. Service history is never destroyed to tidy a reminder list, and every `service_item_id` still resolves.

**Restore on a brand-new phone.** First run has an explicit escape: `vehicle.edit` (firstRun) carries a single text link, *I already have an Odova backup*, which opens `settings.import` in firstRun mode. Without it the most important journey in a no-account app requires inventing a fake vehicle and then wiping it. No new screen id.

### Odometer and data integrity

**Reading lower than its predecessor.** Blocked, with exactly three resolutions: fix the typo; record an `OdometerCorrection` (cluster replaced, rollover); or accept it as a back-dated entry if it fits between neighbours.

**Reading older than the oldest reading.** Accepted without a correction — it becomes the new first reading. Monotonicity is checked against neighbours that exist, not against a floor. This is what a used-car buyer typing "96,000 km, May 2019" is doing, and it is also the recovery path for an assumed anchor.

**Cluster swapped to a different unit.** Not a correction and not a scale factor. Storage is canonical metres; the odometer unit is a per-record fact, and the unit label in `log.odometer` is tappable so a km cluster on a miles car can be entered as km from that date on. `unit_mixup` is removed as a correction reason.

**Odometer not updated for months.** `estimateOdometer` extrapolates for at most 60 days past the newest reading. Beyond that the app stops projecting entirely and shows the last entered value with its date. Ten thousand kilometres of invented number, rendered as something the user can act on, is worse than a blank.

**Distance axis due, but the odometer is stale (>60 days).** Status becomes `needs_odometer`, and the card asks for a reading instead of making an accusation. `due_soon` still shows normally; the time axis is never downgraded this way.

**Very first fill-up.** No consumption figure ever. Show `—` with *your first figure arrives at your next full fill*.

**Partial fill, or a forgotten one.** A partial contributes its volume to the enclosing segment and never opens or closes one. A `chain_broken` fill discards the segment it would have closed — no averaging, no pro-rating — and opens a new one if it was full.

**Segment with zero or negative distance.** Discarded, and both fills are flagged for the user. A nonsense consumption number is never displayed.

**Two fills on the same day, or two at the same odometer.** Both allowed. Ordering within a day is by `created_at`; a zero-distance segment falls out under the rule above.

**Bi-fuel vehicle.** Segments are built per `fuel_kind` independently and the two series are never merged. LPG and petrol are two consumption histories on one car.

**EV where nothing is ever marked full.** Cost per distance only, with one line saying why. "Full" means the driver's usual charge target, not 100%.

**Fill-ups in a second currency.** `costs.fuel` groups by currency exactly as `costs` does. There is no headline price-per-litre that adds euros to pounds — mixed windows show the figures side by side (€1.72/L · £1.48/L) and never a blended one.

**Backup file imported twice.** The preview detects that the file's contents are identical to what is on the device and says so above the NOW→AFTER columns. Because three safety copies are kept, the pre-import state is still recoverable after a second import.

**Damaged or partial backup file.** Records are never silently dropped: unreadable ones are skipped, counted, and listed with type, date and a plain-language reason. Orphans are attached to an auto-created vehicle named **Recovered records**. Type errors reject one record; implausible values do not — the app never "corrects" a user's number for being out of range.

**Backup from a newer app version.** Refused outright, no partial import, with a message telling the user to update Odova. `format_version` is the only gate; the on-device schema version never appears in the file.

**Migration fails on launch.** The app opens `settings.backup` with a banner — but the recovery artefact is the safety copy written *before* migration by the old schema's writer, not a fresh export through the new readers that just failed. Export of the broken store is not offered as the fix.

**Disk full mid-export or mid-import.** Export writes to a temp file and only then hands it to the share sheet; a failed write deletes the temp file and reports it. Import builds the new database beside the old one and swaps; a failed build leaves the old data untouched and reports it.

### Time and dates

**Device clock wrong.** If `today` is before the newest `created_at` or more than 24 hours ahead of it, the app enters clock-suspect mode: date fields default to the newest known date instead of `today`, the `occurred_on ≤ today` block is relaxed to `≤ newest_known + 1 day`, rate calculation is suspended (confidence drops to `assumed`), and one line explains that the phone's date looks wrong. New records are never silently written with a 1970 date.

**Time-zone change or DST.** Fire times are stored as local wall-clock and resolved to an instant at schedule time, so 09:00 stays 09:00 in the new zone. A backwards clock change triggers a full schedule rebuild; a pending notification whose recomputed time is in the past fires at the next delivery slot, never immediately.

**Anniversary on the 29th, 30th or 31st.** Calendar-month arithmetic clamps to the last day of the target month. Intervals are stored in months, never in days.

**Jalali dates.** Display only. Gregorian↔Jalali round-trips over 1300–1500 AP are a ship-blocking test, leap years included. Nothing Jalali ever reaches storage or the export.

**Future dates.** Rejected for fill-ups, service records, odometer readings and trips. Permitted for `Expense.occurred_on`, `Expense.covers_to` and `ServiceItem.target_date` — you can pay an insurance premium that covers next year.

### Language and input

**Device locale outside the six.** English strings plus region-derived formats. A Brazilian phone shows English text with km, L/100 km, BRL and Monday-first weeks. `ku` / `kmr` / `ku-TR` map to English, not to ckb; `fa-AF` and `prs` map to fa; every `ar-*` maps to the single ar string set.

**Digits typed in any script.** Numeric fields accept Latin, Arabic-Indic and Extended Arabic-Indic digits plus `٫ ٬ ، . ,` and space, normalising to one canonical decimal. If the value stays ambiguous (`1,234` — one thousand or one point two three four?), reject with an inline error rather than guess. On blur the field re-renders the canonical formatted value.

**Free text in the wrong direction.** UI chrome takes direction from the locale; notes, workshop names and nicknames take direction from their content, first-strong per paragraph. VIN is forced LTR with start alignment even on an RTL screen. Licence plates are stored and displayed verbatim and are never digit-shaped.

**200% text scale plus the longest translation.** Every screen must survive it with no truncation, clipping or overlap. Buttons wrap to two lines rather than shrink; labels sit above inputs, never beside them; text containers never get fixed pixel heights. Tab labels have a 12-character budget declared in ARB metadata.

**Missing translation.** Falls back to English text, never to the raw key. Debug builds wrap fallbacks in `‹ ›` and emit a MISSING report. No runtime machine translation, ever.

**Language changed with a form half-filled.** The app re-renders from the root without restarting; in-progress input survives the rebuild. Every scheduled notification is cancelled, re-rendered and rescheduled, because its text was baked into the OS at schedule time.

### Storage and scale

**Eight years, twelve thousand records, one vehicle.** History is paged and virtualised, sorted by `(occurred_on desc, id desc)` with the ULID as tiebreak. The month index is built once per data change, not per scroll. Cold launch to first frame on the floor device stays under two seconds with this dataset.

**App killed mid-form.** Drafts are never written to the database. The entry is lost; nothing is corrupted. Dismissing a dirty modal shows `dialog.discard`; a clean one dismisses silently.

**Four vehicles, one household.** Nothing aggregates across vehicles except the home screen's "what's due next" list, the `costs` tab's explicit All-vehicles toggle, and the backup file. Switching the active vehicle resets all four tab stacks; the `costs` toggle never touches `activeVehicleId`.

### Notifications

**Permission never granted.** The app stays fully useful and no feature is gated: Home *is* the notification — overdue at the top, red, sorted by urgency; the app-icon badge carries the due+overdue count; an in-app digest appears once when the app is opened after seven or more days away; and an offline `.ics` export is offered in Settings. One dismissible line in Settings, never a persistent banner.

**Permission asked at the wrong moment.** Never on first launch and never before a vehicle exists. The ask comes after the first reminder with a future due date, or the second odometer/fill-up entry, whichever is first, and only behind an in-app pre-prompt. "Not now" may be re-asked at most twice more, 30 days apart. After the third decline, never again.

**More is due than the cap allows.** Hard global cap: 2 notifications per rolling 7 days, 1 per calendar day, all vehicles combined. Overflow coalesces into one grouped notification per slot, prioritised `overdue2 > overdue1 > due > nudge > early`, ties broken safety > normal > low then nearest due. Anything deferred more than 21 days past its stage is dropped, not queued.

**User does not open the app for eight months.** The 120-day horizon and the 48-slot budget would otherwise run dry in silence. Two backstops: an inexact periodic background rebuild (no network, no exact alarms) re-arms the queue, and the last notification scheduled at the horizon edge is a generic *Open Odova to refresh your reminders* so the queue can never end without a signal.

**OEM background killers.** Xiaomi, Huawei, Oppo, Vivo and Samsung drop alarms for apps that are not whitelisted, and those devices dominate three of our six locales. Detection: on every launch, compare `scheduled_notifications` against the OS pending list; if entries the app believes are pending are absent, show a one-time dismissible Settings row explaining battery-optimisation exclusion with a deep link to the OS setting. Never a modal, never repeated.

**Snoozed forever.** Snooze suppresses notifications only; the item stays red in the app. After three consecutive snoozes the fourth prompt offers *Snooze again / Change the interval / Turn this reminder off*.

**Notification tapped for a deleted vehicle or reminder.** Lands on plain Home with no error message. A deep link always synthesises a back stack of `[home]`, so back never exits the app from a modal.

**Done from a notification.** Writes a service record with `odometer_estimated = true` using the projected odometer, then shows a prefilled, editable confirmation card the next time the app is opened, including the resulting new due date and due odometer. The flag is visible in service history and present in the export. The record carries one line with `amount = 0`, never a null cost — a record with no line cannot exist.

**Swiping a notification away.** Changes nothing. No data write, no state change, later stages still fire.

---

## 15. Explicitly out of v1
Each of these is tempting, and each is out for a stated reason.

| Not building | Why |
|---|---|
| **Cloud sync, accounts, multi-device** | Contradicts the first non-negotiable. The backup file is the sync mechanism, operated by hand. |
| **Sharing a vehicle between family members** | Requires a server, an identity model and conflict resolution. Two people can share one backup file and one phone. |
| **OBD-II / Bluetooth dongles** | A hardware compatibility matrix, a permission, a background service and a support burden, for a number the user can read off the dash in three seconds. |
| **Receipt OCR / photo capture of invoices** | An attachment store is a second durability problem and a second privacy story. It also fails silently on Persian and Arabic receipts, which is exactly where we cannot afford it. |
| **Fuel-price lookup, nearby stations, price comparison** | Network call. |
| **VIN decoding, manufacturer service schedules, recall data** | Every one is a licensed online database. The catalogue ships as *starting points, not manufacturer advice — your handbook wins*, and that is an honest position we can hold offline. |
| **Maps, geocoding, GPS trip tracking, automatic trip detection** | Network, permissions, battery, and a location-history file on a device we promised keeps nothing. Trips store free-text place names. |
| **Analytics, crash reporting, remote config, A/B tests** | No network calls of any kind. This is also why the projection accuracy target below can never be measured in the field. |
| **CSV import** | Every source app has a different shape; the mapping UI is bigger than the rest of Settings. CSV is export-only. |
| **Merge import, per-record conflict pickers, partial restore** | See non-negotiables. Replace is the only semantic an ordinary driver can be asked to understand. |
| **Encrypted or password-protected backups** | Deliberate. A forgotten password destroys the history five years from now, and we have no reset path. |
| **Summer/winter tyre sets, per-axle brake tracking, tyre pressure logs** | A tyre *set* is an entity, not a field, and v1 has a single tyre interval. Noted as a known non-retrofit. |
| **Recurring-expense generation** | An annual premium is one row with a coverage window; the monthly view amortises it. Generated rows would need reconciling forever. |
| **Widgets, watch apps, Android Auto / CarPlay, tablet layouts** | v1 targets a phone screen from 375×667 up. Everything else waits for evidence. |
| **Free-text search** | Type + date-range chips beat a search box on a maintenance log, and search means normalisation across three digit sets and six locales. |
| **Hijri display calendar** | Gregorian and Jalali only. No evidence anyone schedules an oil change by Hijri date. |

## 16. Version two
- **A tyre-set entity** — summer/winter, per-set mileage, storage location. The one thing v1 cannot retrofit cheaply.
- **Photo attachments** with a proper media store, export inclusion and a size budget. Receipts and the invoice a buyer wants to see are the top request we are knowingly declining.
- **A merge import**, once there is evidence of the two-phone case being real, with per-vehicle rather than per-record granularity.
- **Reminders promoted for high-frequency users** — trips as a tab root for rideshare and delivery drivers, who log several a day and currently reach them two taps deep under Costs.
- **A per-vehicle severe-service profile** derived from measured daily distance rather than from a yes/no question at onboarding.
- **Warranty and roadside-assistance expiry** as first-class date-only items.
- **A local-only accuracy self-check screen**, so a curious user can see how far the projection missed, since we can never measure it in aggregate.
- **Front/rear brake split**, if v1's single item proves too coarse in practice.

## 17. Definition of done for v1
An engineer should be able to run this list and get a yes or no on every line.

**Targets.** iOS 15+, Android 8.0 (API 26)+. Floor device: a 2019 mid-range Android (4 GB RAM, eMMC storage) — every budget below is measured on it, not on a flagship. Minimum screen 375×667 logical points. One floor, used everywhere.

**Functional gates**
- [ ] Fill-up, service, expense and odometer entry all reachable from the central `+` in one tap, saved in under 15 seconds each on the floor device, with the caller screen and scroll position restored.
- [ ] The due engine passes a fixture suite covering every combination of `{distance-only, time-only, both} × {ok, due_soon, due, overdue, unknown, needs_odometer, paused}`, including grace bands and the axis that drove the status.
- [ ] The fuel engine passes a fixture suite covering: first fill, partials, `chain_broken`, missing odometer on an imported row, zero and negative segments, bi-fuel, EV with and without full charges, and lifetime average computed as total/total rather than a mean of segments.
- [ ] `add_months` clamps correctly on the 29th/30th/31st across leap years.
- [ ] No screen stack exceeds two pushes under its tab root.

**Data-safety gate** (the one that blocks a release on its own)
- [ ] Export → wipe → import produces a byte-identical export on the second pass, ignoring only `exported_at`, `exported_at_local`, `app_version`, `app_build` and `content_hash`. That exception list is the contract; the "two exports diff cleanly" claim is stated with it or not at all.
- [ ] A vehicle with an `OdometerCorrection` round-trips with identical lifetime distance, identical fuel segments, identical daily rate and identical projected due dates. Corrections have an array in the file.
- [ ] Every field the app branches on survives a round trip: `vehicle_type`, `is_business`, `status` + `sold_on` + `sold_price`, `expected_annual_m`, per-vehicle notice overrides, per-vehicle unit and currency overrides expressed as null-means-inherit, `odometer_estimated`, `rollover`, `priority`, `notify`, snooze state.
- [ ] Upgrade from every shipped schema version to current, over a 12,000-record database, completes under 3 seconds on the floor device with zero record loss; a pre-migration safety copy exists and is restorable.
- [ ] Simulated crash at each of five points during import leaves the previous database intact and usable.
- [ ] A file with a newer `format_version` is refused with no partial write.
- [ ] A file with 5% damaged records imports the rest, lists every skipped record with a plain-language reason, and attaches orphans to **Recovered records**.

**Per-locale gate** — run for all six of en, de, fr, fa, ar, ckb, plus the pseudo-locales en-XA and ar-XB
- [ ] Screenshot goldens: 6 locales × 8 core screens, reviewed on every UI change. The RTL pass is signed off by a native fa reader and a native ar reader against the explicit mirroring checklist.
- [ ] Font coverage test: every codepoint in the fa/ar/ckb ARB files has a real glyph in all four joining forms, `ڕ ڵ ۆ ێ ھ ە چ ژ گ پ ک ی` included.
- [ ] Zero glyph clipping at 200% text scale on every screen, in every locale.
- [ ] Plural matrix passes for n ∈ {0,1,2,3,10,11,20,99,100,101,102,103,110,1000} in all six locales, with explicit `=0` cases wherever the empty state differs.
- [ ] Number round-trip per numbering system (latn, arab, extarab), including input normalisation and the ambiguous-separator rejection.
- [ ] Gregorian↔Jalali round-trip over 1300–1500 AP.
- [ ] Locale switch preserves in-progress form input and rebuilds every scheduled notification with re-rendered text.
- [ ] Cross-locale export/import identity: a file exported under fa-IR with Jalali display and extarab numerals imports identically under en-US.
- [ ] CI is red on: dead keys, mismatched placeholders, unparseable ICU, missing CLDR plural categories, hard-coded user-visible literals, and any `left`/`right` outside the icon-asset layer.

**Scale gate** — dataset: 4 vehicles, 8 years, 12,000 records, 900 service records, 60 reminders
- [ ] Cold launch to interactive Home under 2.0 s.
- [ ] History scroll holds 60 fps with no jank frame over 32 ms.
- [ ] `costs` full recompute under 400 ms; `costs.fuel` under 400 ms.
- [ ] Export completes under 5 s and the file is under 12 MB.
- [ ] Import (validate + preview + swap) under 10 s, with progress shown after 1 s.
- [ ] Peak memory under 250 MB.

**Accessibility gate** — currently the weakest area of this spec and treated as a release blocker, not a polish item
- [ ] Minimum touch target 48×48 dp everywhere, including the odometer stepper and chart tap targets.
- [ ] Estimated values carry a non-visual signal: the `~` prefix is announced as "about", the estimate treatment is exposed as an accessibility label ("about 187,400 kilometres, estimated"), and lighter text still meets 4.5:1 contrast. Never a confidence percentage, bar or tier name in the UI.
- [ ] The `ƒ` computed badge on the fill-up price trio has an accessible name ("calculated from the other two").
- [ ] Both charts have a non-visual alternative: a screen-reader summary and an accessible data table behind one control.
- [ ] Save in the log modal is reachable one-handed on a 6.7" phone — a bottom-anchored action, not a top-corner one. A fill-up is logged at a pump in the rain or the design has failed.
- [ ] Screen-reader language and direction are tagged per element, so a Latin workshop name inside a Persian screen is read in the right language.
- [ ] Full keyboard/switch traversal of every form, with a visible focus indicator.

**Offline gate**
- [ ] The binary contains no HTTP client, no socket usage and no third-party SDK that opens one. A dependency-graph check for networking APIs runs in CI and fails the build.
- [ ] Full manual pass of every screen in aeroplane mode on a device that has never been online.

## 18. Decisions still open
Genuinely unsettled. Each can be closed with one sentence from the right person.

1. **Brake pads: one reminder or two (front/rear)?** Two is technically correct; one matches what a driver expects to see. Currently one, splittable later.
2. **Should the 60-day staleness threshold scale with measured daily distance?** A delivery driver goes stale in two weeks; a weekend car never does. Fixed at 60 days for v1.
3. **Should first run ask "when was the last oil change?"** One extra question buys a real anchor instead of an `unknown` card. Currently no; worth testing against real installs.
4. **Does "do you drive this for work?" earn its place at onboarding?** Its only consumers are a default trip purpose and a costs split. Test against removing it.
5. **Are the heavy-use multipliers right** (oil 7,500 km / 6 months, air filter 15,000 km)? These are our judgement, not a manufacturer severe-service table. Someone with trade data should sanity-check them.
6. **Have the motorbike and EV default sets been reviewed by anyone who owns one?** The car and van sets we are confident about; these two we are not. Chain and sprockets at 1,000 km / 1 month is a real interval that will dominate a bike owner's home screen and may need its own notification treatment.
7. **Should road tax / registration default on in any market?** We have no network and only a device locale; inferring a country from a language is wrong often enough that it is off everywhere. Confirm that is acceptable.
8. **Kurdish Sorani numerals: extarab (۰۱۲۳) or arab (٠١٢٣)?** We default to extarab per the brief; CLDR says arab, and Latin digits are common in print in Iraqi Kurdistan. A native ckb-IQ reviewer settles it before first release.
9. **Should ckb-IR default to the Jalali calendar,** or do Sorani speakers in Iran expect Gregorian in a Kurdish-language app? One native check.
10. **Toman presentation for fa-IR:** confirm with an Iranian user that a 0-decimal Toman-labelled amount reads correctly for both a 40,000 fuel fill and a 12,000,000 service. Storage stays IRR with a display-only divide-by-ten; `IRT` is not ISO 4217 and is not a stored currency.
11. **Sorani translation sourcing.** Professional ckb translators are scarce, and plural and terminology quality in that file is the single largest risk to the RTL launch. Who supplies and who reviews it?
12. **Leave Android auto-backup and the iOS app container backup enabled?** A free safety net that has saved many users' data, but it copies the file to a cloud the user did not explicitly choose — awkward beside "nothing leaves your phone". If it stays on, the privacy copy needs a line about it.
13. **Does the `.ics` calendar export ship in v1?** It is the strongest fallback for a user who denies notifications, and it is a second format to build, translate and test.
14. **Does `report.service` produce PDF, plain text, or both?** It is a share-sheet payload either way, so it does not touch the navigation graph.
15. **Should Costs default the report's cost figures to on?** Total spend is the selling point when selling a car; some sellers do not want a buyer knowing they spent €6,842 on repairs. The toggle exists either way.
16. **Is accrual accounting on the Costs tab worth the confusion?** Amortising insurance is necessary for a stable cost-per-month, but it means Costs and History disagree for the same date range, and one line of copy may not be enough.
17. **Mark-done confirmation: auto-dismiss after 5 seconds or wait for Close?** Auto-dismiss is faster for the common case; a driver marking three items done in a row may find it flickers.
18. **Should the fill-up form offer price-per-unit at all for EV charging,** where many sessions are billed as a flat fee? Today a session fee is entered as total plus kWh.
19. **Should a comparison row in the All-vehicles Costs view be tappable?** The contract makes `vehicle.switcher` the only place selection happens, which leaves a user comparing three cars unable to drill into the expensive one. Cleanest bend: the row opens `vehicle.switcher` preselected.
20. **Should Home offer a one-time "still tracking this?" prompt** at, say, +180 days? Notifications stop at +45 days and the item then stays permanently red, so a genuinely abandoned item can occupy the primary card forever.
21. **Should Home's last-fill-up row open `log.fillup` in edit mode?** It is currently a dead read-out, and the edge costs nothing and matches the pattern `history` and `costs.fuel` already use. Recommend adding it.
22. **Should purchase-anchored `unknown` items be excluded from notification scheduling too,** as they already are from Home's primary card? Otherwise a new user gets notified about eleven items the app is guessing at. Recommend yes.
23. **The delete-all confirmation word** is currently the localised imperative (LÖSCHEN, حذف, سڕینەوە). Typing the entry count instead is language-free but easier to typo. One round of testing with a Sorani reader.
24. **The 64 MB import cap and the 5% / 50-record damage threshold** are engineering guesses. Revisit once we know what damaged files people actually bring.
25. **Calm's light-theme contrast: darken `--color-ink-3`, or keep the softness?** `#8B7B6C` measures 3.67 / 3.99 / 3.42 / 3.02:1 on the four light surfaces against a 4.5 requirement, and it is `color:` in 47 CSS rules, 25 of them at 13–14px. Two further pairs go with it: `--color-ink-3` also fails in **dark** on `surface-2` (4.39) and `surface-3` (3.84), which `design/calm/ACCESSIBILITY-FINDING.md` does not record, and `--color-focus` is 2.82:1 on `surface-3`, below SC 1.4.11's 3:1 for a focus indicator. `#6B5F53` clears all four light surfaces (5.57 / 6.06 / 5.20 / 4.59). §17 calls accessibility a release blocker, so this is not a polish item — but darkening tertiary text is a design judgement about how soft Calm reads, and `CLAUDE.md` §9 assigns the closure to EPIC-17. Until then the failures are dated, executable exceptions in `test/theme/calm/calm_contrast_test.dart`, which goes **red** the day the values change and forces their removal. The cost of deciding grows: today it is two hex values and one re-shoot of the 112 reference PNGs; after EPIC-15 it is that plus a parity re-check of all 28 built screens.
26. **The stated projection accuracy target** (within about three weeks over a twelve-month horizon at `measured` confidence) is derived from the band width, not measured — and the no-analytics constraint means it can never be measured in the field. Accept the uncertainty, or ship the opt-in local self-check screen listed under version two.
