- 19.1 icon + launch screen — done. Gauge silhouette generated from the CSS tokens; alpha and size assertions read Contents.json rather than a typed list. LaunchImage.imageset deleted, unreferenced after the storyboard rewrite.
- 19.2 signing hygiene — done. Two real findings: a committed `DEVELOPMENT_TEAM`
  (three sites) and `CODE_SIGN_STYLE = Automatic` on Release (three sites). Both
  fixed; simulator and APK still build. The `.p8` pattern had never been seen to
  fail — the self-test only planted a keystore — and there was no history-half
  case at all, so a shallow checkout would have made that arm pass silently.
- 19.3 version — done. The pubspec/constant tie already existed from EPIC-14; added the Info.plist substitution assertion, which was the untested third copy. Bumped to 1.0.0+1.
