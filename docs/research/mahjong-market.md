# American Mah Jongg Training App — Market & Design Research

Research for Mahj Trainer (iOS flashcard/drill app teaching the NMJL card to beginners, target demo women 50+ plus younger newcomers). Compiled 2026-07-12.

---

## Competitor profiles

### I Love Mahj (ilovemahj.com) — the category leader
Browser-based (no app install) platform for playing and learning American Mah Jongg on the official NMJL card. Not primarily an App Store product — it's a web SaaS, which matters: it competes with Mahj Trainer for the same "I want to learn the card" search intent but via a completely different distribution channel (Google/word of mouth, not App Store).
- **Pricing:** 2-week free trial (no credit card needed per one review, though another source says 3-week trial), then **$6/mo or $60/yr**. No steep annual discount (accused of this in reviews).
- **Features:** live multiplayer with real people or "intelligent bots," in-person game/table organizer tools (RSVP, table assignment), "Exercise Room" practice mode, hand/Charleston drills, stats/leaderboards, retail shop for physical tile sets and cards.
- **Design/UX:** described in third-party reviews as "modern and intuitive," light color scheme, navy nav accents, clean hierarchy, generous whitespace. Tone is friendly, enthusiastic, community-first ("Build your Mah Jongg Community"), not salesy.
- **Praise:** best-in-class onboarding for total beginners; tutorials + practice mode called "incredibly helpful"; considered the default/largest player base for live online American Mah Jongg.
- **Complaints:** subscription-only with no permanent free tier; live player pool thins during off-hours; no discount deep enough to feel like a "steal" on the annual plan.
- Note: the "I Love Mahjong" iOS App Store listing (id594713410, John Rouda, 3.7★/374 ratings, free, mahjong-solitaire style) appears to be an **unrelated tile-matching solitaire game that squats on similar branding**, not the ilovemahj.com product — worth knowing since a searcher looking for "I Love Mahj" on iOS currently lands on the wrong app.

### Eight Bam / "American Mahjong Practice" — closest functional analog
iOS-only (also Android) solo-practice app, the most direct functional precedent for Mahj Trainer's drill-based approach.
- **Pricing:** free download with IAP — **$3.99/mo** "All Features," or a one-time **$14.99–$17.99 "2026 Hands, All Features"** non-renewing unlock. This one-time option was added *because users asked for it* (see complaints below).
- **Rating:** 4.9★ from ~22,000 ratings — very high volume and score, showing strong product-market fit for the practice-app category.
- **Features:** shows all possible winning hand combos against your current tiles, AI opponents at adjustable difficulty, real-time hand-validity feedback, replay, daily challenge + leaderboard for subscribers, works offline, house-rules toggle.
- **Praise:** "invaluable" for learning rules and pattern recognition; helped users get measurably better at Charleston and hand recognition; responsive developer support (called out by name in a review).
- **Complaints:** touch controls "hyper sensitive" (accidental discards), concealed-hand tiles not hidden properly, app resets/loses state if phone is set down for a few minutes, subscription cost adds up for sporadic players (drove the one-time-purchase SKU).

### Real Mah Jongg (Mattron Entertainment)
iOS app for live/AI play with the official card and alternates (Big Card, Mah Jongg Press).
- **Pricing:** 2-week free trial then **$6.99/mo**.
- **Rating:** 4.7★ / 5.3K ratings.
- **Features:** hand suggestions, scorecard, voice/text chat, customizable tile art and game speed.
- **Praise:** good for practicing "at my own speed between weekly games with friends."
- **Complaints:** AI opponents feel rigged/repetitive ("computer seems to constantly win with same hands — quints, concealed hands, NEWS, and 2020"), which erodes trust in the practice value.

### The Mahj App (Tabletop Ritual LLC) — direct teaching-only competitor
The closest positioning match to Mahj Trainer: explicitly "the only mobile app built specifically to teach American Mahjong," not a gameplay app.
- **Pricing:** free download, Premium **$3.99/mo or $29.99/yr** (App Store listing) — some marketing copy also cites a flat **$3.99** price, so their pricing messaging is inconsistent across channels.
- **Rating:** 4.9★ but only ~7 ratings — very early/low traction despite strong scores.
- **Features:** tile basics/terminology/full rules reference, Charleston instruction, table etiquette, searchable Q&A ("Just Ask Mahj"), community forum ("Strategy Lab"), teacher directory, Daily Challenge with streaks, two tile-art skins (traditional + "Mexican embroidery-inspired").
- **Signal:** the teacher directory + community forum shows they're trying to be a hub, not just a drill tool — more ambitious/bloated scope than Mahj Trainer's flashcard focus.

