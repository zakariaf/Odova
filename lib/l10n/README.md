# `lib/l10n` — the six locales

**Owner:** every user-visible string. **Skills:** `i18n-rtl-l10n`,
`calm-typography-and-rtl`.

`arb/` holds the six ARB sources — `en de fr fa ar ckb`, three of them
right-to-left — and `gen/` holds the committed output of `flutter gen-l10n`. CI
regenerates and runs `git diff --exit-code` over `gen/`, because a stale
generation compiles and serves yesterday's strings.

`CLAUDE.md` rule 6: a string lands in all six files in the same commit, or in
none of them.
