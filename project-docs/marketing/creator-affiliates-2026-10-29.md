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
| [@themahjonghouse](https://www.instagram.com/themahjonghouse/) | 26K | Houston + franchises | Luxury set brand with lesson locations; "Mahjong Made Simple" teaching series |
| [@mahjwithsusan](https://www.instagram.com/mahjwithsusan/) | 16K | | Susan Siegel, beginner and joker tips on the current card |
| [@holymahj](https://www.instagram.com/holymahj/) | 15K | Charleston + Chicago | Anne and Caroline, pop-ups, leagues, beginner classes, Mahj Point retreat |
| [@bamgoodtime](https://www.instagram.com/bamgoodtime/) | 14K | Columbus, GA | Custom tiles, ELO ranked leagues, events |
| [@palmbeachmahjong](https://www.instagram.com/palmbeachmahjong/) | 8.4K | Palm Beach | Founder Giuliana; lessons, open play, events; a 1M-view first-lesson reel |
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

### Sent log

DMs go from TikTok @mahjtips as three short messages (intro, code link, feedback ask). After those three, TikTok rejects anything more until they accept the request ("You can only send up to 1 message before this user accepts your message request"), so an unanswered TikTok thread has no room for a follow-up.

| Date | Creator (TikTok) | Personal line |
|---|---|---|
| 2026-10-29 | @mahjwithsusan (2.5K) | "the one tile I never discard in the Charleston" video |
| 2026-10-29 | @palmbeachmahjong (3.7K, Oh My Mahjong instructor) | "one word every mahjong player should know" video |
| 2026-10-29 | @holymahj (461; 15K on IG) | Nov 2 beginner class |
| 2026-10-29 | @bamgoodtimemahjong (1.3K) | "happy first mahjong" post |
| 2026-10-29 | @themahjonghouse (3.5K, founder Stacey White, teacher programs) | Mahjong Made Simple card video |

| 2026-11-01 | @hoosier.mahjong.lady (852, mutual, traveling instructor in Indianapolis) | wall as one long dragon tail video |
| 2026-11-01 | @mamamahjong (133, mutual) | five sets in five months post |
| 2026-11-01 | @lets.learn.mahjong (86, daily lesson account) | hand-selection tip: missing tiles over card value |
| 2026-11-01 | @themahjongfairy.htx (2.1K, Landy, Houston) | American Mahjong 101 bonus lesson on calling a discard (accepted the request and said thanks, code sent the same day) |

Follow-ups to all five 10-29 creators were tried once on 2026-11-04 and TikTok rejected every one, so none was delivered: none of the five has accepted or replied. Don't retry them. The 11-08 follow-up for the 11-01 batch only works in threads they've accepted.

Accounts that don't follow @mahjtips back get only the first message until they accept the request; TikTok drops the rest. On 2026-11-01 these got the intro only, so the code and feedback ask go out once they accept:

| Date | Creator (TikTok) | Personal line |
|---|---|---|
| 2026-11-01 | @thehappymahjongteacher (9.7K, Taylor, Fort Worth) | "can you spot the error" line reading video |
| 2026-11-01 | @mahjongwithandrew (8.7K, Lowcountry SC instructor) | pop quiz: what's wrong with the line 4 hand |
| 2026-11-01 | @mahj.the.day (346, Morristown and Ocean City NJ) | bachelorette party, rookie to thriving (accepted; code and feedback ask sent 2026-11-04) |

Since 2026-11-04, a creator who isn't a mutual gets one combined DM (intro, code link and feedback ask together), because only one message goes through until they accept.

| Date | Creator (TikTok) | Personal line |
|---|---|---|
| 2026-11-04 | @sooner_mahj (568, mother and daughter teachers, OKC; follows us) | wrapped up their fall league |
| 2026-11-04 | @blooms.bams (1.9K, instructor, Rockingham NC) | "I didn't think I needed another book about mahjong" post |
| 2026-11-04 | @mahjongonmain (152, classes in Union County NC) | sat down to answer league questions |
| 2026-11-04 | @beehive.bam (130, new players; follows us) | impromptu Halloween game post |
| 2026-11-04 | @mahjgurl (602, Liz, certified instructor, Chicagoland) | building walls since '88 (from her bio) |
| 2026-11-06 | @littlemissmahjong (825, Montreal, teaches American and Hong Kong) | how what helps you learn can eventually hold you back |
| 2026-11-06 | @themahjclubs (440, Scottsdale club and lessons) | "Joker this, Charleston that" |
| 2026-11-06 | @mahjongwithamy (28, Sonoma and Marin instructor) | Moira Mahjong tile unboxing |
| 2026-11-06 | @mahj.in.color (55, mutual, lifestyle page for women of color) | when you can and cannot use a joker |
| 2026-11-06 | @pearl.loves.mahjo (53, mutual, Franklin TN) | hosting a first table in the Franklin Mahjong Open |

TikTok web DMs from the social Chrome work (profile > Message, Return sends): all five showed as sent in the phone inbox.

Next up, about 5 a day: @get.your.mahhon (224, mutual, has only traded wave stickers with us, no bio or caption to write a line from), @southern.mahj.clu (commented 11-06, pitch next), @stefmahj (660, Fripp Island, "tips"), @hostmahj (909, table inspo), @flamingo.mahj (635, lessons, but recent posts are all mats), @mahjong.haus.na. @andersruffdesignco (2.7K) follows us but is a product brand.

| Date | Creator (TikTok) | Personal line |
|---|---|---|
| 2026-11-12 | @thesocialparlor (1.2K, mutual, lesson and open play venue, Bryant AR; followed us 11-11) | tour of The Social Parlor |
| 2026-11-12 | @southern.mahj.clu (1.9K, Southern Mahj Club, teaches American) | beginner series building a hand from every section |
| 2026-11-12 | @stefmahj (697, Stephanie) | Fripp vacation post teaching Wade to play |
| 2026-11-12 | @hostmahj (979) | dreaming about telling new friends the best starter supplies |

All four were one combined DM (intro, code link, feedback ask) and show as sent in the web inbox. TikTok's web Message button sometimes needs a second click before the thread opens. Comments the same day on Southern Mahj Club (369 series), The Social Parlor (Lotus Cove mat), Host Mahj (starter supplies) and Stephanie (mat giveaway), each confirmed on the page. All four followed and one video each liked from the iPhone app the same day (web likes and follows don't stick), each confirmed on screen.

TikTok as of 11-12 8:45 AM PT: no new replies in any pitched thread, no unanswered viewer comments. About 12 new followers in two days, including @mahjongmouse (tile and mat brand, not a pitch). Still next: @flamingo.mahj, @mahjong.haus.na; @get.your.mahhon has nothing to write a line from.

Warmer leads seen 11-04 in the phone app's inbox suggestions, showing "Follow back" (display names, handles and fit not checked yet): MahjMeCrazyLA, Bougie Bams Mahjong, 3BeeMahj, Menace Mahjong Society, pamperedtileco. Check each before pitching; any that sell a competing app or course get skipped.

Replies as of 11-04 5:51 PM PT: none to the 11-04 batch (@sooner_mahj has seen it, the app shows the other four as sent). Landy (The Mahjong Fairy HTX) replied on 11-01 that they'd check it out and report back. Mama mahjong has not replied; the item the web couldn't display is a wave sticker on our side of the thread. No Instagram replies or requests.

Followed 11-04 in the phone app, verified by Following going from 21 to 29: @sooner_mahj, @beehive.bam, @andersruffdesignco, MahjMeCrazyLA, 3BeeMahj, Bougie Bams Mahjong (all six followed us first), @pearl.loves.mahjo and @mahj.in.color (new mahj accounts, not yet pitched).

Replies as of 11-06 8:30 AM PT:

- @lets.learn.mahjong (90 followers) said thanks and asked what working together would look like. Answered: try it first, then one post labeled as an ad for a flat fee; asked their rate. They declined at 8:22 AM because they're building their own mahjong course and aren't taking partnerships in this space, but want to stay in touch. Thanked them; no fee was offered. Don't pitch them again.
- @mahjgurl (Liz) accepted, thanked us and will send feedback. Thanked them back and followed.
- MahjMeCrazyLA, Bougie Bams Mahjong, 3BeeMahj and Mahj In Color show only a wave sticker, nothing to answer. None of the other 11-04 or 11-01 threads has replied.

Engagement on 11-06: comments on Gilded Bam, The Mahjong Fairy HTX, @southern.mahj.clu, Mahj In Color and little miss mahjong, plus a reply to @lesmclean143 on our own post. Web comments survive a reload. Likes in the phone app stick (Gilded Bam, Southern Sparrow, janelledewolf). One web like showed no change in count and a second couldn't be read, so treat web likes as unproven. Followed @mahjgurl and Menace Mahjong Society in the app.

Instagram DMs go from @mahjtips on instagram.com in Chrome (same three messages; the profile's Message button opens a chat panel, Return sends).

| Date | Creator (Instagram) | Personal line |
|---|---|---|
| 2026-10-30 | @marchesamahjong (6.3K, Arabella) | Mom & Daughter Mahjong event |
| 2026-10-30 | @rockymountainmahjong (5.1K, Avery Burns) | taught herself from a book, 2nd at the 2024 world championship two years later |
| 2026-10-30 | @bluetigermahjclub (5.0K, Lisa Oleson) | Bams & Bubbly champagne tiles post |
| 2026-10-30 | @queencitymahjong (4.6K) | "why one lesson instead of three" post |

Skipped @abbyaroundthetable: her profile needs a sign-in to read, so there was no post to write the line from. All four got their one follow-up on 2026-11-06 (still no replies), so let them go after this.

New on Instagram, one combined DM each (followed all five, verified after reload):

| Date | Creator (Instagram) | Personal line |
|---|---|---|
| 2026-11-06 | @mahjongoc (4.8K, Jodie, Orange County) | "come with friends and leave your family" |
| 2026-11-06 | @southshoremahjong (3.4K, Gretchen, Boston South Shore) | Fall League filling up |
| 2026-11-06 | @mahjongsocialatl (2.8K, Atlanta) | "less class holiday party sign up geniuses" |
| 2026-11-06 | @thecharlestoncoach (2.2K, Gaithersburg, MD) | mahjong at the pumpkin patch |
| 2026-11-06 | @mrsmerrimanmahjong (1.9K, Allison, Charlotte) | teaches assisted play (from their bio) |

Skipped @atlanta_mahjong_mentors: their latest post says they're slowing down. Next on Instagram: @mahjonginthesouth, @themahjongsocialchatt, @mahjongatdeenas. Instagram has no replies or requests as of 11-06.

| Date | Creator (Instagram) | Personal line |
|---|---|---|
| 2026-11-12 | @mahjonginthesouth (1.4K, Sandi, Jacksonville) | "I want everyone to play mahjong" (from their bio) |
| 2026-11-12 | @themahjongsocialchatt (1.8K, Chattanooga) | Mahj Mash at Bleu Fox Cheese |
| 2026-11-12 | @mahjongatdeenas (3.3K, San Diego North County) | Tuesday open play at Weir Beer |

All three followed, liked and commented, verified after reload. @rockymountainmahjong (Avery) replied on 11-07 that they're stepping away from mahjong for their health; thanked them on 11-12 and said the code is theirs whenever they return. Don't pitch them again. No Instagram requests or comments to answer. YouTube has no unanswered comments.

Instagram engagement on 11-06: comments and post likes on @mahjongoc, @mahjongsocialatl and @thecharlestoncoach, plus a like on @southshoremahjong. All verified after reload.

YouTube on 11-06: no DMs exist there, and our channel has no comments to answer. Commented, liked and subscribed on Ladies That Mahj (32.5K), Jodella's Mahjong Channel (25) and Roundwell Mahjong (271), and liked West Georgia Mahjong. All verified after reload. Skipped channels that look mass-produced.

## What a sponsored post is worth

A trial is worth about $4.60 on first-month cash (51% trial to paid at about $9 first-30-day proceeds, 2026-10 numbers) and about $9 if payers stay a second month. Apple Ads paid about $9.35 per trial (Oct 13 to 19, small sample). Assuming 1% of viewers install (a guess, not measured) and 26% of installs start a trial, 1,000 views is worth about $12 to $23. Rule of thumb: up to $15 per 1,000 average views, with a $10 floor. Use a `ct=<handle>` link so the assumption gets measured. @lets.learn.mahjong averages about 240 views, worth $3 to $6, so anything above the floor is buying the relationship and reusable content.

Jack, 2026-11-06: state an offer as price per view, since a small flat number can read as cheap when it's actually above value. For a 240-view account: "I budget about $15 per 1,000 views, so your average of about 240 would come to about $4. I'd rather make it a flat $10." Ask for reuse rights in the same message.

### The DM

> hi [first name]! [line about their post], that's exactly the stuff I built my app around. it's called Mahj Trainer, made it on paternity leave between baby naps haha
>
> here's a free lifetime code: [redeem link]
>
> I'd love to know what you think so I can improve it! and if you like it I'd love to sponsor a post

The opening line has to come from something they actually posted (a Charleston tip, a joker question, a beginner class). It's what shows the DM was written for them.