### MAHJ: Learn American Mahjong (Welcome2Mahj) — direct teaching-only competitor, one-time price
Another close analog, structured as sequential lessons rather than freeform drills.
- **Pricing:** free with **one-time $4.99 unlock** for lessons 4-18 — **no subscription at all**. This is the strongest evidence in the category that a one-time-purchase model is viable and possibly preferred for this demographic.
- **Rating:** 4.9★ / 57 ratings.
- **Features:** 18 interactive *audio* lessons progressing from zero knowledge to "confident at your first game night," tile-recognition drills across all 152 tiles, daily puzzle, searchable glossary (free tier); paid tier adds Charleston/calling/scoring/etiquette lessons, bot practice games, a rules-Q&A "coach," hand analyzer, scoring calculator, printable one-page cheat sheet, and a "Crew" feature to learn with friends.
- **Positioning line worth noting:** "from 'I don't know a single tile' to confident at your first real game night" — a strong, specific beginner promise.

### Other apps encountered (lower relevance/quality signal)
- **MahJongo** (multi-variant incl. American): praised for clean UI, smart AI, no intrusive ads; but recurring crash/iPad-compatibility complaints.
- **Mahjic Play** (Mahjic/Bam Good Time ecosystem): native iOS/Mac, hand-illustrated tile art, warm gradients, "feels more like a modern game than a digitized card table" — closest competitor on *visual polish*; ties into a club/event platform (Bam Good Time) so it's aimed at organized clubs, not solo learners.
- **NMJL Online**: the *official* National Mah Jongg League app — free tutorial, but full play requires owning the physical card + a separate NMJL online membership purchased from the League. Bare-bones by most accounts; official but not well-loved as a product.
- **MahJongg4Fun / Mahjong 4 Friends**: free/freemium multiplayer-focused, multi-variant, not learning-focused.

---

## Design language patterns

### The lifestyle-brand aesthetic that defines "modern mahjong" for this demographic
**The Mahjong Line** (Dallas) is the brand that reset expectations for what mahjong "should" look like among affluent 40-70 women — it's the visual reference point this whole category gets compared to.
- Palette: maximalist, saturated color used deliberately for gameplay legibility ("strategically employ color to improve a quick scan of the table") — cornflower blue, lilac, sage green, red/pink brand marks, on clean white.
- Type: sans-serif, legible, "contemporary sophistication rather than ornamental."
- Photography: lifestyle/product shots of tiles-in-use, not sterile product-only shots; custom illustrated icon accents (paper airplane, envelope) for personality.
- Layout: spacious, grid-based, generous whitespace, well-organized despite a large catalog.
- Tone: "energetic yet sophisticated." Tagline: *"Games for a life well played."* Copy leans into "color explosion" and "giddiness" — mahjong as a chic, social, adult-leisure status object, not a dusty grandmother's game.
- Enlarged tile faces specifically to "give artwork room to breathe and improve legibility" — a legibility-first design choice that doubles as an accessibility win for the 50+ audience.

**Oh My Mahjong** occupies similar territory with distinct, named palette stories per collection (not just "pretty colors" but seasonal/moodboard names): Heritage (sage/olive + burl wood, "grounded, sophisticated"), Lagoon (teal/citron/magenta, "energizing and serene"), Luminaire (blush/sky blue/mint pastels, "light, fresh, effortlessly elegant"), Moonlight (lavender/blush/mint/sky blue), Taylor (lilac/lime/baby pink, "playful and polished"). Crisp white tile faces are a constant across every colorway — white-as-canvas is the category convention, with color living in the artwork/edges, not the base.

**Mahjic Play** is the closest analog inside an *app* (not a physical-goods brand): "warm gradients, proportional tile sizing, clean board layout" that "feels more like a modern game than a digitized card table" — proof that warm/soft gradient treatments read as premium in this category even in-app, not just on tile sets.

