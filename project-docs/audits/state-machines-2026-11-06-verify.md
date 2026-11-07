VERDICT: PASS

# Verify: state machine audit fixes, 2026-11-06

Independent check of [the fixes](state-machines-2026-11-06-fixes.md) for [the review](state-machines-2026-11-06-review.md)'s three kept claims, over `git diff 48c9ca065dafc22ac0c051181f5991cc6d829399..HEAD` (HEAD `b8e37e6a`). No app code or test was changed. Every claim in the fixes doc was re-read against the code.

**Summary:** all three fixes hold on the review's routes in the shipping code. No regression found, no test newly fails, nothing in check 4 is breached. The full suite passed on HEAD (333 passed, 0 failed, 1 skipped). With the fixes reverted and their tests kept, the SM-01 and SM-02 tests fail as they should. SM-03's headline test does not fail: it passes without the fix, so the behaviour it names is not what it checks (see "Should change"). SM-01's tests check only the fix's own helpers, so the launch route needs a device check.

## Fixes

| Id | Works | Regression check | Evidence |
|---|---|---|---|
| SM-01 | Yes (route by code; device check below) | Clean | Route: lapsed member, app closed over 3 days, cold launch. `start()` applies the cached record (`SubscriptionService.swift:290`): it is old, so `confirmsLapse` is false (`:689-690`). `refreshCustomerInfo` then uses `.cachedOrFetched` (`:473`), and RevenueCat's background cache is stale by then, so the record comes from the network with a current `requestDate`, and `apply` sets `lapseConfirmed` (`:668`). Home reacts on `onChange(of: lapseConfirmed)` (`HomeView.swift:317`) and on appear (`:250`), calling `AppSettings.endMemberReminders` (`AppSettings.swift:351`). Setting the flag false fires `didSet` and `cancelGameNightReminder`, so the request is removed. The base needed a live `isPro` true to false change, which never happens on this route. Neighbours: the live teardown (`HomeView.swift:326`) still runs after a network lapse in a session, because `apply` sets `isPro` and `lapseConfirmed` in one synchronous pass. Purchase, restore and delegate updates call `apply` with fresh records (`:622`, `:654`, `:734`), so a rejoin clears `lapseConfirmed`. `isPro` and `membershipResolved` are judged exactly as on the base (diff touches neither). The simulator never configures RevenueCat, so `lapseConfirmed` stays false there. Writes only on a change (`:668`, `AppSettings.swift:352`), which meets Home's iOS 18 no-publish rule. A renewed member read lapsed from an old cache (SM-R1) is not torn down, because that record is not fresh |
| SM-02 | Yes | Clean | Route: Daily Reminder on, notifications switched off in iOS Settings, back to the app. `.active` runs `reconcileReminders()` (`MahjTrainerApp.swift:41`; launch at `:74`), which reads iOS's status and pending ids (`AppSettings.swift:238-245`). `.denied` or `.notDetermined` turns the toggle OFF (`:258-271`), and its `didSet` cancels the request, so Settings and Game Night Prep (`GameNightPrepView.swift:78`) show the real state. An allowed toggle whose request is missing is laid again, not cleared (`:262`, `:269`): a missing request alone never clears a setting. The permission alert sends the app inactive and back to active. `permissionRequestsInFlight` (`:278`, `:315`) is raised before the alert and checked after the awaits (`:257`), so a toggle just turned on is never undone mid-prompt. Seen on screen: Settings launched with `-settings.reminderEnabled YES` on a simulator that never granted notifications shows Daily Reminder OFF (launch run below). Neighbour: a member whose game night toggle is reconciled OFF sees Home's "When's your game night?" card again (`HomeView.swift:386-388`) unless they dismissed it. That is truthful, and the card opens Game Night Prep, which has the "Notifications are off" alert. `MonthlyChallengeReminder.swift:20` asks for permission without the counter, but it never touches these toggles, and the next `.active` reconciles with the answer |
| SM-03 | Yes | Clean (one upgrade trade-off, disclosed, in notes) | Route: a member who knows Mahj+ questions lapses, opens Home on free days, then rejoins within 7 days. Home's only ledger writer is now `ledger.record(from: records)` (`HomeView.swift:401`; grep finds no other caller of `record`). `record(from:)` always counts with `isMember: true` (`MasteryLedger.swift:41-52`), so a membership change cannot move a day's total, and the gain chip (`HomeView.swift:683`) and Your Progress (`StatsView.swift:26`) cannot count a rejoin as learning. Removing the `membershipResolved` guard and the two membership re-records is safe for the same reason: the count no longer depends on membership. Upgrade: the stored `mastery.ledger` format is unchanged and no day is dropped. The new `mastery.ledger.allAccessSince` floor (`:45-50`, `:102`) only narrows which older day may be the baseline. `resetAll` clears it (`:88-93`), and Settings > Reset calls it. Day keys stay Gregorian local (`dayKey`), as before |

