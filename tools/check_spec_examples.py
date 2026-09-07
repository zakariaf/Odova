#!/usr/bin/env python3
"""Gate: the worked examples in SPEC.md are valid.

The backup file format is the app's whole persistence story, and the worked
example in the spec is what an engineer copies into a validator. An example that
does not parse is a bug in the specification, so it fails the build like any
other.

Checks:
  1. Every ```json block in SPEC.md parses as JSON.
  2. The backup envelope carries the keys the spec says it must.
  3. `record_counts` agrees with the actual array lengths in the same example.
  4. Every record id in an example is one the app could actually write — a
     ULID in Crockford base32, which has no I, L, O or U.
"""
import json
import re
import sys
from pathlib import Path

SPEC = Path(__file__).resolve().parent.parent / "SPEC.md"
ENVELOPE = ["format", "format_version", "app_version", "exported_at",
            "units", "record_counts", "settings", "vehicles"]
ARRAYS = ["vehicles", "reminders", "odometer_readings", "odometer_corrections",
          "fillups", "services", "expenses", "trips"]


def main() -> int:
    text = SPEC.read_text(encoding="utf-8")
    blocks = re.findall(r"```json\n(.*?)\n```", text, re.S)
    if not blocks:
        print("FAIL  no ```json blocks found in SPEC.md")
        return 1

    fail = 0
    backups = 0
    for i, block in enumerate(blocks, 1):
        try:
            doc = json.loads(block)
        except json.JSONDecodeError as e:
            print(f"FAIL  json block {i} does not parse: {e}")
            fail = 1
            continue

        if not isinstance(doc, dict) or doc.get("format") != "odova.backup":
            continue
        backups += 1

        missing = [k for k in ENVELOPE if k not in doc]
        if missing:
            print(f"FAIL  backup example (block {i}) is missing: {', '.join(missing)}")
            fail = 1

        counts = doc.get("record_counts", {})
        for key in ARRAYS:
            if key not in doc:
                continue
            actual = len(doc[key])
            declared = counts.get(key)
            if declared is not None and declared != actual:
                print(f"FAIL  record_counts.{key} says {declared}, "
                      f"the example holds {actual}")
                fail = 1

        for bad in _bad_ids(doc):
            print(f"FAIL  \"{bad}\" is not an id Odova could ever write: "
                  f"a ULID is Crockford base32, which excludes I, L, O and U")
            fail = 1

    if backups == 0:
        print("FAIL  no backup example (\"format\": \"odova.backup\") in SPEC.md")
        fail = 1

    if not fail:
        print(f"ok    {len(blocks)} json block(s) parse; "
              f"{backups} backup example(s) self-consistent")
    return fail


# Crockford base32 leaves out I, L, O and U so a human reading an id aloud
# cannot turn a 1 into an l or a 0 into an O. `RecordId.tryParse` enforces it,
# which means an example carrying one of those letters is an example the app
# would REFUSE to import — and the round-trip test that found it had to be told
# the spec was wrong rather than the code. Cheaper to catch here.
CROCKFORD = set("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
ID_PATTERN = re.compile(r"\b(?:veh|rem|odo|cor|fil|srv|lin|exp|trp)_([0-9A-Za-z]{26})\b")


def _bad_ids(node):
    """Every prefixed id in `node` whose ULID half is not Crockford base32."""
    out = []
    if isinstance(node, dict):
        for value in node.values():
            out += _bad_ids(value)
    elif isinstance(node, list):
        for item in node:
            out += _bad_ids(item)
    elif isinstance(node, str):
        for match in ID_PATTERN.finditer(node):
            if set(match.group(1)) - CROCKFORD:
                out.append(match.group(0))
    return out


if __name__ == "__main__":
    sys.exit(main())
