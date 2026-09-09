# EPIC-19 — Release engineering and store shipping

**Branch** `epic/19-release` · **iOS only** (see the platform decision in the
epic) · tasks 19.1 – 19.9 done, 19.10 config only.

## The decision that reshaped the epic

v1 ships to the App Store and not to Google Play. About half this epic's weight
was Android-shaped and was removed rather than carried at zero value — a
checklist nobody can run is one people learn to skip past. The Android *build*
stays in CI, because compiling for a second target is cheap and catches things.

**Two costs, both recorded in the epic rather than dropped:**

1. **§17's offline gate lost its strongest evidence.** The merged manifest was a
   property of the shipped artifact and `INTERNET` being absent from it was
   mechanical proof. iOS declares no network permission, so nothing reproduces
   it. Task 19.4 says so in its own text, and 19.8 partly closes it from the
   other end with a new gate that reads the built binary's imported symbols and
   linked libraries — a link-time fact that survives obfuscation.
2. **A halt is now a pause.** Play could be stopped at 1%; an approved iOS build
   cannot be un-shipped, only superseded by one that must itself pass review.
   The rollout plan is written as pause-then-expedite, with the expedited-review
   request named in advance.

## What the tests found

Six real defects, each on the first run of the test written for it.

| | |
|---|---|
| `DEVELOPMENT_TEAM = 3TMBQZX389` committed, three sites | pins the project to one Apple account; a cloner signs against a team they are not in |
| `CODE_SIGN_STYLE = Automatic`, three sites including Release | an archive built with whatever identity the machine holds — a rejected upload burns a build number that can never be reused |
| `debugShowCheckedModeBanner` never set | the red DEBUG ribbon was across every store screenshot captured an hour earlier, and every device screenshot in every review before that |
| `PrivacyInfo.xcprivacy` not in the Xcode target | it would have read correctly, reviewed correctly and shipped nowhere |
| `de` and `fr` keywords at 107 and 108 against a 100 limit | rejected at upload, at the end of the ritual |
| three identical Home screenshots for `fa`, `ar`, `ckb` | the app mirrors for RTL, every scripted tap landed on empty space, and the capture script reported success three times |

The last two are worth pairing: a count check passes the duplicate set, and so
does a human looking at three thumbnails in a folder they cannot read.

## What mutation found in my own tests

Three assertions read stronger than they were:

- the release-precondition test matched a **filename** where it should have
  matched the comparison — replacing the `grep` with `false` survived it;
- the rollout test's `\S+` matched the **next table pipe**, so a blank watcher
  cell passed;
- the data-loss assertion matched the **whole document**, where the phrase also
  appears in a paragraph about which signal to trust.

All three now assert the structural property. The first is the same shape as the
`PrivacyInfo` finding — a check that passes on the thing being absent.

## Per task

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
- 19.6 store listing — done, with two caveats worth carrying.
  **Sorani has not been read by a native speaker.** §18.11 names that as the
  largest single risk to the RTL launch and it is still open; the copy is the
  same shape as the other five and should be reviewed BEFORE submission.
  **The screenshots are from a fresh install**, so Costs and History are empty
  states and the set uses Home, Reminders and Settings instead. Richer shots
  need a seeded device; the capture script takes a locale list and can be re-run.
- 19.7 release build — done. Found the DEBUG banner (it was in every screenshot ever taken in this repo). release.sh --dry-run refuses today, correctly: the design review is NOT SIGNED. The workflow does not upload, by design.
- 19.8 manual checks — partly done, honestly. New artifact-level gate (binary symbol/link inspection) partly replaces the merged-manifest evidence iOS lost. The aeroplane-mode walk is NOT done: it needs real hardware and the real artifact, and is recorded as outstanding.
- 19.9 submission record — done. Export compliance answered in writing (no encryption; the backup is plain by design and crypto only hashes), which is the question most likely to be answered wrongly out of caution.
- 19.10 the ritual — config only, NOT run. Blocked twice: the developer has not
  asked for a release by name, and `design/review/SIGNOFF-2026-09-08.md` reads
  NOT SIGNED. `tools/release.sh --dry-run` refuses today and names the review
  among its reasons, which is the correct answer.

## What `/simplify` found

Four review passes over the branch. Two findings were about the gates
themselves being at the wrong altitude, and both were right.

