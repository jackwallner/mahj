// Tool results. `structuredContent` and `content` are what the model reads;
// `_meta.widget` is the widget's own payload, hidden from the model.
import { type GlossaryEntry } from "./content.ts";
import { readRack } from "./rack.ts";
import { learnDeck, type LearnTopic, practiceSession, type PracticeTopic, type Question } from "./sessions.ts";
import { parseRack, spokenName } from "./tiles.ts";

const key = () => crypto.randomUUID();

const PRACTICE_LABEL: Record<LearnTopic, string> = {
  basics: "the basics",
  tiles: "the tiles",
  sections: "reading a rack",
  charleston: "the Charleston",
  strategy: "keep or throw",
};

export function lessonResult(topic: LearnTopic) {
  const deck = learnDeck(topic);
  const cards = deck.cards.map((c) => ({ title: c.title, body: c.body }));
  const text = [`${deck.title}:`, ...cards.map((c) => `- ${c.title}: ${c.body}`)].join("\n");
  return {
    structuredContent: { title: deck.title, cards },
    content: [{ type: "text" as const, text }],
    _meta: { widget: { view: "learn", key: key(), deck: { ...deck, practice: true, practiceLabel: PRACTICE_LABEL[topic] } } },
  };
}

function answerText(q: Question): string {
  return q.kind === "pass" ? q.pass.map(spokenName).join(", ") : q.choices[q.answerIndex];
}

export function practiceResult(topic: PracticeTopic, count: number) {
  const session = practiceSession(topic, count);
  const questions = session.questions.map((q) => ({
    prompt: q.prompt,
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

export function rackResult(raw: string[]) {
  const parsed = parseRack(raw);
  if (parsed.tooMany.length) {
    const error = `An American set has only four of each tile (eight flowers, eight jokers), and this rack has more ${parsed.tooMany.map(spokenName).join(", ")} than that. Check the tiles and try again.`;
    return { structuredContent: emptyRead(parsed, error), content: [{ type: "text" as const, text: error }], _meta: { widget: { key: key(), error } } };
  }
  if (parsed.tiles.length < 5) {
    const error = "Share at least five tiles, ideally the whole 13-tile rack, so there is enough to read.";
    return { structuredContent: emptyRead(parsed, error), content: [{ type: "text" as const, text: error }], _meta: { widget: { key: key(), error } } };
  }
  const read = readRack(parsed.tiles);
  const lines = [
    read.summary,
    read.passes.length ? `Passing candidates (fit nothing the rack leans to): ${read.passes.map(spokenName).join(", ")}.` : "",
    ...read.sections.filter((s) => s.verdict !== "poor").map((s) => `${s.name}: ${s.note}`),
    parsed.unreadable.length ? `Could not read: ${parsed.unreadable.join(", ")}.` : "",
    "Sections are the stable families of the yearly card; the player should check the exact lines on their own card.",
  ].filter(Boolean);
  return {
    structuredContent: {
      tiles: read.tiles,
      read: read.read ? read.sections.find((s) => s.id === read.read)?.name ?? null : null,
      summary: read.summary,
      passes: read.passes,
      sections: read.sections.map(({ name, verdict, note }) => ({ name, verdict, note })),
      unreadable: parsed.unreadable,
    },
    content: [{ type: "text" as const, text: lines.join("\n") }],
    _meta: { widget: { view: "rack", key: key(), read } },
  };
}

function emptyRead(parsed: ReturnType<typeof parseRack>, summary: string) {
  return { tiles: parsed.tiles, read: null, summary, passes: [], sections: [], unreadable: parsed.unreadable };
}

export function termResult(query: string, entry: GlossaryEntry | null) {
  const structured = entry
    ? { term: entry.term, definition: entry.definition, found: true }
    : { term: query, definition: "Not in the Mahj glossary.", found: false };
  return {
    structuredContent: structured,
    content: [{ type: "text" as const, text: entry ? `${entry.term}: ${entry.definition}` : `"${query}" is not in the Mahj glossary.` }],
  };
}
