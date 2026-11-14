#!/usr/bin/env python3
"""C11: C10 as a static. Learn mahjong, join the table.

    python3 c11_join_the_table_static.py [--out DIR]

C10 (video) gets watched but rarely tapped; C1 (static) gets tapped. This keeps
C10's cold-audience message and painted table, and lays it out like C1: the
app's name and "free to start" on top, the hook, then the table set for four
with the app open on it. Outputs a 9:16 and a 4:5 plus the copy file.
"""

from __future__ import annotations

import pathlib
import sys

from PIL import Image, ImageDraw, ImageFilter

import c9_whole_charleston as N
from c10_join_the_table import COPY
from c9_whole_charleston import B, R

ID = "C11-join-the-table-static"
FOLDER = "C11 join-the-table-static"
HOOK = ("Learn mahjong.", "Join the table.")
PHONE_W = 250


def painted(dy: int) -> Image.Image:
    """The table for four with the app open, moved dy down (a whole number of planks), painted."""
    assert dy % 150 == 0, "keep the plank seams lined up"
    im = R.table_scene(0.4, None, 4, 0)
    R.paste_center(im, R.phone_sprite("05_charleston_answered.png", PHONE_W), 540, 790, -8)
    low = Image.new("RGBA", im.size)
    low.paste(im.crop((0, 0, R.W, R.H - dy)), (0, dy))
    for y in range(0, dy, 150):
        low.paste(im.crop((0, 0, R.W, 150)), (0, y))
    return R.paint(low, 0).convert("RGBA")


def shrink(im: Image.Image, s: float) -> Image.Image:
    """Scale down and widen back to 1080 by mirroring the side wood, so the planks stay continuous."""
    small = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    pad = (R.W - small.width) // 2
    out = Image.new("RGBA", (R.W, small.height))
    out.paste(small, (pad, 0))
    out.paste(small.crop((0, 0, pad, small.height)).transpose(Image.FLIP_LEFT_RIGHT), (0, 0))
    right = small.crop((small.width - (R.W - pad - small.width), 0, small.width, small.height))
    out.paste(right.transpose(Image.FLIP_LEFT_RIGHT), (pad + small.width, 0))
    return out


def shadowed(layer: Image.Image, blur: int, strength: float) -> Image.Image:
    sh = layer.getchannel("A").filter(ImageFilter.GaussianBlur(blur)).point(lambda v: int(v * strength))
    out = Image.new("RGBA", layer.size, R.INK + (0,))
    out.putalpha(sh)
    out.alpha_composite(layer, (0, -5))
    return out


def hook(size: int) -> Image.Image:
    f = R.K.font(size, "Black", serif=True)
    lh = int(size * 1.12)
    layer = Image.new("RGBA", (R.W, lh * len(HOOK) + 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for k, line in enumerate(HOOK):
        fill = R.AMBER if k == len(HOOK) - 1 else R.CREAM
        d.text((540 - d.textlength(line, font=f) / 2, 10 + k * lh), line, font=f, fill=fill,
               stroke_width=size // 12, stroke_fill=R.INK)
    return shadowed(layer, 14, 0.6)


def brand(icon: int) -> Image.Image:
    """Icon, name and "Free to start on the App Store", centred as one row."""
    ic = R.icon(icon)
    name, sub = B.font(max(56, round(icon * 0.5)), "Bold", True), B.font(44, "Semibold")
    d = ImageDraw.Draw(ic)
    text_w = round(max(d.textlength("Mahj Trainer", font=name), d.textlength("Free to start on the App Store", font=sub)))
    layer = Image.new("RGBA", (ic.width + text_w + 20, ic.height), (0, 0, 0, 0))
    layer.alpha_composite(ic)
    t = ImageDraw.Draw(layer)
    x, mid = ic.width - 14, ic.height // 2
    stroke = max(3, icon // 30)
    t.text((x, mid - 4), "Mahj Trainer", font=name, fill=R.CREAM, anchor="ls", stroke_width=stroke, stroke_fill=R.INK)
    t.text((x, mid + 10), "Free to start on the App Store", font=sub, fill=R.CREAM, anchor="lt",
           stroke_width=stroke, stroke_fill=R.INK)
    out = Image.new("RGBA", (R.W, layer.height), (0, 0, 0, 0))
    out.alpha_composite(shadowed(layer, 8, 0.5), ((R.W - layer.width) // 2, 0))
    return out


def story() -> Image.Image:
    im = painted(450)  # table 780 to 1680
    im.alpha_composite(brand(120), (0, 250))
    im.alpha_composite(hook(108), (0, 420))
    return im.convert("RGB")


def feed() -> Image.Image:
    im = shrink(painted(150), 0.9).crop((0, 0, R.W, 1350))  # table 432 to 1242
    im.alpha_composite(brand(104), (0, 30))
    im.alpha_composite(hook(98), (0, 170))
    return im.convert("RGB")


def main() -> None:
    args = sys.argv[1:]
    out = pathlib.Path(args[args.index("--out") + 1]) if "--out" in args else B.ICLOUD / FOLDER
    out.mkdir(parents=True, exist_ok=True)
    story().save(out / f"{ID}-story-9x16.png")
    feed().save(out / f"{ID}-feed-4x5.png")
    (out / f"{ID}-copy.txt").write_text("\n\n".join(f"{k}:\n{v}" for k, v in COPY.items()) + "\n")
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
