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

- `MonthlyChallengeContent.challenge(for:)`: twelve questions per month, the
  same on every device. Six on the month's theme, two of each other generated
  skill, plus two authored (Charleston three-tile passes in a Charleston
  month, table judgments otherwise). Themes rotate Charleston, Defense, Read
  the Rack from November 2026 (`rotationAnchor`); October 2026 is the first
  month offered (`firstMonth`). Tile counting is left out because its
  generator is not seeded.
- Free for everyone. `AppDestination.isFree` lets `mahj://challenge` through
  the Home paywall guard. The result screen shows one Mahj+ pointer to free
  players; no lock anywhere in the flow.
- `MonthlyChallengeStore` keeps the FIRST finished run per month. Same
  questions for everyone, so a replay would be a memory test, and a shared
  score has to mean one attempt.
- Month names are forced to English (`en_US_POSIX`): a bare `Calendar`
  answers "M11", and the app's copy is English.
- DEBUG `-ChallengeMonth 2026-11` renders a coming month for store art.

**Each month's App Store work:** an in-app event (badge CHALLENGE, deep link
`mahj://challenge`, publish up to 14 days early, max 31 days) via
`~/football/scripts/asc-app-event.py`, and a NEW_CONTENT featuring nomination
via `POST /v1/nominations` at least two weeks ahead.

**State, 2026-10-12:** the challenge ships in 1.4.0 (build 41 on
TestFlight). November event `6822009957` (CHALLENGE, Nov 1 to Dec 1,
publishes from Oct 18) is a DRAFT with media; submit it in the same review
submission as 1.4.0, which needs 1.3.2 out of review first. Featuring
nomination `952638cd-10d2-4571-b10f-aa1ca0b1e427` (NEW_CONTENT, publish
Nov 1) is SUBMITTED. Nominations API: create with `submitted: false`, then
PATCH `submitted: true` (creating already-submitted returned 500), and a
DRAFT event cannot be linked through `inAppEvents` (400).
