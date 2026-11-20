# What Mahj Trainer should build from the competitor review study

2026-11-20. A product proposal built on [2026-11-20-competitor-reviews.md](2026-11-20-competitor-reviews.md) (3,462 tagged reviews on 8 rival apps), checked against the code on `main` at `077dce9` and against Mahj's own player feedback. Proposal only: no app code changed.

## What it gets Jack

- **Protects ratings where the nearest rival is losing them.** Cedar's "Mahjong Trainer: Learn & Win" has 17 of 19 reviews at 1 to 3 stars for tiny tiles and wrong rules answers. A large-tile setting and a rules audit close both gaps in Mahj before a player can write that review.
- **Adds the one teaching drill players ask for and no trainer has.** "Help me choose which hand to play, and why" is the top unmet ask (161 mentions, 87 of them from 2026). Mahj's own feedback asked for it on Nov 15.
- **More reasons to come back, inside the trainer direction.** The direction memo (`~/ios/growth/2026-11-04-mahj-direction.md`) puts retention first: halving churn is worth as much as doubling installs. Every item here is retention or ratings work. None needs bots, multiplayer, a ranking, or a change to the frozen trial flow.

## Two findings settled first

**The 2026-11-13 Mahj Minute question ("Since when is a 5pung 5 tiles?") was already found and fixed, and the fix is live.** It was the fourth question that day, the Keep or Throw card `plus-kd-count-tiles` ("You need a pung of 5 Bams", `Shared/Content/PlusContent.swift:239`). Its setup said "You hold one. Two are in the discards, one is exposed on a rack." Players read "exposed" as an exposed pung of 5 Bams, which put six 5 Bams in play when only four exist. Two commits on Nov 14 (`cebf377`, `b4dfd69`) rewrote it: you hold one and no jokers, two are discarded, and the fourth sits in an opponent's exposed pung beside two jokers, late in the hand. The count now adds up to four, and `ContentValidityTests` now fails any dead-tile card that names a lone exposed tile or rules a group out without saying what jokers you hold. Both commits are in 1.4.5 (build 88), live on the App Store since 2026-11-18. The lesson for item 3 below: the card was right on the rules and still read as wrong, because one word let a player picture an impossible table.

**The other critical Mahj review (1 star, 2026-09-18, "You can not call a joker ever") is a phrasing problem, not a wrong rule.** Every place the app talks about a discarded joker says it cannot be called (`TileBasicsContent.swift:208`, `MoreContent.swift:408`, `KeepDiscardContent.swift:103`, `MonthlyChallengeContent.swift:694`). What reads as wrong is the correct rule that you may call a discard for a pung with jokers from your hand, written as "call it with two jokers" (`MonthlyChallengeExtras.swift:142`, and the choice at `:420`). A one-line rule citation under the answer is the fix (item 3).

## Mahj's own feedback agrees on three themes and is silent on two

26 rows in `app_feedback` (Oct 19 to Nov 19, read with `scripts/feedback-inbox.sh --all`, nothing marked read). 24 are churn answers, 1 is a suggestion, 1 is an empty message.

| What players said | Rows | Matches the review study? |
|---|---|---|
| Too expensive, or "I don't want to pay" | 14 of 24 churn | Yes (theme 2, price). Out of scope here: prices and the trial flow are frozen. All 14 left in or right after the free week, so part of "too expensive" is "not enough value in week one", which the retention work below targets. |
| Wanted more content, too repetitive, "little beyond a set" | 4 | Yes (practice variety, Cedar's repeated questions). Argues for generated content (item 2's Endless skill) and the archive (item 7). |
| Too beginner, too advanced, not challenging enough | 3 | Partly. One said "Didn't simulate a real game enough" (item 4). |
| Show me the hand I should go for in Play a Hand | 1 suggestion (Nov 15) | Yes, exactly item 2's ask: "display the specific hand I should be going for... I was going for the wrong line". |
| "Would give almost any amount for an app that can shape my play" | 1 (Nov 11, inside a churn answer) | Yes, hand help and guided play (items 2 and 4). |
| Didn't use it enough, got what I needed | 3 | Neutral. |
| Tile size, readability | 0 | Silent. |
| A wrong rules answer | 0 | Silent here, but 2 of Mahj's 5 App Store reviews are rules complaints. |

