"""Copy and concept data for the Mahj Trainer Meta ad pack.

Every candidate concept lives here, shipped or not, so scoring.md and the
renderer read from one place. `FINAL` lists the five that ship.

Rules every string here follows (check_pack in build_pack.py enforces the
mechanical ones): no prices, no em dashes, no hands from the NMJL card,
"Mahj Trainer" spelled exactly, claims true for a FREE user (Mahj Minute,
Game Night Prep and Endless Practice are Mahj+, so no ad sells them), and
"not affiliated" wherever the card itself is the subject.

Meta limits used: primary text lead under 125 characters (the part shown
before "See more"), headline under 40 (27 is Meta's feed recommendation,
carousel cards 20), description under 30.
"""

INSTALL, LEARN = "Install Now", "Learn More"

# Real App Store reviews of Mahj Trainer (US, iTunes RSS, read 2026-10-15),
# quoted exactly. Never edit the wording; never add one that is not real.
REVIEWS = [
    ("I am fairly new and the practice Charleston’s are great.", "Great practice", "Sep 26, 2026"),
    ("I’ve been reading about mah Jong but this allows you to actually test what you know "
     "or learn new stuff. Very helpful!", "Great app", "Oct 5, 2026"),
    ("Nice to practice without the card anywhere anytime", "Great!", "Jul 20, 2026"),
]

