// Reads a rack against the nine stable card sections. Ported from the app's
// RackGenerator (fits, missNote, explain) so the plugin and the app give the
// same read. Every statement is about the SHAPE of a section and holds on any
// year's card; nothing here names or copies a hand from the NMJL card.
import { content } from "./content.ts";
import { countTiles, isHonor, isSuited, rank, spokenName, type TileCode } from "./tiles.ts";

export type SectionId =
  | "year" | "evens2468" | "likeNumbers" | "quints" | "consecutiveRun"
  | "odds13579" | "windsDragons" | "threeSixNine" | "singlesAndPairs";

export type Verdict = "fits" | "possible" | "poor" | "checkCard";

export type SectionRead = { id: SectionId; name: string; verdict: Verdict; note: string };

export type RackRead = {
  tiles: TileCode[];
  read: SectionId | null;
  headline: string;
  summary: string;
  sections: SectionRead[];
  /** Tiles that build toward nothing the rack leans to: Charleston candidates. */
  passes: TileCode[];
  counts: { jokers: number; flowers: number; honors: number; pairs: number; pungs: number };
};

const GENERATABLE: SectionId[] = ["evens2468", "odds13579", "threeSixNine", "consecutiveRun", "windsDragons"];

export function sectionName(id: SectionId): string {
  return content.categories.find((c) => c.id === id)?.displayName ?? id;
}

function ranksOf(tiles: TileCode[]): number[] {
  return [...new Set(tiles.map(rank).filter((r): r is number => r !== null))].sort((a, b) => a - b);
}

function subset(ranks: number[], allowed: number[]): boolean {
  return ranks.every((r) => allowed.includes(r));
}

function plural(ranks: number[]): string {
  const words = ranks.map((r) => `${r}s`);
  if (words.length <= 1) return words[0] ?? "";
  return `${words.slice(0, -1).join(", ")} and ${words[words.length - 1]}`;
}

export function fits(tiles: TileCode[], id: SectionId): boolean {
  const ranks = ranksOf(tiles);
  const honors = tiles.some(isHonor);
  switch (id) {
    case "windsDragons":
      return honors && !tiles.some(isSuited);
    case "evens2468":
      return !honors && ranks.length >= 2 && subset(ranks, [2, 4, 6, 8]);
    case "odds13579":
      return !honors && ranks.length >= 2 && subset(ranks, [1, 3, 5, 7, 9]);
    case "threeSixNine":
      return !honors && subset(ranks, [3, 6, 9]) && ranks.includes(6) && (ranks.includes(3) || ranks.includes(9));
    case "consecutiveRun": {
      if (honors || ranks.length < 3) return false;
      return ranks[ranks.length - 1] - ranks[0] === ranks.length - 1;
    }
    default:
      return false;
  }
}

function explain(tiles: TileCode[], id: SectionId): string {
  const list = ranksOf(tiles).join(", ");
  switch (id) {
    case "evens2468":
      return `Every number on this rack is even (${list}), with no honors at all. That is 2468 territory, and every odd tile you pick up is dead weight for it.`;
    case "odds13579":
      return `Every number here is odd (${list}). That points straight at 13579, the mirror image of the evens section.`;
    case "threeSixNine":
      return "Every number here is a 3, 6 or 9. The 6 rules out a pure odds hand and the 3 or 9 rules out a pure evens hand, so 369 is the read.";
    case "consecutiveRun":
      return `The numbers step up in order (${list}). A run mixes odd and even by definition, so it cannot be an evens or odds hand: this is a Consecutive Run.`;
    default:
      return "Nothing but winds and dragons, with no numbered tiles anywhere. When honors pile up like this, Winds and Dragons is where to look.";
  }
}

