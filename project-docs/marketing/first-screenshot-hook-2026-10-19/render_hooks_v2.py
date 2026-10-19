#!/usr/bin/env python3
"""v2 of the first-screenshot hooks: less text.

Same headlines and renderer as render_hooks.py, but the screen drops the
coach's paragraph and tip. The capture is spliced so the coach card ends right
under "Coach would pass" and its three tiles, leaving the rack, the pick and
the verdict as the whole story.

Usage: python3 render_hooks_v2.py
Writes hook-<key>-v2-<slug>.png and contact-sheet-v2.png next to this file.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

import render_hooks as v1

HERE = Path(__file__).resolve().parent
TRIMMED = HERE / "source-charleston-perfect-pass-trimmed.png"

KEEP_TOP = (150, 1556)  # below the status bar through the coach's three tiles
KEEP_CARD_END = (2128, 2236)  # the coach card's bottom padding, edge and shadow
KEEP_X = (30, 1176)  # trims the side margins so the tiles fill a wider card
CARD_WIDTH = 1272


def trimmed_source() -> Image.Image:
    raw = Image.open(v1.SOURCE).convert("RGB")
    top = raw.crop((KEEP_X[0], KEEP_TOP[0], KEEP_X[1], KEEP_TOP[1]))
    end = raw.crop((KEEP_X[0], KEEP_CARD_END[0], KEEP_X[1], KEEP_CARD_END[1]))
    out = Image.new("RGB", (top.width, top.height + end.height))
    out.paste(top, (0, 0))
    out.paste(end, (0, top.height))
    # v1.render crops a 1206-wide capture, so scale back to that width
    height = round(out.height * raw.width / out.width)
    return out.resize((raw.width, height), Image.Resampling.LANCZOS)


def main() -> None:
    src = trimmed_source()
    src.save(TRIMMED)
    v1.SOURCE = TRIMMED
    v1.CROP_TOP = 0
    v1.CROP_BOTTOM = src.height
    v1.CARD_WIDTH = CARD_WIDTH
    written = []
    for key, header in v1.VARIANTS:
        out = HERE / f"hook-{key}-v2-{v1.slug(header)}.png"
        image = v1.render(header)
        assert image.size == v1.SIZE
        image.save(out)
        written.append(out)
        print(f"wrote {out}")
    v1.contact_sheet(written, HERE / "contact-sheet-v2.png")
    print(f"wrote {HERE / 'contact-sheet-v2.png'}")


if __name__ == "__main__":
    main()
