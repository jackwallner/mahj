# Mahj build 42 independent audit

Audit date: October 12, 2026, America/Los_Angeles. Target: Mahj Trainer 1.4.0 (42), app source at `ff4161d`. Success criterion: find reproducible defects across the new Monthly Challenge and existing experiences, with evidence, affected personas, priorities and explicit coverage limits.

**Recommendation: hold App Review submission while the high-priority defects below are corrected.** The passing test suite does not establish release readiness. Wrong rules and grading, dropped offline feedback, calendar-dependent challenge identities, and inaccessible screens remain in this build.

31 findings: **5 P1, 21 P2, 5 P3**. Policy/performance risks and source-only findings are labeled separately from runtime reproductions; this count is not a claim of 31 independently reproduced UI bugs. F01-F05 are the first repair priorities.

This is an audit, not a repair pass. App code and release state were not changed. The simulator binary was rebuilt from the build-42 source; this was not a physical-device installation from TestFlight. Website-only commits appeared during the audit, without changes to the audited app source. Unrelated website edits were preserved.

## Method and coverage

Three independent specialist passes supplemented the primary audit: an American mah jongg teacher/content and calendar reviewer, an iPad/low-vision/accessibility reviewer, and an Android/returning-member reviewer. They worked separately and did not recursively delegate. Findings were checked against actual code, actual UI, deterministic executions or current primary documentation, as identified below.

| Persona or context | Coverage and evidence |
| --- | --- |
| Brand-new, older player on smaller phone | iPhone 17e, iOS 26.5. First onboarding pages and skill choice at AX5, the largest accessibility text size. Home, free daily mix, challenge, report sheet and dark appearance. |
| Interrupted commuter | Challenge answer saved, app terminated, resumed at question 2. Full 12-question run, termination after the last answer before Finish, relaunch, results and misses review. |
| Low-vision iPad user | iPad Air 11-inch M4, iPadOS 26.5, portrait. All 12 challenge questions, results, misses, normal text and AX5; Home, Tile Room and legacy flashcard front/back. |
| Screen-reader user | Actual accessibility trees for challenge and answer review; source review of choices, deck gestures and reference disclosure controls. Physical VoiceOver speech was not tested. |
| Larger phone on newer OS | iPhone 18 Pro Max, iOS 27.0. Release install/launch, Home and challenge deep-link landing screenshots verified. Repeated automation-session failures limited interactive coverage; this is a visual smoke check only. |
| Experienced teacher and skeptical expert | Shared rules/reference/paid content, all three monthly themes, real build-41 migration, deterministic generator runs across 39 months and Play a Hand scoring. |
| International player | Actual Shared source executed with Gregorian, Buddhist, Hebrew, Islamic, Indian and Japanese calendars for the same instant. |
| Offline reporter | Actual FeedbackService with an isolated preferences suite and intercepted offline URLSession. No report was sent to production. |
| Returning or lapsed subscriber | Purchase, trial, reminder, review and churn code inspected. Release simulator paywall unavailable-price state opened. No purchase, restore, cancellation or real charge was performed. |
| Android player | Separate source/parity/reminder review and remote unit-test verification, recorded in the Android addendum below. No local Android emulator was used. |

Verification completed independently of the previous agent's claims:

- Release simulator build succeeded.
- iOS XCTest run: **214 tests, zero failures**, including the actual app's existing suite.
- Actual Shared-source probe: all 39 months from October 2026 through December 2029 contained exactly 12 questions. Authored closer pools did not repeat before exhaustion. The finite pools do eventually repeat, which is expected.
- Both phone and iPad completed the October challenge through real controls. Score was 4/12 when choosing the first option throughout. The results and misses review opened.
- Normal-size choice locking worked. Stopping after question 1 resumed at question 2 with the first answer preserved.
- The free Get Started mix completed 10 questions, credited one session/streak day and returned Home. Its next-day resting state appeared.
- Play a Hand dealt, accepted a target and a discard, then restored the exact graded turn after termination/relaunch.
- Normal phone Reference opened. The standalone paywall exposed Close, Retry, Restore, Terms and Privacy in the unavailable-price simulator state. That state is expected with the Release simulator RevenueCat guard, not evidence of a production billing outage.

Committed screenshots, semantic trees, probe drivers and output are indexed in [the evidence folder](solaudit1012-evidence/README.md). Complete temporary logs and the xcresult are under `/tmp/mahj-solaudit1012/` for this session.

## Priorities and evidence labels

