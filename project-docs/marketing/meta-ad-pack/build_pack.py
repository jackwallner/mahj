#!/usr/bin/env python3
"""Render the Mahj Trainer Meta ad pack: statics, a carousel and a Reel.

Usage:
  python3 build_pack.py                 # final 5 ads into iCloud "Mahj Meta Ads"
  python3 build_pack.py --all --out DIR # every candidate (C1-C8), for scoring
  python3 build_pack.py --only C3       # one ad
  python3 build_pack.py --check DIR     # dimensions + copy rules on a rendered pack

Inputs are real app captures from a free user on the iPhone 17 Pro simulator
(raw 1206x2622), kept outside the repo like the TikTok kit's captures. Outputs
are binaries and never go in git.

Layout rules (see research.md, "Specs"):
- Feed 4:5 is 1080x1350. Stories/Reels 9:16 is 1080x1920 and every word and
  logo sits inside x 90-990, y 290-1240; only the app screen bleeds below.
- Carousel cards are 1080x1350 (as briefed) plus a 1080x1080 set, because Meta
  forces every card to the first card's ratio and lists 1:1 as its default.
- No text under 44 px. Headlines are New York (the app's display serif), body
  is SF, on the app's cream with its ink, jade, coral and gold.
"""

from __future__ import annotations

import argparse
import functools
import json
import pathlib
import re
import shutil
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from scipy import ndimage

import ads as A

HERE = pathlib.Path(__file__).resolve().parent
CAPS = pathlib.Path.home() / "ios/appstore-screenshots/captures/mahj"
META = CAPS / "meta-20261015"
CPP = CAPS / "cpp-20261015"
VIDEO = META / "drill-recording-30fps.mp4"
ICON = pathlib.Path.home() / "mahj/MahjTrainer/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
ICLOUD = pathlib.Path.home() / "Library/Mobile Documents/com~apple~CloudDocs/Mahj Meta Ads"

SERIF = "/System/Library/Fonts/NewYork.ttf"
SANS = "/System/Library/Fonts/SFNS.ttf"

# Theme.swift light palette.
CREAM = (247, 241, 230)
CARD = (255, 252, 246)
WELL = (241, 233, 219)
RULE = (219, 209, 191)
INK = (41, 36, 31)
INK2 = (97, 89, 79)
JADE = (23, 107, 92)
CORAL = (219, 107, 79)
GOLD = (194, 145, 46)

W = 1080
M = 72  # side margin, 4:5 and carousel
SAFE_X = (90, 990)  # 9:16 text zone
SAFE_Y = (290, 1240)
MIN_TEXT = 44
FEED, STORY, SQUARE = (1080, 1350), (1080, 1920), (1080, 1080)


# ---------------------------------------------------------------- primitives

@functools.cache
def font(size: int, weight: str = "Bold", serif: bool = False) -> ImageFont.FreeTypeFont:
    assert size >= MIN_TEXT, f"text below {MIN_TEXT}px: {size}"
    f = ImageFont.truetype(SERIF if serif else SANS, size)
    if serif:
        # Pin the optical size near what iOS uses for the app's large titles.
        # The named instances sit at opsz 256, a hairline display cut whose
        # hyphen vanishes and which reads poorly for older eyes.
        f.set_variation_by_axes([36, SERIF_WEIGHTS[weight], 0])
    else:
        f.set_variation_by_name(weight)
    return f


SERIF_WEIGHTS = {"Regular": 400, "Medium": 500, "Semibold": 600, "Bold": 700, "Heavy": 800}


def wrap(text: str, f: ImageFont.FreeTypeFont, width: int) -> list[str]:
    d = ImageDraw.Draw(Image.new("L", (1, 1)))
    lines: list[str] = []
    for para in text.split("\n"):
        cur = ""
        for word in para.split():
            trial = f"{cur} {word}".strip()
            if d.textlength(trial, font=f) <= width or not cur:
                cur = trial
            else:
                lines.append(cur)
                cur = word
        lines.append(cur)
    return lines


def fit(text: str, width: int, start: int, low: int, max_lines: int, serif: bool = True,
        weight: str = "Bold") -> tuple[ImageFont.FreeTypeFont, list[str]]:
    """Largest size from start down to low that wraps into max_lines."""
    for size in range(start, low - 1, -2):
        f = font(size, weight, serif)
        lines = wrap(text, f, width)
        if len(lines) <= max_lines:
            return f, lines
    raise ValueError(f"{text!r} needs more than {max_lines} lines at {low}px")


