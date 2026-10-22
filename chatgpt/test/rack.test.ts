// The rack reader against the app's coach-written drills: every "which
// section" rack must read the same, and every Charleston pass must be the
// coach's or one the quiz accepts as just as good. Runs without a server.
import assert from "node:assert/strict";
import { test } from "node:test";

import { content } from "../src/content.ts";
import { readRack } from "../src/rack.ts";
import { practiceSession, type PassQuestion } from "../src/sessions.ts";
import { racked } from "../src/tiles.ts";

const items = (id: string) => content.drills.find((d) => d.id === id)!.items;

test("reads every hand-match rack as the coach does", () => {
  for (const item of items("hand-match")) assert.equal(readRack(racked(item.tiles)).read, item.answer, item.id);
});

test("passes what the coach passes on every Charleston deal", () => {
  const questions = new Map((practiceSession("charleston", 12).questions as PassQuestion[]).map((q) => [q.id, q]));
  for (const item of items("charleston-pass")) {
    const q = questions.get(item.id)!;
    const read = readRack(racked(item.deal));
    assert.equal(read.passes.length, 3, item.id);
    const required = q.pass.filter((t) => !q.swap.includes(t));
    for (const tile of required) assert.ok(read.passes.includes(tile), `${item.id} keeps out ${tile}`);
    for (const tile of read.passes) assert.ok([...q.pass, ...q.also].includes(tile), `${item.id}: ${tile}`);
  }
});

test("never passes a joker or an early flower", () => {
  for (const item of [...items("hand-match"), ...items("charleston-pass")]) {
    const read = readRack(racked(item.tiles ?? item.deal));
    assert.ok(![...read.passes, ...read.spare].some((t) => t === "J" || t === "F"), item.id);
  }
});

test("a messy deal still gets a shortlist", () => {
  const read = readRack(racked(["3C", "3C", "6C", "6B", "9B", "9D", "9D", "F", "GD", "2B", "7C", "E", "J"]));
  assert.equal(read.read, "threeSixNine");
  assert.ok(read.passes.includes("E"));
});
