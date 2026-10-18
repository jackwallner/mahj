"""Compose a monthly challenge event's card (1920x1080) and details (1080x1920) art.

Usage: python3 scripts/compose-event-art.py <intro.png> <question.png> <out-dir>

Screens are raw simulator captures (1206x2622). No device frame and no added
text: the App Store overlays the event name itself, and event art must never
mention price, "free", trials or discounts (2.3.7).
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

TOP = (46, 24, 52)
BOTTOM = (86, 46, 98)


def gradient(w: int, h: int) -> Image.Image:
    img = Image.new("RGB", (w, h))
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / (h - 1)
        draw.line([(0, y), (w, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(TOP, BOTTOM)))
    return img


def panel(src: Path, width: int, crop_top: int, crop_h: int, radius: int) -> Image.Image:
    shot = Image.open(src).convert("RGB")
    shot = shot.crop((0, crop_top, shot.width, min(shot.height, crop_top + crop_h)))
    scale = width / shot.width
    shot = shot.resize((width, int(shot.height * scale)), Image.LANCZOS)
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, shot.width - 1, shot.height - 1], radius, fill=255)
    out = Image.new("RGBA", shot.size)
    out.paste(shot, (0, 0), mask)
    return out


def shadowed(canvas: Image.Image, layer: Image.Image, xy: tuple[int, int]) -> None:
    shadow = Image.new("RGBA", (layer.width + 120, layer.height + 120), (0, 0, 0, 0))
    alpha = layer.split()[3].point(lambda a: int(a * 0.45))
    shadow.paste((10, 4, 14, 255), (60, 80), alpha)
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas.alpha_composite(shadow, (xy[0] - 60, xy[1] - 60))
    canvas.alpha_composite(layer, xy)


def card(intro: Path, question: Path, out: Path) -> None:
    canvas = gradient(1920, 1080).convert("RGBA")
    # Two screens on the right half; the left keeps clear for Apple's overlay.
    left = panel(intro, 470, 300, 1700, 44)
    right = panel(question, 470, 300, 1900, 44)
    shadowed(canvas, left, (870, (1080 - left.height) // 2 + 30))
    shadowed(canvas, right, (1390, (1080 - right.height) // 2 - 20))
    canvas.convert("RGB").save(out / "event-card-1920x1080.png")


def details(question: Path, out: Path) -> None:
    canvas = gradient(1080, 1920).convert("RGBA")
    shot = panel(question, 780, 0, 2622, 64)
    shadowed(canvas, shot, ((1080 - shot.width) // 2, (1920 - shot.height) // 2))
    canvas.convert("RGB").save(out / "event-details-1080x1920.png")


if __name__ == "__main__":
    intro, question, out = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
    out.mkdir(parents=True, exist_ok=True)
    card(intro, question, out)
    details(question, out)
