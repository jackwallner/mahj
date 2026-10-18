---
paths:
  - "Shared/Content/MonthlyChallengeContent.swift"
  - "Shared/Services/MonthlyChallengeStore.swift"
  - "MahjTrainer/Views/MonthlyChallengeView.swift"
  - "MahjTrainer/AppRouter.swift"
  - "MahjTrainerTests/MonthlyChallengeTests.swift"
---

# Mahj: the monthly challenge and its App Store events

**Why it exists (1.4.0, 2026-10-12):** App Store in-app events need genuinely
new, time-boxed content (Football's evergreen "season" event was rejected
under 2.3.13). A challenge that changes every calendar month is a new event
and a new featuring nomination every month on the fleet's highest-impression
app.

**Daily rounds (1.4.1, rebuilt 2026-10-18):** a 12-question month took four
minutes and then sat on Home for 30 days, so the month is now made of daily
rounds. Jack's calls: three questions a day, the same for every player; the
month score is the best 20 days (max 60, `countedDays`), so missing days is
forgiven. The first month is October 2026 (`firstMonth`): Jack moved it
up from November so App Review, and players who get the release in
October, have rounds to play before November's event; October takes
Reading Your Rack from the rotation.

- `MonthlyChallenge.round(day:)` builds a `ChallengeRound` (key
  "YYYY-MM-DD"): [themed generated, other skill (the two alternate by day),
  themed harder]. Every third day the closer is hand-written, taken in
  order from `authoredSequence` (10 per month, no repeats). Hand-written
  pool: three-tile Charleston passes; four-choice defense reads
  (`defenseQuestions`) plus one judgment call; hand-match racks from the
  sections the generator cannot deal (Like Numbers, Year, Quints, Singles &
  Pairs). Charleston months mix in `CharlestonGenerator.twoSinglesBatch`;
  defense months swap in the run-trap tile (`DefenseGenerator.withRunBait`).
  Both are iOS-only. Themes rotate Charleston, Safe Discards, Reading Your
  Rack from November 2026 (`rotationAnchor`).
- Content reviews: two passes by a teacher persona and one by a new player
  (2026-10-12) drove the generator fixes (strays that change the read,
  6+ of a number, odds of only 3s and 9s), rack-aware miss notes, run
  reads in defense copy and the plain-language names. Dump any month with
  `TEST_RUNNER_CHALLENGE_DUMP=<path>` on `MonthlyChallengeDumpTests`.
- Free for everyone. `AppDestination.isFree` lets `mahj://challenge` through
  the Home paywall guard. The result screen shows one Mahj+ pointer to free
  players on days 1, 6, 11... played; no lock anywhere in the flow.
- Home: the card appears only after a first finished practice
  (`progress.totalSessions > 0`), so a brand-new player's Home is the 1.3.2
  lobby; the event link still opens the challenge for them. The card shows
  while today's round is unplayed; once played the challenge collapses to a
  plum points chip in the stats row (`ViewThatFits` stacks the chips at
  large text). Before the first month the link shows the start date with
  the reminder button (only reachable on a pre-October clock now).
- `MonthlyChallengeStore` keeps the FIRST run per round, saved after every
  answer (`recordAnswer`); leaving resumes at the same question and the last
  answer finishes it. A half-played round from an earlier day is closed on
  open (`closeEarlierRounds`), scored on what was answered. Legacy month
  keys (`monthlyChallenge.results`/`.progress`) are deleted on init: only
  test builds ever wrote them.
- Standing: `ChallengeStandingService` posts the month score to Supabase
  RPC `challenge_submit` (migration `20261018120000_challenge_scores.sql`,
  project `ucoveqbyfuxqvpysmixu`) with a random per-month token
  (`scoreToken`) and the feedback publishable key. The function keeps the
  best score per token, checks the score is possible (`points <= 3 *
  least(days, 20)`), accepts only the month running somewhere on Earth, and
  answers `{players, below}`. The table is unreadable to anon. The app shows
  "Top N%" only in the top half. Jack (2026-10-18): always show a rank, no
  player count, so every month is padded with 50 baseline players
  (`challenge_baseline`, migration `20261018180000_challenge_baseline.sql`),
  rebuilt from the clock on each call and never stored: each plays a fixed
  share of the days so far at a fixed accuracy. A 3/3 on the 1st reads about
  Top 29%, a near-perfect daily player about Top 2%. The client floor
  (`ChallengeStanding.minimumPlayers`, 10) only guards an empty reply. Never on a simulator; captures pin
  one with DEBUG `-mahj.standing players,below`. Declared in App Privacy as
  Gameplay Content, not linked, App Functionality, and in the privacy
  policy.
- `MonthlyChallengeReminder`: opt-in, one notification on the 1st of each
  of the next three months, re-laid on launch. The button checks the real
  notification permission on appear and says notifications are off rather
  than show "Reminder On" for nothing.
- The hero reads the date once per render, so a Resume tapped after
  midnight finishes the round its saved answers belong to.
- The closers can be Mahj+ questions. A free player who misses one never gets
  "This one will come back" (`SessionBuilder.isMemberOnly`): free sessions
  never bring Mahj+ questions back.
- The What's New line is `isAppleOnly`, so the Android export skips it.
- Month names are forced to English (`en_US_POSIX`): a bare `Calendar`
  answers "M11", and the app's copy is English.
