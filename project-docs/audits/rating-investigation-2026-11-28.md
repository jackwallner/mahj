# Rating investigation, November 28, 2026

## Scope and limits

The lead was a four-star Canadian rating with no comment, observed between November 26 and 27, 2026. It does not identify an install, version, device, screen, or failure. No defect below can be attributed to that rater. Absence of TestFlight crashes does not rule out App Store crashes; Apple's production crash reports have no public API route.

The likely public version was **1.4.5, build 88** (`d2cd689`). A read-only App Store Connect check on November 28 confirmed build 88 attached to 1.4.5 and build 84 attached to the preceding 1.4.4; 1.4.6 remains waiting for review with build 96, unchanged. Canadian PostHog events in the UTC November 26 to 28 window independently identify 1.4.5. They contain 51 answers and five practice completions, including room drills and the monthly challenge. No exception event appears in those Canadian events. This is partial telemetry, not proof of crash-free operation or identification of the rater.

## Release review

Reviewed the commit list from **1.4.4, build 84** (`0677d6a`) through `d2cd689`, then read every application-source diff. The app changes are:

| Commits | Change | Audit result |
|---|---|---|
| `cebf377`, `b4dfd69` | Clarify the dead 5 Bam teaching scenario, its translated prompt and explanation, and content checks | Four real 5 Bams are accounted for. No new defect established in the edited content. |
| `289d9e9` | Arabic physical swipe direction in the deck and primer | No causal link to the uncommented Canadian rating. English paths remain unchanged. |
| `118dfb1` | Limit the result's Done button to the session's readable width on iPad | No new failure established. |
| Build/version commits | Move build 84 to 88 and version 1.4.4 to 1.4.5 | Match the public release. |

Other commits in the range change the website, marketing assets, documentation, plugin packaging, exported Android content, or QA material, not the iOS runtime. Known clipping and teaching-content fixes added after build 88 were also checked; those are already on main and must not be described as new findings of this investigation.

## Runtime defect: notification cancellation can freeze launch

The actual build-88 UI run produced an unresponsive app while `PaywallRenderTests.testOnboardingTrialStep` tried to find the first Continue button. This was not dismissed as a harness timeout.

Its captured spindump shows the UI thread had not run for **98.252 seconds**, with all 258 samples in this call chain:

```text
SubscriptionService.purchases(_:receivedUpdated:)
  SubscriptionService.apply(_:)
    AppSettings.cancelTrialEndReminder()
      UNUserNotificationCenter.removePendingNotificationRequests(withIdentifiers:)
        NSXPCConnection waiting for a synchronous reply
```

`SubscriptionService.apply` calls the cleanup when the account is not in a renewing trial, even when the retired trial-reminder feature has never been used. `AppSettings` is main-actor isolated. The notification API's apparently void removal call still waits synchronously on the notification service, which prevented input and UI queries during this run. The later first-run journey succeeded after relaunch, so the failure is intermittent rather than every launch.

The fix dispatches notification mutations through `NotificationRequests`, a serial utility queue. The UI can finish processing the RevenueCat record without waiting for the notification service. Daily, game-night and monthly reminder remove/add operations use the same queue, so the same blocking API cannot freeze their UI callers either. Copy, identifiers, trigger components, repeat flags, sound and routing metadata are preserved. No permission, billing, or trial-flow behavior is changed. An injected removal operation lets `MemberReminderTests.testTrialReminderCancellationRunsOffTheUIThread` test the actual dispatch path without relying on a system-service hang; a second test checks submission order.

Evidence: `gh-sim` run `mahj-rating-live-88-imac7b92-1128-014205-23127`, failed UI test and attachment `4816FC13-1F75-4987-9BC9-40862C5A1892.txt`. The spindump contains no evidence that this anonymous rater encountered the hang.

## Runtime defect: a warm challenge link replaces active practice