- **P1:** core teaching is wrong, data is silently lost, or a major cohort receives invalid behavior. Correct before submission.
- **P2:** a meaningful flow, accessibility, trust or retention failure. Correct before release where feasible.
- **P3:** readability/polish or a source risk whose real-world cost still needs measurement.
- **UI:** reproduced in the app. **Executed source:** reproduced by compiling the real implementation. **Source:** definite code/content behavior without the full device scenario. **Risk:** implication requires further device or policy review.

## High-priority findings

### F01. P1, offline retry silently deletes queued feedback

**Evidence: executed source. Persona: player reporting several problems without connectivity.**

`Shared/Services/FeedbackService.swift:117` copies the pending queue, clears it, then returns when the first retried submission is queued again. The untouched remainder is never restored. Three reports submitted offline produce a queue of three; retrying while still offline leaves exactly one. This loses reports the app promised to save for later.

Reproduce with [FeedbackProbe.swift](solaudit1012-evidence/probes/FeedbackProbe.swift). The [captured output](solaudit1012-evidence/feedback-proof.txt) shows `before retry 3` and `after offline retry 1`. Requests are intercepted locally, so this did not generate developer inbox traffic.

Fix direction: retain the unprocessed suffix when a retry fails, and persist successful removals incrementally. Verify multiple queued reports, failure on the first/middle item, and enqueueing while a flush is suspended.

### F02. P1, a device's calendar changes the shared challenge and can create tens of thousands of archive entries

**Evidence: executed source. Persona: Hebrew/Buddhist-calendar user, or someone changing their system calendar.**

`Shared/Content/MonthlyChallengeContent.swift:114` and `:168` use `Calendar.current` for identity, seed, theme, release floor and archive iteration. English locale changes the names, not the calendar. The same October 12, 2026 instant produces:

| Calendar | Challenge key | Theme | Past archive months |
| --- | --- | --- | ---: |
| Gregorian | 2026-10 | Reading Your Rack | 0 |
| Buddhist | 2569-10 | Reading Your Rack | 6,516 |
| Hebrew | 5787-02 | Charleston | 46,510 |
| Islamic Umm al-Qura | 1448-05 | Charleston | 0 |
| Indian | 1948-07 | Reading Your Rack | 0 |
| Japanese | 0008-10 | Reading Your Rack | 0 |

The player no longer gets the same questions as friends. Changing calendar also changes the lookup key, so saved results appear missing. `MonthlyChallengeView.swift:127` eagerly constructs archive rows; generating thousands of challenges is a serious performance risk. A UI hang was not reproduced, and is not claimed.

Fix direction: explicit Gregorian identity/rotation/release dates, with deliberate timezone semantics and separate localized presentation. Bound the archive to the true release instant. [Actual-source output](solaudit1012-evidence/content-proof-root.txt).

### F03. P1, Play a Hand penalizes useless discards because its hidden scoring window changes

**Evidence: executed source. Persona: experienced player choosing a defensible discard.**

`Shared/Content/HandPlayEngine.swift:105` chooses a consecutive-run range by raw tile count, while `:129` scores groups only inside that range. `:181` recalculates the range separately for each candidate discard. A discard can win by flipping the hidden range rather than by improving the rack.

Actual reproduction: `deal(seed: "run-audit-1")`, then the first draw, gives `1C 5C 5C 6C 7C 8C 8C 3B 4B 5B 3D RD W N`. Initial selected range is 3...6. Only 3 Bam, 3 Dot and 4 Bam are accepted. North, West, Red Dragon and 1 Crak are marked wrong, even though they are outside the run. Removing an in-window single changes the range to 5...8 and raises the computed value from 4.7 to 5.2. No useful tile was created by that discard.

Coaching even tells the player that the rejected tile was already outside the run, then calls it second best. This contradicts the stated rule that equally useless tiles are equally correct. [Counterexample and per-discard values](solaudit1012-evidence/content-proof-root.txt).

Fix direction: maximize the same group-value function across valid ranges, or freeze the target range while grading. Explain any intended distinction in terms of the shown rack.

### F04. P1, multiple lessons say a formally dead hand keeps playing or can be rebuilt

**Evidence: source/content, corroborated rules. Persona: beginner following the app at a real table.**

Affected content:

- `ReferenceContent.swift:282`: dead player stays in the game to discard.
- `PlusContent.swift:82` and `:86`: keep playing is graded correct.
- `KeepDiscardContent.swift:99` and `:104`: a dead hand with three jokers should rebuild.
- `MoreContent.swift:274`: a dead player throws the winning tile.
- `MonthlyChallengeContent.swift:364`: new `monthly-def-dead-joker` asks for a dead player's safest discard, scheduled in June 2027 by the actual-source month dump.

