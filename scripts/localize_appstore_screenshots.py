#!/usr/bin/env python3
"""Render translated App Store screenshot captions from approved captures."""

from __future__ import annotations

import argparse
import copy
import json
import shutil
import subprocess
import sys
import tempfile
import re
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SCREENSHOT_ROOT = ROOT / "fastlane" / "screenshots"
EN_US = SCREENSHOT_ROOT / "en-US"

SHARED_ROOT = Path.home() / "ios" / "appstore-screenshots"
MANIFEST_PATH = SHARED_ROOT / "configs" / "ppo-2026-10" / "mahj-v2.json"
SHOTFLOW = SHARED_ROOT / "bin" / "shotflow"

sys.path.insert(0, str(SHARED_ROOT))
from lib import render as shared_render  # noqa: E402
from lib.render import (  # noqa: E402
    draw_header,
    gradient,
    paste_rounded,
    shadowed_round_rect,
)

PHONE_SIZE = (1320, 2868)
IPAD_SIZE = (2064, 2752)
DUO_SIZE = (1398, 2034)

PHONE_FILES = (
    "01_pass_with_a_plan.png",
    "02_read_your_rack.png",
    "03_know_what_to_keep.png",
    "04_get_coached_on_every_discard.png",
    "05_choose_the_room_you_need.png",
    "06_learn_every_tile_family.png",
    "07_recognize_the_tile_you_need.png",
    "08_see_the_pattern_your_rack_is_chasing.png",
)

DUO_FILES = tuple(f"duo_{name}" for name in PHONE_FILES)
IPAD_FILES = tuple(f"ipad_{name}" for name in PHONE_FILES)

IPAD_SOURCE_ORDER = (
    "ipad_05_charleston.png",
    "ipad_03_hand_match.png",
    "ipad_04_keep_or_throw.png",
    "ipad_02_play_a_hand.png",
    "ipad_06_home.png",
    "ipad_08_tile_room.png",
    "ipad_01_quick_session.png",
    "ipad_07_reference.png",
)

PHONE_LAYOUT = {
    "header_top": 96,
    "header_size": 156,
    "header_min_size": 140,
    "header_max_lines": 2,
    "header_margin": 48,
    "header_bottom_padding": 34,
    "phone_top": 570,
    "bottom_margin": 38,
    "phone_width": 1140,
}

DUO_HEADER_LAYOUT = {
    "header_top": 96,
    "header_size": 156,
    "header_min_size": 140,
    "header_max_lines": 2,
    "header_margin": 48,
    "header_bottom_padding": 34,
}

IPAD_HEADER_LAYOUT = {
    "header_top": 96,
    "header_size": 200,
    "header_min_size": 180,
    "header_max_lines": 2,
    "header_margin": 82,
    "header_max_width": 1900,
    "header_bottom_padding": 40,
}

DUO_COPY_CUTOFF = 450
IPAD_CARD_TOP = 630
IPAD_BOTTOM_MARGIN = 48
IPAD_CARD_RADIUS = 30

# --recapture mode: raw captures made in each language, headers from JSON.
RAW_ROOT = ROOT / "build" / "l10n-raw"
HEADERS_PATH = ROOT / "scripts" / "screenshot_headers.json"
ARABIC_TOOL_SRC = ROOT / "scripts" / "arabic_header.swift"
ARABIC_FONT = "AlNile-Bold"
RTL_LOCALES = ("ar-SA",)

# New York at its default optical size (256) draws hairlines under a pixel wide:
# the crossbar of "H" disappears (Vietnamese "Học" read "I Iọc"). Size 200 looks
# the same and keeps every stroke.
SERIF_STYLE = "mahj-serif"
shared_render.FONT_STYLES[SERIF_STYLE] = (shared_render.FONT_PATHS["serif"], {"Optical Size": 200})

