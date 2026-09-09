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
| App record created in App Store Connect (`io.applander.odova`) | Account Holder | not done | — |
| Bundle ID registered on the Developer portal | Account Holder | not done | — |
| Privacy questionnaire answered (from `store/privacy-answers.md`) | Account Holder | not done | — |
| Age rating questionnaire | Account Holder | not done | — |
| Paid Applications Agreement | Account Holder | **not required** — free app, no IAP | 2026-09-09 |
| Export compliance answer | Account Holder | not done — see below | — |

**Export compliance** deserves its own line, because the honest answer is
unusually short. The question is whether the app uses encryption. Odova uses
none: no HTTPS (there is no network), no encrypted backup (§2 says the backup is
a **plain, unencrypted JSON file the user keeps**), and no encrypted database.
`crypto` is in the dependency list and hashes inside the backup file for
integrity — hashing is not encryption, and the exemption for it is standard.
The answer is therefore "no" to the encryption question, and the reason is
written here so nobody answers "yes, standard algorithms" out of caution and
inherits an annual self-classification report they do not owe.

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
