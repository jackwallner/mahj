// Reads a dealt rack the way a coach does: count the tiles that build toward
// each stable section of the card, shortlist the strongest, and pass what fits
// none of them. Strays are expected, since a dealt rack is never clean, which
// is what the Charleston is for. Every statement is about the SHAPE of a
// section and holds on any year's card; nothing here names or copies a hand
// from the NMJL card.
import { content } from "./content.ts";
import { countTiles, isHonor, isSuited, rank, spokenName, type TileCode } from "./tiles.ts";

export type SectionId =
  | "year" | "evens2468" | "likeNumbers" | "quints" | "consecutiveRun"
  | "odds13579" | "windsDragons" | "threeSixNine" | "singlesAndPairs";

export type Verdict = "fits" | "possible" | "poor";

export type SectionRead = { id: SectionId; name: string; verdict: Verdict; note: string };

export type RackRead = {
  tiles: TileCode[];
  /** The section the rack clearly leans to, or null when it is torn or scattered. */
  read: SectionId | null;
  /** The two or three sections worth keeping in mind, strongest first. */
  shortlist: SectionId[];
  headline: string;
  summary: string;
  sections: SectionRead[];
  /** The coach's next pass: up to three tiles that fit nothing on the shortlist. */
  passes: TileCode[];
  /** Further tiles that can go on later passes. */
  spare: TileCode[];
  counts: { jokers: number; flowers: number; honors: number; pairs: number; pungs: number };
};

type Support = { id: SectionId; tiles: TileCode[] };

const isDragon = (t: TileCode) => t === "RD" || t === "GD" || t === "SO";
const isWind = (t: TileCode) => t === "N" || t === "E" || t === "W" || t === "S";

export function sectionName(id: SectionId): string {
  return content.categories.find((c) => c.id === id)?.displayName ?? id;
}

/// The card in play: a new one comes out each April.
export function cardYear(now = new Date()): number {
  return now.getUTCMonth() >= 3 ? now.getUTCFullYear() : now.getUTCFullYear() - 1;
}

function yearDigits(): number[] {
  return [...new Set(String(cardYear()).split("").map(Number).filter((d) => d > 0))];
}

function ranksOf(tiles: TileCode[]): number[] {
  return [...new Set(tiles.map(rank).filter((r): r is number => r !== null))].sort((a, b) => a - b);
}

const inRanks = (tiles: TileCode[], allowed: number[]) => tiles.filter((t) => allowed.includes(rank(t) ?? 0));

function list(words: string[]): string {
  return words.length <= 1 ? (words[0] ?? "") : `${words.slice(0, -1).join(", ")} and ${words[words.length - 1]}`;
}

/// Run hands span at most five numbers in a row. A stretch counts in full when
/// one suit holds three numbers in a row inside it; otherwise only tiles with
/// a same-suit neighbor count, so evens in one suit and odds in another never
/// pass for a run.
function runStretch(tiles: TileCode[]): { tiles: TileCode[]; low: number; chain: string | null } {
  const has = (r: number, suit: string) => tiles.includes(`${r}${suit}`);
  let best = { tiles: [] as TileCode[], low: 1, chain: null as string | null };
  for (let low = 1; low <= 5; low++) {
    const high = low + 4;
    const block = tiles.filter((t) => isSuited(t) && rank(t)! >= low && rank(t)! <= high);
    const chain = longestChain(block, low, high);
    const counted = chain
      ? block
      : block.filter((t) => [rank(t)! - 1, rank(t)! + 1].some((r) => r >= low && r <= high && has(r, t[1])));
    if (counted.length > best.tiles.length) best = { tiles: counted, low, chain };
  }
  return best;
}

