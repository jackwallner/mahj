# Meta $20 install test (approved 2026-11-13)

Jack, in chat: "yeah do that in meta mcp and then in chrome as needed,
approved". Meta's Ads MCP was not connected, so it was built in Ads Manager
through Chrome. Rerun of the void 2026-10-27 test (`trial-test-2710.md`),
with its targeting fixed.

## Why the last test read nothing

The campaign-level **iOS 14+ campaign** toggle was off. With it off, the
only Apple store choice is "Apple App Store (iOS 13.7 or earlier)", which is
how the ad set ended up on `iOS_ver_2.0_to_14.4` and old iPads on Audience
Network. Always turn that toggle on for an iOS app campaign.

## Published 2026-11-13 ~9:10 AM PT

| Object | ID | Setting |
|---|---|---|
| Campaign "Mahj US install test 1311" | `120252014610480737` | App promotion, iOS 14+ campaign on (Mahj Trainer, app 987930193620309, SKAdNetwork), **$20 lifetime** campaign budget, highest volume |
| Ad set "US iPhone iOS17+ installs" | `120252014610460737` | Maximize app installs, Nov 13 to Nov 16 ~9 AM PT. Location US. Suggestion women 40+. Devices: iPhones only, iOS 17.0+ |
| Ad "C1 charleston-pass 1311" | `120252014610470737` | C1 4:5 plus the 9:16 as related media, headline "Practice the pass at home", C1 primary text, Install now. AI images, music, text improvements, overlays, animation off. Meta defaults left on (carousel display, enhance CTA, brightness, relevant comments) |

- **Spending limit:** the $60 account limit was fully spent. "Reset now" set
  spent to $0, so $60 of room. The $20 lifetime budget is the real cap.
- **Audience Network:** ad set level platform exclusion no longer saves
  (Meta is removing it), so both Audience Network placements are excluded
  in **Account controls** for the whole ad account. Undo there if a later
  campaign needs them.
- Status at publish: ad Processing (review).

## Creative swap 2026-11-13 ~6:25 PM PT

Jack approved swapping the C10 video in for the C1 static ("yes", in chat).
Same campaign, ad set, budget and end date. Done in Ads Manager through Chrome.

| Ad | ID | State |
|---|---|---|
| "C1 charleston-pass 1311" | `120252014610470737` | Turned off. At the swap: $3.62 spent, 166 impressions, 141 reach, 3 installs (about $1.20 each, Meta's count) |
| "C10 join-the-table video 1311" | `120252019897300737` | On, Processing (review). Single video: C10 9:16 plus the 4:5, C10 primary text, headline "Learn mahj at home", description "American Mah Jongg practice", Install now |

- C10 settings: text improvements, video touch-ups, AI images, video
  slideshow, carousel and video effects off. Left on: relevant comments,
  enhance CTA, multi-advertiser ads, app store details.
- About $16.38 of the $20 is left for C10.
- The readout now splits by ad: C1 covers Nov 13 9:10 AM to 6:25 PM PT, C10
  the rest. ASC and RevenueCat can't split by ad, so judge each ad on Meta's
  installs and the whole test on ASC downloads.

## Creative swap 2026-11-14 ~10:40 AM PT

Jack approved swapping C11 in for C10 ("yes", in chat). Same campaign, ad
set, budget and end date. Done in Ads Manager through Chrome by duplicating
the C1 ad (same static install setup) and replacing its media and text.

| Ad | ID | State |
|---|---|---|
| "C10 join-the-table video 1311" | `120252019897300737` | Turned off. At the swap: $4.93 spent, 193 impressions, 6 clicks, 1 install (Meta's count) |
| "C11 practice-charleston static 1311" | `120252028880770737` | On, in review. C11 4:5 as primary media with the C11 9:16 in the Vertical slot, C11 primary text, headline "Practice mahj at home", Install now. No related media (C1's was removed), AI images and the five creative enhancements off. Meta defaults left on as on C1 (essential enhancements, carousel display) |

- Campaign at the swap: $8.63 spent, 7 installs (C1 6, C10 1), so about
  $11.37 is left for C11.
- C1 stays off, so the remaining budget reads as a clean C11 run. C1 and C11
  can be compared on Meta's installs per dollar; C1 had $3.70 for 6.
- The upload dialog pre-ticks "publish this upload to current active ads as
  related media" (C10 was ticked). Untick it, or the new images go onto the
  live ad too.

## Readout (Nov 17, then Nov 20 for ASC and SKAN lag)

1. Meta: spend, impressions by device and placement (confirm iPhone, no
   Audience Network), installs (SKAN), cost per install.
2. ASC first-time downloads, US, Nov 13 to 16 against the 7 days before.
3. RevenueCat new trials over the same days.

A pass is installs that show up in ASC at roughly $5 or less each.
Hold the 1.4.4 release (Meta SDK removed) until the readout.
