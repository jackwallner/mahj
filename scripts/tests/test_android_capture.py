from __future__ import annotations

import importlib.util
import os
import subprocess
import tempfile
import unittest
from io import BytesIO
from pathlib import Path
from unittest.mock import patch

from PIL import Image

SCRIPT = Path(__file__).resolve().parents[1] / "android_capture_screenshots.py"


def load_capture():
    spec = importlib.util.spec_from_file_location("mahj_android_capture", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def png(size: tuple[int, int]) -> bytes:
    buffer = BytesIO()
    Image.new("RGB", size, "white").save(buffer, "PNG")
    return buffer.getvalue()


class AndroidCaptureTests(unittest.TestCase):
    def setUp(self) -> None:
        with patch.dict(os.environ, {"ANDROID_SERIAL": "emulator-5586"}):
            self.capture = load_capture()

    def test_requires_an_explicit_emulator(self) -> None:
        for serial in ["", "physical-device", "emulator"]:
            self.capture.SERIAL = serial
            with self.subTest(serial=serial), patch.object(self.capture, "adb") as adb:
                with self.assertRaisesRegex(ValueError, "intended headless emulator"):
                    self.capture.main()
                adb.assert_not_called()

    def test_rejects_an_unknown_appearance(self) -> None:
        self.capture.APPEARANCE = "sepia"
        with patch.object(self.capture, "adb") as adb:
            with self.assertRaisesRegex(ValueError, "must be light or dark"):
                self.capture.main()
            adb.assert_not_called()

    def test_adb_failure_is_not_silently_accepted(self) -> None:
        error = subprocess.CalledProcessError(1, ["adb", "screencap"])
        with patch.object(self.capture.subprocess, "run", side_effect=error):
            with self.assertRaises(subprocess.CalledProcessError):
                self.capture.adb("exec-out", "screencap", "-p")

    def test_dark_home_launch_preserves_appearance(self) -> None:
        self.capture.APPEARANCE = "dark"
        with patch.object(self.capture, "launch") as launch:
            self.capture.home(seedProgress=True)
            launch.assert_called_once_with(resetAll=True, onboarded=True, appearance="dark", seedProgress=True)

    def test_non_png_capture_is_not_saved(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            self.capture.OUT = Path(directory)
            with patch.object(self.capture, "adb", return_value=b"error: device offline"):
                with self.assertRaisesRegex(ValueError, "did not return a PNG"):
                    self.capture.shot("offline")
            self.assertEqual(list(Path(directory).iterdir()), [])

    def test_wrong_capture_dimensions_are_not_saved(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            self.capture.OUT = Path(directory)
            with patch.object(self.capture, "adb", return_value=png((720, 1280))):
                with self.assertRaisesRegex(ValueError, "expected 1080x2424"):
                    self.capture.shot("wrong-size")
            self.assertEqual(list(Path(directory).iterdir()), [])

    def test_valid_capture_is_saved(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            self.capture.OUT = Path(directory)
            image = png((1080, 2424))
            with patch.object(self.capture, "adb", return_value=image):
                self.capture.shot("valid")
            self.assertEqual((Path(directory) / "valid.png").read_bytes(), image)

    def test_fresh_capture_refuses_to_clear_a_release_app(self) -> None:
        with patch.dict(os.environ, {"MAHJ_CAPTURE_FRESH_INSTALL": "1"}):
            with patch.object(self.capture, "adb", return_value=b"pkgFlags=[HAS_CODE]") as adb:
                with self.assertRaisesRegex(ValueError, "require the local debug APK"):
                    self.capture.main()
                adb.assert_called_once_with("shell", "dumpsys", "package", self.capture.PACKAGE)


if __name__ == "__main__":
    unittest.main()
