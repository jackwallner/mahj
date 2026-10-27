---
paths:
  - "Shared/Content/RackGenerator.swift"
  - "Shared/Content/CharlestonGenerator.swift"
  - "Shared/Content/DefenseGenerator.swift"
  - "Shared/Content/EndlessPractice.swift"
  - "Shared/Services/PracticeRecordStore.swift"
  - "Shared/Services/OrdinaryRunStore.swift"
  - "MahjTrainer/Views/Drills/OrdinaryRunEntryView.swift"
  - "MahjTrainerTests/OrdinaryRunStoreTests.swift"
  - "MahjTrainer/Views/Drills/PracticeRunView.swift"
  - "MahjTrainer/Views/EndlessPickerView.swift"
  - "MahjTrainer/Views/StatsView.swift"
  - "MahjTrainerTests/GeneratedPracticeTests.swift"
  - "MahjTrainerTests/RackGeneratorTests.swift"
  - "MahjTrainerTests/PracticeRecordStoreTests.swift"
  - "Shared/Content/SessionBuilder.swift"
  - "MahjTrainer/Views/Drills/QuickSessionView.swift"
---

# Mahj: generated practice

Moved verbatim from AGENTS.md. Loads when a matching file is read; update it here.

**Generated practice (1.1, 2026-07-30):** the authored sets are finite, so a
motivated player exhausted Mahj+ in two sittings and then paid for nothing new.
1.1 answers that with three Mahj+ modes on Home under TRAINING, all run by
`PracticeRunView` (Endless / Timed / Review), all built on the existing
`QuickItem` shape:
- **Endless Practice** (`RackGenerator`, `CharlestonGenerator`,
  `DefenseGenerator` + `EndlessPractice`) deals four skills procedurally,
  forever: rack reads, tile counts, Charleston passes and defensive discards.
  The generated Charleston question is a SINGLE-tile pass ("which of these four
  can you lose for free"), not the full three-tile pass, because a three-tile
  ranking is not gradeable without a coach; the authored drills still teach the
  whole pass. `DefenseGenerator` shows ONE opponent's exposures and rejects any
  deal where two pungs share a number, because that reads as Like Numbers
  rather than evens or odds and the safe discard would be a different tile.
  Since 2026-09-27 (content audit after player reports) it deals only
  evens/odds/369, never offers an honor as the safe tile (real cards put winds
  and dragons in number sections), keeps the safe tile outside any
  five-number run window holding both exposures (6 and 8 Bam want the 7), and
  gives it the other parity when both exposures share one (3 and 9 fit odds).
  Since 2026-10-11 (1.4 QA) the safe tile must sit outside EVERY section the
  exposures fit, and every bait tile inside every one (`sectionsFitting`): 3
  and 9 read as 369 and odds, so a 6 was safe under the odds read and graded
  wrong. Since 2026-10-18 (challenge answer audit) Endless and the challenge
  also require `DefenseGenerator.isUnarguable`: the safe tile never makes a
  sum with the two exposures (Addition hands: 5 and 7 with a 2 is
  5 + 7 = 12), the three numbers span seven or more (no run with room for
  two pungs holds them all), and never pungs of 2s and 6s (2026). The
  filter sits on top of `build`, so seeded output is unchanged; Android's
  Endless applies it too, and the parity fixture's `defenseFilter` holds the
  Kotlin port to Swift's verdicts.
  Defense explanations hedge the read ("the family their exposures point
  to", "Of these four it is the safest throw"): the table is a judgment,
  not a proof. A run is one suit, so only pungs in ONE suit get the
  "Consecutive Run in Bams from 2 to 4" sentence, and the challenge's
  run-trap tile (`withRunBait`) is the middle tile in that suit (it once
  put a Crak between two Dots and marked an equally safe tile wrong).
  Rack miss notes (2026-10-18): the run note says "never make
  three in a row" only when no three numbers are consecutive (it once
  called 3-4-5-6 a skip), and the Winds & Dragons note counts numbered
  tiles and honors instead of saying "mostly numbered" on joker-heavy
  racks, and ends "so it has little to build a Winds & Dragons hand
  from" (never "a Winds & Dragons hand is mostly winds and dragons":
  some card lines carry numbers). Kotlin matches, checked by the parity
  fixture's rack `missNotes`.
  `CharlestonGenerator` likewise rejects any core that does not read as
  exactly its own section (`RackGenerator.category`): a 369 core with no 6 is
  just odds, and an odd stray then fit the hand.
  Tile counting deals a joker question about one time in four
  (`jokerCountingItem`): eight in the set, held + exposed + discarded, so its
  answers run past four and the four-copy tests skip it.
  `RackGenerator` only generates the five sections whose
  read is UNAMBIGUOUS (evens/odds/369/consecutive/winds-dragons); Like Numbers
  and Quints stay authored because a single-number rack always doubles as evens
  or odds. Every rack is checked with `fits` against all five and thrown away
  if it reads as more than one, and distractors are only sections the rack does
  NOT fit. Generated racks are ORIGINAL structures, never card hands.
- **Fix My Mistakes** replays `PracticeRecordStore.reviewQueue()`, an SM-2-ish
  schedule over per-item history. An item leaves the queue after two correct in
  a row, not one.
- **Timed Challenge**: 90 seconds of mixed generated items, best score kept.

`PracticeRecordStore` records EVERY graded answer app-wide (each drill view
calls it alongside `progress.recordItem`). Generated ids are unique per
question, so they collapse onto one per-skill row and never enter the review
queue or the seen/missed sets, which would otherwise grow without bound.
`StatsView` (free for everyone) reads the per-room rollups.

`OrdinaryRunStore` saves one Home Quick Session or authored room drill,
including held answers and flashcard undo. The tour demo and recurring modes
keep their own interruption models. On iOS, the resume destination holds its
own snapshot so clearing the store for Start over or completion cannot remove
the destination. In Compose, construct the snapshot during composition and
persist it in `SideEffect`: reading answer state only inside the effect does
not observe a pick, so the held answer can be lost before Next.

Saved runs, 1.4.2 (review fixes): the slot only ever holds a run with an
answer (`OrdinaryRun.hasAnswers`). Drills save on the first answer, never on
appear: every drill used to save an empty run when it opened, so peeking at
another drill wiped a half-done one and Home offered "Resume Quick Session"
with nothing answered. An unanswered run never replaces the slot, the same
run undone back to nothing drops out, and an empty run left on disk by 1.4.1
is ignored on load. `resumable(besideOpenPane:isMember:)` also refuses a run
`isLocked` for this player: a room drill through `Room.isLocked`, a Quick
Session built with Mahj+ questions; the run stays on disk for a returning
member. Home's room-drill Resume card goes straight into the run
(`SavedOrdinaryRunView`, which checks the lock again). A saved Quick Session
has no card of its own: the Get Started card reads "Resume Quick Session" and
`QuickSessionView` picks the run up (skipping a locked one, which then builds
a fresh mix). Resume / Start over (`OrdinaryRunEntryView`) is only asked when
a room's drill row opens a drill with a saved run.
