#!/usr/bin/env python3
"""Write the app's translations of every string the screenshot test looks up.

Usage: scripts/dump_screenshot_strings.py <language> <out.json>

ScreenshotTests finds controls by English key; this maps each key to the
translations in Localizable.xcstrings and Content.xcstrings (a screen title can
live in either). The language is the catalog code (ar, de, es, fr, id, vi).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

RESOURCES = Path(__file__).resolve().parent.parent / "MahjTrainer" / "Resources"

KEYS = (
    "Get Started", "Play a Hand", "Play it out", "The Card Room", "Read the Rack",
    "The Table Room", "Keep or Throw", "The Charleston Room", "Pick Your Pass",
    "The Tile Room", "2468 (Evens)", "Reference and glossary", "Sections",
    "THE ROOMS", "Settings", "Back", "Next", "Next Rack", "Finish", "Close",
    "Done", "Pass These 3",
)


def main() -> None:
    language, out = sys.argv[1], Path(sys.argv[2])
    catalogs = [
        json.loads((RESOURCES / f"{name}.xcstrings").read_text())["strings"]
        for name in ("Content", "Localizable")
    ]
    table: dict[str, list[str]] = {}
    for key in KEYS:
        found: list[str] = []
        for catalog in catalogs:
            unit = catalog.get(key, {}).get("localizations", {}).get(language, {}).get("stringUnit", {})
            value = unit.get("value")
            if value and value not in found:
                found.append(value)
        if not found:
            raise SystemExit(f"no {language} translation for {key!r}")
        table[key] = found
    out.write_text(json.dumps(table, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
