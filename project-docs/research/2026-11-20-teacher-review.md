# Teacher review, 2026-11-20

A mah jongg teacher who got a free code from the teacher outreach ran through the
full app (member, so Master Tables racks were in her Quick Sessions) and sent nine
screenshots. Her bar: a student with one or two lessons. Her verdict: parts are
excellent for that student (she singled out Endless Practice), other parts are
ambiguous or over a beginner's head.

## Her points and what was done

| # | Her point | Item | Verdict | Change |
|---|---|---|---|---|
| 1 | Endless Practice is excellent: simple questions, clear answers | Endless Practice | Praise | None |
| 2 | Singles and Pairs card says drop the third flower; another card says hold a spare flower | `more-judge-flower-discipline` vs `kd-third-flower` | Fixed | Card now agrees: early, hold the third flower as a pivot; let it go once you are sure of the hand |
| 3 | Call priority has no fully correct choice (the mah jongg exception is only in the note) | `table-call-priority` | Fixed | Prompt states neither caller needs it for mah jongg; answer reads "next in turn after the discarder"; note names mah jongg as the only call that beats turn order. Mah jongg vs exposure already has its own question (Tile Room extras) |
| 4 | 2026 vs 2468 is too close for a new player | `hm-year` (free Card Room) | Fixed | Rack is now 2s, Soaps, 6s in craks only, with flowers and a joker; 2468 is no longer a choice (13579, Winds & Dragons, Consecutive Run instead). The 2468 decoy stays in Master Tables (`pro-rack-4`) and the Mahj+ set (`plus-hm-year`), which are the harder tiers |
| 5 | "How many tiles in a set" is the least useful fact | `plus-tq-set-size` | Fixed | Replaced with `plus-tq-hand-size`: a finished hand is 14 tiles, every card line totals 14. The 152 fact stays on the Tile Room card |
| 6 | Pung and kong come up early without definitions | `table-call-then-what` | Fixed, partly | Prompt defines pung inline. The root cause is Quick Session ordering, below |
| 7 | "Never straddle two sections" is too absolute | `plus-kd-commit` | Fixed | Keeping two hands alive is smart while you still have tiles that fit neither; commit once every discard costs one of them. Scenario now says you are at that point |
| 8 | Singles and Pairs rack: pairs split across three suits, not a real S&P shape; steer beginners away from S&P | `pro-rack-6` (Master Tables) | Fixed | Six pairs in one suit (1 to 6 Bam) plus a North; note says S&P is hard to finish without jokers, chase it only when most of the rack is pairs. Stays in Master Tables, the advanced room |
| 9 | Never show 2026 with mixed suits | Onboarding hero, `cat-year` card | Fixed | 2 Crak, Soap, 2 Crak, 6 Crak on iOS and Android |
| 10 | Split into basic, intermediate, challenging | Whole app | Proposed | Below, for Jack |

## Proposal: basic, intermediate, challenging

**What it gets you:** a new student's first sessions only ask what a student with
one or two lessons can answer, which is the bar every teacher will judge by.

What she hit is mostly ordering, not the content itself. `SessionBuilder.quickSession`
shuffles every item the player is entitled to (free rooms, the Mahj+ sets and, for
members, Master Tables) into one pool, ordered only by missed/unseen/seen. So a
member's first Quick Session can open on a Master Tables decoy rack, and a pung
question can come before the Tile Room has defined a pung. Onboarding already asks
for a skill level (`mahj.skillLevel`), but only the primer and the recommended room
read it.

Recommendation:

1. Give every item a tier: **Basic** (tile names, groups, jokers, flowers, one
   clear section per rack, table procedure), **Intermediate** (keep or throw,
   decoys between two sections, Charleston judgment), **Challenging** (defense,
   counting, Master Tables). First cut by room: the free drills are Basic, the
   Mahj+ extra sets Intermediate, Master Tables Challenging, then hand-move the
   exceptions (Table Room procedure questions are Basic; some free keep-or-throw
   cards are Intermediate).
2. Quick Session for a "new" player draws Basic only until they have seen most of
   it, then mixes in Intermediate; Challenging only after that or by choice. "Some"
   and "experienced" players keep today's mix.
3. Show the tier on each room or drill row ("Basic", "Next step", "Challenge")
   rather than a new screen, so the lobby stays as it is.
4. Teacher copy: once tiers exist, the outreach email can say "start your
   students on Basic", which answers her concern directly.

Out of scope here: no code for tiers was written. The trial flow is untouched.
