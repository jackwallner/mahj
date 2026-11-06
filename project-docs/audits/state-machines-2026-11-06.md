# State machine audit, 2026-11-06

Scope: iOS app and `Shared/` at HEAD (`5da0345`, 1.4.4 build 82), plus `supabase/` functions the app's score and entitlement paths touch (read only). There are no widget or watch targets. Android is out of scope. No app code was changed.

**Summary: 6 bugs. 3 proved by a failing test with a passing control in the same suite (SM-03, SM-04, SM-05), 3 by code path only (SM-01, SM-02, SM-06). 3 of the 6 are product calls (SM-04, SM-05, SM-06).** 14 state machines documented below. Money and trial paths (M1 to M3) were traced end to end and produced no bad transition; the defects are in notifications, a derived "gain" number, and a few stores that outlive the entitlement or a reset.

Repro suite: [state-machines-2026-11-06-repro.swift](state-machines-2026-11-06-repro.swift). Run by copying it to `MahjTrainerTests/StateMachineAuditRepro.swift` and `gh-sim test --scheme MahjTrainer --only MahjTrainerTests/StateMachineAuditRepro` (run `mahj@20261106-110853-5abb-claude-imac95e8-1106-112116-6682`: 4 passed, 3 failed, as intended). Real recorded failures:

```
FAIL testBugWeeklyGainCountsRegainedAccess(): XCTAssertNil failed: "2" - No question was answered after the baseline day, so there is no weekly gain to report
FAIL testBugAnsweringAnotherDrillDiscardsTheHalfDoneRun(): XCTAssertNotNil failed - Drill A had three answers saved and was never finished
FAIL testBugResetProgressChangesTheChallengePlayerIdentity(): XCTAssertEqual failed: ("C84159C0-0116-484B-90B5-15B20D66561A") is not equal to ("C8FEBD95-CCF7-4B90-A37B-9F3AD3AA628A") - One person, one month, one server row
```

Passing controls: `testControlWeeklyGainIsNilWhenNothingChanges`, `testControlWeeklyGainCountsRealAnswers`, `testControlOpeningAnotherDrillKeepsTheHalfDoneRun`, `testControlTokenIsStableWithoutReset`.

## Bugs, ranked by impact

| Id | Bug | What the user sees | User route | Evidence | file:line |
|---|---|---|---|---|---|
| SM-01 | A lapsed member's weekly game night reminder keeps firing and cannot be turned off in the app | "Your game night prep is ready" every game night after cancelling; tapping it opens the paywall; the locked Game Night Prep tile still shows the weekday | Member: Home > Game night card (or Training > Game Night Prep) > turn on "Weekly game night reminder", allow notifications. Let the subscription end while the app is closed (the normal case: cancel in iOS Settings, trial or period runs out). Open the app: Home shows Game Night Prep locked with "Thursday" as its badge. The only toggle lives inside Game Night Prep, whose tile opens the paywall for a non-member | **Code path** | `HomeView.swift:318-327` (only teardown), `AppSettings.swift:102-110`, `HomeView.swift:1032`, `HomeView.swift:1123-1126` |
| SM-02 | Daily and game night reminder toggles never reconcile with iOS notification permission or the scheduled requests | Toggle reads ON, time picker shown, "Prep is scheduled", and nothing ever fires | Settings > Daily Reminder on, allow. iOS Settings > Mahj Trainer > Notifications off (or restore the phone from an iCloud backup, which restores UserDefaults but not pending notifications). Back in the app: Settings still shows Daily Reminder ON; Game Night Prep still says "Prep is scheduled" | **Code path** | `AppSettings.swift:77-86`, `AppSettings.swift:131-148` (init reads flags only), `GameNightPrepView.swift:78`; control: `MonthlyChallengeView.swift:437-444` does reconcile |
| SM-03 | Weekly gain counts regained Mahj+ access as learning | Home chip "+2 questions locked in this week" and Your Progress "Up 2 this week" right after rejoining, with no practice | A former member knew Plus questions. They lapsed and opened Home on later days (ledger records free totals). Within 7 days: Home > Get Mahj+ > start the plan. Home chip and Your Progress now show the gain | **Test** | `MasteryLedger.swift:33-52`, `HomeView.swift:393-397`, `HomeView.swift:679`, `StatsView.swift:26` |
| SM-04 | Reset Progress deletes the challenge score token, so the same player re-posts the month as a second player | After a reset the standing counts them twice: the old row stays on the server and a new one is added, shifting every other player's "Top N%" | Settings > Reset Progress > Reset. Home > challenge card > Play Today's Mahj Minute > finish (the standing refresh posts with a new token). **Product call** | **Test** (token) plus server Code path | `MonthlyChallengeStore.swift:165-174`, `MonthlyChallengeStore.swift:222-226`, `ChallengeStandingService.swift` (`p_player`), `supabase/migrations/20261018120000_challenge_scores.sql` (one row per token) |
| SM-05 | One saved-run slot: answering a single question in any other drill replaces a half-done run | The Resume card for "Meet the Tiles" is gone after the player tried one question in another drill; Get Started restarts with a new mix | Room > drill A, answer 3 questions, Back. Room > drill B, answer 1 question, Back. Home's Resume card now offers B, A starts over. **Product call** | **Test** | `OrdinaryRunStore.swift:72-79`, `OrdinaryRunStore.swift:90-96` |
| SM-06 | A half-played challenge day is closed as "played" with the answers it has | A day shows as played with 1 of 5, and the other four questions cannot be played the next day | Home > challenge card > Play Today's Mahj Minute > answer question 1, leave. Next calendar day open the app: Home closes yesterday on 1 answer. **Product call** | **Code path** | `MonthlyChallengeStore.swift:207-220`, `HomeView.swift:249`, `HomeView.swift:313`, `HomeView.swift:428-430` |

