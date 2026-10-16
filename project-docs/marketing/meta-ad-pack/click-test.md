# Meta $50 click test (planned, not launched)

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
