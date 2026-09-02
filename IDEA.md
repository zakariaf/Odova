# E06 — Car maintenance, made effortless

## The idea in one paragraph

Most people look after their car by remembering. They remember the oil was changed
"sometime last spring", they keep a fuel receipt in the door pocket, and they find out
the timing belt was overdue when it breaks. This app replaces remembering with a phone
that already knows. You add your car and its current odometer reading. It tracks what
has been done and works out what is due next — by kilometres and by date, whichever
comes first — and tells you before it becomes a repair bill instead of a service.

## What it does

- **Service reminders.** Oil and filter, brake pads, tyres, coolant, battery, timing
  belt, inspection. Each one is due at an interval *and* a date; the app watches both.
- **Fuel tracking.** Log a fill-up in a few taps. It works out your real consumption
  (L/100km or MPG), cost per fill, and whether the car is quietly getting thirstier.
- **Mileage log.** Odometer readings over time, so every reminder stays accurate without
  you doing arithmetic.
- **Trips and expenses.** What the car actually costs you — fuel, service, insurance,
  parking, tolls — per month and per kilometre.
- **Service history.** Every job, date, odometer reading and price, in one place. Worth
  real money when you sell the car.
- **More than one car.** The household's second car, the motorbike, the work van.

## Who it is for

Ordinary drivers who keep a car for years and pay for its upkeep themselves — commuters,
families, people running a used car, rideshare and delivery drivers, tradespeople with a
van or two. Not fleet managers, not mechanics, not car enthusiasts with a spreadsheet.

The person we are designing for does not enjoy this task. They want it handled in under a
minute a month and they want to be told, not asked.

## The rules we are building to

- **Offline first.** It works with no signal, in a car park, in a basement garage.
- **No account.** No sign-up wall, no email, no password. Open it and use it.
- **Private.** Your mileage and your money stay on your phone.
- **Calm.** It notifies about things that matter and stays silent otherwise. No streaks,
  no badges, no upsell banners.

## Why this one

There are plenty of fuel-log apps and plenty of service-reminder apps. Most of them look
like a database with a UI on top: they ask you to configure intervals, understand their
vocabulary, and maintain the data before they give you anything back. The gap is an app
that answers one question on the home screen — **what does my car need next?** — and
earns the rest of the data slowly, as a by-product of answering it.

Related work by the same developer: **Khodroyar** (خودرویار), a Persian-language service
reminder app shipped for the Iranian market. This is the global, English-language product
with fuel, mileage and cost tracking added — a different, larger app, and it needs its own
name.

---

# Naming

Two rounds of name generation, 129 candidates, every survivor checked against the App
Store, Google Play and the domain registry. Method and raw evidence at the bottom.

## What the category is already called

A survey of 216 app titles across both stores gives the whole picture in four numbers:
**Car** is the first word 18 times, **Fuel** 13, **Mileage** 13, **My** 6.

The incumbents worth knowing: **CARFAX Car Care** (1M+ installs, and it owns the words
"Car Care"), **Fuelio** by Sygic (5M+), **Drivvo** (5M+, dominant in LATAM), **Fuelly**
(the US fuel-economy brand), **aCar**, **Simply Auto**, **My Cars**, **Spritmonitor** in
Germany. Adjacent and hungry for the same search terms: MileIQ, Everlance, Driversnote,
Stride on the tax-mileage side; Carly, FIXD, Car Scanner on the OBD side.

Roots that are finished — do not go near them:

| Root | Why it is dead |
|---|---|
| `Fuel-` | Fifteen-plus live names (Fuelly, Fuelio, Fuelpro, Fuelmeter, Fuely, FuelNest…). Every suffix is consumed. |
| `Mile-` / `Mileage-` | Owned by the gig/tax-deduction sector, and it smells of gallons. |
| `My` + anything | You get filed next to myChevrolet (959K ratings) and read as a dealer app. |
| `-Log` / `-Logbook` / `-Ledger` / `-Diary` | Saturated, and it names the boring half of the product. |
| `Garage-` | Crowded, plus a 33K-rating fashion retailer outranks you on the word. |
| `Carfax`, `Carly`, `Drivvo` and homophones | Live companies with trademarks and lawyers. |

The useful finding is the gap. **Every one of those 216 names is a noun for the tool** —
log, tracker, manager, monitor, meter, scope, book, reminder. Not one names the thing the
driver actually wants: that the car is fine and nothing is due. Schedule language (*due,
next, interval, ahead*) is likewise untouched, and no incumbent name is built to be
pronounced outside English.

## The recommendation: **Odova**

> **App Store subtitle:** `Mileage, fuel and what's due` — 28 characters, fits the 30-char field.
> **Buy:** `odovaapp.com` (confirmed unregistered). `odova.com` has been registered since
> 2009 but has nothing behind it — worth a low broker offer later, not a launch blocker.

