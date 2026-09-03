# EPIC-06 — Units, money and the fuel engine

| | |
|---|---|
| **Epic** | EPIC-06 — Units, money and the fuel engine |
| **Depends on** | EPIC-05 |
| **Estimate** | **14.5 h (CC) · ~3–4 months (human)** across 10 tasks |
| **Spec sections** | §3 Canonical units, §3 Currency, §3 Display conversion and rounding, §3 Fuel maths, §3 Derived values, §12 Ground rules for every number on these screens, §12 `costs.fuel` (The numbers, exactly), §14 Odometer and data integrity (fuel cases), §17 Definition of done (the fuel fixture suite) |
| **Screens** | none |

Everything in this epic is **pure Dart with no Flutter import**, testable in
milliseconds without a widget harness (`CLAUDE.md` → How to work). It is also where the
product's hardest rule lives: *never guess in a way that looks like fact*. A wrong
consumption number is worse than none, because the user will believe it — so most of
the work here is deciding, precisely, **what the engine refuses to compute**.

## Where we are now

EPIC-01 created the Flutter app; EPIC-05 built the store underneath it.

What you inherit:

- A Drift database with all ten SPEC §3 entities as `STRICT` tables, canonical integer
  columns (metres, millilitres, grams, watt-hours, money as integer minor units +
  a three-character ISO 4217 code), `YYYY-MM-DD` event dates and UTC-millis
  bookkeeping times.
- Seven repositories that are the single write path, returning
  `Result<T, PersistFailure>` and exposing vehicle-scoped `.watch()` streams. They map
  rows into immutable domain models in `lib/domain/models/` whose quantity fields are
  **canonical integers with the unit in the name** — `odometerM`, `quantityMl`,
  `quantityG`, `energyWh`, `totalCostMinor` + `currencyCode`. Task 6.2 and Task 6.3
  replace those with value objects at the mapping boundary; the repository is the only
  place that changes.
- `OdometerRepository.cumulativeM` — corrections applied, monotonicity guarded — which
  is what the fuel engine's segment distances are measured with. The fuel engine never
  reads a raw dash number.
- The migration ladder, its committed snapshots and the safety-copy guard.
- `lib/core/ids/` with `RecordId` and the ULID factory, and the injected `Clock` from
  the composition root.

What is deliberately still missing:

- **No `Money`, no `Distance`, no unit conversion.** This epic writes them. Nothing in
  the app formats a number yet.
- **No due engine.** `dailyDistance`, `estimateOdometer`, `resolveAnchor`,
  `computeDueState` and `projectDueDate` belong to the due-engine epic. This epic
  touches distance only through `cumulativeM`.
- **No formatting and no localisation.** Digits, numerals, decimal separators, the
  Jalali calendar and ICU messages are `i18n-rtl-l10n`'s and a later epic's. This epic
  ends at a `double` and an `int`; it never produces a string a user reads. The one
  exception is that the rounding *rules* live here, because rounding is arithmetic and
  formatting is presentation.
- **No screens.** Nothing renders; there is no parity check in the definition of done.

## What we will have when this is done

- `lib/core/` holds a pure foundation with no `package:flutter`, no `dart:io`, no
  `intl` import anywhere in it, proven by `bash tools/check_core_purity.sh`, and
  `flutter test test/core/` runs the whole thing in a couple of seconds.
- Every stored quantity has one canonical type and one conversion path: metres in,
  km or miles out, at render only. Flipping a unit preference changes no stored byte,
  and there is a test that says so.
- Money is integer minor units keyed to each currency's real ISO 4217 exponent, split
  through one `allocate()` primitive so parts always sum to the whole, never added
  across currencies, and never converted — there is no exchange rate anywhere in the
  binary.
- `buildFuelSegments` produces exactly the segments SPEC §3 describes, per `fuel_kind`,
  and returns a typed reason for every fill it refused to build one from. The lifetime
  average is total-over-total.
- A committed fixture suite covering every case in the §17 fuel gate — first fill,
  partials, `chain_broken`, missing odometer on an imported row, zero and negative
  segments, bi-fuel, EV with and without full charges, and lifetime average as
  total/total rather than a mean of segments — that a reviewer can read as a table of
  inputs and expected outputs without opening the engine.

## Skills to load

