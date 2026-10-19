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

Moved verbatim from AGENTS.md. Loads when a matching file is read; update it here.

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
free from `HandCategory.requires` via `missNotes(for:answer:)`. Rack reads
use `RackGenerator.missNotes`, which names the tiles that rule a section
out; when nothing does, it says the answer is the stronger read (2026-10-18:
the old fallback restated what the section wants, which on a rack that half
fits it argued for the wrong answer). Not yet ported to Kotlin. The pager shows
`MissNoteCard` ("Why not X?") only on a wrong pick, plus a `RequeuedChip` when
the item genuinely re-enters the review schedule (never for generated items,
which can never come back).

**What's New sheet:** `WhatsNew` + `WhatsNewSheet`, shown once on the first
launch after an update. A FRESH install never sees it: onboarding calls
`WhatsNew.markCurrentAsBaseline()`. An onboarded player with no stored marker
is an upgrader from a pre-1.1 build and does get it. The sheet raises
`onUpgrade` rather than presenting `PaywallView` itself, because a sheet cannot
present another sheet while dismissing. Home shows it only on a bare Home
(`homeIsBare`), so a notification or `mahj://challenge` launch opens its
screen first and the sheet waits for the player to come back, and it is
marked seen as it is shown (a swipe-down dismiss would otherwise bring it
back every time Home is bare again).

**1.4.1 update notes (2026-10-16):** 1.4.0 was pulled before release, so its
release entry was renamed to 1.4.1 (build 47): a 1.3.2 player sees the 1.4
features once. A TestFlight install that saw the 1.4.0 sheet sees it again,
which is fine. The experience audit is in
`project-docs/audits/release-experience-2026-10-16.md`.

**Weekly gain access-change gap (2026-10-16):** the actual record-store/ledger
probe reports new weekly learning when previously known paid questions become
accessible again, without additional answers. Membership-filtered ring totals
are correct for room coverage, but their delta is not always a learning delta.
Both build 45 and 46 share this implementation. Proof is in the same audit.
