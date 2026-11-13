#!/usr/bin/env python3
"""C9: the best TikTok post as a Meta video ad.

    python3 c9_whole_charleston.py [--out DIR] [--still t1,t2,...]

"The whole Charleston" animated short is the account's best post by views, shares
and saves (2026-11-13 pull). This cuts its opening to ten seconds (hook, right,
across, left), then turns to the app's own Pick Your Pass drill and coach card,
then an end card. One render gives the 9:16 and, cropped from the same frames,
the 4:5.

Everything a viewer must read sits in y 250 to 1250 of the 9:16, clear of the
Reels and Stories overlays, which is also why the 4:5 is a plain crop. Voice is
Kokoro and the score is synthesized (see the shorts engine, render.py); every
caption is burned in, so it plays with the sound off.
"""

from __future__ import annotations

import functools
import pathlib
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = pathlib.Path(__file__).resolve().parent
SHORTS = pathlib.Path.home() / "ios/growth/animated-shorts-2026-10-27"
sys.path[:0] = [str(SHORTS), str(HERE)]
import build_pack as B  # noqa: E402
import charleston as C  # noqa: E402
import render as R  # noqa: E402
from render import OUT, seg, wave  # noqa: E402

ID = "C9-whole-charleston-video"
FOLDER = "C9 whole-charleston-video"
LINES = [
    "The Charleston, in ten seconds.",
    "Pass three tiles to your right.",
    "Then three across.",
    "Then three to your left. That's the first Charleston.",
    "So which three do you pass? Practice with a coach that explains every pass.",
]
HOOK = ("The Charleston,", "in 10 seconds.")
COPY = {
    "Primary text": "The Charleston in 10 seconds: three right, three across, three left. "
                    "Then practice choosing your 3 with a coach that explains every pass.",
    "Primary text, long": "The Charleston in 10 seconds: three right, three across, three left. "
                          "Then practice choosing your 3 with a coach that explains every pass.\n"
                          "Mahj Trainer is short American Mah Jongg drills for newer players: the Charleston, "
                          "reading your rack, keep or throw. Original practice hands, free to start, no account.",
    "Alternate 1": "Right, across, left. The order is the easy part. Practice picking your 3 tiles on real "
                   "deals, then see the coach's pass and the reason.",
    "Alternate 2": "New to the Charleston? Watch it once, then practice the pass at home before game night.",
    "Headline": "Practice the Charleston at home",
    "Description": "American Mah Jongg drills",
    "CTA": "Install Now",
}

R.SPEED, R.TAIL, R.END_CARD = 1.06, 0.35, 2.8
HOOK_Y, CAPTION_Y = 250, 365  # the engine draws these at 200 and 1370, outside Meta's safe area
FEED_TOP = 80  # the 4:5 is rows 80 to 1430 of the 9:16
HOLD = 0.7  # extra time on the coach card before the end card

# ---------------------------------------------------------------- text in the safe area

_hook_overlay, _caption, _timeline = R.hook_overlay, R.caption, R.timeline


def hook_overlay(hook: tuple[str, ...], alpha: float) -> Image.Image:
    out = Image.new("RGBA", (R.W, R.H), (0, 0, 0, 0))
    out.alpha_composite(_hook_overlay(hook, alpha), (0, HOOK_Y - 200))
    return out


def caption(base: Image.Image, group, t: float, alpha: float) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    _caption(layer, group, t, alpha)
    base.alpha_composite(layer, (0, 0), (0, 1370 - CAPTION_Y, R.W, R.H))


def timeline(short, vo):
    scenes = _timeline(short, vo)
    scenes[-2]["end"] += HOLD
    scenes[-1]["start"] += HOLD
    scenes[-1]["end"] += HOLD
    return scenes


R.hook_overlay, R.caption, R.timeline = hook_overlay, caption, timeline

# ---------------------------------------------------------------- the three passes

PASS_LINES = ((1, 0, "right."), (2, 1, "across."), (3, 2, "left."))


