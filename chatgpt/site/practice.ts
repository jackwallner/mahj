// The behaviour of the free practice page (docs/american-mahjong-practice-online.html).
// `npm run site` bundles it, with the real rack reader, into docs/practice.js.
// Nothing here touches the network: a rack dealt or typed on the page stays on the page.
import { type CharlestonPass, type RackRead, readRack } from "../src/rack.ts";
import { racked, spokenName, type TileCode } from "../src/tiles.ts";
import { $, esc, motion, positions, shuffled, svg, tile } from "./draw.ts";
import { PASS_LABELS, startReader } from "./reader.ts";

const SAMPLE = "2C 2C 4C 4C 6B 6B 8B 8D F J 1C 9B N";
/** The first Charleston. The last of the three is a blind-pass round. */
const ROUNDS: CharlestonPass[] = ["first-right", "first-across", "first-left"];
const BLIND: Record<string, true> = { "first-left": true };

function list(words: string[]): string {
  return words.length <= 1 ? (words[0] ?? "") : `${words.slice(0, -1).join(", ")} and ${words[words.length - 1]}`;
}

/** Tiles of `some` that `pool` cannot cover, counting duplicates once each. */
function without(some: TileCode[], pool: TileCode[]): TileCode[] {
  const left = [...pool];
  return some.filter((t) => {
    const j = left.indexOf(t);
    if (j < 0) return true;
    left.splice(j, 1);
    return false;
  });
}

/** How one pass compares with the coach's: tiles the coach keeps, dead tiles the player held, points of three. */
export function grade(picked: TileCode[], read: RackRead): { kept: TileCode[]; missed: TileCode[]; score: number } {
  const kept = without(picked, [...read.passes, ...read.spare]);
  const good = picked.length - kept.length;
  const missed = good >= read.passes.length ? [] : without(read.passes, picked);
  return { kept, missed, score: Math.max(0, 3 - Math.max(kept.length, read.passes.length - good)) };
}

function startDrill(): void {
  const rackEl = $("#drill-rack");
  const stepEl = $("#drill-step");
  const titleEl = $("#drill-title");
  const goEl = $<HTMLButtonElement>("#drill-go");
  const resultEl = $("#drill-result");

  let wall: TileCode[] = [];
  let rack: TileCode[] = [];
  let round = 0;
  let picked = new Set<number>();
  let read: RackRead | null = null;
  let score = 0;

  const blind = () => BLIND[ROUNDS[round]!] === true;
  const ready = () => (blind() ? picked.size <= 3 : picked.size === 3);

  function label(): string {
    if (read) return round === ROUNDS.length - 1 ? "Deal again" : "Next pass";
    if (!blind()) return picked.size === 3 ? "Pass these 3" : "Pick 3 tiles";
    return picked.size === 3 ? "Pass these 3" : `Pass ${picked.size}, ${3 - picked.size} blind`;
  }

  function drawRack(fresh: Set<number>): void {
    rackEl.innerHTML = rack.map((t, i) => {
      const joker = t === "J";
      return `<button type="button" class="t tap${fresh.has(i) ? " fresh" : ""}" style="--i:${i}" data-i="${i}" aria-pressed="false"${joker ? " disabled" : ""}>${svg(t)}</button>`;
    }).join("");
    rackEl.classList.toggle("on", motion);
  }

  function sync(): void {
    stepEl.textContent = `Pass ${round + 1} of ${ROUNDS.length}`;
    titleEl.textContent = PASS_LABELS[ROUNDS[round]!];
    goEl.textContent = label();
    goEl.disabled = !read && !ready();
    rackEl.querySelectorAll<HTMLButtonElement>("button").forEach((b, i) => {
      const on = picked.has(i);
      b.classList.toggle("on", on);
      b.setAttribute("aria-pressed", String(on));
    });
    rackEl.classList.toggle("locked", read !== null);
  }

  function deal(): void {
    wall = shuffled();
    rack = racked(wall.splice(0, 13));
    round = 0;
    score = 0;
    read = null;
    picked = new Set();
    resultEl.innerHTML = "";
    drawRack(new Set(rack.map((_, i) => i)));
    sync();
  }

  function show(): void {
    const mine = [...picked].map((i) => rack[i]!);
    read = readRack(rack, ROUNDS[round]);
    const g = grade(mine, read);
    score += g.score;
    const names = (tiles: TileCode[]) => list(tiles.map((t) => `the ${spokenName(t)}`));
    const verdict = g.kept.length
      ? `The coach keeps ${names(g.kept)}.`
      : g.missed.length ? `The coach also passes ${names(g.missed)}.` : "Same call as the coach.";
    const sub = read.summary.startsWith(`${read.headline}. `) ? read.summary.slice(read.headline.length + 2) : read.summary;
    const last = round === ROUNDS.length - 1;
    resultEl.innerHTML = `
      <p class="drill-verdict${g.kept.length || g.missed.length ? " off" : ""}" aria-live="polite">${esc(verdict)}</p>
      <h3>${esc(read.headline)}</h3>
      <p class="read-sub">${esc(sub)}</p>
      ${read.picks.length ? `<h4>The coach's pass</h4>
        <ul class="picks">${read.picks.map((p) => `<li>${tile(p.tile)}<span><b>${esc(spokenName(p.tile))}</b> ${esc(p.reason)}</span></li>`).join("")}</ul>` : ""}
      ${read.passNote ? `<p class="read-sub">${esc(read.passNote)}</p>` : ""}
      ${last ? `<p class="drill-score">${score} of ${ROUNDS.length * 3} with the coach</p>` : ""}`;
    sync();
  }

  function next(): void {
    if (round === ROUNDS.length - 1) return deal();
    const gone = [...picked].map((i) => rack[i]!);
    const stay = rack.filter((_, i) => !picked.has(i));
    const got = wall.splice(0, gone.length);
    rack = racked([...stay, ...got]);
    round += 1;
    read = null;
    picked = new Set();
    resultEl.innerHTML = "";
    drawRack(positions(rack, got));
    sync();
  }

  rackEl.addEventListener("click", (e) => {
    const b = (e.target as HTMLElement).closest<HTMLButtonElement>("button[data-i]");
    if (!b || read) return;
    const i = Number(b.dataset.i);
    if (picked.has(i)) picked.delete(i);
    else if (picked.size < 3) picked.add(i);
    sync();
  });
  goEl.addEventListener("click", () => (read ? next() : show()));
  $("#drill-deal").addEventListener("click", deal);
  deal();
}

startDrill();
startReader(SAMPLE);
