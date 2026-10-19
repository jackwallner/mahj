# Meta $50 click test (launched 2026-10-16)

Status 2026-10-15: planned. **Nothing is built in Ads Manager and nothing is
spent.** Launch only on Jack's explicit go-ahead in chat.

Status 2026-10-16: "Mahj Trainer" Page created (ID 61595624634024, app icon,
App Store link). Business portfolio "E3 Fitness LLC" (ID 2346140409473669)
was restricted by Meta within minutes of creation for "automation that
doesn't follow our rules" (Account Integrity), because Claude filled the setup
forms through Chrome automation. No ad account exists yet. Jack requests the
review by hand (179-day window). Claude does no more browser work in Meta
Business Suite or Ads Manager; once the portfolio is cleared, Jack builds the
campaign by hand from the setup below.

Status 2026-10-16 (later): portfolio reinstated after Jack's review request.
Jack drives every Meta screen by hand; Claude gives step-by-step instructions.

Status 2026-10-16 (Part 1 done): Jack added the Page to the portfolio, created
the "Mahj Trainer" ad account (USD, Pacific), added a card and set a $60
account spending limit. Next: Jack builds the campaign below as a draft (not
published), sends screenshots, and publishes only after go in chat.

Status 2026-10-16 (Part 2, via Meta's official Ads MCP, no browser): ad
account `act_1842133493904848`. Campaign `120251564972370737` "Mahj US W40+
click test 2610" (Traffic, auction, no special category, no campaign budget)
and ad set `120251564975060737` "US W40+ iOS manual 6 placements" ($10/day,
website, link clicks, highest volume, US women 40 to 65+, Advantage+ audience
off, FB/IG Feed, Stories, Reels, mobile, iOS, no end date) created and read
back, both PAUSED. Deviations: the API rejects a campaign spending limit under
$100, so the $60 account limit is the only hard cap; the Page's ads ID is
`1348505275016223` (61595624634024 is its profile ID). No ads yet: the MCP's
local upload is not enabled for this account and the media library is empty,
so Jack uploads the 8 files (C1, C3, C7 feed/story PNGs, both C3 mp4s and both
C3 covers) to Ads Manager Media library, then Claude builds the 3 ads. No
Instagram account is linked, so ads run under the Page-backed identity.

Status 2026-10-16 (Part 3): all 8 files are in the ad account library via
URL upload. Image hashes: C1 feed `f8870b6d36365688cfe271bb1fcb4010`, C1 story
`f9cb0efd3ec9aa0899907e5dcaf17284`, C7 feed `caea0efde9e4e13a26ba0fc8422b72c3`,
C7 story `5e01bf5ab1150bc0d22c59393e33f09c`, C3 cover 4:5
`0cc272ed70872dbc25b8c96c33ea60cc`, C3 cover 9:16
`a63225a296fc26df913359b964982bb2` (all pixel-identical to the local files).
Videos ready: C3 4:5 `2202054177402819`, C3 9:16 `2258993131616688`. **Ads are
blocked:** Meta rejects every ad in this Traffic campaign whose link is an
apps.apple.com URL ("App Url is only supported by App Installs objective").
Placement-customized creatives C1 `1090472490279204` and C7
`1122747526886495` exist but carry that link and cannot be used. Next: Jack
picks a website destination (a mahj site page that sends people on to the
App Store with the per-ad `ct` link), then new creatives and the 3 ads.

Status 2026-10-16 (Part 4, App Promotion rebuild): Jack registered Mahj as
Meta app `987930193620309` (bundle com.jackwallner.mahj, store ID
6790052126). New campaign `120251566262580737` "Mahj US W40+ app click test
2610" (OUTCOME_APP_PROMOTION, auction, no special category, no campaign
budget) and ad set `120251566264100737` "US W40+ iOS manual 6 placements"
(promoted app 987930193620309 with store URL
https://apps.apple.com/us/app/id6790052126, destination APP, LINK_CLICKS
accepted, IMPRESSIONS billing, highest volume, $10/day, no end date, US women
40 to 65, Advantage+ audience off, FB Feed/Stories/Reels and IG
Feed/Stories/Reels, mobile, iOS) created and read back, both PAUSED, $0
spent. The Traffic campaign and its ad set are untouched and still PAUSED.
C1 creative `1896386585067602` (4:5 feed, 9:16 Stories/Reels, Install Now,
per-ad `ct` link, enhancements, music and site links off) exists. **Ads are
blocked:** Meta refuses the ad with "Instagram Account Is Missing" (subcode
1772103) because the ad set includes Instagram placements and the ad account
has no Instagram account, not even a Page-backed one, and the MCP cannot
create one. Next: Jack either links an Instagram account (or the Page-backed
one) to the ad account, or approves Facebook-only placements; then the
creatives are rebuilt with that identity and the 3 ads created. Whether Meta
keeps the `ct` parameter is unknown until an ad exists.

