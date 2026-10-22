// Turns the app's free drills into the two shapes the widget draws: a deck of
// cards to read, and a set of questions to answer.
import { content, type Drill, type GlossaryEntry } from "./content.ts";
import { racked, type TileCode } from "./tiles.ts";

export type Card = { title: string; subtitle?: string; lead?: string; body: string; tip?: string; tiles: TileCode[] };
export type Deck = { title: string; cards: Card[] };

export type ChoiceQuestion = {
  kind: "choice";
  id: string;
  prompt: string;
  context?: string;
  tiles: TileCode[];
  choices: string[];
  answerIndex: number;
  explanation: string;
};
export type PassQuestion = {
  kind: "pass";
  id: string;
  prompt: string;
  tiles: TileCode[];
  pass: TileCode[];
  /** Tiles just as good as the coach's `swap` picks, for deals with interchangeable strays. */
  also: TileCode[];
  swap: TileCode[];
  explanation: string;
  tip?: string;
};
export type Question = ChoiceQuestion | PassQuestion;
export type Session = { title: string; questions: Question[] };

export const LEARN_TOPICS = ["basics", "tiles", "sections", "charleston", "strategy"] as const;
export type LearnTopic = (typeof LEARN_TOPICS)[number];

export const PRACTICE_TOPICS = ["tiles", "reading", "charleston", "strategy", "table", "mixed"] as const;
export type PracticeTopic = (typeof PRACTICE_TOPICS)[number];

// Deals where several strays are equally good passes: any of `also` can
// stand in for the coach's `swap` picks, and the rest of the pass is required.
const PASS_ALSO: Record<string, { swap: TileCode[]; also: TileCode[] }> = {
  "cs-junk": { swap: ["1D", "9C", "5B"], also: ["2C", "8D"] },
  "cs-commit": { swap: ["3B"], also: ["5B", "7B", "9B"] },
};

// Practice reads a flashcard as a question, so a few fronts are reworded to
// ask what the choices answer.
const QUESTION_COPY: Record<string, { context: string; prompt: string }> = {
  "kd-count-four": { context: "Counting the tiles you can see tells you when a hand can no longer be made.", prompt: "How many 5 Craks exist in the whole set?" },
  "kd-call-cost": { context: "Someone discards a tile you could call for an exposed pung.", prompt: "Should you call it?" },
  "kd-joker-swap": { context: "An opponent's exposed kong on the table shows 6 Bam, 6 Bam, joker, 6 Bam.", prompt: "You just drew the real 6 Bam. Now what?" },
  "kd-follow-count": { context: "Two tiles fit Hand A. Nine tiles fit Hand B. You like Hand A better.", prompt: "Which do you play?" },
};

// The app's closing primer page points at its drill rooms; here it points at
// what the plugin can do instead.
const PRIMER_COPY: Record<string, string> = {
  "htp-ready": "That's the whole shape of the game: build toward the card, survive the Charleston, and read racks fast. Ask for practice on any part of it, or share your 13 tiles for a read.",
};

/// "Swap It!" + body, without doubling the punctuation.
function sentence(title: string, body: string): string {
  return `${title}${/[.!?]$/.test(title) ? "" : "."} ${body}`;
}

function drill(id: string): Drill {
  const found = content.drills.find((d) => d.id === id);
  if (!found) throw new Error(`missing drill ${id}`);
  return found;
}

// deno-lint-ignore no-explicit-any
type Item = Record<string, any>;

/// A flashcard laid flat: the front is the heading, and the back's title
/// leads the answer unless it only restates the front ("Bams (Bamboo)").
function flashcard(item: Item): Card {
  const front = String(item.frontTitle).toLowerCase(), back = String(item.backTitle).toLowerCase();
  const restates = back.startsWith(front) || front.startsWith(back);
  return {
    title: item.frontTitle,
    subtitle: item.frontSubtitle,
    lead: restates ? undefined : item.backTitle,
    body: item.backBody,
    tiles: item.frontTiles ?? [],
  };
}

export function learnDeck(topic: LearnTopic): Deck {
  switch (topic) {
    case "basics":
      return {
        title: "How American Mah Jongg works",
        cards: content.primer.map((p) => ({ title: p.title, body: PRIMER_COPY[p.id] ?? p.body, tip: p.tip, tiles: p.tiles })),
      };
    case "tiles":
      return { title: "Meet the tiles", cards: drill("meet-tiles").items.map(flashcard) };
    case "sections":
      return { title: "The sections of the card", cards: drill("category-cards").items.map(flashcard) };
    case "charleston":
      return { title: "The Charleston", cards: drill("charleston-rules").items.map(flashcard) };
    case "strategy":
      return {
        title: "Keep or throw",
        cards: drill("judgment-cards").items.map((item: Item) => ({ ...flashcard(item), title: item.frontSubtitle, subtitle: item.frontTitle })),
      };
  }
}