Three open syllables, **o‑DO‑va**. A Spanish, Turkish, Arabic, Hindi or Indonesian speaker
who hears it once writes it back correctly — there is no English morpheme in it to mangle,
and it transliterates cleanly (أودوفا, ओदोवा). That matters more than anything else here,
because the audience is explicitly not English-first and there is no marketing budget to
teach people a spelling.

The `odo-` opening is an odometer echo: faint enough that nobody has to work it out, real
enough that the name does not feel arbitrary once you know. It is invented, so it is
genuinely ownable — no company, product or trademark of this name exists anywhere. And it
is not welded to petrol, so it survives the app growing into EVs, motorbikes or whole-cost
tracking without a rename.

**What you are giving up:** it means nothing on first contact. A driver reading the store
listing learns what this is from the subtitle, not the name. That is a real cost, and it is
the reason the shortlist below exists.

**Verified:** no app named Odova on the App Store — confirmed directly against the iTunes
Search API in all three storefronts (US: 0 title matches in 30 results, GB: 0 in 32, DE: the
search returns nothing at all). Nearest neighbours anywhere are OOVA, a fertility tracker,
and Odoo, the ERP. Google Play clear — nearest titles are Oova, DOWAY, Diprova, none
automotive. No trademark, company or product found on the word.

## Two alternatives, if you want meaning over safety

### Comes First — *the one that explains itself*

> **Subtitle:** `By distance or by date` · **Buy:** `comesfirstapp.com` (free)

Every owner's manual on earth says *"every 10,000 km or 12 months, whichever comes
first."* The phrase is already attached to service intervals in the mind of anyone who has
read the book in the glovebox, including in translation — and "whichever comes first" is
precisely the mechanic that separates this app from every car log in the store. Both words
are first-year English, impossible to misspell.

Verified clear: nothing near it on Google Play, no app of the name on the App Store, and no
company, product or trademark on the phrase.

The catch is that it is a sentence fragment, not a thing. *"I logged it in Odova"* works;
*"I logged it in Comes First"* does not. There is no one-word handle for an icon or a
social account, and a common English phrase gives you a weak mark you could never enforce.

### Oilcan — *the one with a personality*

> **Subtitle:** `Never miss an oil change` · **Buy:** `oilcanapp.com` (free)

A garage object everybody can picture, affectionate and slightly nostalgic, and it lodges
after one hearing. It contains *oil* — the highest-intent search term in the category — and
no app on either store holds the title. It is the only name in the whole set with a point
of view.

Two reasons it is not the recommendation. Heard once, a Turkish or Arabic speaker writes
"oylcan". And *Oil Can Henry's* was a real US oil-change chain (now Valvoline Instant Oil
Change), so there is a name-adjacent mark in the exact service category. Longer term, "oil"
hard-codes a combustion engine into your brand at the moment EV service reminders start
mattering.

## The rest of the shortlist

Everything below survived screening. Play and domain columns were checked directly today;
App Store notes say how each was confirmed.

| Name | Subtitle | App Store | Google Play | Domain | Note |
|---|---|---|---|---|---|
| **Curavo** | Service, fuel and mileage | Clear — confirmed GB (29 results) and DE | Clear (nearest: Curravo, CuraOS) | `curavo.com` live; `curavoapp.com` taken 2026-04-21 → use `curavo.io` | `cura-` = care, the only warm root that survived. But it reads medical across the whole Romance world, and *curavo* is a live Italian verb. |
| **Oleva** | Oil changes and service, sorted | Clear US (42) and DE (6); one exact title exists — *Oleva*, an AI image toy, visible in the PL storefront | Clear | `olevaapp.com` **free** | Soft and easy everywhere, but the first read is cosmetics, and Oliva/Olive/OLEVS blur the spelling. |
| **Refik** | Your car's quiet companion | Near match: *Refik: Namaz, Dua ve Zikir* (Lifestyle, US + GB) | **Clear — genuinely nothing** | `refikapp.com` **free** | Arabic/Turkish *rafīq*, companion. The warmest meaning found and the cleanest store result — but Refik Anadol's studio filed a US mark in 2024, and outside MENA it reads as a man's first name. A MENA-first brand, not a global one. |
| **Zakira** | It remembers, you drive | Clear — US (31), GB (29), DE (23) | Clear (Zakir, Zakerha are neighbours) | `zakiraapp.com` **free** | Arabic *dhākira*, memory. Structurally clean, but Arabic and Urdu readers hear a woman's given name first. |
| **Mint Condition** | Keep your car like new | Still unverified — blocked in all three | Clear on the phrase | `mintconditionapp.com` **free** | Best felt meaning in the set. Held back by a live US franchise trading under the exact phrase, 14 characters, and an idiom that only lands in English. |
| **Service Soon** | Every service, before it's due | Clear — US (46), GB (45), DE (8) | Clear | `servicesoonapp.com` **free** | Reads as a dashboard warning, so comprehension is instant — and it is legally unownable. Anyone can copy it. |
| **Next Leg** | Ready before you set off | Clear in GB; US/DE still blocked | Clear (nearest: NextLegend) | `nextlegapp.com` **free** | Two easy syllables, but thenextleg.io ran a real product under this name, and "leg" is a body part in most of the target languages. |
| **Car Papers** | Every receipt and reminder | Clear — US (45), GB (42), DE (44) | Clear | `carpapersapp.com` **free** | Frames the app as document storage, which undersells it; two live vehicle-document businesses already trade on the phrase. |
| **Service Interval** | Due by distance or date | Clear — ~93 results scanned | Clear | `serviceintervalapp.com` **free** | Precise, but it is manual jargon and unregistrable as a mark. |
| **Keep Rolling** | Keep your car on the road | Near match: *Keep Rolling: Ring Bounce* (Games, US + GB) | One casual game of the same name | `keeprollingapp.com` **free** | Right feeling for rideshare and trades. KEEP ON ROLLING (US reg. 5687606) is held by a fleet-maintenance company — the worst possible neighbour. |

