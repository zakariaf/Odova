# Changelog

All notable changes to Odova are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `SPEC.md` — the full product specification: data model and due engine,
  reminders and the projection engine, the six-locale contract, the backup file
  format, the screen map, and every screen with its states and navigation edges.
- `IDEA.md` — the idea in plain words, and the naming research behind Odova
  including what was verified against the App Store and Google Play.
- Repo configuration: CI, issue and PR templates, Dependabot, licence,
  contribution and security policy.
- `tools/` — repo gates (release hygiene, spec-example validation) with
  self-tests that prove each gate can fail, plus the app-name availability
  checker used to choose the name, and the design mockup pipeline.
- `design/` — three complete candidate design systems, each covering all 28
  screens, with 340 reference screenshots in light/dark and LTR/RTL.
- `epics/` — 19 executable build epics derived from `SPEC.md`: 182 TDD tasks, the
  skills each epic loads, and a visual-parity gate on every task that builds a
  screen.
- `.claude/skills/` — 40 Flutter engineering skills vendored from
  zakariaf/Flutter-Skills at a pinned commit, plus seven `calm-*` skills written
  here that implement the Calm design system in Flutter and gate the built app
  against its design reference.
- `design/calm/ACCESSIBILITY-FINDING.md` — two WCAG contrast failures found in
  Calm's light theme while writing those skills. Not yet fixed; the remedy is a
  design decision.
- The Flutter app — empty on purpose. It launches as **Odova**
  (`io.applander.odova`) on iOS 15+ / Android API 26+, holds no `INTERNET`
  permission in any manifest, resolves all six locales including `ckb` in
  right-to-left, and boots through a composition root that installs its two
  error handlers before anything that can throw. No theme, no database and no
  screen yet.
- `tools/audit_deps.sh` + `audit_deps.py` — the dependency policy gate. Refuses
  any package that opens a network path, walking the **resolved transitive
  tree** rather than `pubspec.yaml`.
- `tools/check_lint_include.sh` — proves `very_good_analysis`' versioned
  ruleset is actually loaded. An `include:` that resolves to nothing analyses
  zero rules and reports green.
- `tools/check_dependabot.sh`, `tools/strip_generated_from_lcov.sh`.
- `test/policy/` — cross-cutting gates over the toolchain pins, the platform
  floors, the lint config, the shape of `lib/`, the CI workflow, and a grep for
  `dart:io`'s network APIs, which no dependency check can see.

[Unreleased]: https://github.com/zakariaf/Odova/commits/main
