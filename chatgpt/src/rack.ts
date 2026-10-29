// Reads a dealt rack the way a coach does: count the tiles that build toward
// each stable section of the card, weigh the pairs and pungs that anchor
// them, shortlist the strongest, and pick a three-tile pass with a reason for
// every tile. Strays are expected, since a dealt rack is never clean, which
// is what the Charleston is for. Every statement is about the SHAPE of a
// section or a rule of the game and holds on any year's card; nothing here
// names or copies a hand from the NMJL card.
import { content } from "./content.ts";
import { countTiles, isHonor, isSuited, rank, spokenName, type TileCode } from "./tiles.ts";

export type SectionId =
  | "year" | "evens2468" | "likeNumbers" | "quints" | "consecutiveRun"
  | "odds13579" | "windsDragons" | "threeSixNine" | "singlesAndPairs";

export type Verdict = "fits" | "possible" | "poor";

export type SectionRead = { id: SectionId; name: string; verdict: Verdict; note: string };

export const CHARLESTON_PASSES = ["first-right", "first-across", "first-left", "second-left", "second-across", "second-right", "courtesy"] as const;
export type CharlestonPass = (typeof CHARLESTON_PASSES)[number];

/** One tile to pass and why. `fill` marks a tile the plan can spare, not one that fits nothing. */
export type PassPick = { tile: TileCode; reason: string; fill: boolean };

export type RackRead = {
  tiles: TileCode[];
  /** The section the rack clearly leans to, or null when it is torn or scattered. */
  read: SectionId | null;
  /** The two or three sections worth keeping in mind, strongest first. */
  shortlist: SectionId[];
  headline: string;
  summary: string;
  sections: SectionRead[];
  /** The coach's pass, up to three tiles, each with its reason. */
  picks: PassPick[];
  passes: TileCode[];
  /** Further tiles that can go on later passes. */
  spare: TileCode[];
  /** What to do about the rest of the pass, or why there is no confident pass. */
  passNote: string | null;
  /** The pairs and pungs the plan is built on, with how many copies exist. */
  anchors: string[];
  /** Tiles worth hoping to receive. */
  hope: TileCode[];
  jokerNote: string;
  counts: { jokers: number; flowers: number; honors: number; pairs: number; pungs: number };
};

/** The card the shared content is written for. Bump it with the yearly content update each April. */
export const CARD_YEAR = 2026;

