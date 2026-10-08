#!/usr/bin/env python3
"""Capture raw Google Play screenshots from the debug build on an emulator.

Drives the real app with its debug launch extras and UI Automator, with the
system status bar in demo mode (09:41, full signal, no notifications), and
writes 1080-wide raw captures to android/play-assets/raw/. Composite them with
scripts/play_screenshot_compositor.py.

Usage: ANDROID_SERIAL=emulator-5586 python3 scripts/android_capture_screenshots.py
Requires a booted emulator with the debug APK installed.
"""

from __future__ import annotations

import os
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from io import BytesIO
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = Path(os.environ.get("MAHJ_CAPTURE_OUTPUT", ROOT / "android" / "play-assets" / "raw"))
APPEARANCE = os.environ.get("MAHJ_CAPTURE_APPEARANCE", "light")
SDK = Path(os.environ.get("ANDROID_HOME", Path.home() / "Library/Android/sdk"))
SERIAL = os.environ.get("ANDROID_SERIAL", "")
ADB = [str(SDK / "platform-tools/adb"), "-s", SERIAL]
PACKAGE = "com.jackwallner.mahj"


def adb(*args: str) -> bytes:
    return subprocess.run(ADB + list(args), capture_output=True, check=True, timeout=30).stdout


def demo_mode(on: bool) -> None:
    def demo(command: str, *extras: str) -> None:
        adb("shell", "am", "broadcast", "-a", "com.android.systemui.demo", "-e", "command", command, *extras)

    if not on:
        demo("exit")
        return
    adb("shell", "settings", "put", "global", "sysui_demo_allowed", "1")
    demo("enter")
    demo("clock", "-e", "hhmm", "0941")
    demo("battery", "-e", "level", "100", "-e", "plugged", "false")
    demo("network", "-e", "wifi", "show", "-e", "level", "4", "-e", "fully", "true")
    demo("network", "-e", "mobile", "hide")
    demo("notifications", "-e", "visible", "false")


def nodes() -> list:
    adb("shell", "uiautomator", "dump", "/sdcard/mahj-ui.xml")
    root = ET.fromstring(adb("exec-out", "cat", "/sdcard/mahj-ui.xml"))
    return list(root.iter("node"))


def find(key: str):
    for node in nodes():
        rid = node.get("resource-id", "")
        if rid == key or rid.endswith("/" + key) or node.get("text") == key or node.get("content-desc") == key:
            return node
    return None


def tap(key: str, settle: float = 1.0) -> None:
    for _ in range(8):
        node = find(key)
        if node is not None:
            x1, y1, x2, y2 = map(int, re.findall(r"\d+", node.get("bounds")))
            adb("shell", "input", "tap", str((x1 + x2) // 2), str((y1 + y2) // 2))
            time.sleep(settle)
            return
        time.sleep(0.75)
    raise SystemExit(f"Could not find {key!r} on screen")


def launch(**extras: object) -> None:
    args = ["shell", "am", "start", "-S", "-n", f"{PACKAGE}/.MainActivity", "--ez", "uiTest", "true"]
    for key, value in extras.items():
        if isinstance(value, bool):
            args += ["--ez", key, "true" if value else "false"]
        else:
            args += ["--es", key, str(value)]
    adb(*args)
    time.sleep(3)


def shot(name: str) -> None:
    image = adb("exec-out", "screencap", "-p")
    if not image.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError(f"Screenshot {name!r} did not return a PNG")
    with Image.open(BytesIO(image)) as screenshot:
        if screenshot.size != (1080, 2424):
            raise ValueError(f"Screenshot {name!r} is {screenshot.size}, expected 1080x2424")
        screenshot.verify()
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / f"{name}.png").write_bytes(image)
    print("captured", name)


def home(**extras: object) -> None:
    launch(resetAll=True, onboarded=True, appearance=APPEARANCE, **extras)


def main() -> None:
    if not re.fullmatch(r"emulator-\d+", SERIAL):
        raise ValueError("Set ANDROID_SERIAL to the intended headless emulator")
    if APPEARANCE not in {"light", "dark"}:
        raise ValueError("MAHJ_CAPTURE_APPEARANCE must be light or dark")
    if os.environ.get("MAHJ_CAPTURE_FRESH_INSTALL") == "1":
        package = adb("shell", "dumpsys", "package", PACKAGE).decode()
        if "DEBUGGABLE" not in package:
            raise ValueError("Fresh-install captures require the local debug APK")
        # A second capture pass otherwise uses up today's one free hand.
        # Reset only this debug app, never the AVD or a Play-installed release.
        adb("shell", "pm", "clear", PACKAGE)
    demo_mode(True)
    try:
        home()
        tap("get-started", 2)
        shot("01-quicksession")

        home()
        tap("tile-hand-play")
        tap("target-evens2468")
        tap("play-it-out", 1.5)
        tap("rack-tile-0", 1.5)
        shot("02-playahand")

        home()
        tap("room-card-room")
        tap("drill-hand-match", 2)
        shot("03-handmatch")

        home()
        tap("room-table-room")
        tap("drill-judgment-cards", 2)
        shot("04-keepthrow")

        home()
        tap("room-charleston-room")
        tap("drill-charleston-pass", 1.5)
        for index in (6, 9, 10):
            tap(f"rack-tile-{index}", 0.4)
        time.sleep(0.6)
        shot("05-charleston")

        home(seedProgress=True)
        time.sleep(1)
        shot("06-home")

        home()
        tap("Reference and glossary", 1.5)
        shot("07-reference")

        home()
        tap("room-tile-room")
        tap("drill-meet-tiles", 2)
        shot("08-tileroom")
    finally:
        demo_mode(False)


if __name__ == "__main__":
    main()
