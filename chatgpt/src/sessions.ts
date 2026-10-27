// Turns the app's free drills into the two shapes the widget draws: a deck of
// cards to read, and a set of questions to answer.
import { content, type Drill, type GlossaryEntry } from "./content.ts";
import { ALL_TILES, racked, spokenName, type TileCode } from "./tiles.ts";

/** A lesson card. Cards with `choices` are self-tests: the widget asks before it shows `lead` and `body`. */
export type Card = { title: string; subtitle?: string; context?: string; lead?: string; body: string; tip?: string; tiles: TileCode[]; choices?: string[]; answerIndex?: number };
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
export type Session = { title: string; questions: Question[]; /** How many questions the topic holds. */ available: number };

export const LEARN_TOPICS = ["basics", "tiles", "sections", "charleston", "strategy"] as const;
export type LearnTopic = (typeof LEARN_TOPICS)[number];

export const PRACTICE_TOPICS = ["tiles", "reading", "charleston", "strategy", "table", "mixed"] as const;
export type PracticeTopic = (typeof PRACTICE_TOPICS)[number];

// Deals where several strays are equally good passes: any of `also` can
// stand in for the coach's `swap` picks, and the rest of the pass is required.
const PASS_ALSO: Record<string, { swap: TileCode[]; also: TileCode[] }> = {
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

// The app's Charleston lesson has no tiles on its cards; these show the tiles
// each card talks about.
const LESSON_TILES: Record<string, TileCode[]> = {
  "ch-what": ["1B", "9D", "W"],
  "ch-first-look": ["2C", "4C", "6B", "8B", "8D", "N"],
  "ch-jokers": ["J"],
  "ch-flowers": ["F", "F"],
  "ch-pairs": ["5C", "5C", "9B", "E"],
  "ch-telegraph": ["2C", "4C", "6C"],
};

// The app's closing primer page points at its drill rooms; here it points at
// what the plugin can do instead.
const PRIMER_COPY: Record<string, string> = {
  "htp-ready": "That's the whole shape of the game. Build toward the card, get through the Charleston, and learn to read a rack fast. Ask for practice on any part of it, or share your 13 tiles for a read.",
};

/// A lead + body, without doubling the punctuation.
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
/// A card with a self-test carries its choices so the player answers first.
function flashcard(item: Item): Card {
  const front = String(item.frontTitle).toLowerCase(), back = String(item.backTitle).toLowerCase();
  const restates = back.startsWith(front) || front.startsWith(back);
  const tiles = item.frontTiles?.length ? item.frontTiles : LESSON_TILES[item.id] ?? [];
  return {
    title: item.frontTitle,
    subtitle: item.frontSubtitle,
    lead: restates ? undefined : item.backTitle,
    body: item.backBody,
    tiles,
    ...(item.choice ? { choices: item.choice.options, answerIndex: item.choice.answerIndex } : {}),
  };
}

/// A keep-or-throw card reads as its situation, then the question.
function judgmentCard(item: Item): Card {
  const copy = QUESTION_COPY[item.id];
  const { subtitle: _, ...card } = flashcard(item);
  return { ...card, context: copy?.context ?? item.frontTitle, title: copy?.prompt ?? item.frontSubtitle };
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
      return { title: "Keep or throw", cards: drill("judgment-cards").items.map(judgmentCard) };
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

// Telling the tiles apart, drawn from the set: each suit, a wind, a dragon and
// a flower or joker, so the tile quiz is not all rules about jokers.
const NAMING_HINT: Record<string, string> = {
  C: "Craks show a number over a red character.",
  B: "Bams are green sticks, so count them.",
  D: "Dots are circles, so count them.",
};

function namingQuestion(code: TileCode): ChoiceQuestion {
  const name = spokenName(code);
  let others: TileCode[];
  if (/^[1-9][CBD]$/.test(code)) {
    const r = Number(code[0]), suit = code[1];
    others = [...["C", "B", "D"].filter((x) => x !== suit).map((x) => `${r}${x}`), `${r === 9 ? 8 : r + 1}${suit}`];
  } else if (["N", "E", "W", "S"].includes(code)) {
    others = ["N", "E", "W", "S"].filter((x) => x !== code);
  } else {
    others = ["RD", "GD", "SO", "F", "J"].filter((x) => x !== code).slice(0, 3);
  }
  const why = code === "1B"
    ? "The 1 Bam is usually drawn as a bird, not a single stick."
    : /^[1-9][CBD]$/.test(code) ? `${NAMING_HINT[code[1]]} This is the ${name}.`
    : code === "SO" ? "The Soap is the White Dragon: a blank or framed white tile, the dots' dragon and the zero in year hands."
    : code === "RD" ? "The Red Dragon (中) is the craks' dragon."
    : code === "GD" ? "The Green Dragon (發) is the bams' dragon."
    : code === "F" ? "Flowers come in many designs, and all eight count as the same tile."
    : code === "J" ? "Jokers are marked JOKER. There are eight."
    : `Winds show their letter. This is ${name}.`;
  return { kind: "choice", id: `name-${code}`, prompt: "Which tile is this?", tiles: [code], choices: [name, ...others.map(spokenName)], answerIndex: 0, explanation: why };
}

function namingQuestions(): ChoiceQuestion[] {
  const pick = <T,>(items: T[]) => items[Math.floor(Math.random() * items.length)];
  const suited = shuffle(["C", "B", "D"]).map((suit) => `${pick([1, 2, 3, 4, 5, 6, 7, 8, 9])}${suit}`);
  return [...suited, pick(["N", "E", "W", "S"]), pick(["RD", "GD", "SO"]), pick(["F", "J"])].map(namingQuestion);
}

/// Naming questions plus the tile quiz, with at most three of its joker rules.
function tileQuestions(): Question[] {
  const quiz = drill("tile-quiz").items.map(fromQuiz);
  const jokerRule = (q: ChoiceQuestion) => /joker|quint/.test(q.id);
  return [...namingQuestions(), ...quiz.filter((q) => !jokerRule(q)), ...shuffle(quiz.filter(jokerRule)).slice(0, 3)];
}

const PRACTICE: Record<Exclude<PracticeTopic, "mixed">, { title: string; questions: () => Question[] }> = {
  tiles: { title: "Tile check", questions: tileQuestions },
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
    return { title: "Mixed practice", questions: shuffle(questions).map(shuffleChoices), available: pools.reduce((n, p) => n + p.length, 0) };
  }
  const { title, questions } = PRACTICE[topic];
  const pool = questions();
  return { title, questions: shuffle(pool).slice(0, count).map(shuffleChoices), available: pool.length };
}

/// Any practice question by id, unshuffled, for checking a typed answer.
export function findQuestion(id: string): Question | null {
  const named = id.match(/^name-(.+)$/);
  if (named) return ALL_TILES.includes(named[1]) ? namingQuestion(named[1]) : null;
  const pools: [string, (item: Item) => Question][] = [["tile-quiz", fromQuiz], ["hand-match", fromHandMatch], ["charleston-pass", fromCharleston], ["judgment-cards", fromJudgment], ["table-quiz", fromQuiz]];
  for (const [drillId, make] of pools) {
    const item = drill(drillId).items.find((i: Item) => i.id === id);
    if (item) return make(item);
  }
  return null;
}

// Glossary lookup. Words that carry no meaning in a question are dropped, and
// a plural "s" is trimmed, so "What are kongs?" and "joker exchange rules"
// reduce to the words of a term. A term matches when its words are exactly the
// query's, in any order; otherwise the longest term whose words all appear in
// the query wins, but only when the query's other words name nothing else in
// the glossary (so "dead wall" is not "Wall").
const QUESTION_WORDS = new Set(["what", "whats", "is", "are", "a", "an", "the", "does", "do", "did", "i", "you", "me", "my", "we", "how", "when", "can", "should", "mean", "means", "meaning", "define", "definition", "of", "explain", "tell", "about", "in", "on", "for", "to", "rule", "rules", "american", "mah", "jongg", "jong", "mahjong", "mahjongg", "game", "term", "called", "it", "this", "that"]);

const stem = (word: string) => (word.length > 3 && word.endsWith("s") && !word.endsWith("ss") ? word.slice(0, -1) : word);

function words(text: string): string[] {
  return text.toLowerCase().replace(/['\u2019]/g, "").replace(/[^a-z0-9]+/g, " ").trim().split(" ").filter((w) => w && !QUESTION_WORDS.has(w)).map(stem);
}

const NAMES = content.glossary.flatMap((entry) => [entry.term, ...entry.aliases].map((name, i) => ({ entry, words: words(name), canonical: i === 0 })));
const KNOWN_WORDS = new Set(NAMES.flatMap((n) => n.words));

export function lookUpTerm(query: string): GlossaryEntry | null {
  const q = words(query);
  if (!q.length) return null;
  const key = (w: string[]) => [...w].sort().join(" ");
  const exact = NAMES.filter((n) => n.words.length && key(n.words) === key(q)).sort((a, b) => Number(b.canonical) - Number(a.canonical));
  if (exact.length) return exact[0].entry;
  const inside = NAMES.filter((n) => n.words.length && n.words.every((w) => q.includes(w)))
    .filter((n) => q.filter((w) => !n.words.includes(w)).every((w) => !KNOWN_WORDS.has(w)))
    .sort((a, b) => b.words.length - a.words.length || Number(b.canonical) - Number(a.canonical));
  return inside[0]?.entry ?? null;
}

/// A few terms to offer when a lookup misses.
export const COMMON_TERMS = ["pung", "kong", "quint", "soap", "exposure", "joker swap", "Charleston", "blind pass", "courtesy pass", "dead hand", "hot tile"];
