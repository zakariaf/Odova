#!/usr/bin/env bash
# Contract: analysis_options.yaml's `include:` resolves to a file that actually
# exists in the resolved package.
#
# This is the one lint failure that is completely silent. `include:` naming a
# file the package does not ship makes analysis run with ZERO added rules —
# `flutter analyze` then reports green over a codebase nobody is checking. It
# happens on every very_good_analysis bump, because the filename carries the
# version and bumping the constraint without bumping the filename is one line
# out of two.
#
# Resolution goes through .dart_tool/package_config.json rather than guessing at
# PUB_CACHE, so a relocated cache cannot turn this gate into a skip.
set -uo pipefail
cd "$(dirname "$0")/.."

options=analysis_options.yaml
config=.dart_tool/package_config.json

[ -f "$options" ] || { echo "FAIL  $options is missing"; exit 1; }

include=$(sed -nE 's|^include:[[:space:]]*package:([A-Za-z0-9_]+)/(.+)$|\1 \2|p' "$options")
if [ -z "$include" ]; then
  echo "ok    $options has no package: include — nothing to resolve"
  exit 0
fi
pkg=${include%% *}
rel=${include#* }

if [ ! -f "$config" ]; then
  echo "FAIL  $config is missing — run 'flutter pub get' first."
  echo "      Without it the include cannot be resolved, and an unresolved"
  echo "      include is indistinguishable from a working one at analyze time."
  exit 1
fi

root=$(python3 - "$config" "$pkg" <<'PY'
import json, pathlib, sys, urllib.parse
config, name = pathlib.Path(sys.argv[1]), sys.argv[2]
for p in json.loads(config.read_text())["packages"]:
    if p["name"] == name:
        # rootUri is either absolute (file:///...) or relative to .dart_tool/.
        raw = p["rootUri"]
        if raw.startswith("file:"):
            base = pathlib.Path(urllib.parse.unquote(urllib.parse.urlparse(raw).path))
        else:
            base = (config.parent / urllib.parse.unquote(raw)).resolve()
        print(base / p.get("packageUri", "lib/"))
        break
PY
)

if [ -z "$root" ]; then
  echo "FAIL  '$pkg' is not in $config — the include names a package that is"
  echo "      not a dependency, so it contributes no rules at all."
  exit 1
fi

if [ -f "$root/$rel" ]; then
  echo "ok    lint include resolves: $root/$rel"
  exit 0
fi

echo "FAIL  '$rel' is not in the resolved '$pkg' — analysis is running with"
echo "      ZERO added rules and reporting green."
echo "      available:"
ls "$root" | sed 's/^/        /'
exit 1