# Raw capture behind each frame, in store order. Phone frames use the answered
# states the English set shows (Pick Your Pass submitted, Read the Rack and Quick
# Session answered); iPad frames use the dealt state, as the English iPad set does.
PHONE_RAW_ORDER = (
    "05_charleston_answered.png",
    "03_hand_match_answered.png",
    "04_keep_or_throw.png",
    "02_play_a_hand.png",
    "06_home.png",
    "08_tile_room.png",
    "01_quick_session_answered.png",
    "07_reference.png",
)
IPAD_RAW_ORDER = tuple(f"ipad_{name}" for name in (
    "05_charleston.png",
    "03_hand_match.png",
    "04_keep_or_throw.png",
    "02_play_a_hand.png",
    "06_home.png",
    "08_tile_room.png",
    "01_quick_session.png",
    "07_reference.png",
))
PHONE_RAW_SIZE = (1206, 2622)

TRANSLATIONS: dict[str, tuple[str, ...]] = {
    "es-MX": (
        "Pasa con un plan",
        "Lee tu rack antes de elegir",
        "Sabe qué fichas conservar",
        "Te guía en cada descarte",
        "Elige la sala que necesitas",
        "Aprende todas las familias de fichas",
        "Reconoce la ficha que necesitas",
        "Ve el patrón que busca tu rack",
    ),
    "vi": (
        "Trao quân có kế hoạch",
        "Đọc khay bài rồi hãy chọn",
        "Biết nên giữ quân nào",
        "Được hướng dẫn mỗi lần bỏ quân",
        "Chọn phòng luyện tập phù hợp",
        "Làm quen với mọi họ bài",
        "Nhận ra quân bài bạn cần",
        "Nhìn ra mẫu bài hợp với khay bài",
    ),
    "id": (
        "Oper ubin dengan rencana",
        "Baca rak sebelum memilih",
        "Tahu ubin mana yang perlu disimpan",
        "Dibimbing setiap kali membuang ubin",
        "Pilih ruang latihan yang kamu butuhkan",
        "Kenali setiap keluarga ubin",
        "Kenali ubin yang kamu butuhkan",
        "Lihat pola yang dikejar rakmu",
    ),
}


def absolute_from_manifest(path: str) -> str:
    return str((MANIFEST_PATH.parent / path).resolve())


def localized_manifest(headers: tuple[str, ...], sources: tuple[Path, ...] = ()) -> dict[str, Any]:
    manifest = json.loads(MANIFEST_PATH.read_text())
    manifest["capture_report"] = absolute_from_manifest(manifest["capture_report"])

    for proof in manifest.get("market", {}).get("proof_points", []):
        if proof.get("source"):
            proof["source"] = absolute_from_manifest(proof["source"])

    for frame, header in zip(manifest["sets"][0]["frames"], headers):
        frame["header"] = header
        frame["story_focus"] = header
        frame["layout"].update(PHONE_LAYOUT)
        for key in ("source", "source_evidence"):
            if frame.get(key):
                frame[key] = absolute_from_manifest(frame[key])

    for frame, source in zip(manifest["sets"][0]["frames"], sources):
        frame["source"] = frame["source_evidence"] = str(source.resolve())

    return manifest


def render_phone(
    locale: str,
    headers: tuple[str, ...],
    output: Path,
    sources: tuple[Path, ...] = (),
    theme: dict[str, Any] | None = None,
) -> int:
    rtl = locale in RTL_LOCALES
    # With sources given (recapture mode) shotflow draws a stand-in header and
    # overlay_headers replaces it: Pillow cannot shape Arabic, and the shared
    # serif drops the crossbar of "H".
    recapture = bool(sources)
    manifest = localized_manifest(tuple("Pass" for _ in headers) if recapture else headers, sources)
    output.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="mahj-shotflow-") as temp_name:
        temp = Path(temp_name)
        manifest_path = temp / f"{locale}.json"
        render_root = temp / "rendered"
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2))

        result = subprocess.run(
            [str(SHOTFLOW), "all", str(manifest_path), "--output", str(render_root)],
            capture_output=True,
            text=True,
        )
        if result.returncode:
            raise RuntimeError(f"phone render failed for {locale}:\n{result.stdout[-2000:]}")

        set_id = manifest["sets"][0]["id"]
        rendered = render_root / set_id
        audit = json.loads((render_root / "audit.json").read_text())
        if audit.get("status") != "pass" or audit.get("errors"):
            raise RuntimeError(f"phone audit failed for {locale}: {audit.get('errors')}")

        for frame, filename in zip(manifest["sets"][0]["frames"], PHONE_FILES):
            source = rendered / frame["filename"]
            validate_png(source, PHONE_SIZE)
            shutil.copyfile(source, output / filename)

        if recapture:
            overlay_headers(
                output, PHONE_FILES, headers, theme, PHONE_SIZE, PHONE_LAYOUT, PHONE_LAYOUT["phone_top"] - 20, rtl
            )

        return len(audit.get("warnings", []))


