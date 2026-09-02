#!/usr/bin/env python3
"""Gate: every skill in .claude/skills/ has frontmatter Claude can actually read.

The failure this exists to catch is silent. A `description:` written as a PLAIN
(unquoted) YAML scalar breaks the moment it contains a ": " sequence — YAML reads
that as a nested mapping and the whole frontmatter fails to parse. The skill still
loads, but with EMPTY METADATA, so it can never be auto-invoked: it only works if
someone types its name. Nothing warns you, and `claude plugin validate` passes.

Two of the 40 vendored skills shipped with exactly this bug (`async-safety`, whose
description contains `onTap: () => vm.save(x)`, and `design-review-workflow`, whose
description contains `release build: a screenshot sweep`).

The fix is always the same: use a folded block scalar.

    description: >-
      Text that may contain: colons, freely.
"""
import os
import re
import sys

try:
    import yaml
except ImportError:
    print("skip  PyYAML not installed; frontmatter not checked")
    sys.exit(0)

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                    ".claude", "skills")
# Display-only truncation in the skill listing. Past this, the trigger phrases at
# the end of a description — the part that makes a skill get found — are cut.
LISTING_LIMIT = 1536


def main() -> int:
    if not os.path.isdir(ROOT):
        print(f"skip  no {ROOT}")
        return 0

    fail = 0
    n = 0
    for d in sorted(os.listdir(ROOT)):
        p = os.path.join(ROOT, d, "SKILL.md")
        if not os.path.isfile(p):
            continue
        n += 1
        raw = open(p, encoding="utf-8").read()

        if not raw.startswith("---"):
            print(f"FAIL  {d}: frontmatter must start on line 1, byte 0")
            fail = 1
            continue

        try:
            fm = yaml.safe_load(raw.split("---", 2)[1])
        except yaml.YAMLError as e:
            first = str(e).split("\n")[0]
            print(f"FAIL  {d}: frontmatter does not parse — {first}")
            print("      The skill will load with EMPTY metadata and never be "
                  "auto-invoked.")
            print("      Fix: write the description as a folded block "
                  "(`description: >-`).")
            fail = 1
            continue

        if not isinstance(fm, dict):
            print(f"FAIL  {d}: frontmatter is {type(fm).__name__}, not a mapping")
            fail = 1
            continue
        for key in ("name", "description"):
            if not fm.get(key):
                print(f"FAIL  {d}: frontmatter has no usable `{key}`")
                fail = 1
        if fm.get("name") and fm["name"] != d:
            print(f"FAIL  {d}: frontmatter name is {fm['name']!r}, "
                  f"which does not match the directory")
            fail = 1
        desc = fm.get("description") or ""
        if len(desc) > LISTING_LIMIT:
            print(f"FAIL  {d}: description is {len(desc)} chars; the skill listing "
                  f"truncates at {LISTING_LIMIT}, which cuts the trigger phrases "
                  f"that make it discoverable")
            fail = 1

    if not fail:
        print(f"ok    {n} skills: frontmatter parses, names match, descriptions "
              f"within the listing limit")
    return fail


if __name__ == "__main__":
    sys.exit(main())
