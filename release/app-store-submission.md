# App Store submission — Odova 1.0.0

Written before submission, so nothing here is derived under pressure.

## Odova ships no in-app purchase

`release-and-store-shipping` rule 15 says a **first** release must submit the app
version *and* its first in-app purchase in one submission, or App Review closes
it unreviewed under Guideline 2.1(b). That rule is the most expensive thing in
the skill to get wrong, and **it does not apply here.**

SPEC.md §15 puts ads, in-app purchase and every other form of monetisation out
of v1. There is no purchase of any type to attach, so

```
GET /v1/reviewSubmissions/{id}/items
```

correctly returns **1** item, not 2 — and a `1` is the right answer rather than
the symptom of a forgotten attachment. Nobody should spend an afternoon under
submission pressure re-deriving that.

The **Paid Applications Agreement is not required**: it governs paid apps and
in-app purchases, and Odova is free with neither. Signing it would be answering
a question nobody asked.

If a purchase is ever added, `test/policy/no_iap_test.dart` fails and this
paragraph is rewritten in the same pull request. That is the whole mechanism —
the claim is pinned to a test rather than to a memory.

## Account-holder-only gates

None of these has an API. Each blocks submission with a message that names a
symptom rather than the setting, so each is raised on day one and dated here.

| Gate | Who | Status | Date |
|---|---|---|---|
| App record created in App Store Connect (`io.applander.odova`) | Account Holder | **done** — Apple ID `6810617822` | 2026-09-10 |
| Bundle ID registered on the Developer portal | Account Holder | **done** — `io.applander.odova`, resource id `AN23Q8L9KB`, name "Odova", platform Universal | 2026-09-10 |
| Privacy questionnaire answered (from `store/privacy-answers.md`) | Account Holder | not done — **no API exists**, see below | — |
| Age rating questionnaire | Account Holder | **done** — every descriptor `NONE`, rated 4+ / Brazil L | 2026-09-10 |
| Paid Applications Agreement | Account Holder | **not required** — free app, no IAP | 2026-09-09 |
| Export compliance answer | ~~Account Holder~~ the plist | **done in the repo** — `ITSAppUsesNonExemptEncryption = false`, see below | 2026-09-10 |

**Export compliance** deserves its own line, because the honest answer is
unusually short. The question is whether the app uses encryption. Odova uses
none: no HTTPS (there is no network), no encrypted backup (§2 says the backup is
a **plain, unencrypted JSON file the user keeps**), and no encrypted database.
`crypto` is in the dependency list and hashes inside the backup file for
integrity — hashing is not encryption, and the exemption for it is standard.
The answer is therefore "no" to the encryption question, and the reason is
written here so nobody answers "yes, standard algorithms" out of caution and
inherits an annual self-classification report they do not owe.

It is no longer a person's job to answer it. `ios/Runner/Info.plist` now
declares `ITSAppUsesNonExemptEncryption = false`, which is the same answer given
once instead of at every upload, and
`test/policy/ios_capabilities_test.dart` pins it — so the day someone flips it
to `true` for a plugin, the change is reviewed rather than typed into a web form
by whoever happened to be uploading.

## The bundle identifier

`io.applander.odova`, registered 2026-09-10 through the App Store Connect API.
Its resource id is `AN23Q8L9KB` and its platform is **Universal** — Apple
returns Universal for a newly created identifier regardless of what the request
asks for, which costs nothing and leaves a Mac target open if one is ever
wanted.

The identifier is pinned by `test/policy/platform_test.dart`, which asserts
both `PRODUCT_BUNDLE_IDENTIFIER` and the Android `applicationId`. It is not a
credential and is recorded here on purpose; the team id is not, because the
Xcode project deliberately carries no `DEVELOPMENT_TEAM` and CI supplies it.

**Apple enabled `IN_APP_PURCHASE` on the identifier by default.** That is the
portal's behaviour for every new bundle id and is not a claim that the app has
one. It does not affect the no-IAP position above: Guideline 2.1(b) is about a
submitted in-app purchase *product*, and `reviewSubmissions/{id}/items` counts
products rather than capabilities. There are none, `test/policy/no_iap_test.dart`
keeps it that way, and the capability can be switched off in the portal if a
reviewer ever asks why it is on.

## The listing, as configured

Everything below was written through the App Store Connect API on 2026-09-10,
against app `6810617822`, version `1.0.0` in `PREPARE_FOR_SUBMISSION`.