/// The longest same-suit numbers-in-a-row inside a stretch, three or more,
/// as "1-2-3-4-5 Crak".
function longestChain(block: TileCode[], low: number, high: number): string | null {
  let best: { suit: string; from: number; to: number } | null = null;
  for (const suit of "CBD") {
    for (let from = low; from <= high; from++) {
      let to = from;
      while (to + 1 <= high && block.includes(`${to + 1}${suit}`) && block.includes(`${from}${suit}`)) to++;
      if (block.includes(`${from}${suit}`) && to - from >= 2 && (!best || to - from > best.to - best.from)) best = { suit, from, to };
    }
  }
  if (!best) return null;
  const nums = Array.from({ length: best.to - best.from + 1 }, (_, i) => best!.from + i).join("-");
  return `${nums} ${spokenName(`1${best.suit}`).split(" ")[1]}`;
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

/// Natural groups of three or more, which jokers can stretch to a quint.
function pungTiles(tiles: TileCode[]): TileCode[] {
  const counts = countTiles(tiles.filter((t) => t !== "J" && t !== "F"));
  return tiles.filter((t) => (counts[t] ?? 0) >= 3);
}

function support(tiles: TileCode[], id: SectionId): TileCode[] {
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
    case "quints": {
      const jokers = tiles.filter((t) => t === "J");
      const groups = pungTiles(tiles);
      return jokers.length >= 2 && groups.length ? [...groups, ...jokers] : [];
    }
    case "singlesAndPairs":
      return [];
  }
}

const SCORED: SectionId[] = ["evens2468", "odds13579", "threeSixNine", "consecutiveRun", "likeNumbers", "windsDragons", "year", "quints"];

/// Share of the rack a section uses. Jokers and flowers are neutral, and
/// number sections ignore dragons because many number hands carry one.
function share(tiles: TileCode[], s: Support): number {
  const countable = tiles.filter((t) => isSuited(t) || isWind(t) || (isDragon(t) && (s.id === "windsDragons" || s.id === "year"))).length;
  return countable ? s.tiles.length / countable : 0;
}

function choose(tiles: TileCode[], counts: RackRead["counts"]): { read: SectionId | null; shortlist: SectionId[] } {
  if (counts.pairs >= 5 && counts.pungs === 0 && counts.jokers === 0) return { read: "singlesAndPairs", shortlist: ["singlesAndPairs"] };
  const scored = SCORED.map((id) => ({ id, tiles: support(tiles, id) }))
    .filter((s) => s.tiles.length >= 3)
    .sort((a, b) => b.tiles.length - a.tiles.length);
  // Two natural pungs plus jokers is a quint hand before it is anything else.
  if (counts.pungs >= 2 && scored[0]?.id === "quints") return { read: "quints", shortlist: ["quints"] };
  const like = likeGroup(tiles);
  if (like.tiles.length >= 6 || (like.tiles.length >= 5 && like.suits === 3)) return { read: "likeNumbers", shortlist: ["likeNumbers"] };

  const [best, second] = scored;
  if (!best) return { read: null, shortlist: [] };
  // A runner-up needs real backing to be worth saving tiles for.
  const shortlist = scored.filter((s) => s === best || (s.tiles.length >= 4 && s.tiles.length >= best.tiles.length - 2)).slice(0, 3).map((s) => s.id);
  // A one-tile edge is a lean only on a well-built rack; otherwise it is torn.
  const gap = best.tiles.length - (second?.tiles.length ?? 0);
  const clear = best.tiles.length >= 5 && share(tiles, best) >= 0.4 && (gap >= 2 || (gap === 1 && best.tiles.length >= 7));
  return { read: clear ? best.id : null, shortlist };
}