function fromQuiz(item: Item): ChoiceQuestion {
  return {
    kind: "choice",
    id: item.id,
    prompt: item.prompt,
    tiles: item.tiles ?? [],
    choices: item.choices,
    answerIndex: item.answerIndex,
    explanation: item.explanation,
  };
}

function fromHandMatch(item: Item): ChoiceQuestion {
  const names = item.choices.map((id: string) => content.categories.find((c) => c.id === id)?.displayName ?? id);
  return {
    kind: "choice",
    id: item.id,
    prompt: "Which section fits this rack best?",
    tiles: racked(item.tiles),
    choices: names,
    answerIndex: item.choices.indexOf(item.answer),
    explanation: item.explanation,
  };
}

function fromJudgment(item: Item): ChoiceQuestion {
  return {
    kind: "choice",
    id: item.id,
    prompt: QUESTION_COPY[item.id]?.prompt ?? item.frontSubtitle,
    context: QUESTION_COPY[item.id]?.context ?? item.frontTitle,
    tiles: item.frontTiles ?? [],
    choices: item.choice.options,
    answerIndex: item.choice.answerIndex,
    explanation: sentence(item.backTitle, item.backBody),
  };
}

function fromCharleston(item: Item): PassQuestion {
  return {
    kind: "pass",
    id: item.id,
    prompt: item.situation,
    tiles: racked(item.deal),
    pass: item.recommendedPass,
    also: PASS_ALSO[item.id]?.also ?? [],
    swap: PASS_ALSO[item.id]?.swap ?? [],
    explanation: item.reasoning,
    tip: item.tip,
  };
}

const PRACTICE: Record<Exclude<PracticeTopic, "mixed">, { title: string; questions: () => Question[] }> = {
  tiles: { title: "Tile check", questions: () => drill("tile-quiz").items.map(fromQuiz) },
  reading: { title: "Read the rack", questions: () => drill("hand-match").items.map(fromHandMatch) },
  charleston: { title: "Pick your pass", questions: () => drill("charleston-pass").items.map(fromCharleston) },
  strategy: { title: "Keep or throw", questions: () => drill("judgment-cards").items.map(fromJudgment) },
  table: { title: "Table rules", questions: () => drill("table-quiz").items.map(fromQuiz) },
};

function shuffle<T>(items: T[]): T[] {
  const out = [...items];
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}

/// Choices are shuffled so the right answer is not always first, the way the
/// app's ChoiceShuffle does it.
function shuffleChoices(q: Question): Question {
  if (q.kind !== "choice" || q.choices.some((c) => /^(both|all|none|neither)\b/i.test(c))) return q;
  const order = shuffle(q.choices.map((_, i) => i));
  return { ...q, choices: order.map((i) => q.choices[i]), answerIndex: order.indexOf(q.answerIndex) };
}

export function practiceSession(topic: PracticeTopic, count: number): Session {
  if (topic === "mixed") {
    const pools = Object.values(PRACTICE).map((p) => shuffle(p.questions()));
    const questions: Question[] = [];
    for (let i = 0; questions.length < count && i < 20; i++) {
      for (const pool of pools) if (pool[i] && questions.length < count) questions.push(pool[i]);
    }
    return { title: "Mixed practice", questions: shuffle(questions).map(shuffleChoices) };
  }
  const { title, questions } = PRACTICE[topic];
  return { title, questions: shuffle(questions()).slice(0, count).map(shuffleChoices) };
}

export function lookUpTerm(query: string): GlossaryEntry | null {
  const norm = (s: string) => s.trim().toLowerCase().replace(/[-_]/g, " ").replace(/\s+/g, " ").replace(/s$/, "");
  const q = norm(query);
  if (!q) return null;
  return (
    content.glossary.find((g) => norm(g.term) === q || g.aliases.some((a) => norm(a) === q)) ??
    (q.length >= 3 ? content.glossary.find((g) => norm(g.term).includes(q) || q.includes(norm(g.term))) : undefined) ??
    null
  );
}

/// A few terms to offer when a lookup misses.
export const COMMON_TERMS = ["pung", "kong", "quint", "soap", "exposure", "joker swap", "Charleston", "blind pass", "courtesy pass", "dead hand", "hot tile"];
