// The rack reader against the app's coach-written drills: every "which
// section" rack must read the same, every Charleston deal must lean the way
// its explanation says, and every pass must be the coach's or one the quiz
// accepts as just as good. Then invariants over thousands of random deals.
// Runs without a server.
import assert from "node:assert/strict";
import { test } from "node:test";

import { content } from "../src/content.ts";
import { CARD_YEAR, readRack, type SectionId, support } from "../src/rack.ts";
import { findQuestion, lookUpTerm, practiceSession, type PassQuestion } from "../src/sessions.ts";
import { isHonor, parseRack, racked, rank, spokenName, type TileCode } from "../src/tiles.ts";
import { checkResult, rackResult } from "../src/tools.ts";

const items = (id: string) => content.drills.find((d) => d.id === id)!.items;
const rackOf = (s: string) => racked(s.split(" "));

/// Every tile of an American set, for random deals from a fixed seed.
function dealer(seed: number) {
  const set: TileCode[] = [];
  for (let k = 0; k < 4; k++) {
    for (const s of "CBD") for (let r = 1; r <= 9; r++) set.push(`${r}${s}`);
    set.push("N", "E", "W", "S", "RD", "GD", "SO");
  }
  for (let k = 0; k < 8; k++) set.push("F", "J");
  return () => {
    const a = [...set];
    for (let i = a.length - 1; i > 0; i--) {
      seed = (seed * 1664525 + 1013904223) >>> 0;
      const j = Math.floor((seed / 2 ** 32) * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return racked(a.slice(0, 13));
  };
}

test("reads every hand-match rack as the coach does", () => {
  for (const item of items("hand-match")) assert.equal(readRack(racked(item.tiles)).read, item.answer, item.id);
});

test("leans every Charleston deal the way its explanation does", () => {
  const lean: Record<string, SectionId> = {
    "cs-evens": "evens2468", "cs-winds": "windsDragons", "cs-run": "consecutiveRun", "cs-pairs": "odds13579", "cs-junk": "windsDragons",
    "cs-flowers": "evens2468", "cs-like": "likeNumbers", "cs-commit": "evens2468", "cs-year": "year",
  };
  for (const item of items("charleston-pass")) assert.equal(readRack(racked(item.deal)).read, lean[item.id], item.id);
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

test("random deals: a full pass, true reasons, true summaries", () => {
  const deal = dealer(4242);
  for (let n = 0; n < 1500; n++) {
    const tiles = deal();
    const read = readRack(tiles);
    const label = tiles.join(" ");
    const passable = tiles.filter((t) => t !== "J" && t !== "F").length;
    if (read.read !== "singlesAndPairs") assert.equal(read.picks.length, Math.min(3, passable), label);
    // A tile passed as fitting nothing fits no shortlisted section.
    for (const p of read.picks.filter((p) => !p.fill)) {
      for (const id of read.shortlist) assert.ok(!support(tiles, id).includes(p.tile), `${label}: ${p.tile} fits ${id}`);
    }
    // "Keep the tiles they share" names only tiles two sections share.
    const shared = read.summary.match(/share \(([^)]+)\)/)?.[1];
    if (shared) {
      const sets = read.shortlist.map((id) => support(tiles, id));
      for (const tile of parseRack([shared]).tiles) assert.ok(sets.filter((s) => s.includes(tile)).length >= 2, `${label}: ${tile}`);
    }
    assert.doesNotMatch(read.summary + (read.passNote ?? ""), /dead weight|fit nothing this rack/, label);
    // Nothing passed is also a tile to hope for or an anchor the pass breaks.
    for (const t of read.hope) assert.ok(!read.passes.includes(t), `${label}: passes and hopes for ${t}`);
    const kept = [...tiles];
    for (const t of read.passes) kept.splice(kept.indexOf(t), 1);
    for (const a of read.anchors) {
      const [, group, name] = a.match(/^(Pair|Pung|Kong) of (.+?) \(/)!;
      const held = kept.filter((t) => spokenName(t) === name).length;
      assert.equal(held, { Pair: 2, Pung: 3, Kong: 4 }[group], `${label}: ${a}`);
    }
  }
});

test("runs count suits: a lone off-suit tile is not part of a run", () => {
  const tiles = rackOf("1C 2C 3C 4B 5D 2B 3D 4C 1D 9C N W J");
  assert.deepEqual(support(tiles, "consecutiveRun"), ["1C", "2C", "3C", "4C"]);
  assert.deepEqual(support(rackOf("5C 7B 7B 7B 7B 2D 4D 6D 8D N F F J"), "consecutiveRun"), []);
  assert.equal(support(rackOf("1C 1C 2B 2B 3D 3D 5C 7B 9D N E F J"), "consecutiveRun").length, 6);
});

test("quints: four naturals and a joker, or a pair and three jokers, is a quint", () => {
  const four = readRack(rackOf("5C 7B 7B 7B 7B 2D 4D 6D 8D N F F J"));
  assert.ok(four.shortlist.includes("quints"));
  assert.match(four.sections.find((s) => s.id === "quints")!.note, /already make a quint/);
  const pair = readRack(rackOf("7B 7B J J J 2C 4C 6D 8D N E F F"));
  assert.match(pair.sections.find((s) => s.id === "quints")!.note, /already make a quint/);
  assert.doesNotMatch(JSON.stringify(readRack(rackOf("2C 2C 4C 4C 6B 6B 8B 8D F J N 2D 8C")).sections), /natural pung to build on/);
});

test("section notes never contradict the counts", () => {
  const read = readRack(rackOf("N N E E W W S S RD RD 1C 3C 7C"));
  const winds = read.sections.find((s) => s.id === "windsDragons")!;
  assert.notEqual(winds.verdict, "poor");
  assert.doesNotMatch(JSON.stringify(read.sections), /Only 10/);
  assert.ok(read.shortlist.includes("singlesAndPairs"));
});

test("369 counts the 6s a rack holds even with no 3s or 9s", () => {
  const read = readRack(rackOf("2C 2C 4C 6C 8C 4B 4B 5B 6D 8D F F J"));
  const note = read.sections.find((s) => s.id === "threeSixNine")!.note;
  assert.doesNotMatch(note, /None of your tiles/);
  assert.match(note, /two 6s/);
});

test("random deals: every tile count in a section note is the rack's real count", () => {
  const families: [RegExp, (t: TileCode) => boolean][] = [
    [/2s, 4s, 6s or 8s|a 2, 4, 6 or 8/, (t) => [2, 4, 6, 8].includes(rank(t) ?? 0)],
    [/1s, 3s, 5s, 7s or 9s|a 1, 3, 5, 7 or 9/, (t) => [1, 3, 5, 7, 9].includes(rank(t) ?? 0)],
    [/3s, 6s or 9s|a 3, 6 or 9/, (t) => [3, 6, 9].includes(rank(t) ?? 0)],
    [/winds or dragons|a wind or dragon/, isHonor],
  ];
  const words = ["None", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen"];
  const deal = dealer(369);
  for (let n = 0; n < 1500; n++) {
    const tiles = deal();
    for (const { note } of readRack(tiles).sections) {
      const said = note.match(/^(?:Only )?(\w+) of your tiles (?:is|are) ([^.]+)\./);
      const sixes = note.match(/^Your (\w+) 6s? (?:is|are) the only/);
      const label = `${tiles.join(" ")}: ${note}`;
      if (sixes) assert.equal(words.indexOf(sixes[1]), tiles.filter((t) => rank(t) === 6).length, label);
      if (!said) continue;
      const family = families.find(([phrase]) => phrase.test(said[2]));
      if (!family) continue;
      const count = /^\d+$/.test(said[1]) ? Number(said[1]) : words.indexOf(said[1]);
      assert.equal(count, tiles.filter(family[1]).length, label);
    }
  }
});

test("no passable tile means a plain explanation, not a claim", () => {
  const read = readRack(rackOf("J J J J J J J J F F F F F"));
  assert.equal(read.picks.length, 0);
  assert.match(read.passNote ?? "", /flowers/);
});

test("pass context: blind rounds and the courtesy pass", () => {
  const tight = rackOf("2C 2C 4C 4C 4C 6B 6B 8B 8D 8D F F J");
  assert.equal(readRack(tight).picks.length, 3);
  assert.match(readRack(tight, "first-left").passNote ?? "", /blind/);
  assert.ok(readRack(tight, "first-left").picks.every((p) => !p.fill));
  assert.match(readRack(rackOf("2C 2C 4C 4C 6B 6B 8B 8D F J 1C 9B N"), "courtesy").passNote ?? "", /courtesy/);
});

test("parser: tricky input reads or is refused, never crashes", () => {
  assert.deepEqual(parseRack(["constructor", "__proto__", "4C", "6B", "8B"]).tiles, ["4C", "6B", "8B"]);
  assert.equal(parseRack(["constructor", "__proto__", "toString"]).unreadable.length, 3);
  assert.equal(parseRack(["2C 2C 4C 4C 6B 6B 8B 8D F J 1C 9B N"]).tiles.length, 13);
  assert.deepEqual(parseRack(["2C2C", "C5", "F3", "5", "dot", "North Wind", "1 bird", "3 jokers", "🀄"]).tiles, racked(["2C", "2C", "5C", "F", "5D", "N", "1B", "J", "J", "J", "RD"]));
  assert.ok(parseRack(["x".repeat(500)]).unreadable[0].length <= 25);
});

test("a rack with unreadable entries asks for a fix instead of reading", () => {
  const r = rackResult(["2C", "2C", "4C", "4C", "6B", "6B", "8B", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown"]);
  assert.equal(r.structuredContent.passes.length, 0);
  assert.ok((r._meta.widget as { error?: string }).error);
  assert.deepEqual((r._meta.widget as { unreadable?: string[] }).unreadable, Array(6).fill("unknown"));
  const proto = rackResult(["constructor", "__proto__", "4C", "6B", "8B"]);
  assert.match(proto.content[0].text, /Could not read: constructor, proto/);
});

test("a short rack is read with a warning", () => {
  const r = rackResult(["2C", "2C", "4C", "4C", "6B", "6B", "8B"]);
  assert.match((r._meta.widget as { partial?: string }).partial ?? "", /only the 7 tiles/);
  // Every shared tile fits, so the pass comes from the tiles not shared.
  assert.equal(r.structuredContent.passes.length, 0);
  assert.match(r.content[0].text, /tiles you didn't share/);
});

test("glossary matches whole terms and aliases, never a fragment", () => {
  const cases: Record<string, string | null> = {
    "joker exchange rules": "Joker swap", "What is a white dragon?": "Soap", "How do I swap a joker": "Joker swap",
    the: null, tile: null, hand: null, pass: null, "dead wall": null, scoring: null, kongs: "Kong", "dead hand": "Dead hand",
  };
  for (const [q, term] of Object.entries(cases)) assert.equal(lookUpTerm(q)?.term ?? null, term, q);
});

test("practice: tile naming, few joker rules, answers checked by id", () => {
  const tiles = practiceSession("tiles", 12).questions;
  assert.ok(tiles.some((q) => q.id.startsWith("name-")));
  assert.ok(tiles.filter((q) => /joker|quint/.test(q.id)).length <= 3);
  assert.equal(practiceSession("reading", 12).questions.length, 9);
  const q = findQuestion("quiz-joker-count")!;
  assert.equal(q.kind === "choice" && checkResult(q.id, q.choices[q.answerIndex]).structuredContent.correct, true);
  assert.equal(checkResult("cs-evens", "1C 9B N").structuredContent.correct, true);
  assert.equal(checkResult("cs-evens", "1C 9B 2C").structuredContent.correct, false);
});

test("the card year is current", () => {
  // The shared content's year examples and CARD_YEAR change together when a
  // new card comes out each April.
  assert.ok(new Date() < new Date(Date.UTC(CARD_YEAR + 1, 3, 1)), `A new card is out: update the shared content's year examples and CARD_YEAR (${CARD_YEAR}).`);
});
