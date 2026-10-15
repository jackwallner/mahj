# Persona scoring (2026-10-15)

Every candidate was scored against the five personas in `personas.md`:
thumb-stop (T), clarity in 2 seconds (C), trust (Tr) and install intent (I),
1 to 5 each. Each line is her reaction, in her voice. Scores are deliberately
harsh: a 5 means she would stop, get it, believe it and tap Install today.

The scoring was done on the actual renders (`build_pack.py --all`), viewed as a
phone feed would show them, not on the copy alone. Copy and layout are in
`ads.py` and `build_pack.py`; file lists are in `ads.md`.

Personas: **P1 Linda** 58, brand-new. **P2 Barbara** 67, returning after 30
years. **P3 Carol** 52, intermediate, Tuesday group. **P4 Debbie** 63, club
teacher. **P5 Joan** 71, grandmother, iPad, reading glasses.

## Fixes before scoring (render QA, not persona feedback)

These were found by viewing the first renders and fixed before any persona
read them, so they are not counted as revisions:

- New York's named weights render at optical size 256, a hairline display cut
  whose hyphen does not draw ("3-step" came out "3 step"). Pinned the serif to
  optical size 36, the cut iOS uses for the app's own large titles. Sturdier
  strokes, closer to the app, easier for older eyes.
- Headlines were allowed to shrink to 72 px. The research rule is 84 px and
  up, so `fit()` now refuses to go below 84 and fails the build instead.
- C4 feed faded out the "Why not Any Like Numbers?" card, which is the whole
  proof. Re-cropped to the explanation and the "why not" card.
- C6 showed "October Challenge, 17 days left", which dates the ad within
  weeks. Cropped to the Get Started card only.
- C7 feed faded the example rack. Re-cropped to the example tiles.
- C3 4:5 cut the fourth answer (2468) off the bottom before the tap, so the
  viewer could not play along. The 4:5 version now starts its first crop at
  the rack.

## Round 1

