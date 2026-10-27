---
paths:
  - "Shared/Services/FeedbackService.swift"
  - "Shared/Services/MembershipTransitions.swift"
  - "Shared/Services/MasteryLedger.swift"
  - "Shared/Services/ReviewPromptTracker.swift"
  - "MahjTrainer/Views/ReviewPromptSheet.swift"
  - "MahjTrainer/Views/StatsView.swift"
---

# Mahj: feedback, the churn question, and the week-over-week nudge (1.4)

Why 1.4 exists: the October 2026 growth review
(`project-docs/audits/growth-2026-10-11.md`) found an elite funnel (28%
download to trial, 50% trial to paid, 75% first renewal) with two leaks:
ratings (21, versus 138 for a two-month-old clone that fires Apple's star
prompt) and feedback (a mail draft nobody finished). Retention work targets
the days 4 to 5 trial-cancel window with proof the practice is working.

## The feedback sink

`FeedbackService` POSTs to a Supabase table (`app_feedback`, project
`ucoveqbyfuxqvpysmixu`, the "Sports" project, shared across the fleet). The
publishable key in the binary can only INSERT rows where `app = 'mahj'` and
`kind` is one of `general`, `not_enjoying`, `question` (retired), `churn`; it cannot
read anything. Reading needs the management API or the dashboard:
`scripts/feedback-inbox.sh` prints unread rows and marks them read.

Delivery rules: 2xx is sent, a network error, 408, 429 or 5xx queues the row
in UserDefaults (cap 20) and `flushPending()` retries on the next launch or
return to the app, any other 4xx is dropped.
Never retry a rejected row forever. A flush removes each row only after the
server answered for it (the first version cleared the queue up front and lost
every report after the first offline failure). Nothing personal is sent:
counts, ids, device model, locale. The public privacy policy describes these
fields (updated 2026-10-16); keep it in step.

## One sheet, two jobs

`ReviewPromptSheet.Step`: `.feedback` (Settings > Send Feedback) and
`.churn(ChurnMoment)`. None of them touches `ReviewPromptTracker`: ratings
come only from Apple's prompt after a positive moment, never from this sheet.
The enjoyment and review-pitch steps were removed 2026-10-12 (5.6.1 review
gating). The composer scrolls, so Send stays reachable at AX5 and with the
keyboard up.

No per-question report link (removed 2026-10-16, build 53, before 1.4.1
shipped). Jack's call: a "Something wrong with this question?" link under
every graded answer casts doubt on the right answer. Question problems come
in through Send Feedback. The `question` kind stays in `FeedbackKind` only so
rows queued on a TestFlight build still decode.

## Release experience audit, October 16, 2026

See `project-docs/audits/release-experience-2026-10-16.md`. Both build 45 and
46 have an unscrollable trial-reminder offer whose actions disappear at AX5.
Both also retain a pending cancellation question when renewal turns back on;
the fresh-baseline fix in 46 does not fix that separate sequence. These were
verified with the actual view/service using inert callbacks and isolated
preferences, not real App Store transactions. Fixed in build 51: Home now
re-reads the question after its delay and spends it only when it is shown.

## The churn question

`SubscriptionService.observe(_:)` compares each RevenueCat customer record
with the last one seen (`MembershipTransitions.churnMoment`) and stores at
most ONE `ChurnMoment` per departure (`membership.churnAskSpent`, cleared
when renewal turns back on). Home presents it once, 0.9s after it is bare
(`HomeView.homeIsBare`: Home on screen, nothing pushed, no sheet up), and
spends it only when it is actually shown; a covered Home retries when a
sheet closes or the player comes back. The first observation ever is never a
moment: a lapse nobody watched is history, not a question. A billing issue
(`billingIssueDetectedAt`) turns RevenueCat's `willRenew` off too, but Apple
is still retrying and nobody chose to leave, so `apply` counts it as
renewing.

Apple's rating prompt is never requested before onboarding finishes
(`ReviewRequest` checks `hasOnboarded`): the tour ends in a real session, and
a player who relaunched mid-onboarding is already past launch two. Mahj
Minute asks only at half right or better, like drills and the challenge.

## Weekly gain

`MasteryLedger` records known-question counts per room once a day (Home's
`onAppear` and whenever the records change; 1.4.2 watches the records
themselves, since a re-answered item changes mastery without adding a row
and a drill in the Duo's pane never brings Home back on screen). `weeklyGain()` is today
minus the oldest day inside the 7-day window, positive only; nil on day one
and on a backwards week. It drives the plum "+N" chip on Home and the "Up N this
week" card on Your Progress. NOT the reminders: 1.4.0 baked the count into
the repeating daily and game-night notifications, which then repeated a
stale number every day to players who stopped opening the app. 1.4.1 went
back to generic repeating copy (dated one-offs with fresh copy were tried and
rejected: they run out, so a reminder the player turned on silently stops).
`AppSettings.replaceCountedReminders` rewrites a 1.4.0 install's counted
reminders once, keyed on the legacy `settings.reminderWeeklyGain`.

## Trial-end reminder

Removed in build 47 (2026-10-16): the offer screen after a trial purchase
changed the frozen trial flow (`membership-and-trial.md`). The scheduling
and cancel code in `AppSettings` stays so a reminder a TestFlight install
already scheduled is still cancelled when the trial converts or stops
renewing. Bringing it back is a RevenueCat Experiment behind offering
metadata, measured on trial conversion, and only with Jack's go-ahead.

## Game night card

Home shows "When's your game night?" to members with no reminder set, until
they set one or dismiss it (`mahj.gameNightCardDismissed`). Free players never
see it; the prep is a member surface.
