// Tile codes match the app's `Tile.shortLabel` and the exported content:
// 1C-9C craks, 1B-9B bams, 1D-9D dots, N E W S winds, RD GD SO dragons,
// F flower, J joker.

export type TileCode = string;

const SUITS: Record<string, string> = { C: "Crak", B: "Bam", D: "Dot" };
const WINDS: Record<string, string> = { N: "North", E: "East", W: "West", S: "South" };
const DRAGONS: Record<string, string> = { RD: "Red Dragon", GD: "Green Dragon", SO: "Soap" };

export function isSuited(code: TileCode): boolean {
  return /^[1-9][CBD]$/.test(code);
}

export function rank(code: TileCode): number | null {
  return isSuited(code) ? Number(code[0]) : null;
}

export function isHonor(code: TileCode): boolean {
  return code in WINDS || code in DRAGONS;
}

export function spokenName(code: TileCode): string {
  if (isSuited(code)) return `${code[0]} ${SUITS[code[1]]}`;
  if (code in WINDS) return `${WINDS[code]} Wind`;
  if (code in DRAGONS) return DRAGONS[code];
  return code === "F" ? "Flower" : "Joker";
}

/// Same order players rack in: craks, bams, dots, dragons, winds, flowers, jokers.
function sortKey(code: TileCode): number {
  if (isSuited(code)) return "CBD".indexOf(code[1]) * 10 + Number(code[0]);
  if (code in DRAGONS) return 30 + ["RD", "GD", "SO"].indexOf(code);
  if (code in WINDS) return 40 + ["N", "E", "W", "S"].indexOf(code);
  return code === "F" ? 50 : 60;
}

export function racked(tiles: TileCode[]): TileCode[] {
  return [...tiles].sort((a, b) => sortKey(a) - sortKey(b));
}

const WORDS: Record<string, TileCode> = {
  north: "N", east: "E", west: "W", south: "S",
  red: "RD", "red dragon": "RD", green: "GD", "green dragon": "GD",
  soap: "SO", white: "SO", "white dragon": "SO",
  flower: "F", flowers: "F", f: "F", joker: "J", jokers: "J", j: "J",
  n: "N", e: "E", w: "W", s: "S", rd: "RD", gd: "GD", so: "SO", wd: "SO",
};

const SUIT_WORDS: Record<string, string> = {
  c: "C", crak: "C", craks: "C", crack: "C", cracks: "C", character: "C", characters: "C",
  b: "B", bam: "B", bams: "B", bamboo: "B", bamboos: "B",
  d: "D", dot: "D", dots: "D", circle: "D", circles: "D",
};

const NUMBER_WORDS = ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"];

/// Reads one tile written the way people type it: "5D", "5 dot", "soap",
/// "north", "J". Returns null when it is not a tile.
export function parseTile(raw: string): TileCode | null {
  const text = raw.trim().toLowerCase().replace(/\s+/g, " ");
  if (text in WORDS) return WORDS[text];
  const match = text.match(/^([1-9]|[a-z]+)\s?([a-z]+)$/);
  const number = match && (/^[1-9]$/.test(match[1]) ? match[1] : NUMBER_WORDS.indexOf(match[1]) > 0 ? String(NUMBER_WORDS.indexOf(match[1])) : null);
  if (match && number && match[2] in SUIT_WORDS) return `${number}${SUIT_WORDS[match[2]]}`;
  return null;
}

export type ParsedRack = { tiles: TileCode[]; unreadable: string[]; tooMany: TileCode[] };

/// Parses a rack and flags anything impossible in an American set: four of
/// each tile, eight flowers, eight jokers.
export function parseRack(raw: string[]): ParsedRack {
  const tiles: TileCode[] = [];
  const unreadable: string[] = [];
  for (const item of raw) {
    const tile = parseTile(item);
    if (tile) tiles.push(tile);
    else unreadable.push(item);
  }
  const counts = countTiles(tiles);
  const tooMany = Object.entries(counts)
    .filter(([code, n]) => n > (code === "F" || code === "J" ? 8 : 4))
    .map(([code]) => code);
  return { tiles: racked(tiles), unreadable, tooMany };
}

export function countTiles(tiles: TileCode[]): Record<TileCode, number> {
  const counts: Record<TileCode, number> = {};
  for (const tile of tiles) counts[tile] = (counts[tile] ?? 0) + 1;
  return counts;
}