- Identity is Gregorian in the device's time zone (`Calendar.gregorianLocal`),
  never `Calendar.current`: a Buddhist or Hebrew system calendar gave a
  different month key, different questions and a 46,000-month archive. Mahj
  Minute day keys and the local day keys use it too.
- Saved runs carry `QuickItem.challengeFingerprint` per answer. The answer
  review and skill breakdown are only shown while the fingerprints still
  match the month's rebuilt questions; an update that changes a month keeps
  the score but drops the review instead of re-labelling old answers.
  Results without fingerprints (pre build 43) are score-only.
- The last answer banks the run AND the session/streak credit
  (`QuickSessionView.grade`); crediting on the result screen lost both when
  the app closed before Finish.
- DEBUG `-ChallengeMonth 2026-11` pins the 2nd of that month at noon,
  `-ChallengeMonth 2026-11-30` a given day, for captures and UI tests.

**Each month's App Store work:** an in-app event (badge CHALLENGE, deep link
`mahj://challenge`, publish up to 14 days early, max 31 days) via
`~/football/scripts/asc-app-event.py`, and a NEW_CONTENT featuring nomination
via `POST /v1/nominations` at least two weeks ahead.

**State, 2026-10-13:** 1.4.0 (build 45) and the November event `6822009957`
(CHALLENGE, Nov 1 to Dec 1, publishes from Oct 18) were submitted together
(reviewSubmission `38d9d9ef-7167-429a-b856-43f26e373db3`, WAITING_FOR_REVIEW).
The version was set to `AFTER_APPROVAL`, but on 2026-10-15 it read
`MANUAL`: release 1.4.0 by hand before the event publishes, because 1.3.2
(live since 2026-10-13) cannot open `mahj://challenge`. Featuring
nomination `952638cd-10d2-4571-b10f-aa1ca0b1e427` (NEW_CONTENT, publish
Nov 1) is SUBMITTED. Nominations API: create with `submitted: false`, then
PATCH `submitted: true` (creating already-submitted returned 500), and a
DRAFT event cannot be linked through `inAppEvents` (400).

**2026-10-14:** App Review rejected 1.4.0 under 2.3.4 (the App Preview
showed a device frame; the event was not reviewed). The framed preview was
replaced with a real screen recording (challenge, answered question,
Charleston pass) built with `~/ios/app-previews/record_walkthrough.py` and
`compose_captioned.py`; source and edit in
`~/ios/app-previews/output/mahj-trainer-mahjong-practice/clean-2026-10-14/`.
Resubmitting needs the version page's "Update Review" first: until then the
reviewSubmission PATCH `submitted: true` returns 409 "Version is not ready
to be submitted yet". Same submission, WAITING_FOR_REVIEW again. Never put a
device frame in a preview; any framed video left in a PPO treatment gets the
same rejection.

**2026-10-15:** 1.4.0 was accepted but the November event was rejected under
2.3.7: "free" in its short and long descriptions counts as a price
reference. Event copy (name, short and long description, card and details
art) never mentions price, "free", trials or discounts; say what the
challenge is instead. The copy was rewritten without "free" and the same
submission resubmitted by API: PATCH the rejected `reviewSubmissionItems`
`resolved: true` (state READY_FOR_REVIEW), then the reviewSubmission
`submitted: true` (WAITING_FOR_REVIEW). An accepted version in a submission
with a rejected item is held until that item is accepted or removed.

**Submit the version and the event SEPARATELY (2026-10-17).** In one
submission an accepted version is held until every item is accepted, and
Apple has passed a version while leaving the event unreviewed. 1.4.1 (build
53) went in as reviewSubmission `6285fdb7-6fda-4c59-840f-8e8fc41a0975`
(version only, MANUAL release) and the November event as `9563ec21-be0a-4ed7-bb06-8a0c26b7ebd3`
(event only); Apple allows one extra submission beside a version in review.
The version submission was then cancelled to add the off switch below and
resubmitted with build 54 (reviewSubmission `1bac690f-ea0e-46db-b2b8-4353a4c7c1fb`, version only, MANUAL, 2026-10-18); the event submission was left in review. Adding the version through `asc review items-add` returned 500 twice; `~/ios/release/release.py submit --apply` reused the same empty submission and went through.
An item already submitted cannot be removed (`items-remove` answers "Item was
already submitted"): cancel the whole submission (`asc review
submissions-cancel`), wait for COMPLETE, then create the two. The event's
link works from 1.4.0 on, so it never needs the new version.

**Remote off switch (1.4.1, build 54):** offering metadata `monthly_challenge: off`
hides the Home card and drops `mahj://challenge` (event and reminder taps
just open Home). Saved runs stay. Set it on every offering, like the other
switches. Players reach a month's questions only from the 1st of that month
in their own time zone. The What's New line for the challenge
(`WhatsNew.monthlyChallengeItemID`) and the monthly reminder follow the same
switch. `MahjTrainerScreenshots/ChallengeSwitchTests.swift` checks off, on and
unset on a real build through `-mahj.rc.monthly_challenge`.

**2026-10-18: pulled for daily rounds.** Both submissions were cancelled
(1.4.1 version `663a9ff6` is DEVELOPER_REJECTED; event submission
`9563ec21` cancelled) to ship the daily-round format, the standing and the
Home gate in the same 1.4.1. The version stays 1.4.1 because Apple approved
1.4.0 and takes no more builds under it; players never saw either. The event
copy must be rewritten for daily rounds before it goes back in.
