---
paths:
  - "Shared/Services/FeedbackService.swift"
  - "Shared/Services/MembershipTransitions.swift"
  - "Shared/Services/MasteryLedger.swift"
  - "Shared/Services/ReviewPromptTracker.swift"
  - "MahjTrainer/Views/ReviewPromptSheet.swift"
  - "MahjTrainer/Views/TrialReminderOfferView.swift"
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
`kind` is one of `general`, `not_enjoying`, `question`, `churn`; it cannot
read anything. Reading needs the management API or the dashboard:
`scripts/feedback-inbox.sh` prints unread rows and marks them read.

Delivery rules: 2xx is sent, a network error queues the row in UserDefaults
(cap 20) and `flushPending()` retries on the next launch, a 4xx is dropped.
Never retry a rejected row forever. A flush removes each row only after the
server answered for it (the first version cleared the queue up front and lost
every report after the first offline failure). Nothing personal is sent:
counts, ids, the question as shown (prompt, tiles, choices, answer, pick,
coaching), device model, locale. Generated questions have random ids, so the
report must carry the choices or it cannot be investigated. The public privacy
policy describes these fields (updated 2026-10-12); keep it in step.

## One sheet, three jobs

`ReviewPromptSheet.Step`: `.feedback` (Settings > Send Feedback),
`.question(QuestionReport)` and `.churn(ChurnMoment)`. None of them touches
`ReviewPromptTracker`: ratings come only from Apple's prompt after a positive
moment, never from this sheet. The enjoyment and review-pitch steps were
removed 2026-10-12 (5.6.1 review gating). The composer scrolls, so Send stays
reachable at AX5 and with the keyboard up.

`QuestionPager(reportID:)` adds the "Something wrong with this question?"
link under the coaching note. Every pager-based drill passes its item id and
its choices (`reportChoices`, `reportAnswerIndex`, `reportPickedIndex`).
Flashcards and the Charleston drill do not have it (yet).

## The churn question

`SubscriptionService.observe(_:)` compares each RevenueCat customer record
with the last one seen (`MembershipTransitions.churnMoment`) and stores at
most ONE `ChurnMoment` per departure (`membership.churnAskSpent`, cleared
when renewal turns back on). Home presents it once, 0.9s after it draws,
never on top of What's New or the paywall. The first observation ever is
never a moment: a lapse nobody watched is history, not a question.

## Weekly gain

`MasteryLedger` records known-question counts per room once a day (Home's
`onAppear` and whenever the record count changes). `weeklyGain()` is today
minus the oldest day inside the 7-day window, positive only; nil on day one
and on a backwards week. It drives the plum "+N" chip on Home, the "Up N this
week" card on Your Progress, and the reminder bodies
(`AppSettings.refreshReminderCopy`). Local notifications are static text, so
the bodies are rewritten on every launch with the latest number.

## Trial-end reminder

`TrialReminderOfferView` appears right after an onboarding trial purchase and
before the tour. Accepting requests notification permission THEN schedules
one notification two days before the week ends
(`AppSettings.scheduleTrialEndReminder`). Never schedule it silently; the
whole point is that the player chose it. `PaywallView` offers the same view
when a purchase on the sheet starts a real trial (most later trials start
there), keyed on `purchasing` so a restore never triggers it. A declined
system prompt here does NOT set `reminderPermissionDenied`: that shared flag
drives Settings' "Notifications are off" alert, which then fired unexplained
on the player's first Settings visit.

## Game night card

Home shows "When's your game night?" to members with no reminder set, until
they set one or dismiss it (`mahj.gameNightCardDismissed`). Free players never
see it; the prep is a member surface.
