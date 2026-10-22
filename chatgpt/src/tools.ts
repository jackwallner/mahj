// Tool results. `structuredContent` and `content` are what the model reads;
// `_meta.widget` is the widget's own payload, hidden from the model.
import { type GlossaryEntry } from "./content.ts";
import { readRack } from "./rack.ts";
import { COMMON_TERMS, learnDeck, type LearnTopic, practiceSession, type PracticeTopic, type Question } from "./sessions.ts";
import { parseRack, spokenName } from "./tiles.ts";

const key = () => crypto.randomUUID();
const names = (tiles: string[]) => tiles.map(spokenName).join(", ");

const PRACTICE_LABEL: Record<LearnTopic, string> = {
  basics: "the basics",
  tiles: "the tiles",
  sections: "reading a rack",
  charleston: "the Charleston",
  strategy: "keep or throw",
};

export function lessonResult(topic: LearnTopic) {
  const deck = learnDeck(topic);
  const cards = deck.cards.map((c) => ({
    title: c.title,
    ...(c.subtitle ? { subtitle: c.subtitle } : {}),
    ...(c.lead ? { answer: c.lead } : {}),
    body: c.body,
    ...(c.tip ? { tip: c.tip } : {}),
  }));
  const text = [
    `${deck.title}:`,
    ...cards.map((c) => `- ${c.title}${c.subtitle ? ` (${c.subtitle})` : ""}: ${c.answer ? `${c.answer}. ` : ""}${c.body}${c.tip ? ` Tip: ${c.tip}` : ""}`),
  ].join("\n");
  return {
    structuredContent: { title: deck.title, cards },
    content: [{ type: "text" as const, text }],
    _meta: { widget: { view: "learn", key: key(), deck: { ...deck, practice: true, practiceLabel: PRACTICE_LABEL[topic] } } },
  };
}

function answerText(q: Question): string {
  if (q.kind === "choice") return q.choices[q.answerIndex];
  return q.also.length ? `${names(q.pass)} (${names(q.also)} can stand in for ${names(q.swap)})` : names(q.pass);
}

export function practiceResult(topic: PracticeTopic, count: number) {
  const session = practiceSession(topic, count);
  const questions = session.questions.map((q) => ({
    prompt: q.kind === "choice" && q.context ? `${q.context} ${q.prompt}` : q.prompt,
    tiles: q.tiles,
    ...(q.kind === "choice" ? { choices: q.choices } : {}),
    answer: answerText(q),
    explanation: q.explanation,
  }));
  return {
    structuredContent: { title: session.title, questions },
    content: [{
      type: "text" as const,
      text: `${session.title}: ${questions.length} questions are shown in the interactive quiz, which checks and explains each answer. Do not list the answers. If the quiz is not visible, ask the questions one at a time and reveal each answer only after the player responds.`,
    }],
    _meta: { widget: { view: "practice", key: key(), session } },
  };
}

function rackError(parsed: ReturnType<typeof parseRack>, error: string) {
  const text = parsed.unreadable.length ? `${error} Could not read: ${parsed.unreadable.join(", ")}.` : error;
  return {
    structuredContent: { tiles: parsed.tiles, read: null, shortlist: [], summary: text, passes: [], spare: [], sections: [], unreadable: parsed.unreadable },
    content: [{ type: "text" as const, text }],
    _meta: { widget: { key: key(), error: text } },
  };
}

export function rackResult(raw: string[]) {
  const parsed = parseRack(raw);
  if (parsed.tooMany.length) {
    return rackError(parsed, `An American set has only four of each tile (eight flowers, eight jokers), and this rack has more ${parsed.tooMany.map(spokenName).join(", ")} than that. Check the tiles and try again.`);
  }
  if (parsed.unreadable.length > parsed.tiles.length) {
    return rackError(parsed, "Only part of that could be read, so a read would not be fair. Send one tile per entry, like 5D, 2B, N, soap or joker.");
  }
  if (parsed.tiles.length < 5) {
    return rackError(parsed, "Share at least five tiles, ideally the whole 13-tile rack, so there is enough to read.");
  }
  const read = readRack(parsed.tiles);
  const { jokers, flowers } = read.counts;
  const keeps = [
    jokers ? (jokers === 1 ? "joker (jokers can never be passed)" : "jokers (they can never be passed)") : "",
    flowers ? (flowers === 1 ? "flower (many hands use flowers)" : "flowers (many hands use them)") : "",
  ].filter(Boolean);
  const passLine = read.passes.length
    ? `Pass first: ${names(read.passes)}. ${read.passes.length === 1 ? "It fits" : "They fit"} nothing this rack is building.${read.spare.length ? ` Later passes: ${names(read.spare)}.` : ""}`
    : "Nothing on this rack is dead weight. On the last pass of each Charleston you may pass blind; otherwise give up the tiles your plan needs least.";
  const fill = read.passes.length && read.passes.length < 3
    ? " That is all the dead weight: for the rest of a three-tile pass, give up the tiles your plan needs least, or pass blind on the last pass."
    : "";
  const lines = [
    read.summary,
    passLine + fill,
    keeps.length ? `Keep your ${keeps.join(" and ")}.` : "",
    ...read.sections.filter((s) => s.verdict !== "poor" && s.id !== read.read).map((s) => `${s.name}: ${s.note}`),
    parsed.unreadable.length ? `Could not read: ${parsed.unreadable.join(", ")}.` : "",
    "Sections are the stable families of the yearly card; the player should check the exact lines on their own card.",
  ].filter(Boolean);
  const name = (id: string) => read.sections.find((s) => s.id === id)?.name ?? id;
  return {
    structuredContent: {
      tiles: read.tiles,
      read: read.read ? name(read.read) : null,
      shortlist: read.shortlist.map(name),
      summary: read.summary,
      passes: read.passes,
      spare: read.spare,
      sections: read.sections.map(({ name, verdict, note }) => ({ name, verdict, note })),
      unreadable: parsed.unreadable,
    },
    content: [{ type: "text" as const, text: lines.join("\n") }],
    _meta: { widget: { view: "rack", key: key(), read } },
  };
}

export function termResult(query: string, entry: GlossaryEntry | null) {
  const structured = entry
    ? { term: entry.term, definition: entry.definition, found: true }
    : { term: query, definition: "Not in the Mahj glossary.", found: false };
  const miss = `"${query}" is not in the Mahj glossary. If it is an American mah jongg term, explain it briefly without quoting the NMJL card. Glossary terms include ${COMMON_TERMS.join(", ")}.`;
  return {
    structuredContent: structured,
    content: [{ type: "text" as const, text: entry ? `${entry.term}: ${entry.definition}` : miss }],
  };
}