def arabic_tool() -> Path:
    binary = Path(tempfile.gettempdir()) / "mahj-arabic-header"
    if not binary.exists() or binary.stat().st_mtime < ARABIC_TOOL_SRC.stat().st_mtime:
        subprocess.run(["swiftc", "-O", str(ARABIC_TOOL_SRC), "-o", str(binary)], check=True)
    return binary


def arabic_headers(
    headers: tuple[str, ...], theme: dict[str, Any], size: tuple[int, int], layout: dict[str, Any], out_dir: Path
) -> list[tuple[Image.Image, dict[str, Any]]]:
    """Shape and draw each Arabic header on a transparent canvas with CoreText."""
    ink = tuple(int(theme["ink"].lstrip("#")[i : i + 2], 16) for i in (0, 2, 4))
    jobs = [
        {
            "text": header,
            "font": ARABIC_FONT,
            "out": str(out_dir / f"ar_header_{index}.png"),
            "canvasWidth": size[0],
            "canvasHeight": 700,
            "top": layout["header_top"] + 14,
            "maxWidth": layout.get("header_max_width", size[0] - 2 * layout["header_margin"]),
            "size": layout["header_size"],
            "minSize": 110,
            "maxLines": 2,
            "lineGap": 1.2,
            "color": list(ink),
        }
        for index, header in enumerate(headers)
    ]
    result = subprocess.run([str(arabic_tool())], input=json.dumps(jobs), capture_output=True, text=True, check=True)
    return [(Image.open(job["out"]).convert("RGBA"), info) for job, info in zip(jobs, json.loads(result.stdout))]


def overlay_headers(
    folder: Path,
    files: tuple[str, ...],
    headers: tuple[str, ...],
    theme: dict[str, Any],
    size: tuple[int, int],
    layout: dict[str, Any],
    clear_to: int,
    rtl: bool,
) -> None:
    """Replace the top of finished phone frames with the real header."""
    latin_theme = {**theme, "headline_font": SERIF_STYLE}
    background = gradient(size, theme["background"], theme["background_2"])
    frames = json.loads(MANIFEST_PATH.read_text())["sets"][0]["frames"]
    with tempfile.TemporaryDirectory(prefix="mahj-arabic-") as temp:
        shaped = arabic_headers(headers, theme, size, layout, Path(temp)) if rtl else []
        for index, (filename, header) in enumerate(zip(files, headers)):
            canvas = background.convert("RGBA")
            if rtl:
                text, info = shaped[index]
                canvas.alpha_composite(text.crop((0, 0, size[0], size[1])))
                lines, bottom = info["lines"], info["bounds"][3]
            else:
                frame = copy.deepcopy(frames[index])
                frame["header"] = header
                frame["layout"].update(layout)
                _, evidence = draw_header(canvas, frame, latin_theme, False)
                lines, bottom = evidence["header_lines"], evidence["header_bounds"][3]
            if lines > 2 or bottom > clear_to - 20:
                raise ValueError(f"header does not fit in {filename}: {header!r} lines={lines} bottom={bottom}")
            image = Image.open(folder / filename).convert("RGB")
            image.paste(canvas.crop((0, 0, size[0], clear_to)).convert("RGB"), (0, 0))
            image.save(folder / filename)
            validate_png(folder / filename, size)


