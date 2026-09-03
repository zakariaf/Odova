#!/usr/bin/env bash
# Contract: the coverage report covers only code somebody wrote.
#
#   usage: strip_generated_from_lcov.sh [LCOV_FILE] [ANALYSIS_OPTIONS]
#          (defaults: coverage/lcov.info, analysis_options.yaml)
#
# Coverage here is a PUBLISHED REPORT, never a gate — there is no threshold in
# CI and no paid service. It still has to be honest: generated code is large and
# is fully exercised by whatever calls it, so leaving lib/l10n/gen/ and the
# *.g.dart / *.freezed.dart / *.drift.dart families in the report inflates the
# total by thousands of lines nobody wrote or reviewed.
#
# The globs are READ from analyzer.exclude rather than retyped here. That file's
# own header states the contract — "excludes and coverage filters that drift
# apart lie the coverage number upward".
#
# The second argument exists so test/policy/lint_test.dart can point this at a
# temporary options file carrying a different glob and assert the output
# follows. That proves the single source of truth is READ; a grep for the glob
# strings would only prove nobody typed one particular string.
set -euo pipefail
cd "$(dirname "$0")/.."

lcov="${1:-coverage/lcov.info}"
options="${2:-analysis_options.yaml}"
[ -f "$lcov" ] || { echo "strip_generated_from_lcov: no such file: $lcov" >&2; exit 1; }
[ -f "$options" ] || { echo "strip_generated_from_lcov: no such file: $options" >&2; exit 1; }

python3 - "$lcov" "$options" <<'PY'
import fnmatch
import pathlib
import re
import sys

lcov = pathlib.Path(sys.argv[1])
options = pathlib.Path(sys.argv[2]).read_text()

block = re.search(r"^  exclude:\s*$\n((?:^    - .*$\n?)+)", options, re.M)
if block is None:
    sys.exit(f"strip_generated_from_lcov: {sys.argv[2]} has no analyzer.exclude")

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


# Split on the marker with an OPTIONAL newline: a file whose final record ends
# `end_of_record` with no trailing newline would otherwise keep the literal
# inside the record text and get a second one appended on write.
records = re.split(r"end_of_record\n?", lcov.read_text())
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
