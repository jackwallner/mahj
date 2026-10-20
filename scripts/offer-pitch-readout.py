#!/usr/bin/env python3
"""Read the trial sheet pitch test (`offer_pitch`) from RevenueCat.

Every player who saw the one-tap trial sheet carries an `offer_pitch`
attribute (the arm they saw). For each arm this prints sheet viewers,
trials started on the sheet (`converted_surface` starting with `offer_`), and
the chance that arm beats the other (Beta(1,1) posterior, Monte Carlo), the
same "chance to win" reading the trial button test uses.

Usage: python3 scripts/offer-pitch-readout.py [--min-version 1.4.2] [--days 60]
(key read from ~/.mahj_credentials, never printed)
"""

from __future__ import annotations

import argparse
import json
import random
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

PROJECT = "proj28030dc2"
BASE = "https://api.revenuecat.com/v2"


def secret_key() -> str:
    for line in (Path.home() / ".mahj_credentials").read_text().splitlines():
        if line.startswith("RC_SECRET_KEY"):
            return line.split("=", 1)[1].strip().strip('"').strip("'")
    sys.exit("RC_SECRET_KEY not found in ~/.mahj_credentials")


KEY = secret_key()


def get(path: str) -> dict:
    url = path if path.startswith("http") else BASE + path
    for attempt in range(5):
        req = urllib.request.Request(url, headers={"Authorization": f"Bearer {KEY}"})
        try:
            with urllib.request.urlopen(req) as resp:
                return json.loads(resp.read())
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < 4:
                time.sleep(int(e.headers.get("Retry-After") or 10))
                continue
            raise RuntimeError(f"GET {path} -> {e.code}: {e.read().decode()[:300]}")
    raise RuntimeError(f"GET {path}: rate limited")


def version(text: str | None) -> tuple[int, ...]:
    try:
        return tuple(int(part) for part in (text or "").split("."))
    except ValueError:
        return ()


def customers(min_version: tuple[int, ...], since: datetime):
    path: str | None = f"/projects/{PROJECT}/customers?limit=1000"
    while path:
        page = get(path)
        for item in page["items"]:
            seen = datetime.fromtimestamp(item.get("last_seen_at", 0) / 1000, timezone.utc)
            if seen >= since and version(item.get("last_seen_app_version")) >= min_version:
                yield item["id"]
        path = page.get("next_page")


def attributes(customer: str) -> dict[str, str]:
    quoted = urllib.parse.quote(customer, safe="")
    page = get(f"/projects/{PROJECT}/customers/{quoted}/attributes?limit=1000")
    return {a["name"]: a.get("value") or "" for a in page["items"]}


def chance_to_win(a: tuple[int, int], b: tuple[int, int], draws: int = 20000) -> float:
    rng = random.Random(7)
    wins = sum(
        rng.betavariate(1 + a[1], 1 + a[0] - a[1]) > rng.betavariate(1 + b[1], 1 + b[0] - b[1])
        for _ in range(draws)
    )
    return wins / draws


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--min-version", default="1.4.2")
    parser.add_argument("--days", type=int, default=60, help="only customers seen in the last N days")
    args = parser.parse_args()
    since = datetime.now(timezone.utc) - timedelta(days=args.days)

    arms: dict[str, list[int]] = {}
    for customer in customers(version(args.min_version), since):
        attrs = attributes(customer)
        arm = attrs.get("offer_pitch")
        if not arm:
            continue
        row = arms.setdefault(arm, [0, 0, 0])
        row[0] += 1
        surface = attrs.get("converted_surface", "")
        if surface.startswith("offer_"):
            row[1] += 1
        elif surface:
            row[2] += 1

    if not arms:
        print("No sheet viewers yet.")
        return
    print(f"{'arm':<10}{'viewers':>9}{'sheet trials':>14}{'rate':>8}{'other trials':>14}")
    for arm, (viewers, sheet, other) in sorted(arms.items()):
        print(f"{arm:<10}{viewers:>9}{sheet:>14}{sheet / viewers:>8.1%}{other:>14}")
    if {"benefits", "timeline"} <= arms.keys():
        t, b = arms["timeline"], arms["benefits"]
        print(f"\nChance timeline beats benefits: {chance_to_win((t[0], t[1]), (b[0], b[1])):.0%}")


if __name__ == "__main__":
    main()