### Promise each bug breaks

- **SM-01**: "Free players never see it; the prep is a member surface." (`.claude/rules/feedback-and-retention.md`, Game night card). The reminder body "Your game night prep is ready" (`AppSettings.swift`, `scheduleGameNightReminder`). The only teardown is a live `isPro` true to false change (`HomeView.swift:318`); `isPro` starts false each launch (`SubscriptionService.swift:209`), so a lapse that happened while the app was closed is false to false and `onChange` never fires. Besides that handler, `gameNightReminderEnabled` is only written by the two toggles (Game Night Prep, and the Home card that opens it), and `cancelGameNightReminder` runs only from the property's `didSet`. To settle: on a TestFlight build, enable the reminder as a sandbox member, let the sandbox subscription expire with the app killed, relaunch, and read `UNUserNotificationCenter.getPendingNotificationRequests` for `mahj.gameNightReminder` (expect present; the fix would remove it).
- **SM-02**: the code's own standard, `MonthlyChallengeView.swift:437`: "Notifications switched off in iOS Settings: say so rather than show a reminder that will never arrive." The monthly button re-reads `authorizationStatus` in `.task`; `AppSettings` never calls `getNotificationSettings` or `getPendingNotificationRequests` (grep over `MahjTrainer`, `Shared`, tests finds only the monthly one). To settle: on a device, schedule, revoke, return, and compare the toggle with `getPendingNotificationRequests`/`notificationSettings()`.
- **SM-03**: "Home and Your Progress now show how many questions you locked in this week, so you can see the practice working." (`WhatsNew.swift` 1.4.1 item `week-gain`) and Home's chip label "N questions locked in this week" (`HomeView.swift:679`). `recordMastery` writes known counts under the current membership (`masteryByRoom(isMember:)`), so a membership change moves the total with no answer behind it. Already described in `.claude/rules/mastery-coaching-whats-new.md` ("Weekly gain access-change gap", 2026-10-16, builds 45 and 46) and still present at HEAD.
- **SM-04**: ledger comment on the token: "A random id for this install's score in one month"; the server table comment: "One row per app, month and random per-month token". Reset removes the token (`tokensKey`), the old row stays (`greatest()` upsert never deletes). Real player counts are tiny (the monthly-challenge rules note 8 players on the November event), so one duplicate matters. Product call: Reset says "Your streak, completed drills, and practice history will be cleared" and may legitimately restart the challenge.
- **SM-05**: `OrdinaryRunStore.save` comment: "The one slot holds a run with answers. An unanswered run never replaces it (a peek at another drill wiped a half-done one)". The author protected the peek case but not the answered case. Product call: single slot may be the intended simplification.
- **SM-06**: `HomeView.closeEarlierChallengeRounds` comment: "A round left half done on an earlier day is scored on what was answered". Intended, but it permanently turns a day the player did not finish into a played day with a partial total. Product call.

### Fix grouping, in order

1. **Reconcile reminders with reality at launch and foreground** (SM-01, SM-02): one `AppSettings.reconcile(isMember:)` that runs when membership resolves and on `.active`, reads `notificationSettings()` and pending requests, turns off game night when not a member, and clears a toggle whose permission is gone or whose request is missing. Fixes both and removes the `HomeView` live-transition special case.
2. **Make weekly gain a learning delta** (SM-03): store the membership flag with each ledger day, or compute gain only over item ids that were trackable on both days.
3. **Decide the reset and slot semantics** (SM-04, SM-05, SM-06): keep the month token across Reset (or tell the server), decide whether an answered run in another drill should park rather than replace, and decide whether a half day should close as played.

