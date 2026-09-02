# All-clear: the good state, designed

Most apps treat "no rows" as one state and give it a grey box, a shrug illustration and the words
"Nothing here yet". Odova has two different empty conditions and only one of them is a shortfall.

- **All-clear** — the car is fine, nothing is due, the user did the work. `CalmAllClear`.
- **Empty** — a list the user has not filled in yet: no trips, no expenses, no fill-ups.
  `CalmEmptyState`.

SPEC §9 calls all-clear "the most common state, and the one most apps waste". ~70% of Home opens
never leave Home, and most of those find nothing due. This is the screen the product is judged on.
Rendering it in the vocabulary of a shortfall tells the user the app failed to load.

## What `CalmAllClear` contains — exactly four things

Straight from `.allclear` in `odova.css` and the anatomy in SPEC §9:

1. **A reassuring mark.** A 92px check disc on `ok.tint`, ink `ok.ink`, with a 12px ring of the same
   tint spread around it. It is the largest single mark anywhere in the app. Not an illustration,
   not a mascot, not a tick inside an otherwise grey circle.
2. **A plain statement of the good news.** `titleLg` 27 / semibold / `trackingTight`:
   *"Nothing due"*. Present tense, no exclamation mark, no "You're all caught up! 🎉". Calm does
   not congratulate; it reports.
3. **What is next and when.** `bodyLg` 17 in `ink2` plus a `caption` 13 fuzz line:
   *"Next: Inspection (TÜV), 14 March"* / *"in about 6 weeks"*. The exact date comes from the time
   axis and is plain; the "about" line is the estimate. SPEC §1 forbids a guess that looks like a
   fact, so the two never merge into one confident sentence.
4. **The date it was last confirmed.** The `.allclear__since` panel — a full-width `surface2` block
   at `radiusXl` 24, `s4`/`s5` padding: a `caption` label *"Since the last oil change"* over a
   `headline` 19 figure *"3,120 km · 4 months"*. This is the line that turns "nothing to do" into
   evidence. Without it the card is an assertion; with it, it is a receipt.

Optionally, **one quiet next action** — a text-weight row, never a filled primary button. "See all
reminders (14) ›" is usually the whole of it, and it lives *outside* the card as the normal
see-all row.

The card sits in the primary slot at a primary card's weight: the sage radial wash
(`ok.tint` → `surface` at 72%), `elev-2` + `elev-sheen`, `radius3xl` 36, `s8`/`s6`/`s7` padding,
`s4` gaps, centre-aligned. It is shorter than the 148 + 72 + 72 stack it replaces, and SPEC §9
spends that height deliberately: it pulls the glance tiles above the fold, so a user who finds
nothing due still leaves knowing what the car costs and what it drinks.

## What it must never contain

- **A shrug illustration, an empty-box graphic or a mascot.** Nothing is wrong. Drawing an absence
  invents a problem the user does not have.
- **"Nothing here yet" or any "yet".** "Yet" says the state is temporary and incomplete. This state
  is the goal.
- **A big empty box, a grey disc, or a dashed placeholder rectangle.** The card is a full,
  finished, tinted surface — the sage wash is what distinguishes it from the neutral `surface2`
  disc `CalmEmptyState` uses.
- **A nag or a filled CTA.** No "Log a service anyway", no "Add more reminders", no badge, no
  countdown. A primary button here converts a reward into a chore.
- **A number the app is not sure of.** If there is no `ServiceRecord` to measure from, the
  since-line is omitted entirely rather than showing `— km · — months`. SPEC §9: with service
  history but no fill-ups the consumption tile shows `—` and the reward line is the service one
  alone.
- **Motion.** `.allclear` declares no animation, and that is correct: this is a state you land on,
  not an event that happens. A celebratory pop-in would fire on ~70% of app opens and be
  intolerable by the third.

## `CalmEmptyState`, for contrast

Same skeleton, opposite tone: a neutral 104px `surface2` art disc in `ink3`, a `title` 22 line, a
`bodyLg` body capped at 28ch, and **one filled primary action** — because here there genuinely is
something the user has not done.

```
No trips yet
Log a trip when you want to attribute a journey's cost.
The odometer stays the source of truth for distance.
[ Add a trip ]
```

The body sentence states the mechanism, not the feature: it tells the user what a trip *is for*
so they can decide they do not need one. Calm's empty states are allowed to talk someone out of a
feature.

## First run is neither

SPEC §9 gives first run its own composition and it is not `CalmAllClear`: the odometer strip
(entered, never projected), the unknown-anchor card in the primary slot reading *"Set up your
reminders — tell me when things were last done"*, the see-all row, and tiles showing `—`. No fake
numbers, no zeroes, and below the tiles one statement — *"Log a fill-up and your consumption starts
here."* — not a button, because the **+** is already one tap away. Showing a green check on day one
would be a lie: nothing is due because nothing is known, which is `unknown`, not `ok`. See
`calm-due-state-and-status`.

## Accessibility

The mark is decorative — wrap it in `ExcludeSemantics` and let the heading carry the meaning, so a
screen-reader user hears *"Nothing due. Next: Inspection, 14 March, in about six weeks. Since the
last oil change: 3,120 kilometres, 4 months."* and not "image, image". Mark the title with
`Semantics(header: true)`. The state must be legible with colour stripped: the check glyph, the
word "Nothing due" and the since-panel are all non-colour signals, so the sage wash is decoration
on top of three of them — the never-colour-alone floor is `accessibility-as-code`'s and the
redundant encoding of due states is `calm-due-state-and-status`'s.

Full widget: `examples/calm_all_clear.dart`.
