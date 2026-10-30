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
2. **Insert Affiliate (RevenueCat partner).** Per-creator deep links, SDK tags the RevenueCat customer, commission on purchases and renewals, creator dashboard. Needs the SDK in a build plus Associated Domains for its links. Pricing (insertaffiliate.com, Oct 2026): Free covers 2 affiliates and 100 transactions; Starter is £20/mo plus 10% of affiliate revenue for up to 5 affiliates; Growth is £70/mo plus 8% for up to 25. Creator commissions are paid on top (Stripe Connect payouts). The docs don't say how a link survives a fresh App Store install, so expect some referrals to go unattributed. WinWinKit is the code-based alternative.
3. **Homegrown.** Per-creator link opens `mahj://ref/<creator>`, app stores it as a RevenueCat subscriber attribute, webhooks give trial, conversion and renewal per creator. No UI change, so the frozen trial flow is untouched. A typed "creator code" field on the paywall would touch the trial flow and needs Jack's go-ahead.

## Offer to creators

- Pay on trial-to-paid conversion, not trial start (trial starts are free to fake). A share of first-year proceeds per paying subscriber, plus a small flat bounty per trial if a creator insists.
- Free lifetime Mahj+ for the creator, sent as a one-time offer code link (below).
- Pitch to teachers: free "homework" for their students between lessons; the app teaches how to read the card, never reprints it, so it does not compete with their classes.
- FTC: creators must disclose (#ad or paid-partnership label).

## Creator codes

- ASC offer "Mahj+ Lifetime Creators 2026-10" (`dc18b396-b7ae-4266-994f-b52d8fc44dd4`) on `com.jackwallner.mahj.lifetime`: free in all 175 territories, any customer. Batch `e6778bcd-7829-4431-aa72-c5f5ac6cfa55`, 500 one-time codes (Apple's minimum batch), expire 2027-04-28.
- Codes and redeem links live in `creator-codes.csv` beside this file. It is gitignored because the repo is public; never commit it. Fill in `creator` and `sent` when a link goes out, one code per creator.
- Link format: `https://apps.apple.com/redeem?ctx=offercodes&id=6790052126&code=CODE`. Opens the App Store with the code filled in; the creator taps Redeem.
- Separate from "Mahj+ Lifetime Gift 2026-10" (`be413994-...`, 500 codes, 2026-10-03), whose recipients aren't recorded. Keeping the creator batch apart means creator redemptions show up under their own offer name in ASC and RevenueCat.

## Outreach plan: small teachers first

The big Tier 1 accounts wait until a few small teachers have said yes. Follower counts below were read from each public Instagram profile on 2026-10-29.

### Wave 1: teachers who post lessons online (reach past their own city)

| Account | Followers | Where | Notes |
|---|---|---|---|
| [@themahjonghouse](https://www.instagram.com/themahjonghouse/) | 26K | Houston | Stacey White, beginner and refresh lessons |
| [@mahjwithsusan](https://www.instagram.com/mahjwithsusan/) | 16K | | Susan Siegel, beginner and joker tips on the current card |
| [@holymahj](https://www.instagram.com/holymahj/) | 15K | Charleston, SC | Anne and Caroline, lessons and Mahjong Mondays |
| [@bamgoodtime](https://www.instagram.com/bamgoodtime/) | 14K | Fort Worth | Beginner lessons, open play, leagues |
| [@palmbeachmahjong](https://www.instagram.com/palmbeachmahjong/) | 8.4K | Palm Beach | Step-by-step setup and deal tutorials |
| [@marchesamahjong](https://www.instagram.com/marchesamahjong/) | 6.3K | Houston | Arabella Hibbert, lessons and parties |
| [@rockymountainmahjong](https://www.instagram.com/rockymountainmahjong/) | 5.1K | Denver | Lessons, leagues, tournaments |
| [@bluetigermahjclub](https://www.instagram.com/bluetigermahjclub/) | 5.0K | Chicago suburbs | Lisa Oleson, NMJL card lessons |
| [@queencitymahjong](https://www.instagram.com/queencitymahjong/) | 4.6K | Charlotte | Weekly group lessons |
| [@abbyaroundthetable](https://www.instagram.com/abbyaroundthetable/) | 4.1K | | Tile-identification tutorials, also on TikTok; check she teaches American |

### Wave 2: local teachers (the app is homework for their students)

| Account | Followers | Where |
|---|---|---|
| [@mahjongoc](https://www.instagram.com/mahjongoc/) | 4.5K | Orange County, CA (claims 3,200+ taught) |
| [@southshoremahjong](https://www.instagram.com/southshoremahjong/) | 3.4K | Boston South Shore |
| [@mahjongatdeenas](https://www.instagram.com/mahjongatdeenas/) | 3.2K | San Diego North County (Bespoke affiliate) |
| [@mahjongsocialatl](https://www.instagram.com/mahjongsocialatl/) | 2.8K | Atlanta |
| [@thecharlestoncoach](https://www.instagram.com/thecharlestoncoach/) | 2.2K | Gaithersburg, MD |
| [@mrsmerrimanmahjong](https://www.instagram.com/mrsmerrimanmahjong/) | 1.9K | Charlotte |
| [@themahjongsocialchatt](https://www.instagram.com/themahjongsocialchatt/) | 1.8K | Chattanooga |
| [@atlanta_mahjong_mentors](https://www.instagram.com/atlanta_mahjong_mentors/) | 1.5K | Atlanta (101/102/103 course) |
| [@mahjonginthesouth](https://www.instagram.com/mahjonginthesouth/) | 1.4K | Jacksonville |

### Cadence

- About 5 DMs a day, wave 1 first. Look at their last few posts and write the one personal line before sending.
- The code link goes in the first DM, so it's one message. If replies are scarce, try asking first and sending the link after they answer.
- Log the creator and date in `creator-codes.csv` when a link goes out. One follow-up after a week, then let it go.
- A yes on sponsoring gets a flat fee per post (amount is Jack's call) and a campaign link (`ct=<handle>`) for our own tracking.

### The DM

> hi [first name]! I'm Jack, I made an app called Mahj Trainer so newer players can practice between games. been building it on paternity leave between baby naps haha
>
> [one line about a recent post of theirs]
>
> here's a free lifetime code if you want to try it, one tap and it's yours: [redeem link]
>
> if you like it I'd love to sponsor a post, and if it's missing anything your students need I'd really like to know
