# REG94: ASC release versus latest TestFlight audit

Audit date: 2026-09-04

Scope: compare the released App Store build with the newest valid TestFlight
build, then scan the 1.3 feature and purchase flows for regressions, bugs, and
poor user experiences.

Revised 2026-09-04 after working the findings. The original pass changed no
source. This revision fixes REG94-001 and REG94-002, downgrades REG94-003 and
REG94-004 to P3 with the reasoning for leaving them alone, and corrects the
classifications the first pass got wrong in both directions.

## Compared builds

Re-verified against the live ASC API on 2026-09-04 (`/v1/apps/6790052126/appStoreVersions`
and `/v1/builds`), not from the previous audit's notes:

| Build | ASC state | Evidence |
| --- | --- | --- |
| 1.2.1 (23) | Version READY_FOR_SALE; build VALID, uploaded 2026-08-19 | The live App Store version. 1.2.1, 1.2.0, 1.1 and 1.0 are the only four App Store versions on the app, so this is the baseline every regression here is measured against. |
| 1.3.0 (29) | VALID, uploaded 2026-09-04 12:47 PT | Newest pre-release build. 1.3.0 (27) and (28) precede it the same day; 1.2.2 (26) from 2026-09-02 was never given an App Store version. |
| No 1.3.0 version | `asc-readiness.py` reports NO editable version | 1.3.0 exists only as TestFlight builds. |
| Source mapping | `fe6898a` (build 23) to `1aa35c8` (build 29) | The current project is version 1.3.0, build 29. The diff is 54 files as of `100c1b3`, primarily the 1.3 practice, reference, hand-play, mastery, and game-night features; `1aa35c8` is the commit build 29 was cut from. |

Build 29 is assigned only to the internal `Jack` beta group. ASC reports no
public TestFlight link or external beta group for it. There was also no editable
1.3.0 App Store version at the time of the audit. This is release-readiness
context, not an app defect, but it limits independent TestFlight coverage.

The three Mahj+ products are present and approved in ASC: monthly and yearly
subscriptions in the `Mahj+` group, plus the lifetime non-consumable. The
current paywall loaded the matching products dynamically and showed billing
periods, trial terms, auto-renewal language, Restore, Terms of Use, and Privacy
Policy. No current pricing or purchase-surface regression was found.

## Validation performed

- Read the live ASC app, version, build, beta-group, and product metadata.
- Compared the build-23 baseline source documented in `reg93.md` with the
  current build-29 source.
- Built and ran the current project on the leased headless iPhone 17 Pro
  simulator running iOS 26.5.
- Ran the unit suite: 155 tests passed, with 0 failures and 0 skips (157 after
  the two regression tests added by this pass).
- Diffed each suspect file against the build-23 baseline before classifying it.
  That is what showed REG94-002 to be a 1.0-era defect rather than a 1.3
  regression, and what showed the code REG94-003 blamed to be untouched since
  build 23.
- Captured the same graded question on the simulator with and without the
  REG94-002 fix, from a real member walk into Tile Check: Extra Reps, so the
  truncation and its repair are on record as screenshots rather than as a
  reading of the layout code.
- Manually exercised onboarding, Home and compact Home, Play a Hand, Endless
  Practice, Timed Challenge, Game Night Prep, Fix My Mistakes, Reference, the
  free-to-Mahj+ paywall, and accessibility snapshots of modal surfaces.
- Forced a relaunch during an in-progress Play a Hand after a graded discard to
  test persistence at the most failure-prone point.

The screenshot UI test scheme did not finish within the XcodeBuildMCP five
minute ceiling. It stalled while the member Endless Practice test interacted
with the Finish control. The underlying process showed no app crash, and the
manual runtime walk continued independently. This is a test-harness coverage
limitation, not classified as an app failure.

Runtime checks used a local build matching version 1.3.0, build 29, rather than
downloading the TestFlight IPA. ASC metadata and the source build number match,
but this remains a limitation on binary-level comparison.

## Findings

### REG94-001, P2: Play a Hand loses a graded throw after termination

Status: Confirmed in the build-29-equivalent runtime.

Reproduction:

