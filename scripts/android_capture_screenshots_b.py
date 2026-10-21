#!/usr/bin/env python3
"""Capture raw screens for the variant B Play screenshot experiment.

Same driver as scripts/android_capture_screenshots.py (debug launch extras,
UI Automator, status bar demo mode), but in the experiment's story order and
with seed progress plus the debug-only Mahj+ unlock, so no screen shows a
lock or an empty state. Writes android/play-assets/experiment-b/raw/; composite
with scripts/play_screenshot_compositor_b.py.

Usage: ANDROID_SERIAL=emulator-5594 python3 scripts/android_capture_screenshots_b.py
"""

from __future__ import annotations

import time

import android_capture_screenshots as cap

OUT = cap.ROOT / "android" / "play-assets" / "experiment-b" / "raw"


def shot(name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / f"{name}.png").write_bytes(cap.adb("exec-out", "screencap", "-p"))
    print("captured", name)


def home() -> None:
    cap.launch(resetAll=True, onboarded=True, appearance="light", seedProgress=True, forcePro=True)
    wait_for("get-started")


def wait_for(key: str, tries: int = 30) -> None:
    """The splash can outlast cap.launch's fixed sleep on a loaded emulator."""
    for _ in range(tries):
        try:
            if cap.find(key) is not None:
                time.sleep(1.5)
                return
        except Exception:  # a dump taken mid-transition can be empty
            pass
        time.sleep(1)
    raise SystemExit(f"{key!r} never appeared")


def tap(key: str, settle: float = 2.0) -> None:
    wait_for(key)
    cap.tap(key, settle)


def answer_minute() -> None:
    """Answer the five questions with the first choice, then close the result."""
    for _ in range(12):
        if cap.find("minute-done") is not None:
            break
        if cap.find("next") is not None:
            cap.tap("next", 2.5)
        elif cap.find("choice-0") is not None:
            cap.tap("choice-0", 2)
        else:
            time.sleep(1)
    tap("minute-done", 3)


def play_week() -> None:
    """Today's minute plus two archive days, so the week row shows real progress."""
    tap("Start Today's Challenge", 3)
    answer_minute()
    for _ in range(2):
        tap("Play", 3)
        answer_minute()


def main() -> None:
    cap.adb("shell", "wm", "size", "reset")  # some AVDs boot with a shorter override size
    cap.adb("shell", "svc", "power", "stayon", "true")
    cap.demo_mode(True)
    try:
        home()
        shot("01-home")

        home()
        tap("tile-hand-play", 2)
        tap("target-evens2468", 3)
        shot("02-coach")

        home()
        tap("room-card-room", 2)
        tap("drill-hand-match", 3)
        tap("2468 (Evens)", 3)
        shot("03-card")

        home()
        tap("room-charleston-room", 2)
        tap("drill-charleston-pass", 3)
        for index in (0, 8, 10):  # the coach's own pass for this seeded deal
            tap(f"rack-tile-{index}", 1.0)
        time.sleep(1.5)
        tap("Pass These 3", 3)
        shot("04-charleston")

        home()
        tap("tile-minute", 4)
        play_week()
        cap.demo_mode(True)  # re-assert after the long minute run
        time.sleep(1.5)
        shot("05-minute")

        home()
        tap("Reference and glossary", 3)
        shot("06-reference")
    finally:
        cap.demo_mode(False)


if __name__ == "__main__":
    main()
