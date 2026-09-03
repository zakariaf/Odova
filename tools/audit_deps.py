#!/usr/bin/env python3
"""Audit the FULL transitive pub dependency tree against Odova's ban list.

Vendored from .claude/skills/dependency-hygiene/scripts/audit_deps.py and
edited to encode this project's policy. SPEC.md §2's first non-negotiable is
that the app ships with no networking code at all — "a promise you can only
keep by policy is not a promise; one you keep by having no client is". This
script is what makes that structural rather than aspirational.

Usage (from the repo root):
    dart pub deps --json > /tmp/deps.json
    python3 tools/audit_deps.py /tmp/deps.json

Exit 0 = clean. Exit 1 = a banned package ships in the binary, directly or
transitively. Exit 2 = usage/parse error. Direct-only inspection of pubspec.yaml
cannot find transitive hits; that is the entire point of walking the resolved
graph, and tools/check_gates_selftest.sh has an arm that plants one two hops
down.
"""

import json
import re
import sys

# Substring/regex patterns matched case-insensitively against package names.
# Each entry names WHY it is refused, because a ban list without reasons is a
# list somebody edits.
BANNED = [
    # --- network clients. CLAUDE.md rule 1 refuses these permanently. -------
    (r"^http$|^dio$|^web_socket|^grpc$|^socket_io", "a network client — SPEC.md §2: the app ships with no networking code"),
    (r"^googleapis|^google_sign_in|^firebase_auth", "accounts and network — SPEC.md §2: no account, no server"),
    # --- fonts. Named in CLAUDE.md rule 1 and by calm-tokens. ---------------
    (r"^google_fonts$", "downloads fonts over HTTP. Vazirmatn and the Latin face are bundled assets; see SPEC.md §5 Fonts"),
    # --- telemetry. There is no server to send it to, and no consent screen
    #     that would make one honest. --------------------------------------
    (r"^firebase", "Firebase — its core registers device/usage data categories"),
    (r"^cloud_fire", "Firebase (Firestore) — same core"),
    (r"crashlytics", "crash reporting is telemetry"),
    (r"sentry", "crash reporting is telemetry"),
    (r"analytics", "analytics of any kind is refused by policy"),
    (r"^posthog|^mixpanel|^amplitude|^segment", "product analytics"),
    (r"^google_mobile_ads|^appsflyer|^adjust", "ads/attribution SDK — network and identifiers"),
    # --- device identifiers. ------------------------------------------------
    (r"^device_info_plus", "device identifiers with no shipped use"),
    (r"^package_info_plus", "see the ALLOW note below — the decision is deliberate"),
]

# Names that match a BANNED pattern but are deliberately kept. A name goes here
# ONLY with a written justification: why the reachable-but-inert dependency is
# acceptable, and what the real enforced gate is instead.
#
# package_info_plus is the one that was a real question rather than a
# hypothetical, so the answer is recorded here rather than left to the next
# person to re-litigate. SPEC.md §6 and §17 put `app_version` and `app_build`
# in the backup file, so there IS a shipped use. It stays banned anyway: the
# same two strings are available at build time for nothing, and the plugin adds
# native code on both platforms plus `installerStore` and `appName`, none of
# which Odova wants. The version reaches the app through
# `--dart-define=ODOVA_VERSION` / `ODOVA_BUILD`, read with
# `String.fromEnvironment`. Revisit only if something needs a value that is
# genuinely not knowable at build time.
ALLOW: set[str] = set()