1. Start a free Play a Hand session and draw the first tile.
2. Tap a discard and wait for the coaching card to appear.
3. Force-quit the app before tapping Next turn.
4. Relaunch and choose Resume.

Actual result: the hand returns to the turn boundary before the discard. The
drawn tile is back in the 14-tile rack, the coaching card is gone, and the
throw is available to answer again. The original throw's coaching and its
progress record are therefore not durable across termination.

Evidence in source:

- `MahjTrainer/Views/Drills/HandPlayView.swift:86-97` restores only the saved
  turn-boundary snapshot.
- `MahjTrainer/Views/Drills/HandPlayView.swift:350-363` saves after `draw()`.
- `MahjTrainer/Views/Drills/HandPlayView.swift:365-394` mutates the rack,
  grade, clean-discard count, and practice record in `throwTile()` without
  saving the new state.

Impact: a crash, force-quit, or termination while the coaching card is visible
can make the player repeat a throw and lose feedback. This is especially
confusing because Home correctly offers Resume, but Resume does not represent
the last visible state.

Resolution, applied 2026-09-04: `HandPlayStore.InProgressHand` now carries the
graded throw (`ThrowGrade`, a Codable copy of what the view was already
holding), and `throwTile()` saves on the same line that records the practice
row. Resuming lands back on the exact screen the player left, coaching card,
rack and all.

Two things the fix had to keep. The `grade` field is optional, so a hand saved
by build 29 or earlier still decodes and simply resumes at the turn boundary as
before. And the store's own comment, which said saving mid-throw was WRONG, was
right about the old shape: saving the post-discard rack without the grade would
have resumed into a 13-tile rack that was still tappable, spending two discards
on one draw. Saving the grade with the rack is what makes it safe.

Also closed by the same change: the practice record was written at the throw
but the hand was not, so a relaunch handed the player the same throw back and
counted it a second time in the Play a Hand stats row.

Regression cover: `HandPlayStoreTests.testAGradedThrowSurvivesRelaunch` and
`testATurnBoundaryHandResumesWithNoGrade`, plus the mid-throw half of
`NewFeatureSmokeTests.testAnAbandonedHandIsWaitingOnTheNextLaunch`, which
throws a tile, terminates the app on the coaching card, and reopens.

### REG94-002, P2: Long choice labels truncate after grading

Status: Confirmed in Endless Practice, Game Night Prep, and Fix My Mistakes.
NOT a 1.3 regression: `ChoiceList.row` is byte-identical to the released
build-23 source (`git diff fe6898a HEAD -- QuestionUI.swift` touches only
`QuestionPager` and the new miss-note types). It has been wrong since 1.0 and is
fixed here because it costs the player teaching content, not because 1.3 caused
it.

Before an answer, a long choice can wrap to two lines. After grading, the
correct-answer checkmark is added to the same row and the label is compressed
until it ends in an ellipsis. One observed correct label was:

`On your turn, for any exposed joker whose tile you hold`

The player is most likely to need the full text after grading, when the app is
explaining the answer. VoiceOver can retain the full accessibility label, but
the sighted learner sees incomplete teaching content.

Evidence in source: `MahjTrainer/Views/Components/QuestionUI.swift:171-218`
places `Text(labels[index])`, a spacer, and the answered-state icon in one
horizontal stack. The text has no explicit multiline sizing or reserved icon
layout.

Resolution, applied 2026-09-04: the label now carries
`.fixedSize(horizontal: false, vertical: true)`, the modifier every other
wrapping label in this file already had, so it wraps instead of ellipsing. The
trailing icon moved into a `resultIcon` slot that is always 22pt wide, empty or
not, so the label's width is identical before and after grading and the text
cannot rewrap underneath the answer the player is reading. The stack is
top-aligned so a three-line answer puts its checkmark against the first line.

Cost, accepted: every choice row is now 34pt narrower than before, graded or
not. That is the price of the width never changing, and it is the right trade
in a drill app where the labels are the lesson.

### REG94-003, P3 (downgraded from P2): Coaching auto-scroll hides the question context

Status: The behaviour is real, the diagnosis was wrong, and no code change was
applied. Downgraded to P3.