## What we ruled out, and why

- **Anvil** — a vehicle service log app of the same name already ships on Google Play. Same
  category, same word. The worst collision found.
- **Glovebox** — a funded insurance-app company owns the name, and two rivals already use it
  for vehicle records. The automotive meaning is taken three times over.
- **Odo** — a mileage tracker already ships under this exact name in this exact category
  (and *Odomate* is now in the store too, so the `odo-` seam is starting to fill).
- **Car Minder / Car Helper** — near-identical titles on near-identical products in every
  storefront checked. "Car + verb" is the most-mined seam in the category.
- **Hubcap** — an existing app of the name plus a live software-class trademark held by its
  operator. Trademark risk, not just ASO risk.
- **Olive** — an automotive-sector company already brands as olive® with a registered mark.
- **Roadworthy** — a genuinely good English name, killed by the `-worthy` sound: the /ð/ does
  not exist in Spanish, French, German, Turkish, Arabic, Hindi or Indonesian, so it comes out
  "roadvorzy" and is unspellable from hearing. It is also a regulated certificate term in the
  UK and Australia, with live operators using it.
- **Rawat / Zakira / Refik** — the "borrow a warm root from Arabic, Turkish or Hindi" idea
  fails structurally, not individually. Those roots are overwhelmingly *people's names*:
  Rawat is a Rajput surname (a car app called Rawat reads like a car app called Patel),
  Zakira is a common given name, Refik is a famous media artist. The territory can produce a
  regional brand; it cannot produce a neutral worldwide one.
- **Well Oiled** — both stores are empty, and the phrase means "drunk" in a target market.
  The kind of thing no availability check catches.

## How to check a name yourself

A script in this repo does all three checks in one call:

```bash
python3 tools/name_check.py "Odova" "Comes First"      # App Store + Play + domains
python3 tools/name_check.py --no-ios "Odova"           # when Apple is throttling you
python3 tools/name_check.py --json "Odova"             # machine-readable
```

It scans the iTunes Search API across the US, GB and DE storefronts, reads the first page
of Google Play search titles, and asks Verisign's RDAP whether `<name>.com` and
`<name>app.com` are registered.

Doing it by hand:

- **App Store** — `https://itunes.apple.com/search?term=<name>&entity=software&limit=40&country=us`
- **Google Play** — `https://play.google.com/store/search?q=<name>&c=apps&hl=en&gl=US`
- **Domain** — `https://rdap.verisign.com/com/v1/domain/<name>.com` (404 means free)

Two things that will bite you. Apple rate-limits hard and starts returning **HTTP 403** —
a 403 is not a clean result, and treating it as one is how you convince yourself a taken
name is free. And *registered* is not *in use*: most of the `.com`s above resolve to parking
landers, so always fetch the page before writing a domain off.

### Caveat on the current data

Apple rate-limited this machine with HTTP 403 partway through screening. The block later
lifted and the finalists were re-checked; **Odova, Oilcan, Oleva and Curavo are now
confirmed clear against the live API**, and Play and domain results were all re-verified
directly. Two of the round-2 alternates picked up near-matches on the re-check that are
worth knowing: *Refik: Namaz, Dua ve Zikir* (Lifestyle, US + GB) and *Keep Rolling: Ring
Bounce* (Games, US + GB). Rows still marked *"not yet API-verified"* have been through
Play, web and trademark checks only — re-run `tools/name_check.py` before committing to one
of those — at the time of writing only **Mint Condition** is still unverified (Apple blocked
all three storefronts for it), and **Due Care** and **Next Leg** are confirmed in two
storefronts out of three.
