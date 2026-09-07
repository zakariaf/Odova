# EPIC-17 — Accessibility, text scale and screen readers

## Task 17.1 — the accessibility lane

The harness is tested before anything is tested with it, and every assertion is
about it FAILING. A harness that silently swallows is worse than none: it turns
a release blocker into a green suite, which is the one outcome nobody recovers
from by reading the code.

**Two things I got wrong writing the self-test, and both are worth keeping:**

- **A `SizedBox` around a `Text` clips silently.** It reports nothing at all. It
  is `RenderFlex` that shouts, so the overflow fixture is a `Column` in a fixed
  height. Worth knowing before writing a test that depends on the shout.
- **A bare `Icon` produces NO semantics node.** There is nothing in the
  semantics tree to find — the icon is announced as silence, which is exactly
  the defect, and only the widget tree knows it is there. So
  `expectEverythingLabelled` walks BOTH: the semantics tree for a button or
  tappable row with no label (what TalkBack actually reads, and where a widget
  whose ancestor excludes it is invisible), and the widget tree for an `Icon`
  with no `semanticLabel` and no `ExcludeSemantics` around it.

`ExcludeSemantics` is the honest way to have an unlabelled icon: it is a claim a
reviewer can check, where a missing label cannot be told from an oversight.

**The matrix is enumerated and named, not counted** — 6 locales × 100%/200% ×
bold on/off = 24 — and built from `odovaSupportedLocales` rather than a literal,
so a locale added to the app cannot be missed here. A dropped locale hides
perfectly well inside an integer and not at all inside a test name.

`accessibleNavigation` follows `boldText` deliberately: both are on when a user
has turned the OS settings up, and a 200% bold screen tested with screen-reader
navigation off is a combination nobody has.

**`test/policy/a11y_bans_test.dart`** refuses the one-line escapes —
`withClampedTextScaling`, `textScaleFactor`, `ignoreOverflowErrors`, and
`FittedBox` outside an allowlist whose single entry (the PDF writer) carries its
reason. All three plantable bans were proven red before being trusted.
