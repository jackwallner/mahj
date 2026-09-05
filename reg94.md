# REG94: ASC release versus latest TestFlight audit

Audit date: 2026-09-04

Scope: compare the released App Store build with the newest valid TestFlight
build, then scan the 1.3 feature and purchase flows for regressions, bugs, and
poor user experiences. No app source or product configuration was changed for
this audit.

## Compared builds

| Build | ASC state | Evidence |
| --- | --- | --- |
| 1.2.1 (23) | READY_FOR_SALE, uploaded 2026-08-19 | Live App Store version for app ID 6790052126 |
| 1.3.0 (29) | VALID, uploaded 2026-09-04 | Newest valid pre-release build in ASC |
| Source mapping | `fe6898a` to `1aa35c8` | The current project is version 1.3.0, build 29. The source diff is 52 files, primarily the 1.3 practice, reference, hand-play, mastery, and game-night features. |

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
- Ran the unit suite: 155 tests passed, with 0 failures and 0 skips.
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

Suggested direction, not applied: persist the discard and grade transaction at
the same time as the practice record, or persist enough grade state to restore
the post-throw screen before the next turn.

### REG94-002, P2: Long choice labels truncate after grading

Status: Confirmed in Endless Practice, Game Night Prep, and Fix My Mistakes.

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

Suggested direction, not applied: make the answer text retain multiline height
and reserve a stable trailing area for the result icon so grading cannot change
the readable width of the label.

### REG94-003, P2: Coaching auto-scroll hides the question context

Status: Confirmed on the phone layout for choice-based questions.

After a wrong answer, the pager automatically scrolls to the explanation and
anchors it at the bottom. The explanation, miss note, and Next control become
visible, but the top of the rack or prompt is pushed under the navigation area
or offscreen. The player can manually scroll back, but the coaching moment
starts with the question being explained partially hidden.

Evidence in source: `MahjTrainer/Views/Components/QuestionUI.swift:108-114`
calls `scrollTo(questionExplanationID, anchor: .bottom)` whenever `answered`
changes to true.

Suggested direction, not applied: reveal the explanation without losing the
prompt and rack, or leave enough of the question anchored above the coaching
card to preserve context.

### REG94-004, P1 candidate: Modal accessibility isolation remains unresolved

Status: Carry-forward from REG93-008. The current automation shows the risk,
but direct VoiceOver focus behavior still needs confirmation on a device.

While the What's New sheet was visible, the accessibility snapshot still
contained underlying Home controls such as Get Started, Play a Hand, room
cards, and Reference alongside the sheet controls. The app may apply additional
VoiceOver focus behavior that the snapshot does not prove, so this is not
classified as a confirmed VoiceOver regression. It is still an open release
risk because a user of assistive technology could encounter or activate a
control that is visually covered by the sheet.

Evidence: `HomeView.swift` presents the sheet, while the current modal surface
does not explicitly isolate the underlying accessibility tree. The same risk
was recorded as REG93-008 and was intentionally left for real VoiceOver
verification.

Required validation, not applied: run VoiceOver through What's New, the paywall,
and any other sheet or full-screen modal, confirming that focus stays inside the
presented surface until dismissal.

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
| REG93-008, modal accessibility isolation | Open, carried forward as REG94-004. |
| REG93-009, stacked flashcard previews in the accessibility tree | Closed by hiding non-current deck cards. |
| REG93-010, compact Home header collision | Closed. The current compact header stacks cleanly. |
| REG93-011, Timed Challenge started before the player was ready | Closed. The ready screen and early-exit score handling worked in the current runtime. |
| REG93-012, paywall loading, semantics, and footer occlusion | Closed in the current paywall runtime. |
| REG93-013, onboarding plan disclosure did not match the purchased plan | Closed. The onboarding trial disclosure and CTA both use the monthly plan. |
| REG93-014, ASC, in-app branding, and pricing metadata drift | Closed for the checked products and current paywall. |
| REG93-015, non-current onboarding pages remained exposed | Closed by the current page accessibility handling. |

## Release assessment

Three new issues are confirmed in the current build-29 code path: one data and
coaching persistence defect, one answer-legibility defect, and one coaching
layout defect. The modal accessibility issue remains open from the prior audit
and should not be treated as closed without direct VoiceOver validation.

No app crash was observed. The 155-test unit suite passed. No regression was
found in the current onboarding purchase copy, paywall compliance content,
compact Home navigation, generated practice picker, Timed Challenge ready state,
Game Night completion, Reference search, or the previously fixed Play a Hand
tile interaction.