/// Why a section does not fit, or null when nothing on the rack rules it out.
function ruledOut(tiles: TileCode[], id: SectionId): string | null {
  const ranks = ranksOf(tiles);
  const name = sectionName(id);
  const noNumbers = `This rack has no numbered tiles at all, and ${name} is built from numbers.`;
  const numbered = tiles.filter(isSuited).length;
  switch (id) {
    case "evens2468": {
      if (ranks.length === 0) return noNumbers;
      const odd = ranks.filter((r) => r % 2 === 1);
      return odd.length ? `This rack holds ${plural(odd)}, and a finished 2468 hand never uses an odd number.` : null;
    }
    case "odds13579": {
      if (ranks.length === 0) return noNumbers;
      const even = ranks.filter((r) => r % 2 === 0);
      return even.length ? `This rack holds ${plural(even)}, and a finished 13579 hand never uses an even number.` : null;
    }
    case "threeSixNine": {
      if (ranks.length === 0) return noNumbers;
      const outside = ranks.filter((r) => r % 3 !== 0);
      if (outside.length) return `This rack holds ${plural(outside)}, and a finished 369 hand never uses them.`;
      return ranks.includes(6) ? null : "There is no 6 here, and 369 needs the 6 to read as anything other than odds.";
    }
    case "consecutiveRun": {
      if (ranks.length === 0) return "A run is all numbers stepping up in order, and this rack has no numbered tiles.";
      if (ranks.length < 3) return `A run steps up with no gaps, and this rack only has ${plural(ranks)}.`;
      const threeInARow = ranks.some((r) => ranks.includes(r + 1) && ranks.includes(r + 2));
      return threeInARow ? null : `The numbers here (${ranks.join(", ")}) never make three in a row, and a run steps up with no gaps.`;
    }
    case "windsDragons": {
      const honors = tiles.filter(isHonor).length;
      const honorCount = honors === 0 ? "no winds or dragons" : honors === 1 ? "only one wind or dragon" : `only ${honors} winds or dragons`;
      return numbered > honors ? `This rack has ${numbered} numbered tiles and ${honorCount}, so it has little to build a Winds & Dragons hand from.` : null;
    }
    case "likeNumbers": {
      if (ranks.length === 0) return noNumbers;
      if (numbered < 5) return `Like Numbers is built from one number in several suits, and this rack has only ${numbered} number tile${numbered === 1 ? "" : "s"}.`;
      return ranks.length >= 3 ? `Like Numbers repeats one number across the suits, and this rack spreads across ${plural(ranks)}.` : null;
    }
    case "quints": {
      const jokers = tiles.filter((t) => t === "J").length;
      return jokers < 2 ? `Quints need five of a kind, which takes jokers, and this rack has ${jokers === 0 ? "none" : "just one"}.` : null;
    }
    case "singlesAndPairs": {
      const counts = countTiles(tiles.filter((t) => t !== "J" && t !== "F"));
      const pung = Object.entries(counts).filter(([, n]) => n >= 3).map(([t]) => spokenName(t)).sort()[0];
      if (pung) return `This rack holds three or more ${pung}, and Singles & Pairs never uses a pung.`;
      return tiles.includes("J") ? "Singles & Pairs never takes jokers, so the joker on this rack could not help it." : null;
    }
    case "year":
      if (ranks.length === 0) return noNumbers;
      // Every 20XX year has a 2 and a zero, and soaps stand in for zeros.
      return tiles.includes("SO") || ranks.includes(2) ? null : "Year hands are built from the year's digits with soaps for zeros, and this rack has no soaps and no 2s.";
  }
}

/// One number held in two or more suits, at least four tiles of it.
function likeNumberSignal(tiles: TileCode[]): string | null {
  for (const r of ranksOf(tiles)) {
    const copies = tiles.filter((t) => rank(t) === r);
    const suits = new Set(copies.map((t) => t[1]));
    if (copies.length >= 4 && suits.size >= 2) {
      return `You hold ${copies.length} ${r}s across ${suits.size} suits, which is how a Like Numbers hand starts.`;
    }
  }
  return null;
}

function readSection(tiles: TileCode[], id: SectionId, read: SectionId | null): SectionRead {
  const name = sectionName(id);
  if (GENERATABLE.includes(id) && fits(tiles, id)) {
    return { id, name, verdict: "fits", note: explain(tiles, id) };
  }
  if (id === "likeNumbers") {
    const signal = likeNumberSignal(tiles);
    if (signal) return { id, name, verdict: "possible", note: signal };
  }
  const reason = ruledOut(tiles, id);
  if (reason) return { id, name, verdict: "poor", note: reason };
  if (id === "year") {
    return { id, name, verdict: "checkCard", note: "Year hands use this year's digits, with soaps standing in for zeros. Check the year line on your card against your 2s and soaps." };
  }
  const scored = ["evens2468", "odds13579", "threeSixNine", "consecutiveRun", "likeNumbers"].includes(id);
  const backing = support(tiles, id).length;
  if (scored && backing < 6) {
    return { id, name, verdict: "poor", note: `Only ${backing} of your tiles build toward ${name}.` };
  }
  const leans = read ? `, but more of them point to ${sectionName(read)}` : "";
  return { id, name, verdict: "possible", note: `${name} could use some of these tiles${leans}.` };
}

const isDragon = (t: TileCode) => t === "RD" || t === "GD" || t === "SO";
const isWind = (t: TileCode) => t === "N" || t === "E" || t === "W" || t === "S";

