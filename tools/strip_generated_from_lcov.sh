#!/usr/bin/env bash
# Contract: the coverage report covers only code somebody wrote.
#
#   usage: strip_generated_from_lcov.sh [LCOV_FILE]   (default: coverage/lcov.info)
#
# Coverage here is a PUBLISHED REPORT, never a gate — there is no threshold in
# CI and no paid service. It still has to be honest: generated code is large and
# is fully exercised by whatever calls it, so leaving lib/l10n/gen/ and the
# *.g.dart / *.freezed.dart / *.drift.dart families in the report inflates the
# total by thousands of lines nobody wrote or reviewed.
#
# The globs are READ from analysis_options.yaml's analyzer.exclude rather than
# retyped here. That file's own header states the contract — "excludes and
# coverage filters that drift apart lie the coverage number upward" — and
# test/policy/lint_test.dart fails if any consumer keeps a second copy.
set -euo pipefail
cd "$(dirname "$0")/.."

lcov="${1:-coverage/lcov.info}"
[ -f "$lcov" ] || { echo "strip_generated_from_lcov: no such file: $lcov" >&2; exit 1; }

python3 - "$lcov" <<'PY'
import fnmatch
import pathlib
import re
import sys

lcov = pathlib.Path(sys.argv[1])
options = pathlib.Path("analysis_options.yaml").read_text()

block = re.search(r"^  exclude:\s*$\n((?:^    - .*$\n?)+)", options, re.M)
if block is None:
    sys.exit("strip_generated_from_lcov: analysis_options.yaml has no analyzer.exclude")

globs = [
    line.split("-", 1)[1].strip().strip("'\"")
    for line in block.group(1).splitlines()
    if line.strip()
]
if not globs:
    sys.exit("strip_generated_from_lcov: analyzer.exclude parsed as empty")


def excluded(path: str) -> bool:
    # An analyzer glob is a path pattern; `**/x` also matches a bare `x`, and a
    # `dir/**` prefix matches everything under it.
    for glob in globs:
        if fnmatch.fnmatch(path, glob):
            return True
        if glob.startswith("**/") and fnmatch.fnmatch(path, glob[3:]):
            return True
        if fnmatch.fnmatch(path, f"**/{glob}"):
            return True
    return False


records = lcov.read_text().split("end_of_record\n")
kept = []
dropped = []
for record in records:
    match = re.search(r"^SF:(.+)$", record, re.M)
    if match is None:
        continue
    (dropped if excluded(match.group(1)) else kept).append(record)

lcov.write_text("end_of_record\n".join(kept) + ("end_of_record\n" if kept else ""))
print(
    f"strip_generated_from_lcov: kept {len(kept)} file(s), "
    f"dropped {len(dropped)} generated"
)
PY