def pass_timing(line: int, word: str, dur: float) -> tuple[float, float]:
    """(start, length): the tiles leave just before the word that names the direction."""
    start = max(0.1, C.cue(line, word, 0.6) + R.LEAD - 0.45)
    return start, min(1.5, dur - start - 0.05) if line < 3 else 1.5


def pass_scene(line: int, idx: int, word: str):
    direction, picks, _ = C.PASSES[idx]

    def scene(t: float, dur: float) -> Image.Image:
        im = C.table().copy()
        R.glow(im, 540, C.CY, 900, (255, 214, 150), 0.14 + 0.02 * wave(t, 3.2))
        start, length = pass_timing(line, word, dur)
        C.arrow(im, direction, seg(t, start - 0.4, start) * (1 - seg(t, start + length, start + length + 0.3)))
        C.draw_pass(im, (t - start) / length, direction, C.states()[idx], C.states()[idx + 1], picks,
                    lifted=seg(t, 0.15, 0.55) if line == 1 else 0.0)
        return im
    return scene


# ---------------------------------------------------------------- the app: pick, then the coach

PANEL = (72, 500, 936, 900)  # x, y, width, height of the app panel
RAW_X, RAW_W = 24, 1158  # raw crop of the 1206x2622 recording
SCALE = PANEL[2] / RAW_W
PICK_SRC, PICK_TOP = 55.55, 820  # recording second and raw row where the pick view starts
TAPS = ((56.42, 678, 1515), (57.92, 752, 1302), (59.17, 227, 1515))  # second, raw x, raw y
CARD_SRC, CARD_TOP = 63.9, 1120
APP: dict = {}


def extract(folder: pathlib.Path, stem: str, start: float, dur: float, top: int, speed: float) -> int:
    raw_h = round(PANEL[3] / SCALE)
    vf = (f"crop={RAW_W}:{raw_h}:{RAW_X}:{top},setpts=PTS/{speed:.4f},fps={R.FPS},"
          f"scale={PANEL[2]}:{PANEL[3]}:flags=lanczos")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", f"{start}", "-t", f"{dur}", "-i", str(B.VIDEO),
                    "-vf", vf, str(folder / f"{stem}_%04d.png")], check=True)
    return len(list(folder.glob(f"{stem}_*.png")))


def prepare(vo) -> None:
    C.prepare(vo)
    cut = C.cue(4, "coach", 2.8) + R.LEAD - 0.25  # the coach card arrives as the voice says "coach"
    speed = min(2.6, max(1.4, (TAPS[-1][0] - PICK_SRC + 0.3) / (cut - 0.15)))
    folder = pathlib.Path(tempfile.mkdtemp(prefix="c9-app-"))
    APP.update(cut=cut, speed=speed, dir=folder,
               pick=extract(folder, "pick", PICK_SRC, (cut + 0.6) * speed, PICK_TOP, speed),
               card=extract(folder, "card", CARD_SRC, 7.0, CARD_TOP, 1.0))


@functools.lru_cache(maxsize=4)
def app_frame(stem: str, i: int) -> Image.Image:
    i = min(max(i, 0), APP[stem] - 1)
    return Image.open(APP["dir"] / f"{stem}_{i + 1:04d}.png").convert("RGB")


@functools.cache
def wood() -> Image.Image:
    im = C.table().copy()
    plank = im.crop((0, 0, R.W, 450))  # three clean plank rows above the cloth
    for y in range(450, R.H, 450):
        im.paste(plank, (0, y))
    return im


@functools.cache
def panel_back() -> Image.Image:
    _, _, w, h = PANEL
    pad = 60
    out = Image.new("RGBA", (w + 2 * pad, h + 2 * pad), (0, 0, 0, 0))
    ImageDraw.Draw(out).rounded_rectangle((pad, pad + 16, pad + w, pad + h + 16), 40, fill=(30, 16, 10, 150))
    out = out.filter(ImageFilter.GaussianBlur(20))
    ImageDraw.Draw(out).rounded_rectangle((pad - 3, pad - 3, pad + w + 2, pad + h + 2), 39, fill=B.RULE + (255,))
    return out


