#!/usr/bin/env python3
"""Render the Mahj TikTok slideshow kit into iCloud Drive.

    python3 build_kit.py --backgrounds <dir of scene photos> [--out <dir>]

Slides are 1080x1920 JPEGs. Scene photos (CC0/public-domain or free FLUX
renders, never with tiles in them, since AI garbles mahjong tiles) only sit
behind text; every tile and screen comes from real Mahj 1.4.0 captures.
"""
from __future__ import annotations

import argparse
import csv
import pathlib
import random
import shutil

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

import posts as P

HERE = pathlib.Path(__file__).resolve().parent
CAPS = pathlib.Path.home() / "ios/appstore-screenshots/captures/mahj/cpp-20261015"
ICON = pathlib.Path.home() / "mahj/MahjTrainer/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
ICLOUD = pathlib.Path.home() / "Library/Mobile Documents/com~apple~CloudDocs/Mahj TikTok Kit"
W, H = 1080, 1920
FONT = "/System/Library/Fonts/SFNS.ttf"
SERIF = "/System/Library/Fonts/NewYork.ttf"
CREAM, INK, SAGE = (246, 242, 233), (40, 48, 38), (91, 131, 96)

SHOTS = {
    "hand_match": "03_hand_match.png", "hand_match_answered": "03_hand_match_answered.png",
    "charleston": "05_charleston.png", "charleston_answered": "05_charleston_answered.png",
    "play": "02_play_a_hand.png", "keep": "04_keep_or_throw.png",
    "keep_answered": "04_keep_or_throw_answered.png", "quick": "01_quick_session.png",
    "quick_answered": "01_quick_session_answered.png", "tile_room": "08_tile_room.png",
    "reference": "07_reference.png", "home": "06_home.png",
}
# Tile crops in raw 1206x2622 capture pixels: (file, left, top, right, bottom).
RACKS = {
    "hand_match_rack": ("03_hand_match.png", 60, 880, 1146, 1300),
    "charleston_rack": ("05_charleston.png", 70, 1200, 1136, 1600),
    "quick_rack": ("01_quick_session.png", 60, 920, 1146, 1310),
    "play_rack": ("02_play_a_hand.png", 100, 1110, 1106, 1460),
    "keep_card": ("04_keep_or_throw.png", 140, 1000, 1066, 1700),
}


def font(size: int, bold: bool = True, serif: bool = False) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(SERIF if serif else FONT, size)
    try:
        f.set_variation_by_name("Bold" if bold else "Regular")
    except Exception:  # noqa: BLE001
        pass
    return f


def wrap(draw: ImageDraw.ImageDraw, text: str, f: ImageFont.FreeTypeFont, width: int) -> list[str]:
    lines: list[str] = []
    for para in text.split("\n"):
        cur = ""
        for word in para.split():
            trial = f"{cur} {word}".strip()
            if draw.textlength(trial, font=f) <= width:
                cur = trial
            else:
                lines.append(cur)
                cur = word
        lines.append(cur)
    return lines


