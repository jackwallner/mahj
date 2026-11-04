// The behaviour of the plugin's web page (docs/chatgpt/index.html). `npm run site`
// bundles it, with the real rack reader, into docs/chatgpt/page.js. Nothing here
// touches the network: a rack typed on the page stays on the page.
import { CHARLESTON_PASSES, type CharlestonPass, type RackRead, readRack, type SectionId, support } from "../src/rack.ts";
import { parseRack, racked, spokenName, type TileCode } from "../src/tiles.ts";

const motion = !matchMedia("(prefers-reduced-motion: reduce)").matches;
const esc = (s: string) => s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]!);
const $ = <T extends HTMLElement>(sel: string) => document.querySelector<T>(sel)!;

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

const svg = (t: TileCode) => `<svg viewBox="0 0 44 59.4" role="img" aria-label="${esc(spokenName(t))}"><rect class="face" x=".75" y=".75" width="42.5" height="57.9" rx="7" fill="var(--ivory)" stroke="var(--edge)" stroke-width="1.5"/>${face(t)}</svg>`;
const tile = (t: TileCode, i = 0, attrs = "", cls = "") => `<span class="t ${cls}" style="--i:${i}" ${attrs}>${svg(t)}</span>`;

/** Positions of `some` on the rack, so duplicate tiles match once each. */
function positions(tiles: TileCode[], some: TileCode[]): Set<number> {
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

function shuffled(): TileCode[] {
  const a = [...WHOLE_SET];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j]!, a[i]!];
  }
  return a;
}

// ---------- the conversation in the hero ----------
const SAMPLE = "2C 2C 4C 4C 6B 6B 8B 8D F J 1C 9B N";
const VERDICT = { fits: "Leaning", possible: "In reach", poor: "Long shot" };

function rackScene(): string {
  const read = readRack(racked(SAMPLE.split(" ")));
  const passAt = positions(read.tiles, read.passes);
  const tiles = read.tiles.map((t, i) => tile(t, i, passAt.has(i) ? `data-at="1900"` : "", passAt.has(i) ? "pass" : "")).join("");
  return `<div class="w">
    <div class="w-eyebrow"><span>Your rack</span><span>${read.tiles.length} tiles</span></div>
    <h4 class="fade" data-at="1500">${esc(read.headline)}</h4>
    <p class="w-sub fade" data-at="1500">${esc(read.summary.slice(read.headline.length + 2))}</p>
    <div class="rack seven" data-at="100">${tiles}</div>
    <h5 class="fade" data-at="2300">Pass</h5>
    <ul class="picks">${read.picks.map((p, i) => `<li class="fade" data-at="${2300 + i * 220}">${tile(p.tile)}<span><b>${esc(spokenName(p.tile))}</b> ${esc(p.reason)}</span></li>`).join("")}</ul>
  </div>`;
}

function passScene(): string {
  const deal = racked(["4C", "5C", "6C", "5B", "6B", "7B", "6D", "6D", "1C", "9D", "N", "F", "J"]);
  const passAt = positions(deal, ["1C", "9D", "N"]);
  let tap = 0;
  const tiles = deal.map((t, i) => {
    if (!passAt.has(i)) return tile(t, i);
    tap += 1;
    return tile(t, i, `data-at="${900 + tap * 480}"`, "tap");
  }).join("");
  return `<div class="w">
    <div class="w-eyebrow"><span>Charleston</span><span>1 of 6</span></div>
    <h4>First Charleston, pass across. Pick 3 tiles to pass.</h4>
    <div class="rack seven" data-at="100">${tiles}</div>
    <p class="verdict fade" data-at="2900">Same pass as the coach.</p>
    <p class="w-body fade" data-at="3100">Middle numbers 4 through 7 across Craks and Bams, plus a pair of 6 Dots, make a strong Consecutive Run start. The 1 and the 9 are long shots for a run built on 4 through 7, and the lone North is dead weight.</p>
  </div>`;
}

function lessonScene(): string {
  const tiles = ["5C", "5B", "5D", "N", "RD", "F", "J"].map((t, i) => tile(t, i)).join("");
  return `<div class="w">
    <div class="w-eyebrow"><span>How American Mah Jongg works</span><span>2 of 6</span></div>
    <h4>Meet the tiles</h4>
    <div class="rack seven" data-at="100">${tiles}</div>
    <p class="w-body fade" data-at="800">Three suits run 1 through 9. They are craks (red), bams (green) and dots (blue). Winds are printed N, E, W, S. Each dragon goes with a suit, red with craks, green with bams and the blank soap with dots.</p>
  </div>`;
}