### What this means for app UI specifically (vs. physical tile brands)
- App competitors (I Love Mahj, Eight Bam, Real Mah Jongg) skew *functional-clean* rather than lifestyle-branded: light backgrounds, blue/navy accents, large tap targets, minimal ornamentation. None of them have adopted the maximalist-color lifestyle-brand look yet — this is a visible gap. A "warm modern, ivory/cream, in the spirit of I Love Mahj" direction sits between the two poles (more polish than the utilitarian practice apps, less maximalist/loud than Mahjong Line) and is currently unclaimed in-app.
- Every app in the category leads with **large tile/text rendering** as a stated design goal ("tiles are large," "large tile displays," "large tile graphics, high-contrast"). This is a hard requirement, not a nice-to-have, for the 50+ segment — treat generous tap targets and tile size as non-negotiable, not an aesthetic choice to trade off against density.
- None of the reviewed competitor apps use skeuomorphic felt-table backgrounds as a dominant surface (that look reads as "generic solitaire game," per the unrelated-app confusion around "I Love Mahjong" on iOS). Mahj Trainer's existing `Theme.felt` deep green + ivory pairing is on-trend with the physical-brand aesthetic (rich accent + neutral base) but should stay a supporting accent (headers/CTAs), not a full-screen backdrop, to avoid reading as a solitaire game rather than a modern teaching app.

---

## Pricing landscape

| App | Model | Price |
|---|---|---|
| I Love Mahj | Subscription only, 2-3wk trial | $6/mo or $60/yr |
| Real Mah Jongg | Subscription only, 2wk trial | $6.99/mo |
| Eight Bam (American Mahjong Practice) | Freemium; sub **or** one-time unlock | $3.99/mo **or** $14.99-$17.99 one-time (non-renewing, per card-year) |
| The Mahj App | Freemium subscription | $3.99/mo or $29.99/yr (marketing also cites flat $3.99 elsewhere — inconsistent) |
| MAHJ: Learn American Mahjong | Freemium, **one-time only** | $4.99 one-time unlock, no subscription |
| Mahjong Solitaire (generic) | Subscription | $1.99/mo, $4.99/3mo, $14.99/yr |
| Mahj Trainer (current) | Subscription, RC `pro` entitlement | $4.99/mo or $29.99/yr, 1-week trial on both |

**Patterns:**
- The category splits roughly in half between pure-subscription (I Love Mahj, Real Mah Jongg — both live-play platforms with real server/matchmaking costs to cover) and freemium-with-a-one-time-option (Eight Bam, MAHJ) for pure practice/learning apps that have no ongoing server cost.
- **One-time pricing shows up specifically as a response to user complaints about subscriptions** — Eight Bam added its non-renewing $14.99-17.99 unlock because sporadic players said the monthly fee "adds up" and there's "no annual discount that significantly reduces the cost." This is a direct, documented instance of this exact demographic pushing back on subscriptions and a vendor responding.
- Teaching-only apps (no live multiplayer/server cost) price lower ($3.99-4.99) than live-play platforms ($6-7/mo), which matches their lower marginal cost — Mahj Trainer, as a teaching-only drill app, is priced in-line with Real Mah Jongg/I Love Mahj (live platforms) rather than with its true peer set (Eight Bam/The Mahj App/MAHJ), which sit at $3.99-4.99/mo or $4.99-17.99 one-time. Mahj Trainer's $4.99/mo is toward the top of what teaching-only apps charge monthly.
- Trials are near-universal (1-3 weeks) across every subscription competitor; Mahj Trainer's existing 1-week trial on both tiers is consistent with the category norm, if slightly shorter than the 2-3wk trials of the live-play leaders.
- Explicit senior/older-adult buying guidance (from general app-store advice content, not mahjong-specific) confirms the pattern: this demographic responds better to **"a genuine ads-free experience or a one-time, clearly priced upgrade rather than constant upsells"** — pricing anxiety and aggressive upsell fatigue are named concerns for fixed-income older users.

---

## What users praise/complain about

