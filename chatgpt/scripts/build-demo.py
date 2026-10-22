#!/usr/bin/env python3
"""Build the review demo (docs/chatgpt/demo.mp4) from ChatGPT screenshots.

The demo is a captioned slideshow: each slide pairs one screenshot of the
plugin running in ChatGPT with a short caption. Capture the frames named in
STORYBOARD (the chat column only, about 1128x1064), then run:

    python3 chatgpt/scripts/build-demo.py <frames-dir> [out.mp4]

Needs Pillow and ffmpeg. Keep captions factual and free of em dashes.
"""

import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "chatgpt" / "demo.mp4"

# (frame file, step label, title, body). The first slide is the title card.
STORYBOARD = [
    ("02-lesson-card1.png", "1 of 6 · Learn", "The player asks to learn",
     "Prompt: “Teach me the basics of American mah jongg.” Mahj Trainer opens a short lesson deck."),
    ("03-lesson-tiles.png", "1 of 6 · Learn", "Tiles drawn in the widget",
     "Back and Next step through six cards. The widget makes no network calls."),
    ("04-lesson-last.png", "1 of 6 · Learn", "The last card leads to practice",
     "Practice this starts a quiz on the same topics."),
    ("05-practice-checked.png", "2 of 6 · Practice", "Each answer is checked",
     "The answers stay in the widget, hidden from the model, and every pick is explained."),
    ("06-practice-miss.png", "2 of 6 · Practice", "A miss gets the reason",
     "A wrong pick shows the right answer and why it is right."),
    ("07-pass-picked.png", "3 of 6 · Charleston", "Pick three tiles to pass",
     "The player taps the three tiles they would pass."),
    ("08-pass-result.png", "3 of 6 · Charleston", "Compared with the coach",
     "The pass is checked against the coach's pick, with the section the deal leans toward."),
    ("09-practice-score.png", "3 of 6 · Charleston", "A score and a redo",
     "The quiz ends with the score, the question to look at again and Redo the miss."),
    ("10-rack-read.png", "4 of 6 · Rack read", "The player shares a dealt rack",
     "Prompt: “My rack is 2C 2C 4C 4C 6B 6B 8B 8D F J 1C 9B N. What should I pass?” Each passed tile gets a reason."),
    ("11-rack-reply.png", "4 of 6 · Rack read", "ChatGPT sums up the read",
     "It names the pass and sends the player to their own card for the exact lines."),
    ("12-term.png", "5 of 6 · Glossary", "Terms in plain language",
     "Prompt: “Ask Mahj Trainer what a joker swap is.” The glossary tool answers."),
    ("13-out-of-scope.png", "6 of 6 · Out of scope", "No tool for other games",
     "Riichi is a different game, so ChatGPT answers on its own without Mahj Trainer."),
]

W, H = 1920, 1080
BG = (244, 242, 236)
INK = (24, 34, 29)
INK2 = (86, 96, 90)
MUTED = (120, 124, 120)
JADE = (23, 107, 92)
SLIDE_SECONDS = 5.5
TITLE_SECONDS = 3.0
FADE = 0.4

FONT = "/System/Library/Fonts/SFNS.ttf"


def font(size: int, weight: str = "Regular") -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(FONT, size)
    try:
        f.set_variation_by_name(weight)
    except (OSError, ValueError):
        pass
    return f


def wrap(draw: ImageDraw.ImageDraw, text: str, f: ImageFont.FreeTypeFont, width: int) -> list[str]:
    lines, line = [], ""
    for word in text.split():
        trial = f"{line} {word}".strip()
        if draw.textlength(trial, font=f) <= width:
            line = trial
        else:
            lines.append(line)
            line = word
    return lines + [line]