Open `flutter-conventions-index` first.

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The house rules, and rule 7 in particular: pure functions are **total** — they return uncertainty, never throw. |
| `value-objects-money-and-units` | Owns this epic. Money as minor units keyed to the real ISO-4217 exponent, the `allocate()` primitive, canonical SI storage with conversion at the edge, and the injected `Clock`. |
| `dart3-idioms-and-coding-standards` | Sealed types for the refusal reasons and the fuel-quantity variants, plus the complexity limits the segment builder must stay inside. |
| `error-handling-typed-results` | The engine returns a value for every input; "no number" is an explicit variant, not an exception and not a `null` that a caller renders as `0`. |
| `testing-strategy` | Round-trip tests for every conversion, rounding goldens at the half-way values, seeded fuzz against an independent oracle, and `package:test` for a Flutter-free core. |
| `seeded-determinism-and-golden-vectors` | The §17 fixture suite is a committed golden-vector file with a specified regeneration path, not a pile of ad-hoc expectations. |
| `project-structure-and-packages` | `lib/core/` is the sanctioned pure-foundation layer; this epic must not create a `utils/` or `shared/` grab-bag. |

The rules every epic inherits — TDD without exception, tests run per task, `/simplify`
then `/code-review` at the end, and `SPEC.md` wins over any skill — are stated once in
`epics/README.md`.

## Tasks

### Task 6.1 — The Flutter-free core boundary and its gate

- **Goal** `lib/core/` is provably pure, so everything this epic adds tests in
  milliseconds and can never acquire a `BuildContext`.
- **Spec** §3 Derived values (*deterministic, no I/O, no clock except an injected
  today*); `CLAUDE.md` → How to work.
- **Skills** `project-structure-and-packages`, `testing-strategy`.
- **Write these tests first**
  - `tools/check_gates_selftest.sh` gains a case: planting
    `import 'package:flutter/material.dart';` in a scratch file under `lib/core/`
    makes `tools/check_core_purity.sh` exit non-zero; removing it makes it exit zero.
    Repeat the plant for `dart:io` and `package:intl` — all three are banned in the
    core, and the third is the one people add by accident when they reach for
    formatting.
  - `test/core/core_is_pure_test.dart` — `no file under lib/core imports flutter,
    dart:io, dart:ui or intl`, asserted by reading the directory, so the rule holds
    even when the shell gate is not run.
- **Then build**
  - `lib/core/` subdirectories for this epic: `units/`, `money/`, `fuel/`,
    `rounding/`. No `utils/`, no `common/`, no `helpers/`.
  - `tools/check_core_purity.sh`, wired into CI beside the existing repo gates.
- **Verify**
  ```bash
  bash tools/check_core_purity.sh
  bash tools/check_gates_selftest.sh
  flutter test test/core/core_is_pure_test.dart
  ```
- **Done when**
  - [ ] The purity gate exists, runs in CI, and has been seen to fail on all three
        banned imports.
  - [ ] `lib/core/` has no grab-bag directory.
- **Estimate** 0.5 h (CC) · ~half a week (human)

### Task 6.2 — `Distance`, `Volume`, `Energy`, `Mass`: canonical in, converted on read

- **Goal** Every physical quantity in the app has one canonical integer representation
  and one conversion path, used only at the presentation edge.
- **Spec** §3 Canonical units; §3 Display conversion and rounding.
- **Skills** `value-objects-money-and-units`, `dart3-idioms-and-coding-standards`,
  `testing-strategy`.
- **Write these tests first** — `test/core/units/distance_test.dart`,
  `volume_test.dart`, `energy_test.dart`, `fuel_quantity_test.dart`
  - `whole kilometres round-trip exactly` — `Distance.fromKm(187412).km == 187412`,
    and the canonical value is `187_412_000` metres.
  - `whole miles round-trip exactly` — `1 mi == 1609.344 m`, so
    `Distance.fromMiles(120000).miles == 120000` with no drift. The factor is the
    reason distance is metres and not centimetres.
  - `300,000 km survives arithmetic with no float drift` — sum 3,000 hundred-kilometre
    distances and assert integer equality with `Distance.fromKm(300000)`.
  - `one litre is 1000 mL, one US gallon is 3785.411784 mL, one imperial gallon is
    4546.09 mL` — three cases, asserted on the canonical integer.
  - `kWh is watt-hours times 1000`.
  - `a fuel quantity is exactly one of volume, mass or energy` — a sealed
    `FuelQuantity` with `LiquidVolume`, `GasMass`, `ElectricEnergy`; a `switch` over it
    with no `default:` is exhaustive, which is what makes the fill-up mapper safe.
  - `conversion never happens on write` — a grep-style test over `lib/data/` asserting
    no call to a `.toKm`/`.toMiles`/`.toGallons`/`.toKwh` getter appears there.
    Conversion is a read-time act; a converted value must never reach a column.
  - `changing the display unit leaves the canonical value identical` — build a
    quantity, read it as km, read it as miles, assert the underlying metres are
    unchanged.
  - Seeded fuzz: `for seed in 0..999`, a random metre value converted to miles and back
    stays within one metre, printed in `reason:` so a failure is its own repro.
