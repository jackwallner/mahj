#!/usr/bin/env python3
"""Composite the variant B Play screenshots for a store listing experiment.

Built to win at thumbnail size, where the live set (A) loses: a deep jade
field (the app icon's green) with a cream serif headline, and a larger crop of
the real screen (about 1.5x the live scale) that runs off the bottom edge, so
tiles and text stay legible when Play shrinks the image. Same 1080x1920 size,
fonts and rounded screen edge as scripts/play_screenshot_compositor.py.
Reads android/play-assets/experiment-b/raw/ (from
scripts/android_capture_screenshots_b.py), writes
android/play-assets/experiment-b/screenshots/ and a contact sheet of the live
set against variant B at thumbnail size, experiment-b/compare.png.

Usage: python3 scripts/play_screenshot_compositor_b.py
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

import appstore_screenshot_compositor as ios

ROOT = Path(__file__).resolve().parent.parent
EXP = ROOT / "android" / "play-assets" / "experiment-b"
RAW = EXP / "raw"
OUT = EXP / "screenshots"
LIVE = ROOT / "android" / "play-assets" / "screenshots"

W, H = 1080, 1920
FIELD = (28, 84, 66)  # the app icon's jade
HEADLINE = 104
LINE = 116
TOP = 104
RULE_Y = TOP + 2 * LINE + 30
SHOT_TOP = RULE_Y + 62
SHOT_W = 980
CORNER = 54


@dataclass
class Shot:
    raw: str
    out: str
    headline: str  # "\n" marks the line break
    crop_top: int  # first raw row shown; the crop runs off the bottom edge
    cut: int | None = None  # a text-free raw row inside the next card, stretched to the bottom edge


SHOTS = [
    Shot("01-home.png", "01_learn.png", "Learn American\nMah Jongg", 0, cut=1605),
    Shot("02-coach.png", "02_coach.png", "Play a hand\nwith a coach", 330),
    Shot("03-card.png", "03_card.png", "Learn to read\nthe card", 430),
    Shot("04-charleston.png", "04_charleston.png", "Master the\nCharleston", 470),
    Shot("05-minute.png", "05_daily.png", "Five minutes\na day", 250, cut=1815),
    Shot("06-reference.png", "06_reference.png", "Look it up\nmid game", 150, cut=1545),
]


def render(shot: Shot) -> Path:
    canvas = Image.new("RGB", (W, H), FIELD)
    draw = ImageDraw.Draw(canvas, "RGBA")
    font = ios.serif(HEADLINE, "Bold")
    for i, line in enumerate(shot.headline.split("\n")):
        width = draw.textlength(line, font=font)
        if width > W - 120:
            raise ValueError(f"{shot.out}: {line!r} is {width:.0f}px wide")
        draw.text(((W - width) / 2, TOP + i * LINE), line, font=font, fill=ios.CREAM)
    draw.rounded_rectangle([(W / 2 - 44, RULE_Y), (W / 2 + 44, RULE_Y + 6)], radius=3, fill=ios.GOLD)

    raw = Image.open(RAW / shot.raw).convert("RGB")
    scale = SHOT_W / raw.width
    visible = round((H - SHOT_TOP) / scale)
    if shot.crop_top + visible > raw.height:
        raise ValueError(f"{shot.raw}: crop {shot.crop_top}+{visible} runs past {raw.height}")
    crop = raw.crop((0, shot.crop_top, raw.width, shot.crop_top + visible))
    if shot.cut is not None:
        # Never end on a half-visible line of text: the card carries on past the
        # edge as its own empty row, borders included.
        top = shot.cut - shot.crop_top
        band = raw.crop((0, shot.cut, raw.width, shot.cut + 1)).resize((raw.width, crop.height - top))
        crop.paste(band, (0, top))
    shot_h = H - SHOT_TOP
    scaled = crop.resize((SHOT_W, shot_h), Image.LANCZOS)
    left = (W - SHOT_W) // 2

    shadow = Image.new("RGBA", (SHOT_W + 120, shot_h + 120), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([(60, 70), (60 + SHOT_W, 60 + shot_h + CORNER)], radius=CORNER, fill=(0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(26))
    canvas.paste(shadow, (left - 60, SHOT_TOP - 60), shadow)
    # Round only the top corners: the screen continues past the bottom edge.
    mask = ios.rounded_mask((SHOT_W, shot_h + CORNER), CORNER).crop((0, 0, SHOT_W, shot_h))
    canvas.paste(scaled, (left, SHOT_TOP), mask)
    ImageDraw.Draw(canvas, "RGBA").rounded_rectangle(
        [(left, SHOT_TOP), (left + SHOT_W, H + CORNER)], radius=CORNER, outline=(*ios.CREAM, 150), width=3
    )

    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / shot.out
    canvas.save(path, "PNG")
    return path


def compare() -> Path:
    """A over B at thumbnail size (Play's phone gallery shows them about this small)."""
    thumb_w, thumb_h, gap, pad, label_h = 162, 288, 14, 28, 52
    rows = [("A  live", sorted(LIVE.glob("*.png"))), ("B  experiment", sorted(OUT.glob("*.png")))]
    cols = max(len(files) for _, files in rows)
    sheet = Image.new("RGB", (2 * pad + cols * thumb_w + (cols - 1) * gap, pad + 2 * (label_h + thumb_h + pad)), (255, 255, 255))
    draw = ImageDraw.Draw(sheet)
    font = ios.sans(26, "Semibold")
    y = pad
    for label, files in rows:
        draw.text((pad, y), label, font=font, fill=ios.INK)
        y += label_h
        for i, f in enumerate(files):
            sheet.paste(Image.open(f).convert("RGB").resize((thumb_w, thumb_h), Image.LANCZOS), (pad + i * (thumb_w + gap), y))
        y += thumb_h + pad
    path = EXP / "compare.png"
    sheet.save(path, "PNG")
    return path


def main() -> None:
    for shot in SHOTS:
        path = render(shot)
        print(f"wrote {path.relative_to(ROOT)} {Image.open(path).size}")
    print(f"wrote {compare().relative_to(ROOT)}")


if __name__ == "__main__":
    main()
