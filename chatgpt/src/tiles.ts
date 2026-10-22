// Tile codes match the app's `Tile.shortLabel` and the exported content:
// 1C-9C craks, 1B-9B bams, 1D-9D dots, N E W S winds, RD GD SO dragons,
// F flower, J joker.

export type TileCode = string;

const SUITS: Record<string, string> = { C: "Crak", B: "Bam", D: "Dot" };
const WINDS: Record<string, string> = { N: "North", E: "East", W: "West", S: "South" };
const DRAGONS: Record<string, string> = { RD: "Red Dragon", GD: "Green Dragon", SO: "Soap" };
const has = (table: Record<string, string>, key: string) => Object.hasOwn(table, key);

/// The 42 kinds of tile in an American set, as canonical codes.
export const ALL_TILES: TileCode[] = [
  ...["C", "B", "D"].flatMap((s) => [1, 2, 3, 4, 5, 6, 7, 8, 9].map((r) => `${r}${s}`)),
  "N", "E", "W", "S", "RD", "GD", "SO", "F", "J",
];
const CANONICAL = new Set(ALL_TILES);

export function isTile(code: unknown): code is TileCode {
  return typeof code === "string" && CANONICAL.has(code);
}

export function isSuited(code: TileCode): boolean {
  return /^[1-9][CBD]$/.test(code);
}

export function rank(code: TileCode): number | null {
  return isSuited(code) ? Number(code[0]) : null;
}

export function isHonor(code: TileCode): boolean {
  return has(WINDS, code) || has(DRAGONS, code);
}

export function spokenName(code: TileCode): string {
  if (isSuited(code)) return `${code[0]} ${SUITS[code[1]]}`;
  if (has(WINDS, code)) return `${WINDS[code]} Wind`;
  if (has(DRAGONS, code)) return DRAGONS[code];
  return code === "F" ? "Flower" : "Joker";
}

/// Same order players rack in: craks, bams, dots, dragons, winds, flowers, jokers.
function sortKey(code: TileCode): number {
  if (isSuited(code)) return "CBD".indexOf(code[1]) * 10 + Number(code[0]);
  if (has(DRAGONS, code)) return 30 + ["RD", "GD", "SO"].indexOf(code);
  if (has(WINDS, code)) return 40 + ["N", "E", "W", "S"].indexOf(code);
  return code === "F" ? 50 : 60;
}

export function racked(tiles: TileCode[]): TileCode[] {
  return [...tiles].sort((a, b) => sortKey(a) - sortKey(b));
}

// Words people use for one tile. Maps, not objects, so "constructor" and
// "__proto__" are just unknown words.
const NAMES = new Map<string, TileCode>(Object.entries({
  n: "N", north: "N", e: "E", east: "E", w: "W", west: "W", s: "S", south: "S",
  rd: "RD", red: "RD", chung: "RD", gd: "GD", green: "GD", fa: "GD",
  so: "SO", soap: "SO", soaps: "SO", white: "SO", wd: "SO", zero: "SO",
  f: "F", flower: "F", flowers: "F", season: "F", seasons: "F",
  j: "J", joker: "J", jokers: "J", wild: "J",
  bird: "1B", sparrow: "1B",
}));

// Two-word names: "north wind", "red dragon", "white dragon".
const PAIRED = new Map<string, TileCode>(Object.entries({
  "north wind": "N", "east wind": "E", "west wind": "W", "south wind": "S",
  "red dragon": "RD", "green dragon": "GD", "white dragon": "SO", "soap dragon": "SO",
  "dragon red": "RD", "dragon green": "GD", "dragon white": "SO",
}));

const SUIT_WORDS = new Map<string, string>(Object.entries({
  c: "C", crak: "C", craks: "C", crack: "C", cracks: "C", character: "C", characters: "C", char: "C", wan: "C",
  b: "B", bam: "B", bams: "B", bamboo: "B", bamboos: "B", stick: "B", sticks: "B",
  d: "D", dot: "D", dots: "D", circle: "D", circles: "D", ball: "D", balls: "D",
}));

const NUMBER_WORDS = new Map<string, number>(
  ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine"].map((w, i) => [w, i + 1]),
);

// Words that carry no tile, as in "my rack is 2C, 4C and a joker".
const FILLER = new Set(["and", "a", "an", "the", "of", "my", "rack", "tiles", "tile", "is", "are", "i", "have", "hold", "plus", "with"]);

// Unicode mahjong tiles, U+1F000 to U+1F02A.
const EMOJI = new Map<number, TileCode>([
  [0x1f000, "E"], [0x1f001, "S"], [0x1f002, "W"], [0x1f003, "N"],
  [0x1f004, "RD"], [0x1f005, "GD"], [0x1f006, "SO"],
  ...[1, 2, 3, 4, 5, 6, 7, 8, 9].flatMap((r) => [
    [0x1f006 + r, `${r}C`], [0x1f00f + r, `${r}B`], [0x1f018 + r, `${r}D`],
  ] as [number, TileCode][]),
  ...[0x1f022, 0x1f023, 0x1f024, 0x1f025, 0x1f026, 0x1f027, 0x1f028, 0x1f029].map((c) => [c, "F"] as [number, TileCode]),
  [0x1f02a, "J"],
]);

