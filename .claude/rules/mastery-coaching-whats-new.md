---
paths:
  - "Shared/Services/Mastery.swift"
  - "Shared/Services/PracticeRecordStore.swift"
  - "Shared/Content/SessionBuilder.swift"
  - "Shared/Models/HandCategory.swift"
  - "Shared/Services/WhatsNew.swift"
  - "MahjTrainer/Views/WhatsNewSheet.swift"
  - "MahjTrainer/Views/Components/QuestionUI.swift"
  - "MahjTrainer/Views/RoomView.swift"
  - "MahjTrainer/Views/HomeView.swift"
  - "MahjTrainerTests/MasteryTests.swift"
  - "MahjTrainer/Views/SettingsView.swift"
---

# Mahj: mastery, coaching the miss, and What's New

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

**Mastery, not completions (1.3):** the room ring counts questions answered
right TWICE IN A ROW (`PracticeRecord.isKnown`), not drills opened, because
opening a drill once rewards tapping. An item lapses only a full interval past
due, so a weekly player does not watch rooms un-learn themselves. `Mastery.swift`
holds `MasteryLevel` (Learning / Solid / Sharp at 0.4 and 0.85 coverage),
`PracticeRecordStore.mastery(for:isMember:)` and `roomToWorkOn`. The denominator
excludes locked Mahj+ drills for a free player: a ring that can never close is
a nag. Generated skills never count toward it.

**Coaching the miss (1.3):** `QuickItem.choiceNotes` is parallel to `choices`
and rides the SAME permutation in `SessionBuilder.prepared`, or a note starts
explaining somebody else's wrong answer. Section questions derive theirs for
free from `HandCategory.requires` via `missNotes(for:answer:)`. The pager shows
`MissNoteCard` ("Why not X?") only on a wrong pick, plus a `RequeuedChip` when
the item genuinely re-enters the review schedule (never for generated items,
which can never come back).

**What's New sheet:** `WhatsNew` + `WhatsNewSheet`, shown once on the first
launch after an update. A FRESH install never sees it: onboarding calls
`WhatsNew.markCurrentAsBaseline()`. An onboarded player with no stored marker
is an upgrader from a pre-1.1 build and does get it. The sheet raises
`onUpgrade` rather than presenting `PaywallView` itself, because a sheet cannot
present another sheet while dismissing.