def render_duo(locale: str, headers: tuple[str, ...], output: Path, theme: dict[str, Any]) -> None:
    output.mkdir(parents=True, exist_ok=True)

    for index, (header, filename) in enumerate(zip(headers, DUO_FILES)):
        source_path = EN_US / filename
        source = Image.open(source_path).convert("RGB")
        require_size(source_path, source.size, DUO_SIZE)

        canvas = gradient(DUO_SIZE, theme["background"], theme["background_2"]).convert("RGBA")
        frame = copy.deepcopy(json.loads(MANIFEST_PATH.read_text())["sets"][0]["frames"][index])
        frame["header"] = header
        frame["story_focus"] = header
        frame["layout"].update(DUO_HEADER_LAYOUT)
        _, evidence = draw_header(canvas, frame, theme, False)
        if evidence["header_lines"] > 2 or evidence["header_bounds"][3] >= DUO_COPY_CUTOFF:
            raise ValueError(f"Duo header does not fit for {locale} frame {index + 1}: {evidence}")

        canvas.paste(source.crop((0, DUO_COPY_CUTOFF, *source.size)), (0, DUO_COPY_CUTOFF))
        image = canvas.convert("RGB")
        path = output / filename
        image.save(path)
        validate_png(path, DUO_SIZE)


def render_ipad(
    locale: str,
    headers: tuple[str, ...],
    output: Path,
    theme: dict[str, Any],
    source_dir: Path = EN_US,
    source_order: tuple[str, ...] = IPAD_SOURCE_ORDER,
) -> None:
    output.mkdir(parents=True, exist_ok=True)
    rtl = locale in RTL_LOCALES
    if source_dir != EN_US:
        theme = {**theme, "headline_font": SERIF_STYLE}
    shaped: list[tuple[Image.Image, dict[str, Any]]] = []
    temp_dir = tempfile.TemporaryDirectory(prefix="mahj-arabic-")
    if rtl:
        shaped = arabic_headers(headers, theme, IPAD_SIZE, IPAD_HEADER_LAYOUT, Path(temp_dir.name))
    card_height = IPAD_SIZE[1] - IPAD_CARD_TOP - IPAD_BOTTOM_MARGIN
    card_width = round(card_height * IPAD_SIZE[0] / IPAD_SIZE[1])
    x = (IPAD_SIZE[0] - card_width) // 2

    for index, (header, source_name, filename) in enumerate(zip(headers, source_order, IPAD_FILES)):
        source_path = source_dir / source_name
        source = Image.open(source_path).convert("RGB")
        require_size(source_path, source.size, IPAD_SIZE)

        canvas = gradient(IPAD_SIZE, theme["background"], theme["background_2"]).convert("RGBA")
        frame = copy.deepcopy(json.loads(MANIFEST_PATH.read_text())["sets"][0]["frames"][index])
        frame["header"] = header
        frame["story_focus"] = header
        frame["layout"].update(IPAD_HEADER_LAYOUT)
        if rtl:
            text, info = shaped[index]
            canvas.alpha_composite(text.crop((0, 0, IPAD_SIZE[0], IPAD_SIZE[1])).convert("RGBA"))
            evidence = {"header_lines": info["lines"], "header_bounds": info["bounds"]}
        else:
            _, evidence = draw_header(canvas, frame, theme, False)
        if evidence["header_lines"] > 2 or evidence["header_bounds"][3] > IPAD_CARD_TOP - 44:
            raise ValueError(f"iPad header does not fit for {locale} frame {index + 1}: {evidence}")

        card_box = (
            x - 4,
            IPAD_CARD_TOP - 4,
            x + card_width + 4,
            IPAD_CARD_TOP + card_height + 4,
        )
        shadowed_round_rect(
            canvas,
            card_box,
            IPAD_CARD_RADIUS + 4,
            (246, 241, 230, 255),
            shadow=(0, 15, 28, 46),
            blur=28,
        )
        screen = source.resize((card_width, card_height), Image.Resampling.LANCZOS)
        paste_rounded(canvas, screen, (x, IPAD_CARD_TOP), IPAD_CARD_RADIUS)
        ImageDraw.Draw(canvas).rounded_rectangle(
            (x, IPAD_CARD_TOP, x + card_width - 1, IPAD_CARD_TOP + card_height - 1),
            IPAD_CARD_RADIUS,
            outline=(219, 209, 191, 210),
            width=2,
        )

        path = output / filename
        canvas.convert("RGB").save(path)
        validate_png(path, IPAD_SIZE)


