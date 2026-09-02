# `.claude/`

## `skills/` — vendored, not authored here

40 general Flutter engineering skills, copied from
**[zakariaf/Flutter-Skills](https://github.com/zakariaf/Flutter-Skills)**
at commit `d88a664` (`d88a6640176430640f3976edc283c57041fbafac`).

They are **vendored on purpose**: a clone of this repo gets the same guidance the
app was built against, with no submodule to init and no plugin to install. The
cost is that they go stale, so the commit is recorded above — that is the only
thing that makes "are we behind?" answerable.

### Updating

```bash
git clone --depth 1 https://github.com/zakariaf/Flutter-Skills /tmp/fs
rm -rf .claude/skills && mkdir -p .claude/skills
cp -R /tmp/fs/skills/* .claude/skills/
git -C /tmp/fs rev-parse HEAD    # record the new sha in this file
```

Review the diff rather than taking it blind — these skills encode opinions, and an
opinion that changed upstream may contradict a decision `SPEC.md` has already made.
**`SPEC.md` wins.** Where a skill and the spec disagree, the spec is the product
decision and the skill is the general default.

### Start here

`flutter-conventions-index` is the front door: cross-cutting house rules plus a
routing table to the other 39. Its rule 6 — *derive, don't store* — is the same
rule as this project's own non-negotiable, which is a good sign the two fit.

### The ones this app leans on hardest

| Skill | Why it matters here |
|---|---|
| `i18n-rtl-l10n` | Six locales, three right-to-left. It independently specifies `nullable-getter: false`, which `l10n.yaml` already sets. |
| `data-export-and-restore` | The whole persistence story is one plain JSON file the user keeps. |
| `local-notifications-scheduler` | The hardest engineering problem in the app: a date-scheduled notification for a distance-based threshold. |
| `value-objects-money-and-units` | Canonical integer storage — metres, millilitres, minor currency units. |
| `persistence-drift` | Schema migrations that must not lose eight years of service history. |
| `dependency-hygiene` | Nothing may open a network path. |
| `design-system-structure` | Three candidate systems live in `design/`. |
| `lint-and-style-config` | `analysis_options.yaml` and its pinned `include:` are built to this. |
| `ci-pipeline-and-gates` | `.github/workflows/ci.yml` and the `tools/` gates. |
| `release-and-store-shipping` | Includes the App Review rule that a first release must submit the app version and its first in-app purchase together. |

## `calm-*` — written here, not vendored

Six further skills implement **Calm**, the design system chosen for this app
(`design/calm/`). They are ours, not upstream, and they encode Calm's *content*
where `design-system-structure` owns token *structure*:

| Skill | Owns |
|---|---|
| `calm-design-system` | The front door: what Calm is, what it rejects, and a routing table to the other five. |
| `calm-tokens` | Every token as Dart — five `ThemeExtension`s, hand-authored light and dark `ColorScheme`, the no-raw-values gate. |
| `calm-typography-and-rtl` | The nine-step scale, the 13px floor, no monospace, Vazirmatn, six locales, numerals and calendars. |
| `calm-components` | The widget library, every variant and every state. |
| `calm-due-state-and-status` | The five due states, redundant encoding, and how "we do not know" is rendered so it never reads as "you are fine". |
| `calm-layout-and-motion` | Spacing rhythm, one-primary-thing-per-screen, the 52px touch floor, all-clear as the good state, motion and reduced motion. |

Every value in them comes from `design/calm/odova.css`; all 26 example files
compile against a real Flutter project with zero analyzer errors, and all eight
gate scripts have been seen to fail on a planted violation.

**They found two WCAG failures in Calm itself** — see
`design/calm/ACCESSIBILITY-FINDING.md`. Unfixed, because the remedy is a design
decision.

Licence: MIT for the vendored `Flutter-Skills`; the `calm-*` skills are Apache 2.0
with the rest of this repo.
