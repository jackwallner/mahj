# Mahj acquisition plan

Status as of 2026-08-09: Apple Ads campaigns are staged but paused. No ad
spend is active. Pricing is still at the original level. Do not enable the
campaigns until the new pricing cohort has produced usable revenue data.

## Objective

Prove that Mahj can support paid acquisition at a higher price before buying
installs. The primary audience hypothesis is US women age 50+, with an
all-eligible control to test whether demographic narrowing improves economics.

## Pricing gate

Current product prices:

- Monthly: $1.99
- Yearly: $9.99
- Lifetime: $29.99

Proposed two-times test prices:

- Monthly: $3.99
- Yearly: $19.99
- Lifetime: $59.99

This preserves the existing relative price ladder. Keep the same product IDs
and change prices in App Store Connect. Preserve the current subscription price
for existing subscribers. Apple may send price-change notices or require
consent depending on storefront and increase size. See [Apple's subscription
pricing rules](https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions).

When the price changes, update all price-bearing surfaces together:

- App Store Connect subscription and lifetime prices
- The fallback values in `MahjTrainer/Views/PaywallView.swift`
- English and localized App Store descriptions under `fastlane/metadata/`
- `docs/index.html` and any other marketing copy

StoreKit and RevenueCat should keep the existing product IDs and entitlement.
The price change should not create a new entitlement or product family.

## Current monetization baseline

The observed baseline is provisional, not true LTV:

- 39 trial starts
- 6 paid conversions, currently annual purchases
- 28 trials still pending
- $59.94 gross revenue in the measured historical period
- $41.94 proceeds in that period
- $59.94 / 39 = approximately $1.54 gross revenue per trial start
- 6 / 39 = approximately 15.4% observed trial-to-paid conversion

If the annual price doubles from $9.99 to $19.99, paid conversion could fall to
approximately 7.7% and still produce the same observed gross revenue per trial
start, assuming the same plan mix and ignoring renewals. This is why the price
test is worth running before ads.

## Price-test measurement

Hold the new price for at least 30 to 45 days and collect at least 30 new trial
starts. Prefer 50 or more trial starts and 8 or more paid conversions before
calling the result decision-grade.

Track separate cohorts based on the price-effective date:

```text
trial start rate       = trial starts / installs
trial-to-paid rate     = paid conversions / trial starts
net revenue per trial  = net proceeds / trial starts
net revenue per install = net proceeds / installs
paid CAC               = ad spend / paid conversions
```

Use 30 to 45 day net revenue as the initial payback measure. Annual renewal
LTV cannot be proven until the annual cohort reaches its renewal date, so label
the early result as realized revenue or payback, not final LTV.

Do not start ads unless the new-price cohort supports at least a $1.50 CPI on
net revenue per install. Start with a $1.00 Apple Ads target and retain $1.50
as the absolute ceiling. Paid ratings or organic ranking lift are secondary
outcomes and must not be counted as guaranteed revenue.

## Apple Ads staging