Status 2026-10-16 (Part 5, Facebook only): the parent session decided to run
the click test on Facebook placements only (Instagram returns for the install
test once an Instagram identity exists). Ad set `120251566264100737` renamed
"US W40+ iOS FB 3 placements" and read back: Facebook Feed, Stories and Reels
only, mobile, iOS, US women 40 to 65, Advantage+ audience off, LINK_CLICKS,
$10/day, destination APP, PAUSED. Three ads created and read back, all PAUSED
(effective status IN_PROCESS while Meta reviews), $0 spent:

| Ad | Ad ID | Creative ID |
|---|---|---|
| C1 charleston-pass | `120251566327090737` | `1896386585067602` |
| C3 read-the-rack-reel | `120251566333710737` | `2868680573531536` |
| C7 every-april | `120251566331180737` | `1987105995266961` |

All three use Install Now, the per-ad `ct` link, the copy above, 4:5 media in
Feed and 9:16 in Stories and Reels (C3 uses the cover PNGs as video
thumbnails), and have Advantage+ creative enhancements, music, site links and
multi-advertiser ads off. Previews (Feed and Stories, each ad) checked by eye:
right asset per placement, right copy, Install Now button; the ad header shows
the app name "Mahj Trainer: Mahjong Practice" and no Page photo. **`ct`
survival is not verified:** Meta accepted each link as sent with no rewrite,
but the MCP read-back does not return the link of these placement-customized
creatives, and App Promotion ads may send clicks to the promoted app's plain
store URL. The first App Store Connect campaign readout after launch settles
it; if `meta-c*-2610` shows no downloads, use the RevenueCat lift cross-check.
To launch, Jack sets the dates and publishes campaign `120251566262580737`
after go in chat.

Status 2026-10-16 (Part 6, launched): Jack said go in chat. About 16:42 PT,
via the Meta Ads MCP, campaign `120251566262580737`, ad set
`120251566264100737` and ads C1, C3 and C7 were set ACTIVE. Meta refused
to move the ad set's start (subcode 1487057, "cannot be edited if the Ad Set
has already started"), so the stored start stays 2026-10-16 10:45 PT, which
predates the real activation; delivery runs from activation. End time set to
**2026-10-21 16:45 PT** (the campaign stop time follows it). Read back right
after activation:

| Object | status | effective_status | Delivery |
|---|---|---|---|
| Campaign `120251566262580737` | ACTIVE | ACTIVE | waiting on ads |
| Ad set `120251566264100737` | ACTIVE | ACTIVE | waiting on ads |
| C1 `120251566327090737` | ACTIVE | IN_PROCESS | pending review |
| C3 `120251566333710737` | ACTIVE | IN_PROCESS | pending review |
| C7 `120251566331180737` | ACTIVE | IN_PROCESS | pending review |

Ad set unchanged otherwise: $10/day, Facebook Feed, Stories and Reels only,
mobile, iOS, US women 40 to 65, Advantage+ audience off. No errors, no
disapprovals, $0 spent so far. The ads start delivering once Meta's review
clears them. The old Traffic campaign `120251564972370737` is still PAUSED.
The $60 account spending limit was not read back (the MCP does not expose it);
it was set by hand in Part 1 and nothing has changed it since. Readout day 7:
2026-10-23 or later.

Status 2026-10-17 (Part 7, Instagram added mid-test): Jack asked for Instagram
too. Ads Manager would not publish any edit to the ad set: error #1870194
("location targeting option that has been removed"). Cause: the targeting
carries a hidden `geo_locations.location_types` of `frequently_in` that the
UI never shows, so removing and re-adding United States there does not clear
it. Through the Meta Ads MCP, two targeting writes on ad set
`120251566264100737`: publisher platforms now Facebook and Instagram, with
Instagram stream, story and reels added to the existing Facebook feed, story
and Reels. The second write set `location_types` to `home, recent`, but Meta
merges this field, so it now reads `frequently_in, home, recent` and Ads
Manager still blocks UI edits. Each write force-paused the ad set and the MCP
reactivated it. All 3 ads went back into review (PENDING_REVIEW, no errors).
Budget, bid, schedule and audience are unchanged. The stale Ads Manager draft
was discarded.

Open: the creatives have no Instagram identity (no `instagram_user_id`, no
Page-backed account), and Part 4 saw "Instagram Account Is Missing" with
Instagram placements. If the placement breakdown shows no Instagram
impressions once review clears, Instagram is not serving. Further edits to
this ad set have to go through the API, or into a new ad set without
`location_types`. The readout covers both platforms combined; the day 1
Facebook-only result was 1 link click at $0.44.

