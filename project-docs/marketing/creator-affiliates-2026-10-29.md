# Creator affiliate shortlist (2026-10-29)

Goal: American mah jongg creators paid per result (trial or paid conversion), nothing up front.

## Shortlist

Instagram counts are HypeAuditor estimates (Oct 2026). Verify on the profile before pitching.

### Tier 1: teachers with a beginner audience (best fit)

| Account | Followers | ER | Why |
|---|---|---|---|
| [@larasmahjongedit](https://www.instagram.com/larasmahjongedit/) Lara, "American Mahjong Teacher" | 118K | 2.7% | Explicitly American, teaching-first |
| [@ladiesthatmahj](https://www.instagram.com/ladiesthatmahj/) Bucks County Mahjong + Online Mahjong Course | 64K | 4.0% | Highest engagement; sells a course, app is student homework |
| [@mahjongmolly](https://www.instagram.com/mahjongmolly/) Molly Hardy | 102K | 1.1% | Trains instructors (Mahjong Line partner), card-strategy content |
| [@mahjongwithlo](https://www.instagram.com/mahjongwithlo/) Lori Rosebrough | 86K | 2.4% | Teacher account |
| [@themarvelousmrsmahjong](https://www.instagram.com/themarvelousmrsmahjong/) | 71K | 2.2% | Check fit |
| [@mahjongcollective_](https://www.instagram.com/mahjongcollective_/) Lynn Cooper | 53K | 2.3% | Check fit |
| [@mahjongandmagnolias](https://www.instagram.com/mahjongandmagnolias/) (Nashville) | 55K | 2.4% | Lessons/events |
| [@feelslikemahjong](https://www.instagram.com/feelslikemahjong/) | 55K | 2.5% | Check fit |

### Tier 2: lifestyle or comedy reach

- [@mywifeplaysmahjong](https://www.instagram.com/mywifeplaysmahjong/) Brent R, 108K: husband-POV comedy, broad reach.
- [@pagesandtiles](https://www.instagram.com/pagesandtiles/) Belle, 54K, 3.0% ER: books + mahj.

### Tier 3: small, high-trust niche channels

- Tile Talk (podcast + YouTube, Christina, Elizabeth, Marshall): covers the card, Charleston, beginners.
- The Order of the Tile (Prim Proper newsletter + podcast).
- Mahj Tile Talk (Substack; sells coaching).
- Debbie Barnett's Beginner's Series (YouTube), recommended by ilovemahj as the starting point.

### Skip

Brand accounts that sell their own product or app: Oh My Mahjong (245K, also sells cards and teaching), The Mahjong Line (122K, runs its own ambassador program), Bespoke Mahjong, boutiques, jewelry and phone-case brands.

## Paying per result

Apple has no App Store affiliate program, and Apple offer codes do not work for per-creator payouts: StoreKit and RevenueCat only return the offer reference name, not the code, and each subscription is capped on active offers.

Options, cheapest first:

1. **App Store campaign links (`ct=lara`), no code change.** ASC App Analytics reports page views, downloads and proceeds per campaign. Counts only users who share analytics with developers, so it undercounts and can't see trial starts. Fine to start pay-per-download or a goodwill bounty; weak for a contract.
2. **Insert Affiliate (RevenueCat partner).** Per-creator deep links, SDK tags the RevenueCat customer, commission on purchases and renewals, creator dashboard. Needs the SDK in a build. Paid tool (listings say about $20 to $200/mo); confirm on their site. WinWinKit is the code-based alternative.
3. **Homegrown.** Per-creator link opens `mahj://ref/<creator>`, app stores it as a RevenueCat subscriber attribute, webhooks give trial, conversion and renewal per creator. No UI change, so the frozen trial flow is untouched. A typed "creator code" field on the paywall would touch the trial flow and needs Jack's go-ahead.

## Offer to creators

- Pay on trial-to-paid conversion, not trial start (trial starts are free to fake). A share of first-year proceeds per paying subscriber, plus a small flat bounty per trial if a creator insists.
- Free lifetime Mahj+ for the creator (RevenueCat promotional entitlement).
- Pitch to teachers: free "homework" for their students between lessons; the app teaches how to read the card, never reprints it, so it does not compete with their classes.
- FTC: creators must disclose (#ad or paid-partnership label).
