# App Store privacy answers

One question per line, in App Store Connect's own wording, so the answers can be
transcribed without interpretation. `test/policy/privacy_answers_test.dart`
asserts the shape; the reasons are here so a stranger can check every line
against `pubspec.lock` in five minutes.

| | |
|---|---|
| **App** | Odova (`io.applander.odova`) |
| **Version** | 1.0.0+1 |
| **Written** | 2026-09-09 |
| **Basis** | SPEC.md §2 (no network of any kind), §15 (no ads, no analytics, no IAP) |

## Data collection

**Do you or your third-party partners collect data from this app?** — **No.**

That answer is only defensible because it is true by construction rather than by
policy: the app has no HTTP client, no socket, no analytics SDK and no crash
reporter, and `tools/audit_deps.sh` fails the build if one appears in the
resolved graph. There is nowhere for data to go.

Every data type is therefore **Not Collected**:

| Category | Answer |
|---|---|
| Contact Info | Not Collected |
| Health & Fitness | Not Collected |
| Financial Info | Not Collected |
| Location | Not Collected |
| Sensitive Info | Not Collected |
| Contacts | Not Collected |
| User Content | Not Collected |
| Browsing History | Not Collected |
| Search History | Not Collected |
| Identifiers | Not Collected |
| Purchases | Not Collected |
| Usage Data | Not Collected |
| Diagnostics | Not Collected |
| Other Data | Not Collected |

**Financial Info deserves a sentence, because the app plainly holds money.**
Fuel prices, service costs and running totals are the point of the product. They
are *stored*, on the device, in the user's own container — and "collect" in
Apple's sense means transmitted off the device. Nothing is transmitted. The
distinction is the whole of §2, and it is the one line on this sheet a reviewer
is most likely to query.

**Tracking:** No. `NSPrivacyTracking` is `false` and
`NSPrivacyTrackingDomains` is empty in `ios/Runner/PrivacyInfo.xcprivacy`.

## Required-reason APIs

| Category | Reason | Why |
|---|---|---|
| `NSPrivacyAccessedAPICategoryFileTimestamp` | `C617.1` | drift opens and stats the database file, and the backup writer reads the file's own timestamps. All inside the app container; nothing is sent, because there is nowhere to send it. |

Plugins declare their own — `path_provider_foundation` and the notification
plugin each ship a manifest and Xcode merges them. Repeating their entries here
would be this repo answering for code it does not own.

## Packages, and what each one buys

Checked against `pubspec.lock`. None opens a socket; `tools/audit_deps.sh`
enforces that on every build, and its BANNED list covers `http`, `dio`,
`web_socket_channel`, `grpc` and `socket_io`.

| Package | What it does | Collects anything? |
|---|---|---|
| `drift` | the local database | no |
| `sqlite3` | the SQLite bindings drift talks to | no |
| `sqlite3_flutter_libs` | ships the SQLite binary itself, so the app does not depend on the OS copy | no |
| `path_provider` | where the container is | no |
| `flutter_local_notifications` | schedules local reminders; no push, no server | no |
| `flutter_timezone` | the device's zone name, to fire reminders at the right local hour | no |
| `timezone` | the bundled TZ database | no |
| `intl` | formatting | no |
| `pdf` | the report the user shares themselves | no |
| `crypto` | hashing inside the backup file | no |
| `go_router`, `flutter_riverpod`, `clock`, `meta` | app plumbing | no |

## SPEC.md §18 decision 12 — the iOS container backup

**Open until now. Decided: leave it ON, and say so.**

The app's container is included in the user's iCloud/device backup, as any app's
is by default. The alternative — excluding it with
`NSURLIsExcludedFromBackupKey` — was considered and rejected:

- §1's fourth fact is that "their history is worth money and no server holds a
  copy". A user who restores a new phone from an iCloud backup and finds eight
  years of service history gone would have lost it to a privacy gesture they
  never asked for, and Odova's own backup file is a thing they must remember to
  make.
- The data does not leave the device *to us*. It goes to the user's own Apple
  account, under their own control, encrypted by Apple — which is a different
  claim from "we upload it", and one the copy already distinguishes.

**So the privacy copy must not say the data never leaves the phone**, because
under this decision it can. §13's About paragraph is already careful:

> No account. No sign-up. No server. Nothing is uploaded. No tracking, no
> analytics, no ads.

Every clause there is about **Odova** — no server of ours, nothing uploaded by
us. None of it is falsified by the user's own OS backup. The store description
holds to the same shape, and
`test/policy/privacy_claims_test.dart` refuses the absolute forms
("never leaves your phone", "cannot be backed up") that this decision would make
untrue.

**Decided by:** Zakaria Fatahi, 2026-09-09, on the record here.