- **Then build**
  - `lib/core/units/distance.dart` — `Distance` over `int metres`, with
    `Distance.fromKm`, `.fromMiles`, `.metres`, and the `double` getters `km`, `miles`
    used only at the edge.
  - `lib/core/units/volume.dart` — `Volume` over `int millilitres`, with `litres`,
    `gallonsUs`, `gallonsUk`.
  - `lib/core/units/energy.dart` — `Energy` over `int wattHours`, with `kwh`.
  - `lib/core/units/mass.dart` — `Mass` over `int grams`, with `kg`.
  - `lib/core/units/fuel_quantity.dart` — the sealed three-way type, and
    `DistanceUnit`, `VolumeUnit`, `ConsumptionUnit` enums matching the SPEC §3 Enums
    spellings exactly (`km|mi`, `l|gal_us|gal_uk`, the six consumption units).
  - `lib/data/repositories/` mapping updated: `odometerM` becomes `Distance`,
    `quantityMl`/`quantityG`/`energyWh` become one `FuelQuantity`. The repository is the
    only layer touched; the columns do not change.
- **Verify**
  ```bash
  flutter test test/core/units/ test/data/repositories/
  flutter analyze --fatal-infos --fatal-warnings
  bash tools/check_core_purity.sh
  ```
- **Done when**
  - [ ] Every quantity is an `int` canonical plus edge-only `double` getters.
  - [ ] The three volume factors and the mile factor are asserted, not commented.
  - [ ] `lib/data/` calls no conversion getter.
  - [ ] The repository mapping now returns value objects and its tests still pass.
- **Estimate** 1 h (CC) · ~1 week (human)

### Task 6.3 — `Money` and `Currency`: exponents, `allocate()`, and the toman rule

- **Goal** Money is exact, never mixes currencies, and is never converted — because a
  made-up rate silently rewrites the resale value of someone's service history.
- **Spec** §3 Canonical units (Money); §3 Currency; §3 Display conversion and rounding
  (money decimals = the currency exponent); §12 Ground rules (*Money never mixes*).
- **Skills** `value-objects-money-and-units`, `error-handling-typed-results`,
  `testing-strategy`.
- **Write these tests first** — `test/core/money/money_test.dart`,
  `currency_test.dart`, `allocate_test.dart`
  - `the minor unit comes from the ISO 4217 exponent, never a hardcoded 100` — four
    cases: `EUR` 2, `JPY` 0, `KRW` 0, `KWD` 3. A hardcoded 100 is a 100× error on JPY
    and a 10× error on KWD.
  - `an unknown currency code is a typed failure, not a default to two decimals` —
    `Currency.tryParse('XYZ')` returns null and the caller emits a `Failure`.
  - `adding two Money of different currencies is a programmer error` — throws in
    debug; it is never a recoverable failure, because a screen that tries it is wrong.
  - `a total over mixed currencies groups, never sums` — `MoneyTotal` of
    `€1,240` and `£80` yields a `Map<Currency, int>` with two entries, and its
    dominant-currency getter picks the one with the most rows, per §12.
  - `allocate distributes the residual by largest remainder and the parts sum to the
    whole` — `allocate(1200_00, weights: 365 days)` sums to exactly `120000` minor
    units. 1,200.00 EUR over 365 days never becomes 1,199.99.
  - `allocate is stable for equal weights` — the residual goes to the earliest parts,
    deterministically, so two runs agree.
  - `a percentage is rounded to minor units once, before allocate` — the two-rounding-
    sites trap; a naive double percent fed to `allocate` is a classic off-by-a-cent bug
    that `allocate` coverage alone will not catch.
  - `toman is a display divide-by-ten and never a stored code` — `IRR` stays the stored
    currency; with `currency_display = toman` the *render* value is a tenth; the string
    `IRT` appears nowhere in the codebase, asserted by a grep test.
  - `there is no exchange rate anywhere` — a grep test over `lib/` for `rate`,
    `convert` and `fx` in a money context, asserting no conversion function exists. The
    app has no network and must never grow one by accident.
  - `money decimals follow the exponent` — `EUR` renders 2, `JPY` 0, `KWD` 3, asserted
    on the decimals rule rather than on a formatted string.
