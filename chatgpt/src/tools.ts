// Tool results. `structuredContent` and `content` are what the model reads;
// `_meta.widget` is the widget's own payload, hidden from the model. Practice
// answers live only in `_meta.widget`, so the model can't give them away;
// without the widget it checks a typed answer with `check_mahjong_answer`.
// `plain` is Claude's copy: its directory rejects tool output that tells the
// model how to reply, so those lines describe the result instead.
import { type GlossaryEntry } from "./content.ts";
import { type CharlestonPass, readRack } from "./rack.ts";
import { COMMON_TERMS, findQuestion, learnDeck, type LearnTopic, practiceSession, type PracticeTopic, type Question } from "./sessions.ts";
import { parseRack, spokenName } from "./tiles.ts";

const key = () => crypto.randomUUID();
const names = (tiles: string[]) => tiles.map(spokenName).join(", ");
const period = (s: string) => (/[.!?]$/.test(s) ? s : `${s}.`);

/** A dealt rack is 13 tiles, 14 for East. */
const FULL_RACK = 13;
const MAX_RACK = 14;

const PRACTICE_LABEL: Record<LearnTopic, string> = {
  basics: "the basics",
  tiles: "the tiles",
  sections: "reading a rack",
  charleston: "the Charleston",
  strategy: "keep or throw",
};

const PASS_NAME: Record<CharlestonPass, string> = {
  "first-right": "the first pass right",
  "first-across": "the first pass across",
  "first-left": "the first pass left (a blind-pass round)",
  "second-left": "the second Charleston's first pass, left",
  "second-across": "the second Charleston's pass across",
  "second-right": "the second Charleston's last pass, right (a blind-pass round)",
  courtesy: "the courtesy pass",
};

export function lessonResult(topic: LearnTopic) {
  const deck = learnDeck(topic);
  const cards = deck.cards.map((c) => ({
    title: c.title,
    ...(c.context ? { context: c.context } : {}),
    ...(c.subtitle ? { subtitle: c.subtitle } : {}),
    ...(c.lead ? { answer: c.lead } : {}),
    body: c.body,
    ...(c.tip ? { tip: c.tip } : {}),
  }));
  const text = [
    `The "${deck.title}" lesson (${cards.length} cards) is shown in the interactive deck. Cards that ask a question let the player answer before the explanation shows, and the deck ends with a button to practice it. The card text below is for follow-up questions, or to teach from if the deck is not visible.`,
    `${deck.title}:`,
    ...cards.map((c) => `- ${c.context ? `${period(c.context)} ` : ""}${c.title}${c.subtitle ? ` (${c.subtitle})` : ""}: ${c.answer ? `${period(c.answer)} ` : ""}${c.body}${c.tip ? ` Tip: ${c.tip}` : ""}`),
  ].join("\n");
  return {
    structuredContent: { title: deck.title, cards },
    content: [{ type: "text" as const, text }],
    _meta: { widget: { view: "learn", key: key(), deck: { ...deck, practice: true, practiceLabel: PRACTICE_LABEL[topic] } } },
  };
}

function answerText(q: Question): string {
  if (q.kind === "choice") return `“${q.choices[q.answerIndex]}”`;
  return q.also.length ? `${names(q.pass)} (${names(q.also)} can stand in for ${names(q.swap)})` : names(q.pass);
}

export function practiceResult(topic: PracticeTopic, count: number, plain = false) {
  const session = practiceSession(topic, count);
  const questions = session.questions.map((q) => ({
    id: q.id,
    prompt: q.kind === "choice" && q.context ? `${q.context} ${q.prompt}` : q.prompt,
    tiles: q.tiles,
    ...(q.kind === "choice" ? { choices: q.choices } : { pick: 3 }),
  }));
  const short = session.questions.length < count
    ? ` This topic has ${session.available} questions, so the set has all ${session.questions.length}.`
    : "";
  return {
    structuredContent: { title: session.title, available: session.available, questions },
    content: [{
      type: "text" as const,
      text: `${session.title}: ${questions.length} questions are shown in the interactive quiz, which checks and explains each answer.${short} The answers are not in this result. ${plain ? "Without the quiz, check_mahjong_answer checks a typed answer by question id." : "If the quiz is not visible, ask the questions one at a time and check each reply with check_mahjong_answer before saying whether it is right."}`,
    }],
    _meta: { widget: { view: "practice", key: key(), session } },
  };
}

/// Checks one typed answer against a practice question.
export function checkResult(id: string, answer: string, plain = false) {
  const q = findQuestion(id);
  if (!q) {
    const text = `No practice question has the id "${id.slice(0, 40)}". Use an id from start_mahjong_practice.`;
    return { structuredContent: { id, found: false, correct: false, answer: "", explanation: text }, content: [{ type: "text" as const, text }] };
  }
  let correct: boolean;
  if (q.kind === "choice") {
    // The player may type the whole choice or its start ("throw" for "Throw it").
    const norm = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
    const given = norm(answer);
    const matches = q.choices.map(norm).flatMap((c, i) => (c === given || (given.length >= 3 && c.startsWith(given)) ? [i] : []));
    if (matches.length !== 1) {
      const text = `That answer doesn't match one choice. ${plain ? "The choices are" : "Ask the player to pick one of"}: ${q.choices.join(" | ")}.`;
      return { structuredContent: { id, found: true, correct: false, answer: "", explanation: text }, content: [{ type: "text" as const, text }] };
    }
    correct = matches[0] === q.answerIndex;
  } else {
    const picked = parseRack([answer]).tiles;
    const required = [...q.pass];
    for (const t of q.swap) required.splice(required.indexOf(t), 1);
    const flexible = [...q.swap, ...q.also];
    correct = picked.length === 3 && picked.every((t) => {
      const r = required.indexOf(t), f = flexible.indexOf(t);
      if (r >= 0) return required.splice(r, 1), true;
      if (f >= 0) return flexible.splice(f, 1), true;
      return false;
    }) && required.length === 0;
  }
  const right = answerText(q);
  const text = `${correct ? "Right." : `Not quite. The answer is ${right}.`} ${q.explanation}`;
  return {
    structuredContent: { id, found: true, correct, answer: right, explanation: q.explanation },
    content: [{ type: "text" as const, text }],
  };
}

