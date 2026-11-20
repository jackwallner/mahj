#!/usr/bin/env python3
"""Per-locale field budget and keyword overlap check for the localization pass.

Prints the character count of each field against its limit and flags keyword
tokens that repeat a name or subtitle word, repeat another keyword, form a
plural/singular pair, equal "app", or repeat a token already used by en-US or
another locale that the US storefront indexes.
"""

from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from pathlib import Path

LIMITS = {"name": 30, "subtitle": 30, "keywords": 100, "promotional_text": 170, "description": 4000}
US_INDEXED = ["es-MX", "zh-Hans", "zh-Hant", "fr-FR", "pt-BR", "ko", "vi", "ru", "ar-SA"]
CJK = re.compile(r"[぀-ヿ㐀-鿿가-힯]")


def read(root: Path, locale: str, field: str) -> str:
    text = (root / locale / f"{field}.txt").read_text(encoding="utf-8")
    return text[:-1] if text.endswith("\n") else text


def norm(value: str) -> str:
    folded = unicodedata.normalize("NFKD", value.casefold())
    return "".join(c for c in folded if not unicodedata.combining(c))


def words(value: str) -> set[str]:
    return {norm(w) for w in re.findall(r"[^\W_]+", value)}


def singular_pair(a: str, b: str) -> bool:
    return a != b and (a + "s" == b or b + "s" == a or a + "es" == b or b + "es" == a)


def check(root: Path, locale: str) -> list[str]:
    problems: list[str] = []
    fields = {f: read(root, locale, f) for f in LIMITS}
    for field, limit in LIMITS.items():
        value = fields[field]
        flag = "" if len(value) <= limit else "  OVER LIMIT"
        print(f"  {field:16} {len(value):4}/{limit}{flag}")
        if len(value) > limit:
            problems.append(f"{field} over limit")
        if "—" in value:
            problems.append(f"{field} has an em dash")
        if value != value.strip():
            problems.append(f"{field} has edge whitespace")
    kw = fields["keywords"]
    if ", " in kw or kw.startswith(",") or kw.endswith(","):
        problems.append("keywords: bad comma spacing")
    if len(kw) < 95:
        problems.append(f"keywords use {len(kw)} of 100 characters (aim for 95 to 100)")
    visible = norm(fields["name"] + " " + fields["subtitle"])
    visible_words = words(fields["name"] + " " + fields["subtitle"])
    tokens = [t for t in kw.split(",") if t]
    seen: dict[str, str] = {}
    for token in tokens:
        key = norm(token)
        if key == "app":
            problems.append("keyword 'app'")
        if key in seen:
            problems.append(f"duplicate keyword {token}")
        seen[key] = token
        parts = words(token)
        if key in visible_words or (parts and parts <= visible_words):
            problems.append(f"keyword {token} repeats a name/subtitle word")
        elif CJK.search(token) and key in visible:
            problems.append(f"keyword {token} sits inside the name/subtitle text")
    keys = list(seen)
    for i, a in enumerate(keys):
        for b in keys[i + 1:]:
            if singular_pair(a, b):
                problems.append(f"plural/singular pair {a}/{b}")
    return problems


def us_overlap(root: Path, locales: list[str]) -> list[str]:
    """English tokens used in two fields the US storefront indexes add nothing."""
    owner: dict[str, str] = {}
    out: list[str] = []
    pool = [("en-US", w) for w in words(read(root, "en-US", "name") + " " + read(root, "en-US", "subtitle"))]
    pool += [("en-US", norm(t)) for t in read(root, "en-US", "keywords").split(",")]
    for loc, tok in pool:
        owner.setdefault(tok, loc)
    for loc in [l for l in US_INDEXED if l in locales]:
        for token in read(root, loc, "keywords").split(","):
            key = norm(token)
            if not key.isascii() or not key.isalpha() and not key.isalnum():
                continue
            if key in owner and owner[key] != loc:
                out.append(f"{loc}: '{token}' already indexed for the US by {owner[key]}")
            owner.setdefault(key, loc)
    return out


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("locales", nargs="+")
    parser.add_argument("--root", default="fastlane/metadata")
    args = parser.parse_args()
    root = Path(args.root)
    failed = 0
    for locale in args.locales:
        print(locale)
        problems = check(root, locale)
        for p in problems:
            print(f"  PROBLEM {p}")
        failed += bool(problems)
    for line in us_overlap(root, args.locales):
        print(f"  NOTE {line}")
    print("clean" if not failed else f"{failed} locale(s) with problems")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