- **Then build**
  - `lib/core/money/currency.dart` — the shipped ISO 4217 exponent table (0 for
    JPY/KRW, 3 for KWD/BHD/OMR/TND, 2 otherwise), `Currency.tryParse`, and
    `minorPerMajor`.
  - `lib/core/money/money.dart` — `Money(int amountMinor, Currency currency)`, no
    `double` in any signature, arithmetic that asserts same-currency.
  - `lib/core/money/allocate.dart` — the single largest-remainder primitive every
    division of money routes through, including `monthlyShare`'s day-weighted split
    later.
  - `lib/core/money/money_total.dart` — the `Map<Currency, int>` grouping with the
    dominant-currency rule.
  - `lib/data/repositories/` mapping updated: `(totalCostMinor, currencyCode)` becomes
    one `Money`.
- **Verify**
  ```bash
  flutter test test/core/money/ test/data/repositories/
  bash .claude/skills/value-objects-money-and-units/scripts/check-money-violations.sh
  ```
- **Done when**
  - [ ] No `double`/`num` appears in any money signature and no `REAL` is involved.
  - [ ] The exponent table is real ISO 4217; nothing hardcodes 100.
  - [ ] Every division of money goes through `allocate()`.
  - [ ] `IRT` and any exchange-rate concept are absent, proven by a test.
- **Estimate** 2 h (CC) · ~2 weeks (human)

### Task 6.4 — The six consumption conversions and the rounding table

- **Goal** The app can express one canonical consumption in any of the six units the
  user might pick, and rounds every kind of number the way SPEC §3 says.
- **Spec** §3 Display conversion and rounding (the six formulas, the decimals table,
  half away from zero).
- **Skills** `value-objects-money-and-units`, `testing-strategy`,
  `seeded-determinism-and-golden-vectors`.
- **Write these tests first** — `test/core/units/consumption_test.dart`,
  `test/core/rounding/rounding_test.dart`
  - `l_100km matches the spec formula` — `(ml/1000) / (m/1000) × 100` on a worked
    case: 41.2 L over 640 km is 6.4 L/100 km.
  - `km_l, mpg_us, mpg_uk, kwh_100km and mi_kwh each match their formula` — five
    cases, from the same canonical pair.
  - `l_100km and mpg_us agree with the independent oracle` —
    `mpg_us ≈ 235.214583 / l_100km` and `mpg_uk ≈ 282.481 / l_100km`, checked with
    `closeTo`. The oracle is independent of the production code, per
    `testing-strategy` rule 3; checking a function against itself proves nothing.
  - `km_l is the reciprocal of l_100km times 100`.
  - `conversion is a total function` — a zero distance or a zero volume returns an
    explicit "not computable" value, never `Infinity`, `NaN` or a throw.
  - `distance and volume units are independent of the consumption unit` — litres in
    with MPG out is a supported pairing, because plenty of people log in litres and
    think in MPG.
  - `rounding is half away from zero on the absolute value` — `2.5 → 3`,
    `−2.5 → −3`, `0.05 at 1 dp → 0.1`, `−0.05 at 1 dp → −0.1`. Half-even is more
    correct and looks broken to a user checking against their phone calculator, so
    half-even is a bug here.
  - `the decimals table is applied per value kind` — one case per row of the SPEC §3
    table: odometer 0; segment distance 0 at ≥100 and 1 below; volume and energy 2;
    consumption 1; money the currency exponent; price per litre/gallon/kWh 3; cost per
    km/mi 3; percentages 0. `0.089 €/km` must not round to `0.09`.
  - `nothing rounds a rounded value` — a test that converts and rounds once from the
    canonical integer, and asserts a double-rounded path differs, so the wrong
    implementation fails loudly.
- **Then build**
  - `lib/core/units/consumption.dart` — `Consumption` over the canonical pair
    (`Distance`, `FuelQuantity`), with one `as(ConsumptionUnit)` returning a `double`
    or the explicit not-computable value.
  - `lib/core/rounding/rounding.dart` — `roundHalfAwayFromZero(double, {int decimals})`
    and a `Decimals` table naming each value kind from SPEC §3 rather than scattering
    magic numbers at call sites.
- **Verify**
  ```bash
  flutter test test/core/units/consumption_test.dart test/core/rounding/
  ```
- **Done when**
  - [ ] All six conversions are implemented and cross-checked against an independent
        oracle.
  - [ ] Rounding is half away from zero, applied once, from the canonical value.
  - [ ] Every row of the SPEC §3 decimals table has a named test case.
  - [ ] No conversion can return `NaN` or `Infinity`.