### Praise (recurring themes across I Love Mahj, Eight Bam, Real Mah Jongg, MahJongo)
- **"Invaluable for learning"** — the single most common review sentiment across every practice/teaching app; users credit these apps with making them noticeably better/faster at pattern recognition and Charleston decisions.
- **Self-paced practice between real games** — repeatedly framed as filling the gap between weekly in-person sessions ("lets me practice at my own speed between weekly games with friends").
- **Clean, uncluttered UI** — called out explicitly and positively ("modern and intuitive," "no intrusive ads, a beautifully designed interface").
- **Responsive developer support** — named-individual support responses (Eight Bam's "Ray") get cited approvingly in reviews; this is a low-cost trust signal worth deliberately doing well (fast, human-sounding App Store review responses and support replies).
- **Large tiles / big touch targets** — treated as a feature worth praising, not assumed baseline.

### Complaints (recurring across the same set)
- **Subscription fatigue / no meaningful annual discount** — the most common monetization complaint; drove Eight Bam to ship a one-time SKU.
- **Touch-target/interaction bugs** — "hyper sensitive" controls causing accidental wrong actions; state loss when the app backgrounds or the phone is set down for a few minutes.
- **AI/bot opponents feel unfair or repetitive** — undermines trust in "practice" value when the bot always wins with the same hand types (quints, concealed, NEWS, 2020) — reads as rigged rather than realistic, which is corrosive for a *learning* app specifically since users are trying to build an accurate mental model of the game.
- **Concealed-hand / rule-edge-case bugs** — apps sometimes let a user "win" or expose info that wouldn't be legal at a real table, which damages credibility for an app whose whole value proposition is teaching correct rules.
- **Crashes / platform compatibility** (MahJongo on iPad) — stability complaints directly undercut a teaching app's core promise.
- **No permanent free tier** on the live-play platforms (I Love Mahj, Real Mah Jongg) — beginners specifically say they want to try before committing money, and a hard paywall after a timed trial (vs. a permanently free tier with upsells) reads as riskier to a price-sensitive, non-technical audience.
- **Branding/name collisions** — the "I Love Mahjong" App Store listing being an unrelated solitaire game is a live example of a confused-purchase risk category-wide; app names/keywords in this space are noisy and easy to conflate (worth checking Mahj Trainer's App Store name/keywords don't collide with an unrelated existing listing).

---

## Opportunities for Mahj Trainer

### How competitors handle the NMJL copyright issue
No competitor reprints the official NMJL card verbatim. The two documented approaches:
1. **License/require ownership of the real card** (NMJL Online): free tutorial, but full functionality requires the user to already own the physical NMJL card + buy a separate online membership from the League itself. Safe but creates friction and caps the free experience.
2. **Original teaching content + explicit "not affiliated" disclaimer** (Mahj Mastery, The Mahjong Press, and implicitly all the practice apps that reference "2025/2026 hands" without calling them official): third-party apps build their own hand sets or generic teaching examples and post a clear non-affiliation disclaimer. This is exactly Mahj Trainer's existing approach per CLAUDE.md (original teaching hands, disclaimer in Home footer/Settings/App Store description) and it's the category-standard, lowest-risk path — no competitor has been found reprinting the actual card. Keep the disclaimer visible in the same places competitors do (footer, settings, store listing) since that's now an expected pattern, not just a legal CYA.

### Gaps Mahj Trainer can exploit
1. **No pure drill-flashcard app exists yet.** Every "teaching" competitor (The Mahj App, MAHJ) wraps lessons in a bigger scope — community forums, teacher directories, "Crew" social features, audio lessons. Mahj Trainer's tight scope (flashcard/quiz drills only, no gameplay, no social layer) is currently a *positioning gap*, not a weakness — it can be pitched as "the fast, focused way to drill" against apps that ask for more time/investment.
2. **The lifestyle-brand aesthetic hasn't reached app UI yet.** Every app skews utilitarian; every beautiful visual identity in the category lives on physical tile sites (Mahjong Line, Oh My Mahjong). A genuinely well-designed "warm modern" app is still a white-space opportunity — it can borrow legitimacy from tile brands this audience already loves without competing with them.
3. **Trust-building around correctness is undervalued by competitors.** Rigged-feeling bots and rule-edge-case bugs are recurring complaints; because Mahj Trainer has no gameplay/AI opponent to get wrong, it structurally avoids this whole complaint category — worth stating explicitly in App Store copy ("no bots to out-guess, no gameplay bugs — just the rules, taught clearly").
4. **One-time-purchase or hybrid pricing is a proven demand signal**, not just a hypothesis — Eight Bam shipping a one-time SKU in direct response to complaints, and MAHJ launching subscription-free entirely, are two independent, documented data points in this exact category. Given Mahj Trainer's current $4.99/mo positions it at the high end of teaching-only apps (peers are $3.99-4.99/mo or one-time $4.99-17.99), consider testing a one-time "yearly card unlock" SKU alongside the subscription, mirroring Eight Bam's model — this also sidesteps the "will I still want this after 2 months" hesitation that's specific to a *learning* app (unlike I Love Mahj/Real Mah Jongg, which have recurring server/matchmaking costs that justify a recurring fee, Mahj Trainer's content is closer to a fixed instructional product).
5. **Branding clarity**: given the "I Love Mahjong" name collision on iOS, do a quick App Store search for "Mahj Trainer" and close synonyms before/at launch to confirm no confusing neighbor listing exists in search results.
6. **Accessibility-as-differentiator**: every competitor treats "large tiles/high contrast" as a feature to brag about rather than a baseline; leaning into explicitly senior-friendly affordances (bigger default text size support, high-contrast mode, generous tap targets already implied by SwiftUI/iOS HIG) gives Mahj Trainer copy ammunition ("designed to be easy on the eyes") that doubles as genuine usability for the target demo.

