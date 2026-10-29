#!/usr/bin/env python3
"""Validate App Store metadata fields for the selected locales."""

import argparse
import re
import sys
import unicodedata
from pathlib import Path


LIMITS = {
    "name": 30,
    "subtitle": 30,
    "keywords": 100,
    "promotional_text": 170,
    "description": 4000,
}


def read_field(locale_dir: Path, field: str) -> str:
    value = (locale_dir / f"{field}.txt").read_text(encoding="utf-8")
    if value.endswith("\n"):
        value = value[:-1]
    return value


def normalize_token(value: str) -> str:
    decomposed = unicodedata.normalize("NFKD", value.casefold())
    return "".join(character for character in decomposed if not unicodedata.combining(character))


def validate_locale(metadata_root: Path, locale: str) -> list[str]:
    locale_dir = metadata_root / locale
    errors: list[str] = []
    fields: dict[str, str] = {}

    for field, limit in LIMITS.items():
        path = locale_dir / f"{field}.txt"
        if not path.is_file():
            errors.append(f"{locale}: missing {field}.txt")
            continue
        value = read_field(locale_dir, field)
        fields[field] = value
        if value != value.strip():
            errors.append(f"{locale}: {field} has leading or trailing whitespace")
        if len(value) > limit:
            errors.append(f"{locale}: {field} is {len(value)} characters, limit {limit}")
        if "\u2014" in value:
            errors.append(f"{locale}: {field} contains an em dash")

    if "keywords" not in fields or "name" not in fields or "subtitle" not in fields:
        return errors

    keywords = fields["keywords"]
    terms = keywords.split(",")
    seen: set[str] = set()
    for term in terms:
        if not term:
            errors.append(f"{locale}: keywords has an empty token")
            continue
        if term != term.strip():
            errors.append(f"{locale}: keywords has whitespace around a token")
        if any(character.isspace() for character in term):
            errors.append(f"{locale}: keyword token {term!r} contains spaces")
        normalized = normalize_token(term)
        if normalized in seen:
            errors.append(f"{locale}: duplicate keyword token {term!r}")
        seen.add(normalized)

    visible_text = normalize_token(f"{fields['name']} {fields['subtitle']}")
    visible_tokens = {
        normalize_token(token)
        for token in re.findall(r"[^\W_]+", f"{fields['name']} {fields['subtitle']}", re.UNICODE)
    }
    for term in terms:
        normalized = normalize_token(term)
        if normalized in visible_tokens or (len(normalized) > 1 and normalized in visible_text):
            errors.append(f"{locale}: keyword {term!r} repeats a name or subtitle token")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("locales", nargs="+", help="fastlane metadata locale codes")
    args = parser.parse_args()

    metadata_root = Path(__file__).resolve().parents[1] / "fastlane" / "metadata"
    errors = [error for locale in args.locales for error in validate_locale(metadata_root, locale)]
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1

    print(f"Validated {len(args.locales)} locales: {', '.join(args.locales)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