- **Estimate** 2 h (CC) · ~2 weeks (human)

### Task 6.5 — `buildFuelSegments`: full tank to full tank, and nothing else

- **Goal** The segment builder from SPEC §3 exists exactly as specified, including the
  off-by-one fill that is the most common bug in this category.
- **Spec** §3 Fuel maths (the `buildFuelSegments` pseudocode and the hard-cases table);
  §14 Odometer and data integrity (fuel cases).
- **Skills** `value-objects-money-and-units`, `dart3-idioms-and-coding-standards`,
  `testing-strategy`.
- **Write these tests first** — `test/core/fuel/build_fuel_segments_test.dart`
  - `the first full fill opens a segment and produces nothing` — one fill in, zero
    segments out.
  - `the opening fill's own fuel belongs to the following segment` — three full fills
    at 0 / 600 km / 1,200 km with 40 L, 45 L, 50 L: the first segment's volume is 45 L,
    not 40 L. This is the off-by-one and it gets its own named test.
  - `two partials between two fulls yield one segment with partial_count 2` — and the
    segment's volume is the sum of both partials plus the closing full.
  - `a partial never opens a segment` — a partial after a chain break leaves `open`
    null.
  - `chain_broken discards the segment it would have closed` — nothing averaged,
    nothing pro-rated, and the flagged fill produces no segment.
  - `chain_broken on a full fill opens a new segment there`.
  - `a fill with a null odometer is treated as a chain break` — the imported-row case
    from §17.
  - `two fills at the same odometer produce no segment and flag both fills` — a data
    error, never a 0 L/100 km.
  - `a negative distance produces no segment and flags both fills`.
  - `fills are ordered by (occurred_on, odometer, created_at) regardless of input
    order` — shuffle the fixture with a fixed seed and assert identical output.
  - `two fills on the same day order by created_at` — the §14 rule.
  - `segments are built per fuel_kind independently` — a bi-fuel car with interleaved
    petrol and LPG fills yields two series, never merged, and neither series sees the
    other's odometer as a chain break.
  - `distance comes from cumulative metres, not the raw dash number` — a fixture with
    an `OdometerCorrection` between two fills produces the corrected distance. The
    engine consumes `cumulativeM` from EPIC-05.
  - `volume above tank capacity × 1.15 still builds a segment` — saved with a warning;
    some people carry a jerrycan.
- **Then build**
  - `lib/core/fuel/fuel_segment.dart` — `FuelSegment { FillUp from, FillUp to,
    Distance distance, FuelQuantity volume, int partialCount }`.
  - `lib/core/fuel/build_fuel_segments.dart` — `buildFuelSegments(List<FillUp> fills)`
    returning a `FuelSegmentSet { List<FuelSegment> segments,
    List<FillUpId> flagged, List<FuelWarning> warnings }`, one call per `fuel_kind`.
    The function is total: it never throws and never returns null.
  - Keep it inside the complexity limits — the loop is one method; the ordering and
    the per-kind split are separate functions.
- **Verify**
  ```bash
  flutter test test/core/fuel/build_fuel_segments_test.dart
  ```
  A pass is all fourteen cases green, with the off-by-one case named in the output.
- **Done when**
  - [ ] The builder matches the SPEC §3 pseudocode line for line, including `pending`.
  - [ ] The opening fill's volume is excluded from its own segment.
  - [ ] Bi-fuel produces independent series.
  - [ ] Segment distance is cumulative, correction-aware metres.
- **Estimate** 2 h (CC) · ~2 weeks (human)

### Task 6.6 — The refusals: what the engine will not compute

- **Goal** Every "no number" case in the spec is one typed reason the UI can render as
  `—` plus one sentence, so nothing downstream can accidentally show a plausible lie.
- **Spec** §3 Fuel maths (hard cases); §3 (*a wrong consumption number is worse than
  none*); §14 Odometer and data integrity; §12 Ground rules (*refuse rather than
  guess*); `CLAUDE.md` rule 7.
- **Skills** `error-handling-typed-results`, `dart3-idioms-and-coding-standards`,
  `testing-strategy`.