| Ad | Persona | T | C | Tr | I | Her reaction |
|---|---|---|---|---|---|---|
| C1 Holding up the Charleston | Linda | 5 | 5 | 4 | 5 | "That is my exact nightmare, and that rack looks like the ones in class." |
| | Barbara | 3 | 4 | 4 | 3 | "I can pass three tiles, thank you. The coach note under it does look real." |
| | Carol | 3 | 4 | 4 | 3 | "The Charleston isn't my problem anymore. Pretty tiles, though." |
| | Debbie | 4 | 4 | 5 | 4 | "Odd tiles out, joker and flower kept. That's the pass I'd teach." |
| | Joan | 4 | 4 | 4 | 4 | "I can read every word. I don't want to slow my girls down either." |
| C2 Charleston 3-step carousel | Linda | 4 | 4 | 5 | 5 | "A rule I can remember, shown on one real deal. I'd save this." |
| | Barbara | 3 | 3 | 4 | 3 | "Sort by suit and count pairs? I did that in 1985. Card 3 is the useful one." |
| | Carol | 4 | 4 | 4 | 4 | "'Name two or three sections' is exactly where I freeze." |
| | Debbie | 4 | 4 | 5 | 5 | "Jokers can't be passed: correct. I'd forward this to my beginners." |
| | Joan | 3 | 3 | 4 | 3 | "Six cards to swipe. The first one is clear, the rest is a lot of tiles." |
| C3 Read the rack Reel | Linda | 4 | 4 | 4 | 4 | "I guessed Like Numbers. Now I want to know why it isn't." |
| | Barbara | 4 | 4 | 4 | 4 | "A real decision, not a cartoon. I got it in two seconds and felt good." |
| | Carol | 5 | 4 | 5 | 5 | "A quiz I can take in the feed, then a Charleston. That's my lunch break." |
| | Debbie | 4 | 4 | 4 | 4 | "The explanation is right and the captions are big enough to read." |
| | Joan | 3 | 2 | 4 | 3 | "The tiles fly by in the Charleston part. I couldn't see what she picked." |
| C4 Most apps let you play (v1 "mahjong apps") | Linda | 3 | 4 | 4 | 4 | "I don't use other apps, but 'shows you why' is what I need." |
| | Barbara | 4 | 4 | 4 | 4 | "Finally someone says it. Playing bots taught me nothing." |
| | Carol | 4 | 4 | 4 | 4 | "That 'Why not Like Numbers' box is the explanation I never get at the table." |
| | Debbie | 3 | 4 | 4 | 4 | "Fair claim, nobody named, and the explanation is accurate." |
| | Joan | 3 | 2 | 3 | 3 | "Mahjong apps? Those are the matching games. Is this one of those?" |
| C5 Real reviews (v1: two quotes, no app) | Linda | 3 | 4 | 4 | 4 | "Someone 'fairly new' like me liked the Charleston part." |
| | Barbara | 2 | 3 | 3 | 2 | "Two short reviews. Is that all they have? Show me the thing." |
| | Carol | 2 | 3 | 2 | 2 | "Testimonial ads always feel made up, and there's no app to judge." |
| | Debbie | 2 | 3 | 3 | 2 | "Could be about anything. It doesn't show me the teaching." |
| | Joan | 3 | 4 | 4 | 3 | "Nice big stars and big letters. But what is it?" |
| C6 6:55 pm, game night at 7 | Linda | 3 | 3 | 4 | 3 | "Game night isn't the problem yet. I don't know what I'm doing." |
| | Barbara | 3 | 3 | 4 | 3 | "Cute clock. What does 'Get Started' actually do?" |
| | Carol | 4 | 4 | 4 | 4 | "Tuesday at 6:55 I'm in the driveway. Five minutes, sure." |
| | Debbie | 2 | 3 | 4 | 2 | "A green button. Nothing here for me to judge." |
| | Joan | 3 | 4 | 4 | 3 | "Easy to read. My game night is Thanksgiving, though." |
| C7 The hands change every April | Linda | 2 | 3 | 4 | 2 | "I've only ever seen one card. April means nothing to me yet." |
| | Barbara | 5 | 4 | 5 | 5 | "Exactly. The card's new, but I still know a 2468 when I see one. And they say they're not the League." |
| | Carol | 5 | 4 | 5 | 4 | "Every spring I'm a beginner again. This names it." |
| | Debbie | 4 | 4 | 5 | 4 | "Disclaimer up front and an original example rack. Good." |
| | Joan | 2 | 3 | 4 | 2 | "Patterns, sections. Too technical for me." |
| C8 Teaching someone to play? | Linda | 2 | 3 | 4 | 2 | "I'm the student, not the teacher. Scroll." |
| | Barbara | 2 | 3 | 4 | 2 | "Not for me." |
| | Carol | 2 | 3 | 4 | 2 | "I don't teach anyone." |
| | Debbie | 5 | 4 | 4 | 4 | "That's the question I get every week, answered." |
| | Joan | 3 | 3 | 4 | 2 | "Maybe my daughter would send me this. I wouldn't install it myself." |

### Round 1 totals (out of 100 per ad)

| Ad | T | C | Tr | I | Total |
|---|---|---|---|---|---|
| C1 | 19 | 21 | 21 | 19 | **80** |
| C2 | 18 | 18 | 22 | 20 | **78** |
| C3 | 20 | 18 | 21 | 20 | **79** |
| C4 | 17 | 18 | 19 | 19 | **73** |
| C5 | 12 | 17 | 16 | 13 | **58** |
| C6 | 15 | 17 | 20 | 15 | **67** |
| C7 | 18 | 18 | 23 | 17 | **76** |
| C8 | 14 | 16 | 20 | 12 | **62** |

## Revisions

| Ad | Low score | What changed |
|---|---|---|
| C3 | Joan clarity 2: "the tiles fly by" | The Charleston part played 11 s of footage at 2.5x. It now starts at the first tap (skips 2 s of idle deal) and plays at 2x, so each of the three picks lingers about a second. Length still 18.4 s. |
| C4 | Joan clarity 2, trust 3: "mahjong apps are the matching games" | Headline and primary text say "mahj apps", the word American players use for their game, which no solitaire player says. The "AMERICAN MAH JONGG" eyebrow stays. |
| C5 | Barbara, Carol, Debbie at 2: no product, thin proof | Rebuilt as one real review set large over the real Charleston result it describes ("practice Charleston's"). The second quote moved to an alternate primary text. The eyebrow now says "A real App Store review", singular, so it never implies a body of reviews. |
| C2 | Barbara 3: step 1 is too basic | Kept. Linda and Debbie, the two people it is for, scored it highest on trust, and step 1 anchors the real deal the next cards use. Barbara is served by C7 and C3. |
| C6, C8 | Weak proof (C6) and a narrow audience (C8) | Not revised. Both were cut instead: see below. |

## Round 2 (revised ads only)

