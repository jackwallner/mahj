---
paths:
  - "Shared/Content/RackGenerator.swift"
  - "Shared/Content/CharlestonGenerator.swift"
  - "Shared/Content/DefenseGenerator.swift"
  - "Shared/Content/EndlessPractice.swift"
  - "Shared/Services/PracticeRecordStore.swift"
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

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

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