Once a hand is validly declared dead, the player stops picking and discarding. A weak live hand and a declared dead hand are different states. The app itself correctly says the other three players continue at `MoreContent.swift:320`.

[Mahj Life's NMJL-attributed rulings](https://mahjlife.com/wiki/reasons-to-disqualify-another-player-article-24/) cite *Mah Jongg Made Easy* and NMJL bulletins for the cease-playing rule; [Mahjcon's own tournament rules](https://mahjcon.com/mahjpedia/id163-common-tournament-rules-regulations/) also require the erring player to stop playing. These are corroborating rule sources, not a claim that this audit accessed the copyrighted current card.

Fix direction: correct all shared/exported occurrences together. Defensive exercises should say that a still-live hand is unlikely to finish.

### F05. P1, returning subscribers are promised a free trial without an eligibility check

**Evidence: source plus SDK documentation. Persona: lapsed member who already used the introductory offer. No purchase performed.**

`PaywallView.swift:7`, plan labels, and `PaywallPricing.terms` at `:253` always promise seven free days for subscriptions. `OnboardingView.swift:258` and `:274` do the same for every non-current member. No introductory-offer eligibility check exists. Apple can correctly charge an ineligible returning customer immediately after its own confirmation sheet, despite the app's trial promise. RevenueCat documents that introductory offers apply only to eligible purchases and provides an eligibility check. [RevenueCat's official offer documentation](https://www.revenuecat.com/docs/subscription-guidance/subscription-offers/ios-subscription-offers).

There are two related downstream defects: `SubscriptionService.swift:199` derives `startedTrial` from the product having an introductory discount, rather than the purchased entitlement's actual period. `OnboardingView.swift:399` treats every successful monthly purchase as a newly started trial and offers a reminder based on `Date()`. An ineligible paid purchase can therefore be recorded as a trial and receive an irrelevant trial-end reminder.

Fix direction: eligibility-aware copy, conservative wording while eligibility is unknown, and post-purchase entitlement period/expiration as the source of truth. Verify with separate eligible and previously subscribed sandbox accounts on a physical device.

## Challenge persistence and review

### F06. P2, upgrading build 41 to 42 rewrites the meaning of saved results

**Evidence: executed actual historical/current source. Persona: existing TestFlight player.**

`MonthlyChallengeStore.swift:3` and `:27` save booleans and positional picks without question identities, a content version or a question snapshot. `MonthlyChallengeView.swift:308` regenerates the questions from the latest source. Its count-only guard at `:320` accepts a different set of twelve.

Compiled the complete content from actual build-41 bump commit `41457e7` and build 42. October Q3 changed from `gen-defense-monthly-2026-10-1`, safest discard 8 Crak, to `gen-rackReading-monthly-2026-10-1`, Consecutive Run. A defense miss becomes a rack-reading miss in both the review and skill breakdown. Q10 also changed from a generated run to authored Quints. Published build 41 had no picks, but its correctness history is still falsely reassigned.

The intermediate build-41 source `2e1a142`, which had positional picks, demonstrates an additional failure: old Q1 slot 0 was Odds; new Q1 slot 0 is 369 while the answer is Evens in slot 2. A previously correct pick can be relabeled incorrectly. In-progress runs have the same positional issue.

Evidence: [build 41](solaudit1012-evidence/build41-october.txt), [build 42](solaudit1012-evidence/current-october.txt), [intermediate build 41](solaudit1012-evidence/old-october.txt).

Fix direction: persist the exact challenge or a stable content/item/choice version. Show score only for old results whose original questions cannot be reconstructed reliably.

### F07. P2, finishing the last answer can permanently miss session and streak credit

**Evidence: UI and saved preferences. Persona: interrupted player.**

Answer all twelve questions, then terminate before tapping Finish. `MonthlyChallengeStore.recordAnswer` correctly banks the result immediately. On relaunch, the hero offers See Your Results and the final score is preserved. However, session/streak credit is written only by `MonthlyChallengeResultView.recordCompletionIfNeeded` at `MonthlyChallengeView.swift:511`, and a reopened result has `recordsCompletion = false`.

Actual phone state after relaunch: October result contains all twelve answers, but `progress.totalSessions` and streak keys remain absent. Home shows 0 day streak, 0 drills done beside the completed 4/12 challenge. Opening the saved results does not repair it. [Preferences](solaudit1012-evidence/final-answer-kill-proof.json), [Home screenshot](solaudit1012-evidence/phone-home-dark-after-challenge.png).

Fix direction: bank completion credit idempotently when answer 12 is persisted, or reconcile uncredited saved results on launch. Avoid giving repeated credit when an archived result is viewed.

### F08. P2, answer review repeats the entire rack label on every individual tile

**Evidence: actual iPad accessibility tree. Persona: screen-reader user.**

`MonthlyChallengeView.swift:599` sets a full-rack accessibility label on TileRackView without making the wrapper one accessibility element. Every one of thirteen tile elements inherits the entire thirteen-tile label. A sequential reader encounters 169 tile names and cannot distinguish the individual elements.

Compare [in-run tree](solaudit1012-evidence/ipad-06-question.json), which has correct individual names, with [review tree](solaudit1012-evidence/ipad-09-misses-ax5.json). This is semantic-tree proof; physical VoiceOver speech playback was not performed.

Fix direction: announce the rack once with proper grouping, or retain individual tile names without the wrapper label.

### F09. P3, largest-text answer-review headers become word fragments

**Evidence: UI. Persona: low-vision phone user.**

The horizontal header at `MonthlyChallengeView.swift:580` makes QUESTION 1 wrap as several fragments and Reading Your Rack span many lines at AX5. The header dominates the card before the question. Choices keep an icon, label and inline your-pick annotation in one row, leaving less width at precisely the size that needs more.

[Phone screenshot](solaudit1012-evidence/phone-misses-ax5.png). Scrolling works and the answers remain available, so this is a readability defect, not a blocked review flow. Reflow metadata and annotations vertically at accessibility sizes; consider a larger tile representation rather than leaving 30-point tiles beside very large text.

## Onboarding, accessibility and existing drills

### F10. P2, largest-text onboarding clips essential content and skill choices

**Evidence: UI. Persona: older first-time player using AX5.**

On iPhone 17e, page 1 puts the heading above the visible content and clips the long introduction. The skill page places its heading and part of the Brand new choice above the viewport. The pages are VStacks in a paged TabView, without vertical scrolling (`OnboardingView.swift:59`). Continuing is possible, but the user cannot read the full introduction or compare all skill options normally.

[Introduction](solaudit1012-evidence/phone-onboarding-ax5.png), [skill selection](solaudit1012-evidence/phone-onboarding-skill-ax5.png). Grow/scroll each page while retaining a reachable Continue button. Recheck the trial page with live prices at the same size before shipping; its disclosure was not verified with live StoreKit data in this audit.

### F11. P2, the question-report sheet has an unreachable Send button at AX5

**Evidence: UI and source. Persona: low-vision player reporting a wrong answer.**

After grading a challenge answer, open Something wrong with this question at AX5 on iPhone 17e. The prompt overlaps the navigation bar, all four chip labels truncate, and Send falls below the viewport. Selecting a reason does not make it reachable. There is no outer scroll area for this composer, only the editor's own scrolling (`ReviewPromptSheet.swift:216`).

[Selected-reason screenshot](solaudit1012-evidence/phone-report-selected-ax5.png). No feedback was sent. The same composer serves general feedback and churn, so those paths also need keyboard and largest-text verification. Use a scrolling form with a stable reachable submission action and full chip labels.

### F12. P2, iPad Home training cards overlap at the largest text size

**Evidence: UI and accessibility frames. Persona: low-vision iPad user.**

`HomeView.swift:775` fixes training cards to 118 points high even as their labels/icons grow to 250-346 points. On iPad portrait AX5, Endless Practice draws over the challenge footer and Play a Hand, Mahj Minute and Game Night Prep overwrite adjacent rows. Actual semantic button frames overlap: Play a Hand at y973.5/h256.25, Endless Practice at y927.5/h346.25, Mahj Minute at y1074/h311.

[Screenshot](solaudit1012-evidence/ipad-17-home-training-overlap-ax5.png), [tree](solaudit1012-evidence/ipad-17-home-training-overlap-ax5.json). Use intrinsic heights and a single training column at accessibility sizes. Audit room cards too: their descriptions truncate heavily in this layout.

### F13. P2, legacy flashcards advertise accessibility actions they do not implement

**Evidence: source; physical assistive-technology verification still needed. Persona: VoiceOver or Switch Control user.**

`FlashcardDrillView.swift:154` adds button traits and a tap-to-reveal hint, but all flipping/ordinary grading is implemented by `DragGesture(minimumDistance: 0)` at `:290`. There is no default accessibility action for reveal and no named Knew It/Again actions for the ordinary swipe deck. VoiceOver's navigation swipes are not the same as these raw gestures. Choice cards have their own buttons; the plain deck lacks equivalent semantic controls.

Fix direction: explicit reveal and grading accessibility actions or visible buttons, while preserving the signature gestures. Verify a complete ordinary deck with VoiceOver and Switch Control, including Undo. This audit inspected source and the real deck tree; it does not claim a completed physical VoiceOver session.

### F14. P2, graded answer choices do not expose selected/correct/missed state semantically

**Evidence: source and runtime snapshots. Persona: screen-reader user in any quiz using ChoiceList.**

`Components/QuestionUI.swift:154` changes fill, stroke, checkmark and cross after answering, but does not set a selected trait, accessibility value or result label. `allowsHitTesting(false)` at `:243` prevents ordinary touch but still leaves the choices represented as buttons. Before/after snapshots expose the same answer names, without your pick or the answer. The explanation sometimes names the answer, but that is not a substitute for the row state.

Affected: challenge, Get Started and other shared choice-based drills. [Actual October before/after captures](solaudit1012-evidence/phone-challenge-snapshots.json). Add explicit state labels/values and announce grading. Do not reintroduce the visual dimming problem the current implementation intentionally avoids.

### F15. P2, dark Home Get Started still has low-contrast white text

**Evidence: UI and calculated source colors. Persona: older player in dark mode.**

The recent onFill fix is bypassed at `HomeView.swift:365`, `:368` and `:373`: the card keeps white title/subtitle/icon on the adaptive jade gradient. At its solid dark-mode jade endpoint `(0.36, 0.71, 0.62)`, white contrast is **2.45:1**, below even the 3:1 large-text threshold. The subtitle has additional white opacity. Other main buttons correctly use dark ink on light dark-mode fills.

[Screenshot](solaudit1012-evidence/phone-home-dark-after-challenge.png). Use the shared onFill color and check both ends of the actual gradient. Also inspect the white-on-coral streak banner in QuickSessionView; the app-wide claim should not be treated as fully verified.

### F16. P3, legacy completion text truncates at AX5

**Evidence: UI. Persona: low-vision player after finishing a free mix.**

The non-scrolling VStack in `Drills/DrillCompleteView.swift:23` truncates the completion message on iPhone 17e at AX5. [Screenshot](solaudit1012-evidence/phone-quick-complete-ax5.png). Done remains reachable and works, so this is not a navigation trap. Give the completion copy adequate vertical space or scrolling.

### F17. P2, Reduce Motion is ignored by major effects

**Evidence: source. Persona: motion-sensitive user.**

No `accessibilityReduceMotion`/Reduce Motion handling exists in the app source. Confetti always flies, ChoiceList pops and shakes, and the flashcard uses a full 180-degree flip. Configuring the OS preference therefore has no corresponding app behavior.

Fix direction: honor the preference for all celebration/deck animations, retaining immediate static grading feedback. Verify on device with Reduce Motion enabled. A runtime OS-preference toggle was not exercised here.

### F18. P3 risk, confetti's animation schedule outlives its visible burst

**Evidence: source. Persona: user leaving a graded/result screen open.**

`Components/ConfettiBurst.swift:40` mounts `TimelineView(.animation)` whenever firedAt exists. The two-second check only returns from Canvas drawing, and firedAt is never cleared. The timeline remains mounted after the burst. This contradicts the comment that it costs nothing once finished and creates a potential ongoing idle rendering/energy cost across many screens.

Pause/remove the schedule when the burst ends. Use profiling to quantify actual callbacks/CPU before claiming battery impact; no energy measurement was made in this audit.

## Rules and teaching accuracy beyond the challenge

### F19. P2, new defensive coaching contradicts the exposure-lock rule

**Evidence: source/content and current official rule bulletin. Persona: intermediate player learning safe discards.**

`MonthlyChallengeContent.swift:370` and `:376` describe a tile matching an opponent's exposures as the worst throw and most likely to finish the hand. A natural exposed pung is complete and cannot grow after its owner discards. The fourth natural copy generally cannot improve that exposed group. `PlusContent.swift:198` correctly teaches the fourth copy of an exposed 6 Dot pung is one of the safest discards, and `MoreContent.swift:313` teaches the lock.

`ProContent.swift:101` has a related ambiguity: natural North and Red Dragon pungs are already exposed, yet both fourth-copy honors are graded worse than 5 Bam without enough information to establish that conclusion. Winds & Dragons can contain numbers, as the app itself says.

The [official NMJL January 2026 bulletin](https://nmjlbulletins.blob.core.windows.net/bulletins/202601/Nat%20Mah%20Jongg%20Jan-2026.pdf), page 3 questions 2 and 4, establishes when changes to an exposure end. Fix the exact remaining concealed needs, rather than treating matching an exposure as inherently dangerous.

### F20. P2, the glossary gives a false definition of Charleston stealing

**Evidence: source/content and tournament organizer's rules. Persona: beginner reading Reference.**

`ReferenceContent.swift:266` defines stealing as keeping an incoming tile and substituting one's own, restricted to blind rounds. Inspecting received tiles and keeping useful ones for the next pass is ordinary Charleston play. Stealing means forwarding permitted incoming tiles unseen.

The existing Blind Pass lesson at `CharlestonContent.swift:45` and glossary at `ReferenceContent.swift:258` are already correct and contradict this entry. [National Mah Jongg Tournaments' standardized rules, item 6](https://mahjongg.org/wp-content/uploads/2023/06/STANDARDIZED-NATIONAL-MAH-JONGG-TOURNAMENT-RULES-1.pdf) identifies stealing with blind passing. Merge the definitions or make stealing an alias.

### F21. P2, the glossary closes the discard-call window too early

**Evidence: source/content, corroborated by the app's fuller lesson. Persona: new player learning when a call is legal.**

`ReferenceContent.swift:278` says to claim before the next player picks. The correct fuller lesson at `MoreContent.swift:279` through `:287` allows a call until the next player has drawn and racked the tile. A user following Reference can incorrectly abandon a legal call after the pick but before racking.

Fix direction: reconcile the glossary with the fuller procedure and its rack/discard deadline. Have the content owner check the final wording against the NMJL rules book.

### F22. P2, payout questions omit the Singles & Pairs exception and reject a valid answer

**Evidence: source/content and official NMJL bulletin. Persona: experienced Singles & Pairs player.**

`MoreContent.swift:250`, `table-pay-jokerless`, asks generically what changes when a hand wins without jokers and grades double correct, although its explanation acknowledges the exception. `:257`, `table-pay-stacked`, asks what each player pays for a self-drawn jokerless win and accepts four times, rejecting Double without qualification.

A self-picked Singles & Pairs hand earns the self-pick doubling but no jokerless bonus, so Double is correct for a valid case admitted by the prompt. The [official NMJL January 2026 bulletin](https://nmjlbulletins.blob.core.windows.net/bulletins/202601/Nat%20Mah%20Jongg%20Jan-2026.pdf), page 4 question 11, confirms the exception.

Fix direction: specify a hand outside Singles & Pairs in both prompts or make the answer explicitly conditional.

### F23. P3, a scheduled challenge explanation invents an intervening draw

**Evidence: source/content and actual-source month scheduling. Persona: careful intermediate player.**

`MonthlyChallengeContent.swift:383` and `:392`, `monthly-def-just-passed`, says the immediately preceding player just discarded 6 Dot and nobody called, but explains the risk by saying the feared player has drawn since. No opponent has drawn in that interval. The item is scheduled for March 2027.

Fix direction: describe the immediate turn correctly, or change the scenario to a discard from an earlier round. The general caution about previously passed tiles is reasonable; the stated chronology is not.

## Feedback, privacy, reviews and retention

### F24. P2, random-question reports omit the data needed to investigate the answer

**Evidence: source. Persona: player reporting an incorrect generated answer.**

`QuestionReport` at `ReviewPromptSheet.swift:22` contains only item ID, prompt, source and tiles. `QuestionUI.swift:102` sends those fields, with the prompt additionally truncated to 160 characters. No choices, selected answer, answer index, explanation, miss note or random seed is included. EndlessPractice IDs are random UUIDs (`EndlessPractice.swift:118`, `:163`, `:224`, `:249`), so the ID cannot reconstruct the exact generated choice set.

The one-tap answer-seems-wrong report may arrive without the disputed answer. Fixed authored items are easier to find, but generated choice errors and shuffling issues are much harder to diagnose.

Fix direction: include a bounded snapshot of the exact question, choice identities/order, selected/correct identity, explanation and generator seed/version. Check privacy disclosures as part of that change. No actual report was sent in this audit.

### F25. P2, the public privacy policy does not describe new feedback and conversion transfers

**Evidence: live page fetched and compared with source. Persona: privacy-conscious subscriber.**

The [published policy](https://jackwallner.github.io/mahj/privacy-policy), still dated October 8, describes support messages as what the user chooses to send. It does not describe the new Supabase feedback processor, automatic question context, app/build, OS, device model, locale or membership flag sent by `FeedbackService.swift:20` and `:139`. It describes RevenueCat for purchase verification and ad attribution, but not the pitch counts, surfaces, dates, opens-before-pitch and conversion attributes transmitted by `SubscriptionService.syncConversionAttributes` and `ConversionDiagnostics`.

The generic statement that support messages exist does not explain those automatic fields or their retention/deletion handling. This is a concrete disclosure mismatch, not a claim that any processor leaked data or that the current ASC privacy labels were inspected.

Fix direction: update the policy to match real transfers and retention, then reconcile App Privacy/Play Data Safety disclosures. The live policy was fetched successfully with curl during this audit.

### F26. P2 risk, the custom enjoyment gate conflicts with Apple's current review-prompt guidance

**Evidence: source and current primary policy. Persona: App Review and an unhappy user.**

`ReviewPromptSheet.swift:145` asks for enjoyment, sends Yes to the native star prompt and routes Not really to private feedback. Both code comments and repository guidance explicitly describe filtering unhappy players out of the rating path. Calling the native API only after that gate does not remove the preceding custom prompt.

[Apple guideline 5.6.1](https://developer.apple.com/app-store/review/guidelines/#app-store-reviews) requires the provided review API and says custom review prompts are disallowed. This is a release-review risk inferred from the implementation and current policy, not a prediction that this specific submission will be rejected.

Fix direction: neutral positive-moment eligibility followed directly by the system prompt. Keep feedback independently reachable in Settings and question reports.

### F27. P2, monthly and daily challenge result sheets omit the review cooldown protection

**Evidence: source. Persona: user dismissing a review sheet by dragging it away.**

`DrillCompleteView.swift:108` correctly checks the host is still visible and calls `ReviewPromptTracker.markShown()` before presenting. `MahjMinuteView.swift:288` and `MonthlyChallengeView.swift:511` instead wait 1.4 seconds and set their presentation booleans, without either safeguard. ReviewPromptSheet marks the cooldown through button actions, but has no dismissal hook for dragging the sheet away.

Once eligible, dragging these result sheets away leaves lastShown unset, allowing the next qualifying result to ask again. Leaving within the delay also schedules an ask on a no-longer-visible host. The existing completion-screen comment explicitly documents this prior bug, but the fix did not reach these two paths.

Fix direction: share the guarded presentation/cooldown implementation and verify toolbar dismissal, drag dismissal, backgrounding and Done before the delay. This scenario was traced in source; the native rating system was not invoked during the audit.

## Android addendum

Current Android source was copied to an isolated directory on the configured remote MacBook Pro, excluding credentials, signing data, artwork, build output and local.properties. A temporary official Temurin 17 runtime was checked against its published SHA-256. The agent ran `./gradlew --no-daemon testDebugUnitTest`, with no RevenueCat key and no emulator.

**30 tests passed, zero failures/errors/skips:** ContentTest 9, GeneratorParityTest 8, StoreTest 13. Gradle reported BUILD SUCCESSFUL in 1m 52s. [Summary](solaudit1012-evidence/android/unit-summary.txt), [log](solaudit1012-evidence/android/unit-tests.log) and XML reports are committed with the evidence. Temporary remote source/runtime and the task's Kotlin daemon were removed. This proves unit/parity behavior, not Android UI or billing.

Android's missing Monthly Challenge is an explicitly documented platform gap, not a newly discovered regression. Its notes intentionally omit that promise. Android still declares version 1.3.1/versionCode 1, so future 1.4 note promises were not counted as currently displayed bugs.

### F28. P2, Android cold launch cancels a paid member's saved Game Night reminder

**Evidence: source-confirmed initialization race. Persona: returning paid Android member.**

`android/.../data/SubscriptionService.kt:57` starts every Release process with isPro false; customer information arrives asynchronously at `:80`. `ui/RootScreen.kt:126` runs `LaunchedEffect(isPro)` on initial composition and switches Game Night reminders off whenever that value is false. `data/AppSettings.kt:107` persists false and cancels the alarm. The later active-membership response does not restore the preference.

A paid player with reminders enabled can lose them simply by opening the app, especially with slow/offline customer info. iOS's corresponding onChange does not run initially, so this exact path is platform-specific.

Fix direction: distinguish unresolved membership from confirmed lapse, preserve preferences while loading/offline, and cancel only after an authoritative inactive result. Verify a cold launch with delayed customer info and an existing alarm.

### F29. P2, Android repeating reminders drift from the selected local hour across DST

**Evidence: source and isolated timezone arithmetic. Actual AlarmManager delivery not observed. Persona: player expecting a regular local reminder.**

`android/.../data/Reminders.kt:31` converts a selected local time once and repeats at fixed 24-hour or seven-day millisecond intervals. The manifest only reschedules on BOOT_COMPLETED. Those intervals do not preserve local wall time when daylight saving or the timezone changes.

[Arithmetic proof](solaudit1012-evidence/android/dst-proof.txt): Los Angeles October 31 at 09:00 plus 24 hours becomes November 1 at 08:00. Thursday October 29 at 17:00 plus seven 24-hour days becomes November 5 at 16:00. Settings still shows the original hour. Inexact alarm delay is a separate issue, not the basis of this finding.

Fix direction: schedule the next calendar occurrence as a one-shot, recompute after delivery and time/timezone changes, and test both DST directions.

### F30. P2, Android timed challenge counts scheduler ticks rather than elapsed time

**Evidence: source. Persona: timed-challenge competitor. Android background suspension not runtime tested.**

`android/.../ui/screens/SessionScreens.kt:288` subtracts one after each `delay(1000)`. A longer scheduler pause still counts as one second, so elapsed answering time can exceed ninety seconds. iOS `Drills/PracticeRunView.swift:333` already uses a deadline specifically to fix the earlier suspension/overrun behavior; the Android port retains the old algorithm.

Fix direction: a monotonic deadline with remaining time recomputed after pauses/resume, with a clear intentional pause policy if desired. Verify wall-clock duration under load and background/resume before comparing best scores.

### F31. P3, Android Game Night permission denial has no local recovery explanation

**Evidence: source. Persona: notification-denied Android player.**

`ui/RootScreen.kt:68` sets reminderPermissionDenied, but only `SettingsScreen.kt:192` displays the explanation and Open Settings action. `PracticeScreens.kt:282` exposes the Game Night reminder switch without observing that denial. A player entering Game Night Prep directly from Home can deny permission and see the switch silently stay off, with no recovery instructions on that surface. iOS handles this inline.

Fix direction: display the permission result at the requesting surface or centralize it in RootScreen. Verify first denial and permanent denial from Home, not just from Settings.

Two shared problems are also present on Android: unconditional seven-day trial copy, and ordinary flashcard grading available only by pointer drag rather than TalkBack actions. The latter has a semantic Reveal action on Android, but lacks semantic Knew It/Again grading. They are cross-platform extensions of F05/F13, not separately counted duplicates.

## Remaining verification before a release claim

These gaps are not counted as bugs:

- Physical device TestFlight install and upgrade, real VoiceOver speech/actions, Switch Control, hardware keyboard and Reduce Motion preference verification.
- iPad landscape, split view, Stage Manager and smaller/wider iPad models. Available headless UI tools did not expose rotation; Simulator.app was never opened.
- Real eligible/ineligible sandbox purchases, restore, pending/delayed entitlements, renewal, cancellation and trial reminders. No money was spent.
- Actual production feedback delivery, server rejection/recovery, notification permission revocation and notification firing across month/DST boundaries. Offline retry was tested with intercepted transport only.
- Full legacy deck completion on iPad. Front/back and five cards were exercised; ordinary phone Get Started completion was tested separately.
- Battery/CPU measurement of the confetti schedule, exact UI performance under the non-Gregorian archive explosion, live ASC privacy labels and App Review submission/event state.
- Interactive iOS 27 coverage beyond the visual Home/launch and challenge landing smoke check. The accessibility automation session repeatedly failed even after an own-device reboot. The app did reach Home and the challenge; tool failure alone is not classified as an app crash.

Additional lower-confidence observations to investigate: Reference's custom expansion buttons lack an explicit expanded/collapsed accessibility value; monthly reminder status is cached separately from actual notification authorization; the delayed What's New and churn presentations can compete on an upgrade launch. These require targeted runtime checks and are not promoted to confirmed findings here.

## Suggested repair and re-audit order

1. Repair feedback queue persistence, calendar identity, Play a Hand scoring and trial eligibility. Correct all dead-hand/rules contradictions and resync shared Android content.
2. Version/snapshot challenge content and reconcile completion credit. Add meaningful regressions using the preserved counterexamples.
3. Fix onboarding/report/Home reflow and semantic choice/deck/rack actions. Recheck the complete journeys at AX5 on phone and iPad, with VoiceOver on a physical device.
4. Align privacy/review flows and reminder behavior. Run eligible and ineligible subscriber scenarios, then the production-independent offline/recovery matrix.
5. Rerun the iOS and Android suites, perform a real build upgrade with saved results/in-progress runs, and repeat the device checks before declaring the release ready.