## Considered and not claimed

- Remote kill switches (`isOn`) read ON while `offerings` is nil (`RemoteConfig.swift`), so `trial_offer: off` and `rating_prompt: off` do not hold on a first launch with no network. No route that is not a first-ever offline launch; RevenueCat serves cached offerings otherwise.
- `loadOfferings` assigns `offerings = nil` after a failed fetch (`SubscriptionService.swift:474-477`). Every caller reloads only when the needed package is already missing, so no loaded state is lost on a shipping route.
- Saved quiz and deck runs resume against the room's current content. A release that shortens a drill would index past the end for a player with a run saved at a high index (`QuizDrillView.swift` `questions[index]`). Latent, needs a future content edit.
- Trial-end reminder (`AppSettings.requestTrialEndReminder`): no caller since build 47. Dead code, only the cancel path runs.
- Reminder toggled off while the permission callback is in flight re-schedules (`AppSettings.swift:229-240`): needs the system alert open at the same time as a tap on the toggle.
- Churn `spent` flag stale across an unobserved resubscribe-and-cancel (M3).
- Streak across a time zone change: `bumpStreak` counts calendar days in the current zone, so a flight east can count two sessions hours apart as two days. A product call on how travel should read; no data lost.

## State machines

Notation: `I-n` are invariants. A transition row marked **BAD(I-n)** breaks that invariant and is reachable at HEAD; the bug id it maps to is in brackets. Unmarked rows are intended.

### M1 Membership and entitlement (`SubscriptionService`)

Spread over: `isPro`, `membershipResolved`, `isTrialing`, `expirationDate`, `offerings`, `trialIneligible`, private `trialEligibility`, `membershipRecovery.last`, UserDefaults `membership.reinstallSyncDone`, `membership.lastSnapshot`, DEBUG `subscription.localProOverride`.

States (derived):

| State | isPro | membershipResolved | Meaning |
|---|---|---|---|
| Unresolved | false | false | Cold start, no customer record read yet. Reads as free for every member. |
| Free | false | true | A record was read, no active `pro`. |
| Trial | true | true | `periodType == .trial`. |
| Paid | true | true | Paid or lifetime. |

Invariants:
- I-1 Nothing treats Unresolved as a lapse or sells to it (`membershipResolved` gate).
- I-2 `isPro` reflects the newest customer record (no older record may overwrite a newer one).
- I-3 Every member-only side effect that was set up while Paid is torn down on every route into Free, including a cold start into Free.
- I-4 No sale while ownership is unknown (`PurchaseGate`).

| From | Event | To | Notes |
|---|---|---|---|
| Unresolved | `start()` applies `cachedCustomerInfo` | Free / Trial / Paid | cache can be stale (see `observe` baseline rule) |
| Unresolved | network `customerInfo` | any | |
| Free | purchase / restore / delegate update | Trial or Paid | `apply` |
| Trial | converts | Paid | no churn moment |
| Trial or Paid | expiry seen live (app running) | Free | Home `onChange(isPro)` switches the game night reminder off |
| Trial or Paid | expiry while app not running, then cold start | Free | **BAD(I-3)** [SM-01]: `isPro` goes false to false, `onChange` never fires, reminder stays scheduled and enabled |
| any | delegate `receivedUpdated` racing a fetch | last writer wins | I-2 not enforced (`apply` takes no record timestamp). Code path only, not claimed |

Recovery runner (`MembershipRecoveryRunner`): `idle -> running -> {ownsNothing, recovered, ownedUnsynced, unresolved}`. Stale checks (older than 15 s) are given up and a result from a given-up attempt is dropped (`attempt` counter). Verified by reading: a late `syncOutcome` can set `reinstallSyncDone` after the attempt was dropped, but that only happens when the entitlement was active, which makes `isPro` true and `PurchaseGate.decide` returns `.alreadyMember` before it reads `last`. No bad transition found.

### M2 Purchase attempt (onboarding trial page, `PaywallView`, `TrialOfferSheet`)

States per surface: `idle -> preflighting (purchasing = true) -> {redraw, noProduct, alreadyMember, unavailable(throws), buying -> {cancelled, purchased -> confirming -> {unlocked, stuck-message}}}`.