const termScene = () => `<div class="reply fade" data-at="100">
    <p><b>Joker swap.</b> On your turn, after you draw or call and before you discard, trade a natural tile from your rack for a joker in any exposed group, your own included.</p>
    <p class="fade" data-at="900">The tile must be exactly the one the joker stands for, and the joker becomes yours to use. You may swap more than one in a turn.</p>
  </div>`;

const SCENES = [
  { ask: `Read my rack: ${SAMPLE}. What should I pass?`, card: rackScene, hold: 4200 },
  { ask: "Quiz me on the Charleston.", card: passScene, hold: 5200 },
  { ask: "Teach me how American mah jongg works.", card: lessonScene, hold: 4800 },
  { ask: "What is a joker swap?", card: termScene, hold: 4800 },
];

class Stopped extends Error {}

function startConversation(): void {
  const log = $("#chat-log");
  const typed = $("#chat-typed");
  const tabs = [...document.querySelectorAll<HTMLButtonElement>("#chat-tabs button")];
  let run = 0;
  let onScreen = true;

  const wait = async (ms: number, id: number) => {
    let left = ms;
    while (left > 0) {
      await new Promise((r) => setTimeout(r, 40));
      if (id !== run) throw new Stopped();
      if (onScreen && !document.hidden) left -= 40;
    }
  };

  const select = (i: number) => tabs.forEach((b, k) => b.setAttribute("aria-pressed", String(k === i)));
  const bubble = (ask: string) => `<div class="bubble">${esc(ask)}</div>`;

  function showAll(i: number): void {
    select(i);
    typed.textContent = "";
    log.innerHTML = bubble(SCENES[i]!.ask) + SCENES[i]!.card();
    log.classList.add("instant");
    log.querySelectorAll("[data-at]").forEach((el) => el.classList.add("on"));
  }

  async function play(i: number, id: number): Promise<void> {
    const scene = SCENES[i]!;
    select(i);
    log.classList.remove("instant");
    log.innerHTML = "";
    typed.textContent = "";
    await wait(300, id);
    const speed = scene.ask.length > 40 ? 14 : 30;
    for (let k = 1; k <= scene.ask.length; k++) {
      typed.textContent = scene.ask.slice(0, k);
      await wait(speed, id);
    }
    await wait(280, id);
    typed.textContent = "";
    log.innerHTML = bubble(scene.ask) + `<div class="thinking"><i></i><i></i><i></i></div>`;
    await wait(850, id);
    log.querySelector(".thinking")!.remove();
    log.insertAdjacentHTML("beforeend", scene.card());
    const timed = [...log.querySelectorAll<HTMLElement>("[data-at]")].sort((a, b) => Number(a.dataset.at) - Number(b.dataset.at));
    let at = 0;
    for (const el of timed) {
      await wait(Number(el.dataset.at) - at, id);
      at = Number(el.dataset.at);
      el.classList.add("on");
    }
    await wait(scene.hold, id);
  }

  async function loop(start: number, once: boolean): Promise<void> {
    const id = ++run;
    let i = start;
    try {
      do {
        await play(i, id);
        i = (i + 1) % SCENES.length;
      } while (!once);
    } catch (e) {
      if (!(e instanceof Stopped)) throw e;
    }
  }

  tabs.forEach((b, i) => b.addEventListener("click", () => {
    if (!motion) return showAll(i);
    void loop(i, true);
  }));

  new IntersectionObserver((entries) => {
    onScreen = entries.some((e) => e.isIntersecting);
  }).observe($("#chat"));

  if (motion) void loop(0, false);
  else showAll(0);
}

// ---------- the rack reader, running on the page ----------
const PASS_LABELS: Record<CharlestonPass, string> = {
  "first-right": "First pass right",
  "first-across": "First pass across",
  "first-left": "First pass left",
  "second-left": "Second pass left",
  "second-across": "Second pass across",
  "second-right": "Second pass right",
  courtesy: "Courtesy pass",
};

