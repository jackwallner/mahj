// Prints every word the plugin can say (lessons, full practice pools, glossary,
// sample rack reads, tool descriptions) for a content review.
import { lessonResult, practiceResult, rackResult, termResult } from "../src/tools.ts";
import { LEARN_TOPICS, lookUpTerm } from "../src/sessions.ts";
import { content } from "../src/content.ts";

const out = [];
const p = (s = "") => out.push(s);
for (const t of LEARN_TOPICS) {
  const r = lessonResult(t);
  p(`## LESSON ${t}`);
  for (const c of r._meta.widget.deck.cards) p(`- [${c.title}]${c.subtitle ? ` (${c.subtitle})` : ""}${c.lead ? ` LEAD: ${c.lead}` : ""}\n  ${c.body}${c.tip ? `\n  TIP: ${c.tip}` : ""}${c.tiles?.length ? `\n  TILES: ${c.tiles.join(" ")}` : ""}`);
  p();
}
for (const t of ["tiles", "reading", "charleston", "strategy", "table"]) {
  const r = practiceResult(t, 12);
  p(`## PRACTICE ${t} (${r._meta.widget.session.questions.length} shown of pool)`);
  p(`MODEL TEXT: ${r.content[0].text}`);
  for (const q of r._meta.widget.session.questions) {
    p(`- Q: ${q.prompt}${q.context ? ` [context: ${q.context}]` : ""}\n  TILES: ${q.tiles.join(" ")}`);
    if (q.kind === "choice") p(`  CHOICES: ${q.choices.map((c, i) => (i === q.answerIndex ? `*${c}*` : c)).join(" | ")}`);
    else p(`  PASS: ${q.pass.join(" ")}${q.also.length ? ` (also ok: ${q.also.join(" ")})` : ""}${q.tip ? `\n  TIP: ${q.tip}` : ""}`);
    p(`  WHY: ${q.explanation}`);
  }
  p();
}
p("## GLOSSARY");
for (const g of content.glossary) p(`- ${g.term} (${g.aliases.join(", ")}): ${g.definition}`);
p();
p("## SECTIONS (categories)");
for (const c of content.categories) p(`- ${c.displayName}: spot: ${c.howToSpot} | requires: ${c.requires}`);
p();
const racks = {
  evens: "2C 2C 4C 4C 6B 6B 8B 8D F J 1C 9B N",
  odds: "1B 1B 3B 5B 5C 7C 9D 9D F J 2C N RD",
  "369": "3C 3C 6C 6B 9B 9D 9D F GD 2B 7C E J",
  run: "1C 2C 3C 4C 5C 5B 5D F 8D 9D N W J",
  winds: "N N E E W S S RD GD SO F J 5C",
  likenum: "7C 7C 7B 7B 7D F F J 2C 4D N RD 1B",
  pairs: "2C 2C 5B 5B 8D 8D N N RD RD F F 9C",
  mess: "1C 4B 7D 2C 5B 8D N E RD GD F 3C 6B",
  year: "2C 2B SO SO 6D 6D F F J N 1C 9B 4C",
  junk: "foo bar 5C 5C 5C",
  short: "5C 6C",
  evensJokers: "2C 2C 2C 4C 4C 6B 6B 8D 8D F J J J",
  quints: "5C 7B 7B 7B 7D 7D 7D N F F J J J",
  torn: "2C 2C 4C 6C 8C 3B 5B 7B 9B N W F J",
  words: "north north east 5 dot 5 dots five crak soap joker flower 2 bam 2 bam 6 bam",
};
for (const [k, v] of Object.entries(racks)) {
  const r = rackResult(v.split(" "));
  p(`## RACK ${k}: ${v}`);
  p(r.content[0].text);
  p();
}
p("## TERM LOOKUPS");
for (const t of ["pung", "joker swap", "hot tile", "charleston", "blind pass", "dead hand", "soap", "exposure", "mahjong", "courtesy pass", "riichi", "kitty", "pushing"]) p(`- ${t} -> ${termResult(t, lookUpTerm(t)).content[0].text}`);
console.log(out.join("\n"));
