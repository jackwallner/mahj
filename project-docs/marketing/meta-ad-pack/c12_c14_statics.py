#!/usr/bin/env python3
"""C12 to C14: three more statics in C11's layout, for more winners to test.

    python3 c12_c14_statics.py [--out DIR]

Same painted table, brand row, two-line hook and big phone as C11 (the static
that held up at scale); each one changes one thing:

- C12 read-the-rack: a different drill. The Read the Rack deal, answered
  "2468 (Evens)" with the app's green check.
- C13 keep-or-throw: a different question on C11's deal. One tile in gold, the
  5 Crak, and the call: throw it.
- C14 pass-with-confidence: C11's screen exactly, a new hook. A pure hook test.

Every deal is an app-generated practice rack cut from a real capture, never a
card hand. Outputs go to the iCloud Meta Ads folder, one folder per ad.
"""

from __future__ import annotations

import functools
import pathlib
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

import c11_join_the_table_static as S
from c9_whole_charleston import B

COMMON = {
    "Description": "American Mah Jongg practice",
    "CTA": "Install Now",
}


@functools.cache
def read_rack_tiles() -> tuple[Image.Image, ...]:
    """The 13 tiles of the Read the Rack deal: 2C 2C 4C 4C 4C 6B 6B / 8B 8D 8D F F J."""
    im = Image.open(B.META / "03_read_rack_q1_answered.png").convert("RGB").crop((70, 630, 1136, 1050))
    a = np.asarray(im).astype(int)
    bg = np.median(np.concatenate([a[0], a[-1]]), axis=0)
    mask = ndimage.binary_fill_holes(ndimage.binary_closing(np.abs(a - bg).sum(2) > 18, iterations=3))
    lab, _ = ndimage.label(mask)
    boxes = [(s[1].start, s[0].start, s[1].stop, s[0].stop) for s in ndimage.find_objects(lab)]
    boxes = [b for b in boxes if b[2] - b[0] > 60 and b[3] - b[1] > 80]
    unit = float(np.median([b[2] - b[0] for b in boxes]))
    tiles = []
    for l, t, r, b in sorted(boxes, key=lambda b: (b[1] // 100, b[0])):
        n = max(1, round((r - l) / unit))
        step = (r - l) / n
        tiles += [B.rounded(im.crop((round(l + i * step), t, round(l + (i + 1) * step), b - 4)), 16)
                  for i in range(n)]
    assert len(tiles) == 13, f"expected 13 tiles, cut {len(tiles)}"
    return tuple(tiles)


ADS = [
    {
        "ID": "C12-read-the-rack-static",
        "FOLDER": "C12 read-the-rack-static",
        "HOOK": ("Read your rack faster.", "Before game night."),
        "PROMPT": "Which section is this?",
        "RESULT": "2468 (Evens)",
        "WHY": ("Every number tile is even:", "2s, 4s, 6s and 8s."),
        "PICKS": (),
        "MARK": "check",
        "TILES": read_rack_tiles,
        "COPY": {
            "Primary text": "Already play mahj? Look at a rack and know which section it's chasing. "
                            "Five-minute practice drills for American Mah Jongg.",
            "Alternate 1": "Read your rack in seconds, not minutes.",
            "Alternate 2": "Stop staring at your tiles. Practice reading racks at home.",
            "Headline": "Read your rack faster",
        },
    },
    {
        "ID": "C13-keep-or-throw-static",
        "FOLDER": "C13 keep-or-throw-static",
        "HOOK": ("Keep it or throw it?", "Before game night."),
        "PROMPT": "Keep or throw the 5 Crak?",
        "RESULT": "Throw it!",
        "WHY": ("Your rack leans 2468.", "An odd 5 doesn't fit."),
        "PICKS": (4,),
        "MARK": "star",
        "TILES": B.deal_tiles,
        "COPY": {
            "Primary text": "Already play mahj? Practice every keep-or-throw call at home, with a coach "
                            "who explains each answer. Five minutes at a time.",
            "Alternate 1": "Know what to throw before game night.",
            "Alternate 2": "Play American Mah Jongg? Practice your discards at home.",
            "Headline": "Know what to throw",
        },
    },
    {
        "ID": "C14-pass-with-confidence-static",
        "FOLDER": "C14 pass-with-confidence-static",
        "HOOK": ("Pass with confidence.", "Practice the Charleston."),
        "PROMPT": S.PROMPT,
        "RESULT": S.RESULT,
        "WHY": S.WHY,
        "PICKS": B.PASS,
        "MARK": "star",
        "TILES": B.deal_tiles,
        "COPY": {
            "Primary text": S.COPY["Primary text"],
            "Alternate 1": "No more guessing on the Charleston.",
            "Alternate 2": "Practice every pass at home, five minutes at a time.",
            "Headline": "Practice mahj at home",
        },
    },
]


def build(ad: dict, root: pathlib.Path | None) -> pathlib.Path:
    for key in ("HOOK", "PROMPT", "RESULT", "WHY", "PICKS", "MARK", "TILES"):
        setattr(S, key, ad[key])
    out = (root or B.ICLOUD) / ad["FOLDER"]
    out.mkdir(parents=True, exist_ok=True)
    S.story().save(out / f"{ad['ID']}-story-9x16.png")
    S.feed().save(out / f"{ad['ID']}-feed-4x5.png")
    copy = {**ad["COPY"], **COMMON}
    (out / f"{ad['ID']}-copy.txt").write_text("\n\n".join(f"{k}:\n{v}" for k, v in copy.items()) + "\n")
    return out


def main() -> None:
    args = sys.argv[1:]
    root = pathlib.Path(args[args.index("--out") + 1]) if "--out" in args else None
    for ad in ADS:
        print(f"wrote {build(ad, root)}")


if __name__ == "__main__":
    main()
