# Single-question learn guides, 2026-11-12

Nine new rules guides under `docs/learn/`, each answering one question a new player types. Pattern copied from the guides that reached Google positions 7 to 10 within a month (answer in the first two sentences, then the rule, table variations, a worked example, five open FAQ answers).

## Evidence

- **Search Console** (jackwallner.com, pages under /ios/mahj/, last 90 days): 23 queries, almost all brand. Rules queries with impressions: "what is soap in mahjong" and three variants (5 impressions, positions 7 to 28), "a quint must have a joker unless it is flowers" (pos 10), "can you pass a joker during the charleston" (pos 26), "courtesy pass in mahjong" (pos 88), "when can you stop the charleston" (pos 60).
- **Google People Also Ask**, 13 searches (`gl=us&hl=en&pws=0`): dead hand ("should you call someone's hand dead", "can you pull jokers from a dead hand"), mahjong in error ("what happens if you call mahjong wrong"), exposures ("can you add to an exposed pung", "what is an invalid exposure", "can you ever expose NEWS"), calling ("can I pick up a discard if it doesn't form a meld", "can you pick up a discard to replace a joker", "can you call a discard for mahjong on a concealed hand"), soap ("is soap the only 0"), quints ("can a pung be 3 jokers"), flowers ("8 or 16 flowers"), wall ("how many tiles make a wall", "who goes first", "deal to the right or left"), joker exchange ("on your own hand", "for mahjong").

## Pages

| URL | Target question |
|---|---|
| /ios/mahj/learn/dead-hand.html | What is a dead hand in mahjong? |
| /ios/mahj/learn/mahjong-in-error.html | What happens if you call mahjong wrong? |
| /ios/mahj/learn/exposure-rules.html | Mahjong exposure rules: can you add to an exposed pung? |
| /ios/mahj/learn/calling-a-discard.html | When can you call a discard in mahjong? |
| /ios/mahj/learn/soap-in-mahjong.html | What is soap in mahjong? |
| /ios/mahj/learn/quints.html | What is a quint in mahjong? |
| /ios/mahj/learn/joker-exchange.html | How does a joker exchange work in mahjong? |
| /ios/mahj/learn/flowers.html | How many flowers are in American mahjong? |
| /ios/mahj/learn/building-the-wall.html | How do you build the wall and deal in American mahjong? |

Linked from `docs/learn/index.html` (hub cards), `docs/index.html` (Learn section), and the Keep reading lists of `jokers.html` and `scoring-and-table-rules.html`.

## Skipped on purpose

- Every Charleston subtopic (stopping the Charleston, courtesy pass, passing jokers). `learn/charleston.html` and `learn/how-to-play-american-mahjong.html` are frozen outreach controls until Dec 11, so no new page targets their queries, links to them, or edits them.
- Pung/kong/quint definitions beyond the quint page, and joker basics: `glossary.html` and `jokers.html` already answer them.

## Rule checks

Every rule was checked against the app's own content (`Shared/Content/ReferenceContent.swift` glossary, `MoreContent.swift`, `TileBasicsContent.swift`, `HowToPlayContent.swift`) and published sources: Tom Sloper's FAQ (sloperama.com/mjfaq/mjfaq19.html), schoolofmahjong.com's NMJL-style reference, ilovemahj.com's getting-started guide, mahjparlour.com. Where tables differ, each page says so in a "Where tables play it differently" section. Unverified: the exact League penalty when other players threw in their hands after a wrong mah jongg (no primary text found), so that page states only that League rules are stricter.

## Verification

2026-11-12, after the mirror deployed (commits 58b9f58 and 938c6c9):

- All nine URLs return 200 on jackwallner.com, serve the latest copy, and carry no meta refresh on the mirror.
- All nine are in https://jackwallner.com/sitemap.xml, and their `.html.md` twins return 200.
- `python3 ~/portfolio/scripts/indexnow.py`: IndexNow 200, 303 URLs submitted.
- An independent Sonnet fact-check pass flagged 12 items; the fixes went in before the second commit (wrong-claim penalty, soap count, exposure fix window closing on a joker swap, call window closing on a joker swap, sextet and all-joker wording, answer-first lines).

Next read: add the nine URLs to the weekly watch list; first Search Console read about two weeks after indexing.