def cover(img: Image.Image) -> Image.Image:
    return ImageOps.fit(img.convert("RGB"), (W, H), Image.LANCZOS, centering=(0.5, 0.45))


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *img.size), radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def shadowed_paste(base: Image.Image, img: Image.Image, xy: tuple[int, int], blur: int = 24) -> None:
    sh = Image.new("RGBA", (img.width + blur * 4, img.height + blur * 4), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((blur * 2, blur * 2, blur * 2 + img.width, blur * 2 + img.height),
                                         40, fill=(0, 0, 0, 90))
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(sh, (xy[0] - blur * 2, xy[1] - blur * 2 + 12))
    base.alpha_composite(img, xy)


def stroke_text(d: ImageDraw.ImageDraw, lines: list[str], f, y: int, fill=(255, 255, 255),
                stroke=(0, 0, 0), sw: int = 6, gap: int = 14) -> int:
    for line in lines:
        w = d.textlength(line, font=f)
        d.text(((W - w) / 2, y), line, font=f, fill=fill, stroke_width=sw, stroke_fill=stroke)
        y += f.size + gap
    return y


def hook_slide(bg: Image.Image, text: str) -> Image.Image:
    im = cover(bg).convert("RGBA")
    shade = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    for y in range(H):  # gentle top-weighted shade so white text reads on any photo
        a = int(110 * max(0.0, 1 - abs(y - 640) / 900))
        sd.line([(0, y), (W, y)], fill=(0, 0, 0, a))
    im.alpha_composite(shade)
    d = ImageDraw.Draw(im)
    f = font(92)
    lines = wrap(d, text, f, 860)
    y = 560 - (len(lines) * 106) // 2
    y = stroke_text(d, lines, f, y)
    stroke_text(d, ["Swipe right ->"], font(42), y + 30, sw=4)
    return im.convert("RGB")


def card_slide(bg: Image.Image, text: str, rack: str | None) -> Image.Image:
    im = cover(bg).filter(ImageFilter.GaussianBlur(18)).convert("RGBA")
    im.alpha_composite(Image.new("RGBA", (W, H), (246, 242, 233, 70)))
    d = ImageDraw.Draw(im)
    f = font(66, bold=True)
    lines = wrap(d, text, f, 800)
    text_h = len(lines) * (f.size + 18)
    rack_img = None
    if rack:
        name, *box = RACKS[rack]
        rack_img = Image.open(CAPS / name).convert("RGB").crop(tuple(box))
        rack_img = rack_img.resize((880, int(rack_img.height * 880 / rack_img.width)), Image.LANCZOS)
    card_h = text_h + 140 + ((rack_img.height + 50) if rack_img else 0)
    top = max(260, (H - card_h) // 2 - 120)
    card = Image.new("RGBA", (920, card_h), (0, 0, 0, 0))
    ImageDraw.Draw(card).rounded_rectangle((0, 0, 920, card_h), 44, fill=(*CREAM, 242))
    im.alpha_composite(card, (80, top))
    y = top + 70
    if rack_img:
        im.alpha_composite(rounded(rack_img, 28), (100, y))
        y += rack_img.height + 50
    for line in lines:
        d.text((130, y), line, font=f, fill=INK)
        y += f.size + 18
    return im.convert("RGB")


def app_slide(text: str, shots: tuple[str, str]) -> Image.Image:
    im = Image.new("RGBA", (W, H), (*CREAM, 255))
    d = ImageDraw.Draw(im)
    f = font(58)
    lines = wrap(d, text, f, 900)
    y = 190
    for line in lines:
        d.text(((W - d.textlength(line, font=f)) / 2, y), line, font=f, fill=INK)
        y += f.size + 16
    sw = 440
    shot_top = max(y + 70, 560)
    for i, key in enumerate(shots):
        s = Image.open(CAPS / SHOTS[key]).convert("RGB")
        s = s.resize((sw, int(s.height * sw / s.width)), Image.LANCZOS)
        s = s.crop((0, 0, sw, min(s.height, 960)))
        shadowed_paste(im, rounded(s, 40), (70 + i * (sw + 60), shot_top))
    icon = rounded(Image.open(ICON).convert("RGB").resize((96, 96), Image.LANCZOS), 22)
    label_y = shot_top + 960 + 50
    lf = font(40)
    label = "Mahj Trainer"
    lw = 96 + 24 + d.textlength(label, font=lf)
    x = int((W - lw) / 2)
    im.alpha_composite(icon, (x, label_y))
    d.text((x + 120, label_y + 24), label, font=lf, fill=INK)
    return im.convert("RGB")


def schedule() -> list[dict]:
    by_fmt = {k: [p for p in P.POSTS if p["fmt"] == k] for k in P.FORMATS}
    order = []
    for round_ in range(6):
        for k in P.FORMATS:
            order.append(by_fmt[k][round_])
    return order


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--backgrounds", required=True)
    ap.add_argument("--out", default=str(ICLOUD))
    args = ap.parse_args()
    out = pathlib.Path(args.out)
    bgs = sorted(p for p in pathlib.Path(args.backgrounds).iterdir() if p.suffix.lower() in (".jpg", ".jpeg", ".png"))
    rng = random.Random(42)
    rng.shuffle(bgs)
    slots = ["1 Morning", "2 Midday", "3 Evening"]
    if out.exists():
        for child in out.glob("Day *"):
            shutil.rmtree(child)
    rows = []
    for i, post in enumerate(schedule()):
        day, slot = i // 3 + 1, slots[i % 3]
        folder = out / f"Day {day:02d}" / f"{slot} - {post['id']} {P.FORMATS[post['fmt']]}"
        folder.mkdir(parents=True, exist_ok=True)
        bg = Image.open(bgs[i % len(bgs)])
        bg2 = Image.open(bgs[(i * 7 + 3) % len(bgs)])
        slides = [
            hook_slide(bg, post["hook"]),
            card_slide(bg2, post["s2"], post.get("rack") if post["fmt"] == "C" else None),
            card_slide(bg2, post["s3"], post.get("rack") if post["fmt"] != "C" else None),
            app_slide(post["s4"], post["shots"]),
            card_slide(bg2, post["s5"], None),
        ]
        for n, s in enumerate(slides, 1):
            s.save(folder / f"{n}.jpg", quality=92)
        (folder / "caption.txt").write_text(
            f"CAPTION (paste as is):\n{post['caption']}\n{P.CTA_CAPTION}\n\n"
            f"SOUND: {P.SOUNDS[post['sound']]}\n\n"
            f"FORMAT: {post['fmt']} {P.FORMATS[post['fmt']]}\nHOOK: {post['hook']}\n")
        rows.append({"day": day, "slot": slot, "post": post["id"], "format": f"{post['fmt']} {P.FORMATS[post['fmt']]}",
                     "hook": post["hook"], "account": "A" if (i % 3) != 1 else "B",
                     "views_24h": "", "views_72h": "", "saves": "", "app_comments": "", "call": ""})
    with open(out / "Tracker.csv", "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print(f"wrote {len(rows)} posts to {out}")


if __name__ == "__main__":
    main()
