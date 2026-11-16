#!/usr/bin/env python3
"""C11: a practice static for players who already play.

    python3 c11_join_the_table_static.py [--out DIR]

C10 (video) gets watched but rarely tapped; C1 (static) gets tapped. This keeps
C10's painted table and lays it out like C1: the app's name on top, the hook,
then a big phone showing the moment that sold C1, a Charleston pass picked and
"Perfect pass! 3 of 3". The screen is redrawn, not a 1:1 capture: the real
tiles from the app (B.rack) with the coach's three in gold, the prompt and the
result card enlarged so it all reads in a one-second scroll. The phone goes on
after the paint pass so it stays sharp. Outputs a 9:16, a 4:5 and the copy.
"""

from __future__ import annotations

import pathlib
import sys

from PIL import Image, ImageDraw, ImageFilter

from c9_whole_charleston import B, R

ID = "C11-join-the-table-static"
FOLDER = "C11 join-the-table-static"
HOOK = ("Practice the Charleston.", "Before game night.")
PROMPT = "Which 3 would you pass?"
RESULT = "Perfect pass! 3 of 3"
WHY = ("Odd tiles and the wind go.", "Keep your evens.")  # true for this 2468-leaning deal
PICKS = B.PASS  # tiles raised in gold; the rest fade (none picked: nothing fades)
MARK = "star"  # result card icon: "star" or "check"
TILES = B.deal_tiles
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
    """The painted table, moved dy down (a whole number of planks). The phone covers the middle,
    so no cups: their steam showed as smudges above the phone."""
    assert dy % 150 == 0, "keep the plank seams lined up"
    im = R.table_bg().copy()
    low = Image.new("RGBA", im.size)
    low.paste(im.crop((0, 0, R.W, R.H - dy)), (0, dy))
    for y in range(0, dy, 150):
        low.paste(im.crop((0, 0, R.W, 150)), (0, y))
    return R.paint(low, 0).convert("RGBA")


def coach_card(width: int) -> Image.Image:
    """The app's result card, enlarged: gold star, "Perfect pass! 3 of 3", and the coach's why."""
    f, fw = B.font(62, "Semibold"), B.font(52, "Medium")
    h = 286
    im = Image.new("RGBA", (width, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, width - 1, h - 1), 34, fill=B.CARD + (255,))
    star = B.stars(1, 60) if MARK == "star" else check(60)
    tw = d.textlength(RESULT, font=f)
    x = round((width - star.width - 22 - tw) / 2)
    im.alpha_composite(star, (x, 44))
    d.text((x + star.width + 22, 76), RESULT, font=f, fill=B.INK, anchor="lm")
    for k, line in enumerate(WHY):
        d.text((width / 2, 158 + k * 64), line, font=fw, fill=B.INK, anchor="mm")
    return im


def check(size: int) -> Image.Image:
    """The app's green answer check."""
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((0, 0, size - 1, size - 1), fill=B.JADE)
    d.line((size * 0.27, size * 0.52, size * 0.44, size * 0.68, size * 0.74, size * 0.34), fill=(255, 255, 255),
           width=round(size * 0.11), joint="curve")
    return im


def rack(width: int) -> Image.Image:
    """The real deal, 7 over 6, the coach's 3 raised with a thick gold ring, the rest faded."""
    faces = TILES()
    gap = 16
    tw = (width - 6 * gap) // 7
    th = round(tw * faces[0].height / faces[0].width)
    lift, ring = round(th * 0.16), 10
    row_gap = lift + 2 * ring + 12  # a raised tile in row 2 must clear row 1
    h = lift + 2 * th + row_gap + 2 * ring
    im = Image.new("RGBA", (width, h), (0, 0, 0, 0))
    for r, idxs in enumerate([range(0, 7), range(7, 13)]):
        x0 = (width - (len(idxs) * tw + (len(idxs) - 1) * gap)) // 2
        for k, i in enumerate(idxs):
            x, y = x0 + k * (tw + gap), lift + ring + r * (th + row_gap)
            t = faces[i].resize((tw, th), Image.LANCZOS)
            if i in PICKS:
                y -= lift
            elif PICKS:
                veil = Image.new("RGBA", t.size, B.CREAM + (0,))
                veil.putalpha(t.getchannel("A").point(lambda v: v * 18 // 100))
                t = t.copy()
                t.alpha_composite(veil)
            B.shadow(im, t, (x, y), blur=6, alpha=40, drop=4)
            if i in PICKS:
                ImageDraw.Draw(im).rounded_rectangle((x - ring, y - ring, x + tw + ring - 1, y + th + ring - 1),
                                                     24, outline=B.GOLD, width=ring)
    return im


def screen(width: int, height: int, card_bottom: int) -> Image.Image:
    """The pass, picked and scored: prompt, the deal with the coach's 3 in gold, the result card
    ending at card_bottom, the rack centred in between."""
    im = Image.new("RGBA", (width, height), B.CREAM + (255,))
    f = B.font(66, "Bold", True)
    ImageDraw.Draw(im).text((width / 2, 50), PROMPT, font=f, fill=B.INK, anchor="mt")
    card = coach_card(width - 60)
    card_top = card_bottom - card.height
    tiles = rack(width - 56)
    top = 50 + 66
    y = top + (card_top - top - tiles.height) // 2
    im.alpha_composite(tiles, ((width - tiles.width) // 2, y))
    B.shadow(im, card, (30, card_top), blur=14, alpha=50, drop=6)
    im.putalpha(R.rounded_mask(im.size, int(width * 0.09)))
    return im


PAD = 34  # phone bezel


def phone(width: int, height: int, card_bottom: int) -> Image.Image:
    """A dark-framed phone with a soft shadow around the screen."""
    pad = PAD
    s = screen(width - 2 * pad, height, card_bottom)
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


def place_phone(im: Image.Image, width: int, top: int, card_bottom: int, angle: float = -1) -> None:
    """Phone centred across, its frame starting at top and running off the bottom; the result
    card ends at card_bottom on the canvas."""
    sprite = phone(width, im.height - top + 200, card_bottom - top - PAD)
    sprite = sprite.rotate(angle, Image.BICUBIC, expand=True)
    im.alpha_composite(sprite, ((R.W - sprite.width) // 2, top - 30))


def story() -> Image.Image:
    im = table(450)  # cloth 780 to 1680
    im.alpha_composite(brand(104), (0, 255))
    im.alpha_composite(hook(104), (0, 403))
    place_phone(im, 1040, 645, 1530)
    return im.convert("RGB")


def feed() -> Image.Image:
    im = shrink(table(150), 0.9).crop((0, 0, R.W, 1350))  # cloth 432 to 1242
    im.alpha_composite(brand(104), (0, 22))
    im.alpha_composite(hook(98), (0, 180))
    place_phone(im, 1040, 395, 1305)
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
