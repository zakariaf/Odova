- 19.1 icon + launch screen — done. Gauge silhouette generated from the CSS tokens; alpha and size assertions read Contents.json rather than a typed list. LaunchImage.imageset deleted, unreferenced after the storyboard rewrite.
- 19.2 signing hygiene — done. Two real findings: a committed `DEVELOPMENT_TEAM`
  (three sites) and `CODE_SIGN_STYLE = Automatic` on Release (three sites). Both
  fixed; simulator and APK still build. The `.p8` pattern had never been seen to
  fail — the self-test only planted a keystore — and there was no history-half
  case at all, so a shallow checkout would have made that arm pass silently.
- 19.3 version — done. The pubspec/constant tie already existed from EPIC-14; added the Info.plist substitution assertion, which was the untested third copy. Bumped to 1.0.0+1.
- 19.4 capability surface — done, and weaker than the task it replaces. The
  merged-manifest assertion was §17's strongest mechanical evidence; iOS has no
  equivalent, so 19.8's aeroplane-mode pass now carries more of the offline gate
  than the two-platform epic asked it to. `no_network_test` and `audit_deps`
  already existed (EPIC-17 and earlier); both were re-verified by planting.
- 19.5 privacy — done. The manifest needed wiring into the Xcode target, not
  just writing; verified it is bundled in the built .app. §18.12 decided: OS
  backup stays ON, recorded with a name and a date, and the copy rule that
  follows is enforced in six locales. The sheet's own test caught `sqlite3` and
  `sqlite3_flutter_libs` missing from it.
