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


def localized_manifest(headers: tuple[str, ...]) -> dict[str, Any]:
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

    return manifest


def render_phone(locale: str, headers: tuple[str, ...], output: Path) -> int:
    manifest = localized_manifest(headers)
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

        return len(audit.get("warnings", []))


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


def render_ipad(locale: str, headers: tuple[str, ...], output: Path, theme: dict[str, Any]) -> None:
    output.mkdir(parents=True, exist_ok=True)
    card_height = IPAD_SIZE[1] - IPAD_CARD_TOP - IPAD_BOTTOM_MARGIN
    card_width = round(card_height * IPAD_SIZE[0] / IPAD_SIZE[1])
    x = (IPAD_SIZE[0] - card_width) // 2

    for index, (header, source_name, filename) in enumerate(zip(headers, IPAD_SOURCE_ORDER, IPAD_FILES)):
        source_path = EN_US / source_name
        source = Image.open(source_path).convert("RGB")
        require_size(source_path, source.size, IPAD_SIZE)

        canvas = gradient(IPAD_SIZE, theme["background"], theme["background_2"]).convert("RGBA")
        frame = copy.deepcopy(json.loads(MANIFEST_PATH.read_text())["sets"][0]["frames"][index])
        frame["header"] = header
        frame["story_focus"] = header
        frame["layout"].update(IPAD_HEADER_LAYOUT)
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


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--locale",
        nargs="+",
        choices=tuple(TRANSLATIONS),
        default=list(TRANSLATIONS),
        help="Locales to render. Defaults to every localized screenshot set.",
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        default=SCREENSHOT_ROOT,
        help="Destination directory containing locale subfolders.",
    )
    args = parser.parse_args()

    for locale in args.locale:
        render_locale(locale, args.output_root)


if __name__ == "__main__":
    main()
