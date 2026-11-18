// The rack reader, running on the page. It makes no network calls: a rack typed
// here stays here.
import { CHARLESTON_PASSES, type CharlestonPass, type RackRead, readRack, type SectionId, support } from "../src/rack.ts";
import { parseRack, racked, spokenName, type TileCode } from "../src/tiles.ts";
import { $, esc, motion, positions, shuffled, tile } from "./draw.ts";

const VERDICT = { fits: "Leaning", possible: "In reach", poor: "Long shot" };
export const PASS_LABELS: Record<CharlestonPass, string> = {
  "first-right": "First pass right",
  "first-across": "First pass across",
  "first-left": "First pass left",
  "second-left": "Second pass left",
  "second-across": "Second pass across",
  "second-right": "Second pass right",
  courtesy: "Courtesy pass",
};

export function startReader(sample: string): void {
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

  input.value = sample;
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