function startReader(): void {
  const rackEl = $("#reader-rack");
  const input = $<HTMLInputElement>("#reader-tiles");
  const passEl = $<HTMLSelectElement>("#reader-pass");
  const resultEl = $("#reader-result");
  const sectionsEl = $("#reader-sections");
  const errorEl = $("#reader-error");

  passEl.insertAdjacentHTML("beforeend", CHARLESTON_PASSES.map((p) => `<option value="${p}">${PASS_LABELS[p]}</option>`).join(""));

  let read: RackRead | null = null;
  let pinned: SectionId | null = null;
  let timer = 0;

  function spot(id: SectionId | null): void {
    if (!read) return;
    const hits = id ? positions(read.tiles, support(read.tiles, id)) : new Set<number>();
    rackEl.classList.toggle("spot", id !== null);
    rackEl.querySelectorAll<HTMLElement>(".t").forEach((el, i) => el.classList.toggle("hit", hits.has(i)));
    sectionsEl.querySelectorAll<HTMLElement>("button").forEach((b) => {
      b.classList.toggle("active", b.dataset.id === id);
      b.setAttribute("aria-pressed", String(b.dataset.id === pinned));
    });
  }

  function drawRack(tiles: TileCode[], passAt: Set<number>, animate: boolean): void {
    rackEl.innerHTML = tiles.map((t, i) => tile(t, i, "", passAt.has(i) ? "pass" : "")).join("");
    rackEl.classList.remove("spot");
    rackEl.classList.toggle("on", animate && motion);
    window.clearTimeout(timer);
    const mark = () => rackEl.querySelectorAll(".pass").forEach((el) => el.classList.add("on"));
    if (animate && motion) timer = window.setTimeout(mark, tiles.length * 38 + 420);
    else mark();
  }

  function fail(message: string, tiles: TileCode[]): void {
    read = null;
    pinned = null;
    drawRack(tiles, new Set(), false);
    errorEl.textContent = message;
    errorEl.hidden = false;
    resultEl.classList.add("stale");
    sectionsEl.classList.add("stale");
  }

  function show(animate: boolean): void {
    const parsed = parseRack([input.value]);
    if (!input.value.trim()) return fail("Type your tiles or deal a rack.", []);
    if (parsed.tooMany.length) return fail(`A set has only four of each tile, and eight flowers and jokers. This rack has too many: ${parsed.tooMany.map(spokenName).join(", ")}.`, parsed.tiles);
    if (parsed.unreadable.length) return fail(`Can't read ${parsed.unreadable.join(", ")}. Try codes like 5D, 2B, N, soap or joker.`, parsed.tiles);
    if (parsed.tiles.length > 14) return fail(`That is ${parsed.tiles.length} tiles. A rack holds 13 (14 for East).`, parsed.tiles);
    if (parsed.tiles.length < 5) return fail("Share at least five tiles, ideally the whole 13.", parsed.tiles);

    pinned = null;
    const pass = passEl.value ? (passEl.value as CharlestonPass) : undefined;
    read = readRack(parsed.tiles, pass);
    errorEl.hidden = true;
    resultEl.classList.remove("stale");
    sectionsEl.classList.remove("stale");
    drawRack(read.tiles, positions(read.tiles, read.passes), animate);

    const short = read.tiles.length < 13 ? `This reads only the ${read.tiles.length} tiles shared. The other ${13 - read.tiles.length} can change the lean and the pass.` : "";
    const sub = read.summary.startsWith(`${read.headline}. `) ? read.summary.slice(read.headline.length + 2) : read.summary;
    const plan = [
      read.anchors.length ? `<li><b>Build on</b> ${esc(read.anchors.join(", "))}</li>` : "",
      read.hope.length ? `<li><b>Hope to draw</b> ${esc(read.hope.map(spokenName).join(", "))}</li>` : "",
      read.jokerNote ? `<li>${esc(read.jokerNote)}</li>` : "",
    ].join("");
    resultEl.innerHTML = `
      <h3 aria-live="polite">${esc(read.headline)}</h3>
      <p class="read-sub">${esc(sub)}</p>
      ${short ? `<p class="read-sub">${esc(short)}</p>` : ""}
      ${read.picks.length ? `<h4>${pass ? `Pass, for the ${esc(PASS_LABELS[pass].toLowerCase())}` : "Pass"}</h4>
        <ul class="picks">${read.picks.map((p) => `<li>${tile(p.tile)}<span><b>${esc(spokenName(p.tile))}</b> ${esc(p.reason)}</span></li>`).join("")}</ul>` : ""}
      ${read.passNote ? `<p class="read-sub">${esc(read.passNote)}</p>` : ""}
      ${read.spare.length ? `<p class="read-sub">Later passes: ${esc(read.spare.map(spokenName).join(", "))}.</p>` : ""}
      ${plan ? `<ul class="plan">${plan}</ul>` : ""}`;

    const size = read.tiles.length;
    const shareOf = (id: SectionId) => Math.min(1, support(read!.tiles, id).length / size);
    // The reader orders the live sections by strength; long shots read best by reach.
    const live = read.sections.filter((s) => s.verdict !== "poor");
    const longShots = read.sections.filter((s) => s.verdict === "poor").sort((a, b) => shareOf(b.id) - shareOf(a.id));
    const rows = [...live, ...longShots].map((s) => {
      const share = shareOf(s.id);
      return `<li><button type="button" data-id="${s.id}" aria-pressed="false">
        <span class="sec-head"><b>${esc(s.name)}</b><span class="chip ${s.verdict}">${VERDICT[s.verdict]}</span></span>
        <span class="bar ${s.verdict}"><i style="--n:${share}"></i></span>
        <span class="sec-note">${esc(s.note)}</span>
      </button></li>`;
    }).join("");
    sectionsEl.innerHTML = rows;
    if (animate && motion) {
      sectionsEl.classList.add("pre");
      requestAnimationFrame(() => requestAnimationFrame(() => sectionsEl.classList.remove("pre")));
    }
  }

  function deal(): void {
    input.value = racked(shuffled().slice(0, 13)).join(" ");
    show(true);
  }

  $("#reader-deal").addEventListener("click", deal);
  passEl.addEventListener("change", () => show(false));
  let typing = 0;
  input.addEventListener("input", () => {
    window.clearTimeout(typing);
    typing = window.setTimeout(() => show(false), 220);
  });

  sectionsEl.addEventListener("pointerover", (e) => {
    if ((e as PointerEvent).pointerType !== "mouse" || pinned) return;
    const b = (e.target as HTMLElement).closest("button");
    if (b) spot(b.dataset.id as SectionId);
  });
  sectionsEl.addEventListener("pointerleave", (e) => {
    if ((e as PointerEvent).pointerType === "mouse" && !pinned) spot(null);
  });
  sectionsEl.addEventListener("focusin", (e) => {
    const b = (e.target as HTMLElement).closest("button");
    if (b && !pinned && b.matches(":focus-visible")) spot(b.dataset.id as SectionId);
  });
  sectionsEl.addEventListener("focusout", () => {
    if (!pinned) spot(null);
  });
  sectionsEl.addEventListener("click", (e) => {
    const b = (e.target as HTMLElement).closest("button");
    if (!b) return;
    const id = b.dataset.id as SectionId;
    pinned = pinned === id ? null : id;
    spot(pinned ?? null);
  });

  input.value = SAMPLE;
  show(false);
  // Hold the first deal until the rack is on screen, so it is seen.
  if (motion) {
    rackEl.classList.add("waiting");
    const seen = new IntersectionObserver((entries) => {
      if (!entries.some((e) => e.isIntersecting)) return;
      seen.disconnect();
      rackEl.classList.remove("waiting");
      show(true);
    }, { threshold: 0.3 });
    seen.observe(rackEl);
  }
}

