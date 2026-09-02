# Security and privacy

## The short version

Odova has no server, no account and no network code. Your data is on your phone
and in whatever backup file you chose to save. Nobody — including the author —
can see it, lose it, subpoena it or leak it, because nobody else ever has it.

## The backup file is not encrypted, on purpose

Export writes a plain JSON file. Anyone who can read that file can read your
whole history: your vehicles, where you fill up, what you spend, your plate and
VIN if you entered them.

That is a deliberate trade, and it is worth stating the reasoning plainly. An
encrypted backup needs a password. A password protecting a file you open once
every three years is a password you will not remember, and there is no account
and no server to recover it from — so an encrypted backup would mean people
permanently losing the eight years of history the app exists to protect. A file
the user can read in a text editor and restore on any phone, forever, is worth
more than a lock nobody can open.

**So: treat the backup like a document, not like a password.** Keep it somewhere
you would keep a bank statement. Think before you email it to yourself, and
before you attach one to a bug report — never do the latter.

## Reporting a vulnerability

Report privately through
[GitHub Security Advisories](https://github.com/zakariaf/Odova/security/advisories/new)
rather than a public issue.

Please include what an attacker gains and how you reproduce it. Expect a first
response within a week — this is a single-maintainer project, not a company.

**In scope:** anything that moves user data off the device, any path that makes
the app perform a network request, data loss or corruption across import,
migration or app update, and any way to read another app's or another user's
Odova data on the same device.

**Out of scope:** that the backup file is unencrypted (see above), and anything
that requires an already-compromised or physically unlocked device.