/** Longest text kept from one unreadable entry when it is echoed back. */
const ECHO_MAX = 24;

function numberOf(token: string): number | null {
  if (/^[1-9]$/.test(token)) return Number(token);
  return NUMBER_WORDS.get(token) ?? null;
}

/// One token that is a whole tile on its own: "5d", "c5", "f3", "north",
/// or a run of codes typed together, "2c2c4c".
function codesIn(token: string): TileCode[] | null {
  const named = NAMES.get(token);
  if (named) return [named];
  if (/^f[1-8]$/.test(token)) return ["F"];
  const flipped = token.match(/^([cbd])([1-9])$/);
  if (flipped) return [`${flipped[2]}${flipped[1].toUpperCase()}`];
  const glued = token.match(/^([1-9])([a-z]+)$/);
  if (glued && SUIT_WORDS.has(glued[2])) return [`${glued[1]}${SUIT_WORDS.get(glued[2])}`];
  if (/^(?:[1-9][cbd]|rd|gd|so|wd|[newsfj])+$/.test(token) && token.length > 2) {
    const codes = token.match(/[1-9][cbd]|rd|gd|so|wd|[newsfj]/g)!;
    return codes.map((c) => NAMES.get(c) ?? c.toUpperCase());
  }
  return null;
}

/// Splits one entry into tokens, turning tile emoji into codes first.
function tokens(raw: string): string[] {
  const text = [...raw.normalize("NFKC")]
    .map((ch) => {
      const emoji = EMOJI.get(ch.codePointAt(0)!);
      return emoji ? ` ${emoji} ` : ch;
    })
    .join("")
    .replace(/[​-‏‪-‮⁠-⁤︎️'’]/g, "")
    .replace(/×/g, " x ")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
  return text ? text.split(" ") : [];
}

export type ParsedRack = { tiles: TileCode[]; unreadable: string[]; tooMany: TileCode[] };

const echo = (s: string) => (s.length > ECHO_MAX ? `${s.slice(0, ECHO_MAX)}…` : s);

/// Reads a rack written the way people type it, one tile per entry or the
/// whole rack in one string: "5D", "5 dot", "five dots", "dot 5", "2C2C",
/// "soap", "North Wind", "F3", tile emoji. Number words split from their suit
/// across entries ("5", "dot") still pair up. Flags anything impossible in an
/// American set: four of each tile, eight flowers, eight jokers.
export function parseRack(raw: string[]): ParsedRack {
  const words = raw.flatMap(tokens);
  const tiles: TileCode[] = [];
  const unreadable: string[] = [];
  for (let i = 0; i < words.length; i++) {
    const [a, b, c] = [words[i], words[i + 1], words[i + 2]];
    const n = numberOf(a);
    // "5 dot", "five of dots", "1 bird"
    if (n !== null && b && SUIT_WORDS.has(b)) { tiles.push(`${n}${SUIT_WORDS.get(b)}`); i += 1; continue; }
    if (n !== null && b === "of" && c && SUIT_WORDS.has(c)) { tiles.push(`${n}${SUIT_WORDS.get(c)}`); i += 2; continue; }
    if (n === 1 && (b === "bird" || b === "sparrow")) { tiles.push("1B"); i += 1; continue; }
    // "dot 5", "bam five"
    const m = b ? numberOf(b) : null;
    if (SUIT_WORDS.has(a) && a.length > 1 && m !== null) { tiles.push(`${m}${SUIT_WORDS.get(a)}`); i += 1; continue; }
    // "3 jokers", "two flowers", "2 north": a count before a tile that has no number
    const counted = n !== null && b ? (PAIRED.get(`${b} ${c}`) ?? codesIn(b)?.[0]) : undefined;
    if (counted && !isSuited(counted) && n! <= 8) {
      tiles.push(...Array(n!).fill(counted));
      i += PAIRED.has(`${b} ${c}`) ? 2 : 1;
      continue;
    }
    // "2C x2", "N x 3": repeats the tile before it
    const times = a.match(/^x([1-8])$/)?.[1] ?? (a === "x" && b && /^[1-8]$/.test(b) ? b : null);
    if (times && tiles.length) {
      tiles.push(...Array(Number(times) - 1).fill(tiles[tiles.length - 1]));
      if (a === "x") i += 1;
      continue;
    }
    // "north wind", "red dragon"
    const paired = b ? PAIRED.get(`${a} ${b}`) : undefined;
    if (paired) { tiles.push(paired); i += 1; continue; }
    const codes = codesIn(a);
    if (codes) { tiles.push(...codes); continue; }
    if (!FILLER.has(a)) unreadable.push(echo(a));
  }
  const counts = countTiles(tiles);
  const tooMany = Object.entries(counts)
    .filter(([code, k]) => k > (code === "F" || code === "J" ? 8 : 4))
    .map(([code]) => code);
  return { tiles: racked(tiles.filter(isTile)), unreadable, tooMany };
}

export function countTiles(tiles: TileCode[]): Record<TileCode, number> {
  const counts: Record<TileCode, number> = Object.create(null);
  for (const tile of tiles) counts[tile] = (counts[tile] ?? 0) + 1;
  return counts;
}