/// Why a section is a long shot for this rack.
function longShot(tiles: TileCode[], id: SectionId, counts: RackRead["counts"]): string {
  const n = support(tiles, id).length;
  const name = sectionName(id);
  switch (id) {
    case "year":
      return tiles.includes("SO") ? `Only ${n} of your tiles are the year's digits or soaps.` : "Year hands use soaps for the zeros, and this rack has none.";
    case "quints":
      if (counts.jokers < 2) return `Five of a kind takes jokers, and this rack has ${counts.jokers === 0 ? "none" : "just one"}.`;
      return "Quints need a natural pung to build on, and this rack has none yet.";
    case "threeSixNine":
      return ranksOf(tiles).includes(6) ? `Only ${n} of your tiles are 3s, 6s or 9s.` : "369 needs 6s to stand apart from an odds hand, and this rack has none.";
    case "consecutiveRun":
      return n ? `Only ${n} of your tiles step up in order.` : "No suit here holds numbers in a row.";
    case "likeNumbers":
      return "No number shows up across the suits often enough.";
    case "windsDragons":
      return `Only ${n} winds or dragons.`;
    case "singlesAndPairs": {
      const pung = Object.entries(countTiles(tiles.filter((t) => t !== "J" && t !== "F"))).find(([, c]) => c >= 3)?.[0];
      if (pung) return `Singles & Pairs never uses a pung, and you hold three ${spokenName(pung)}s.`;
      return `Only ${counts.pairs} natural pair${counts.pairs === 1 ? "" : "s"}, and Singles & Pairs is built from pairs.`;
    }
    default:
      return `Only ${n} of your tiles build toward ${name}.`;
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
      return `${n} of your tiles sit in the stretch ${run.low} to ${run.low + 4}${run.chain ? `, including ${run.chain}` : ""}.`;
    }
    case "likeNumbers": {
      const like = likeGroup(tiles);
      const count = ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"][like.tiles.length];
      return `You hold ${count} ${like.rank}s across ${like.suits === 3 ? "all three" : "two"} suits.`;
    }
    case "windsDragons":
      return `${n} of your tiles are winds or dragons.`;
    case "year":
      return `${n} of your tiles are the year's digits (${yearDigits().join(" and ")}) or soaps for the zeros. Check the year line on your card.`;
    case "quints":
      return `${counts.jokers} jokers and a natural pung to stretch: jokers are the only way to five of a kind.`;
    case "singlesAndPairs": {
      const flowers = counts.flowers === 2 ? " (plus a pair of flowers)" : "";
      return `${counts.pairs} natural pairs${flowers}, no pungs and no jokers. It works only if the pairs line up with a line on your card.`;
    }
  }
}

function verdictFor(tiles: TileCode[], id: SectionId, read: SectionId | null, shortlist: SectionId[], counts: RackRead["counts"]): SectionRead {
  const name = sectionName(id);
  if (id === read) return { id, name, verdict: "fits", note: strength(tiles, id, counts) };
  if (shortlist.includes(id)) return { id, name, verdict: "possible", note: strength(tiles, id, counts) };
  if (id === "singlesAndPairs" && counts.pairs >= 4 && counts.pungs === 0) {
    const jokers = counts.jokers ? " Your jokers could not help it, though." : "";
    return { id, name, verdict: "possible", note: `${counts.pairs} natural pairs and no pungs.${jokers}` };
  }
  if (id === "quints" && support(tiles, id).length) return { id, name, verdict: "possible", note: strength(tiles, id, counts) };
  return { id, name, verdict: "poor", note: longShot(tiles, id, counts) };
}

/// The order a coach passes in: tiles that also fit a shortlisted section go
/// last, pairs are not broken while singles remain, then lone winds before
/// numbers before dragons (many number hands carry a dragon), and 1s and 9s
/// before middle numbers.
function passOrder(tiles: TileCode[], keepAlso: TileCode[]) {
  const counts = countTiles(tiles);
  return (t: TileCode) => [
    keepAlso.includes(t) ? 1 : 0,
    (counts[t] ?? 0) >= 2 ? 1 : 0,
    isWind(t) ? 0 : isSuited(t) ? 1 : 2,
    isSuited(t) ? -Math.abs(rank(t)! - 5) : 0,
  ];
}

function compare(a: number[], b: number[]): number {
  for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return a[i] - b[i];
  return 0;
}