## Question

Can Meta put Mahj Trainer in front of women 40+ who install, at under the
$2.60 break-even cost per install? Apple Ads already does $1.62 per tap
install but caps out near $3 a day (almost all of it is `mahjong trainer`), so
Meta is only worth it if it adds volume at a similar price.

This is a go/no-go for the $280 install-optimized test in `ads.md`, not a
replacement for it.

## Why a Traffic campaign

- Needs only a business portfolio, an ad account and a Facebook Page. No Meta
  developer app, no SDK build, no ATT, no privacy-label change.
- Meta's install optimizer needs about 50 installs a week to learn; $10 a day
  cannot feed it. Link-click optimization works at this budget.
- Installs are counted by App Store Connect campaign links (one `ct` per ad).

## Setup

**Campaign**
- Objective: **Traffic**. Name: `Mahj US W40+ click test 2610`.
- Advantage+ campaign budget off. Campaign spending limit: **$50** (hard cap).
- Special ad category: none.

**Ad set (one)**
- Conversion location: Website. Performance goal: **Maximize number of link
  clicks**.
- Budget: **$10/day**, start date set at launch, end date start + 5 days.
- Location: United States.
- Audience: original audience options (Advantage+ audience off), **women,
  age 40 to 65+**, no interests, no lookalikes.
- Placements: **manual**. Facebook Feed, Instagram Feed, Facebook Stories,
  Instagram Stories, Facebook Reels, Instagram Reels. Everything else off
  (Audience Network, Messenger, right column, search, in-stream), since those
  inflate accidental clicks.
- Devices: mobile only, **iOS devices only** (the link is the App Store).

**Ads (three, the least similar concepts)**

| Ad | Creative (iCloud "Mahj Meta Ads") | Headline | Link |
|---|---|---|---|
| C1 Charleston pass | `C1 charleston-pass`, 4:5 feed + 9:16 story | Practice the pass at home | `https://apps.apple.com/us/app/apple-store/id6790052126?pt=128748779&ct=meta-c1-2610&mt=8` |
| C3 Read the rack | `C3 read-the-rack-reel`, both mp4s, matching cover PNGs | Read your rack faster | `https://apps.apple.com/us/app/apple-store/id6790052126?pt=128748779&ct=meta-c3-2610&mt=8` |
| C7 Every April | `C7 every-april`, 4:5 feed + 9:16 story | New card, familiar patterns | `https://apps.apple.com/us/app/apple-store/id6790052126?pt=128748779&ct=meta-c7-2610&mt=8` |

- Primary text, alternates and description: from each folder's `copy.txt`.
- Call to action: **Download** for C1 and C3 ("Install Now" exists only in
  app-promotion campaigns), **Learn More** for C7 as written.
- Identity: the Mahj Trainer Facebook Page (and its Instagram account if one
  is linked).
- "Customize placements": 4:5 for Feed, 9:16 for Stories and Reels.
- Advantage+ creative enhancements: **all off** (same list as `ads.md`).
- All three links checked 2026-10-15: each resolves to the Mahj Trainer App
  Store page with its `ct` intact.

## Cost

$50 of spend, plus Washington sales tax on advertising (about 10%), so about
$55 all in. No other spend.

## Readout (day 7, after App Store Connect's 1 to 2 day lag)

1. **Meta (Ads Manager):** spend, link clicks, cost per link click, link CTR,
   per ad.
2. **App Store Connect:** Analytics, Acquisition, Campaigns: first-time
   downloads per `meta-c*-2610` campaign. This only counts users who share
   analytics with developers, so it is a floor.
3. **Implied cost per install** = spend / ASC campaign downloads.
4. **Cross-check:** RevenueCat new Mahj customers for the 5 test days against
   the prior 14-day daily average, minus Apple Ads tap installs for the same
   days.

## Decision rules (fixed before launch)

- **Go** to the $280 install test: implied cost per install **under $2.60**.
- **Go only if the RevenueCat lift agrees:** $2.60 to $4.00 (the ASC floor
  undercounts, so the lift decides).
- **Stop, Meta is not for Mahj:** cost per link click **over $1.00**, or
  implied cost per install **over $4.00** with no RevenueCat lift. That result
  stands; no rerun with the same ads.
- The winning ad (lowest implied cost per install) leads the install test.

## Order of work

1. Jack: business portfolio (his own, not elevatedestates.tv), ad account
   (USD, Pacific time), payment method, and a "Mahj Trainer" Facebook Page.
   These are his to create; Claude does not create accounts, accept terms or
   enter payment details.
