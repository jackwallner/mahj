"""Laurel badge treatments for Mahj screenshot 1 (PPO test, 2026-11).

The branches are Apple's laurel.leading / laurel.trailing symbols in gold,
rendered by render_laurel.swift into laurel_left.png and laurel_right.png.
"""
from PIL import Image, ImageDraw, ImageFont

SRC = "/Users/jackwallner/mahj/fastlane/screenshots/en-US/01_pass_with_a_plan.png"
SERIF = "/System/Library/Fonts/NewYork.ttf"
INK = (38, 46, 34)
SS = 3
BW, BH = 1320, 300
SHIFT = 150
CUT = 330
LAUREL_H = 250
GAP = 34


def spaced(d: ImageDraw.ImageDraw, center: tuple[float, float], text: str,
           font: ImageFont.FreeTypeFont, track: float) -> float:
    widths = [d.textlength(ch, font=font) for ch in text]
    total = sum(widths) + track * (len(text) - 1)
    x = center[0] - total / 2
    for ch, w in zip(text, widths):
        d.text((x, center[1]), ch, font=font, fill=INK, anchor="lm")
        x += w + track
    return total


def laurel(path: str) -> Image.Image:
    img = Image.open(path).convert("RGBA")
    img = img.crop(img.getbbox())
    h = LAUREL_H * SS
    return img.resize((round(img.width * h / img.height), h), Image.LANCZOS)


def badge(top: str, big: str) -> Image.Image:
    W, H = BW * SS, BH * SS
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = W / 2, H / 2
    ft = ImageFont.truetype(SERIF, 32 * SS)
    fb = ImageFont.truetype(SERIF, 84 * SS)
    top_w = spaced(d, (cx, cy - 62 * SS), top.upper(), ft, 6 * SS)
    d.text((cx, cy + 16 * SS), big, font=fb, fill=INK, anchor="mm")
    half = max(top_w, d.textlength(big, font=fb)) / 2 + GAP * SS
    left, right = laurel("laurel_left.png"), laurel("laurel_right.png")
    y = round(cy - left.height / 2)
    img.alpha_composite(left, (round(cx - half - left.width), y))
    img.alpha_composite(right, (round(cx + half), y))
    return img.resize((BW, BH), Image.LANCZOS)


def compose(top: str, big: str, out: str) -> Image.Image:
    src = Image.open(SRC).convert("RGB")
    W, H = src.size
    canvas = Image.new("RGB", (W, H))
    canvas.paste(src.crop((0, 0, W, CUT)), (0, 0))
    canvas.paste(src.crop((0, CUT, W, H - SHIFT)), (0, CUT + SHIFT))
    canvas.paste(src.crop((0, CUT, W, CUT + 1)).resize((W, SHIFT)), (0, CUT))
    b = badge(top, big)
    canvas.paste(b, (0, CUT + 10), b)
    canvas.save(out)
    return canvas


def side_by_side(frames: list[Image.Image], out: str) -> None:
    w, h = frames[0].width * 2 // 5, frames[0].height * 2 // 5
    sheet = Image.new("RGB", (w * len(frames) + 40 * (len(frames) - 1), h), "white")
    for i, f in enumerate(frames):
        sheet.paste(f.resize((w, h), Image.LANCZOS), (i * (w + 40), 0))
    sheet.save(out)


if __name__ == "__main__":
    teacher = compose("Recommended by", "Mahj Teachers", "teacher.png")
    players = compose("Trusted by over", "2,000 Players", "players.png")
    side_by_side([Image.open(SRC).convert("RGB"), teacher, players], "arms.png")