After a wrong answer, the pager automatically scrolls to the explanation and
anchors it at the bottom. The explanation, miss note, and Next control become
visible, but the top of the rack or prompt is pushed under the navigation area
or offscreen. The player can manually scroll back, but the coaching moment
starts with the question being explained partially hidden.

What the audit blamed: `MahjTrainer/Views/Components/QuestionUI.swift:108-114`
calls `scrollTo(questionExplanationID, anchor: .bottom)` whenever `answered`
becomes true.

Why the anchor is not the cause. The coaching block is the LAST view in the
pager's VStack, and `CenteringScrollView` gives the content a `minHeight` of
the whole viewport. So there are only two cases, and the anchor is irrelevant
in both: a question that fits has no scroll range, and nothing moves whatever
the anchor says; a question that overflows scrolls to its own end, which is
where `.bottom` on the last element puts it and also where a minimum scroll
puts it. Dropping the anchor was tried and reverted as a no-op.

The real mechanism is content height. 1.3 moved `MissNoteCard` and
`RequeuedChip` into that same block, so a wrong answer now carries up to three
cards where 1.2.1 carried one. The prompt goes off the top because the question
plus its coaching is taller than a phone, not because of how it was scrolled.

Resolution: no change, and the reasoning is written into the source at the
`onChange` so the anchor is not "fixed" again by the next audit.

What the current behaviour actually shows, captured from a wrong answer in Read
the Rack on an iPhone 17 Pro (`31_miss_coaching`): all four choices with the
correct one ticked and the miss crossed, the explanation, the "Why not 2468
(Evens)?" card, the Saved to Fix My Mistakes chip, and the bottom row of the
rack. Everything the player needs to understand the miss is on screen at once.
What is off the top is the prompt and the first row of tiles, one flick away.

That is the right thing to have chosen. Anything that keeps the prompt takes
its space from the coaching, on a viewport that cannot hold both. Reducing the
coaching itself would mean cutting the miss note, which is the half of a wrong
answer that changes the next one. Left as it is deliberately, and worth
revisiting only if the block grows again.

### REG94-004, P3 (downgraded from P1 candidate): Modal accessibility isolation

Status: Reclassified 2026-09-04. Not a defect on the evidence available, and no
code change applied.

The observation was that while the What's New sheet was visible, the
accessibility snapshot still listed underlying Home controls (Get Started, Play
a Hand, the room cards, Reference) alongside the sheet's own.

Why that is not evidence of a defect. Every modal in this app is a real
`.sheet` or `.fullScreenCover`:

