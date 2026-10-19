# First screenshot hook (2026-10-19)

A new first App Store screenshot (the hero frame) for Mahj Trainer, built from
what the paid ads and past product page tests say. Design only: nothing was
uploaded to App Store Connect, no PPO test was created, no ad was changed and
nothing was spent. `fastlane/screenshots` is untouched.

**Pick: A, "Never hold up the Charleston"** (`hook-a-never-hold-up-the-charleston.png`).

## Evidence

| Source | What was measured | Result | What it says about the hook |
|---|---|---|---|
| PPO, Charleston confidence first screenshot | Downloads per person, treatment vs control | **+19%** | The first-frame message is the lever, and Charleston confidence is the message that won |
| PPO, September 80-20 refresh (Charleston-first set, live "Pass with a plan") | Same | **+16%** | Charleston first held up as the control to beat |
| PPO, app preview video | Same | **+13%** | Showing the real drill in motion helps |
| PPO, search header image | Same | **-10%** | Decorative header and search art lose; keep a real screen under one line |
| Meta click test, C1 "Never be the one holding up the Charleston." over the real Pick Your Pass screen | Oct 16 to 19, Meta Ads MCP read | 1,016 impressions, 65 link clicks, **6.4% link CTR, $0.27 per click**, $17.80 | Strongest thumb-stop of the three. Fear of slowing the table is what made people tap |
| Meta, C7 "The hands change every April" | Same | 76 impressions, 1 click, 1.3% CTR, $1.57 per click | The yearly-card angle did not pull; Meta stopped serving it |
| Meta, C3 "Which section is this rack chasing?" reel | Same | 26 impressions, 1 click | No read (no Instagram asset, barely served) |
| Meta installs | ASC first-time downloads by source, Oct 16 to 18 | At most 3 installs from 52 clicks (implied $5.50+ per install), no lift; stop rule hit | Clicks came mostly from women 65+ and did not reach installs. The CTR win is real for attention, unproven for installs |
| Apple Ads, `mahjong trainer` (exact, CPP ad group) | ads-loop report Oct 17, since start | 8 impressions, 4 taps (50% tap-through), 3 installs, 5 trials, 1 paid; $1.52 per install | Searchers who already want a trainer convert well on the current page |
| Apple Ads, generic terms (`mahjong practice`, `mah jongg`, `american mahjong` and 5 more that served) | Same | 31 impressions combined, 1 tap, 0 installs; 17 more keywords never served | Broad intent barely shows and does not tap. The hero has to sell to browsers who have not decided they need a trainer |
| TikTok kit (42 hooks) | `Tracker.csv` in iCloud "Mahj TikTok Kit" | No results logged yet | No signal |

Caveat: every number above is small. The PPO results are the only ones measured
on downloads; Meta measured attention only, and its traffic skewed to 65+.

## Variants

All three use the same real capture and layout, so the headline is the only
variable. Style matches the live set (ppo-2026-10/mahj-v2 theme colours, New
York serif at 156 px, two lines, no periods) with one change asked for here:
no device frame. The screen is a real iPhone 17 Pro simulator capture of the
free Charleston drill after a pass (Pick Your Pass, "Perfect pass! 3 of 3",
the coach's three tiles and the reason), the same screen as Meta ad C1,
cropped below the status bar. No prices, no illustration, no frame.

| # | Headline | Angle | Evidence for it | Risk |
|---|---|---|---|---|
| **A** | **Never hold up the Charleston** | Social stakes: the fear of making the table wait | Meta C1 hook (6.4% CTR, 5x C7); Charleston-first PPO wins (+19%, +16%) | Negative framing; the Meta clickers it pulled skewed 65+ and did not install |
| B | Know which 3 tiles to pass | Concrete skill outcome | Closest to the live winner "Pass with a plan" and to the coach answer on screen | Too close to the control to move much; a likely near-tie |
| C | Practice the Charleston at home | The product action, in search words | Meta C1 ad headline; matches the `practice`/`trainer` search intent that converts on Apple Ads | Describes the app instead of the reason to want it; reads like a feature line |

Files (1320x2868, opaque PNG):

- `hook-a-never-hold-up-the-charleston.png`
- `hook-b-know-which-3-tiles-to-pass.png`
- `hook-c-practice-the-charleston-at-home.png`
- `contact-sheet.png`: the three side by side at thumbnail scale
- `source-charleston-perfect-pass.png`: the raw capture (from
  `~/ios/appstore-screenshots/captures/mahj/meta-20261015/05_charleston_perfect.png`)
- `render_hooks.py`: rebuilds everything (`python3 render_hooks.py`); it reuses
  the fleet shotflow renderer in `~/ios/appstore-screenshots/lib/render.py`

## The pick and why

1. **A wins on the only two signals that agree.** Charleston-first is the theme
   that won two product page tests, and "holding up the Charleston" was the
   Charleston hook that got 5x the click rate of anything else in paid social.
   A keeps the winning topic and adds the emotional reason to care.
2. **It speaks to the browser, not the searcher.** Apple Ads shows people
   searching `mahjong trainer` already install at a high rate; generic
   searchers barely tap. The hero has to give a not-yet-convinced player a
   reason, and the fear of slowing your group is that reason. B and C
   describe a skill or an action, which the trainer searchers do not need and
   the browsers do not feel.
3. **The screen proves the promise.** Under the headline sits the answer to
   the fear: three tiles chosen, "Perfect pass", and the coach's reason. A real
   screen under one line is the format that won; the decorative header image
   is the one that lost.

B is the safe second choice if A's negative framing feels off-brand. C is the
weakest.

## If this goes to a PPO test

- Swap only frame 1 in the current set, so the test reads the hook and not a
  whole new set. Note that A also drops the device frame the live set uses, so
  a win is copy plus framing; render a framed A with shotflow if a clean copy
  read is wanted.
- Judge on downloads per person, as before. A losing result stands.
- Meta's audience skewed 65+, so A's CTR may not transfer to App Store
  browsers; the PPO is the real test of it.

## v2: less text (2026-10-19)

Jack's read on v1: too text heavy. v2 (`render_hooks_v2.py`) keeps the same
headlines but cuts the coach's paragraph and tip, so the screen is just the
rack, the three picked tiles and "Perfect pass! 3 of 3" with the coach's
three tiles. Side margins are trimmed so the tiles render larger.

- `hook-a-v2-never-hold-up-the-charleston.png` (pick)
- `hook-b-v2-know-which-3-tiles-to-pass.png`
- `hook-c-v2-practice-the-charleston-at-home.png`
- `contact-sheet-v2.png`