The account is US dollar, pay-as-you-go. Advanced Search Results charges for
taps, not purchases. A bid is a maximum cost per tap, and the actual price may
be lower. The CPA goal is an install target, not a paying-subscriber CAC. See
[Apple's bid guidance](https://ads.apple.com/app-store/help/bids-and-budget/0062-set-and-adjust-bids)
and [CPA cap guidance](https://ads.apple.com/app-store/help/bids-and-budget/0063-set-and-adjust-your-CPA-cap).

All campaigns target US iPhone Search Results. Apple Ads marked the app
eligible on iPhone and ineligible on iPad. The 50+ groups use age 50 to 65+,
gender female, and exclude existing Mahj downloaders (`6790052126`).

| Campaign | Campaign ID | Daily budget | Structure | Status |
| --- | ---: | ---: | --- | --- |
| Mahj US Core 50plus Women | `2144426215` | $10 | 26 exact core keywords, $0.50 default bid | Paused |
| Mahj US Discovery 50plus Women | `2144427100` | $4 | Search Match plus 26 broad discovery keywords, $0.30 default bid | Paused |
| Mahj US Core All Eligible Control | `2144427101` | $4 | 26 exact core keywords, no age or gender filter, $0.50 default bid | Paused |
| Mahj US Competitor 50plus Women | `2144425775` | $1 | 5 competitor exact keywords, $0.35 default bid | Paused |
| Mahj US Brand 50plus Women | `2144427588` | $1 | 4 brand exact keywords, $0.25 default bid | Paused |

The staged campaigns use a $1.50 CPA goal. Before activation, change that goal
to the proven acquisition ceiling from the new-price cohort. The staged daily
total is $20, with a 14-day maximum of approximately $280. The account rejected
lifetime budgets, so the cap is implemented with daily budgets and a fixed end
date.

Campaign-level negative keywords are:

- Broad: `mahjong solitaire`, `mahjong connect`, `tile match`, `tile matching`,
  `3d mahjong`, `mahjong dimensions`, `mahjong multiplayer`, `online mahjong`
- Exact: `mahjong games`

The initial keyword structure follows Apple's brand, category, competitor, and
discovery campaign pattern. See [Apple's campaign structure
guidance](https://ads.apple.com/app-store/best-practices/campaign-structure).

## Activation sequence

The current staged dates are placeholders. After the price gate is met, extend
the campaigns to a fresh 14-day window before enabling them.

1. Enable `Mahj US Core 50plus Women` at $10/day.
2. Enable `Mahj US Core All Eligible Control` at $4/day.
3. Leave Discovery, Competitor, and Brand paused for the first seven days so
   the core audience comparison is readable.
4. After seven days, review search terms, CPI, trial-start rate, and paid
   conversion. Add Discovery or Competitor spend only when the search-term data
   supports it.

The initial live test therefore spends at most $14/day. Stop or reduce bids if
CPI exceeds $1.50, if cost per trial start is not supported by new-price
revenue, or if the 50+ cohort materially underperforms the all-eligible control.

## Astro keyword snapshot

US Astro data retrieved 2026-08-09 for the live app, App Store ID `6790052126`.
Popularity and difficulty are Astro's scores, with higher values indicating
more search volume or competition respectively.

| Keyword | Current rank | Popularity | Difficulty |
| --- | ---: | ---: | ---: |
| `mahjong training` | #5 | 5 | 44 |
| `mahjong lessons` | #8 | 5 | 56 |
| `mahjong card practice` | #10 | 5 | 68 |
| `mahjong hand practice` | #10 | 5 | 63 |
| `american mahjong practice` | #11 | 8 | 53 |
| `american mah jongg` | #12 | 5 | 48 |
| `mahjong practice` | #13 | 32 | 58 |
| `learn mahjong` | #14 | 24 | 53 |
| `mahjong trainer` | #19 | 5 | 11 |
| `nmjl` | #10 | 5 | 33 |
| `charleston mahjong` | #33 | 5 | 59 |
| `mahjong strategy` | #74 | 5 | 66 |
| `mahjong for beginners` | #85 | 5 | 53 |
| `mahjong app` | #177 | 5 | 72 |
| `american mahjong` | Not top 100 | 8 | 52 |

Astro suggestions worth testing include `mahjong for seniors` (popularity 29,
difficulty 79) and `real mah jongg` (popularity 39, difficulty 50). Avoid
scaling broad terms such as `mahjong`, `majong`, `mahjong solitaire`, `free
mahjong games`, and `joker`, which have higher volume but poor or ambiguous
intent.

## References

- [Apple subscription price changes](https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions)
- [Apple pricing and proceeds](https://developer.apple.com/help/app-store-connect/reference/pricing-and-availability/app-pricing-and-availability/)
- [Apple Ads campaign structure](https://ads.apple.com/app-store/best-practices/campaign-structure)
- [Apple Ads bids](https://ads.apple.com/app-store/help/bids-and-budget/0062-set-and-adjust-bids)
- [Apple Ads CPA caps](https://ads.apple.com/app-store/help/bids-and-budget/0063-set-and-adjust-your-CPA-cap)
- [Apple Ads match types](https://ads.apple.com/app-store/help/keywords/0059-understand-keyword-match-types)
- [Apple Ads negative keywords](https://ads.apple.com/app-store/help/keywords/0060-use-negative-keywords)
- [Apple Ads audience settings](https://ads.apple.com/app-store/help/ad-groups/0021-modify-audience-settings)
