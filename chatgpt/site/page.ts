// The behaviour of the plugin's web page (docs/chatgpt/index.html). `npm run site`
// bundles it, with the real rack reader, into docs/chatgpt/page.js. Nothing here
// touches the network: a rack typed on the page stays on the page.
import { readRack } from "../src/rack.ts";
import { racked, spokenName } from "../src/tiles.ts";
import { $, esc, motion, positions, shuffled, tile } from "./draw.ts";
import { startReader } from "./reader.ts";

// ---------- the conversation in the hero ----------
const SAMPLE = "2C 2C 4C 4C 6B 6B 8B 8D F J 1C 9B N";

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
    await wait(160, id);
    // About a second of typing, however long the prompt is.
    const step = Math.ceil(scene.ask.length / 25);
    for (let k = step; k < scene.ask.length + step; k += step) {
      typed.textContent = scene.ask.slice(0, k);
      await wait(40, id);
    }
    await wait(200, id);
    typed.textContent = "";
    log.innerHTML = bubble(scene.ask) + `<div class="thinking"><i></i><i></i><i></i></div>`;
    await wait(560, id);
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
startReader(SAMPLE);
