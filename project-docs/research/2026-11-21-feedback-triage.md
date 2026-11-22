# In-app feedback triage, 2026-11-21

Every row in `app_feedback` as of 2026-11-21 (33 rows, read without marking
any read): Mahj 28 (26 churn answers, 2 Send Feedback messages), Skat 3
(1 churn, 2 messages), Bridge 2 (1 churn, 1 message). Cribbage and
Sheepshead have none.

## The bug: feedback arriving as one word

Three Send Feedback messages are the opening of a sentence and nothing else:
"I'm" (Mahj 1.4.1, Oct 19), "The first" (Skat 1.3.1, Oct 31) and "The"
(Skat 1.3.3, Nov 20).

**Cause.** The Send button. It was a big button at the bottom of the
sheet, just above the keyboard, disabled until the box had text. With an
empty box the keyboard's suggestion bar offers exactly "I", "The" and "I'm",
the three words we received. A player taps a suggestion, Send lights up, and
the next reach for the suggestion bar lands on Send. Measured on an iPhone 17
Pro simulator after typing "I'm": Send ended about 50 points above the
suggestion bar at the default text size, and at Accessibility Medium it
touched the bar. Return cannot send (it is a
`TextEditor`, so Return inserts a new line).

**Ruled out first.** Dictation or a composing keyboard holding unfinished
words as marked text that the SwiftUI binding misses: a hosted test showed
the binding does include marked text on iOS 27, so that theory was dropped.

**Fix.** Send moved to the navigation bar's top right (as in Mail), with
"Not now" at the top left, nowhere near the keyboard. Same sheet, same
copy, same disabled-until-there-is-something rule. Shipped in Mahj and all
four card trainers, since they share the sheet. Each app has
`FeedbackSheetLayoutUITests`: it types a word and checks there is one Send,
in the navigation bar, at least 200 points above the keyboard, at the
default size and at Accessibility Medium. In Mahj it lives in the
`MahjTrainerScreenshots` target (Screenshots scheme), because the MahjTrainer
scheme runs unit tests only.

## Churn answers (28 across apps)

| Reason | Mahj | Skat | Bridge | Action |
|---|---|---|---|---|
| Too expensive, or "I don't want to pay" | 14 | 1 | 0 | Out of scope: prices and the trial flow are frozen without Jack's go-ahead. |
| Didn't use it enough | 3 | 0 | 1 | None new. Reminders and the Mahj Minute already exist. |
| More content, too repetitive, "little beyond a set" | 4 | 0 | 0 | Covered by the opportunity proposal (see below). |
| Level fit: not challenging, too advanced, too beginner | 3 | 0 | 0 | Covered by the proposal's Master Tables set and the teacher review's basic, intermediate and challenging tiers for Quick Session. |
| Got what I needed | 1 | 0 | 0 | None. |
| "Something else", no words | 1 | 0 | 0 | None. |

The level-fit and content rows overlap: the Nov 15 iPad answer is both
"too beginner" and "didn't simulate a real game".

## Rows already decided (waiting on the proposal)

`project-docs/research/2026-11-20-opportunity-proposal.md` covers these, so
nothing was built for them here.

- **"Which line?" drill:** Mahj, Nov 15 Send Feedback message (beginner
  asking Play a Hand to name the line, or the line number, it is steering
  toward).
- **Table mode:** Mahj, Nov 15 churn "[Something was missing] Was too
  beginner for me. Didn't simulate a real game enough."
- **Too repetitive / more content:** Mahj churn Nov 4 and Nov 11 ("Wanted
  more content"), Nov 13 ("Too Repetitive") and the long Nov 11 answer ("once
  you work through a set there's little beyond it", "repetition of
  questions"). That same answer praises the coach explanations and the
  interface.

## Other actionable rows

**Bridge, Oct 22, member:** "interested in getting better at bidding. I
guess don't understand how to move past the first three lessons." The
Auction Room is exactly three drills (Opening Playbook, Name Your Opening,
Openings: Extra Reps), all about the opening bid. Nothing teaches responding
to partner or the opener's rebid; the only later bidding is Competitive
Bidding in the Master Tables (doubles, preempts, Stayman, transfers). Not a
bug: a content gap at the next step a bidding learner needs. Effort M (a
Responding room or two drills in the Auction Room, with hand generation and
16-language copy). Decision 1 below.

## Decisions

1. **Bridge: add "Responding to partner" and "Opener's rebid" drills to the
   Auction Room?** Recommend yes. It is the one typed request from a paying
   Bridge member, bidding is what bridge learners come for, and today the
   path stops after the opening bid.