function rackError(parsed: ReturnType<typeof parseRack>, error: string) {
  const read = parsed.tiles.length ? ` Read so far: ${names(parsed.tiles)}.` : "";
  const missed = parsed.unreadable.length ? ` Could not read: ${parsed.unreadable.join(", ")}.` : "";
  const text = `${error}${missed}${read}`;
  return {
    structuredContent: { tiles: parsed.tiles, read: null, shortlist: [], summary: text, passes: [], reasons: [], spare: [], sections: [], unreadable: parsed.unreadable },
    content: [{ type: "text" as const, text }],
    _meta: { widget: { key: key(), error, tiles: parsed.tiles, unreadable: parsed.unreadable } },
  };
}

export function rackResult(raw: string[], pass?: CharlestonPass, plain = false) {
  const parsed = parseRack(raw);
  if (parsed.tooMany.length) {
    return rackError(parsed, `An American set has only four of each tile (eight flowers, eight jokers), and this rack has more ${parsed.tooMany.map(spokenName).join(", ")} than that. Check the tiles and try again.`);
  }
  // A read on part of a rack would pass tiles the missing ones might need.
  if (parsed.unreadable.length) {
    return rackError(parsed, "Some entries are not tiles I can read, and a read without them could pass the wrong tiles. Fix them and share the rack again, using codes like 5D, 2B, N, soap or joker.");
  }
  if (parsed.tiles.length > MAX_RACK) {
    return rackError(parsed, `That is ${parsed.tiles.length} tiles. A rack holds 13 (14 for East), so check for a doubled tile.`);
  }
  if (parsed.tiles.length < 5) {
    return rackError(parsed, "Share at least five tiles, ideally the whole 13-tile rack, so there is enough to read.");
  }
  const read = readRack(parsed.tiles, pass);
  const partial = read.tiles.length < FULL_RACK
    ? `This reads only the ${read.tiles.length} tiles shared. The other ${FULL_RACK - read.tiles.length} can change the lean and the pass.`
    : null;
  const { jokers, flowers } = read.counts;
  const keeps = [
    jokers ? (jokers === 1 ? "joker" : "jokers") : "",
    flowers ? (flowers === 1 ? "flower (many hands use flowers)" : "flowers (many hands use them)") : "",
  ].filter(Boolean);
  const passLine = read.picks.length
    ? `Pass: ${read.picks.map((p) => `${spokenName(p.tile)} (${p.reason})`).join("; ")}.${read.spare.length ? ` Later passes: ${names(read.spare)}.` : ""}`
    : "";
  const lines = [
    `This read is shown in the interactive rack card, with the tiles, the pass and every section.${plain ? "" : " In chat, don't repeat the tiles or the section list."}`,
    partial ?? "",
    pass ? `The player is making ${PASS_NAME[pass]}.` : "",
    read.summary,
    passLine,
    read.passNote ?? "",
    read.anchors.length ? `Anchors: ${read.anchors.join("; ")}.` : "",
    read.hope.length ? `Tiles to hope for: ${names(read.hope)}.` : "",
    keeps.length ? `Keep your ${keeps.join(" and ")}.` : "",
    read.jokerNote,
    ...read.sections.filter((s) => s.verdict !== "poor" && s.id !== read.read).map((s) => `${s.name}: ${s.note}`),
    `Sections are the stable families of the yearly card. ${plain ? "The exact lines are on the player's own card." : "The player should check the exact lines on their own card."}`,
  ].filter(Boolean);
  const name = (id: string) => read.sections.find((s) => s.id === id)?.name ?? id;
  return {
    structuredContent: {
      tiles: read.tiles,
      read: read.read ? name(read.read) : null,
      shortlist: read.shortlist.map(name),
      summary: read.summary,
      passes: read.passes,
      reasons: read.picks.map((p) => p.reason),
      spare: read.spare,
      sections: read.sections.map(({ name, verdict, note }) => ({ name, verdict, note })),
      unreadable: parsed.unreadable,
    },
    content: [{ type: "text" as const, text: lines.join("\n") }],
    _meta: { widget: { view: "rack", key: key(), read, partial, pass: pass ? PASS_NAME[pass] : null } },
  };
}

export function termResult(query: string, entry: GlossaryEntry | null) {
  const structured = entry
    ? { term: entry.term, definition: entry.definition, found: true }
    : { term: query, definition: "Not in the Mahj glossary.", found: false };
  const miss = `"${query}" is not in the Mahj glossary, so there is no Mahj definition to give. The glossary covers terms such as ${COMMON_TERMS.join(", ")}.`;
  return {
    structuredContent: structured,
    content: [{ type: "text" as const, text: entry ? `${entry.term}: ${entry.definition}` : miss }],
  };
}