def ring(k: float) -> Image.Image:
    r = 34 + 62 * OUT(k)
    im = Image.new("RGBA", (220, 220), (0, 0, 0, 0))
    ImageDraw.Draw(im).ellipse((110 - r, 110 - r, 110 + r, 110 + r), outline=B.CORAL + (int(255 * (1 - k)),),
                               width=12)
    return im


def app(t: float, dur: float) -> Image.Image:
    im = wood().copy()
    R.glow(im, 540, 1000, 1000, (255, 214, 150), 0.16 + 0.02 * wave(t, 3.2))
    return im


def app_overlay(t: float) -> list[tuple[Image.Image, tuple[int, int]]]:
    x, y, w, h = PANEL
    y += int(40 * (1 - OUT(seg(t, 0, 0.55))))
    cut = APP["cut"]
    shot = app_frame("pick", int(t * R.FPS))
    k = seg(t, cut, cut + 0.3)
    if k > 0:
        shot = Image.blend(shot, app_frame("card", int((t - cut) * R.FPS)), k)
    shot = shot.convert("RGBA")
    shot.putalpha(R.rounded_mask((w, h), 36))
    out = [(panel_back(), (x - 60, y - 60)), (shot, (x, y))]
    for at, rx, ry in TAPS:
        k = (t - (at - PICK_SRC) / APP["speed"]) / 0.45
        if 0 <= k < 1 and t < cut:
            out.append((ring(k), (round(x + (rx - RAW_X) * SCALE) - 110, round(y + (ry - PICK_TOP) * SCALE) - 110)))
    return out


# ---------------------------------------------------------------- end card

def fade(im: Image.Image, a: float) -> Image.Image:
    if a >= 0.999:
        return im
    out = im.copy()
    out.putalpha(out.getchannel("A").point(lambda v: int(v * a)))
    return out


@functools.cache
def label(text: str, size: int, weight: str, serif: bool, fill: tuple) -> Image.Image:
    f = B.font(size, weight, serif)
    asc, desc = f.getmetrics()
    im = Image.new("RGBA", (round(f.getlength(text)) + 8, asc + desc + 8), (0, 0, 0, 0))
    ImageDraw.Draw(im).text((4, 4), text, font=f, fill=fill)
    return im