# Packages that are test harnesses, whatever declares them.
#
# This is a statement about the MODEL, not an exemption for a name. The naive
# rule — "what ships is what `dependencies:` drags in" — assumes a runtime
# dependency never pulls in a test framework. flutter_riverpod 3.x breaks that
# assumption: it exports `RiverpodWidgetTesterX`, a `WidgetTester` extension,
# so `flutter_test` is one of its regular dependencies. Everything the test
# framework pulls in — `test`, and through it `web_socket_channel` and
# `web_socket` — then appears to ship, and the gate goes red over a socket no
# release binary can reach.
#
# The walk therefore stops at these names rather than traversing them, and
# whatever is reachable ONLY through them is reported as build/test noise. A
# banned package that is ALSO reachable by a real runtime path is still a hit;
# there is a fixture in tools/check_gates_selftest.sh for exactly that case.
#
# Two things keep this from becoming a hole:
#
#   * it cannot hide a network call in Odova's own code, because the dependency
#     graph was never able to see one — `dart:io` hands you `HttpClient` and
#     `Socket` with no dependency at all. test/policy/no_network_test.dart is
#     the gate for that, and it is the one that matters most.
#   * the app declares no INTERNET permission in ANY Android manifest
#     (test/policy/platform_test.dart). On Android a socket without it does not
#     fail politely; it cannot be opened. That is SPEC.md §2's "by
#     construction", and it holds whatever the dependency graph says.
#
# What is excluded is printed on every run, so nobody finds it by surprise.
NEVER_SHIPS = frozenset(
    {"flutter_test", "integration_test", "flutter_driver", "test"}
)

USAGE = """usage: audit_deps.py <deps.json>

Generate the input first (from the repo / workspace root):
    dart pub deps --json > deps.json

Flags any banned package in the resolved tree and says whether it arrived
directly or transitively. Exits 1 on a shipping hit so it can gate CI."""


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] in ("-h", "--help"):
        print(USAGE, file=sys.stderr)
        return 2
    try:
        with open(sys.argv[1]) as f:
            data = json.load(f)
    except OSError as e:
        print(f"audit_deps: cannot read {sys.argv[1]}: {e}", file=sys.stderr)
        return 2
    except json.JSONDecodeError as e:
        print(f"audit_deps: {sys.argv[1]} is not valid JSON: {e}", file=sys.stderr)
        print("  (expected the output of: dart pub deps --json)", file=sys.stderr)
        return 2

    pkgs = {p["name"]: p for p in data.get("packages", [])}
    names = {n for n, p in pkgs.items() if p.get("kind") != "root"}

    def reachable(roots: set[str], *, stop_at: frozenset[str] = frozenset()) -> set[str]:
        """Everything [roots] pulls in transitively, not descending into [stop_at]."""
        seen: set[str] = set()
        stack = list(roots)
        while stack:
            n = stack.pop()
            if n in seen or n not in pkgs or n in stop_at:
                continue
            seen.add(n)
            stack.extend(pkgs[n].get("dependencies", []))
        return seen

    def declared(kind: str) -> set[str]:
        return {n for n, p in pkgs.items() if p.get("kind") == kind}

    # What ships is what `dependencies:` drags in, minus the test harnesses in
    # NEVER_SHIPS and anything reachable only through them. `dev_dependencies:`
    # (build_runner, codegen, the test framework) never reach the binary, so a
    # banned package that is ONLY dev-reachable is not a shipping defect —
    # build_runner legitimately pulls a local HTTP server for watch mode, and a
    # gate that fails on that gets switched off.
    ships = reachable(declared("direct"), stop_at=NEVER_SHIPS)
    dev_only = reachable(declared("dev") | (NEVER_SHIPS & names)) - ships

    def banned_in(pool: set[str]) -> list[tuple[str, str]]:
        found = []
        for name in sorted(pool):
            if name in ALLOW:
                continue
            for pattern, why in BANNED:
                if re.search(pattern, name, re.IGNORECASE):
                    found.append((name, why))
                    break
        return found

    hits = banned_in(ships)
    noise = banned_in(dev_only)
    direct_names = {n for n, p in pkgs.items() if p.get("kind") == "direct"}

    harnesses = sorted(NEVER_SHIPS & names)
    print(f"{len(names)} resolved · {len(ships)} ship in the binary · {len(dev_only)} build/test only")
    if harnesses:
        print(f"        test harnesses not traversed: {', '.join(harnesses)}")
    for name, why in hits:
        how = "direct" if name in direct_names else "TRANSITIVE"
        print(f"BANNED  {name}  [{how}]\n        {why}")

    if noise:
        print("\nBuild/test only — not in the binary, not a defect:")
        for name, _ in noise:
            print(f"  {name}")

    if hits:
        print("\nRefuse the dependency, or find one that does not pull these in.")
        print("To see who pulls a package in:  dart pub deps | grep -B4 <name>")
        return 1

    print("\nClean: nothing banned reaches the binary.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