/// Removes one copy of each tile in `used` from `tiles`.
function without(tiles: TileCode[], used: TileCode[]): TileCode[] {
  const left = [...used];
  return tiles.filter((t) => {
    const i = left.indexOf(t);
    if (i < 0) return true;
    left.splice(i, 1);
    return false;
  });
}

/// Jokers never pass and flowers stay early. With a clear lean, everything
/// outside it can go, saving tiles a close second could use for last. Torn
/// between sections, pass what fits none of them first.
function passes(tiles: TileCode[], read: SectionId | null, shortlist: SectionId[]): { passes: TileCode[]; spare: TileCode[] } {
  if (read === "singlesAndPairs" || (!read && !shortlist.length)) {
    const strays = tiles.filter(isWind).filter((t) => tiles.filter((x) => x === t).length === 1);
    return { passes: strays.slice(0, 3), spare: strays.slice(3) };
  }
  const core = read ? [read] : shortlist;
  const rest = read ? shortlist.filter((id) => id !== read) : [];
  let pool = tiles.filter((t) => t !== "J" && t !== "F");
  for (const id of core) {
    const own = support(tiles, id);
    pool = pool.filter((t) => !own.includes(t));
  }
  const keepAlso = rest.flatMap((id) => support(tiles, id));
  const order = passOrder(tiles, keepAlso);
  let ranked = pool.sort((a, b) => compare(order(a), order(b)));
  // Torn and short of three: let the weakest shortlisted section go first.
  if (!read && ranked.length < 3 && shortlist.length > 1) {
    const weakest = shortlist[shortlist.length - 1];
    const others = shortlist.slice(0, -1).flatMap((id) => support(tiles, id));
    const extra = without(support(tiles, weakest), others).filter((t) => !ranked.includes(t));
    ranked = [...ranked, ...extra.sort((a, b) => compare(order(a), order(b)))];
  }
  return { passes: ranked.slice(0, 3), spare: ranked.slice(3) };
}

export function readRack(tiles: TileCode[]): RackRead {
  const grouped = countTiles(tiles.filter((t) => t !== "J" && t !== "F"));
  const counts = {
    jokers: tiles.filter((t) => t === "J").length,
    flowers: tiles.filter((t) => t === "F").length,
    honors: tiles.filter(isHonor).length,
    pairs: Object.values(grouped).filter((n) => n === 2).length,
    pungs: Object.values(grouped).filter((n) => n >= 3).length,
  };
  const { read, shortlist } = choose(tiles, counts);
  const order: Record<Verdict, number> = { fits: 0, possible: 1, poor: 2 };
  const rankInList = (id: SectionId) => (shortlist.includes(id) ? shortlist.indexOf(id) : 9);
  const sections = content.categories
    .map((c) => verdictFor(tiles, c.id as SectionId, read, shortlist, counts))
    .sort((a, b) => order[a.verdict] - order[b.verdict] || rankInList(a.id) - rankInList(b.id));
  const pass = passes(tiles, read, shortlist);

  const names = shortlist.map(sectionName);
  const others = names.filter((n) => !read || n !== sectionName(read));
  const headline = read
    ? `Leaning ${sectionName(read)}`
    : names.length >= 2 ? `Torn between ${list(names)}` : names.length ? `Maybe ${names[0]}` : "No clear section yet";
  const summary = read
    ? `Leaning ${sectionName(read)}: ${strength(tiles, read, counts)}${others.length ? ` Also in reach: ${list(others)}.` : ""}`
    : names.length >= 2
      ? `Torn between ${list(names)}. Keep the tiles they share and pass what fits none of them.`
      : names.length
        ? `Nothing stands out yet, though ${names[0]} has the most to build on. Keep your jokers and pairs and pass what fits nothing.`
        : "No section stands out yet. Keep your jokers and pairs and pass what fits nothing.";
  return { tiles, read, shortlist, headline, summary, sections, counts, ...pass };
}
