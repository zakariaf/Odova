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
- `design/` — three complete candidate design systems, each covering all 27
  screens, with 336 reference screenshots in light/dark and LTR/RTL.
- `.claude/skills/` — 40 Flutter engineering skills vendored from
  zakariaf/Flutter-Skills at a pinned commit, plus seven `calm-*` skills written
  here that implement the Calm design system in Flutter and gate the built app
  against its design reference.
- `design/calm/ACCESSIBILITY-FINDING.md` — two WCAG contrast failures found in
  Calm's light theme while writing those skills. Not yet fixed; the remedy is a
  design decision.

### Not yet
- The Flutter app. CI's Flutter lane arms itself the moment `pubspec.yaml`
  exists.

[Unreleased]: https://github.com/zakariaf/Odova/commits/main
