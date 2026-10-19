#!/usr/bin/env python3
"""Render the first-screenshot hook variants for Mahj Trainer (2026-10-19).

Reuses the fleet shotflow renderer (~/ios/appstore-screenshots/lib/render.py)
for the header, fonts and background so the frames match the live set
(ppo-2026-10/mahj-v2: theme colours, New York serif at 156 px, two-line cap,
no periods). The only change from the live style: no device frame. The real
app capture sits on the canvas as a rounded card with a soft shadow.

Source: source-charleston-perfect-pass.png, a real iPhone 17 Pro simulator
capture of the free Charleston drill (Pick Your Pass, coach answer), the same
screen as Meta ad C1. It is cropped below the status bar and above the old
question-report link, which 1.4.1 removed.

Usage: python3 render_hooks.py
Writes the variant PNGs (1320x2868) and contact-sheet.png next to this file.
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path.home() / "ios" / "appstore-screenshots"))
from lib.render import (  # noqa: E402
    draw_header,
    font,
    gradient,
    paste_rounded,
    shadowed_round_rect,
)

HERE = Path(__file__).resolve().parent
SOURCE = HERE / "source-charleston-perfect-pass.png"
SIZE = (1320, 2868)

# Same theme as the live set (configs/ppo-2026-10/mahj-v2.json).
THEME = {
    "background": "#f4f1e8",
    "background_2": "#d8dfc2",
    "ink": "#283026",
    "muted": "#6c7562",
    "accent": "#5b8360",
    "accent_2": "#d77c58",
    "headline_font": "serif",
    "body_font": "sans",
}
LAYOUT = {
    "header_top": 110,
    "header_size": 156,
    "header_min_size": 140,
    "header_max_lines": 2,
    "header_margin": 56,
    "header_bottom_padding": 34,
}

CROP_TOP = 150  # below the status bar, keeps the "Pick Your Pass" title
CROP_BOTTOM = 2236  # below the coach card, above the removed report link
CARD_WIDTH = 1236
CARD_RADIUS = 60
CARD_BORDER = (205, 196, 178, 255)

VARIANTS = [
    ("a", "Never hold up\nthe Charleston"),
    ("b", "Know which 3\ntiles to pass"),
    ("c", "Practice the\nCharleston at home"),
]


def slug(text: str) -> str:
    return "-".join(text.lower().split())


def render(header: str) -> Image.Image:
    canvas = gradient(SIZE, THEME["background"], THEME["background_2"]).convert("RGBA")
    frame = {"header": header, "layout": LAYOUT}
    header_end, info = draw_header(canvas, frame, THEME, show_guides=False)
    if "." in header or info["header_lines"] > 2:
        raise ValueError(f"header breaks the contract: {header!r}")

    raw = Image.open(SOURCE).convert("RGB").crop((0, CROP_TOP, 1206, CROP_BOTTOM))
    height = round(CARD_WIDTH * raw.height / raw.width)
    screen = raw.resize((CARD_WIDTH, height), Image.Resampling.LANCZOS)
    x = (SIZE[0] - CARD_WIDTH) // 2
    gap = 56
    space = SIZE[1] - header_end - gap
    y = header_end + gap + max(0, (space - height) // 2 - 20)
    if y + height > SIZE[1] - 40:
        raise ValueError("screen card does not fit under the header")

    box = (x - 3, y - 3, x + CARD_WIDTH + 3, y + height + 3)
    shadowed_round_rect(canvas, box, CARD_RADIUS + 3, CARD_BORDER, shadow=(0, 20, 38, 58), blur=30)
    paste_rounded(canvas, screen, (x, y), CARD_RADIUS)
    return canvas.convert("RGB")


def contact_sheet(paths: list[Path], out: Path) -> None:
    thumb_w = 392  # roughly a search-result thumbnail on a 6.9" phone, x3
    pad = 36
    thumbs = [Image.open(p).resize((thumb_w, round(thumb_w * SIZE[1] / SIZE[0])), Image.Resampling.LANCZOS) for p in paths]
    sheet = Image.new("RGB", (pad + len(thumbs) * (thumb_w + pad), thumbs[0].height + pad * 2 + 40), (255, 255, 255))
    draw = ImageDraw.Draw(sheet)
    for i, thumb in enumerate(thumbs):
        x = pad + i * (thumb_w + pad)
        sheet.paste(thumb, (x, pad))
        draw.text((x, pad + thumb.height + 10), paths[i].stem, font=font("sans", 22), fill=(60, 60, 60))
    sheet.save(out)


def main() -> None:
    written = []
    for key, header in VARIANTS:
        out = HERE / f"hook-{key}-{slug(header)}.png"
        image = render(header)
        assert image.size == SIZE
        image.save(out)
        written.append(out)
        print(f"wrote {out}")
    contact_sheet(written, HERE / "contact-sheet.png")
    print(f"wrote {HERE / 'contact-sheet.png'}")


if __name__ == "__main__":
    main()