Invariants:
- I-5 The price and trial wording on screen at the tap equal the live terms at purchase time (`PreflightVerdict.decide`).
- I-6 The disclosure names the plan the CTA buys (3.1.2).
- I-7 A cancelled Apple sheet never opens another paywall.
- I-8 A closed surface cannot start a purchase (`Task.checkCancellation` right before StoreKit).

| From | Event | To | Notes |
|---|---|---|---|
| idle | tap with price nil | redraw | never buys |
| idle | tap, eligibility changed | redraw | |
| preflighting | surface closed | cancelled task | I-8 holds |
| buying | user cancels Apple sheet | cancelled | stays put, I-7 holds |
| purchased | entitlement late | stuck-message | tells the player to tap Restore |
| any | member found by reinstall sync | alreadyMember | surfaces dismiss or continue |

No bad transitions found. Tests exist for each verdict (`PurchasePreflightTests`, `PurchaseGateTests`).

### M3 Churn question (`observe`, `MembershipTransitions`)

State: `membership.lastSnapshot` (active, trial, willRenew), `membership.churnAskSpent`, `membership.pendingChurnMoment`, Home `churnPrompt`.

Invariants:
- I-9 At most one stored moment per departure.
- I-10 A departure nobody watched is never asked about.
- I-11 A queued moment is dropped if the player comes back before Home shows it.

| From | Event | To |
|---|---|---|
| no snapshot, record older than 300 s | `apply` | ignored, no baseline (I-10) |
| active, willRenew | renewal off | pending moment, spent = true |
| pending | player returns (renewal on) | pending cleared, spent cleared (I-11) |
| spent | lapse | no second ask (I-9) |
| lapsed, spent | resubscribe observed | spent cleared |
| lapsed, spent | resubscribe and cancel renewal both before the app next opens, then lapse | stale `spent` suppresses the ask. Needs an unobserved resubscribe, not claimed |

### M4 Onboarding (`OnboardingView`, `RootView`)

State: `stage` (`pages | howToPlay | tour`, `@State`), `page` (`@State`), `skillLevel` (`@AppStorage`), `purchasing`, `restoring`, `showPaywallFallback`, `progress.hasOnboarded` (defaults), `sessionsAtOnboarding`.

Invariants: I-12 Skill question cannot be swiped past. I-13 Both escape hatches reach Home. I-14 `hasOnboarded` and `sessionsAtOnboarding` are written together.

Transitions: all intended. `stage` and `page` are not persisted, so a kill during the tour restarts at page 0 (a player who already bought sees "Continue", I-6 holds). No bad transition found.

### M5 Trial sheet pacing and rating prompt (`TrialOfferPacer`, `ReviewPromptTracker`)

State: `trialOffer.*` keys, `reviewPrompt.*` keys, scene phase. Invariants: I-15 at most 3 automatic asks per day on install day and the next, once per session. I-16 rating prompt stands down 120 s after an automatic ask. I-17 gaps 3, 7, 14 days afterwards. Checked by reading and existing tests (`TrialOfferPacerTests`, `ReviewPromptTrackerTests`). A backwards clock makes `now - last` negative and holds the next ask until the clock catches up (not claimed).

### M6 Notifications

| Item | Source of truth | Scheduled by | Cancelled by |
|---|---|---|---|
| Daily reminder | `settings.reminderEnabled` + time | toggle on, time change | toggle off |
| Game night reminder | `settings.gameNightReminderEnabled` + day + time | toggle on, day or time change | toggle off, Home `onChange(isPro)` true to false |
| Monthly challenge reminder | `monthlyChallenge.reminder` | enable, foreground refresh | disable, remote switch off |
| Trial-end reminder | none | no caller in the UI since build 47 | `apply` when trial ends or renewal off |

Invariants:
- I-18 A toggle that reads ON means an OS-authorized, scheduled request exists.
- I-19 A member-only reminder does not outlive membership.
- I-20 A reminder can always be turned off from the UI that shows it.

| From | Event | To | Notes |
|---|---|---|---|
| ON, authorized | player revokes notifications in iOS Settings | toggle still ON, nothing fires | **BAD(I-18)** [SM-02]; the monthly reminder button reconciles (`.task`, `authorizationStatus == .denied`), these two do not |
| ON | restore from iCloud backup to a new phone | defaults say ON, pending requests gone | **BAD(I-18)** [SM-02] |
| game night ON, Paid | lapse while app closed | still ON, fires weekly, tap opens paywall | **BAD(I-19, I-20)** [SM-01] |
| ON | player toggles off while permission callback in flight | callback re-schedules | needs a system alert open at the same time, not reachable, not claimed |