- **Write these tests first** — `test/core/fuel/consumption_unavailable_test.dart`
  - `the very first fill reports firstFill` — the reason the UI turns into *your first
    figure arrives at your next full fill*.
  - `a broken chain reports chainBroken`, `a missing odometer reports
    missingOdometer`, `a zero or negative distance reports nonPositiveDistance` —
    three cases, each carrying the offending fill ids so the UI can flag them.
  - `an EV whose charges are never marked full reports noFullCharge` — and the same
    fixture still yields a cost-per-distance figure, because §3 says cost per distance
    is offered and an energy figure is not invented from partial charges.
  - `fewer than nine valid segments reports insufficientData for the trend only` — the
    average is still computed; only the trend refuses.
  - `every reason is switched exhaustively` — a `switch` over
    `ConsumptionUnavailable` with no `default:`, so a new reason is a compile error at
    every call site.
  - `no code path returns zero, null or NaN in place of a refusal` — a table-driven
    test over every refusal fixture asserting the result is the sealed
    `Unavailable` variant, never a numeric zero. This is the test that stops a `—` from
    silently becoming `0.0 L/100 km`.
- **Then build**
  - `lib/core/fuel/consumption_unavailable.dart` — a sealed
    `ConsumptionUnavailable` with `firstFill`, `chainBroken`, `missingOdometer`,
    `nonPositiveDistance`, `noFullCharge`, `insufficientData`, `mixedCurrency`, each
    carrying its typed params and a stable `code` — never a user-facing string; the
    sentence is localised from the code at the presentation edge.
  - `lib/core/fuel/fuel_result.dart` — the sealed
    `FuelValue<T> = Computed<T> | Unavailable` used by every public function in this
    epic, so "no number" is a value the compiler forces the caller to handle.
- **Verify**
  ```bash
  flutter test test/core/fuel/consumption_unavailable_test.dart
  flutter analyze --fatal-infos --fatal-warnings
  ```
- **Done when**
  - [ ] Every refusal in SPEC §3 and §14 has a named variant and a test.
  - [ ] No `Failure` here carries a localised string; each has a stable code.
  - [ ] No numeric zero or `null` stands in for a refusal anywhere.
- **Estimate** 1 h (CC) · ~1 week (human)

### Task 6.7 — `segmentConsumption`, `averageConsumption`, best, worst and last

- **Goal** The numbers `costs.fuel` will show exist and are computed the way SPEC §12
  says — total over total, never a mean of means.
- **Spec** §3 Fuel maths (`segmentConsumption`, `averageConsumption`); §12 `costs.fuel`
  → The numbers, exactly.
- **Skills** `value-objects-money-and-units`, `testing-strategy`,
  `seeded-determinism-and-golden-vectors`.
- **Write these tests first** — `test/core/fuel/consumption_stats_test.dart`
  - `segmentConsumption is volume over distance in canonical units` — one worked case
    checked against the SPEC §3 formula.
  - `lifetime average is total volume over total distance` — the load-bearing test:
    a 40 km segment at 12 L/100 km and a 900 km segment at 6 L/100 km. The mean of the
    two is 9.0; total-over-total is 6.26. The test asserts 6.3 at 1 dp and states in
    its `reason:` that a mean of means over-weights the short segment and drifts a few
    percent high for anyone who tops up in town.
  - `best and worst carry the closing fill's date` — not just the number, because the
    UI shows both.
  - `lastTank is the newest segment's consumption` — and is `Unavailable` when the
    newest segment was discarded.
  - `average over zero segments is Unavailable, not zero`.
  - `the average is computed per fuel_kind` — a bi-fuel fixture yields two averages
    and the app never merges them.
  - Seeded fuzz: `for seed in 0..499`, generate a random valid fill chain, assert
    `averageConsumption` equals `Σvolume / Σdistance` computed by an independent inline
    oracle, and print the seed in `reason:`.
- **Then build**
  - `lib/core/fuel/consumption_stats.dart` — `segmentConsumption(FuelSegment)`,
    `averageConsumption(Iterable<FuelSegment>)`, `bestSegment`, `worstSegment`,
    `lastSegment`, each returning `FuelValue`.
- **Verify**
  ```bash
  flutter test test/core/fuel/consumption_stats_test.dart
  ```
- **Done when**
  - [ ] The total-over-total test exists with a fixture where it differs from the mean.
  - [ ] Best and worst carry their closing fill's date.
  - [ ] Every statistic is per `fuel_kind`.
- **Estimate** 1 h (CC) · ~1 week (human)

### Task 6.8 — `consumptionTrend`

- **Goal** The app says "getting thirstier" only when it is, because a false alarm is
  the one the user remembers.