/// The tiles on this rack that build toward a section, for the sections a
/// real 13-tile deal can lean toward. Strays are expected: a dealt rack is
/// never clean, which is what the Charleston is for.
function support(tiles: TileCode[], id: SectionId): TileCode[] {
  const inRanks = (allowed: number[]) => tiles.filter((t) => allowed.includes(rank(t) ?? 0));
  switch (id) {
    case "evens2468":
      return inRanks([2, 4, 6, 8]);
    case "odds13579":
      return inRanks([1, 3, 5, 7, 9]);
    case "threeSixNine": {
      const ranks = ranksOf(tiles);
      return ranks.includes(6) && (ranks.includes(3) || ranks.includes(9)) ? inRanks([3, 6, 9]) : [];
    }
    case "windsDragons":
      return tiles.filter(isHonor);
    case "consecutiveRun": {
      let best: TileCode[] = [];
      for (let low = 1; low <= 7; low++) {
        let high = low;
        // Run hands on the card span at most five numbers in a row.
        while (high - low < 4 && ranksOf(tiles).includes(high + 1) && ranksOf(tiles).includes(low)) high++;
        if (high - low < 2) continue;
        const block = tiles.filter((t) => (rank(t) ?? 0) >= low && (rank(t) ?? 0) <= high);
        if (block.length > best.length) best = block;
      }
      return best;
    }
    case "likeNumbers": {
      let best: TileCode[] = [];
      for (const r of ranksOf(tiles)) {
        const copies = tiles.filter((t) => rank(t) === r);
        if (new Set(copies.map((t) => t[1])).size >= 2 && copies.length > best.length) best = copies;
      }
      return best;
    }
    default:
      return [];
  }
}

/// The section a rack clearly leans toward, or null. Number sections count
/// against winds but not dragons, because number hands often carry a dragon.
function lean(tiles: TileCode[], counts: RackRead["counts"]): SectionId | null {
  if (counts.pairs >= 5 && counts.pungs === 0 && counts.jokers === 0) return "singlesAndPairs";
  const like = support(tiles, "likeNumbers");
  if (like.length >= 6) return "likeNumbers";

  const candidates: SectionId[] = ["evens2468", "odds13579", "threeSixNine", "consecutiveRun", "windsDragons", "likeNumbers"];
  const scored = candidates
    .map((id) => {
      const countable = tiles.filter((t) => isSuited(t) || isWind(t) || (id === "windsDragons" && isDragon(t))).length;
      const size = support(tiles, id).length;
      return { id, size, share: countable ? size / countable : 0 };
    })
    .sort((a, b) => b.size - a.size);
  const [best, second] = scored;
  if (best.size < 4 || best.share < 0.6 || best.size - (second?.size ?? 0) < 3) return null;
  return best.id;
}

/// Tiles worth passing: they build toward nothing the rack leans to. Jokers
/// never pass, flowers stay early, and dragons are left to the player because
/// many number hands use one.
function strays(tiles: TileCode[], leaning: SectionId | null, wdPoor: boolean): TileCode[] {
  if (leaning === "singlesAndPairs") return [];
  if (!leaning) return wdPoor ? tiles.filter(isWind) : [];
  const keep = [...support(tiles, leaning)];
  return tiles.filter((t) => {
    if (t === "J" || t === "F" || (isDragon(t) && leaning !== "windsDragons")) return false;
    const i = keep.indexOf(t);
    if (i >= 0) {
      keep.splice(i, 1);
      return false;
    }
    return true;
  });
}

function leanNote(tiles: TileCode[], id: SectionId): string {
  if (GENERATABLE.includes(id) && fits(tiles, id)) return explain(tiles, id);
  const backing = support(tiles, id).length;
  if (id === "singlesAndPairs") {
    return "Nothing but pairs and singles, with no pungs and no jokers. That is the shape of a Singles & Pairs hand.";
  }
  if (id === "likeNumbers") {
    const r = rank(support(tiles, id)[0]);
    return `${backing} of your tiles are ${r}s spread across the suits, which reads as Like Numbers.`;
  }
  return `${backing} of your tiles build toward ${sectionName(id)}.`;
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
  const read = lean(tiles, counts);
  const wdPoor = ruledOut(tiles, "windsDragons") !== null;
  const passes = strays(tiles, read, wdPoor);

  const order: Record<Verdict, number> = { fits: 0, possible: 1, checkCard: 2, poor: 3 };
  const ids = content.categories.map((c) => c.id as SectionId);
  const sections = ids
    .map((id) => (id === read ? { id, name: sectionName(id), verdict: "fits" as Verdict, note: leanNote(tiles, id) } : readSection(tiles, id, read)))
    .sort((a, b) => order[a.verdict] - order[b.verdict]);

  const open = sections
    .filter((s) => s.verdict !== "poor")
    .map((s) => (s.verdict === "checkCard" ? `${s.name} (check your card)` : s.name));
  const others = open.filter((name) => name !== (read && sectionName(read)));
  const summary = read
    ? `Leaning ${sectionName(read)}.${others.length ? ` Still open: ${others.join(", ")}.` : ""}`
    : open.length
      ? `No clear section yet. Still open: ${open.join(", ")}.`
      : "No section stands out yet. Keep your jokers and pairs and pass what fits nothing.";

  const headline = read ? `Leaning ${sectionName(read)}` : "No clear section yet";
  return { tiles, read, headline, summary, sections, counts, passes };
}
