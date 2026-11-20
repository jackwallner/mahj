# Competitor reviews: what American mah jongg players complain about and ask for

2026-11-20. 3,462 reviews and comparison-page notes on 8 competing apps (plus Mahj Trainer), tagged by theme and ranked against Mahj Trainer. Raw tagged rows: [2026-11-20-competitor-reviews.tsv](2026-11-20-competitor-reviews.tsv).

## Bottom line

- The loudest complaints in this category are about apps breaking or changing under players (bugs, forced redesigns, small tiles), not missing features. Mahj gains most by being the app that is legible, correct and stable for a 50+ audience.
- What players praise most is learning by doing with an explanation attached. Every fast-growing competitor (The Mahjong App, MAHJ, Cedar's Mahjong Trainer) sells guided practice. The top unmet teaching ask is help choosing which hand to play, and why.
- Each spring, players wait for apps to load the new NMJL card and then pay again for it. Mahj never waits for the card, and its listing doesn't say so.
- Bots, multiplayer and leaderboards draw real volume (about 600 mentions), but most of it is complaint or praise about apps that already offer them. The daily challenge with a leaderboard is the one social piece every competitor shipped this fall, and Mahj already has its own version (the monthly challenge).
- Cedar's "Mahjong Trainer: Learn & Win" is the closest direct rival by name and format. 17 of its 19 reviews are 1 to 3 stars: tiny tiles with no zoom, wrong rules answers, repeated questions, stuck progress, and billing after a cancelled trial. Those are exactly the failures a trainer cannot afford.

## Data

| App | App Store | Google Play | Web | 1-3★ share of sample | US ratings (avg) |
|---|---|---|---|---|---|
| Mahjong 4 Friends | 643 | 565 | 26 | 20% | 27,028 (4.9) |
| Real Mah Jongg | 709 | 453 | 14 | 17% | 5,736 (4.7) |
| American Mahjong Practice | 549 | 38 | 14 | 7% | 23,054 (4.9) |
| The Mahjong App | 126 | 88 | 10 | 6% | 9,126 (4.9), launched 2026-05-01 |
| Mahj Parlour | 74 | none on Play | 10 | 28% | 1,707 (4.9) |
| MAHJ | 38 | 16 | 6 | 5% | 1,532 (4.9) |
| Maylee | 42 | 1 | 3 | 23% | 1,304 (4.9) |
| Cedar (Mahjong Trainer: Learn & Win) | 15 | 4 | 0 | 89% | 372 (4.4), up from 283 on Nov 3 |
| Mahj Trainer (reference) | 5 | 0 | 0 | 20% | 42 (4.7) |
| General comparison pages | | | 13 | | |

Sources and method:
- **App Store:** public customer-reviews RSS for 10 English storefronts (us, ca, gb, au, nz, ie, za, in, sg, ph), most recent plus most helpful. The feed caps at 500 per sort per storefront, so for the three big apps the US sample is the latest 500 plus the 500 most helpful. Nearly all reviews are US (1,545 of 1,638 in the recent pass).
- **Google Play:** google-play-scraper, us, ca, gb and au, newest and most relevant, deduped (1,165 rows).
- **Web:** 96 notes from 2025-26 comparison posts (bamgoodtime.com, mahjparlour.com, mahjong4friends.com, mahjong-rules.com, game-solver.com, mahjnotes.com and others). Most are written by a competitor, so they count as one weak vote each.
- **What's New and pricing:** every app's version history and in-app purchase list, from its US App Store page.
- **Not covered: Reddit.** Unauthenticated JSON requests return 403 from this Mac. Claude in Chrome blocks reddit.com. A fleet crawl found about 950 candidate threads but was rate-limited to 2 threads a minute and stopped before saving. Web search surfaced no Reddit threads either. A follow-up needs a Reddit API key or a signed-in export.
- **Tagging:** 891 four- and five-star reviews with no complaint or request words were auto-tagged `praise_general`. Sonnet tagged the other 2,571 rows (up to 3 themes, sentiment, intensity 1 to 3, request flag, short gist). A 12-row spot check matched in every case.
- **Caveats:** 42 Mahjong 4 Friends reviews are about Chinese, Hong Kong or Filipino rules, which inflates its `house_rules_settings` and scoring asks. The sample skews 5-star (72%) because the stores do. Rankings use negative or mixed rows only, so praise doesn't drown out complaints.

## Themes ranked

Score = the sum of intensity (1 to 3) over negative or mixed mentions. "Asks" = reviews requesting something missing. Mahj status is explained in the next section.

| # | Theme | Mentions | Neg/mixed | 1-3★ | Strong (3) | Asks | Score | Mostly from | Mahj |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Bugs and stability | 247 | 234 | 161 | 57 | 16 | 513 | Mahjong 4 Friends 121, Real Mah Jongg 77 | covered |
| 2 | Price and paywall | 306 | 186 | 116 | 78 | 53 | 426 | Real Mah Jongg 96, American Mahjong Practice 33 | covered |
| 3 | Controls and layout | 276 | 173 | 96 | 20 | 118 | 344 | Mahjong 4 Friends 96 (Sep-Oct redesign: 46) | partly |
| 4 | Rules accuracy | 176 | 148 | 76 | 19 | 28 | 301 | Real Mah Jongg 70, Mahjong 4 Friends 39 | partly |
| 5 | Bot quality *(outside direction)* | 163 | 104 | 62 | 20 | 29 | 208 | Real Mah Jongg 60, Mahjong 4 Friends 28 | n/a |
| 6 | Card-year updates | 347 | 101 | 33 | 7 | 46 | 179 | American Mahjong Practice 44, Real Mah Jongg 29 | covered, not marketed |
| 7 | Learning and teaching | 726 | 81 | 57 | 17 | 63 | 159 | Mahjong 4 Friends 30, Real Mah Jongg 20 | covered |
| 8 | Readability and accessibility | 102 | 68 | 37 | 10 | 45 | 139 | Mahjong 4 Friends 35, Cedar 5 of its 19 | gap |
| 9 | Platform (Android, web, desktop) | 94 | 69 | 34 | 12 | 25 | 134 | Mahjong 4 Friends 25, Real Mah Jongg 19 | covered |
| 10 | Connectivity and login | 60 | 58 | 32 | 18 | 10 | 128 | Real Mah Jongg 33 | covered (no account) |
| 11 | Multiplayer *(outside direction)* | 369 | 73 | 28 | 6 | 49 | 125 | Mahjong 4 Friends 39 | n/a |
| 12 | Ads | 92 | 54 | 30 | 17 | 13 | 115 | Mahjong 4 Friends 51 | covered (no ads) |
| 13 | Hand help (which hand, suggestions) | 271 | 48 | 19 | 1 | 48 | 83 | Mahjong 4 Friends 20, American Mahjong Practice 13 | partly |
| 14 | House rules and settings | 156 | 46 | 20 | 6 | 68 | 83 | Mahjong 4 Friends 27 (many non-American) | partly |
| 15 | Developer support | 111 | 27 | 17 | 11 | 8 | 65 | Real Mah Jongg 13, Cedar 5 | covered |
| 16 | Stats and progress | 62 | 24 | 8 | 0 | 29 | 42 | Mahjong 4 Friends 12 | covered |
| 17 | Charleston | 39 | 13 | 6 | 3 | 6 | 27 | Mahjong 4 Friends 8 | covered |
| 18 | Practice variety and repetition | 38 | 13 | 10 | 1 | 11 | 24 | Real Mah Jongg 4, Cedar | covered |
| 19 | Defense and strategy | 12 | 6 | 0 | 0 | 9 | 10 | | covered |
| 20 | Competitive and leaderboards *(outside direction)* | 9 | 5 | 1 | 0 | 2 | 7 | | partly (monthly challenge) |
| 21 | Offline | 31 | 2 | 2 | 0 | 2 | 4 | (mostly praise) | covered |

Keyword counts that cut across themes (all rows, any sentiment): help choosing a hand 161 (32 asks, 87 from 2026), new-card timing 206 (29 asks), too expensive 97 (69 negative), playing with friends 219, tile size or zoom 52 (37 negative, 29 asks), scoring and payout 44 (23 asks), one-time or annual price 39, "explain why" or coaching 34, rigged bots 31, repeated hands or questions 26, blanks 23 (13 asks), undo 16, no support reply 12, trial billing 9.

### Quotes (under 15 words)

1. **Bugs:** "Drops tiles randomly into your home row." (1★ Mahjong 4 Friends, 2026-03); "We have tried to create rooms several times and it just won't work." (1★ Mahjong 4 Friends, 2025-08)
2. **Price:** "App immediately asked for $18 or $3.99 a month" (1★ American Mahjong Practice, 2026-06); "I signed up for the trial of $.99... They still Charged me $12.99" (1★ Cedar, 2026-11)
3. **Controls and layout:** "Your new update totally ruins the game." (2★ Mahjong 4 Friends, 2026-09); "Why do developers change what isn't broken?" (5★ Mahjong 4 Friends, 2026-09)
4. **Rules accuracy:** "I had mahjong on 13579 last line and it wouldn't recognize!" (1★ Mahj Parlour, 2026-07); Cedar was marked wrong on the blind pass: "According to NMJL rules I was correct, you can pass 3." (2★, 2026-09)
5. **Bots:** "And bots always get 3-4 jokers" (3★ Mahjong 4 Friends, 2026-11); "Little hard to believe it's not rigged." (3★ Real Mah Jongg, 2024-04)
6. **Card year:** "The lines don't follow the official NMJL 2026 card." (1★ Mahj Parlour, 2026-06); "asks when 2020/2021/2025 card available" recurs every spring (31 asks)
7. **Learning:** "This app doesn't explain how to discard in the app." (1★ American Mahjong Practice, 2026-10); "There is no guide to how to use the app." (1★ Real Mah Jongg, 2026-08)
8. **Readability:** "Might enjoy this if tiles were large enough to see." (1★ Cedar, 2026-11); "Not only is it tiny but the questions are confusing." (1★ Cedar, a teacher, 2026-11)
9. **Hand help:** "Just a place to reference the hands would be so helpful!" (3★ Mahj Parlour, 2026-07); "I wish it had a section that would help on picking a hand" (4★ Cedar, 2026-09)
10. **House rules:** "Wish there was an option to add blanks if desired" (4★ Mahjong 4 Friends, 2026-09); "Love that this app gives you the option to use blanks" (5★ The Mahjong App, 2026-10)
11. **Repetition:** "It deals the same hands over and over again." (1★ Real Mah Jongg, 2026-07)

## Where Mahj stands on each top theme

Checked against `main` at `868bda3` (origin fetched 2026-11-20).

- **Bugs and stability: covered.** Mahj has no network play, no accounts and no sync, so most of what breaks Mahjong 4 Friends and Real Mah Jongg (rooms, servers, lost games) can't happen. There is a state-machine audit and a test suite. The lesson worth carrying: Cedar's 1-stars include "locked up after the second day" and "repeats questions I already answered". Progress that stalls reads as a bug in a trainer.
- **Price and paywall: covered.** All four beginner rooms are free. Mahj+ is monthly, yearly (both with a free week) or lifetime ("One payment. No subscription, nothing renews.", `PaywallView.swift`). That already answers the category's biggest pricing asks (one-time purchase 39 mentions, an annual option, "solo practice should be free"). Weak spot: the store listing doesn't lead with "free beginner rooms" or "lifetime".
- **Controls and layout: partly.** Mahj has little table UI to break. But the Mahjong 4 Friends September portrait redesign drew 46 negative reviews in two months ("wants old format back"), and Mahjong 4 Friends then shipped an orientation setting on Oct 20. Takeaway: this audience punishes forced layout changes. Play a Hand has no undo for a mis-tapped discard (no `undo` in `HandPlayView.swift`); undo asks: 16.
- **Rules accuracy: partly.** `ContentValidityTests` enforce structure, not rule truth. Players check answers against the rule book and leave 1-stars when they disagree: Cedar's blind-pass and Hong Kong questions, and Mahj's own reviews (1★ 2026-09-18 on calling jokers, 4★ 2026-11-13 "Since when is a 5pung 5 tiles?"). The Nov 13 daily question should be found and checked; that was not done here.
- **Card-year updates: covered by design, not marketed.** Mahj teaches the nine stable sections and never copies the card, so it works the day a new card ships, every year, at no extra charge. Competitors charge again (American Mahjong Practice "2026 Hands" $17.99), lag for months (Mahjong 4 Friends shipped the 2026 card on Apr 27; Maylee was patching 2026 hands into July), or get lines wrong (Mahj Parlour). The listing and onboarding don't say this.
- **Learning and teaching: covered.** The primer, flashcards, coached Charleston, Keep or Throw, Play a Hand graded on every throw, miss notes and Fix My Mistakes answer "doesn't explain why" (34) and "no instructions" (38 asks). Defense School and Joker School cover the defense and joker-swap asks.
- **Readability and accessibility: gap.** Text follows Dynamic Type and layouts reflow at accessibility sizes, but tiles are fixed widths (`TileView` 44pt default; racks use 30 to 54pt, and the monthly challenge uses 36pt at accessibility sizes). There is no larger-tiles setting and no zoom on a rack. This is Cedar's single most common 1-star complaint, and the asks are concentrated among older players ("old eyes", "visual learner").
- **Hand help: partly.** Read the Rack and Expert Rack Reading teach which section a rack is chasing. Play a Hand commits to one target. What is missing is the decision competitors' suggested-hands panels make: of two or three lines this rack could make, which is closest and still alive given exposures and dead tiles, and why. The asks: rank by likelihood (The Mahjong App), fade impossible hands (shipped by The Mahjong App Nov 10), freeze a chosen hand, explain why the suggestion changed.
- **House rules: partly.** Blanks appear in Reference, HowToPlay and Charleston content, but there is no drill on house-rule variations (blanks, courtesy-pass variants, stopping after the first Charleston). Those asks are rising in 2026.
- **Stats, Charleston, defense, offline, platform: covered.** Stats view, mastery rings and a weekly gain ledger. The Charleston Room is Mahj's strongest drill. Android port, iPad and Duo layouts, a free web practice page. Content is local, so it works offline.
- **Support: covered.** Settings has Send Feedback (in-app, no email needed) plus Rate. Cedar's "no way to request help" 1-stars are the counterexample.

## Demand outside the current direction (no bots, multiplayer or ranking)

Reported for completeness. Mahj stays a trainer.

| Theme | Mentions | Neg/mixed | Asks | Notes |
|---|---|---|---|---|
| Bots | 163 | 104 | 29 | Complaints split between "rigged or always wins" (31 keyword hits, mostly Real Mah Jongg) and "too weak, no skill setting" (Mahjong 4 Friends). Several players quit over bots: the trust problem Play a Hand avoids by having no opponents. |
| Multiplayer | 369 | 73 | 49 | Mostly praise for playing with a group (219 "with friends" mentions, 141 on Real Mah Jongg). Asks: private rooms, matchmaking when no friends are online, invite links that open the app, quitters penalized. MAHJ, Maylee and American Mahjong Practice reviews note the lack of live play. |
| Competitive and leaderboards | 9 themed, 25 keyword | 5 | 2 | Low complaint, positive pull: "enjoy comparing my score on the leaderboard" (American Mahjong Practice daily challenge). Tournament players use practice apps to prepare. |

Shipping signals (What's New, Oct to Nov 2026): The Mahjong App shipped a Daily Challenge (Oct 14), daily, weekly and friends leaderboards (Oct 20 to Nov 3), a past-puzzle archive (Premium), multiplayer beta (July) and lifetime Premium at $149.99. American Mahjong Practice shipped daily-challenge weekly winners and an archive (Nov 17-18), Hand Builder, Lookup and Defense tools (Oct 28), and Duo support (Nov 9). Mahj Parlour has Parlour Daily mini games, Quick Match and seasonal tile sets sold for Pearls. MAHJ has Host Mode game-night scorekeeping with a settle-up. Cedar shipped bots that explain every move (Nov 12), a camera Table Read (Sep), Apple Watch and widgets (Sep), and lessons read aloud (Nov 18), with weekly plans at $7.99. Real Mah Jongg hasn't shipped a feature since 2021.

## Opportunities for Mahj, best first

Effort: S = days, M = 1 to 2 weeks, L = 3+ weeks.

1. **Large-tile setting and tap-to-zoom on racks (S).** *Evidence:* 52 tile-size mentions, 37 negative, 29 asks. Cedar, the most similar trainer, collects 1-stars mostly for tiny tiles. The audience skews 50+. Mahj Parlour and Maylee both shipped visibility or text-scaling fixes. *Build:* a Settings toggle (Standard or Large) that scales every `TileRackView` `tileWidth`, wraps 13-tile racks onto two rows when needed, and lets a long press enlarge a rack. *Why first:* lowest effort, and it protects ratings against the failure that is sinking the nearest rival.

2. **"Which line?" drill: choose the closest live hand and see why (M).** *Evidence:* 161 hand-choice mentions (87 in 2026), 48 asks. "Help on picking a hand" (Cedar). Rank suggestions by likelihood and fade dead ones (The Mahjong App shipped this Nov 10). Players praise apps that "taught keep, pass, and target hands". *Build:* a rack plus visible exposures and discards, with two or three original candidate lines from different sections (generated, never card hands). Pick the line; the coach shows tiles needed, tiles still live (counting dead tiles), and why the others lose. Fits Read the Rack and `RackGenerator`; Expert Rack Reading is the seed.

3. **Say "no waiting for this year's card" everywhere, and run a New Card Week each April (S).** *Evidence:* 347 card-year mentions. Spring "when is the new card coming" asks every year from 2019 to 2026. Paying again for new hands ($17.99 at American Mahjong Practice). Lag (Mahjong 4 Friends Apr 27, Maylee patches into July). Wrong lines (Mahj Parlour 1★). *Build:* App Store subtitle, keywords and screenshot caption, plus an onboarding line saying it works with any year's card. Each April, a free in-app event and drill set on reading a new card fast (spot what changed by section, re-rank your go-to sections), teaching method only, with no hands copied.

4. **A rules-trust pass: cite the rule in every coach note, then audit all content against the rule book (S to M).** *Evidence:* rules accuracy ranks 4th by score (148 negative). Cedar's wrong blind-pass answer and Hong Kong questions drew 1-stars. Mahj's own two critical reviews are both "incorrect information". *Build:* one plain line in each answer's coach note saying which rule it rests on, with no per-question report link (Jack cut that). Plus an Opus audit of every drill, generator template and challenge question against the NMJL rule book's rules (not the card). Start with the 2026-11-13 daily question and joker calling.

5. **Guided full-hand scenarios: Charleston to mah jongg with scripted tables (L).** *Evidence:* learning-by-play is the top praise driver for the fastest-growing rival (The Mahjong App: "guided gameplay teaches rules", "learn without making others wait"). Cedar just shipped bots with reasons. Mahj's no-bots stance avoids the "rigged AI" trust problem (104 negative). *Build:* within the trainer direction, authored or generated scenarios where the "table" acts from a script, not AI opponents: you pass, draw, discard, decide on calls and joker swaps, and the coach grades each step, extending Play a Hand from 12 turns of draw and discard to the whole hand. Flag for Jack: this is the closest Mahj can get to gameplay without bots.

6. **House Rules drills: blanks, Charleston variants, table penalties (S).** *Evidence:* 23 blanks mentions (18 in 2026, 13 asks), "cannot work out how to exchange blanks", requests to stop after the first Charleston, courtesy-pass variations, 68 house-rule asks overall. *Build:* one Table Room set (Mahj+ extra reps) of original questions on common variants, each labelled "house rule, check with your table".

7. **Playable daily archive and a weekly recap (S).** *Evidence:* both main rivals shipped this in the last 5 weeks (The Mahjong App past puzzles, American Mahjong Practice archive and weekly winners). Review demand for leaderboards is small but positive (25). *Build:* make missed Mahj Minute days playable (no score credit, or a member perk) and add a Sunday recap card built on the existing weekly gain ledger. No new social layer.

8. **Game-night settle-up and scoring trainer (M).** *Evidence:* 44 scoring and payout mentions, 23 asks ("wants scoring explained", "running score"). MAHJ shipped Host Mode settle-up. Mahj already teaches who pays and pays-double rules. *Build:* a free Game Night tool: enter the hand value, self-draw, jokerless or discarder, and it shows who pays whom; plus a short scoring drill set. It fits the game-night ritual Mahj already owns and gives a weekly reason to open the app. Most scoring asks come from Mahjong 4 Friends' non-American players, so the true American demand is maybe half.

9. **Undo a mis-tapped discard in Play a Hand (S).** *Evidence:* 16 undo mentions, 118 controls asks dominated by accidental discards. *Build:* one-step undo before the coach grades the throw.

## Follow-ups not done here

- Reddit coverage needs a Reddit API key (script-type app) or a signed-in export. The search plan and filters are in this report's method.
- Find and check the 2026-11-13 Mahj Minute question the 4★ review flags.