### M7 Saved run slot (`OrdinaryRunStore`) and the drills

States of the slot: `empty | run(drill, answers>0)`. Drill states: `fresh -> answering(selection nil) -> graded(selection set) -> advancing -> finished`, flashcards add `flipped`, `pendingAnswer`, `lastSwipe`.

Invariants:
- I-21 A graded answer is recorded exactly once (resume re-enters `graded`, it does not regrade).
- I-22 Undo restores the exact pre-answer item state.
- I-23 A half-done run is never lost without the player choosing to discard it.
- I-24 A locked run is never offered (`OrdinaryRun.isLocked`).

| From | Event | To | Notes |
|---|---|---|---|
| run(A) | open B, no answer | run(A) | peek keeps A |
| run(A) | answer one question in B | run(B) | **BAD(I-23)** [SM-05] product call |
| run(Quick Session) | answer in a room drill | run(drill) | Get Started restarts with a new mix, same cause |
| graded last question | kill app | slot holds run, Finish completes it | I-21 holds |
| flashcard graded | undo | restores both stores | I-22 holds |
| lapsed member, run with Plus items | Home | Resume hidden, run kept on disk, overwritten by first answer | I-24 holds |

### M8 Quick Session (Get Started) and the daily gate

State: saved run, `progress.lastQuickSessionDay`, view `finished`. `markQuickSessionCompleted` runs at Finish, `recordSession` at the completion screen's `onAppear`. Kill between them leaves the day marked complete with the session uncounted (one frame wide, not claimed). Empty session never banks a day (guard in view). No bad transition found.

### M9 Monthly challenge round (`MonthlyChallengeStore`, `QuickSessionView(monthlyRound:)`)

States per round key: `notStarted -> inProgress(k answers) -> done`. A round left `inProgress` when the day changes is closed as `done` with the answers it has.

Invariants: I-25 one result per round key. I-26 answers land in the day they belong to. I-27 one server identity per player per month. I-28 a closed partial day equals what the player expects "a day played" to mean.

| From | Event | To | Notes |
|---|---|---|---|
| inProgress | day changes | done with k of 5 | SM-06 product call: the other questions of that day can never be played |
| done | Reset Progress | notStarted | results, standings and the month token are deleted |
| notStarted (after reset) | finish round | new `challenge_submit` row with a new token | **BAD(I-27)** [SM-04] product call |

### M10 Play a Hand and the free hand (`HandPlayStore`, `HandPlayView`)

States: `choosing -> committed -> playing(turn n, grade nil|set) -> finished`; store: `inProgress`, `lastFreeHandDay`. `recordStart` runs at the start tap; `saveProgress` after each draw and throw; `clearInProgress` at finish. Invariants: I-29 a free player starts at most one hand per local day; I-30 a started hand is resumable. Traced all kill points: the only gap is between `recordStart` and the first `saveProgress` (same runloop turn). No bad transition found.

### M11 Timed Challenge (`PracticeRunView`)

States: `ready -> running (wall-clock end) -> finished`. The clock uses an absolute end date, so a suspension longer than the remaining time ends the run on resume. Score is banked on `finish` and on `onDisappear`. A run with zero answers dismisses instead of banking. No bad transition found.

### M12 Progress, streak, ledger, reset (`ProgressStore`, `MasteryLedger`, `PracticeRecordStore`)

Invariants: I-31 `weeklyGain` counts only questions answered since the baseline day ("how many questions you locked in this week"). I-32 Reset Progress clears every practice stat and leaves purchases alone.

| From | Event | To | Notes |
|---|---|---|---|
| ledger day recorded as free | membership regained | today recorded as member, known Plus questions counted | **BAD(I-31)** [SM-03] |
| any | Reset Progress | stores cleared except onboarding, review tracker, trial pacer, free-hand day | by design |
| any | clock moves backwards | `bumpStreak` returns early, keeps later day | intended |

### M13 Feedback queue (`FeedbackService`)

`submit -> {sent, queued(≤20), failed(4xx)}`; `flushPending` removes a row only after the server answered for it; one flush at a time. Duplicate rows are possible when a request is accepted but the response is lost (inherent to at-least-once, not claimed). No bad transition found.

### M14 Routing and Home gating (`AppRouter`, `HomeView`, `WhatsNew`)

`pendingDestination` is one slot; a second link replaces the first. `routeAction` waits for membership (and remote config for the challenge) up to 4 s, then goes on what is known. Prompts (What's New, churn) wait for a bare Home. `WhatsNew.shouldPresent` marks seen as it is shown. No bad transition found.
