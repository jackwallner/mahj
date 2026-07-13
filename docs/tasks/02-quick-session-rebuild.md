# Task 02 — Quick Session rebuild + answer-position variety + harder dopamine

Owner: Sonnet subagent, dispatched by the Opus orchestrator.
Repo: /Users/jackwallner/mahj (SwiftUI iOS app "Mahj Trainer").

## Why
The current Quick Session (`MahjTrainer/Views/Drills/MixedSessionView.swift`)
mixes three heterogeneous item types (plain flashcards with flip + self-grade,
CardChoice cards, quizzes, hand-match) plus a per-switch "SessionBeat"
interstitial. It glitches when you pick the right answer and sometimes appears
to skip past the correct answer to the next item. The product decision is to
REBUILD Quick Session as its own cohesive, choice-only mode that reuses content
from the rooms, rather than packing three interactions into one screen.

## Scope (do all of this in one coherent pass)

### A. Rebuild Quick Session as a choice-only mode
- New view `QuickSessionView` and a builder that produces a NORMALIZED
  single-select item. Define e.g.:
  ```
  struct QuickItem: Identifiable, Sendable {
    let id: String
    let prompt: String
    let tiles: [Tile]
    let choices: [String]
    let answerIndex: Int
    let explanation: String
    let sourceLabel: String   // e.g. "Tile Room", for a small tag
  }
  ```
- Build the pool from choice-gradeable content ONLY:
  - `QuizQuestion` -> QuickItem directly.
  - `HandMatchQuestion` -> choices = `choices.map(\.displayName)`, answerIndex =
    index of `answer`, prompt = "Which section is this rack chasing?", tiles =
    racked tiles.
  - `Flashcard` WITH a `CardChoice` -> prompt = frontTitle (+ frontSubtitle if
    present), tiles = frontTiles, choices = choice.options, answerIndex =
    choice.answerIndex, explanation = backBody.
  - EXCLUDE plain flashcards (no CardChoice) entirely — a flip card is not
    right/wrong and does not belong here.
  - EXCLUDE Charleston (too interaction-heavy; stays a room drill).
- Keep the existing priority tiering (missed first, then unseen, then review)
  and the free/Pro filter (exclude Pro content when `!includePro`). Reuse the
  logic in `Shared/Content/SessionBuilder.swift` — you may replace `MixedItem`/
  `dailyMix` with the new `QuickItem`/builder, or add a new builder and delete
  the old one. Keep `SessionBuilder.sessionDrill` (used by DrillCompleteView) or
  provide an equivalent.
- Flow: uniform pick -> immediate grade -> the correct answer highlights and
  HOLDS (never auto-advances) -> explicit Next button -> Finish -> reuse
  `DrillCompleteView(drill:score:total:)`. This uniform flow is what removes the
  glitch/skip; do not reintroduce per-item interstitials that fight the
  transition. A single short intro screen before item 1 is fine (optional).
- `progress.recordItem(id:correct:)` must be called exactly once per item.

### B. Preserve shared question UI for room drills
`MixedSessionView.swift` currently DEFINES `QuestionPager` and `ChoiceList`,
which `QuizDrillView` and `HandMatchDrillView` depend on. Move
`QuestionPager` and `ChoiceList` into a shared file
(`MahjTrainer/Views/Components/QuestionUI.swift`) so those drills keep compiling
after you remove/replace MixedSessionView. Do not duplicate them.

### C. Answer-position variety everywhere (guaranteed, not just authored)
The correct answer must NOT always sit in the same slot. Implement DETERMINISTIC
per-item choice-order shuffling and apply it to every multiple-choice surface:
QuickSession, `QuizDrillView`, `HandMatchDrillView`, and the CardChoice buttons
on flashcards.
- Add a helper, e.g. `func shuffledChoices(labels:[String], answerIndex:Int,
  seed:String) -> (labels:[String], answerIndex:Int)` seeded by the item id so
  the order is STABLE for a given item (no reshuffle on re-render, undo, or
  back-nav) but varies across items and is not always index 0.