def require_size(path: Path, actual: tuple[int, int], expected: tuple[int, int]) -> None:
    if actual != expected:
        raise ValueError(f"{path} is {actual}, expected {expected}")


def validate_png(path: Path, size: tuple[int, int]) -> None:
    image = Image.open(path)
    require_size(path, image.size, size)
    if image.mode != "RGB":
        raise ValueError(f"{path} is {image.mode}, expected opaque RGB")


def render_locale(locale: str, output_root: Path) -> None:
    headers = TRANSLATIONS[locale]
    manifest = json.loads(MANIFEST_PATH.read_text())
    theme = manifest["theme"]
    output = output_root / locale

    warning_count = render_phone(locale, headers, output)
    render_ipad(locale, headers, output, theme)
    render_duo(locale, headers, output, theme)
    print(f"{locale}: wrote 24 RGB images; phone audit OCR warnings={warning_count}")


def load_recapture_headers(path: Path) -> dict[str, tuple[str, ...]]:
    """Read {"<locale>": {"01": {"text": ...}}} and enforce the header contract."""
    data = json.loads(path.read_text())
    headers: dict[str, tuple[str, ...]] = {}
    for locale, frames in data.items():
        texts = tuple(frames[f"{index:02d}"]["text"].strip() for index in range(1, 9))
        for text in texts:
            if re.search(r"[.\u3002\u06d4\u2014\u2013\n]", text):
                raise ValueError(f"{locale}: header breaks the contract (period, dash or newline): {text!r}")
        headers[locale] = texts
    return headers


def render_recaptured(locale: str, headers: tuple[str, ...], raw_root: Path, output_root: Path) -> None:
    """Phone and iPad frames from captures made in the locale's own language."""
    theme = json.loads(MANIFEST_PATH.read_text())["theme"]
    output = output_root / locale
    phone_sources = tuple(raw_root / locale / "phone" / name for name in PHONE_RAW_ORDER)
    for source in phone_sources:
        if not source.exists():
            raise FileNotFoundError(source)
        require_size(source, Image.open(source).size, PHONE_RAW_SIZE)
    warning_count = render_phone(locale, headers, output, phone_sources, theme)
    render_ipad(locale, headers, output, theme, raw_root / locale / "ipad", IPAD_RAW_ORDER)
    print(f"{locale}: wrote 16 RGB images from {raw_root / locale}; phone audit OCR warnings={warning_count}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--recapture",
        action="store_true",
        help="Compose from per-locale raw captures (scripts/capture-localized-screenshots.sh) "
        "and headers from --headers, instead of translating over the English app.",
    )
    parser.add_argument("--headers", type=Path, default=HEADERS_PATH, help="Header JSON for --recapture.")
    parser.add_argument("--raw-root", type=Path, default=RAW_ROOT, help="Raw capture root for --recapture.")
    parser.add_argument(
        "--locale",
        nargs="+",
        default=None,
        help="Locales to render. Defaults to every localized screenshot set.",
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        default=SCREENSHOT_ROOT,
        help="Destination directory containing locale subfolders.",
    )
    args = parser.parse_args()

    if args.recapture:
        headers = load_recapture_headers(args.headers)
        for locale in args.locale or list(headers):
            render_recaptured(locale, headers[locale], args.raw_root, args.output_root)
        return

    for locale in args.locale or list(TRANSLATIONS):
        if locale not in TRANSLATIONS:
            parser.error(f"unknown locale {locale}; choices: {', '.join(TRANSLATIONS)}")
        render_locale(locale, args.output_root)


if __name__ == "__main__":
    main()
