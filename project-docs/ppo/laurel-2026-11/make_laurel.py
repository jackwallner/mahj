"""Laurel badge treatments for Mahj screenshot 1 (PPO test, 2026-11)."""
import math

from PIL import Image, ImageDraw, ImageFont, ImageOps

SRC = "/Users/jackwallner/mahj/fastlane/screenshots/en-US/01_pass_with_a_plan.png"
SERIF = "/System/Library/Fonts/NewYork.ttf"
SYMBOLS = "/System/Library/Fonts/Apple Symbols.ttf"
INK = (38, 46, 34)
GOLD = (168, 130, 58)
SS = 3
BW, BH = 1320, 300
SHIFT = 150
CUT = 330


def leaf(x0, y0, ang, length, width):
    n = 20
    top, bot = [], []
    for i in range(n + 1):
        t = i / n
        w = width / 2 * math.sin(math.pi * t ** 0.85)
        top.append((t * length, w))
        bot.append((t * length, -w))
    pts = top + bot[::-1]
    ca, sa = math.cos(ang), math.sin(ang)
    return [(x0 + x * ca - y * sa, y0 + x * sa + y * ca) for x, y in pts]


def left_branch(d, cx, cy):
    ex, rx, ry = cx - 330 * SS, 95 * SS, 118 * SS
    a0, a1 = 62, 292
    pt = lambda a: (ex + rx * math.cos(a), cy + ry * math.sin(a))
    tan = lambda a: math.atan2(ry * math.cos(a), -rx * math.sin(a))
    stem = [pt(math.radians(a0 + (a1 - a0) * i / 80)) for i in range(81)]
    d.line(stem, fill=GOLD, width=5 * SS, joint="curve")
    pairs = 8
    for i in range(pairs):
        f = i / pairs
        a = math.radians(a0 + 14 + (a1 - a0 - 20) * f)
        x, y = pt(a)
        size = (1.0 - 0.4 * f) * SS
        for k in (-1, 1):
            d.polygon(leaf(x, y, tan(a) + k * math.radians(42), 62 * size, 24 * size), fill=GOLD)
    a = math.radians(a1)
    x, y = pt(a)
    d.polygon(leaf(x, y, tan(a), 44 * SS, 18 * SS), fill=GOLD)


def spaced(d, center, text, font, fill, track):
    widths = [d.textlength(ch, font=font) for ch in text]
    total = sum(widths) + track * (len(text) - 1)
    x = center[0] - total / 2
    for ch, w in zip(text, widths):
        d.text((x, center[1]), ch, font=font, fill=fill, anchor="lm")
        x += w + track


def badge(top, big, stars=False):
    W, H = BW * SS, BH * SS
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    left_branch(ImageDraw.Draw(layer), W / 2, H / 2)
    img = Image.alpha_composite(layer, ImageOps.mirror(layer))
    d = ImageDraw.Draw(img)
    cx, cy = W / 2, H / 2
    if stars:
        fs = ImageFont.truetype(SYMBOLS, 46 * SS)
        spaced(d, (cx, cy - 78 * SS), "★★★★★", fs, GOLD, 6 * SS)
    else:
        ft = ImageFont.truetype(SERIF, 34 * SS)
        spaced(d, (cx, cy - 74 * SS), top.upper(), ft, INK, 6 * SS)
    fb = ImageFont.truetype(SERIF, 88 * SS)
    d.text((cx, cy + 6 * SS), big, font=fb, fill=INK, anchor="mm")
    if stars:
        ft = ImageFont.truetype(SERIF, 34 * SS)
        spaced(d, (cx, cy + 84 * SS), top.upper(), ft, INK, 6 * SS)
    return img.resize((BW, BH), Image.LANCZOS)


def compose(top, big, out, stars=False):
    src = Image.open(SRC).convert("RGB")
    W, H = src.size
    canvas = Image.new("RGB", (W, H))
    canvas.paste(src.crop((0, 0, W, CUT)), (0, 0))
    canvas.paste(src.crop((0, CUT, W, H - SHIFT)), (0, CUT + SHIFT))
    canvas.paste(src.crop((0, CUT, W, CUT + 1)).resize((W, SHIFT)), (0, CUT))
    b = badge(top, big, stars)
    canvas.paste(b, (0, CUT + 10), b)
    canvas.save(out)


if __name__ == "__main__":
    compose("Recommended by", "Mahj Teachers", "teacher.png")
    compose("by mahj players", "Rated 4.6", "rating.png", stars=True)
    compose("Trusted by over", "2,000 Players", "players.png")
