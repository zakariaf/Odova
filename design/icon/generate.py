#!/usr/bin/env python3
"""Generates Odova's app icon from the Calm tokens.

SPEC.md §2 allows "a colour swatch and a silhouette only" in v1, and that is
exactly what this draws: `--color-brand` behind, `--color-surface` in front, an
odometer needle sweeping a gauge. No photograph, no gradient, no third colour.

**The colours are READ from `design/calm/odova.css`, never typed here.** A
palette that lives in two files is a palette that disagrees with itself, and the
icon is the one surface where nobody notices for months.

Pure Python, no imaging dependency. SPEC.md §2 makes every added package
something to audit for a network path, and a PNG encoder is zlib plus a
sixteen-byte header. Anti-aliasing is 4x supersampling.

    python3 design/icon/generate.py
"""

import math
import re
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CSS = ROOT / "design/calm/odova.css"
OUT = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"

SS = 4  # supersampling factor


def token(name: str, *, occurrence: int = 0) -> tuple[int, int, int]:
    """The nth declaration of `--name` in the stylesheet, as RGB."""
    hits = re.findall(rf"--{name}:\s*#([0-9A-Fa-f]{{6}})", CSS.read_text())
    if len(hits) <= occurrence:
        raise SystemExit(f"--{name} #{occurrence} not found in {CSS}")
    value = hits[occurrence]
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def draw(size: int, back: tuple, front: tuple) -> bytes:
    """The gauge, rasterised at `size` square, as RGB rows."""
    n = size * SS
    cx = cy = n / 2
    # A dial that reads as one at 40 px and still has air at 1024.
    radius = n * 0.30
    stroke = n * 0.072
    # Sweeps from 150 deg round to 30 deg, leaving the gap at the bottom that
    # makes a dial read as a dial rather than as a ring.
    start, end = math.radians(150), math.radians(390)
    needle = math.radians(300)
    needle_len = radius * 0.92
    needle_w = n * 0.055
    hub = n * 0.072

    rows = []
    for y in range(n):
        row = bytearray()
        for x in range(n):
            dx, dy = x - cx, y - cy
            dist = math.hypot(dx, dy)
            on = False

            # The arc.
            if abs(dist - radius) <= stroke / 2:
                angle = math.atan2(dy, dx) % (2 * math.pi)
                if angle < start:
                    angle += 2 * math.pi
                on = start <= angle <= end

            # The needle: distance from the hub to a point along its direction.
            if not on:
                ux, uy = math.cos(needle), math.sin(needle)
                along = dx * ux + dy * uy
                if 0 <= along <= needle_len:
                    if abs(-dx * uy + dy * ux) <= needle_w / 2:
                        on = True

            if not on and dist <= hub:
                on = True

            row += bytes(front if on else back)
        rows.append(bytes(row))
    return downsample(rows, size)


def downsample(rows: list[bytes], size: int) -> bytes:
    """Box-filters the supersampled rows down to `size`, as PNG scanlines."""
    out = bytearray()
    for y in range(size):
        out.append(0)  # filter type 0, per scanline
        for x in range(size):
            acc = [0, 0, 0]
            for sy in range(SS):
                row = rows[y * SS + sy]
                for sx in range(SS):
                    base = ((x * SS) + sx) * 3
                    for c in range(3):
                        acc[c] += row[base + c]
            out += bytes(v // (SS * SS) for v in acc)
    return bytes(out)


def png(size: int, scanlines: bytes) -> bytes:
    """A truecolour PNG. NO alpha channel, deliberately.

    Colour type 2, not 6: App Store Connect rejects a 1024 marketing icon that
    carries alpha as ITMS-90717, and a rejected upload burns a build number that
    can never be reused. Emitting the same type for every size means the
    marketing icon cannot be the one that was generated differently.
    """

    def chunk(tag: bytes, body: bytes) -> bytes:
        return (
            struct.pack(">I", len(body))
            + tag
            + body
            + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF)
        )

    header = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"IDAT", zlib.compress(scanlines, 9))
        + chunk(b"IEND", b"")
    )


def main() -> None:
    import json

    back = token("color-brand")
    # The LIGHT surface, always. An app icon has one appearance; iOS does not
    # swap it for dark mode, and picking the dark token here would put a
    # near-black mark on a brown square for everybody.
    front = token("color-surface")

    catalog = json.loads((OUT / "Contents.json").read_text())
    wanted = set()
    for entry in catalog["images"]:
        if "filename" not in entry:
            continue
        points = float(entry["size"].split("x")[0])
        scale = int(entry.get("scale", "1x").rstrip("x"))
        wanted.add((round(points * scale), entry["filename"]))

    for size, name in sorted(wanted):
        (OUT / name).write_bytes(png(size, draw(size, back, front)))
        print(f"wrote {name} ({size}px)")


if __name__ == "__main__":
    main()