- **Spec** §3 Fuel maths (`consumptionTrend`); §12 `costs.fuel` (the trend line copy).
- **Skills** `testing-strategy`, `error-handling-typed-results`.
- **Write these tests first** — `test/core/fuel/consumption_trend_test.dart`
  - `eight valid segments returns insufficientData` — three data points is not a trend,
    and the UI shows nothing.
  - `nine segments is the minimum that produces a verdict` — the boundary, since the
    comparison is the last 3 against the 6 before them.
  - `last 3 more than 8% above the previous 6 returns thirstier`.
  - `last 3 more than 8% below the previous 6 returns leaner`.
  - `a difference inside ±8% returns steady` — including the exact boundary case at
    8.0%. **Decision to record in the PR and SPEC §18:** the spec says "a ±8%
    threshold" without stating whether the boundary is inclusive; we treat exactly 8.0%
    as `steady` and require strictly more than 8% to alarm, because the rule exists to
    suppress false alarms.
  - `discarded segments do not count toward the nine` — a fixture with two flagged
    segments and nine valid ones behaves as nine.
  - `the trend is computed per fuel_kind`.
- **Then build**
  - `lib/core/fuel/consumption_trend.dart` — `consumptionTrend(List<FuelSegment>)`
    returning `thirstier | leaner | steady | insufficientData`, plus the two mean
    values the UI quotes (*Last 3 tanks 7.1, the 6 before 6.5*).
- **Verify**
  ```bash
  flutter test test/core/fuel/consumption_trend_test.dart
  ```
- **Done when**
  - [ ] The 9-segment floor and the ±8% band are both tested at their boundary.
  - [ ] The function returns the two quoted means alongside the verdict.
- **Estimate** 1 h (CC) · ~1 week (human)

### Task 6.9 — `unitPrice` and the per-currency fuel money figures

- **Goal** Fuel money never mixes currencies, and the app never prints a price per litre
  that added euros to pounds and divided by litres.
- **Spec** §3 Fuel maths (`unitPrice`); §3 Currency; §12 `costs.fuel` → The numbers,
  exactly; §14 (*Fill-ups in a second currency*).
- **Skills** `value-objects-money-and-units`, `error-handling-typed-results`,
  `testing-strategy`.
- **Write these tests first** — `test/core/fuel/fuel_money_test.dart`
  - `unitPrice is total over quantity, derived, never stored` — a worked case to 3 dp,
    and an assertion that no `FillUp` model field holds it.
  - `avgPricePaid is Σ cost over Σ quantity, not the mean of unit prices` — a fixture
    where the two differ.
  - `fuelSpend and fuelVolume sum the fills in range`.
  - `fuelCostPerDistance uses exactly the fills whose volume built the segment` — the
    fills after the opening fill up to and including the closing one. A fixture with an
    open, unmeasured segment at the end asserts its cost is excluded; charging it
    against a distance that excludes it is the bug this test exists for.
  - `a segment whose fills span two currencies is excluded from every per-distance
    figure` — it still contributes volume and distance, and the result carries the
    count for the data-quality row *"1 tank spanned two currencies — no cost per
    kilometre for it."*
  - `every money figure is returned per currency` — `avgPricePaid`, `lastPricePaid`,
    `fuelSpend`, `fuelCostPerDistance` and `fuelCostPerMonth` each return a
    `Map<Currency, …>` with the dominant currency identified by fill count.
  - `fuelCostPerMonth divides by completed months only` — the §12 ground rule: on 2
    September 2026, "Last 12 months" is 1 Sep 2025 – 31 Aug 2026, and the current month
    is out of numerator and denominator alike.
  - `no figure blends currencies` — a two-currency fixture never produces a single
    scalar.
- **Then build**
  - `lib/core/fuel/fuel_money.dart` — `unitPrice(FillUp)`, `avgPricePaid`,
    `lastPricePaid`, `fuelSpend`, `fuelVolume`, `fuelCostPerDistance`,
    `fuelCostPerMonth`, each per currency, each returning `FuelValue`.
  - `lib/core/money/completed_months.dart` — the completed-month range helper the §12
    ground rules require, taking an injected `today`.
- **Verify**
  ```bash
  flutter test test/core/fuel/fuel_money_test.dart
  ```
- **Done when**
  - [ ] Unit price is derived at 3 dp and stored nowhere.
  - [ ] Per-distance figures use segment-contributing fills only.
  - [ ] A mixed-currency segment is excluded and counted, never blended.
  - [ ] Ranges are completed calendar months.
- **Estimate** 2 h (CC) · ~2 weeks (human)

### Task 6.10 — The §17 fuel fixture suite as committed golden vectors