def text_block(im: Image.Image, lines: list[str], f, x: int, y: int, fill, lh: float = 1.16,
               center: bool = False, width: int = 0, tracking: int = 0) -> int:
    """Draw lines top-down; return the y just below the block."""
    d = ImageDraw.Draw(im)
    step = round(f.size * lh)
    for line in lines:
        if tracking:
            lx = x
            if center:
                total = sum(d.textlength(c, font=f) + tracking for c in line) - tracking
                lx = x + (width - total) / 2
            for c in line:
                d.text((lx, y), c, font=f, fill=fill)
                lx += d.textlength(c, font=f) + tracking
        else:
            lx = x + (width - d.textlength(line, font=f)) / 2 if center else x
            d.text((lx, y), line, font=f, fill=fill)
        y += step
    return y


def rounded(img: Image.Image, radius: int, corners: tuple[bool, bool, bool, bool] = (True,) * 4) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, img.width - 1, img.height - 1), radius, fill=255,
                                           corners=corners)
    out = img.convert("RGBA")
    out.putalpha(Image.fromarray(np.minimum(np.asarray(out.getchannel("A")), np.asarray(mask))))
    return out


def shadow(base: Image.Image, img: Image.Image, xy: tuple[int, int], blur: int = 22,
           alpha: int = 46, drop: int = 12) -> None:
    pad = blur * 3
    sh = Image.new("RGBA", (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
    a = img.getchannel("A").point(lambda v: v * alpha // 255)
    sh.paste((60, 40, 20, 255), (pad, pad), a)
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(sh, (xy[0] - pad, xy[1] - pad + drop))
    base.alpha_composite(img, xy)


def canvas(size: tuple[int, int]) -> Image.Image:
    return Image.new("RGBA", size, CREAM + (255,))


def bordered(img: Image.Image, radius: int, border: int = 3, color=RULE) -> Image.Image:
    """Rounded image with a hairline border like the app's cards."""
    out = Image.new("RGBA", (img.width + 2 * border, img.height + 2 * border), (0, 0, 0, 0))
    ImageDraw.Draw(out).rounded_rectangle((0, 0, out.width - 1, out.height - 1), radius + border,
                                          fill=color + (255,))
    out.alpha_composite(rounded(img, radius), (border, border))
    return out


# ---------------------------------------------------------------- app pieces

def screen(name: str, top: int, bottom: int, width: int, folder: pathlib.Path = CPP) -> Image.Image:
    """A crop of a real capture, full app width, scaled to `width`, with border."""
    im = Image.open(folder / name).convert("RGB").crop((24, top, 1182, bottom))
    h = round(im.height * width / im.width)
    return bordered(im.resize((width, h), Image.LANCZOS), 34)


@functools.cache
def icon(size: int) -> Image.Image:
    return rounded(Image.open(ICON).convert("RGB").resize((size, size), Image.LANCZOS), round(size * 0.225))


def brand_row(im: Image.Image, x: int, y: int, sub: str = "Free to start on the App Store",
              size: int = 108) -> int:
    shadow(im, icon(size), (x, y), blur=10, alpha=40, drop=4)
    d = ImageDraw.Draw(im)
    name_f, sub_f = font(52, "Bold", True), font(44, "Regular")
    d.text((x + size + 28, y + 2), "Mahj Trainer", font=name_f, fill=INK)
    d.text((x + size + 28, y + 62), sub, font=sub_f, fill=INK2)
    return y + size


def eyebrow(im: Image.Image, text: str, x: int, y: int, color=JADE, center: bool = False,
            width: int = 0) -> int:
    return text_block(im, [text], font(44, "Bold"), x, y, color, lh=1.0, tracking=5,
                      center=center, width=width)


@functools.cache
def deal_tiles() -> tuple[Image.Image, ...]:
    """The 13 tiles of the Pick Your Pass deal, cut from the real capture.

    Order: 2C 2C 4C 4C 5C 6B 6B / 7B 8B 8D N F J (an app-generated practice
    deal, not a card hand).
    """
    im = Image.open(CPP / "05_charleston.png").convert("RGB").crop((70, 1200, 1136, 1625))
    a = np.asarray(im).astype(int)
    bg = np.median(np.concatenate([a[0], a[-1]]), axis=0)
    mask = ndimage.binary_fill_holes(ndimage.binary_closing(np.abs(a - bg).sum(2) > 18, iterations=3))
    lab, _ = ndimage.label(mask)
    boxes = [(s[1].start, s[0].start, s[1].stop, s[0].stop) for s in ndimage.find_objects(lab)]
    boxes = [b for b in boxes if b[2] - b[0] > 60 and b[3] - b[1] > 80]
    unit = float(np.median([b[2] - b[0] for b in boxes]))
    tiles = []
    for l, t, r, b in sorted(boxes, key=lambda b: (b[1] // 100, b[0])):
        n = max(1, round((r - l) / unit))  # touching tiles come out as one box
        step = (r - l) / n
        tiles += [rounded(im.crop((round(l + i * step), t, round(l + (i + 1) * step), b - 4)), 16)
                  for i in range(n)]
    assert len(tiles) == 13, f"expected 13 tiles, cut {len(tiles)}"
    return tuple(tiles)


PAIRS = [(0, 1), (2, 3), (5, 6)]
PASS = (4, 7, 10)  # 5 Crak, 7 Bam, North: the coach's pass for this deal
JOKER, FLOWER = 12, 11


def rack(width: int, max_h: int, dim: tuple[int, ...] = (), gold: tuple[int, ...] = (),
         brackets: bool = False) -> Image.Image:
    """The deal laid out like the app (7 over 6) on a well, scaled to fit."""
    tiles = deal_tiles()
    tw, th = tiles[0].size
    gap, pad = 14, 30
    label_h = 70 if brackets else 0
    rw = 7 * tw + 6 * gap + 2 * pad
    rh = 2 * th + gap + 2 * pad + label_h * 2 + 10
    im = Image.new("RGBA", (rw, rh), (0, 0, 0, 0))
    ImageDraw.Draw(im).rounded_rectangle((0, 0, rw - 1, rh - 1), 40, fill=WELL + (255,))
    rows = [range(0, 7), range(7, 13)]
    pos = {}
    for r, idxs in enumerate(rows):
        n = len(idxs)
        x0 = (rw - (n * tw + (n - 1) * gap)) // 2
        y = pad + r * (th + gap + label_h + 10)
        for k, i in enumerate(idxs):
            x = x0 + k * (tw + gap)
            t = tiles[i]
            yy = y - (14 if i in gold else 0)
            if i in dim:
                t = t.copy()
                t.putalpha(t.getchannel("A").point(lambda v: v * 30 // 100))
                im.alpha_composite(t, (x, yy))
            else:
                shadow(im, t, (x, yy), blur=6, alpha=40, drop=4)
            if i in gold:
                ImageDraw.Draw(im).rounded_rectangle((x - 6, yy - 6, x + tw + 5, yy + th + 5), 22,
                                                     outline=GOLD, width=9)
            pos[i] = (x, yy)
    if brackets:
        d = ImageDraw.Draw(im)
        f = font(46, "Semibold")
        for a, b in PAIRS:
            x1, y1 = pos[a][0] + 8, pos[a][1] + th + 16
            x2 = pos[b][0] + tw - 8
            d.line((x1, y1, x1, y1 + 14, x2, y1 + 14, x2, y1), fill=GOLD, width=7, joint="curve")
            d.text(((x1 + x2) / 2, y1 + 22), "pair", font=f, fill=INK2, anchor="mt")
    scale = min(width / rw, max_h / rh, 1.6)
    return im.resize((round(rw * scale), round(rh * scale)), Image.LANCZOS)


def pill(text: str, f, fg=(255, 255, 255), bg=JADE, padx: int = 34, pady: int = 18) -> Image.Image:
    d = ImageDraw.Draw(Image.new("L", (1, 1)))
    w = round(d.textlength(text, font=f))
    asc, desc = f.getmetrics()
    im = Image.new("RGBA", (w + 2 * padx, asc + desc + 2 * pady), (0, 0, 0, 0))
    dd = ImageDraw.Draw(im)
    dd.rounded_rectangle((0, 0, im.width - 1, im.height - 1), im.height // 2, fill=bg + (255,))
    dd.text((padx, pady), text, font=f, fill=fg)
    return im


def stars(n: int, size: int) -> Image.Image:
    im = Image.new("RGBA", (n * size + (n - 1) * 10, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    r, ri = size / 2, size / 2 * 0.42
    for k in range(n):
        cx, cy = k * (size + 10) + r, r
        pts = []
        for j in range(10):
            ang = np.pi / 2 + j * np.pi / 5
            rad = r if j % 2 == 0 else ri
            pts.append((cx + rad * np.cos(ang), cy - rad * np.sin(ang)))
        d.polygon(pts, fill=GOLD)
    return im


def fade_band(im: Image.Image, top: int, height: int) -> None:
    """Fade whatever is under [top, top+height) into cream, solid below."""
    h = im.height - top
    a = np.clip((np.arange(h) / height), 0, 1) * 255
    band = Image.new("RGBA", (im.width, h), CREAM + (0,))
    band.putalpha(Image.fromarray(np.repeat(a[:, None], im.width, 1).astype("uint8")))
    im.alpha_composite(band, (0, top))


# ---------------------------------------------------------------- statics

# Per concept: the app screen that proves the claim, as (file, folder, raw top,
# raw bottom) for feed and story. Bottoms past the frame simply bleed off.
PANELS = {
    "C1": {"feed": ("05_charleston_perfect.png", META, 650, 2200),
           "story": ("05_charleston_perfect.png", META, 440, 2200)},
    "C4": {"feed": ("03_hand_match_answered.png", CPP, 1385, 2030),
           "story": ("03_hand_match_answered.png", CPP, 1160, 2040)},
    "C6": {"feed": ("06_home_free.png", META, 680, 1050),
           "story": ("06_home_free.png", META, 350, 1050)},
    "C7": {"feed": ("07_reference.png", CPP, 1585, 2290),
           "story": ("07_reference.png", CPP, 1290, 2290)},
    "C8": {"feed": ("08_tile_room.png", CPP, 820, 1890),
           "story": ("08_tile_room.png", CPP, 340, 1890)},
}


def head_stack(im: Image.Image, ad: dict, x: int, y: int, width: int, story: bool) -> int:
    """Eyebrow, optional giant line, headline, body, footnote. Returns bottom y."""
    y = eyebrow(im, ad["eyebrow"], x, y) + 26
    if ad.get("big"):
        f = font(200 if story else 176, "Bold", True)
        y = text_block(im, [ad["big"]], f, x - 6, y - 20, JADE, lh=1.02)
    f, lines = fit(ad["headline"], width, 100 if story else 92, 84, 3)
    y = text_block(im, lines, f, x, y, INK, lh=1.12) + 18
    if ad.get("body"):
        bf = font(48 if story else 46, "Regular")
        y = text_block(im, wrap(ad["body"], bf, width), bf, x, y, INK2, lh=1.3)
    if ad.get("footnote"):
        ff = font(44, "Medium")
        y = text_block(im, wrap(ad["footnote"], ff, width), ff, x, y + 14, JADE, lh=1.25)
    return y


def static_feed(cid: str) -> Image.Image:
    ad = A.ADS[cid]
    im = canvas(FEED)
    y = head_stack(im, ad, M, 70, W - 2 * M, story=False) + 34
    name, folder, top, bottom = PANELS[cid]["feed"]
    panel = screen(name, top, bottom, W - 2 * M, folder)
    shadow(im, panel, (M - 3, y))
    band_top = FEED[1] - 200
    if y + panel.height > band_top:
        fade_band(im, band_top - 70, 70)
    brand_row(im, M, FEED[1] - 154, size=104)
    return im


def static_story(cid: str) -> Image.Image:
    ad = A.ADS[cid]
    im = canvas(STORY)
    x, width = SAFE_X[0], SAFE_X[1] - SAFE_X[0]
    brand_row(im, x, SAFE_Y[0])
    y = head_stack(im, ad, x, SAFE_Y[0] + 160, width, story=True)
    assert y <= SAFE_Y[1], f"{cid} story text ends at {y}, past the safe zone"
    name, folder, top, bottom = PANELS[cid]["story"]
    panel = screen(name, top, bottom, W - 2 * M, folder)
    shadow(im, panel, (M - 3, y + 40))
    return im


def reviews(story: bool) -> Image.Image:
    """One real review, set large, over the drill it talks about (v2)."""
    ad = A.ADS["C5"]
    size = STORY if story else FEED
    im = canvas(size)
    x = SAFE_X[0] if story else M
    width = (SAFE_X[1] - SAFE_X[0]) if story else W - 2 * M
    y = SAFE_Y[0] if story else 70
    if story:
        y = brand_row(im, x, y) + 52
    y = eyebrow(im, ad["eyebrow"], x, y) + 30
    quote, _, date = A.REVIEWS[0]
    st = stars(5, 56)
    im.alpha_composite(st, (x, y))
    y += st.height + 22
    f, lines = fit(f"\u201c{quote}\u201d", width, 92 if story else 86, 84, 4)
    y = text_block(im, lines, f, x, y, INK, lh=1.12) + 8
    y = text_block(im, [f"App Store review, {date}"], font(44, "Medium"), x, y, INK2)
    if story:
        assert y <= SAFE_Y[1], f"C5 story text ends at {y}"
    panel = screen("05_charleston_perfect.png", 650, 2200, W - 2 * M, META)
    shadow(im, panel, (M - 3, y + 40))
    if not story:
        fade_band(im, FEED[1] - 270, 70)
        brand_row(im, M, FEED[1] - 154, size=104)
    return im


def render_static(cid: str) -> dict[str, Image.Image]:
    if cid == "C5":
        return {"feed-4x5": reviews(False), "story-9x16": reviews(True)}
    return {"feed-4x5": static_feed(cid), "story-9x16": static_story(cid)}


# ---------------------------------------------------------------- carousel

def carousel_card(k: int, size: tuple[int, int]) -> Image.Image:
    card = A.ADS["C2"]["cards"][k]
    im = canvas(size)
    width = W - 2 * M
    square = size[1] == size[0]
    y = 64 if square else 84
    y = eyebrow(im, card["eyebrow"], M, y) + 24
    f, lines = fit(card["headline"], width, 88 if square else 96, 84, 3)
    y = text_block(im, lines, f, M, y, INK, lh=1.12) + 14
    if card.get("note") and k != 5:
        nf = font(46 if square else 50, "Regular")
        y = text_block(im, wrap(card["note"], nf, width), nf, M, y, INK2, lh=1.28)
    room = size[1] - y - (56 if square else 76)
    if k == 0:
        r = rack(width, room - 110)
        top = y + (room - 110 - r.height) // 2 + 20
        shadow(im, r, ((W - r.width) // 2, top))
        p = pill("Swipe for the 3 steps →", font(46, "Semibold"))
        im.alpha_composite(p, (W - M - p.width, size[1] - p.height - (48 if square else 64)))
    elif k in (1, 2, 3):
        kw = {1: dict(brackets=True), 2: dict(dim=PASS), 3: dict(gold=PASS)}[k]
        extra = 100 if k == 2 else 0
        r = rack(width, room - extra, **kw)
        top = y + (room - extra - r.height) // 2 + 10
        shadow(im, r, ((W - r.width) // 2, top))
        if k == 2:
            p = pill("10 of 13 tiles fit 2468", font(46, "Semibold"))
            im.alpha_composite(p, ((W - p.width) // 2, top + r.height + 30))
    elif k == 4:
        tiles = deal_tiles()
        scale = min(1.7, (room - 90) / tiles[JOKER].height)
        big = [t.resize((round(t.width * scale), round(t.height * scale)), Image.LANCZOS)
               for t in (tiles[JOKER], tiles[FLOWER])]
        gap = 120
        x0 = (W - (big[0].width * 2 + gap)) // 2
        top = y + (room - big[0].height - 80) // 2 + 10
        lf = font(48, "Semibold")
        d = ImageDraw.Draw(im)
        for j, (t, label) in enumerate(zip(big, ("Never passed", "Keep it early"))):
            x = x0 + j * (t.width + gap)
            shadow(im, t, (x, top), blur=12, alpha=50, drop=6)
            d.text((x + t.width / 2, top + t.height + 28), label, font=lf, fill=INK2, anchor="mt")
    else:
        panel = screen("05_charleston_perfect.png", 1150, 2180, width - (120 if square else 0), META)
        avail = size[1] - y - 200
        if panel.height > avail:
            panel = panel.crop((0, 0, panel.width, avail))
        px = (W - panel.width) // 2
        shadow(im, panel, (px, y + 10))
        fade_band(im, y + 10 + panel.height - 90, 90) if panel.height >= avail else None
        brand_row(im, M, size[1] - 154, size=104)
    return im


# ---------------------------------------------------------------- reel

FPS = 30
# (output start, output end, source start, speed, crop top in points for
# (9:16, 4:5)). The 4:5 panel is shorter, so its first crop starts at the rack
# to keep all four answers on screen before the tap.
SEGMENTS = [
    (0.0, 3.2, 13.6, 1.0, (205, 285)),
    (3.2, 7.2, 16.8, 1.0, (345, 345)),
    (7.2, 11.6, 54.5, 2.0, (300, 300)),  # 2x: slow enough to follow the 3 taps
    (11.6, 15.6, 64.2, 1.0, (362, 362)),
]
END_CARD = 2.8
TAP = (3.3, 3.9, 603, 1989)  # output start, end, raw x, raw y of the 2468 tap


def source_frames(start: float, dur: float) -> np.ndarray:
    cmd = ["ffmpeg", "-loglevel", "error", "-ss", f"{start}", "-t", f"{dur}", "-i", str(VIDEO),
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-"]
    raw = subprocess.run(cmd, capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(-1, 2622, 1206, 3)


def caption_layer(size: tuple[int, int], title: str, sub: str, top: int, x: int, width: int) -> Image.Image:
    im = canvas(size)
    f, lines = fit(title, width, 88, 84, 2)
    y = text_block(im, lines, f, x, top, INK, lh=1.12) + 10
    sf = font(52, "Regular")
    text_block(im, wrap(sub, sf, width), sf, x, y, INK2, lh=1.25)
    return im


def end_card(size: tuple[int, int]) -> Image.Image:
    im = canvas(size)
    story = size[1] == 1920
    cy = 760 if story else 600
    ic = icon(260)
    shadow(im, ic, ((W - 260) // 2, cy - 330), blur=16, alpha=50, drop=8)
    text_block(im, ["Mahj Trainer"], font(96, "Bold", True), 0, cy - 30, INK, center=True, width=W)
    text_block(im, ["American Mah Jongg practice"], font(52, "Regular"), 0, cy + 90, INK2,
               center=True, width=W)
    p = pill("Free to start on the App Store", font(50, "Semibold"))
    im.alpha_composite(p, ((W - p.width) // 2, cy + 200))
    return im


def tap_ring(t: float) -> Image.Image | None:
    if not TAP[0] <= t < TAP[1]:
        return None
    k = (t - TAP[0]) / (TAP[1] - TAP[0])
    r = 40 + 60 * k
    a = int(255 * (1 - k))
    im = Image.new("RGBA", (260, 260), (0, 0, 0, 0))
    ImageDraw.Draw(im).ellipse((130 - r, 130 - r, 130 + r, 130 + r), outline=CORAL + (a,), width=12)
    return im


def render_reel(size: tuple[int, int], out: pathlib.Path) -> pathlib.Path:
    story = size[1] == 1920
    cap_top, cap_x, cap_w = (SAFE_Y[0] + 10, SAFE_X[0], SAFE_X[1] - SAFE_X[0]) if story else (56, M, W - 2 * M)
    panel_top = 660 if story else 330
    pw = W - 2 * M  # 936
    scale = pw / 1158  # raw crop x 24-1182
    ph = size[1] - panel_top
    caps = A.ADS["C3"]["captions"]
    proc = subprocess.Popen(
        ["ffmpeg", "-loglevel", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s",
         f"{size[0]}x{size[1]}", "-r", str(FPS), "-i", "-", "-f", "lavfi", "-i",
         "anullsrc=channel_layout=stereo:sample_rate=44100", "-shortest", "-c:v", "libx264",
         "-preset", "slow", "-crf", "17", "-pix_fmt", "yuv420p", "-profile:v", "high",
         "-movflags", "+faststart", "-c:a", "aac", "-b:a", "96k", str(out)],
        stdin=subprocess.PIPE)
    border = Image.new("RGBA", (pw + 6, ph + 40), (0, 0, 0, 0))
    ImageDraw.Draw(border).rounded_rectangle((0, 0, pw + 5, ph + 60), 37, fill=RULE + (255,))
    for (o0, o1, s0, speed, crop_pt), (_, _, title, sub) in zip(SEGMENTS, caps):
        layer = caption_layer(size, title, sub, cap_top, cap_x, cap_w)
        shadow(layer, border, (M - 3, panel_top - 3), blur=22, alpha=46, drop=12)
        n_out = round((o1 - o0) * FPS)
        frames = source_frames(s0, (o1 - o0) * speed + 0.2)
        raw_top = crop_pt[0 if story else 1] * 3
        raw_h = round(ph / scale)
        for i in range(n_out):
            src = frames[min(round(i * speed), len(frames) - 1)]
            crop = Image.fromarray(src[raw_top:raw_top + raw_h, 24:1182])
            crop = crop.resize((pw, round(crop.height * scale)), Image.LANCZOS)
            frame = layer.copy()
            frame.alpha_composite(rounded(crop, 34, (True, True, False, False)), (M, panel_top))
            ring = tap_ring(o0 + i / FPS)
            if ring:
                cx = M + (TAP[2] - 24) * scale
                cy = panel_top + (TAP[3] - raw_top) * scale
                frame.alpha_composite(ring, (round(cx - 130), round(cy - 130)))
            proc.stdin.write(frame.convert("RGB").tobytes())
    end = end_card(size).convert("RGB").tobytes()
    for _ in range(round(END_CARD * FPS)):
        proc.stdin.write(end)
    proc.stdin.close()
    assert proc.wait() == 0, "ffmpeg failed"
    return out


def reel_cover(size: tuple[int, int]) -> Image.Image:
    """First frame of the Reel as a still, for the thumbnail field."""
    story = size[1] == 1920
    cap_top, cap_x, cap_w = (SAFE_Y[0] + 10, SAFE_X[0], SAFE_X[1] - SAFE_X[0]) if story else (56, M, W - 2 * M)
    _, _, title, sub = A.ADS["C3"]["captions"][0]
    im = caption_layer(size, title, sub, cap_top, cap_x, cap_w)
    panel_top = 660 if story else 330
    top = SEGMENTS[0][4][0 if story else 1] * 3
    shadow(im, screen("03_read_rack_q1.png", top, top + round((size[1] - panel_top) / (936 / 1158)),
                      936, META), (M - 3, panel_top - 3))
    return im


# ---------------------------------------------------------------- output

def folder_name(cid: str) -> str:
    return f"{cid} {A.ADS[cid]['slug']}"


def copy_txt(cid: str) -> str:
    ad = A.ADS[cid]
    parts = [
        f"{cid} {ad['name']}",
        f"Motivation: {ad['motivation']}",
        f"Format: {ad['format']}",
        "",
        f"Primary text (lead):\n{ad['primary']}",
        f"\nPrimary text (long):\n{ad['primary_long']}",
        f"\nAlternate primary text 1:\n{ad['alternates'][0]}",
        f"\nAlternate primary text 2:\n{ad['alternates'][1]}",
        f"\nHeadline: {ad['ad_headline']}",
        f"Description: {ad['description']}",
        f"Call to action: {ad['cta']}",
    ]
    if ad.get("cards"):
        parts.append("\nCard headlines:")
        parts += [f"  {i + 1:02d}. {c['card_headline']}" for i, c in enumerate(ad["cards"])]
    return "\n".join(parts) + "\n"


def save(im: Image.Image, path: pathlib.Path) -> None:
    im.convert("RGB").save(path, optimize=True)
    print(f"  {path.name}")


def render(cid: str, root: pathlib.Path) -> pathlib.Path:
    out = root / folder_name(cid)
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    slug = A.ADS[cid]["slug"]
    print(cid, slug)
    if cid == "C2":
        for k in range(len(A.ADS["C2"]["cards"])):
            save(carousel_card(k, FEED), out / f"{cid}-{slug}-card-{k + 1:02d}-4x5.png")
            save(carousel_card(k, SQUARE), out / f"{cid}-{slug}-card-{k + 1:02d}-1x1.png")
    elif cid == "C3":
        for size, tag in ((STORY, "9x16"), (FEED, "4x5")):
            render_reel(size, out / f"{cid}-{slug}-{tag}.mp4")
            print(f"  {cid}-{slug}-{tag}.mp4")
            save(reel_cover(size), out / f"{cid}-{slug}-cover-{tag}.png")
    else:
        for tag, im in render_static(cid).items():
            save(im, out / f"{cid}-{slug}-{tag}.png")
    (out / f"{cid}-copy.txt").write_text(copy_txt(cid))
    return out


def contact_sheet(root: pathlib.Path, ids: list[str]) -> pathlib.Path:
    thumbs: list[tuple[str, Image.Image]] = []
    for cid in ids:
        folder = root / folder_name(cid)
        for p in sorted(folder.glob("*.png")):
            if cid == "C2" and "1x1" in p.name:
                continue
            thumbs.append((p.stem.replace(f"{cid}-{A.ADS[cid]['slug']}-", f"{cid} "), Image.open(p)))
    th = 520
    cells = [(label, im.resize((round(im.width * th / im.height), th), Image.LANCZOS)) for label, im in thumbs]
    cols, gap = 6, 36
    cw = max(c.width for _, c in cells)
    rows = (len(cells) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (cw + gap) + gap, 150 + rows * (th + 110)), CREAM)
    d = ImageDraw.Draw(sheet)
    d.text((gap, 40), "Mahj Trainer Meta ads", font=font(64, "Bold", True), fill=INK)
    lf = font(44, "Medium")
    for i, (label, c) in enumerate(cells):
        x = gap + (i % cols) * (cw + gap) + (cw - c.width) // 2
        y = 150 + (i // cols) * (th + 110)
        sheet.paste(c, (x, y))
        d.rectangle((x - 1, y - 1, x + c.width, y + th), outline=RULE, width=2)
        d.text((x + c.width / 2, y + th + 14), label[:22], font=lf, fill=INK2, anchor="mt")
    path = root / "contact-sheet.png"
    sheet.save(path, optimize=True)
    print(path)
    return path


# ---------------------------------------------------------------- checks

EXPECTED = {"4x5": FEED, "9x16": STORY, "1x1": SQUARE}
PRICE = re.compile(r"\$\s?\d|\b\d+[.,]\d{2}\b|\bUSD\b|/mo\b|/yr\b|per (month|year|week)|\bprice", re.I)
CARD_HAND = re.compile(r"\b(\d)\1{2,}\b|\bNEWS\b|\b(FFFF|DDDD|NNNN)\b")
DASH = chr(0x2014)  # the em dash, spelled so this file never contains one


def ad_strings() -> list[str]:
    out: list[str] = []

    def walk(v):
        if isinstance(v, str):
            out.append(v)
        elif isinstance(v, dict):
            for x in v.values():
                walk(x)
        elif isinstance(v, (list, tuple)):
            for x in v:
                walk(x)
    walk(A.ADS)
    return out


def check(root: pathlib.Path | None) -> bool:
    ok = True
    for s in ad_strings():
        for rule, pat in (("price", PRICE), ("card-hand pattern", CARD_HAND)):
            if pat.search(s):
                print(f"FAIL {rule}: {s[:80]}")
                ok = False
    for cid, ad in A.ADS.items():
        lead = ad["primary"]
        checks = [("primary lead", lead, 124), ("headline", ad["ad_headline"], 39),
                  ("description", ad["description"], 30)]
        checks += [(f"alternate {i + 1}", t, 124) for i, t in enumerate(ad["alternates"])]
        checks += [(f"card {i + 1}", c["card_headline"], 20) for i, c in enumerate(ad.get("cards", []))]
        for label, text, limit in checks:
            if len(text) > limit:
                print(f"FAIL {cid} {label} is {len(text)} chars (limit {limit})")
                ok = False
    for p in HERE.rglob("*"):
        if p.is_file() and p.suffix in {".py", ".md", ".txt"} and DASH in p.read_text():
            print(f"FAIL em dash in {p.name}")
            ok = False
    if root:
        for p in sorted(root.rglob("*")):
            if DASH in p.name:
                print(f"FAIL em dash in file name {p.name}")
                ok = False
            if p.suffix == ".txt" and DASH in p.read_text():
                print(f"FAIL em dash in {p.name}")
                ok = False
            if p.suffix == ".png" and p.name != "contact-sheet.png":
                tag = re.search(r"(4x5|9x16|1x1)", p.name).group(1)
                got = Image.open(p).size
                flag = "ok  " if got == EXPECTED[tag] else "FAIL"
                ok &= got == EXPECTED[tag]
                print(f"{flag} {got[0]}x{got[1]}  {p.relative_to(root)}")
            if p.suffix == ".mp4":
                info = json.loads(subprocess.run(
                    ["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                     "stream=width,height,r_frame_rate:format=duration", "-of", "json", str(p)],
                    capture_output=True, text=True, check=True).stdout)
                st, dur = info["streams"][0], float(info["format"]["duration"])
                tag = re.search(r"(4x5|9x16)", p.name).group(1)
                good = (st["width"], st["height"]) == EXPECTED[tag] and 15 <= dur <= 20
                ok &= good
                print(f"{'ok  ' if good else 'FAIL'} {st['width']}x{st['height']} {dur:.1f}s "
                      f"{st['r_frame_rate']}  {p.relative_to(root)}")
    print("ALL CHECKS PASS" if ok else "CHECKS FAILED")
    return ok


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", type=pathlib.Path, default=ICLOUD)
    ap.add_argument("--all", action="store_true", help="render every candidate, not just FINAL")
    ap.add_argument("--only", nargs="*", help="concept ids, e.g. C1 C3")
    ap.add_argument("--check", type=pathlib.Path, nargs="?", const=ICLOUD, help="only run checks")
    args = ap.parse_args()
    if args.check:
        sys.exit(0 if check(args.check) else 1)
    ids = args.only or (list(A.ADS) if args.all else A.FINAL)
    args.out.mkdir(parents=True, exist_ok=True)
    for cid in ids:
        render(cid, args.out)
    if not args.only:
        contact_sheet(args.out, ids)
    sys.exit(0 if check(args.out) else 1)


if __name__ == "__main__":
    main()
