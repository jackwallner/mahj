# American Mah Jongg accuracy audit — 2026-07-12

Reviewer: orchestrator (Opus), by direct read of every content file.
Scope: all instructional content in `Shared/Content/*.swift` plus the tile /
category models in `Shared/Models/`.

Method: each factual claim (tile counts, dragon-suit pairings, joker rules,
Charleston mechanics, calling/exposure rules, category "how to spot", and every
quiz/hand-match/keep-throw answer + explanation) was checked against standard
NMJL American Mah Jongg rules. Legal guardrail respected: all example hands are
original teaching hands; nothing here reproduces the copyrighted card.

## Verdict summary
- Items checked: ~120 (12 tile cards, 16 tile quizzes, 8 category cards, 8
  hand-match, 10 Charleston strategy cards, 9 Charleston scenarios, 14
  keep/throw cards, 6 advanced Charleston, 10 defense quizzes, 8 expert racks,
  6 how-to-play pages, + the Tile/HandCategory models).
- Overall: content is accurate and well-taught. The tile set (152 = 108+16+12+
  8+8), dragon-suit pairings (Red-Crak, Green-Bam, Soap/White-Dot), soap-as-zero,
  joker rules (groups of 3+, never pair/single/S&P, never passed, dead when
  discarded), quint/joker logic, 4-copies-max counting, "no chows" and
  colors-mean-different-suits, concealed-vs-exposed, hand size 13/14, and all
  category "how to spot" descriptions are CORRECT.
- 1 correctness/polish issue FIXED. 2 nuanced rules FLAGGED for your call (I did
  not rewrite them blind).

## FIXED
| File | Item(s) | Change |
| --- | --- | --- |
| TileBasicsContent.swift | `tiles-concealed`, `quiz-concealed`, `quiz-hand-size`, `quiz-dead-joker` | "mahj jongg" / "Mahj jongg" -> "mah jongg". The game / winning declaration is "Mah Jongg"; "mahj jongg" is a misspelling (the app brand "Mahj" is fine, the two-word game name is not). |
| KeepDiscardContent.swift | `kd-mahj-call` | "Yes! Mahj Jongg!" -> "Yes! Mah Jongg!" (same reason). |

No structural changes; `ContentValidityTests` invariants (ids, counts, em-dash
ban, 13/3-tile rules, free/Pro split) are untouched and should stay green. (Not
re-run headlessly this pass — edits are string-only; the full build/test runs in
the final verification task.)

## FLAGGED — needs your decision (I did NOT change these)

### F1. Joker-exchange timing / "dead hand" claim
- Where: `TileBasicsContent.swift` `quiz-joker-exchange` ("Yes, but only after
  you draw or call your 14th tile...") and `ProContent.swift` `pro-def-joker-swap`
  ("Exchange before you draw or call and your hand is ruled dead, so always draw
  or call first.").
- The core answer (you MAY redeem an exposed joker from any player's exposure on
  your turn by supplying the matching natural tile) is correct.
- The nuance I am not fully certain of is the strict "you must draw/call first or
  your hand is dead" assertion. Common NMJL guidance allows redeeming an exposed
  joker at any point during your own turn; the hard dead-hand-if-before-draw rule
  is stronger than what many sources state and may be a house/table convention.
- Recommendation: verify against your NMJL rulebook/Mah Jongg Made Easy. If it is
  not a firm rule, soften both to "on your turn, exchange the matching tile for
  the joker" and drop the dead-hand clause. If it IS the rule you teach, keep it.
  Either way this is a one-line copy edit once you confirm.

### F2. Blind-pass timing
- Where: `CharlestonContent.swift` `ch-blind` ("On the LAST pass of either
  Charleston..., you may pass 1-3 of the tiles being passed TO you without
  looking").
- The mechanic (pass received tiles unseen, 1-3, to avoid giving up your own) is
  right. The restriction to "the last pass of either Charleston" is narrower than
  the commonly taught rule (blind passes allowed on any pass EXCEPT the very
  first right pass of the first Charleston). Rules vary by table.
- Recommendation: confirm which convention you want to teach. If the permissive
  version, reword to "on any pass except the first." Low urgency; not wrong for
  many tables, just conservative.

## Notes (checked, correct, no change)
- Charleston order: first = right/across/left, optional second = left/across/
  right, then optional courtesy across (0-3, same count, agreed aloud). Correct.
- Courtesy pass is with the player across only. Correct.
- Second Charleston requires unanimous agreement; anyone may stop it. Correct.
- 1 Bam depicted as a bird; flowers all interchangeable; card colors = distinct
  suits. Correct.
- All hand-match / expert-rack decoy reasoning traced tile-by-tile and holds
  (even counts, pair counts, joker logic all check out).
