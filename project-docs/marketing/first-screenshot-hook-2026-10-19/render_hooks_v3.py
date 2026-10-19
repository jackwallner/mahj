#!/usr/bin/env python3
"""v3 of the first-screenshot hooks: back in an iPhone, on a sunburst.

Jack's read on v2: without the phone shape the screen is less believable.
v3 puts the trimmed screen back in the shotflow iPhone frame at the real
screen aspect, on a deep green sunburst that echoes the icon (the style that
works for Mahjong Trainer: Learn & Win, in Mahj's own palette).

The screen keeps the v2 cut (no coach paragraph or tip). To keep the true
iPhone aspect, the space the paragraph left is filled with the app's own
background, so the Next Deal button sits where it does in the app.

Also renders icon-concept-v3.png: the current 2 Crak tile, tilted with depth,
on the same sunburst with a terracotta sun. A concept only; an icon change
ships in a binary.

Usage: python3 render_hooks_v3.py
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, str(Path.home() / "ios" / "appstore-screenshots"))
from lib.render import draw_header, draw_phone  # noqa: E402

import render_hooks as v1

HERE = Path(__file__).resolve().parent
SIZE = v1.SIZE

DEEP = (24, 62, 48)  # icon green, darkened
RAY = (33, 78, 61)
SUN = (215, 124, 88)  # accent_2 terracotta
CREAM = "#f4f1e8"

THEME = dict(v1.THEME, ink=CREAM)
LAYOUT = dict(v1.LAYOUT, phone_width=1120, phone_gap=70, bottom_margin=-140, phone_bezel=22)

TOP = (0, 1556)  # status bar through the coach's three tiles
CARD_END = (2128, 2234)  # coach card bottom padding, edge and shadow
BUTTON = (2268, 2622)  # fade, Next Deal button, home indicator


def screen_source() -> Image.Image:
    """Full-height screen with the coach paragraph and tip removed."""
    raw = Image.open(v1.SOURCE).convert("RGB")
    w = raw.width
    parts = [raw.crop((0, TOP[0], w, TOP[1])), raw.crop((0, CARD_END[0], w, CARD_END[1]))]
    bottom = raw.crop((0, BUTTON[0], w, BUTTON[1]))
    filler_h = raw.height - sum(p.height for p in parts) - bottom.height
    a = raw.crop((0, CARD_END[1], w, CARD_END[1] + 1)).resize((w, filler_h))
    b = raw.crop((0, BUTTON[0], w, BUTTON[0] + 1)).resize((w, filler_h))
    ramp = Image.linear_gradient("L").resize((w, filler_h))
    parts += [Image.composite(b, a, ramp), bottom]
    out = Image.new("RGB", raw.size)
    y = 0
    for p in parts:
        out.paste(p, (0, y))
        y += p.height
    assert y == raw.height
    return out


def sunburst(size: tuple[int, int], center: tuple[int, int], rays: int = 28, sun: int = 0) -> Image.Image:
    img = Image.new("RGB", size, DEEP)
    draw = ImageDraw.Draw(img)
    reach = int(math.hypot(*size) * 1.2)
    step = 2 * math.pi / rays
    cx, cy = center
    for i in range(0, rays, 2):
        a0, a1 = i * step, (i + 1) * step
        draw.polygon([(cx, cy), (cx + reach * math.cos(a0), cy + reach * math.sin(a0)),
                      (cx + reach * math.cos(a1), cy + reach * math.sin(a1))], fill=RAY)
    # Vignette: darken toward the edges so the rays read as light, not stripes.
    mask = Image.radial_gradient("L").resize(size)
    dark = Image.new("RGB", size, (14, 38, 29))
    img = Image.composite(dark, img, mask.point(lambda v: min(255, int(v * 0.9))))
    if sun:
        ImageDraw.Draw(img).ellipse((cx - sun, cy - sun, cx + sun, cy + sun), fill=SUN)
    return img


def render_screenshot(header: str, screen: Image.Image) -> Image.Image:
    canvas = sunburst(SIZE, (SIZE[0] // 2, 1350)).convert("RGBA")
    frame = {"header": header, "layout": LAYOUT}
    header_end, info = draw_header(canvas, frame, THEME, show_guides=False)
    if "." in header or info["header_lines"] > 2:
        raise ValueError(f"header breaks the contract: {header!r}")
    draw_phone(canvas, screen, frame, header_end, show_guides=False)
    return canvas.convert("RGB")


def icon_concept(size: int = 1024) -> Image.Image:
    canvas = sunburst((size, size), (size // 2, int(size * 0.62)), rays=22, sun=int(size * 0.34))
    tile_w, tile_h, depth = int(size * 0.50), int(size * 0.64), int(size * 0.035)
    tile = Image.new("RGBA", (tile_w + depth, tile_h + depth), (0, 0, 0, 0))
    d = ImageDraw.Draw(tile)
    r = int(size * 0.07)
    d.rounded_rectangle((depth, depth, tile_w + depth - 1, tile_h + depth - 1), r, fill=(196, 178, 140))
    d.rounded_rectangle((0, 0, tile_w - 1, tile_h - 1), r, fill=(250, 245, 232))
    red = (190, 40, 40)
    num = ImageFont.truetype("/System/Library/Fonts/Supplemental/Songti.ttc", int(size * 0.17), index=2)
    # Songti face 0 (SC Black) has no 萬; face 2 is TC Bold.
    han = ImageFont.truetype("/System/Library/Fonts/Supplemental/Songti.ttc", int(size * 0.30), index=2)
    d.text((tile_w // 2, int(tile_h * 0.27)), "2", font=num, fill=red, anchor="mm")
    d.text((tile_w // 2, int(tile_h * 0.66)), "萬", font=han, fill=red, anchor="mm")
    tile = tile.rotate(-9, resample=Image.Resampling.BICUBIC, expand=True)
    pad = int(size * 0.08)  # room for the blur, or the shadow clips to a box
    shadow = Image.new("RGBA", (tile.width + pad * 2, tile.height + pad * 2), (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 110), (pad, pad), mask=tile.split()[3])
    shadow = shadow.filter(ImageFilter.GaussianBlur(size * 0.025))
    x, y = (size - tile.width) // 2, int(size * 0.47) - tile.height // 2
    base = canvas.convert("RGBA")
    base.alpha_composite(shadow, (x - pad + int(size * 0.02), y - pad + int(size * 0.035)))
    base.alpha_composite(tile, (x, y))
    return base.convert("RGB")


def main() -> None:
    screen = screen_source()
    written = []
    for key, header in v1.VARIANTS:
        out = HERE / f"hook-{key}-v3-{v1.slug(header)}.png"
        image = render_screenshot(header, screen)
        assert image.size == SIZE
        image.save(out)
        written.append(out)
        print(f"wrote {out}")
    v1.contact_sheet(written, HERE / "contact-sheet-v3.png")
    icon = icon_concept()
    icon.save(HERE / "icon-concept-v3.png")
    print("wrote contact-sheet-v3.png, icon-concept-v3.png")


if __name__ == "__main__":
    main()