| Ad | Persona | T | C | Tr | I | Her reaction |
|---|---|---|---|---|---|---|
| C3 v2 | Linda | 4 | 4 | 4 | 4 | "Same as before. I'd still play along." |
| | Barbara | 4 | 4 | 4 | 4 | "Fine." |
| | Carol | 5 | 4 | 5 | 5 | "Fine." |
| | Debbie | 4 | 4 | 4 | 4 | "Fine." |
| | Joan | 3 | 3 | 4 | 3 | "Slower now. I saw the three gold tiles and the 'perfect pass'." |
| C4 v2 | Linda | 3 | 4 | 4 | 4 | "Same." |
| | Barbara | 4 | 4 | 4 | 4 | "'Mahj', like we say at the club." |
| | Carol | 4 | 4 | 4 | 4 | "Same." |
| | Debbie | 3 | 4 | 4 | 4 | "Same." |
| | Joan | 3 | 3 | 4 | 3 | "Mahj, okay, that's my daughter's game. Still a lot of words in the picture." |
| C5 v2 | Linda | 4 | 4 | 4 | 4 | "A newer player, and there's the Charleston she means." |
| | Barbara | 2 | 4 | 3 | 2 | "One review. I'd rather just see the drill." |
| | Carol | 3 | 4 | 3 | 3 | "Better with the app. Still reads like a testimonial ad." |
| | Debbie | 3 | 4 | 4 | 3 | "At least it shows the coach's pass. Same thing as C1, really." |
| | Joan | 3 | 4 | 4 | 3 | "Big quote, then the tiles. Easier." |

| Ad | T | C | Tr | I | Round 1 | Round 2 |
|---|---|---|---|---|---|---|
| C3 v2 | 20 | 19 | 21 | 20 | 79 | **80** |
| C4 v2 | 17 | 19 | 20 | 19 | 73 | **75** |
| C5 v2 | 15 | 20 | 18 | 15 | 58 | **68** |

## The final 5

Picked for the best total *and* the least overlap, so Andromeda sees five
separate entities: different motivation, format and first frame.

| # | Ad | Total | Motivation | Format | First 2 seconds | Best for |
|---|---|---|---|---|---|---|
| 1 | **C1 Holding up the Charleston** | 80 | Fear of slowing the table | Static | Serif headline naming the fear over the app's own pass screen | Linda 19, Debbie 17 |
| 2 | **C3 Read the rack Reel** | 80 | Play-along challenge | 18 s video | "Which section is this rack chasing?" over a live drill | Carol 19, Barbara 16 |
| 3 | **C2 Charleston 3 steps** | 78 | A method to save for game night | 6-card carousel | "Freeze in the Charleston?" over bare tiles on a well, with "Swipe" | Linda 18, Debbie 18 |
| 4 | **C7 The hands change every April** | 76 | Yearly card reset, returning players | Static | "The hands change every April" plus the NMJL disclaimer | Barbara 19, Carol 18 |
| 5 | **C4 Most mahj apps let you play** | 75 | Frustration with games that never explain | Static | Contrast headline over a "Why not ...?" coaching card | Barbara 16, Carol 16 |

Cut:

- **C5 Real reviews (68 after revision).** Still the weakest with Barbara,
  Carol and Debbie, and its only strong visual is the same Charleston result
  as C1, which would make it a near-duplicate to Andromeda. The App Store has
  24 US ratings, so social proof is thin today. Revisit when the listing has
  more reviews; the renderer still builds it with `--only C5`.
- **C6 6:55 pm (67).** The habit idea is real (Carol), but the free proof is a
  green button. The stronger habit feature, Mahj Minute, is Mahj+, so the ad
  cannot honestly sell it to a free user.
- **C8 Teacher homework (62).** Debbie loves it and nobody else will stop.
  With broad women 40+ targeting and no interests, four of five people seeing
  it are students, not teachers. Better as an organic post to club organizers.

Coverage check: every persona has at least one final ad she scores 16 or
higher (Linda C1 19, Barbara C7 19, Carol C3 19, Debbie C2 18, Joan C1 16).
Joan is the weakest-served persona overall; C1 is her ad, and every final
carries "Free to start on the App Store" in 44 px or larger.

Residual overlap: C1 and C2 both use the one captured Charleston deal. They
differ in format (single image vs carousel), motivation (fear vs method) and
first frame (the app's pass screen with gold selections vs bare tiles on a
well under a question). If Ads Manager later reports them as one "similar"
entity, pause C2 first; C1 scored higher with Joan.
