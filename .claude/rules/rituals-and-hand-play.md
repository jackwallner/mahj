---
paths:
  - "Shared/Content/MahjMinuteContent.swift"
  - "Shared/Services/MahjMinuteStore.swift"
  - "MahjTrainer/Views/MahjMinuteView.swift"
  - "MahjTrainer/Views/GameNightPrepView.swift"
  - "Shared/Content/SessionBuilder.swift"
  - "Shared/Services/AppSettings.swift"
  - "Shared/Content/HandPlayEngine.swift"
  - "Shared/Services/HandPlayStore.swift"
  - "MahjTrainer/Views/Drills/HandPlayView.swift"
  - "Shared/Content/ReferenceContent.swift"
  - "MahjTrainer/Views/ReferenceView.swift"
  - "MahjTrainerTests/MahjMinuteTests.swift"
  - "MahjTrainerTests/HandPlayEngineTests.swift"
  - "MahjTrainerTests/ReferenceContentTests.swift"
  - "Shared/Content/EndlessPractice.swift"
---

# Mahj: game night, Play a Hand, and the reference

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

**Game-night rhythm (1.2, 2026-08-08):** Mahj+ now owns two recurring practice
rituals. `MahjMinuteContent` deterministically builds the same five questions
for every member on a local calendar day: two generated rack reads, one
authored Charleston decision, and two authored table judgments. Results and a
30-day archive stay on device in `MahjMinuteStore`; sharing uses the system
share sheet and needs no account or leaderboard. `GameNightPrepView` stores a
weekly game night in `AppSettings`, schedules a local notification, and opens
directly into `SessionBuilder.gameNightPrep`, which prioritizes due mistakes,
misses, the weakest room, and unseen member content in that order. Both
features are entirely Mahj+ gated. iPad support is free, with adaptive Home
columns, drill grids, readable content widths, and portrait and landscape
orientations.

**Play a Hand (1.3, 2026-09-03):** the answer to the app testing recognition
and never judgment. `HandPlayEngine` + `HandPlayView`: deal 13 off a real
152-tile wall, commit to one of the five `playableTargets`, then draw and
discard for `turnCount` (12) turns while the coach grades every throw.
Grading is arithmetic the player can check, not opinion: `value(of:target:)`
scores a rack by GROUPS (kong 4.2, pung 3.2, pair 1.7, single 0.6, off-family
0, joker 3.2 always), `bestDiscards` returns EVERY tile whose loss costs least
and all of them grade correct. Ties are real; inventing a single answer to have
something to mark wrong is how a teaching app loses trust. Deliberately NO
opponents or bots: "the AI feels rigged" is the category's most damaging
complaint and a drill app structurally avoids it. Choosing a different target
from the coach is never marked wrong; the hand is then graded against the
player's own choice. The choose screen shows `fittingTiles` (raw count) and
ranks by `value` (groups), which disagree on purpose, so the card says so.
`HandPlayStore` gives a FREE player one whole hand per calendar day (a mode
nobody has tried sells nothing) and `recordStart` is called when play begins,
not when the screen opens. Every throw records under
`PracticeSkill.handPlay`, which exists ONLY so those throws roll up into one
stats row: it is excluded from `PracticeSkill.endlessCases`, so it never shows
in the Endless picker or the Timed Challenge.

**Reference (1.3):** `ReferenceContent` + `ReferenceView`, free for everyone,
one tap from Home's toolbar book icon and a Settings row. A searchable glossary
(nicknames are matched but never shown: "soap", "news", "wild") plus a page per
card section with an ORIGINAL example rack. The toolbar is the right home for
it because the moment it is wanted is mid-game and it must cost Home no
vertical space.
