#!/usr/bin/env python3
"""Offline checks for the frozen baseline and unpublished FAQ patch."""

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
RAW_ROOT: Path | None = None
QUESTION = "Is Mahj Trainer the same as Mahjong Trainer: Learn & Win?"


def normalized(text: str) -> str:
    return " ".join(text.split())


class Page(HTMLParser):
    def __init__(self, text: str) -> None:
        super().__init__(convert_charrefs=True)
        self.jsonld: list[dict] = []
        self.scripts: list[str] = []
        self.visible: list[str] = []
        self.buffer: list[str] = []
        self.in_script = False
        self.in_style = False
        self.script_type = ""
        self.feed(text)

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag == "script":
            self.in_script = True
            self.script_type = dict(attrs).get("type") or ""
            self.buffer = []
        if tag == "style":
            self.in_style = True

    def handle_endtag(self, tag: str) -> None:
        if tag == "script":
            text = "".join(self.buffer)
            if self.script_type == "application/ld+json":
                self.jsonld.append(json.loads(text))
            else:
                self.scripts.append(text)
            self.in_script = False
        if tag == "style":
            self.in_style = False

    def handle_data(self, data: str) -> None:
        if self.in_script:
            self.buffer.append(data)
        elif not self.in_style:
            self.visible.append(data)


class ExperimentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.questions = {}
        for line in (HERE / "questions.tsv").read_text().splitlines():
            if line and not line.startswith("#"):
                kind, qid, question = line.split("\t")
                if qid in cls.questions:
                    raise ValueError(f"Duplicate question: {qid}")
                cls.questions[qid] = (kind, question)
        cls.scorecard = json.loads((HERE / "scorecard.json").read_text())
        cls.records = cls.scorecard["records"]
        cls.discovery = [r for r in cls.records if r["valid"] and r["kind"] == "discovery"]
        cls.original = Page((REPO / "docs/index.html").read_text())
        scratch = tempfile.TemporaryDirectory(prefix="mahj-faq-check-")
        cls.addClassCleanup(scratch.cleanup)
        root = Path(scratch.name)
        (root / "docs").mkdir()
        for filename in ("index.html", "index.html.md"):
            shutil.copyfile(REPO / "docs" / filename, root / "docs" / filename)
        subprocess.run(
            ["git", "apply", str(HERE / "candidate.patch")],
            cwd=root, check=True, capture_output=True, text=True,
        )
        cls.candidate = Page((root / "docs/index.html").read_text())
        cls.markdown = (root / "docs/index.html.md").read_text()

    def test_question_split(self) -> None:
        self.assertEqual(Counter(k for k, _ in self.questions.values()), {"discovery": 8, "branded": 4})
        for kind, question in self.questions.values():
            self.assertEqual("Mahj Trainer" in question, kind == "branded")

    def test_capture_inventory(self) -> None:
        self.assertEqual(len(self.records), 51)
        keys = {(r["engine"], r["question_id"]) for r in self.records}
        self.assertEqual(len(keys), 51)
        for record in self.records:
            self.assertEqual(record["kind"], self.questions[record["question_id"]][0])
            self.assertRegex(record["sha256"], r"^[0-9a-f]{64}$")
            self.assertEqual(record["capture"], f"{record['engine']}-{record['question_id']}.md")
        for engine in ("claude", "gemini", "chatgpt", "google"):
            self.assertEqual(sum(r["valid"] for r in self.records if r["engine"] == engine), 12)

    def test_raw_capture_hashes(self) -> None:
        if RAW_ROOT is None:
            self.skipTest("Pass --raw to verify the local capture archive")
        for record in self.records:
            data = (RAW_ROOT / record["capture"]).read_bytes()
            self.assertEqual(hashlib.sha256(data).hexdigest(), record["sha256"], record["capture"])
            expected = self.questions[record["question_id"]][1]
            self.assertEqual(data.decode().splitlines()[0], f"# {expected}")
            if record["valid"] and record["kind"] == "discovery":
                body = re.split(r"\n(?:URLs|Sources):\n", data.decode().partition("\n\n")[2])[0]
                # This checks the manually recorded mention, not recommendation semantics.
                self.assertEqual(bool(re.search(r"\bMahj Trainer\b", body, re.I)), record["mentioned"])

    def test_branded_and_failed_captures_are_not_absences(self) -> None:
        self.assertEqual(len(self.discovery), 32)
        branded = [r for r in self.records if r["valid"] and r["kind"] == "branded"]
        failed = [r for r in self.records if not r["valid"]]
        self.assertEqual(len(branded), 16)
        self.assertEqual(len(failed), 3)
        for record in branded + failed:
            self.assertIsNone(record["recommended"])
            self.assertIsNone(record["top_pick"])
        for record in failed:
            self.assertIsNone(record["mentioned"])

    def test_recommendation_counts_and_positions(self) -> None:
        expected = {"claude": (0, 0), "gemini": (3, 2), "chatgpt": (0, 0), "google": (1, 0)}
        for engine, counts in expected.items():
            rows = [r for r in self.discovery if r["engine"] == engine]
            self.assertEqual(len(rows), 8)
            self.assertEqual((sum(r["recommended"] for r in rows), sum(r["top_pick"] for r in rows)), counts)
        unranked = next(r for r in self.discovery if r["engine"] == "gemini" and r["question_id"] == "practice-alone")
        self.assertTrue(unranked["recommended"])
        self.assertIsNone(unranked["recommendation_position"])
        self.assertFalse(unranked["top_pick"])
        google_free = next(r for r in self.discovery if r["engine"] == "google" and r["question_id"] == "free")
        self.assertEqual(google_free["website_evidence"], "matching_title")

    def test_patch_only_changes_one_page_and_its_twin(self) -> None:
        patch = (HERE / "candidate.patch").read_text()
        paths = re.findall(r"^\+\+\+ b/(.+)$", patch, re.M)
        self.assertEqual(paths, ["docs/index.html", "docs/index.html.md"])
        additions = "\n".join(line[1:] for line in patch.splitlines() if line.startswith("+") and not line.startswith("+++"))
        self.assertNotIn(chr(0x2014), additions)
        self.assertNotIn("$", additions)
        self.assertNotIn(QUESTION, (REPO / "docs/index.html").read_text())

    def test_visible_faq_matches_jsonld_and_markdown(self) -> None:
        graph = self.candidate.jsonld[0]["@graph"]
        faq = next(item for item in graph if item["@type"] == "FAQPage")["mainEntity"]
        visible = normalized(" ".join(self.candidate.visible))
        self.assertEqual(len(faq), 9)
        self.assertEqual(sum(item["name"] == QUESTION for item in faq), 1)
        for item in faq:
            self.assertIn(normalized(item["name"]), visible)
            self.assertIn(normalized(item["acceptedAnswer"]["text"]), visible)
            self.assertIn(item["name"], self.markdown)
            self.assertIn(item["acceptedAnswer"]["text"], self.markdown)
        answer = next(item["acceptedAnswer"]["text"] for item in faq if item["name"] == QUESTION)
        for fact in ("Jack Wallner", "E3 Apps", "Cedar Theory", "four free", "not bot matches or online multiplayer"):
            self.assertIn(fact, answer)

    def test_application_metadata_and_scripts_are_unchanged(self) -> None:
        original_graph = self.original.jsonld[0]["@graph"]
        candidate_graph = self.candidate.jsonld[0]["@graph"]
        original_app = next(item for item in original_graph if item["@type"] == "MobileApplication")
        candidate_app = next(item for item in candidate_graph if item["@type"] == "MobileApplication")
        self.assertEqual(original_app, candidate_app)
        self.assertEqual(self.original.scripts, self.candidate.scripts)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--raw", type=Path)
    args, rest = parser.parse_known_args()
    RAW_ROOT = args.raw
    unittest.main(argv=[sys.argv[0], *rest], verbosity=2)