- Remap the correct index through the permutation; grading must compare against
  the remapped index. Selection highlighting must map back correctly.
- 2-option CardChoice cards should also flip position based on the seed.
- Do NOT edit the authored `answerIndex` values in Shared/Content; do the
  variety at presentation time so content stays canonical and tests stay green.

### D. Harder dopamine on CORRECT answers
Make a correct answer feel great. Reuse existing primitives (read them first):
`Haptics` (in `MahjTrainer/Utilities/Theme.swift`), `SoundPlayer`
(`MahjTrainer/Utilities/SoundPlayer.swift`, cases like `.success/.miss/.complete`),
`ConfettiBurst` (`particleCount`, `origin`, `trigger`), and the `.shine` /
`.winGlow` modifiers in `MahjTrainer/Views/Components/ShineEffects.swift`.
- Escalate the correct-answer landing: bigger pop/scale, brighter glow, a
  satisfying confetti burst, success haptic + success sound (respect
  `settings.haptics` / `settings.sound` gating, which the primitives already do).
- Track an in-session CONSECUTIVE-correct streak. Escalate at milestones
  (3, 5, 10 in a row): more confetti particles, a stronger/again haptic, and a
  brief celebratory banner (e.g. "3 in a row!"). A missed answer resets the
  streak with the existing gentle miss feedback (do not punish hard).
- Do NOT require generating new sound assets. Layer intensity/among existing
  sounds + haptics + confetti. (If you think a new sound is essential, note it
  for the orchestrator instead of adding a binary wav.)
- Full-screen celebratory effects are allowed (product owner approved).

### E. Wire-up
- Update `HomeView.getStartedCard` to launch `QuickSessionView` with the new
  builder. Keep the "Get Started" card copy.
- Grep the repo for `MixedSessionView` / `MixedItem` / `dailyMix` and update all
  references (HomeView, DrillCompleteView, any tests).

## Constraints
- Swift 6, deployment target iOS 17. Keep the existing warm-modern Theme styles
  (`themedCard`, `primaryCTA`, room accents). Match existing visual language.
- Do NOT touch onboarding/tour/how-to-play (that is task 03).
- No em dashes in any user-facing copy.

## Build / verify (headless; never open Simulator.app)
```
cd /Users/jackwallner/mahj
xcodegen generate          # REQUIRED after adding/removing any .swift file
UDID=$(agent-sim boot mahj)
xcodebuild -project MahjTrainer.xcodeproj -scheme MahjTrainer -destination "id=$UDID" build
xcodebuild test -project MahjTrainer.xcodeproj -scheme MahjTrainer -destination "id=$UDID" -only-testing:MahjTrainerTests
```
The build MUST succeed and unit tests MUST pass. Do light sanity only; no
exhaustive UI automation (a final agent handles full sim verification).

## Commit protocol (resumability)
Commit incrementally with conventional messages, e.g.
`feat: rebuild quick session as choice-only mode`,
`feat: deterministic answer-position shuffle across choices`,
`feat: escalate correct-answer dopamine + session streaks`.
Do NOT push. Do NOT bump build numbers.

## Resume protocol
If respawned: `git log --oneline -8`, read this file, `grep` for
`QuickSessionView`/`MixedSessionView` to see how far the rebuild got, continue
from the first unchecked box, re-run the build.

## Progress
- [x] QuickItem + builder (choice-only pool, tiering, Pro filter)
- [x] QuickSessionView uniform flow (no skip/glitch)
- [x] QuestionPager/ChoiceList moved to shared Components file, room drills compile
- [x] Deterministic answer-position shuffle on all choice surfaces
- [x] Correct-answer dopamine escalation + session streak milestones
- [x] HomeView + all references updated; MixedSessionView removed
- [x] xcodegen + build + unit tests green
- [x] Committed

## Report back
Summarize the new architecture (files added/removed), how the glitch was fixed,
how shuffling + streak escalation work, and confirm build + tests green.