The early run `mahj-imac7b92-1128-020820-15868` failed to return from the challenge to a Timed run. The room-drill case instead timed out during launch. The first after-fix UI run, `mahj-imac7b92-1128-025637-24430`, passed 12 tests but failed four route cases. Inspection exposed two harness problems: `XCUIApplication.open` invokes target launch rather than proving delivery to the same running process, and the room test asked for `Next` when the actual button was `Next Question`. The early timed failure is therefore **not counted as valid proof of a warm-link defect**.

The corrected helper uses Apple's system URL opener, `XCUIDevice.shared.system.open`, and asserts that the app process identifier stays unchanged. Its Next lookup accepts the actual labels. The valid counterfactual run, `mahj-rating-system-route-before-imac7b92-1128-033925-15936`, kept old navigation and included the notification fix only to remove that unrelated launch blocker. Its same-process assertions passed. The room-drill case failed specifically on `Back from the challenge discarded the room drill`; the timed case failed specifically on `Back from the challenge did not return to the Timed Challenge`. The repeated-link-within-the-challenge control passed. This establishes a real warm-link navigation defect independently of target relaunch.

The cause is mixing view-based pushes with a bound typed path: the path does not contain the open view destinations, and changing it replaces them. A room drill can still be recovered through its saved Resume card, but its Back stack is lost. Timed practice is not resumable and loses its in-memory run.

The value-path candidate run `mahj-imac7b92-1128-035522-13573` passed the same-process room, Endless, Timed and repeated-challenge cases. It failed the fifth case: Settings still covered the challenge. The old launch-based Settings test had hidden that separate failure by relaunching the target.

The fix replaces mixed view-based and typed pushes with `NavigationScreen` values, including room purchase continuation. Home owns separate navigation instances for its root, Duo pane and presented Settings sheet, and routes into the visible one. Settings observes that injected instance, so a link appears in front and Back preserves Settings. Its path is cleared only when the sheet is dismissed. Parent-route tracking preserves a held daily question on repeated links, and a manually started Game Night Prep tags its reminder route so the same guard can recognise it.

Final corrected route run `mahj-imac7b92-1128-041712-4110` passed **all five tests**, with no failures or skips. Each delivered URL retained the app process. Room and Endless return with the exact prompt and held answer; Timed returns without restarting; the repeated daily link preserves its graded question; Settings shows a hittable challenge in front, then Back returns to Settings. Public build 88 also directly assigns `path = [destination]` in `HomeView.show` (`d2cd689:MahjTrainer/Views/HomeView.swift:195-203`), so the route replacement is not a new issue introduced by the candidate.

Guards: `RouteOverOpenScreenTests` and `ScreenNavigationTests`. No navigation symptom is attributed to the anonymous rating.

## Backend and support checks

- GitHub issues, all states: none returned on November 28.
- `qa/backlog.jsonl`: all 84 entries marked fixed at the starting main commit. `qa/ledger.jsonl` still has open P3 Q099. An unsupported temporary closure of Q099 during the investigation was reverted. No acceptance was added without identifying an element.
- In-app feedback was read through the existing read-only ops RPC, with no read marking. No report identified the anonymous Canadian rating. Messages are not reproduced here.
- Supabase management logs were queried read-only, one UTC day at a time because the log endpoint caps a request to a day. November 19 to 27 contained **477 shared-project requests** (not a Mahj-only traffic count) mentioning `challenge_submit` or `app_feedback`, with no recorded HTTP 4xx or 5xx responses. Daily counts: 47, 65, 61, 54, 50, 48, 68, 45, 39. This does not rule out device-side failures or missing logs. No synthetic production score or feedback was inserted.
- The current RevenueCat offering is `cta_my`, with annual, monthly, and lifetime packages and the expected metadata. All three iOS products are approved and available in Canada. Price history was read only; no price or availability was changed.
- The class-code RPC deployed on main responds as expected for an unknown code. This feature was not in public build 88 and is not an explanation for that version's rating.
- Both string catalogs contain French translations for every translatable entry. The content coverage tests guard authored content. No Canada-specific missing-product or missing-French-entry defect was established.
- Purchase preflight, reinstall recovery, cancellation, eligibility, and the simulator's no-production-RevenueCat guard were read. No charge was made.

## Verification so far