---

## Concrete design recommendations

Grounded against Mahj Trainer's existing `Theme.swift` (felt: deep green `RGB(0.13, 0.35, 0.28)`, ivory: `RGB(0.98, 0.96, 0.90)`, plus suit accents crakRed, bamGreen, dotBlue, jokerPurple, flowerPink, and gold) — the palette is already well-aligned with the category's "rich accent on neutral base" convention (Oh My Mahjong's white-canvas-plus-colorway pattern, Mahjong Line's white-plus-saturated-accent pattern). Recommendations below refine usage, not the palette itself.

### Color
- Keep ivory/cream as the dominant surface (already correct per competitor convention — no competitor app uses a dark or saturated dominant background; all lean light).
- Use `Theme.felt` (deep green) sparingly as an *accent* — nav bars, primary CTA buttons, header bands — not as a full-screen background. A full felt-green screen reads as "digital card table," which is the aesthetic of the generic/unrelated solitaire apps in this space (the "I Love Mahjong" collision app), not the teaching-app aesthetic Mahj Trainer wants.
- The suit colors (crakRed, bamGreen, dotBlue, jokerPurple, flowerPink, gold) map naturally onto Oh My Mahjong's "named colorway" pattern — consider using them consistently as *semantic* color (always red = crak, always blue = dot, etc.) across drills, quiz feedback, and hand-category badges, so color becomes a learning aid (reinforcing tile-suit recognition) rather than just decoration. This directly supports the app's pedagogical goal in a way no competitor currently does.
- Reserve gold for success/mastery states (streaks, completed hand badges) — it's underused in the current palette and maps well to "achievement" without competing with the suit-color semantics.

### Type
- Sans-serif, generous default sizes, full support for iOS Dynamic Type up to at least the larger accessibility sizes — this is a functional requirement given the demographic, not a style preference (multiple competitors explicitly market "large text/tiles" as a selling point).
- Keep numerals/tile-pips highly legible at small sizes since tiles themselves are visually dense (rack views); avoid condensed or tightly-tracked type anywhere near tile rendering.

### Tone of voice (copy)
- Model I Love Mahj and MAHJ's beginner-first framing over Mahjong Line's maximalist lifestyle voice — Mahj Trainer is a teaching tool, not a tile-shopping brand, so tone should read as warm-competent-encouraging ("clear visual guides," "build real confidence," "one short lesson at a time") rather than "color explosion/giddiness."
- Borrow MAHJ's concrete beginner promise structure for App Store copy and onboarding: name the starting state and the destination explicitly (their line: "from 'I don't know a single tile' to confident at your first real game night").
- State the "no bots, no gameplay bugs, no rigged AI" differentiator plainly somewhere in App Store copy or a first-run screen — it directly counters the most damaging recurring complaint in the category (rigged/unfair-feeling AI opponents) and is uniquely true of Mahj Trainer's drill-only design.
- Keep the non-affiliation disclaimer visible but low-key (footer/settings/store listing, as already planned) — every competitor that addresses copyright does so this way; don't bury it, but don't lead with it either.

### Components
- **Large tap targets everywhere a tile is tappable** — treat this as a hard floor, not a design nice-to-have; multiple competitors were explicitly praised or complained about based on tile/control size alone.
- **Visible, generous progress/streak indicators** — review-funnel and streak mechanics already exist (`ProgressStore`); make streak/completion state highly visible in the UI chrome (not just a stat screen) since "invaluable for learning" reviews consistently cite a sense of visible progress as core to why users kept coming back.
- **Avoid felt-table skeuomorphism as a primary surface pattern** (see Color above) — use flat, card-based layouts (matches "warm modern" direction and avoids reading as a generic mahjong-solitaire game).
- Consider a one-time "hand set / card-year unlock" purchase option alongside the subscription (see Opportunities #4) — if added, present it with the same plain, single-price clarity Oh My Mahjong and MAHJ use (no tiered upsell ladder), since upsell fatigue is a named complaint for this exact demographic.