The silence is about the channel, not the problem: Send Feedback produced 2 rows in a month, and nearly every row comes from the churn question. A player squinting at tiles or doubting an answer leaves, or goes to the App Store. So feedback confirms the hand-help and depth themes and cannot rule out readability or rules trust.

---

## 1. Large tiles and tap-to-zoom

**Player problem.** 52 mentions of tile size or zoom across the category, 37 negative, 29 asks. It is Cedar's most common 1-star complaint ("Might enjoy this if tiles were large enough to see"), and the asks cluster among older players, who are this app's buyers. Mahj's text follows Dynamic Type, but tiles are fixed: `TileView` defaults to 44pt wide and racks run 30 to 54pt. Nobody has complained about Mahj yet, which is the time to fix it.

**What changes.**
- **Settings > Practice: a "Large Tiles" toggle.** One switch, no picker. Default on for anyone whose text size is already an accessibility size, so the players who need it most never have to find it. It is a default, not onboarding, so the trial flow is untouched.
- **Racks scale and rewrap instead of shrinking.** `TileRackView` multiplies its `tileWidth` by 1.3 when Large is on and chooses how many tiles go in a row from the width it is offered. On a 375pt phone a 13-tile rack becomes three rows of 5, 5 and 3 at about 57pt, not two rows of 7 and 6 at 44pt. iPad and the unfolded Duo keep seven across at the larger size. Today the columns are fixed at 7 (`TileView.swift`, `columns = 7`), which is why each call site picks its own small width to fit.
- **Long press on any rack opens it full screen**, at the largest width that fits, over a dimmed backdrop; a tap anywhere closes it. It works in every drill, including Play a Hand, where a tap throws a tile, so the zoom never throws. VoiceOver gets it as a named action ("Zoom tiles"). No zoom button: it would sit under every rack.
- **Call sites to change** (11 racks plus 2 single-tile rows): `OnboardingView.swift:189` (54pt, leave as is: frozen flow and already large), `QuestionUI.swift:102` (36/44), `FlashcardDrillView.swift:580` (52/44/38 by row width), `CharlestonDrillView.swift:53` (44) and `:106` (coach's 3 tiles at 40), `HandPlayView.swift:137`, `:287` (40) and `:521` (34), `ReferenceView.swift:184` (36), `HowToPlayView.swift:196`, `MonthlyChallengeView.swift:686` (30/36, the answer review). The flashcard deck is a ZStack, so its widest card sets every card's width (the 2026-09-27 clipping bug); the deck must size from the widest Large front, checked on an SE.

**Free or Mahj+.** Free. An accessibility setting behind a paywall would be the next 1-star review.

**Effort: S to M (4 to 6 days).** `MahjTrainer/Views/Components/TileView.swift` (rack layout picks columns from width, scale from the environment), `Shared/Services/AppSettings.swift` (the setting and its accessibility default), `MahjTrainer/Views/SettingsView.swift`, the call sites above, `MahjTrainerScreenshots/LayoutSweepTests.swift` and `scripts/layout-sweep.sh` (Large on, all seven devices, AX3 and AX5), then the Android port (`android/.../ui/components`, about 2 more days). The design rules say default-size screens must stay pixel-identical, so the sweep diffs Large off against 1.4.5.

**Risks.** No App Review, copyright or trial-flow risk. Layout is the risk: three rows of tiles push the coach note below the fold on the Charleston and Play a Hand screens. `CenteringScrollView` already scrolls the note into view, but it needs the AX3 test (`OrdinaryRunTests.testCoachingNoteScrollsAboveNextAtAX3`) rerun with Large on. And the study's own warning applies: this audience punishes forced layout changes, so Large stays off for everyone who did not ask for big text.

**How to measure.** PostHog: `setting_changed` already fires; add `key: tile_size` and the text size, plus a new `rack_zoomed` (screen, tile count). Success: 1. at least 20% of players at accessibility text sizes keep Large on after 7 days; 2. Large users' 7-day return rate is at least as good as matched players' (no harm); 3. zero tile-size complaints in Mahj's App Store reviews and feedback over the next 90 days. RevenueCat cannot read this one; at 18 downloads a day, any revenue change would be noise.

## 2. "Which line?": choose the closest live hand, and see why

**Player problem.** Hand choice is the category's top unmet teaching ask: 161 mentions (87 in 2026), 48 asks, and "I wish it had a section that would help on picking a hand" (Cedar, 4 stars). The Mahjong App shipped "fade impossible hands" on Nov 10. Mahj's own feedback on Nov 15 asked for the same thing inside Play a Hand. Mahj teaches the first half: Read the Rack and Expert Rack Reading ask which section a rack is chasing. Nothing asks the real table question: of the two or three hands this rack could make, which is closest and still alive, given what is exposed and discarded?

**What changes.**
- **A new question type.** The screen shows your 13 tiles, then a row "Discarded so far" and up to two opponents' exposures. Below, two or three **candidate lines**. Each candidate is a section plus the group plan this rack would build in it, written from the rack, never from a card: "13579: keep the pung of 1 Craks and pair of 9 Dots, build pungs of 5s and 7s." The player picks one.
- **The coach shows the arithmetic, the way Play a Hand grades throws.** For each candidate: tiles still needed, how many of those are still live (four of each, minus what you hold, what is discarded and what is exposed), and what jokers you hold. Then one sentence on why the losers lose: "The run needs a 6 Dot and both are gone, with one exposed by East and one in the discards. 13579 needs four more and eleven of them are live." It is a count the player can check, not an opinion.
- **Only unarguable deals.** A new generator (`LineChoiceGenerator`) builds on `RackGenerator.fits` and `HandPlayEngine.value`. It throws away any deal where the right candidate does not win clearly on tiles needed and live counts, the same way `DefenseGenerator.isUnarguable` throws away arguable tables. Ties are not dealt.
- **Where it lives.**
  1. Card Room: a free authored drill of 10 questions, "Which Line?", after Read the Rack.
  2. Mahj+: a 10-question Extra Reps set, a harder Master Tables set (decoys where the bigger group is the dead one), and a new Endless and Timed skill so it never runs out (this answers the "too repetitive" churn reason).
  3. Play a Hand's choose screen uses the same coach. Today it shows section names and raw counts (`fittingTiles`). With this, the committed target shows its group plan at the top of the hand ("Building: pungs of 1, 5 and 9 Craks, pair of 3 Bams"), which is what the Nov 15 player asked for, in a form that is never a card line.
  4. A Mahj Minute question type from the month after it ships.

**Free or Mahj+.** The first authored set and one Play a Hand per day are free. Extra Reps, Master Tables, Endless and unlimited hands are Mahj+, the same split as every other room.

**Effort: M (about 2 weeks iOS, plus 4 to 5 days Android).** New `Shared/Content/LineChoiceGenerator.swift` and `MahjTrainerTests/LineChoiceGeneratorTests.swift`; `Shared/Content/SessionBuilder.swift` (`QuickItem` gains optional exposures and discards, decoded as empty for saved runs that lack them); `MahjTrainer/Views/Components/QuestionUI.swift` (the discards and exposures rows); `Shared/Content/EndlessPractice.swift` (a `lineChoice` skill); `Shared/Content/DrillLibrary.swift`, `CategoryContent.swift`, `PlusContent.swift`, `ProContent.swift` (authored sets); `Shared/Content/HandPlayEngine.swift` and `MahjTrainer/Views/Drills/HandPlayView.swift` (the group plan line); both String Catalogs (every generator sentence, 6 languages); the Android port and its parity fixture (the generator must match Swift seed for seed, as `RackGenerator` does).

**Risks.**
- **NMJL copyright, the main one.** A candidate written as an exact tile line ("FF 111 333 5555 77") could match a real card line by chance. So candidates are group plans derived from the player's rack, never fixed lines, and authored candidates are checked privately against the current card and kept off it, as the content rules already require. The copy says "the closest line on your card will look like this", so the player still reads their own card.
- **Card-dependent claims.** "Closest" must hold on any year's card. Ranking by tiles needed and live tiles, never by "this line is usually worth more", keeps it card-agnostic.
- **Content rules.** `ContentValidityTests` extends to the new scene: no more than 4 of any tile across rack, discards and exposures, jokers counted as 8, no exposure that grows after its owner discards.
- No App Review or trial-flow risk. The trial page's benefit rows stay as they are; the new drill is not added to them.

**How to measure.** PostHog: the `answer` event already fires per graded question; add `skill: line_choice`, `candidates`, `margin` (needed-tile gap) and `picked_rank`. New `line_plan_viewed` on Play a Hand. Success: 1. at least 30% of players who reach the Card Room try Which Line in their first 7 days; 2. accuracy rises between a player's first 10 and next 10 questions (proof it teaches); 3. players who try it return in days 8 to 30 at a higher rate than those who don't (read cautiously, since keen players try more). RevenueCat: trial starts from results through `TrialOfferSheet` sources `mahj_offer_drill` and `_auto` after a Which Line result, and first-renewal rate for customers whose first week included it, read 60 days after release.

## 3. A rules-trust pass: cite the rule, then audit everything

**Player problem.** Rules accuracy ranks fourth by score (176 mentions, 148 negative or mixed). Players check answers against the rule book and leave 1-stars when they disagree, whether or not the app is wrong. Cedar was marked down for a wrong blind-pass answer. Mahj's two critical reviews are both "incorrect information": one was a card that read as wrong (Nov 13, now fixed), the other a correct rule that sounded wrong (Sep 18). `ContentValidityTests` checks structure (tile counts, pass sizes, ids), never rule truth.

**What changes.**
- **A one-line citation under every rules-based answer.** After grading, under the coach note: "Rule: Calling a discard". Tapping it opens that term in Reference (`ReferenceContent` glossary, already free and offline), which states the rule in full. It only appears where the answer rests on a rule (calling, exposures, jokers, dead hands, Charleston passes, paying). Strategy calls, such as "which tile is safest" or "commit to 369", get no line, because they are judgment and the notes already hedge them. That split is itself the trust fix: the player can tell a checkable rule from the coach's opinion. No per-question report link (Jack cut it before 1.4.1 shipped, and that stands).
- **The audit.** Every authored item (294 ids: 171 explanations, 41 Charleston reasonings, 65 flashcard backs, plus quiz choices), every generator sentence template and miss note, the Reference glossary and the How to Play primer, each checked against the rules in the NMJL rule book, never the card. Each item gets RIGHT, WRONG, MISLEADING or UNCLEAR with the rule it rests on. Method and bar are the ones Jack set for the challenge audit (2026-10-18): Opus readers in rounds, finished after two rounds in a row with no new WRONG or MISLEADING finding; UNCLEAR wording is fixed without resetting the count. A third pass reads as a suspicious player, asking only "could someone with the rule book think this is wrong?", which is the test the Nov 13 card failed.
- **Ground truth.** The `docs/learn` guides were checked against secondary sources (Sloperama, schoolofmahjong.com and others; `project-docs/seo/learn-guides-2026-11-12.md`). The audit should use the League's own rule book, "Mah Jongg Made Easy". If Jack has no copy, buying one is his call; without it, the audit falls back to the same secondary sources and says so per item.
- **A test that keeps it true.** `ContentValidityTests` fails any item whose explanation uses a rule word (call, expose, dead, joker, blind, courtesy, pays) without a rule reference, and any reference that does not resolve to a Reference term.

**Free or Mahj+.** Free. It applies to every question.

**Effort: M (about 1.5 weeks).** The audit is about 3 days of agent time plus Jack's review of WRONG findings. Citations: a `rule` field on `QuickItem`, `QuizQuestion`, `Flashcard`, `CharlestonScenario` and `HandMatchQuestion` (`Shared/Models/Drill.swift`, `Shared/Content/SessionBuilder.swift`); a tag on each rules-based item across `Shared/Content/*.swift`; the citation line in `QuestionUI.swift`, `FlashcardDrillView.swift` and `CharlestonDrillView.swift`; a deep link into `ReferenceView.swift`; a few new glossary terms (blind pass, courtesy pass, paying) in `ReferenceContent.swift`; `ContentValidityTests.swift`; the Android content export. Translation is light: the citation is a term name the catalogs already hold.

**Risks.** Copyright: cite rules by topic in Mahj's own words, never quote the rule book, and never touch the card. Design: the citation is the one place this proposal adds a line of text under an answer, against Jack's rule to cut secondary labels. It earns its place only if it reads as part of the answer. If it reads as clutter in the first TestFlight build, keep the audit and the test and drop the line. App Review and the trial flow are unaffected. One more risk is the audit itself: fresh readers always find borderline wording, which is why the bar is "no new WRONG or MISLEADING", not "no findings".

**How to measure.** PostHog: new `rule_opened` (term, screen) when a citation is tapped, plus `reference_opened` from there. Success: 1. no new "incorrect information" App Store review or feedback row in the 90 days after release (today: 2 in 5 reviews); 2. citations are opened on at least 2% of graded rules answers (they are being read, not ignored); 3. the WRONG findings are fixed in the same release. RevenueCat cannot measure it.

## 4. Guided full-hand scenarios: a direction decision for Jack

**Player problem.** Learning by doing is what players praise most. The fastest-growing rival, The Mahjong App, sells guided gameplay ("learn without making others wait"). Cedar shipped bots that explain every move on Nov 12. One Mahj churn answer said it "didn't simulate a real game enough", and another wanted an app that can "shape my play". Play a Hand covers 12 turns of draw and discard against no one, with no Charleston, calls, joker swaps or mah jongg.

**What it is.** A small library of authored hands, played start to finish. The deal, the wall and the other three seats are a script, written in advance and played back. The player makes every decision a real hand asks for: the three Charleston passes and the courtesy pass, which line to commit to, each discard, whether to call a discard for an exposure, when to redeem a joker from an exposure, and when to declare mah jongg. The coach grades each decision with the same arithmetic as Play a Hand, and the seats' exposures and discards feed the Which Line live-tile count. Each scenario teaches one idea, such as "switch lines when your pung goes dead" or "don't call the pung that shows your hand".

**What it is not.** No AI opponents, nothing that decides on the fly, no score against other players, and no multiplayer. The seats never try to win: a scripted East calls your discard only where the author wrote that moment in, so nothing can feel rigged (104 negative bot reviews; "the AI feels rigged" is the category's most damaging complaint). It is also not endless: each scenario is hand-written and checked.

**The hard part: mah jongg needs a winning hand.** Mahj has no card lines and never will. A scenario can only end in mah jongg on an original practice line written by Mahj and shown as such ("practice line, not from any card"). That is the line the identity question turns on: a hand that ends in mah jongg on a Mahj line is a step toward Mahj having its own card. Practice lines must be checked privately against the current card and kept off it, every year.

**The risk to the trainer identity.**
- Once three seats discard and expose, players judge it as a game. Reviews will compare it to Real Mah Jongg and Mahjong 4 Friends: "the other players are dumb", "same hands over and over" (26 repetition mentions).
- Authored scenarios run out. Ten scenarios are about two evenings of play. A player who enjoys them asks for more, then for opponents who respond, which is the bot roadmap the direction memo said not to start.
- In its favour: it uses everything Mahj already has (the Charleston coach, Play a Hand's grading, Which Line, Defense School's exposure reads) and gives the trainer a capstone: "play a whole hand with a coach beside you". No competitor offers that without bots.

**Two ways to do it, and the recommendation.**
- **A. Table mode for Play a Hand (M, about 2 weeks).** Keep Play a Hand's dealt hand but add scripted exposures and discards from three seats, and two or three call decisions per hand ("East throws the 5 Bam: call it?"). Still 12 turns, no Charleston, no mah jongg. Most of the teaching value, no practice lines, little identity risk.
- **B. Full scenarios (L, 4 to 5 weeks iOS plus 2 weeks Android, content is the bottleneck).** Everything above, from the Charleston to mah jongg on a practice line.
- **Recommendation: build A in 1.6, measure it, and decide on B with that data.** A tells us whether players want calls and a table at all, without committing Mahj to its own lines.

**Free or Mahj+.** As with Play a Hand: one hand a day free, unlimited for members. For B, the first scenario free and the library for members.

**Effort and files.** A: `Shared/Content/HandPlayEngine.swift` (a scripted table beside the wall), `MahjTrainer/Views/Drills/HandPlayView.swift` (seat rows and the call decision), `Shared/Services/HandPlayStore.swift` (saved state carries the script position), `MahjTrainerTests/HandPlayEngineTests.swift`, Android `HandPlayScreen.kt`. B adds `Shared/Models/TableScenario.swift`, `Shared/Content/TableScenarioContent.swift`, a `TableScenarioEngine` state machine, `TableScenarioView.swift`, a store, `DrillLibrary.swift`, content tests that replay every scripted hand to check that its tiles add up (152 in the wall, four of each), and a state-machine audit like the 2026-11-06 one.

**Risks.** Copyright (B only): practice lines, as above. App Review: none expected, but the copy must not promise "play a real game" (it is a scripted lesson). Trial flow: untouched, and "coached practice hands" in the trial benefits already covers it, so no wording change. Content rules: every scripted hand needs the same count checks as Play a Hand, plus the exposure rule (once its owner discards, an exposed pung never becomes a kong).

**How to measure.** PostHog: `hand_call_decided` (called or passed, right or wrong), `hand_finished` with `mode: table`; for B, `scenario_started`, `scenario_step` and `scenario_finished` with step counts, so drop-off shows which step loses players. Success for A: members play more hands a week in table mode than plain Play a Hand did over the same weeks a month earlier, and free players who finish a table hand start trials from the free-hand-spent sheet (`mahj_offer_hand`) at a higher rate than before. The go signal for B: table hands make up at least 30% of all Play a Hand starts after 30 days. RevenueCat: first renewal for customers whose first week included a table hand.

**Decision for Jack: build table mode (A) in 1.6, and hold full scenarios (B) until A has 30 days of data?**

---

## 5. "No waiting for this year's card", and a New Card Week each April

**Problem and evidence.** 347 card-year mentions. Every spring players ask "when is the new card coming" (31 asks, 2019 to 2026), pay again (American Mahjong Practice "2026 Hands" at $17.99), wait months (Mahjong 4 Friends Apr 27, Maylee patching into July) or get wrong lines (Mahj Parlour 1★). Mahj works with any year's card from day one at no extra charge, and its listing doesn't say so. **Change.** In the listing: the en-US promotional text (editable without a release) leads with "Works with any year's card. Nothing to wait for, nothing extra to buy", and the subtitle, keywords and a screenshot caption follow. The l10n-top5 session is editing `fastlane/metadata` now, so this waits until it lands. In the app: a line on Home's About and in the What's New sheet, not on the onboarding pages (frozen flow). Each April (first one April 2027, when the April challenge theme is already Reading Your Rack): a free App Store in-app event, "New Card Week", with a set of drills on reading a new card fast (spot what changed section by section, re-check the sections you usually play, find which lines your favourite openings now fit). Method only, nothing from the card. Also each April, check the year-digit filters in `CharlestonGenerator` (already covers 2026 and 2027) and `DefenseGenerator` (2s with 6s) against the new year. **Free or Mahj+.** Free event and drills; the event is also a featuring nomination. **Effort.** S: metadata is an hour once the other session finishes, the drills are 2 to 3 days of content in `Shared/Content/MonthlyChallengeContent.swift` and a new set in `CategoryContent.swift`, plus event art. **Risks.** Copyright: no card names beyond "the NMJL card", no hands. App Review 2.3.13: the event needs genuinely new, time-boxed content, which the drill set is. **Measure.** Product page conversion in ASC Analytics for the 30 days before and after the promo text change, April installs against March, PostHog `deep_link_opened` from the event link, and RevenueCat new trials in event week.

## 6. House Rules drills

**Problem and evidence.** 68 house-rule asks, 23 mentions of blanks (13 asks, 18 from 2026), plus "how do I exchange blanks", stopping after the first Charleston, and courtesy-pass variations. Mahj mentions blanks in Reference, How to Play and the Charleston content, but has no drill on what changes from table to table. **Change.** A Table Room drill, "House Rules", of 12 original questions: blanks and how they are swapped, stopping or skipping the second Charleston, courtesy-pass variants, what happens after a wrong mah jongg, common payment variations. Every answer is labelled "House rule: check with your table" and states the League rule first. **Free or Mahj+.** Free drill (the Table Room is a beginner room), with a 10-question Extra Reps set for members. **Effort.** S (2 to 3 days): `Shared/Content/MoreContent.swift` or a new `HouseRulesContent.swift`, `DrillLibrary.swift`, glossary terms in `ReferenceContent.swift`, catalogs, Android export. **Risks.** Rules accuracy, the inverse kind: a house rule presented as a League rule is exactly the 1-star in item 3, so every question carries a citation and the audit covers it. No copyright or trial-flow risk. **Measure.** PostHog `drill_result` for the new drill id (starts and completions), and whether "house rules" or "blanks" stops showing up as an ask in feedback.

## 7. A playable daily archive and a Sunday recap

**Problem and evidence.** Both main rivals shipped this in the last five weeks (The Mahjong App's past puzzles, as a Premium feature; American Mahjong Practice's archive and weekly winners, Nov 17 and 18). Leaderboard demand in reviews is small but positive (25 keyword mentions), and 4 of Mahj's 24 churn answers were about running out or repetition. Today "Earlier Mahj Minutes" and Past months are read-only. **Change.** Any missed day this month becomes playable from the challenge hub. Rounds are built from the date (`MonthlyChallenge.round(day:)`), so no new content is needed. An archive round never counts toward the month score or the standing (the score must stay "same questions, same day"), and it records into Fix My Mistakes like any practice. On Sundays, Home shows one recap card: Minutes played this week, the weekly gain the ledger already counts (`MasteryLedger.weeklyGain()`), and the room to work on. No new social layer. **Free or Mahj+.** Recap free; archive play is Mahj+ (it is extra practice, and it gives members a reason to open on a missed day). **Effort.** S (3 to 4 days): `MahjTrainer/Views/MonthlyChallengeView.swift`, `Shared/Services/MonthlyChallengeStore.swift` (archive runs kept apart from first runs, which the store already treats as the only scored run), `HomeView.swift`, tests in `MonthlyChallengeTests.swift`. **Risks.** The standing: an archive run must never reach `challenge_submit`. The challenge store's midnight and day-closing logic is the most fragile state in the app (see `monthly-challenge.md`), so archive runs go in their own store key. No copyright or trial-flow risk. **Measure.** PostHog `practice_finished` with `mode: archive`; members' weekly active days before and after; RevenueCat trial starts from the archive lock (a new `mahj_offer_archive` source).

## 8. Game-night settle-up and a scoring drill

**Problem and evidence.** 44 scoring and payout mentions, 23 asks ("explain scoring", "running score"). MAHJ shipped a Host Mode settle-up. Many of these asks come from non-American players on Mahjong 4 Friends, so real demand from American players is perhaps half. Mahj already teaches who pays and when payments double. **Change.** A free Game Night tool, one tap from the Game Night card and the Reference: enter the hand's value from your card, then tap who won and how (from the wall, or on whose discard, jokerless or not), and it shows who pays whom, with a running total for the night that clears the next day. Plus a short scoring drill in the Table Room. Players type the value from their own card, so the app never holds a card value. **Free or Mahj+.** Free: it is the reason to open Mahj on game night, the ritual the app already owns. **Effort.** M (about 1 week): new `Shared/Content/Settlement.swift` (pure arithmetic, fully unit-tested), a `SettleUpView.swift`, `GameNightPrepView.swift` and `ReferenceView.swift` entry points, the drill in `MoreContent.swift`, Android. **Risks.** Rules: payment rules differ by table (some play double for jokerless, some don't), so the tool states the League rule and offers no house-rule switches in version one. Copyright: none, the player enters values. App Review: none (it is not gambling: no money moves, it is arithmetic). Trial flow: untouched. **Measure.** PostHog `settle_up_used` (players, hands entered per night) and the share of game-night reminder taps (`notification_opened`) that open it; success is weekly repeat use by the same players.

## 9. Take back a mis-tapped discard in Play a Hand

**Problem and evidence.** 16 undo mentions, and the 118 controls asks are dominated by accidental discards. In Play a Hand a tap throws the tile and grades it in the same moment (`HandPlayView.swift`, `throwTile(at:)`), so a mis-tap leaves the wrong rack for the rest of the hand. **Change.** A "Take back" button on the grade card, until Next is tapped. It returns the tile to the rack and clears the card. The first throw still counts in the stats and the end-of-hand score, so take-backs cannot farm a perfect hand; they only fix the rack. Considered and rejected: tap to lift, tap again to throw. It is the standard pattern, but it would change how every existing player plays, the forced-change mistake the study warns about. **Free or Mahj+.** Free. **Effort.** S (1 to 2 days): `HandPlayView.swift`, `Shared/Services/HandPlayStore.swift` (the saved hand keeps the rack before the throw so a relaunch can still take it back), `HandPlayEngineTests.swift`, Android `HandPlayScreen.kt`. **Risks.** None for review, copyright or the trial flow. **Measure.** PostHog `hand_take_back` (turn, whether the first throw was the coach's pick); success is fewer hands abandoned in the first three turns.

---

## Recommended build order

| Order | What | Effort | Why here |
|---|---|---|---|
| 1 | Rules audit and citations (3) | M | Protects ratings on every question, and every later item reuses its citation and tests. The audit can start this week on a fleet machine. |
| 2 | Large tiles and zoom (1) | S to M | Cheapest ratings protection; the rival's top failure. Lands in the same layout sweep as the citation line. |
| 3 | Take back a discard (9) | S | Two days, and it rides along with Play a Hand work. |
| 4 | Which Line (2) | M | The biggest new teaching value and the Nov 15 player's ask. Needs 1 and 3 settled first. |
| 5 | House Rules drill (6) | S | Content only, reuses the citations. |
| 6 | No-waiting positioning (5, listing part) | S | As soon as the l10n session lands; no release needed for promo text. |
| 7 | Archive and Sunday recap (7) | S | 1.6, retention for members. |
| 8 | Table mode for Play a Hand (4A) | M | 1.6, after Which Line, so its live-tile coach is reused. |
| 9 | Settle-up (8) | M | 1.6 or later; demand is the softest. |
| 10 | New Card Week (5, event part) | S | Built in February, live in early April 2027. |
| 11 | Full scenarios (4B) | L | Only if table mode clears its 30% bar. |

## 1.5 release scope

1.5 ships items 3, 1, 9, 2 and 6, in that order: the rules audit with citations, Large Tiles with long-press zoom, take-back in Play a Hand, the Which Line drill (free set, Mahj+ sets, Endless skill, the group plan in Play a Hand) and the House Rules drill. About 4 to 5 weeks on iOS, with Android following each item. Nothing in it touches the onboarding trial page, the paywall or the purchase-to-tour flow, and the trial benefit rows stay as they are. The listing change (item 5) ships separately, as soon as the l10n-top5 session finishes in `fastlane/metadata`. The What's New for 1.5 leads with "Bigger tiles" and "Which line?", the two things a returning player can see.

## Decisions for Jack

1. **Approve the build order and the 1.5 scope above?** Yes or no.
2. **Table mode (4A) in 1.6, full scenarios (4B) held until table mode has 30 days of data?** Yes or no.
3. **Do you own the League's rule book (Mah Jongg Made Easy)?** If yes, the audit uses it as ground truth. If no, buying a copy is your call; without it the audit uses the same secondary sources as the `docs/learn` guides and marks each item that way.