ADS = {
    "C1": dict(
        slug="charleston-pass",
        name="Holding up the Charleston (pain static)",
        motivation="Fear of slowing the table during the Charleston",
        format="Single image",
        opening="Serif headline naming the fear, over a real Pick Your Pass rack with 3 tiles chosen",
        eyebrow="AMERICAN MAH JONGG",
        headline="Never be the one holding up the Charleston.",
        body="Practice the pass at home. Pick 3 tiles, then see what the coach would pass and why.",
        primary="Worried about holding up the Charleston? Practice the pass at home and see which 3 tiles the coach would pass, and why.",
        primary_long=("Worried about holding up the Charleston? Practice the pass at home and see which 3 "
                      "tiles the coach would pass, and why.\n\nMahj Trainer is short American Mah Jongg "
                      "drills for newer players: the Charleston, reading your rack, keep or throw. Original "
                      "practice hands, free to start, no account."),
        alternates=[
            "Three tiles to pass and the whole table waiting? Practice the Charleston at home, with a coach that explains the pass.",
            "The Charleston gets easier with reps. Real deals, pick your 3, then see the coach's pass and the reason behind it.",
        ],
        ad_headline="Practice the pass at home",
        description="American Mah Jongg drills",
        cta=INSTALL,
    ),
    "C2": dict(
        slug="charleston-3-steps",
        name="Freeze in the Charleston? 3 steps (carousel from TikTok D2)",
        motivation="Learn a method you can use at the next game (save-worthy value)",
        format="Carousel, 6 cards",
        opening="Hook card: 'Freeze in the Charleston?' over a real 13-tile deal",
        source="TikTok kit post D2 ('If you freeze every Charleston, use this 3-step rule'), rewritten around one real deal and the app's own coach answer",
        cards=[
            dict(eyebrow="AMERICAN MAH JONGG", headline="Freeze in the Charleston? Use this 3-step rule.",
                 card_headline="Use this 3-step rule"),
            dict(eyebrow="STEP 1", headline="Sort by suit and count your pairs.",
                 note="This deal: three pairs already.", card_headline="Sort and count pairs"),
            dict(eyebrow="STEP 2", headline="Name the 2 or 3 sections it could become.",
                 note="Lots of 2s, 4s, 6s and 8s points hard to 2468.", card_headline="Name your sections"),
            dict(eyebrow="STEP 3", headline="Pass the tiles that fit none of them.",
                 note="Here: the 5 Crak, 7 Bam and lone North.", card_headline="Pass what fits none"),
            dict(eyebrow="ALWAYS", headline="Never pass a joker. Keep flowers early.",
                 note="Jokers can't be passed in any Charleston.", card_headline="Never pass a joker"),
            dict(eyebrow="MAHJ TRAINER", headline="Practice it on real deals, with a coach.",
                 note="Free to start on the App Store.", card_headline="Practice real deals"),
        ],
        primary="Freeze every Charleston? Use this 3-step rule, then practice it on real deals in Mahj Trainer.",
        primary_long=("Freeze every Charleston? Use this 3-step rule, then practice it on real deals in "
                      "Mahj Trainer.\n\nPick your 3 tiles, then compare with the coach's pass and the "
                      "reason behind it. Free to start, no account."),
        alternates=[
            "Sort, name your sections, pass what fits none. The Charleston in 3 steps, plus a place to practice it.",
            "Save this for game night: a simple Charleston rule for newer American Mah Jongg players.",
        ],
        ad_headline="The Charleston in 3 steps",
        description="Free to start",
        cta=INSTALL,
    ),
    "C3": dict(
        slug="read-the-rack-reel",
        name="Read the rack quiz (screen-recording Reel)",
        motivation="Play-along challenge: can you read a rack in 3 seconds?",
        format="Video 18s, 9:16 and 4:5, burned-in captions, no sound needed",
        opening="'Which section is this rack chasing?' over the real drill, answer withheld",
        primary="Which section is this rack chasing? Answer before the tap. Quick American Mah Jongg drills that explain every answer.",
        primary_long=("Which section is this rack chasing? Answer before the tap.\n\nMahj Trainer turns "
                      "game-night skills into quick drills: read the rack, pick your Charleston pass, keep "
                      "or throw. Every answer comes with the reason. Free to start."),
        alternates=[
            "Can you name this rack's section in 3 seconds? Short daily reps get you there, with the reason behind every answer.",
            "A real drill from Mahj Trainer: read the rack, then pass 3 in the Charleston. Five minutes before game night.",
        ],
        ad_headline="Read your rack faster",
        description="American Mah Jongg drills",
        cta=INSTALL,
        captions=[
            (0.0, 3.2, "Which section is this rack chasing?", "Answer before the tap."),
            (3.2, 7.2, "2468. Every number tile is even.", "Flowers and a joker fit anywhere."),
            (7.2, 11.6, "Now the Charleston.", "Pick 3 tiles to pass right."),
            (11.6, 15.6, "Perfect pass.", "The coach explains every pass."),
        ],
    ),
    "C4": dict(
        slug="teaches-not-plays",
        name="Most mahj apps let you play. Mahj Trainer teaches you (us vs them)",
        motivation="Frustration with game apps that never explain a loss",
        format="Single image",
        opening="Two-line contrast headline over a real 'Why not...?' coaching card",
        eyebrow="AMERICAN MAH JONGG",
        headline="Most mahj apps let you play. Mahj Trainer teaches you.",
        body="Get one wrong and it shows you why, before your next game.",
        primary="Most mahj apps hand you a game against bots. Mahj Trainer teaches the decisions, and shows why when you miss one.",
        primary_long=("Most mahj apps hand you a game against bots. Mahj Trainer teaches the decisions, "
                      "and shows why when you miss one.\n\nRead the rack, pick your Charleston pass, keep or "
                      "throw. One decision at a time, with original practice hands. Free to start."),
        alternates=[
            "Lost a game and never found out why? Mahj Trainer explains every answer, right or wrong.",
            "You don't need more games. You need to know why. Short drills for the decisions you make at the table.",
        ],
        ad_headline="It shows you why",
        description="Practice, not another game",
        cta=INSTALL,
    ),
    "C5": dict(
        slug="real-reviews",
        name="Real App Store reviews (testimonial static)",
        motivation="Social proof from other newer players",
        format="Single image",
        opening="A real 5-star review quote set large in serif",
        eyebrow="A REAL APP STORE REVIEW",
        headline="“I am fairly new and the practice Charleston’s are great.”",
        primary="“I am fairly new and the practice Charleston’s are great.” Practice American Mah Jongg between games. Free to start.",
        primary_long=("“I am fairly new and the practice Charleston’s are great.” (App Store review)\n\n"
                      "Mahj Trainer is short drills for newer American Mah Jongg players: the Charleston, "
                      "reading your rack, keep or throw. Free to start, no account."),
        alternates=[
            "“This allows you to actually test what you know.” Short American Mah Jongg drills for newer players.",
            "Newer players are practicing the Charleston between games. Here's what they say.",
        ],
        ad_headline="Made for newer players",
        description="A real App Store review",
        cta=INSTALL,
    ),
    "C6": dict(
        slug="six-fifty-five",
        name="6:55 pm, game night at 7 (routine static)",
        motivation="A quick warm-up before the weekly game",
        format="Single image",
        opening="A clock time in huge serif: '6:55 pm. Game night at 7.'",
        eyebrow="AMERICAN MAH JONGG",
        big="6:55 pm.",
        headline="Game night at 7.",
        body="Five minutes of practice first. Get Started puts what you missed last time up front.",
        primary="Game night at 7? Spend five minutes first. Get Started puts what you missed last time up front.",
        primary_long=("Game night at 7? Spend five minutes first. Get Started puts what you missed last "
                      "time up front.\n\nShort American Mah Jongg drills: the Charleston, reading your rack, "
                      "keep or throw. Free to start."),
        alternates=[
            "Play once a week and feel like you start over every time? Five minutes before the game helps it stick.",
            "Warm up before mahj night: one five-minute mix built from your own misses.",
        ],
        ad_headline="Five minutes before mahj night",
        description="Free to start",
        cta=INSTALL,
    ),
    "C7": dict(
        slug="every-april",
        name="The hands change every April (returning player static)",
        motivation="Yearly-card reset; returning players who knew the old cards",
        format="Single image",
        opening="'The hands change every April.' in serif over a real reference page",
        eyebrow="AMERICAN MAH JONGG",
        headline="The hands change every April. The patterns come back.",
        body="Learn to spot 2468, Like Numbers and Consecutive Runs on original practice racks.",
        footnote="Not affiliated with the National Mah Jongg League.",
        primary="The hands change every April. The patterns behind them keep coming back. Learn to spot them on original practice racks.",
        primary_long=("The hands change every April. The patterns behind them keep coming back. Learn to "
                      "spot them on original practice racks.\n\nMahj Trainer is not affiliated with the "
                      "National Mah Jongg League; use your current NMJL card for official hands."),
        alternates=[
            "Played years ago? The card is new every spring, but 2468, Like Numbers and runs are old friends. Get them back fast.",
            "New card, familiar patterns. Practice reading racks by section before your group's first game of the year.",
        ],
        ad_headline="New card, familiar patterns",
        description="Not affiliated with the NMJL",
        cta=LEARN,
    ),
    "C8": dict(
        slug="teacher-homework",
        name="Teaching a new player? (organizer static)",
        motivation="Club organizers and teachers recommending practice to students",
        format="Single image",
        opening="'Teaching someone to play?' over the Tile Room and a coaching note",
        eyebrow="FOR MAHJ TEACHERS",
        headline="Teaching someone to play? Send her this.",
        body="Short drills on tiles, sections and the Charleston, each with the reason behind the answer.",
        primary="Teaching someone mahj? Send her short drills on the tiles, the sections and the Charleston, each with the reason why.",
        primary_long=("Teaching someone mahj? Send her short drills on the tiles, the sections and the "
                      "Charleston, each with the reason why.\n\nOriginal practice hands only, never the card. "
                      "Free to start, no account."),
        alternates=[
            "Your students forget the suits between classes. Give them five minutes of practice they'll actually do.",
            "Homework for new mahj players: short drills with a coach note on every answer.",
        ],
        ad_headline="Practice between lessons",
        description="Free to start",
        cta=LEARN,
    ),
}

FINAL = ["C1", "C2", "C3", "C4", "C7"]
