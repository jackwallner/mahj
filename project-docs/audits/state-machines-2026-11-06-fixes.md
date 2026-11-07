# Fixes for the state machine audit, 2026-11-06

Fixes for the claims [the review](state-machines-2026-11-06-review.md) kept from [the audit](state-machines-2026-11-06.md), in the review's ranked order. No verify file exists. An earlier run (`fleet/20261106-165014-9e99-claude`) committed three fixes and was interrupted before its test run; this run continued from those commits on `fleet/20261106-195146-7643-claude`, reworked its SM-01 fix (it had changed how membership is judged, which is held for Jack) and ran the suite.

**Summary: 3 in scope (SM-01 CONFIRMED, SM-03 and SM-02 CONFIRMED-MINOR). 3 fixed, 0 skipped, 2 held for Jack (the review's unverified renewal misread and its billing-recovery product call). Out of scope: SM-04, SM-05, SM-06 (NOT A BUG) and the review's "considered and not claimed" list.**

## Claims

| Id | Outcome | Commit subject | Regression test | What changed |
|---|---|---|---|---|
| SM-01 | Fixed | `fix: end a lapsed member's game night reminder at launch`, reworked in `fix: end the game night reminder only on a confirmed lapse` and `fix: let the lapse check read the record age off the main actor` | `MemberReminderTests.testAConfirmedLapseEndsTheGameNightReminder`, `testAnUnconfirmedLapseKeepsTheReminder`, `testAFreshNonMemberRecordConfirmsTheLapse`, `testAnOldCachedNonMemberRecordConfirmsNothing`, `testAMemberRecordConfirmsNothing` | Home ends the game night reminder on `SubscriptionService.lapseConfirmed`, on appear and whenever it changes, not only on a live `isPro` true to false change, so a lapse while the app was closed (the cold-start false to false case) now ends it. `lapseConfirmed` is true only for a non-member record RevenueCat answered within the last five minutes (`freshBaselineAge`, the bar the churn baseline already uses), so it comes from the network. A cached record never ends it: past RevenueCat's three-day grace a cached record reads a member who renewed while away as lapsed. `isPro` and `membershipResolved` are judged exactly as at `48c9ca06`: the earlier run's `recordSettlesMembership` guard, which left membership unresolved for some cached records, is removed. Writes only on a change. Rules note in `.claude/rules/rituals-and-hand-play.md`. |
| SM-03 | Fixed | `fix: stop counting regained Mahj+ access as weekly learning` | `MasteryLedgerTests.testRejoiningIsNotAWeeklyGain` (the audit's repro, which the review called sound), `testRealAnswersStillCount`; upgrade: `testOlderDaysStayTheBaselineWhenTheyCountTheSame`, `testOlderDaysThatCountedLessAreNotTheBaseline` | `MasteryLedger.record(from:)` writes every known question, open to the player or not, so joining or leaving Mahj+ moves no total. Home calls it in place of the membership-filtered count (the `membershipResolved` guard and the two membership `onChange` re-records went with the dependency). Stored format unchanged. Upgrade: older days stay on disk and stay the baseline when they count the same either way (every free player, and every member who never touched Mahj+ content, keeps their week). Otherwise the baseline starts at the upgrade day (`mastery.ledger.allAccessSince`), so a lapsed member's free-only days cannot fake a gain. Rules note in `.claude/rules/mastery-coaching-whats-new.md`. |
| SM-02 | Fixed | `fix: match reminder toggles to what iOS will deliver` | `ReminderReconcileTests.testNotificationsSwitchedOffReadOff`, `testNeverAllowedOnThisPhoneReadsOff`, `testAllowedAndScheduledStaysOn`, `testTogglesThatAreOffStayOff`, and the review's own check `testRestoredOnFlagWithNoPendingRequestIsReconciled` (real notification center) | `AppSettings.reconcileReminders()` runs at launch and on every `.active`. When iOS reports it will not deliver (denied, or not determined as on a restored phone) the daily and game night toggles read OFF, the same outcome the toggles already give when the permission alert is declined. When notifications are allowed and a request is missing, it is laid again rather than the toggle switched off. It skips while a permission alert the player just triggered is open, so turning a toggle on is never undone mid-prompt. Settings and Game Night Prep ("Prep is scheduled") now show the real state. Rules note in `.claude/rules/rituals-and-hand-play.md`. |

The audit's repro suite was not added to the test target: its SM-03 test is carried over as `testRejoiningIsNotAWeeklyGain`, and its SM-04 and SM-05 tests assert behaviour the review found NOT A BUG.

Fail without the fix: every regression test above calls an API the fix adds (`lapseConfirmed`/`confirmsLapse`, `endMemberReminders(lapseConfirmed:)`, `record(from:)`, `reconcileReminders`), so none compiles on `48c9ca06` (the base). The behaviour each one checks was recorded failing there by earlier runs: SM-03 by the audit's `testBugWeeklyGainCountsRegainedAccess` (`"2"`, run `mahj@20261106-110853-5abb-claude-imac95e8-1106-112116-6682`), SM-02 by the review's `testSM02RestoredOnFlagWithNoPendingRequestIsReconciled` (run `mahj@20261106-113635-7bce-claude-imac12fd-1106-114022-1902`), and SM-01 by the review's code path (`HomeView.swift:318-327` at `f485014` was the only teardown and needed a live `isPro` change).

## Held for Jack

- **SM-R1, a member who renewed while away reads as a non-member until the network answers (review: UNVERIFIED, seen but not claimed).** The earlier run read RevenueCat 5.72 (`CustomerInfo+ActiveDates.swift`, `requestDateGracePeriod = .days(3)`) and found the SDK side holds: a cached record more than three days old judges a renewed period against now and reads it as expired, so a cold launch from the game night notification can open the paywall until the network says member (offline it stays). The fix would change how `membershipResolved` is judged, which is Jack's call, so this run removed it. SM-01's fix no longer depends on it: the reminder only ends on a fresh network answer. Decision: should a cached record whose period was still running when it was fetched, read more than three days later, leave membership unresolved until the network answers (routes already wait up to 4 s for that), at the cost of a member-or-not limbo when offline? To settle the device side: sandbox member, app closed over a renewal for 4 days, launch from the game night notification.
- **Game night reminder after a billing lapse that recovers (review: product call).** With no billing grace period, a card failure makes the entitlement inactive, and the reminder is ended (live, and now also at launch, both on a fresh network answer). When payment recovers, nothing turns it back on. Decision: should a recovered member get the reminder back automatically (the app would need to remember the lapse ended it), or stay off until they turn it on again?

## Skipped

None.

## Notes

- SM-03 trade-off: the gain is now net known questions across all content, the same measure members already had. For a lapsed member, a known Mahj+ question going stale during the week now counts against the week, where before it was invisible. It can hide a small real gain; it can never invent one, which is what the claim was.

- SM-02 trade-off: a toggle read OFF because notifications were switched off in iOS Settings also cancels its request, so turning notifications back on in iOS does not bring the reminder back by itself; the player turns the toggle on again. That is the same outcome as declining the permission alert, and it rests on iOS's own answer (`denied` or `notDetermined`), never on a missing request, which is laid again instead.
- The passing full run (42358003905) tested the code as it stands: only docs changed after it.

## Test runs

Full suite, `gh-sim test --scheme MahjTrainer` (Xcode 27.1, iPhone 17, iOS 27.2):

| Run id | GitHub run | Result |
|---|---|---|
| `mahj@20261106-195146-7643-claude-mbpro0b30-1106-201400-14476` | 42337527466 | Build failed: `confirmsLapse` (nonisolated) read the main-actor `freshBaselineAge`. Fixed by making the constant `nonisolated` |
| `mahj@20261106-195146-7643-claude-mbpro0b30-1106-210011-30` | 42340832479 | Cancelled at GitHub's 1 hour job limit: hung in `TrialEligibilityTests/testFreeWeekUntilTheAccountHasUsedIt` (a StoreKitTest `purchase()`). Every test before it passed, including all regression tests above |
| `...-1106-224616-22053`, `...-1106-231442-8362`, `...-1106-235013-3025`, `...-1107-002150-6949` | 42348457508, 42350461450, 42352932733, 42355187316 | No result: the runner ran out of disk while building after restoring the mahj build cache that the timed-out run saved. The cache (`v1-jackwallner/mahj-42340832479`) was deleted; it rebuilds on its own |
| `mahj@20261106-195146-7643-claude-mbpro0b30-1107-010210-8168` | 42358003905 | **Passed: 333 passed, 0 failed, 1 skipped** (`LiveOfferingMetadataTests`, needs `TEST_RUNNER_RC_LIVE=1`), with `--skip MahjTrainerTests/TrialEligibilityTests/testFreeWeekUntilTheAccountHasUsedIt` |

On the base `48c9ca06`, run alone (`gh-sim test --only MahjTrainerTests/TrialEligibilityTests/testFreeWeekUntilTheAccountHasUsedIt`):

| Run id | GitHub run | Result |
|---|---|---|
| `mahj-base-48c9-imac0886-1107-020516-28608` | 42362444226 | **Already hangs on the base**: the test started at 10:27:51 inside its StoreKitTest `purchase()`, never finished, and the job was cancelled at GitHub's limit. The test and the StoreKit fixture are unchanged by these fixes |

No test newly fails. `TrialEligibilityTests/testFreeWeekUntilTheAccountHasUsedIt` already hung on `48c9ca06`; it is the only test left out of the passing run.
