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

    if backups == 0:
        print("FAIL  no backup example (\"format\": \"odova.backup\") in SPEC.md")
        fail = 1

    if not fail:
        print(f"ok    {len(blocks)} json block(s) parse; "
              f"{backups} backup example(s) self-consistent")
    return fail


if __name__ == "__main__":
    sys.exit(main())