def framed(shot: Image.Image, height: int) -> Image.Image:
    """The screenshot scaled to height, with rounded corners and a soft shadow."""
    shot = shot.convert("RGB")
    w = round(shot.width * height / shot.height)
    shot = shot.resize((w, height), Image.LANCZOS)
    radius, pad = 28, 40
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, height - 1), radius, fill=255)
    card = Image.new("RGBA", (w + pad * 2, height + pad * 2), (0, 0, 0, 0))
    shadow = Image.new("L", card.size, 0)
    ImageDraw.Draw(shadow).rounded_rectangle((pad, pad + 8, pad + w, pad + height + 8), radius, fill=60)
    card.putalpha(shadow.filter(ImageFilter.GaussianBlur(18)))
    card.paste(shot, (pad, pad), mask)
    ImageDraw.Draw(card).rounded_rectangle((pad, pad, pad + w - 1, pad + height - 1), radius, outline=(222, 218, 208), width=2)
    return card


def footer(draw: ImageDraw.ImageDraw) -> None:
    draw.text((120, 1000), "Mahj Trainer for ChatGPT", font=font(22, "Medium"), fill=MUTED)


def slide(shot_path: Path, label: str, title: str, body: str) -> Image.Image:
    img = Image.new("RGB", (W, H), BG)
    card = framed(Image.open(shot_path), 940)
    img.paste(card, (W - 80 - card.width + 40, (H - card.height) // 2), card)
    draw = ImageDraw.Draw(img)
    left, width = 120, W - 80 - card.width + 40 - 120 - 60
    title_font, body_font = font(50, "Semibold"), font(28)
    title_lines = wrap(draw, title, title_font, width)
    body_lines = wrap(draw, body, body_font, width)
    block = 36 + len(title_lines) * 62 + 24 + len(body_lines) * 42
    y = (H - block) // 2
    draw.text((left, y), label.upper(), font=font(22, "Semibold"), fill=JADE)
    y += 44
    for line in title_lines:
        draw.text((left, y), line, font=title_font, fill=INK)
        y += 62
    y += 20
    for line in body_lines:
        draw.text((left, y), line, font=body_font, fill=INK2)
        y += 42
    footer(draw)
    return img


def title_card() -> Image.Image:
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    big, small = font(84, "Bold"), font(34)
    lines = [("Mahj Trainer for ChatGPT", big, INK), ("Learn and practice American mah jongg", small, INK2)]
    y = 430
    for text, f, color in lines:
        draw.text(((W - draw.textlength(text, font=f)) / 2, y), text, font=f, fill=color)
        y += 120
    note = "Recorded in ChatGPT on the web. Not affiliated with the National Mah Jongg League."
    nf = font(22)
    draw.text(((W - draw.textlength(note, font=nf)) / 2, 1000), note, font=nf, fill=MUTED)
    return img


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    frames = Path(sys.argv[1])
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else OUT
    missing = [name for name, *_ in STORYBOARD if not (frames / name).is_file()]
    if missing:
        print("missing frames: " + ", ".join(missing))
        return 1
    with tempfile.TemporaryDirectory() as tmp:
        paths, durations = [], []
        first = Path(tmp) / "00.png"
        title_card().save(first)
        paths.append(first)
        durations.append(TITLE_SECONDS)
        for i, (name, label, title, body) in enumerate(STORYBOARD, 1):
            p = Path(tmp) / f"{i:02d}.png"
            slide(frames / name, label, title, body).save(p)
            paths.append(p)
            durations.append(SLIDE_SECONDS)
        cmd = ["ffmpeg", "-v", "error", "-y"]
        for p, d in zip(paths, durations):
            cmd += ["-loop", "1", "-framerate", "30", "-t", f"{d + FADE}", "-i", str(p)]
        chain, prev, offset = [], "[0:v]", 0.0
        for i in range(1, len(paths)):
            offset += durations[i - 1]
            tag = f"[v{i}]"
            chain.append(f"{prev}[{i}:v]xfade=transition=fade:duration={FADE}:offset={offset:.2f}{tag}")
            prev = tag
        chain.append(f"{prev}format=yuv420p[out]")
        cmd += ["-filter_complex", ";".join(chain), "-map", "[out]", "-c:v", "libx264",
                "-crf", "20", "-preset", "slow", "-movflags", "+faststart", str(out)]
        subprocess.run(cmd, check=True)
    print(f"{out} ({sum(durations):.1f}s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