- `HomeView.swift:83-85` (paywall, Settings, What's New)
- `SettingsView.swift:41-53` (paywall, What's New, review prompt)
- `RoomView.swift:41`, `HandPlayView.swift:58`, `MahjMinuteView.swift:194`,
  `DrillCompleteView.swift:85`, `OnboardingView.swift:84` (paywall and review
  prompt)
- `FeatureTourView.swift:91` (the tour's Quick Session)

UIKit's presentation controller marks the presented view
`accessibilityViewIsModal` for both of those presentations, which is what
actually stops VoiceOver reaching behind a sheet. `accessibilityViewIsModal` is
a VoiceOver-level hint; XCUITest's element tree walks the whole window
hierarchy and ignores it, so a snapshot listing the covered controls is the
expected output for a correctly isolated sheet, not a symptom. The same
snapshot evidence produced this finding in `laudit89.md`, `reg93.md` as
REG93-008, and here, three times without a VoiceOver session behind it.

Deliberately not applied: hanging `accessibilityHidden(true)` on Home while a
sheet is up. It would duplicate what UIKit already does, add presentation state
to a view that does not need it, and the screenshot suite queries those exact
Home elements, so the change would risk real breakage to fix nothing that has
been shown to be broken.

Still open, and the only thing that can close it: one VoiceOver pass on a
device through What's New, the paywall, and the feature tour, confirming focus
stays inside the presented surface. Until somebody runs it this is unverified,
not unresolved.

## REG93 carry-forward check

The following earlier findings did not recur in the current build-29 runtime or
current source and test coverage:

| Prior finding | Current status |
| --- | --- |
| REG93-001, legacy progress migration | Closed by the current migration and conversion diagnostics coverage. |
| REG93-002, Play a Hand discard tile inaccessible | Closed. Rack tiles are exposed as actionable buttons with labels and identifiers. |
| REG93-003, generated Charleston could present multiple junk tiles | Closed by the generator constraints and tests. |
| REG93-004, tile-count prompt contradicted the deal | Closed. The prompt now reflects the exact generated count. |
| REG93-005, Play a Hand setup and verdict were not centered on iPad | Closed by the centering scroll layout. |
| REG93-006, new Home content pushed compact modes offscreen | Closed. Compact Home shows the swipe cue and the horizontal training cards remain reachable. |
| REG93-007, free Play a Hand was consumed without resume | Closed at turn boundaries. REG94-001 is a separate mid-turn persistence gap. |
| REG93-008, modal accessibility isolation | Reclassified as REG94-004, P3. The snapshot evidence does not distinguish a leaking sheet from a correctly isolated one; needs a real VoiceOver pass. |
| REG93-009, stacked flashcard previews in the accessibility tree | Closed by hiding non-current deck cards. |
| REG93-010, compact Home header collision | Closed. The current compact header stacks cleanly. |
| REG93-011, Timed Challenge started before the player was ready | Closed. The ready screen and early-exit score handling worked in the current runtime. |
| REG93-012, paywall loading, semantics, and footer occlusion | Closed in the current paywall runtime. |
| REG93-013, onboarding plan disclosure did not match the purchased plan | Closed. The onboarding trial disclosure and CTA both use the monthly plan. |
| REG93-014, ASC, in-app branding, and pricing metadata drift | Closed for the checked products and current paywall. |
| REG93-015, non-current onboarding pages remained exposed | Closed by the current page accessibility handling. |

## Release assessment

Two of the four findings were real defects and both are fixed: a persistence
defect that also double-counted a throw in the stats (REG94-001, new in 1.3),
and an answer-legibility defect that predates 1.3 (REG94-002). The other two
are downgraded to P3 with no code change. REG94-003's diagnosis did not survive
being tried: the scroll anchor it blamed is provably a no-op here, and the
behaviour is a content-height trade-off that is already resolved the right way.
REG94-004's evidence cannot tell a leaking sheet from a correctly isolated one,
so it stays open as a VoiceOver task rather than a speculative code change.

Only one of the four is a 1.3 regression. Getting to that number is the reason
every finding was diffed against build 23, and the reason two proposed fixes
were not shipped.

No app crash was observed. The unit suite passes at 157 tests. No regression was
found in the current onboarding purchase copy, paywall compliance content,
compact Home navigation, generated practice picker, Timed Challenge ready state,
Game Night completion, Reference search, or the previously fixed Play a Hand
tile interaction.

## Fixes applied

| Finding | Change | Files |
| --- | --- | --- |
| REG94-001 | The graded throw is saved with the hand, so a relaunch resumes onto the coaching card instead of rewinding past a throw that was already counted. | `Shared/Services/HandPlayStore.swift`, `MahjTrainer/Views/Drills/HandPlayView.swift` |
| REG94-002 | Choice labels wrap instead of ellipsing, and the result icon has a reserved slot so grading cannot change the label's width. | `MahjTrainer/Views/Components/QuestionUI.swift` |
| REG94-003 | None. The proposed fix was written, tested and reverted as a no-op; the reasoning is now a comment at the call site. | `MahjTrainer/Views/Components/QuestionUI.swift`, comment only |
| REG94-004 | None, deliberately. See the finding. | - |

Verified on the simulator, not just in the diff: the mid-throw kill and relaunch
comes back to the identical screen (`63_throw_graded` and
`64_graded_throw_resumed` are the same frame), and the long answer that read
`On your turn, for any exposed joke...` before the fix wraps to two full lines
after it.

Regression cover added: `HandPlayStoreTests.testAGradedThrowSurvivesRelaunch`,
`HandPlayStoreTests.testATurnBoundaryHandResumesWithNoGrade`, and the
mid-throw half of
`NewFeatureSmokeTests.testAnAbandonedHandIsWaitingOnTheNextLaunch`.
