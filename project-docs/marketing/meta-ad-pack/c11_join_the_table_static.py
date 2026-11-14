#!/usr/bin/env python3
"""C11: a practice static for players who already play.

    python3 c11_join_the_table_static.py [--out DIR]

C10 (video) gets watched but rarely tapped; C1 (static) gets tapped. This keeps
C10's painted table and lays it out like C1: the app's name on top, the hook,
then a large phone on the Charleston drill. The phone is pasted after the paint
pass so the screen stays sharp, and the screen is cut up so the prompt and
tiles sit high and big: readable at a glance. Outputs a 9:16, a 4:5 and the copy.
"""

from __future__ import annotations

import pathlib
import sys

from PIL import Image, ImageDraw, ImageFilter

from c9_whole_charleston import B, R

ID = "C11-join-the-table-static"
FOLDER = "C11 join-the-table-static"
HOOK = ("Practice your mahj.", "Bring it to the table.")
SCREEN = "05_charleston.png"
# Bands of the 1206x2622 capture: nav header, prompt + tiles + "Selected 0 of 3", the button.
BANDS = [((0, 420), 40), ((990, 1740), 110), ((2280, 2500), 0)]
CUPS = [(176, 1150), (904, 414), (904, 1150), (176, 414)]
COPY = {
    "Primary text": "Already play mahj? Practice the Charleston, read your rack faster and know what to "
                    "throw, five minutes at a time.",
    "Primary text, long": "Already play mahj? Practice the Charleston, read your rack faster and know what to "
                          "throw, five minutes at a time.\n"
                          "Mahj Trainer is short practice drills for American Mah Jongg: Charleston passes, "
                          "keep or throw, which section a rack is chasing. A coach explains every answer. "
                          "Original practice hands, free to start, no account.",
    "Alternate 1": "Five minutes of mahj practice before game night.",
    "Alternate 2": "Play American Mah Jongg? Practice every pass and every discard at home.",
    "Headline": "Practice mahj at home",
    "Description": "American Mah Jongg practice",
    "CTA": "Install Now",
}


def table(dy: int) -> Image.Image:
    """Cloth and four cups, moved dy down (a whole number of planks), painted."""
    assert dy % 150 == 0, "keep the plank seams lined up"
    im = R.table_bg().copy()
    for i, (cx, cy) in enumerate(CUPS):
        R.paste_center(im, R.cup(), cx, cy)
        R.steam(im, cx, cy - 10, 0.4, i)
    low = Image.new("RGBA", im.size)
    low.paste(im.crop((0, 0, R.W, R.H - dy)), (0, dy))
    for y in range(0, dy, 150):
        low.paste(im.crop((0, 0, R.W, 150)), (0, y))
    return R.paint(low, 0).convert("RGBA")


def screen(width: int) -> Image.Image:
    """The Charleston drill with its empty space taken out, scaled to width, corners rounded."""
    src = Image.open(R.K.CAPS / SCREEN).convert("RGBA")
    out = Image.new("RGBA", src.size, src.getpixel((20, 600)))
    y = 0
    for (a, b), gap in BANDS:
        out.paste(src.crop((0, a, src.width, b)), (0, y))
        y += b - a + gap
    out = out.resize((width, round(width * src.height / src.width)), Image.LANCZOS)
    out.putalpha(R.rounded_mask(out.size, int(width * 0.11)))
    return out


def phone(width: int) -> Image.Image:
    """A dark-framed phone with a soft shadow around the screen."""
    s = screen(width)
    pad = max(10, width // 30)
    im = Image.new("RGBA", (s.width + 2 * pad + 60, s.height + 2 * pad + 60), (0, 0, 0, 0))
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((34, 44, im.width - 26, im.height - 16), int(width * 0.14), fill=(20, 10, 10, 150))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(16)))
    ImageDraw.Draw(im).rounded_rectangle((30, 30, im.width - 30, im.height - 30), int(width * 0.13), fill=(34, 34, 38))
    im.alpha_composite(s, (30 + pad, 30 + pad))
    return im


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
    """The two hook lines, shrunk if needed so the longer one fits in 960px."""
    f = R.K.font(size, "Black", serif=True)
    widest = max(ImageDraw.Draw(Image.new("L", (1, 1))).textlength(line, font=f) for line in HOOK)
    if widest > 960:
        size = int(size * 960 / widest)
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
    """Icon and name, centred as one row."""
    ic = R.icon(icon)
    name = B.font(max(56, round(icon * 0.55)), "Bold", True)
    text_w = round(ImageDraw.Draw(ic).textlength("Mahj Trainer", font=name))
    layer = Image.new("RGBA", (ic.width + text_w + 20, ic.height), (0, 0, 0, 0))
    layer.alpha_composite(ic)
    ImageDraw.Draw(layer).text((ic.width - 6, ic.height // 2), "Mahj Trainer", font=name, fill=R.CREAM,
                               anchor="lm", stroke_width=max(3, icon // 30), stroke_fill=R.INK)
    out = Image.new("RGBA", (R.W, layer.height), (0, 0, 0, 0))
    out.alpha_composite(shadowed(layer, 8, 0.5), ((R.W - layer.width) // 2, 0))
    return out


def place_phone(im: Image.Image, width: int, top: int, angle: float = -3) -> None:
    """Phone centred across, its frame starting at top; the bottom runs off the frame."""
    sprite = phone(width).rotate(angle, Image.BICUBIC, expand=True)
    im.alpha_composite(sprite, ((R.W - sprite.width) // 2, top - 30))


def story() -> Image.Image:
    im = table(450)  # cloth 780 to 1680
    im.alpha_composite(brand(120), (0, 250))
    im.alpha_composite(hook(108), (0, 420))
    place_phone(im, 700, 720)
    return im.convert("RGB")


def feed() -> Image.Image:
    im = shrink(table(150), 0.9).crop((0, 0, R.W, 1350))  # cloth 432 to 1242
    im.alpha_composite(brand(104), (0, 30))
    im.alpha_composite(hook(98), (0, 170))
    place_phone(im, 640, 400)
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
