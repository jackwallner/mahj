"""Laurel badge treatments for Mahj screenshot 1 (PPO test, 2026-11).

Layout follows the store's best performing laurel screenshots (Period Tracker
"Trusted by 300M women", Sudoku.com "5,000,000+ 5-Star Ratings", MyNetDiary
"Loved by 32M+ people"): the claim is a bold hero close to headline size and
the wreath spans most of the width, so it reads in search results. The phone
is scaled down to make room instead of cropped.

The branches are Apple's laurel.leading / laurel.trailing symbols in gold,
rendered by render_laurel.swift into laurel_left.png and laurel_right.png.
"""
import math

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

SRC = "/Users/jackwallner/mahj/fastlane/screenshots/en-US/01_pass_with_a_plan.png"
SERIF = "/System/Library/Fonts/NewYork.ttf"
INK = (38, 46, 34)
GOLD = (168, 130, 58)  # the laurel symbols' gold
STARS = "*****"        # a line with this text draws five gold stars
SS = 3
CUT = 330          # headline ends here in the source
BADGE_H = 560      # height of the badge band under the headline
PHONE_SCALE = 0.9  # phone shrinks so it still fits whole below the badge
LAUREL_H = 470
GAP = 26


def font(size: int, weight: str) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(SERIF, size * SS)
    f.set_variation_by_name(weight)
    return f


def spaced(d: ImageDraw.ImageDraw, cx: float, cy: float, text: str,
           f: ImageFont.FreeTypeFont, track: float) -> float:
    widths = [d.textlength(ch, font=f) for ch in text]
    total = sum(widths) + track * (len(text) - 1)
    x = cx - total / 2
    for ch, w in zip(text, widths):
        d.text((x, cy), ch, font=f, fill=INK, anchor="lm")
        x += w + track
    return total


def stars(d: ImageDraw.ImageDraw, cx: float, cy: float, size: float) -> float:
    """Five gold stars, each size tall, centered on (cx, cy); returns the row width."""
    r_out = size / 2
    r_in = r_out * 0.382
    step = size * 1.12
    width = step * 4 + size
    for i in range(5):
        x0 = cx - width / 2 + size / 2 + i * step
        y0 = cy + r_out * 0.1
        pts = []
        for k in range(10):
            r = r_out if k % 2 == 0 else r_in
            a = math.radians(-90 + k * 36)
            pts.append((x0 + r * math.cos(a), y0 + r * math.sin(a)))
        d.polygon(pts, fill=GOLD)
    return width


def laurel(path: str) -> Image.Image:
    img = Image.open(path).convert("RGBA")
    img = img.crop(img.getbbox())
    h = LAUREL_H * SS
    return img.resize((round(img.width * h / img.height), h), Image.LANCZOS)


def badge(lines: list[tuple[str, int, str, int]], width: int) -> Image.Image:
    """lines: (text, size, weight, tracking); tracked lines are set in caps."""
    W, H = width * SS, BADGE_H * SS
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = W / 2
    heights = [size * SS * 1.12 for _, size, _, _ in lines]
    y = H / 2 - sum(heights) / 2
    widest = 0.0
    for (text, size, weight, track), h in zip(lines, heights):
        f = font(size, weight)
        cy = y + h / 2
        if text == STARS:
            w = stars(d, cx, cy, size * SS)
        elif track:
            w = spaced(d, cx, cy, text.upper(), f, track * SS)
        else:
            d.text((cx, cy), text, font=f, fill=INK, anchor="mm")
            w = d.textlength(text, font=f)
        widest = max(widest, w)
        y += h
    half = widest / 2 + GAP * SS
    left, right = laurel("laurel_left.png"), laurel("laurel_right.png")
    ly = round(H / 2 - left.height / 2)
    img.alpha_composite(left, (round(cx - half - left.width), ly))
    img.alpha_composite(right, (round(cx + half), ly))
    return img.resize((width, BADGE_H), Image.LANCZOS)


def background(src: Image.Image) -> Image.Image:
    """The source background is a vertical gradient, uniform across each row."""
    return src.crop((0, 0, 1, src.height)).resize(src.size)


def compose(lines: list[tuple[str, int, str, int]], out: str) -> Image.Image:
    src = Image.open(SRC).convert("RGB")
    W, H = src.size
    bg = background(src)
    canvas = bg.copy()
    canvas.paste(src.crop((0, 0, W, CUT)), (0, 0))

    body = src.crop((0, CUT, W, H))
    diff = ImageChops.difference(body, bg.crop((0, CUT, W, H))).convert("L")
    mask = diff.point(lambda v: 255 if v > 3 else v * 60).filter(ImageFilter.GaussianBlur(2))
    sw, sh = round(W * PHONE_SCALE), round(body.height * PHONE_SCALE)
    body, mask = body.resize((sw, sh), Image.LANCZOS), mask.resize((sw, sh), Image.LANCZOS)
    top = CUT + BADGE_H - round((570 - CUT) * PHONE_SCALE) + 40
    canvas.paste(body, ((W - sw) // 2, top), mask)

    b = badge(lines, W)
    canvas.paste(b, (0, CUT - 30), b)
    canvas.save(out)
    return canvas


def side_by_side(frames: list[Image.Image], out: str, scale: float) -> None:
    w, h = round(frames[0].width * scale), round(frames[0].height * scale)
    gap = max(8, round(40 * scale))
    sheet = Image.new("RGB", (w * len(frames) + gap * (len(frames) - 1), h), "white")
    for i, f in enumerate(frames):
        sheet.paste(f.resize((w, h), Image.LANCZOS), (i * (w + gap), 0))
    sheet.save(out)


if __name__ == "__main__":
    teacher = compose([("Recommended by", 46, "Semibold", 7),
                       ("Mahj", 150, "Semibold", 0),
                       ("Teachers", 150, "Semibold", 0)], "teacher.png")
    players = compose([("Trusted by over", 46, "Semibold", 7),
                       ("2,000", 200, "Semibold", 0),
                       ("Players", 46, "Semibold", 7)], "players.png")
    rated = compose([("Rated", 46, "Semibold", 7),
                     (STARS, 120, "Semibold", 0),
                     ("by most players", 46, "Semibold", 7)], "five_stars.png")
    control = Image.open(SRC).convert("RGB")
    side_by_side([control, teacher, players, rated], "arms.png", 0.4)
    # Search results show screenshot 1 at about 1/4 of its pixel width on a phone.
    side_by_side([control, teacher, players, rated], "arms_search_size.png", 0.18)
