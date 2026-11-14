#!/usr/bin/env python3
"""C10: a cold-audience video ad. Learn mahjong, join the table.

    python3 c10_join_the_table.py [--out DIR] [--still t1,t2,...]

C9 opens on "the Charleston", a word only players know. The install test runs on
a broad audience (US, women 40+ as a suggestion, no interests), so most viewers
have never played. This cut leads with why someone wants in (friends meet for
mahj night), shows what the game is in one line, then the app as the way to
learn at home, and closes back at the table.

Scenes come from the shorts engine (the tile case, the house, the table) and
from C9 (the pass animation, the app panel, the end card and the safe-area
text). Same outputs as C9: 9:16, 4:5, covers and copy.
"""

from __future__ import annotations

import numpy as np
from PIL import Image

import c9_whole_charleston as N
from c9_whole_charleston import C, R
from render import seg, wave

ID = "C10-join-the-table-video"
FOLDER = "C10 join-the-table-video"
LINES = [
    "Learn mahjong, and join the table.",
    "Friends everywhere are meeting for mahjong night.",
    "You trade tiles, build a hand, and call mahjong.",
    "Learn it at home, five minutes at a time. A coach explains every move.",
    "Then pull up a chair.",
]
HOOK = ("Learn mahjong.", "Join the table.")
COPY = {
    "Primary text": "Want in on mahj night? Learn American Mah Jongg at home, five minutes at a time, "
                    "with a coach that explains every move.",
    "Primary text, long": "Want in on mahj night? Learn American Mah Jongg at home, five minutes at a time, "
                          "with a coach that explains every move.\n"
                          "Mahj Trainer is short practice drills for new players: the tiles, the Charleston, "
                          "reading your rack, keep or throw. Original practice hands, free to start, no account.",
    "Alternate 1": "Your friends play mahj. Learn at home first, then pull up a chair.",
    "Alternate 2": "New to American Mah Jongg? Short daily practice, and the reason behind every answer.",
    "Headline": "Learn mahj at home",
    "Description": "American Mah Jongg practice",
    "CTA": "Install Now",
}

N.APP_LINE, N.HOLD = 3, 0.4
N.CAPTION_AT["Friends"] = 455  # between the moon and the roof
SPAN = 1.0  # seconds per pass in the three-pass scene


def lowered(scene, dy: int = 150):
    """The engine's table sits at y 330; move it one plank row down, clear of the caption."""
    def out(t: float, dur: float) -> Image.Image:
        im = scene(t, dur)
        low = Image.new("RGBA", im.size)
        low.paste(im.crop((0, 0, R.W, dy)), (0, 0))
        low.paste(im.crop((0, 0, R.W, R.H - dy)), (0, dy))
        return low
    return out


def pass_starts(dur: float) -> list[float]:
    span = min(SPAN, (dur - 0.35) / 3)
    return [0.2 + k * span for k in range(3)]


def passes(t: float, dur: float) -> Image.Image:
    """Right, across, left, back to back: what trading tiles looks like."""
    im = C.table().copy()
    R.glow(im, 540, C.CY, 900, (255, 214, 150), 0.14 + 0.02 * wave(t, 3.2))
    starts = pass_starts(dur)
    span = starts[1] - starts[0]
    idx = max((k for k, s in enumerate(starts) if t >= s), default=0)
    direction, picks, _ = C.PASSES[idx]
    start = starts[idx]
    C.arrow(im, direction, seg(t, start - 0.2, start + 0.05) * (1 - seg(t, start + span - 0.25, start + span)))
    C.draw_pass(im, (t - start) / span, direction, C.states()[idx], C.states()[idx + 1], picks)
    return im


table_end = lowered(R.scene5)


def sfx(scenes: list[dict], buf: np.ndarray, rng: np.random.Generator) -> None:
    s = [sc["start"] for sc in scenes]
    R.add(buf, R.thump(), s[0], 0.5)
    for at in R.burst_landings():
        if 0 < at < scenes[0]["end"]:
            R.add(buf, R.click(rng), s[0] + at, 0.10 + 0.06 * rng.random())
    for at in R.S2_CLATTER:
        if at < scenes[1]["end"] - s[1]:
            R.add(buf, R.click(rng), s[1] + at, 0.07)
    starts = pass_starts(scenes[2]["end"] - s[2])
    for start in starts:
        for k in range(4):
            R.add(buf, R.click(rng), s[2] + start + 0.75 * (starts[1] - starts[0]) + 0.02 * k,
                  0.07 + 0.03 * rng.random())
    for at, _, _ in N.TAPS:
        R.add(buf, R.click(rng), s[3] + (at - N.PICK_SRC) / N.APP["speed"], 0.11)
    for k, n in enumerate(("A4", "C5", "F5")):
        R.add(buf, R.note(R.hz(n), 1.1, 0.10), s[3] + N.APP["cut"] + 0.12 + 0.07 * k)


SHORT = R.Short(ID, LINES, [R.scene0, R.scene2, passes, N.app, table_end], HOOK,
                overlays={N.app: N.app_overlay, R.scene6: N.end_overlay}, sfx=sfx, prepare=N.prepare)

if __name__ == "__main__":
    N.build(SHORT, FOLDER, COPY)
