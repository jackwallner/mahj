# Fixes for the state machine audit, 2026-11-06

Fixes for the claims [the review](state-machines-2026-11-06-review.md) kept from [the audit](state-machines-2026-11-06.md), in the review's ranked order, on branch `fleet/20261106-165014-9e99-claude`. No verify file existed, so this is the first round.

**Summary: 4 in scope (SM-01 CONFIRMED, SM-03 and SM-02 CONFIRMED-MINOR, SM-R1 the review's UNVERIFIED "other direction", now settled). 4 fixed, 0 skipped, 1 held for Jack (a product call the review left open). Out of scope: SM-04, SM-05, SM-06 (NOT A BUG).**

## Claims

| Id | Outcome | Commit | Regression test | What changed |
|---|---|---|---|---|
| SM-01 | Fixed | `77aaa463` | `MemberReminderTests.testAKnownNonMemberLosesTheGameNightReminder`, `testAnUnknownMembershipKeepsTheReminder`, `testAMemberKeepsTheReminder` | Home ends the game night reminder whenever the customer record says non-member (`AppSettings.endMemberReminders`, run on appear, on `membershipResolved` and on `isPro`), not only on a live true to false change. A lapse while the app was closed (the cold-start false to false case) now turns it off. Writes only on a change (iOS 18 publish rule). |
| SM-R1 | Fixed (settled first) | `77aaa463` | `MemberReminderTests.testAStaleRecordOfARunningPeriodSettlesNothing`, `testARecordThatSawTheLapseSettlesIt`, `testActiveAndNeverSubscribedRecordsSettleIt` | Settled by reading RevenueCat 5.72 `CustomerInfo+ActiveDates.swift` (`requestDateGracePeriod = .days(3)`, `isDateActive`) and `Purchases.swift` (`delegate` didSet calls `sendCachedCustomerInfoToDelegateIfExists`): a cached record more than 3 days old judges a renewed period against now and reads it as expired, through both `cachedCustomerInfo` and the delegate. So a member who renewed while away read as a resolved non-member, and a cold launch from the game night notification opened the paywall (offline it stayed). `SubscriptionService.apply` now ignores a record whose entitlement reads inactive but expires after the record's own request date: it cannot tell a lapse from a renewal, so membership stays unresolved and the network record decides. Routes already wait 4 s for that. This is also what keeps the SM-01 fix from ending a renewed member's reminder. |
| SM-03 | Fixed | `0171f16f` | `MasteryLedgerTests.testRejoiningIsNotAWeeklyGain`, `testRealAnswersStillCount`; upgrade: `testOlderDaysStayTheBaselineWhenTheyCountTheSame`, `testOlderDaysThatCountedLessAreNotTheBaseline` | `MasteryLedger.record(from:)` writes every known question, open to the player or not, so joining or leaving Mahj+ moves no total. Home calls it in place of the membership-filtered count (the `membershipResolved` guard and the two membership `onChange` re-records went with the dependency). Upgrade: older days stay on disk and stay the baseline when they count the same either way (no Mahj+ question known at the upgrade, so every free player and every member who never touched Mahj+ content keeps their week). Otherwise the baseline starts at the upgrade day (`mastery.ledger.allAccessSince`), so a lapsed member's free-only days cannot fake a gain. Rules note updated in `.claude/rules/mastery-coaching-whats-new.md`. |
| SM-02 | Fixed | `30f90109` | `ReminderReconcileTests.testNotificationsSwitchedOffReadOff`, `testNeverAllowedOnThisPhoneReadsOff`, `testAllowedAndScheduledStaysOn`, `testTogglesThatAreOffStayOff`, and the review's own check `testRestoredOnFlagWithNoPendingRequestIsReconciled` (real notification center) | `AppSettings.reconcileReminders()` runs at launch and on every `.active`: when iOS will not deliver (denied, or not determined as on a restored phone) the daily and game night toggles read OFF and their requests are removed; when allowed and the request is missing it is laid again. It skips while a permission alert the player just triggered is open, so turning a toggle on is never undone mid-prompt. Settings and Game Night Prep ("Prep is scheduled") now show the real state. Rules note in `.claude/rules/rituals-and-hand-play.md`. |

The audit's repro suite was not added to the test target: its SM-03 test is carried over as `testRejoiningIsNotAWeeklyGain` (the review called it sound), and its SM-04 and SM-05 tests assert behaviour the review found NOT A BUG.

## Held for Jack

- **Game night reminder after a billing lapse that recovers.** With no billing grace period, a card failure makes the entitlement inactive, and the reminder is turned off (live, and now also at launch). When the member's payment recovers, nothing turns it back on. The review called this a product call. Decision: should a recovered member get their game night reminder back automatically (it would need the app to remember it was ended by a lapse), or stay off until they turn it on again?

## Skipped

None.

## Fail without the fix

RESULTS_STUB

## Test runs

RESULTS_RUNS