def end_overlay(t: float) -> list[tuple[Image.Image, tuple[int, int]]]:
    parts = [(R.icon(300), 380), (label("Mahj Trainer", 100, "Bold", True, B.INK), 782),
             (label("American Mah Jongg practice", 52, "Regular", False, B.INK2), 918),
             (B.pill("Free to start on the App Store", B.font(52, "Semibold")), 1040)]
    out = []
    for k, (im, y) in enumerate(parts):
        p = OUT(seg(t, 0.1 + 0.16 * k, 0.8 + 0.16 * k))
        out.append((fade(im, p), ((R.W - im.width) // 2, int(y + 30 * (1 - p)))))
    return out


# ---------------------------------------------------------------- sound

def sfx(scenes: list[dict], buf: np.ndarray, rng: np.random.Generator) -> None:
    s = [sc["start"] for sc in scenes]
    for start in C.HOOK_STARTS:  # the hook's flights landing
        if 0 < start + C.HOOK_LEN < scenes[0]["end"]:
            for k in range(4):
                R.add(buf, R.click(rng), s[0] + start + C.HOOK_LEN + 0.02 * k, 0.08 + 0.03 * rng.random())
    for line, _, word in PASS_LINES:
        start, length = pass_timing(line, word, scenes[line]["end"] - s[line])
        for k in range(4):
            R.add(buf, R.click(rng), s[line] + start + 0.75 * length + 0.02 * k, 0.07 + 0.03 * rng.random())
    for at, _, _ in TAPS:
        R.add(buf, R.click(rng), s[4] + (at - PICK_SRC) / APP["speed"], 0.11)
    for k, n in enumerate(("A4", "C5", "F5")):  # the coach card landing
        R.add(buf, R.note(R.hz(n), 1.1, 0.10), s[4] + APP["cut"] + 0.12 + 0.07 * k)


SHORT = R.Short(ID, LINES, [C.hook, *(pass_scene(*p) for p in PASS_LINES), app], HOOK,
                overlays={app: app_overlay, R.scene6: end_overlay}, sfx=sfx, prepare=prepare)

# ---------------------------------------------------------------- render


def feed(im: Image.Image) -> Image.Image:
    return im.crop((0, FEED_TOP, R.W, FEED_TOP + 1350))


def encoder(height: int, path: pathlib.Path) -> subprocess.Popen:
    return subprocess.Popen(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s",
                             f"{R.W}x{height}", "-r", str(R.FPS), "-i", "-", "-c:v", "libx264", "-preset", "slow",
                             "-crf", "18", "-pix_fmt", "yuv420p", "-profile:v", "high", str(path)],
                            stdin=subprocess.PIPE)


def mux(video: pathlib.Path, audio: pathlib.Path, out: pathlib.Path) -> None:
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(video), "-i", str(audio), "-c:v", "copy",
                    "-af", "loudnorm=I=-14:TP=-1.5:LRA=11", "-c:a", "aac", "-b:a", "192k", "-ar", str(R.SR),
                    "-shortest", "-movflags", "+faststart", str(out)], check=True)


def main() -> None:
    args = sys.argv[1:]
    out = pathlib.Path(args[args.index("--out") + 1]) if "--out" in args else B.ICLOUD / FOLDER
    out.mkdir(parents=True, exist_ok=True)
    work = pathlib.Path(tempfile.mkdtemp(prefix="c9-"))
    vo = R.narrate(LINES, work)
    prepare(vo)
    scenes = R.timeline(SHORT, vo)
    total = scenes[-1]["end"]
    nframes = int(round(total * R.FPS))
    print("scenes:", ", ".join(f"{sc['start']:.2f}" for sc in scenes), f"end {total:.2f}",
          f"| app cut +{APP['cut']:.2f}, pick speed {APP['speed']:.2f}x", flush=True)
    if "--still" in args:
        for ts in args[args.index("--still") + 1].split(","):
            im = R.frame(SHORT, scenes, int(float(ts) * R.FPS))
            im.save(out / f"still_{float(ts):05.2f}.jpg", quality=92)
            feed(im).save(out / f"still_{float(ts):05.2f}_4x5.jpg", quality=92)
        return
    audio = work / "mix.wav"
    R.soundtrack(SHORT, scenes, total, audio)
    story, square = encoder(R.H, work / "9x16.mp4"), encoder(1350, work / "4x5.mp4")
    for n in range(nframes):
        im = R.frame(SHORT, scenes, n)
        story.stdin.write(im.tobytes())
        square.stdin.write(feed(im).tobytes())
        if n == int(0.9 * R.FPS):
            im.save(out / f"{ID}-cover-9x16.png")
            feed(im).save(out / f"{ID}-cover-4x5.png")
        if n % 60 == 0:
            print(f"frame {n}/{nframes}", flush=True)
    for proc in (story, square):
        proc.stdin.close()
        assert proc.wait() == 0, "ffmpeg failed"
    mux(work / "9x16.mp4", audio, out / f"{ID}-9x16.mp4")
    mux(work / "4x5.mp4", audio, out / f"{ID}-4x5.mp4")
    (out / f"{ID}-copy.txt").write_text("\n\n".join(f"{k}:\n{v}" for k, v in COPY.items()) + "\n")
    print(f"wrote {out} ({total:.2f}s, {nframes} frames)")


if __name__ == "__main__":
    main()