| Field | Value |
|---|---|
| Version | `1.0.0`, `releaseType: MANUAL` — the release is a decision, not a side effect of approval |
| Categories | Utilities (primary), Productivity (secondary) |
| Age rating | 4+ — every content descriptor `NONE`, every boolean false |
| Content rights | `DOES_NOT_USE_THIRD_PARTY_CONTENT` |
| Copyright | `2026 Zakaria Fatahi` |
| Price | Free, base territory USA, all 175 territories, `availableInNewTerritories: true` |
| Screenshots | 80 uploaded — ten 6.9-inch (1320×2868) and ten 13-inch (2048×2732) in each of four locales. 120 are captured; `fa` and `ckb` have a full set in the repo and no listing to carry them |
| Privacy policy | `https://odova.applander.io/privacy` |
| Support | `https://odova.applander.io/support` |
| Marketing | `https://odova.applander.io` |

### Four listing locales, not six

The app ships six languages. The listing carries **four**: `en-US`, `de-DE`,
`fr-FR`, `ar-SA`. Apple rejects `fa`, `fa-IR`, `ckb`, `ku` and `ku-Arab` with
`409 "The language specified is not listed for localization"` — Persian and
Kurdish Sorani are not App Store listing locales at all, whatever the app
supports.

This is worth writing down rather than quietly shipping four. A Persian- or
Sorani-speaking user finds Odova through an English or Arabic page and then
discovers their language inside the app. Nothing in the store copy can say so in
their language, so the English and Arabic descriptions both name all six
languages explicitly — that sentence is the only place a search can find them.

### App Privacy has no API

`store/privacy-answers.md` still has to be typed into App Store Connect by hand.
This is not an oversight: the app resource exposes 41 relationships and none of
them is data usage. `appDataUsages`, `appDataUsageCategories` and
`appDataUsagesPublishState` all return `404 PATH_ERROR — the resource does not
exist`. The nutrition label is web-UI only, so it is the one gate in this file
that no script can close, and `store/privacy-answers.md` exists precisely so
that the person typing it is not composing the answers at the same time.

### App Review contact

`appStoreReviewDetails` requires `contactPhone` in `+<country code> <number>`
form and rejects the record without it. Name, email, the "no demo account
because there are no accounts" note and the reviewer walkthrough are written and
waiting on that one field.

## Build 1.0.0+1

Built and uploaded 2026-09-10 over an unsigned design review — see
`release/UNSIGNED-BUILD.md`, which records that decision and what it knowingly
leaves unfinished. Uploading is not submitting: the version stays in
`PREPARE_FOR_SUBMISSION` with `releaseType: MANUAL`, and the sign-off is still
the gate on submission.

| | |
|---|---|
| Artifact | `build/ios/ipa/odova.ipa`, 22 MB, `--obfuscate` with symbols in `build/symbols/1.0.0+1` |
| Offline gate | 7 Mach-O binaries in the bundle, none reaching the network |
| Validation | `altool --validate-app` — VERIFY SUCCEEDED, no errors |
| Build number | **1, now spent.** Recorded in `release/uploaded-build-numbers.txt`, and `release.sh` refuses it from here on |

The build exists so items 3 and 4 of the sign-off — build `costs.fuel` to its
reference, and run the four design lenses **on a release build** — can be done
against the artifact a user would actually get. That was the deadlock: neither
could happen without a build, and no build could be made without them.

### The signing identity moved, and one certificate was revoked

The only Apple Distribution identity on the release machine was sealed inside a
keychain whose password was lost, so no release could be signed at all — the
archive fell back to a development identity and `CodeSign` failed. The account
was also at Apple's three-certificate cap, so a replacement could not simply be
added.

The stranded certificate was revoked and a new one issued into the login
keychain, with a fresh private key. **Two profiles for other apps on the same
account went `INVALID` and must be regenerated before those apps upload again.**
Nothing already on the App Store is affected: Apple re-signs App Store
deliveries, so revocation reaches future uploads and not shipped apps.

## Who holds what

| Credential | Held by | Recoverable? |
|---|---|---|
| App Store Connect API key (`.p8`) | Account Holder, outside the repo | yes — revoke and reissue in minutes |
| Distribution certificate | Account Holder, outside the repo | yes, while the account has revocation access |

Kept separate deliberately. An ASC key can be revoked and reissued; a lost
distribution certificate with no revocation access is a listing that cannot be
updated. Neither is in the working tree or in `git log --all`, and
`tools/check_release_hygiene.sh` has been seen to fail on both.

## Not submitted

`design/review/SIGNOFF-2026-09-08.md` reads **NOT SIGNED**, and
`tools/release.sh` refuses while it does. See `release/checks/1.0.0+1.md`.