// ---------- small things ----------
function startRibbon(): void {
  const group = shuffled().slice(0, 40).map((t) => tile(t)).join("");
  $("#ribbon").innerHTML = `<div class="ribbon-group">${group}</div><div class="ribbon-group">${group}</div>`;
}

function startMinis(): void {
  document.querySelectorAll<HTMLElement>("[data-tiles]").forEach((el) => {
    const raised = new Set((el.dataset.raised ?? "").split(" ").filter(Boolean).map(Number));
    el.innerHTML = el.dataset.tiles!.split(" ").map((t, i) => tile(t, i, "", raised.has(i) ? "raised" : "")).join("");
  });
}

function startReveals(): void {
  const all = document.querySelectorAll(".reveal");
  if (!motion) return all.forEach((el) => el.classList.add("in"));
  const io = new IntersectionObserver((entries) => {
    for (const e of entries) {
      if (!e.isIntersecting) continue;
      e.target.classList.add("in");
      io.unobserve(e.target);
    }
  }, { threshold: 0.15, rootMargin: "0px 0px -6% 0px" });
  all.forEach((el) => io.observe(el));
}

function startPrompts(): void {
  document.querySelectorAll<HTMLButtonElement>(".prompt").forEach((b) => {
    const state = b.querySelector<HTMLElement>(".prompt-state")!;
    b.addEventListener("click", async () => {
      await navigator.clipboard.writeText(b.querySelector(".prompt-text")!.textContent!);
      state.textContent = "Copied";
      b.classList.add("copied");
      window.setTimeout(() => {
        state.textContent = "Copy";
        b.classList.remove("copied");
      }, 1400);
    });
  });
}

startRibbon();
startMinis();
startReveals();
startPrompts();
startConversation();
startReader();