| Run | Result |
|---|---|
| `mahj-imac7b92-1128-002234-8489` | 362 test cases passed before the known StoreKit eligibility test hung; the one-hour wrapper stopped and cancelled the run. The earlier 401 count included passed suite headings. Not reported as a full passing run. |
| `mahj-imac7b92-1128-012746-8645` | Remaining 26 unit tests passed. The known hanging eligibility test was excluded. |
| `mahj-rating-live-88-imac7b92-1128-014205-23127` | Four UI tests passed: first-run launch to Home, session/challenge/paywall/settings round trip, core practice/held-answer resume/completion/relaunch, and real plan-card rendering. The fifth test captured the notification-service launch hang described above. |

The before-fix notification regression ran in `mahj-rating-notification-before-imac7b92-1128-022621-18076`. The test injected the removal operation while retaining the old direct, synchronous call. It failed exactly on `XCTAssertFalse(Thread.isMainThread)`, with the expected notification identifier. This is a deterministic isolation regression independent of notification-service availability.

An independent read-only review was attempted but could not start because agent authentication failed. It is not counted as a review pass. Direct code review checked reminder payload/date parity and the navigation path registrations.

After-fix unit run `mahj-imac7b92-1128-023947-9076` passed: **393 test cases passed, zero failed, one skipped**. The skip is the opt-in `LiveOfferingMetadataTests` SDK probe (`RC_LIVE` unset); production offering configuration was checked separately through the read-only API. `TrialEligibilityTests.testFreeWeekUntilTheAccountHasUsedIt` was explicitly excluded because of its documented simulator hang. Both new notification tests and all three `ScreenNavigationTests` passed. XcodeGen regenerated the project before building, including the new Swift files.

First after-fix UI run `mahj-imac7b92-1128-025637-24430`: **12 passed, four failed**. Cold launch and trial rendering, real plan rendering, the core practice/resume/completion/relaunch journey, large-text coaching, and wide rack journeys passed. The four route failures triggered the harness corrections described above. This run is not reported as a full pass. The queued Duo capture was intentionally not started because this run did not pass.

The corrected old-navigation comparison and final five-case routing run establish the navigation before/after results above. Together with the 11 non-route UI cases that passed, all **16 distinct UI journeys** are passing across the gh-sim runs. These are selective regression runs, not a claim that one combined 16-case job passed.

Final Duo run `mahj-imac7b92-1128-043816-31735` passed all **four `ScreenNavigationTests`**, including the new manual-prep route-tag test, with no failures or skips. This brings the distinct passing unit-test count to **394** across the runs (the original 393 plus the new route-tag case). It built and launched successfully on iPhone Duo / iOS 27.2, captured folded and unfolded Home, room, drill and Settings screens, and ended with the app still running. The folded drill/Settings and all four unfolded route captures were visually checked; no new layout defect was established. These are render checks, not a claim of a full unfolded gesture or hinge-interruption test.

## Delivery

Verified code commits:

- `3a41d85`: move notification service mutations off the UI thread.
- `0e0bad2`: track active practice in value-based navigation paths.
- `3f1587a`: correct warm-link delivery and Next-button regression helpers.
- `d4db153`: route through the visible Settings stack and tag manual prep.

The fixes and evidence are committed and pushed on main. `./scripts/testflight.sh` archived Release and uploaded **1.4.7, build 102**, with archive identity verified as `com.jackwallner.mahj 1.4.7 (102)`. Upload workflow: [46147776358](https://github.com/jackwallner/gh-sim/actions/runs/46147776358). The script committed the build bump as `303a724`; that commit is pushed.

App Store Connect independently confirms build **102**, version **1.4.7**, processing state **VALID**, not expired, uploaded **2026-11-28 05:14:51 PST**. Verified November 28, 2026 at 13:20 UTC. The full multi-persona release gate was not rerun; its missing receipt warning is expected for this TestFlight-only task and is not represented as a release-gate pass.

No App Review submission, release, price change, review reply, or user contact was performed. No spending was authorised or incurred by these public-repository GitHub runs. The anonymous rating's exact cause remains unknown.