- **Goal** The definition-of-done gate for the fuel engine is a file a reviewer can
  read: inputs, expected outputs, one row per case in SPEC §17.
- **Spec** §17 Definition of done (*The fuel engine passes a fixture suite covering:
  first fill, partials, `chain_broken`, missing odometer on an imported row, zero and
  negative segments, bi-fuel, EV with and without full charges, and lifetime average
  computed as total/total rather than a mean of segments*); §3 Fuel maths.
- **Skills** `seeded-determinism-and-golden-vectors`, `testing-strategy`,
  `error-handling-typed-results`.
- **Write these tests first** — `test/core/fuel/fuel_vectors_test.dart`
  - `every case named in SPEC §17 has a vector` — reads
    `test/fixtures/fuel/fuel_vectors.fixture.json` and asserts the nine required case
    ids are present: `first_fill`, `partials`, `chain_broken`,
    `missing_odometer_import`, `zero_distance`, `negative_distance`, `bi_fuel`,
    `ev_with_full_charges`, `ev_without_full_charges`, `lifetime_total_over_total`.
    A missing case fails the test by name, so the §17 gate cannot quietly shrink.
  - `each vector's expected output matches the engine` — one generated test per vector,
    named after its case id, asserting segments, per-segment consumption, the lifetime
    average and the refusal reason where the expected output is a refusal.
  - `the vectors are reproducible` — regenerating with the committed seed produces a
    byte-identical file; the test fails if the file was hand-edited into disagreement
    with the generator.
  - `a vector may not expect a number where the engine refuses` — a guard test
    asserting no vector's expected output pairs a refusal reason with a numeric value.
- **Then build**
  - `test/fixtures/fuel/fuel_vectors.fixture.json` — synthetic fills only, named
    `*.fixture.json` per `CLAUDE.md`. Never a real backup file.
  - `tools/regen_fuel_vectors.dart` — the regeneration path, seeded and deterministic,
    documented at the top of the fixture file's sibling README line so the next person
    regenerates rather than hand-edits.
  - A short table in `epics/progress/EPIC-06.md` mapping each §17 phrase to its case
    id, so the due-engine epic can copy the pattern for its own fixture suite.
- **Verify**
  ```bash
  flutter test test/core/fuel/
  dart run tools/regen_fuel_vectors.dart --check
  flutter analyze --fatal-infos --fatal-warnings
  ```
  A pass is: every §17 case present, every vector green, and the regeneration check
  reporting no diff.
- **Done when**
  - [ ] All ten case ids exist and are asserted by name.
  - [ ] The fixture is synthetic and lives in `test/fixtures/` as `*.fixture.json`.
  - [ ] The file is regenerable and the check proves it was not hand-edited.
- **Estimate** 2 h (CC) · ~2 weeks (human)

## Definition of done

- [ ] `lib/core/` imports no Flutter, no `dart:io`, no `intl`, proven by a gate that has
      been seen to fail, and the whole core suite runs in seconds.
- [ ] Every quantity is canonical `int` in, converted `double` out, at render only;
      `lib/data/` calls no conversion getter and no stored byte changes when a unit
      preference changes.
- [ ] Money is integer minor units keyed to the real ISO 4217 exponent, split only
      through `allocate()`, never summed across currencies, never converted; `IRT`
      appears nowhere.
- [ ] All six consumption units and every row of the SPEC §3 decimals table are
      implemented, with rounding half away from zero applied once.
- [ ] `buildFuelSegments` matches the SPEC §3 pseudocode, per `fuel_kind`, on cumulative
      correction-aware distance, with the opening fill's volume excluded from its own
      segment.
- [ ] Every case where the spec refuses a number returns a typed reason, never a zero,
      a null or a `NaN`.
- [ ] The lifetime average is total-over-total, with a fixture that would fail a mean of
      segments.
- [ ] The §17 fuel fixture suite is committed, complete, and regenerable.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.

This epic builds no screen, so it carries no `calm-visual-parity` line. If a number
from this epic needs to appear on a screen, that is the owning screen epic's task and
its parity check.

## Progress file

> **Before starting, create the empty progress file `epics/progress/EPIC-06.md`.** It
> starts empty. Append one line per task as it completes — what was built, what was
> deferred, and anything the next epic needs to know. It is the running log for this
> epic and the handover to the next one.

Record two things the due-engine epic will need: the exact signature of `FuelValue`
and `ConsumptionUnavailable` (it will want the same refusal shape for `unknown` and
`needs_odometer`), and the §17-phrase-to-case-id table from Task 6.10.