**The release gate was tested by grepping the script.** A mutation replacing a
`grep` with `false` had already survived it once during the task, and my fix at
the time was to match a *longer* string — the same altitude, one notch tighter.
`check_gates_selftest.sh` now has five arms that RUN `release.sh --dry-run` over
a scratch tree with one precondition broken at a time. A dry run that exits 0
provably checked everything and built nothing, whatever its messages say.

**The icon could drift from the token it claims to read.** `generate.py`'s own
docstring argues that a palette living in two files disagrees with itself — and
then commits thirteen PNGs, which are that second file. Nothing checked a pixel
against `--color-brand`. It does now, by inflating the 1024's IDAT; seen to fail
by moving the token one digit. This is the same shape as the `PrivacyInfo`
finding: a claim that would have passed on the thing being absent.

The rest: `debug_affordances` went through the existing `expectNoBannedPatterns`
(which skips generated code and fails on an empty walk, neither of which my hand
walk did) and now asserts the banner by finding no `CheckedModeBanner` in the
tree; a shared PNG header reader replaced three copies and reads 26 bytes rather
than 8 MB; the store gates take their locale list from the app's rather than a
seventh hand-typed copy; two vacuous guards went; and the capture script carried
a comment describing a step it does not take.

## What `/code-review` found

Eight findings, three of which say a gate this epic ADDS does not check what it
claims. All three are the same shape, and it is the shape this epic kept
meeting: **a check that passes on the thing being absent.**

**The signing test was vacuous for the target that ships.** `CODE_SIGN_STYLE =
Manual` appeared three times and the test was green — all three on
**RunnerTests**. The app target declared the key nowhere at all, which Xcode
reads as `Automatic`, and it inherited `CODE_SIGN_IDENTITY = "iPhone Developer"`
on Release: an archive signed with a *development* identity, rejected at upload,
burning a build number that can never be reused. My own commit message had
claimed this fixed "three sites including Release". It was not.

**The release self-test arms were red for the wrong reason.** The scratch copy
brings `.git` along, so editing a tracked file leaves the tree dirty and
`release.sh` fails precondition 1 — the clean tree — before reaching the arm's
own rule. Deleting the signoff, build-number, checks and changelog checks from
the script entirely left all four arms still passing. Four gates that had never
been seen to fail, added in the same session as a note about how gates that have
only ever been green are comments.

**`check_binary_offline.sh` read the wrong binary.** `Runner` is the thin Swift
host; the Dart AOT image is `Frameworks/App.framework/App`, each plugin is its
own framework, and `dart:io`'s sockets are serviced by the engine. A package
that opened a socket left no trace where the gate looked. The gate written
specifically to partly replace the merged-manifest evidence was green by
construction.

The rest were real too: the release keychain was never put on the search list
(imported and then not found) and never had its auto-lock disabled (relocked
part-way through a 45-minute archive); no provisioning profile was installed and
the team never reached `xcodebuild`, so manual signing could not archive at all;
`release.sh` silently ignored `--dryrun` and built for real; `ExportOptions.plist`
was checked only after minutes of compiling; and the privacy sheet's dependency
assertion exempted every `flutter_*` package — which is all three with a native
side.

## What is NOT done, and why

**Task 19.10's ritual is not run.** It requires the developer to ask for a
release by name, and it is blocked besides — see below. `tools/release.sh
--dry-run` refuses today and names its reasons.

**The aeroplane-mode walk is not done.** §17's offline gate ends in a manual
pass from a clean install on a device that has never been online. A simulator
borrows the host's networking, so toggling the Mac's Wi-Fi tests the Mac. It
needs real hardware and the real artifact. Recorded as outstanding in
`release/checks/1.0.0+1.md` rather than quietly satisfied by the two automated
gates, which answer a narrower question — and it now carries more of the offline
gate than the two-platform epic asked it to.

**Sorani has not been read by a native speaker.** §18.11 names that as the
largest single risk to the RTL launch. The store copy is written to the same
shape as the other five and should be reviewed *before* submission.

**The store screenshots are from a fresh install**, so Costs and History are
empty states; the set uses Home, Reminders and Settings instead. Richer shots
need a seeded device. `tools/capture_store_screenshots.sh` takes a locale list
and can be re-run.

## The blocker

`design/review/SIGNOFF-2026-09-08.md` reads **NOT SIGNED**, and says why: the
band profile fails on 106 of 112 parity comparisons and no release build has
ever been looked at. EPIC-19 makes that file a precondition of the ritual;
`tools/release.sh` checks it and refuses.

Signing it to unblock a checklist would make this epic's first assumption false.
It stays unsigned until the parity work behind it is done — which is the real
remaining work between here and the App Store.