2. Jack: builds the campaign above in Ads Manager by hand from Claude's
   steps, left as an unpublished draft, and sends screenshots.
3. Jack: says go in chat, sets the start and end dates and publishes;
   spending starts then.
4. Day 7: readout above, decision written into this file.

Update 2026-10-17 (later): review cleared and all 3 ads are ACTIVE with no
errors. **Instagram is serving** under the Page identity even without an
Instagram account: on 2026-10-17, Instagram had 30 impressions, 1 link click
and $0.60 (24 of the impressions in Reels, 6 in Feed, none in Stories), and
Facebook had 57 impressions, 3 link clicks and $0.80. Total so far: $1.40,
4 link clicks, $0.35 per link click.

Audit 2026-10-17 (about 11:20 PT, read-only, $5.37 spent, 12 link clicks):
- Spend went almost entirely to women 65+: 307 of 353 impressions and 10 of 12
  clicks. 55 to 64 had 28 impressions and 2 clicks; under 55 barely served.
  The link-click goal buys the cheapest clickers, and Meta logged only 2
  `app_store_visit` against 12 link clicks.
- C3 has no Instagram placement asset, so it serves only on Facebook and has
  had 9 impressions and $0.08. C1 has 82% of spend, so "the winning ad leads"
  can only pick C1. Left as is (a new ad resets learning).
- Only C1's creative carries an Instagram identity (`instagram_user_id`).
- No changes mid-test. The women 40+ audience is a hunch: research.md
  supports women but measures no age. The install test runs it as an A/B
  instead (below).

Install test plan from the audit (needs 1.4.1 live with SKAN/AEM, StartTrial
ranked first, and the account spending cap raised by Jack):
- Two campaigns, each $10/day for 14 days ($140 each), same ads and manual
  Facebook and Instagram feed, Stories and Reels, each with its own `ct`.
  A: women 40 to 65+, Advantage+ audience off. B: Advantage+ audience on,
  18 to 65+, all genders.
- Optimize for app installs (StartTrial once about 50 a week). Every ad gets
  the Instagram identity and Instagram assets. New ad sets built fresh via
  the API with home location only.
- Decision rule: if B's cost per install is at least 20% lower and each arm
  has 30 or more installs, drop the age and gender limits.

Status 2026-10-19 (paused early): Jack paused campaign `120251566262580737`
about 3 days in, ahead of the Oct 21 end, read back PAUSED. Final: $19.64,
1,111 impressions, 64 link clicks at $0.31 (C1 $17.65 and 62 clicks, C3
$0.42, C7 $1.57). Women 65+ took $16.55 and 59 of the clicks. Clicks pass
the $1.00 stop rule, but installs are unproven: Meta saw none without the
SDK, and the last ~$25 would only add click data. Next: the ASC
`meta-c*-2610` downloads for Oct 16 to 19 (a floor, and proof `ct`
survives App Promotion ads). The real viability test is the install test
above, once 1.4.1 (SDK) is live and Jack approves the $280 and a higher cap.

Readout 2026-10-19 (ASC Analytics, App Downloads Standard and Detailed,
daily, processing dates Oct 15 to 19, rows deduplicated across instances;
Oct 19 not processed yet). Meta spend by day: Oct 16 $0.46 (1 click),
Oct 17 $8.96 (27), Oct 18 $7.53 (25), Oct 19 $2.76 (11).

| Date | First-time downloads | Search | App referrer | Web referrer |
|---|---|---|---|---|
| Oct 14 (before) | 31 | 20 | 10 | 1 |
| Oct 15 (before) | 19 | 12 | 5 | 1 |
| Oct 16 | 12 | 7 | 4 | 1 |
| Oct 17 | 19 | 17 | 2 | 0 |
| Oct 18 | 15 | 14 | 0 | 1 |

- No `meta-c*-2610` campaign rows. Detailed's Campaign column is empty on
  every row, and Detailed drops low-count rows, so `ct` survival is still
  unproven either way.
- A Meta install arrives as App referrer (the Facebook or Instagram app) or
  Web referrer. On Oct 17 and 18, with $16.49 and 52 clicks, those two
  sources had 3 first-time downloads combined, and App referrer was already
  5 to 10 a day before launch (ChatGPT referrals). So Meta drove at most 3
  installs and likely fewer: implied cost per install of $5.50 or more.
- Total first-time downloads did not rise against Oct 14 and 15, so no lift.
- **Decision rule result: stop.** Over $4.00 per install with no lift. The
  52 clicks barely reached the App Store (most went to women 65+).
  Under the rules fixed before launch this result stands and the same ads
  are not rerun. The $280 install test is not justified by this data; it
  goes ahead only as a fresh decision of Jack's after 1.4.1 ships.