## Disputed

The fixes doc has no "Disputed" section and lists nothing as disputed. Nothing to rule on.

## Scope (check 4)

- Only the three listed claims changed, plus their rules notes and the fixes doc. No trial, onboarding, paywall, price, offer or membership judgement changed (`isPro` and `membershipResolved` assignments are untouched in `apply`). No backend, App Store Connect or RevenueCat change.
- Teardown only on a fresh network "not a member": the game night reminder ends only on `lapseConfirmed`, a non-member record answered within 300 s. A cached record never ends it. SM-02 clears a toggle only on iOS's own authorization answer (`denied`, `notDetermined`), never on a missing request or a failed call.
- No stored format change. One new key (`mastery.ledger.allAccessSince`), no data reset.
- Held items unchanged: SM-R1 (membership judgement) is untouched. The billing-recovery question (turn the reminder back on) is untouched. The reminder still ends on a billing lapse, as the base's live teardown already did; it now also ends at launch.
- All three in-scope claims are in the fixes table, all fixed, none skipped. No fix rests on an UNVERIFIED claim. SM-02's restore half was app-side only in the review, but `testRestoredOnFlagWithNoPendingRequestIsReconciled` fails without the fix (run below).

## Should change (does not fail the check)

1. **`MasteryLedgerTests.testRejoiningIsNotAWeeklyGain` does not test a rejoin.** It calls `record(from:)` three times with no membership change, so it passes with the fix reverted (run 42374236133, base behaviour behind the same API). The fixes doc calls it "the audit's repro, which the review called sound". It is not: the audit's repro changed membership between days. The fix's membership independence is pinned only by `testRealAnswersStillCount`, which does fail without the fix ("nil" is not equal to "2": a non-member's known Mahj+ questions were dropped). Suggest a test that writes a free-only older day the way the base did, then calls `record(from:)`, and asserts no gain. `testOlderDaysThatCountedLessAreNotTheBaseline` also passes without the fix (base behaviour gives nil either way), so the upgrade floor is pinned only by its own logic.
2. **SM-01's tests check the fix's helpers, not the route.** `testAConfirmedLapseEndsTheGameNightReminder` calls `endMemberReminders(lapseConfirmed: true)` directly. `confirmsLapse` is a pure function. Nothing tests that Home calls them, or that `apply` publishes `lapseConfirmed` from a network record. Device checks left open:
   - Sandbox member with the game night reminder on: let the subscription lapse with the app closed for more than 3 days, then launch. After the network answers, `pendingNotificationRequests()` has no `mahj.gameNightReminder`, and the toggle reads off when the player rejoins.
   - Sandbox member, app closed over a renewal for 4 days, then launch: the reminder survives.
   - Same as the first, launched offline: the reminder survives until the network answers.
3. SM-02 device check: Daily Reminder on, iOS Settings > Notifications off, return to the app. The toggle reads OFF and Game Night Prep reads "Choose your game night". Restore half: back up and restore to another phone with the toggle on, then launch. The toggle reads OFF.

## Test results

All on GitHub's Macs via `gh-sim` (Xcode 27.1, iPhone 17, iOS 27.2).

| Run id | GitHub run | What | Result |
|---|---|---|---|
| `mahj@20261107-032530-6bbb-claude-imacbc8b-1107-032611-14226` | 42368172289 | Full suite, HEAD | No result (infrastructure): the runner hit "No space left on device" during cache restore, before the build. Rerun below |
| `mahj-scratch-revert-imacbc8b-1107-034917-25567` | 42369787298 | Scratch revert | No result (infrastructure): same disk error after restoring the mahj build cache `v1-jackwallner/mahj-42362444226`, saved by the fixes doc's timed-out base run. That cache was deleted, as the fixes doc did for the previous one; it rebuilds on its own |
| `mahj@20261107-032530-6bbb-claude-imacbc8b-1107-040638-31878` | 42371020112 | Full suite, HEAD, `--skip MahjTrainerTests/TrialEligibilityTests/testFreeWeekUntilTheAccountHasUsedIt` | **Passed: 333 passed, 0 failed, 1 skipped** (`LiveOfferingMetadataTests`, needs `TEST_RUNNER_RC_LIVE=1`). Matches the fixes doc's run 42358003905 exactly. All 20 tests in `MemberReminderTests`, `ReminderReconcileTests` and `MasteryLedgerTests` passed, which includes every test this change added or edited |
| `mahj-scratch-revert-imacbc8b-1107-045016-15083` | 42374236133 | Fixes reverted, tests kept, six tests in one `--only` run | 4 failed, 2 passed, as predicted (table below) |
| `mahj@20261107-032530-6bbb-claude-imacbc8b-1107-043330-9859` | 42373025517 | `gh-sim launch`, HEAD, member override, demo seed: Home, Settings, Your Progress | Success, screenshots read (notes) |

The left-out `TrialEligibilityTests/testFreeWeekUntilTheAccountHasUsedIt` was not rerun. It already hangs on `48c9ca06` (fixes doc, run 42362444226), and this diff changes neither the test nor any `.storekit` fixture (`git diff --stat` on both is empty). It is pre-existing, not a regression.

### Fail without the fix (run 42374236133)

The scratch branch was a throwaway worktree on `scratch-revert`, made from HEAD. It used the worktree instead of `git switch` because gh-sim waits for this session's previous run before it snapshots the tree. `HomeView.swift`, `MahjTrainerApp.swift`, `AppSettings.swift`, `MasteryLedger.swift` and `SubscriptionService.swift` were checked out from `48c9ca06`. The new tests were kept, plus the smallest stubs that let them compile with the base behaviour: `reconcileReminders` does nothing, `endMemberReminders` does nothing (the base had no launch teardown), `confirmsLapse` returns `!isMember` (the base tore down on any non-member record), and `record(from:)` records `masteryByRoom(isMember: SubscriptionService.shared.isPro)` (what base Home wrote). The worktree was removed and `scratch-revert` deleted afterwards. This branch ends with only the doc commit on top of `b8e37e6a`.

| Fix | Test | Without the fix | Proves |
|---|---|---|---|
| SM-01 | `MemberReminderTests/testAConfirmedLapseEndsTheGameNightReminder` | FAIL (`XCTAssertFalse`) | Only that the helper works. It fails because the helper is stubbed: a hook test |
| SM-01 | `MemberReminderTests/testAnOldCachedNonMemberRecordConfirmsNothing` | FAIL (`XCTAssertFalse`) | A cached record no longer counts as a lapse (the base's rule would have) |
| SM-03 | `MasteryLedgerTests/testRejoiningIsNotAWeeklyGain` | PASS | Nothing: no membership change in the test |
| SM-03 | `MasteryLedgerTests/testRealAnswersStillCount` | FAIL (`nil` vs `2`) | Known Mahj+ questions count for a non-member, which is the membership independence the fix rests on |
| SM-03 | `MasteryLedgerTests/testOlderDaysThatCountedLessAreNotTheBaseline` | PASS | Nothing on its own (base behaviour also reads nil) |
| SM-02 | `ReminderReconcileTests/testRestoredOnFlagWithNoPendingRequestIsReconciled` | FAIL ("Toggle reads ON but no daily reminder request exists") | The review's failing check, against the real notification center |

## Notes

- Screens (run 42373025517). Home (member override, demo seed): renders as before, with the game night card shown because the reminder is off. No "+N this week" chip, because a fresh simulator install has only today's ledger entry and so no baseline, the same as on the base. The gain chip could not be reached on the simulator, so the SM-03 chip itself was not seen. Settings launched with `-settings.reminderEnabled YES`: Daily Reminder reads OFF, because the simulator never granted notifications and reconcile turned it off. On the base it would read ON with no request. Your Progress renders unchanged (no week card, same reason). No layout code changed, so iPhone Duo layouts are unaffected. `endMemberReminders` and `recordMastery` are idempotent, so a second Home appear in a split changes nothing.
- SM-03 upgrade trade-off (disclosed in the fixes doc and the rules note): an active member who knows any Mahj+ question gets the floor set to the upgrade day, though their older days were written as member counts and were valid baselines. Their weekly chip is hidden on upgrade day, then counts from the upgrade day for up to 6 days. It never invents a gain and drops no data. A lapsed member's free-only days and an active member's days look the same on disk, so a membership-free check cannot tell them apart. Jack could accept it as is.
- `confirmsLapse` uses `now - requestDate <= 300` with no lower bound. A device clock set well behind server time would read an old cached non-member record as fresh. That needs a hand-set clock and a cached non-member record. The churn baseline check (`SubscriptionService.swift:710`) has the same shape. Not a fault of this change. An `abs` would close it.
- No widget or watch target exists (`project.yml`). No new user-facing string, so no catalog change. The Android port is untouched by the diff, and its own game night teardown is out of scope here.
- Another session reused the path `/tmp/verify-sm/full.log` during this check. The ids above come from each run's own id file and GitHub, not from that log.
