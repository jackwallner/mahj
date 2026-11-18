// Tile drawing and small page helpers shared by the site pages built from this
// folder (docs/chatgpt/page.js and docs/practice.js).
import { spokenName, type TileCode } from "../src/tiles.ts";

export const motion = !matchMedia("(prefers-reduced-motion: reduce)").matches;
export const esc = (s: string) => s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]!);
export const $ = <T extends HTMLElement>(sel: string) => document.querySelector<T>(sel)!;

// ---------- tiles, drawn from data like the widget and the app's TileView ----------
const WINDS: Record<string, true> = { N: true, E: true, W: true, S: true };
const PIPS: Record<number, number[]> = { 1: [1], 2: [2], 3: [3], 4: [2, 2], 5: [2, 1, 2], 6: [3, 3], 7: [2, 3, 2], 8: [3, 2, 3], 9: [3, 3, 3] };

function pips(n: number, suit: string): string {
  const rows = PIPS[n]!;
  const size = rows.length === 1 ? 9 : rows.length === 2 ? 7.4 : 5.8;
  const gap = suit === "B" ? size * 0.5 : size * 0.34;
  const pitch = suit === "B" ? size * 1.62 : size + gap;
  const top = 36 - ((rows.length - 1) * pitch + size) / 2 + 6;
  let out = "";
  rows.forEach((count, r) => {
    const width = count * size + (count - 1) * gap;
    const y = top + r * pitch;
    for (let i = 0; i < count; i++) {
      const x = 22 - width / 2 + i * (size + gap);
      out += suit === "D"
        ? `<circle cx="${x + size / 2}" cy="${y + size / 2}" r="${size / 2 - 1}" fill="none" stroke="var(--dot)" stroke-width="${size * 0.26}"/>`
        : `<rect x="${x + size * 0.3}" y="${y - size * 0.06}" width="${size * 0.4}" height="${size * 1.12}" rx="${size * 0.2}" fill="var(--bam)"/>`;
    }
  });
  return out;
}

const BIRD = `<g fill="var(--bam)"><ellipse cx="21" cy="40" rx="9.5" ry="6.2"/><circle cx="29" cy="31.5" r="4.4"/><path d="M12.5 39 L5 32 L7 42.5 Z"/></g><path d="M33 31 L37.5 32.4 L33 33.6 Z" fill="var(--crak)"/><circle cx="30" cy="30.6" r="1" fill="var(--ivory)"/>`;
const SANS = "-apple-system,system-ui,sans-serif";
const label = (text: string, color: string) => `<text x="22" y="53" text-anchor="middle" font-size="9.5" font-weight="800" fill="${color}" font-family="${SANS}">${text}</text>`;
const big = (text: string, color: string, y = 30, size = 24, serif = true) => `<text x="22" y="${y}" text-anchor="middle" font-size="${size}" font-weight="700" fill="${color}" font-family="${serif ? "ui-serif,Georgia,serif" : SANS}">${text}</text>`;

function face(t: TileCode): string {
  if (/^[1-9]C$/.test(t)) return big(t[0]!, "var(--crak)", 27, 23) + big("萬", "var(--crak)", 49, 15, false);
  if (t === "1B") return big("1", "var(--bam)", 16, 13) + BIRD;
  if (/^[1-9][BD]$/.test(t)) return big(t[0]!, t[1] === "B" ? "var(--bam)" : "var(--dot)", 16, 13) + pips(Number(t[0]), t[1]!);
  if (WINDS[t]) return big(t, "#2b2621", 33, 27) + label("WIND", "#6b6157");
  if (t === "RD") return big("中", "var(--crak)", 34, 22, false) + label("RED", "var(--crak)");
  if (t === "GD") return big("發", "var(--bam)", 34, 22, false) + label("GREEN", "var(--bam)");
  if (t === "SO") return `<rect x="13" y="11" width="18" height="24" rx="3" fill="none" stroke="var(--dot)" stroke-width="2.6"/>` + label("SOAP", "var(--dot)");
  if (t === "F") return `<g fill="var(--flower)"><circle cx="22" cy="17" r="5"/><circle cx="15" cy="24" r="5"/><circle cx="29" cy="24" r="5"/><circle cx="17.5" cy="32" r="5"/><circle cx="26.5" cy="32" r="5"/></g><circle cx="22" cy="25.5" r="3.4" fill="var(--ivory)"/>` + label("FLOWER", "var(--flower)");
  return big("J", "var(--joker)", 33, 26) + label("JOKER", "var(--joker)");
}

export const svg = (t: TileCode) => `<svg viewBox="0 0 44 59.4" role="img" aria-label="${esc(spokenName(t))}"><rect class="face" x=".75" y=".75" width="42.5" height="57.9" rx="7" fill="var(--ivory)" stroke="var(--edge)" stroke-width="1.5"/>${face(t)}</svg>`;
export const tile = (t: TileCode, i = 0, attrs = "", cls = "") => `<span class="t ${cls}" style="--i:${i}" ${attrs}>${svg(t)}</span>`;

/** Positions of `some` on the rack, so duplicate tiles match once each. */
export function positions(tiles: TileCode[], some: TileCode[]): Set<number> {
  const left = [...some];
  const out = new Set<number>();
  tiles.forEach((t, k) => {
    const j = left.indexOf(t);
    if (j >= 0) {
      left.splice(j, 1);
      out.add(k);
    }
  });
  return out;
}

const WHOLE_SET: TileCode[] = [
  ...[1, 2, 3, 4].flatMap(() => [
    ..."CBD".split("").flatMap((s) => [1, 2, 3, 4, 5, 6, 7, 8, 9].map((n) => `${n}${s}`)),
    "N", "E", "W", "S", "RD", "GD", "SO",
  ]),
  ...Array<TileCode>(8).fill("F"),
  ...Array<TileCode>(8).fill("J"),
];

export function shuffled(): TileCode[] {
  const a = [...WHOLE_SET];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j]!, a[i]!];
  }
  return a;
}