const isDragon = (t: TileCode) => t === "RD" || t === "GD" || t === "SO";
const isWind = (t: TileCode) => t === "N" || t === "E" || t === "W" || t === "S";
const isNatural = (t: TileCode) => t !== "J" && t !== "F";
const DRAGON_SUIT: Record<string, string> = { RD: "C", GD: "B", SO: "D" };
/** A dealt rack. Fewer tiles is a partial read. */
const FULL_RACK = 13;
const NUMBER_WORDS = ["no", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen"];

export function sectionName(id: SectionId): string {
  return content.categories.find((c) => c.id === id)?.displayName ?? id;
}

function yearDigits(): number[] {
  return [...new Set(String(CARD_YEAR).split("").map(Number).filter((d) => d > 0))];
}

function ranksOf(tiles: TileCode[]): number[] {
  return [...new Set(tiles.map(rank).filter((r): r is number => r !== null))].sort((a, b) => a - b);
}

const inRanks = (tiles: TileCode[], allowed: number[]) => tiles.filter((t) => allowed.includes(rank(t) ?? 0));

function list(words: string[], joiner = "and"): string {
  return words.length <= 1 ? (words[0] ?? "") : `${words.slice(0, -1).join(", ")} ${joiner} ${words[words.length - 1]}`;
}

const plural = (n: number, word: string) => `${NUMBER_WORDS[n] ?? n} ${word}${n === 1 ? "" : "s"}`;
const GROUP = ["", "single", "pair", "pung", "kong"];
/// "a pair of 2 Craks", "four 7 Bams"
const groupOf = (t: TileCode, n: number) => (n >= 2 && n <= 4 ? `a ${GROUP[n]} of ${spokenName(t)}s` : `${plural(n, spokenName(t))}`);
/// "Only three of your tiles are...", "Only one of your tiles is...", "None of your tiles are..."
const only = (n: number, rest: [string, string]) => (n === 0 ? `None of your tiles ${rest[1]}` : `Only ${NUMBER_WORDS[n]} of your tiles ${n === 1 ? rest[0] : rest[1]}`);
const suitName = (suit: string) => spokenName(`1${suit}`).split(" ")[1];

/// Run hands use numbers in a row, at most five numbers wide. Inside the best
/// five-number stretch a tile counts when its number is part of three or more
/// numbers in a row and it has a same-suit neighbor or a twin: a chain in one
/// suit, or pairs of numbers in a row across suits. A lone off-suit tile that
/// happens to sit in the stretch does not count.
function runStretch(tiles: TileCode[]): { tiles: TileCode[]; low: number; chain: string | null; missing: TileCode[] } {
  const holds = (r: number, suit: string) => tiles.includes(`${r}${suit}`);
  let best = { tiles: [] as TileCode[], low: 1, chain: null as string | null, missing: [] as TileCode[] };
  for (let low = 1; low <= 5; low++) {
    const high = low + 4;
    const block = tiles.filter((t) => isSuited(t) && rank(t)! >= low && rank(t)! <= high);
    const linked = block.filter((t) => {
      const r = rank(t)!, suit = t[1];
      return [r - 1, r + 1].some((n) => n >= low && n <= high && holds(n, suit)) || block.filter((x) => x === t).length >= 2;
    });
    const ranks = ranksOf(linked);
    const inSequence = (r: number) => {
      let from = r, to = r;
      while (ranks.includes(from - 1)) from--;
      while (ranks.includes(to + 1)) to++;
      return to - from >= 2;
    };
    const counted = linked.filter((t) => inSequence(rank(t)!));
    if (counted.length > best.tiles.length) best = { tiles: counted, low, ...longestChain(block, low, high) };
  }
  return best;
}

/// The longest same-suit numbers-in-a-row inside a stretch, three or more, as
/// "1-2-3-4 Crak", and the numbers that would extend it inside the stretch.
function longestChain(block: TileCode[], low: number, high: number): { chain: string | null; missing: TileCode[] } {
  let best: { suit: string; from: number; to: number } | null = null;
  for (const suit of "CBD") {
    for (let from = low; from <= high; from++) {
      if (!block.includes(`${from}${suit}`)) continue;
      let to = from;
      while (to + 1 <= high && block.includes(`${to + 1}${suit}`)) to++;
      if (to - from >= 2 && (!best || to - from > best.to - best.from)) best = { suit, from, to };
    }
  }
  if (!best) return { chain: null, missing: [] };
  const { suit, from, to } = best;
  const nums = Array.from({ length: to - from + 1 }, (_, i) => from + i).join("-");
  const missing = [from - 1, to + 1].filter((r) => r >= low && r <= high).map((r) => `${r}${suit}`);
  return { chain: `${nums} ${suitName(suit)}`, missing };
}

/// The most copies of one number held in two or more suits.
function likeGroup(tiles: TileCode[]): { tiles: TileCode[]; rank: number; suits: number } {
  let best = { tiles: [] as TileCode[], rank: 0, suits: 0 };
  for (const r of ranksOf(tiles)) {
    const copies = tiles.filter((t) => rank(t) === r);
    const suits = new Set(copies.map((t) => t[1])).size;
    if (suits >= 2 && copies.length > best.tiles.length) best = { tiles: copies, rank: r, suits };
  }
  return best;
}

/// Five of a kind is a tile's naturals plus jokers. Jokers go to the biggest
/// groups first; a group the jokers can lift to five is a quint already.
function quintPlan(tiles: TileCode[]) {
  const jokers = tiles.filter((t) => t === "J").length;
  const groups = Object.entries(countTiles(tiles.filter(isNatural))).filter(([, n]) => n >= 2).sort((a, b) => b[1] - a[1]);
  let left = jokers;
  const complete: TileCode[] = [];
  for (const [t, n] of groups) if (5 - n <= left) { complete.push(t); left -= 5 - n; }
  const best = groups[0] ? { tile: groups[0][0], n: groups[0][1] } : null;
  if (!complete.length) return { tiles: [] as TileCode[], complete, best, jokers };
  const grouped = new Set(groups.filter(([t, n]) => complete.includes(t) || n >= 3).map(([t]) => t));
  return { tiles: [...tiles.filter((t) => grouped.has(t)), ...tiles.filter((t) => t === "J")], complete, best, jokers };
}

export function support(tiles: TileCode[], id: SectionId): TileCode[] {
  const ranks = ranksOf(tiles);
  switch (id) {
    case "evens2468":
      return inRanks(tiles, [2, 4, 6, 8]);
    case "odds13579":
      return inRanks(tiles, [1, 3, 5, 7, 9]);
    case "threeSixNine":
      return ranks.includes(6) && (ranks.includes(3) || ranks.includes(9)) ? inRanks(tiles, [3, 6, 9]) : [];
    case "consecutiveRun":
      return runStretch(tiles).tiles;
    case "likeNumbers":
      return likeGroup(tiles).tiles;
    case "windsDragons":
      return tiles.filter(isHonor);
    case "year":
      return tiles.includes("SO") ? [...inRanks(tiles, yearDigits()), ...tiles.filter((t) => t === "SO")] : [];
    case "quints":
      return quintPlan(tiles).tiles;
    case "singlesAndPairs": {
      const counts = countTiles(tiles.filter(isNatural));
      return Object.entries(counts).filter(([, n]) => n >= 2).flatMap(([t]) => [t, t]);
    }
  }
}

const SECTIONS: SectionId[] = ["quints", "likeNumbers", "singlesAndPairs", "year", "threeSixNine", "windsDragons", "consecutiveRun", "evens2468", "odds13579"];

/// How strongly a rack backs a section: one point a tile, plus half a point
/// for each natural pair and a point for each pung or bigger, since jokers can
/// grow a pair but never make one. A finished quint adds a point and a half.
/// Singles & Pairs counts its pairs and loses two points a joker, because a
/// joker is dead weight there and can never be passed.
function score(tiles: TileCode[], id: SectionId): number {
  const own = support(tiles, id);
  const jokers = tiles.filter((t) => t === "J").length;
  if (id === "singlesAndPairs") return own.length >= 8 ? own.length - 2 * jokers : 0;
  const groups = Object.values(countTiles(own.filter(isNatural)));
  const bonus = groups.reduce((sum, n) => sum + (n >= 3 ? 1 : n === 2 ? 0.5 : 0), 0);
  const quints = id === "quints" ? quintPlan(tiles).complete.length * 1.5 : 0;
  return own.length + bonus + quints;
}

/// Share of the rack a section uses. Jokers and flowers are neutral, and
/// number sections ignore dragons because many number hands carry one.
function share(tiles: TileCode[], id: SectionId): number {
  const countable = tiles.filter((t) => isSuited(t) || isWind(t) || (isDragon(t) && (id === "windsDragons" || id === "year" || id === "singlesAndPairs" || id === "quints"))).length;
  return countable ? support(tiles, id).length / countable : 0;
}

type Scored = { id: SectionId; score: number };

function choose(tiles: TileCode[]): { read: SectionId | null; shortlist: SectionId[]; scored: Scored[] } {
  const scored = SECTIONS.map((id) => ({ id, score: score(tiles, id) }))
    .sort((a, b) => b.score - a.score || SECTIONS.indexOf(a.id) - SECTIONS.indexOf(b.id));
  const viable = scored.filter((s) => s.score >= 3);
  const [best, second] = viable;
  if (!best) return { read: null, shortlist: [], scored };
  // A number flooding every suit is Like Numbers even though odds or evens
  // count the same tiles: the narrower family is the better read.
  const like = likeGroup(tiles);
  const flooded = best.id !== "quints" && (like.tiles.length >= 6 || (like.tiles.length >= 5 && like.suits === 3));
  const top = flooded ? viable.find((s) => s.id === "likeNumbers")! : best;
  const shortlist = [top, ...viable.filter((s) => s !== top && s.score >= 4 && s.score >= top.score - 2.5)].slice(0, 3).map((s) => s.id);
  const runnerUp = top === best ? second : best;
  const gap = top.score - (runnerUp?.score ?? 0);
  // A lean needs something to build on: seven tiles, or five with a natural
  // pair or pung among them. Quints needs a second group beside its quint.
  const own = support(tiles, top.id);
  const anchored = own.length >= 7 || (own.length >= 5 && Object.values(countTiles(own.filter(isNatural))).some((n) => n >= 2));
  const quintsReady = top.id !== "quints" || quintPlan(tiles).complete.length >= 2 || quintPlan(tiles).tiles.filter(isNatural).length > 5;
  const clear = flooded || (anchored && quintsReady && top.score >= 5 && share(tiles, top.id) >= 0.4 && (gap >= 1.5 || (gap >= 1 && anchored)));
  return { read: clear ? top.id : null, shortlist, scored };
}

/// Why a section is a long shot for this rack, true to its count.
function longShot(tiles: TileCode[], id: SectionId, counts: RackRead["counts"]): string {
  const n = support(tiles, id).length;
  switch (id) {
    case "year":
      return tiles.includes("SO") ? `${only(n, ["is a year digit or a soap", "are year digits or soaps"])}.` : "Year hands use soaps for the zeros, and this rack has none.";
    case "evens2468":
      return `${only(n, ["is a 2, 4, 6 or 8", "are 2s, 4s, 6s or 8s"])}.`;
    case "odds13579":
      return `${only(n, ["is a 1, 3, 5, 7 or 9", "are 1s, 3s, 5s, 7s or 9s"])}.`;
    case "quints": {
      if (counts.jokers === 0) return "A quint is five of a kind, which takes jokers, and this rack has none.";
      const plan = quintPlan(tiles);
      if (!plan.best) return `Quints stretch a group with jokers, and nothing on this rack is paired yet.`;
      const short = 5 - plan.best.n - counts.jokers;
      return `Your biggest group is ${groupOf(plan.best.tile, plan.best.n)}, and with ${plural(counts.jokers, "joker")} that is ${plural(short, "tile")} short of five of a kind.`;
    }
    case "threeSixNine": {
      // Support stays empty until 3s or 9s join the 6s, so count the tiles themselves.
      const ranks = ranksOf(tiles);
      if (!ranks.includes(6)) return "369 needs 6s to stand apart from an odds hand, and this rack has none.";
      const sixes = inRanks(tiles, [6]).length;
      if (!ranks.includes(3) && !ranks.includes(9)) return sixes === 1 ? "Your one 6 is the only 3, 6 or 9 here, and 369 needs 3s or 9s beside it." : `Your ${plural(sixes, "6")} are the only 3s, 6s or 9s here, and 369 needs 3s or 9s beside them.`;
      return `${only(inRanks(tiles, [3, 6, 9]).length, ["is a 3, 6 or 9", "are 3s, 6s or 9s"])}.`;
    }
    case "consecutiveRun":
      return n ? `${only(n, ["steps", "step"])} up in order with a same-suit neighbor or a twin.` : "No three numbers here step up in order with a same-suit neighbor or a twin.";
    case "likeNumbers":
      return "No number shows up across the suits often enough.";
    case "windsDragons":
      return n ? `${only(n, ["is a wind or dragon", "are winds or dragons"])}.` : "This rack has no winds or dragons.";
    case "singlesAndPairs":
      if (counts.jokers) return `Singles & Pairs never uses jokers, and jokers can't be passed, so your ${plural(counts.jokers, "joker")} would be stuck.`;
      return `Only ${plural(counts.pairs + counts.pungs, "natural pair")}, and Singles & Pairs is built from pairs.`;
  }
}

/// What a section has going for it on this rack.
function strength(tiles: TileCode[], id: SectionId, counts: RackRead["counts"]): string {
  const n = support(tiles, id).length;
  switch (id) {
    case "evens2468":
      return `${n} of your tiles are 2s, 4s, 6s or 8s.`;
    case "odds13579":
      return `${n} of your tiles are 1s, 3s, 5s, 7s or 9s.`;
    case "threeSixNine":
      return `${n} of your tiles are 3s, 6s or 9s, and the 6s keep it apart from a pure odds hand.`;
    case "consecutiveRun": {
      const run = runStretch(tiles);
      return `${n} of your tiles step up in order inside ${run.low} to ${run.low + 4}${run.chain ? `, led by ${run.chain}` : ""}.`;
    }
    case "likeNumbers": {
      const like = likeGroup(tiles);
      return `You hold ${NUMBER_WORDS[like.tiles.length]} ${like.rank}s across ${like.suits === 3 ? "all three" : "two"} suits.`;
    }
    case "windsDragons":
      return `${n} of your tiles are winds or dragons.`;
    case "year":
      return `${n} of your tiles are ${CARD_YEAR}'s digits (${yearDigits().join(" and ")}) or soaps for the zero. Check the year lines on your card.`;
    case "quints": {
      const plan = quintPlan(tiles);
      const made = plan.complete.map((t) => `${NUMBER_WORDS[countTiles(tiles)[t]]} ${spokenName(t)}s`);
      return `Your ${list(made)} plus ${plural(counts.jokers, "joker")} already make ${plan.complete.length === 1 ? "a quint" : plural(plan.complete.length, "quint")}, five of a kind.`;
    }
    case "singlesAndPairs": {
      const flowers = counts.flowers === 2 ? " (plus a pair of flowers)" : "";
      const pairs = plural(counts.pairs + counts.pungs, "natural pair");
      return `${pairs[0].toUpperCase()}${pairs.slice(1)}${flowers} and no jokers. Every tile must be the real one and only the winning tile can be called, so commit only if your pairs line up with a line on your card.`;
    }
  }
}

function verdictFor(tiles: TileCode[], id: SectionId, read: SectionId | null, shortlist: SectionId[], counts: RackRead["counts"], scores: Map<SectionId, number>): SectionRead {
  const name = sectionName(id);
  if (id === read) return { id, name, verdict: "fits", note: strength(tiles, id, counts) };
  if (shortlist.includes(id)) return { id, name, verdict: "possible", note: strength(tiles, id, counts) };
  // Real backing that the leaders simply outscore: say so rather than call it thin.
  const lead = read ?? shortlist[0];
  if (lead && (scores.get(id) ?? 0) >= 5) return { id, name, verdict: "poor", note: `${strength(tiles, id, counts)} ${sectionName(lead)} has more.` };
  return { id, name, verdict: "poor", note: longShot(tiles, id, counts) };
}

/// Order of passing among tiles that help equally little: lone winds, then
/// numbers (1s and 9s before middle numbers), then dragons, since many number
/// hands carry a dragon.
function typeOrder(t: TileCode): number[] {
  return [isWind(t) ? 0 : isSuited(t) ? 1 : 2, isSuited(t) ? -Math.abs(rank(t)! - 5) : 0];
}

function compare(a: number[], b: number[]): number {
  for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return a[i] - b[i];
  return 0;
}

const brief = (id: SectionId) => (id === "evens2468" ? "2468" : id === "odds13579" ? "13579" : sectionName(id));

/// Why a tile that fits nothing on the shortlist goes: in the lead section's
/// terms, or naming every section when the rack is torn.
function strayReason(t: TileCode, read: SectionId | null, shortlist: SectionId[], tiles: TileCode[]): string {
  const copies = tiles.filter((x) => x === t).length;
  if (isWind(t)) return copies === 1 ? "a lone wind" : `a pair of winds your sections don't use`;
  if (isDragon(t)) return copies === 1 ? "a lone dragon" : "a pair of dragons your sections don't use";
  if (!read && shortlist.length >= 2) return shortlist.length === 2 ? `fits neither ${brief(shortlist[0])} nor ${brief(shortlist[1])}` : `fits none of ${list(shortlist.map(brief), "or")}`;
  const lead = read ?? shortlist[0] ?? null;
  const r = rank(t)!;
  switch (lead) {
    case "evens2468": return "odd, so no use to 2468";
    case "odds13579": return "even, so no use to 13579";
    case "threeSixNine": return "not a 3, 6 or 9";
    case "consecutiveRun": { const run = runStretch(tiles); return r < run.low || r > run.low + 4 ? `outside your ${run.low} to ${run.low + 4} stretch` : "no neighbor in its suit"; }
    case "likeNumbers": return `not a ${likeGroup(tiles).rank}`;
    case "windsDragons": return "a number tile";
    case "year": return `not one of ${CARD_YEAR}'s digits`;
    case "quints": return "not part of a group";
    case "singlesAndPairs": return "a single outside your pairs";
    default: {
      const near = tiles.some((x) => x !== t && x[1] === t[1] && isSuited(x) && Math.abs(rank(x)! - r) <= 2);
      return near ? "the least connected number" : `no other ${suitName(t[1])}s near it`;
    }
  }
}

function pickPasses(tiles: TileCode[], read: SectionId | null, shortlist: SectionId[], scores: Map<SectionId, number>, pass: CharlestonPass | undefined) {
  const counts = countTiles(tiles);
  const top = Math.max(...shortlist.map((id) => scores.get(id) ?? 0), 1);
  const weight = (id: SectionId) => (id === read ? 1 : read ? 0.6 * (scores.get(id)! / top) : scores.get(id)! / top);
  const supports = new Map(shortlist.map((id) => [id, support(tiles, id)]));
  const lead = read ?? shortlist[0] ?? null;
  const numberLead = lead !== null && !["windsDragons", "singlesAndPairs", "quints"].includes(lead);
  const leadSuits = numberLead ? countTiles((supports.get(lead!) ?? []).filter(isSuited).map((t) => t[1])) : {};
  const jokers = counts["J"] ?? 0;

  // What each tile is worth keeping. A tile that fits no shortlisted section
  // is worth nothing, a dead pair a shade more than a stray. A tile that fits
  // is worth its section's weight plus what passing it costs the groups:
  // splitting a pair loses more than taking the spare from a pung, because
  // jokers can lift a pair back to a pung but never make a pair. Picks are
  // made one at a time, so a pair already broken costs only its last tile.
  type Kind = { tile: TileCode; base: number; helps: SectionId | null; left: number; passed: number };
  type Candidate = { tile: TileCode; value: number; fits: boolean; helps: SectionId | null; left: number };
  const kinds: Kind[] = [];
  for (const tile of new Set(tiles.filter(isNatural))) {
    let base = 0, helps: SectionId | null = null;
    for (const id of shortlist) if (supports.get(id)!.includes(tile) && weight(id) > base) { base = weight(id); helps = id; }
    // A dragon of a suit the lead section is built on can join a number hand.
    if (!base && isDragon(tile) && numberLead && (leadSuits[DRAGON_SUIT[tile]] ?? 0) >= 3) { base = 0.35; helps = lead; }
    kinds.push({ tile, base, helps, left: counts[tile], passed: 0 });
  }
  const loss = (m: number) => (m >= 4 ? 0.1 : m === 3 ? (jokers ? 0.4 : 0.5) : m === 2 ? 0.5 : 0);
  // On a tie, break a group not yet touched rather than give away every copy of one tile.
  const cost = (k: Kind) => (k.base ? k.base + loss(k.left) + (k.left >= 2 ? 0.01 * k.passed : 0) : 0.2 * loss(k.left));
  const ranked: Candidate[] = [];
  for (;;) {
    const open = kinds.filter((k) => k.left > 0 && !(lead === "singlesAndPairs" && k.base && k.left >= 2));
    if (!open.length) break;
    const next = open.sort((a, b) => cost(a) - cost(b) || compare(typeOrder(a.tile), typeOrder(b.tile)))[0];
    ranked.push({ tile: next.tile, value: cost(next), fits: next.base > 0, helps: next.helps, left: next.left });
    next.left--;
    next.passed++;
  }
  const dead = ranked.filter((c) => !c.fits);

  const reasonFor = (c: Candidate): PassPick => {
    if (!c.fits) return { tile: c.tile, reason: strayReason(c.tile, read, shortlist, tiles), fill: false };
    const name = spokenName(c.tile);
    const fill = (reason: string): PassPick => ({ tile: c.tile, reason, fill: true });
    if (c.left >= 3) return fill(`a spare ${name}, keeping a pair${jokers ? " a joker can grow again" : ""}`);
    if (c.left === 2) return fill(`splits your ${name} pair, the one your plan needs least`);
    if (counts[c.tile] >= 2) return fill(`the other ${name}, since a split pair is only a single`);
    if (c.helps && c.helps !== lead) return fill(`only helps ${sectionName(c.helps)}`);
    if (isDragon(c.tile)) return fill("a dragon your plan can do without");
    return fill(`a single your ${sectionName(c.helps ?? lead!)} plan can spare`);
  };

  const blindRound = pass === "first-left" || pass === "second-right";
  // On a partial rack the unshared tiles may hold the real strays, so only
  // tiles that fit nothing are passed.
  const partial = tiles.length < FULL_RACK;
  const take = pass === "courtesy" || blindRound || partial ? Math.min(3, dead.length) : 3;
  const picks = ranked.slice(0, take).map(reasonFor);
  const spare = ranked.slice(take).filter((c) => !c.fits).map((c) => c.tile);
  const pairsOnly = lead === "singlesAndPairs" && picks.length < 3;

  let passNote: string | null = null;
  const fills = picks.filter((p) => p.fill).length;
  if (!ranked.length) {
    passNote = "Jokers can never be passed, so this pass has to come from your flowers, or pass blind on the first left or second right. Check how many flowers your target line uses before you choose.";
  } else if (pass === "courtesy") {
    passNote = picks.length
      ? `The courtesy pass is 0 to 3 tiles across, and both players pass the same number. Ask for ${NUMBER_WORDS[picks.length]}.`
      : "Nothing here is clearly spare, so you can decline the courtesy pass.";
  } else if (partial && !blindRound && picks.length < 3) {
    passNote = `${picks.length ? "The other tiles you shared" : "Every tile you shared"} ${picks.length ? "all fit" : "fits"} your plan, so take the rest of the pass from the tiles you didn't share.`;
  } else if (pairsOnly && !blindRound) {
    passNote = "Everything else is in a pair. Singles & Pairs lines name every pair, so split one your target line doesn't use, or on the first left or second right pass blind instead.";
  } else if (blindRound && picks.length < 3) {
    passNote = `This is a blind-pass round. For the rest of the three, send on ${3 - picks.length === 1 ? "one of the tiles" : "tiles"} you were just handed without looking, and keep your own.`;
  } else if (fills) {
    const deadCount = picks.length - fills;
    passNote = `${deadCount ? `Only ${plural(deadCount, "tile")} ${deadCount === 1 ? "fits" : "fit"} none of your sections` : "Every tile here helps your plan"}, so the rest of the pass gives up what the plan can best spare. On the first left or second right you can pass blind instead.`;
  } else if (picks.length < 3 && ranked.length < 3) {
    passNote = "Jokers can never be passed, so the rest of this pass has to come from your flowers, or pass blind on the first left or second right.";
  }
  return { picks, spare, passNote };
}

function anchorsFor(tiles: TileCode[], lead: SectionId | null): string[] {
  if (!lead) return [];
  const own = lead === "singlesAndPairs" ? tiles.filter(isNatural) : support(tiles, lead).filter(isNatural);
  const counts = countTiles(own);
  const all = countTiles(tiles);
  return Object.keys(counts)
    .filter((t) => (all[t] ?? 0) >= 2)
    .sort((a, b) => all[b] - all[a])
    .slice(0, 4)
    .map((t) => {
      const n = all[t];
      const group = n === 2 ? "Pair" : n === 3 ? "Pung" : "Kong";
      return `${group} of ${spokenName(t)} (${n === 4 ? "all four" : 4 - n === 1 ? "one more exists" : "two more exist"})`;
    });
}

function hopeFor(tiles: TileCode[], lead: SectionId | null): TileCode[] {
  if (!lead || lead === "singlesAndPairs") return [];
  const all = countTiles(tiles);
  const own = support(tiles, lead).filter(isNatural);
  const hope = new Set(Object.keys(countTiles(own)).filter((t) => all[t] === 2 || all[t] === 3));
  if (lead === "consecutiveRun") for (const t of runStretch(tiles).missing) hope.add(t);
  if (lead === "likeNumbers") {
    const like = likeGroup(tiles);
    for (const suit of "CBD") if (!all[`${like.rank}${suit}`]) hope.add(`${like.rank}${suit}`);
  }
  return [...hope].filter((t) => (all[t] ?? 0) < 4).slice(0, 4);
}

function jokerNoteFor(jokers: number, lead: SectionId | null): string {
  if (lead === "singlesAndPairs") return jokers ? "Jokers can't be used in Singles & Pairs, and they can never be passed." : "No jokers, and Singles & Pairs can't use them anyway.";
  if (jokers === 0) return "No jokers yet, so every group has to be natural until one arrives. Hold your pairs.";
  if (jokers <= 2) return `Your ${jokers === 1 ? "joker" : "two jokers"} can lift a pair to a pung or kong, so pairs are worth more than singles. Jokers never pass.`;
  return `${NUMBER_WORDS[jokers][0].toUpperCase()}${NUMBER_WORDS[jokers].slice(1)} jokers can grow any pair into a pung, kong or even a quint. Jokers never pass.`;
}

export function readRack(tiles: TileCode[], pass?: CharlestonPass): RackRead {
  const grouped = countTiles(tiles.filter(isNatural));
  const counts = {
    jokers: tiles.filter((t) => t === "J").length,
    flowers: tiles.filter((t) => t === "F").length,
    honors: tiles.filter(isHonor).length,
    pairs: Object.values(grouped).filter((n) => n === 2).length,
    pungs: Object.values(grouped).filter((n) => n >= 3).length,
  };
  const { read, shortlist, scored } = choose(tiles);
  const scores = new Map(scored.map((s) => [s.id, s.score]));
  const order: Record<Verdict, number> = { fits: 0, possible: 1, poor: 2 };
  const rankInList = (id: SectionId) => (shortlist.includes(id) ? shortlist.indexOf(id) : 9);
  const sections = content.categories
    .map((c) => verdictFor(tiles, c.id as SectionId, read, shortlist, counts, scores))
    .sort((a, b) => order[a.verdict] - order[b.verdict] || rankInList(a.id) - rankInList(b.id) || (scores.get(b.id) ?? 0) - (scores.get(a.id) ?? 0));
  const { picks, spare, passNote } = pickPasses(tiles, read, shortlist, scores, pass);
  const lead = read ?? shortlist[0] ?? null;
  const kept = [...tiles];
  for (const p of picks) kept.splice(kept.indexOf(p.tile), 1);

  const names = shortlist.map(sectionName);
  const others = names.filter((n) => !read || n !== sectionName(read));
  const headline = read
    ? `Leaning ${sectionName(read)}`
    : names.length >= 2 ? `Torn between ${list(names)}` : names.length ? `Maybe ${names[0]}` : "No clear section yet";
  let summary: string;
  if (read) {
    summary = `Leaning ${sectionName(read)}. ${strength(tiles, read, counts)}${others.length ? ` Also in reach: ${list(others)}.` : ""}`;
  } else if (names.length >= 2) {
    const sets = shortlist.map((id) => new Set(support(tiles, id)));
    const shared = [...sets[0]].filter((t) => sets.slice(1).some((s) => s.has(t)) && isNatural(t));
    // The section whose tiles the pass gives up first, else the lowest scored.
    const firstFill = picks.find((p) => p.fill);
    const givingUp = shortlist.find((id) => firstFill && support(tiles, id).includes(firstFill.tile) && sets.filter((set) => set.has(firstFill.tile)).length === 1)
      ?? [...shortlist].sort((a, b) => (scores.get(a) ?? 0) - (scores.get(b) ?? 0))[0];
    const anyDead = picks.some((p) => !p.fill);
    const keep = shared.length ? `Keep the tiles they share (${list(shared.map(spokenName))})` : "They share no tiles";
    summary = anyDead
      ? `Torn between ${list(names)}. ${keep}, pass what fits none of them, and let ${sectionName(givingUp)} go first if nothing arrives for it.`
      : `Torn between ${list(names)}. ${keep}, and every tile fits one of them, so start by letting ${sectionName(givingUp)}, the weakest, go.`;
  } else if (names.length) {
    summary = `Nothing stands out yet, though ${names[0]} has the most to build on. Keep your jokers and pairs and pass the loosest tiles.`;
  } else {
    summary = "No section stands out yet. Keep your jokers and pairs and pass the loosest tiles.";
  }
  return {
    tiles, read, shortlist, headline, summary, sections, counts,
    picks, passes: picks.map((p) => p.tile), spare, passNote,
    // From the tiles kept after the pass, so a passed tile is never an anchor
    // or a tile to hope for.
    anchors: anchorsFor(kept, lead),
    hope: hopeFor(kept, lead).filter((t) => !picks.some((p) => p.tile === t)),
    jokerNote: jokerNoteFor(counts.jokers, lead),
  };
}
