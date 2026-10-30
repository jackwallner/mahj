#!/usr/bin/env python3
"""Generate the Mahj Trainer learn pages from the app's own reference content.

Usage: scripts/generate-learn-pages.py . docs
Prose pages are authored here; the glossary and the card sections are parsed
from the Swift sources so the site and the app never drift apart.

The pages in docs/learn have since been edited by hand (answer-first leads,
question headings, campaign links, the github.io redirect). Running this
reverts those edits, so port them into this script first.
"""
import html
import json
import re
import sys
from pathlib import Path

repo = Path(sys.argv[1])
out = Path(sys.argv[2])
learn = out / "learn"
learn.mkdir(parents=True, exist_ok=True)

BASE = "https://jackwallner.com/ios/mahj/"
APP_URL = "https://apps.apple.com/us/app/mahj-trainer-mahjong-practice/id6790052126"
PUBLISHED = "2026-10-11"
TODAY = "2026-10-12"

# ---------------------------------------------------------------- parsing

def parse_glossary():
    src = (repo / "Shared/Content/ReferenceContent.swift").read_text()
    terms = []
    for m in re.finditer(r'GlossaryTerm\(\s*id: "([^"]+)", term: "([^"]+)",(?: aliases: \[([^\]]*)\],)? group: \.(\w+),\s*definition: "((?:[^"\\]|\\.)*)"', src):
        gid, term, aliases, group, definition = m.groups()
        terms.append({
            "id": gid, "term": term, "group": group,
            "aliases": [a.strip().strip('"') for a in (aliases or "").split(",") if a.strip()],
            "definition": definition.replace('\\"', '"'),
        })
    assert len(terms) >= 30, len(terms)
    return terms

def parse_sections():
    cat = (repo / "Shared/Models/HandCategory.swift").read_text()
    ref = (repo / "Shared/Content/ReferenceContent.swift").read_text()
    def block(name):
        m = re.search(r"var %s: String \{(.*?)\n    \}" % name, cat, re.S)
        return dict(re.findall(r'case \.(\w+):\s*return "((?:[^"\\]|\\.)*)"', m.group(1)))
    display = block("displayName")
    spot = block("howToSpot")
    requires = block("requires")
    sections = []
    for m in re.finditer(r'SectionReference\(\s*category: \.(\w+),\s*exampleRack: \[(.*?)\],\s*watchOut: "((?:[^"\\]|\\.)*)"', ref, re.S):
        key, rack, watch = m.groups()
        sections.append({
            "key": key, "name": display[key], "spot": spot[key], "requires": requires[key],
            "watch": watch, "rack": parse_rack(rack),
        })
    assert len(sections) == 9, len(sections)
    return sections

def parse_rack(text):
    tiles = []
    for m in re.finditer(r"\.(c|b|d)\((\d)\)|\.dragon\(\.(\w+)\)|\.wind\(\.(\w+)\)|\.(flower|joker)", text):
        suit, n, dragon, wind, special = m.groups()
        if suit: tiles.append({"c": "crak", "b": "bam", "d": "dot"}[suit] + ":" + n)
        elif dragon: tiles.append("dragon:" + dragon)
        elif wind: tiles.append("wind:" + wind)
        else: tiles.append(special + ":")
    return tiles

# ---------------------------------------------------------------- rendering

def tile_html(spec):
    kind, value = spec.split(":")
    if kind in ("crak", "bam", "dot"):
        label = {"crak": "C", "bam": "B", "dot": "D"}[kind]
        return f'<span class="tile {kind}" title="{value} {kind.capitalize()}">{value}<small>{label}</small></span>'
    if kind == "dragon":
        name = {"red": "Red", "green": "Green", "soap": "Soap"}[value]
        return f'<span class="tile dragon {value}" title="{name} Dragon">{name[0] if value != "soap" else "S"}<small>DR</small></span>'
    if kind == "wind":
        return f'<span class="tile wind" title="{value.capitalize()} Wind">{value[0].upper()}<small>W</small></span>'
    if kind == "flower":
        return '<span class="tile flower" title="Flower">F<small>FL</small></span>'
    return '<span class="tile joker" title="Joker">J<small>JK</small></span>'

def rack_html(tiles):
    return '<div class="rack" aria-label="Example rack">' + "".join(tile_html(t) for t in tiles) + "</div>"

def esc(s):
    return html.escape(s, quote=False)

def page(slug, title, description, h1, lead, body, faq=None, related=(), words_hint=""):
    canonical = f"{BASE}learn/{slug}.html"
    ld = [{
        "@context": "https://schema.org", "@type": "Article",
        "headline": h1, "description": description, "url": canonical,
        "datePublished": PUBLISHED, "dateModified": TODAY,
        "author": {"@type": "Person", "name": "Jack Wallner"},
        "publisher": {"@type": "Organization", "name": "Mahj Trainer"},
        "isPartOf": {"@type": "WebSite", "name": "Mahj Trainer", "url": BASE},
    }, {
        "@context": "https://schema.org", "@type": "BreadcrumbList",
        "itemListElement": [
            {"@type": "ListItem", "position": 1, "name": "Mahj Trainer", "item": BASE},
            {"@type": "ListItem", "position": 2, "name": "Learn", "item": BASE + "learn/"},
            {"@type": "ListItem", "position": 3, "name": h1, "item": canonical},
        ],
    }]
    faq_html = ""
    if faq:
        ld.append({"@context": "https://schema.org", "@type": "FAQPage", "mainEntity": [
            {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}} for q, a in faq]})
        faq_html = '<section class="faq"><h2>Common questions</h2>' + "".join(
            f"<details><summary>{esc(q)}</summary><p>{esc(a)}</p></details>" for q, a in faq) + "</section>"
    related_html = ""
    if related:
        related_html = '<nav class="related" aria-label="Related guides"><h2>Keep reading</h2><ul>' + "".join(
            f'<li><a href="{s}.html">{esc(t)}</a></li>' for s, t in related) + "</ul></nav>"
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{esc(title)}</title>
<meta name="description" content="{esc(description)}">
<link rel="canonical" href="{canonical}">
<link rel="icon" type="image/png" sizes="256x256" href="../icon_256.png">
<link rel="apple-touch-icon" href="../icon_256.png">
<meta name="apple-itunes-app" content="app-id=6790052126">
<meta property="og:type" content="article">
<meta property="og:title" content="{esc(title)}">
<meta property="og:description" content="{esc(description)}">
<meta property="og:url" content="{canonical}">
<meta property="og:site_name" content="Mahj Trainer">
<meta property="og:image" content="https://jackwallner.github.io/mahj/appstore-screenshot-01.png">
<meta name="twitter:card" content="summary_large_image">
<link rel="stylesheet" href="learn.css">
<script type="application/ld+json">{json.dumps(ld, ensure_ascii=False)}</script>
</head>
<body>
<nav class="top"><div class="wrap">
<a class="brand" href="../"><img src="../icon_256.png" alt="" width="28" height="28"><span>Mahj Trainer</span></a>
<div class="links"><a href="./">Learn</a><a class="pill" href="{APP_URL}">Get the app</a><a class="play-badge" href="https://play.google.com/store/apps/details?id=com.jackwallner.mahj"><img src="../google-play-badge.png" alt="Get it on Google Play" width="646" height="250"></a></div>
</div></nav>
<main class="wrap">
<p class="crumbs"><a href="../">Mahj Trainer</a> / <a href="./">Learn</a> / {esc(h1)}</p>
<article>
<h1>{esc(h1)}</h1>
<p class="lead">{lead}</p>
{body}
{faq_html}
<aside class="cta">
<h2>Read it, then practice it in the app</h2>
<p>Mahj Trainer turns everything on this page into five-minute drills: flashcards with the why on the back, racks to read, Charleston deals to pass, and keep-or-throw calls with a coach's reasoning. The four beginner rooms are free, no account needed.</p>
<div class="cta-row">
<a class="button" href="{APP_URL}">Download for iPhone and iPad</a>
<a class="play-badge" href="https://play.google.com/store/apps/details?id=com.jackwallner.mahj"><img src="../google-play-badge.png" alt="Get it on Google Play" width="646" height="250"></a>
</div>
</aside>
{related_html}
</article>
</main>
<footer class="wrap">
<p>Mahj Trainer is an independent training app. It is not affiliated with or endorsed by the National Mah Jongg League. Every example hand here is an original teaching hand, not a hand from any year's card. For official hands and values, get the current NMJL card.</p>
<p><a href="../">Home</a> · <a href="./">Learn</a> · <a href="../support.html">Support</a> · <a href="../privacy-policy.html">Privacy</a></p>
<p>&copy; 2026 Jack Wallner</p>
</footer>
</body>
</html>
"""

CSS = """
:root { --ink:#1d1d1f; --ink2:#5b5752; --ink3:#86868b; --jade:#21594a; --cream:#faf8f3; --card:#ffffff; --rule:rgba(0,0,0,0.08); }
* { box-sizing:border-box; margin:0; padding:0; }
body { font-family:-apple-system,BlinkMacSystemFont,"SF Pro Text","Helvetica Neue",sans-serif; color:var(--ink); background:var(--cream); line-height:1.6; -webkit-font-smoothing:antialiased; }
.wrap { max-width:760px; margin:0 auto; padding:0 22px; }
nav.top { position:sticky; top:0; z-index:10; background:rgba(250,248,243,0.9); backdrop-filter:blur(12px); border-bottom:1px solid var(--rule); }
nav.top .wrap { display:flex; align-items:center; justify-content:space-between; padding-top:12px; padding-bottom:12px; }
.brand { display:flex; align-items:center; gap:9px; text-decoration:none; color:var(--ink); font-weight:600; font-size:15px; }
.brand img { border-radius:7px; }
nav.top .links { display:flex; gap:16px; align-items:center; }
nav.top .links a { font-size:14px; color:var(--ink); text-decoration:none; }
nav.top .pill, .button { background:var(--ink); color:#fff !important; padding:0 16px; border-radius:980px; font-weight:500; text-decoration:none; display:inline-flex; align-items:center; height:34px; }
.button { height:44px; padding:0 20px; }
/* The badge PNG has 41px of transparent padding per side (visible 564x168 in 646x250): scale so the visible badge is --h tall, pull the padding back with negative margins. */
.play-badge { display:inline-flex; --h:34px; vertical-align:middle; }
.play-badge img { display:block; height:calc(var(--h) * 1.488); width:auto; margin:calc(var(--h) * -0.244); }
.cta .play-badge { --h:44px; }
.cta-row { display:flex; flex-wrap:wrap; gap:12px; align-items:center; }
@media (max-width:640px) { nav.top .play-badge { display:none; } }
.crumbs { font-size:13px; color:var(--ink3); margin:22px 0 10px; }
.crumbs a { color:var(--ink3); text-decoration:none; }
h1 { font-family:Georgia,"Times New Roman",serif; font-size:40px; line-height:1.1; letter-spacing:-0.5px; margin-bottom:12px; }
h2 { font-family:Georgia,"Times New Roman",serif; font-size:26px; margin:40px 0 10px; line-height:1.2; }
h3 { font-size:18px; margin:24px 0 6px; }
p, li { font-size:17px; color:var(--ink); }
p { margin-bottom:14px; }
ul, ol { margin:0 0 16px 22px; }
li { margin-bottom:6px; }
.lead { font-size:19px; color:var(--ink2); margin-bottom:22px; }
.note { background:var(--card); border:1px solid var(--rule); border-radius:14px; padding:14px 16px; margin:16px 0; font-size:15px; color:var(--ink2); }
.note strong { color:var(--ink); }
.rack { display:flex; flex-wrap:wrap; gap:4px; margin:10px 0 16px; }
.tile { display:inline-flex; flex-direction:column; align-items:center; justify-content:center; width:34px; height:46px; border-radius:6px; background:#fffdf7; border:1px solid #d9d3c5; box-shadow:0 1px 0 #c9c2b2; font-weight:700; font-size:16px; line-height:1; }
.tile small { font-size:8px; font-weight:600; letter-spacing:0.5px; margin-top:3px; opacity:0.7; }
.tile.crak { color:#b4322c; } .tile.bam { color:#2f7a4a; } .tile.dot { color:#2a56a8; }
.tile.dragon.red { color:#b4322c; } .tile.dragon.green { color:#2f7a4a; } .tile.dragon.soap { color:#2a56a8; }
.tile.wind { color:#1d1d1f; } .tile.flower { color:#8a4b8f; } .tile.joker { color:#c4802a; }
.section-card { background:var(--card); border:1px solid var(--rule); border-radius:16px; padding:18px 20px; margin:18px 0; }
.section-card h2 { margin-top:0; font-size:24px; }
.section-card p { font-size:16px; }
.term { padding:12px 0; border-bottom:1px solid var(--rule); }
.term h3 { margin:0 0 4px; font-size:17px; }
.term p { font-size:15px; color:var(--ink2); margin:0; }
.term .aka { font-size:13px; color:var(--ink3); }
.faq details { background:var(--card); border:1px solid var(--rule); border-radius:12px; padding:12px 16px; margin-bottom:8px; }
.faq summary { font-weight:600; cursor:pointer; font-size:16px; }
.faq details p { margin:10px 0 0; font-size:15px; color:var(--ink2); }
.cta { background:var(--jade); color:#fff; border-radius:18px; padding:24px; margin:40px 0 24px; }
.cta h2 { color:#fff; margin-top:0; font-size:24px; }
.cta p { color:rgba(255,255,255,0.85); font-size:16px; }
.cta .button { background:#fff; color:var(--jade) !important; }
.related ul { list-style:none; margin:0; }
.related li { margin-bottom:8px; }
.related a { color:var(--jade); font-weight:500; text-decoration:none; font-size:16px; }
.hub { display:grid; grid-template-columns:1fr 1fr; gap:14px; margin:24px 0; }
.hub a { display:block; background:var(--card); border:1px solid var(--rule); border-radius:16px; padding:18px; text-decoration:none; color:var(--ink); }
.hub a strong { display:block; font-size:18px; margin-bottom:4px; }
.hub a span { font-size:14px; color:var(--ink2); }
footer { padding:30px 22px 40px; font-size:12px; color:var(--ink3); text-align:center; }
footer p { font-size:12px; color:var(--ink3); margin-bottom:8px; }
footer a { color:var(--ink3); }
@media (max-width:600px) { h1 { font-size:32px; } .hub { grid-template-columns:1fr; } }
"""

# ---------------------------------------------------------------- pages

pages = []

def add(slug, title, description, h1, lead, body, faq=None, related=()):
    (learn / f"{slug}.html").write_text(page(slug, title, description, h1, lead, body, faq, related))
    pages.append((slug, h1, description))

# --- How to play
add("how-to-play-american-mahjong",
    "How to Play American Mah Jongg: Rules for Beginners (2026 Guide)",
    "The rules of American Mah Jongg in plain English: the 152 tiles, the card, the Charleston, calling, jokers, and how a hand is won. Written for brand-new players.",
    "How to play American Mah Jongg",
    "American Mah Jongg is a four-player tile game played against a yearly card of winning hands. This is the whole shape of the game in about ten minutes, in the order you will meet it at a table.",
    """
<h2>The goal</h2>
<p>Every player is racing to build a 14-tile hand that exactly matches one of the hands printed on the current card from the National Mah Jongg League (NMJL). Thirteen tiles live on your rack. The fourteenth is the tile you draw, or call from a discard, that completes the pattern. Finish first and you declare mah jongg.</p>
<p>That card is the thing that makes American Mah Jongg different from every other mahjong. There is no free-form "any four groups and a pair." The hand has to be on the card, and the card changes every spring.</p>

<h2>The tiles</h2>
<p>A full American set is 152 tiles. Knowing the count matters later, because it is the basis of working out what is still live.</p>
<ul>
<li><strong>Three number suits, 1 through 9, four of each.</strong> Craks (Chinese characters, usually red), bams (bamboo sticks, green, with the 1 Bam often drawn as a bird) and dots (circles, blue). That is 108 tiles.</li>
<li><strong>Winds.</strong> North, East, West and South, four of each. They are honors: they carry no number and never join a run.</li>
<li><strong>Dragons.</strong> Red, Green and White, four of each. Each one belongs with a suit: Red with craks, Green with bams, and the White Dragon, called the soap, with dots. The soap also stands in for a zero in year hands.</li>
<li><strong>Flowers.</strong> Eight of them, and for card purposes they are all interchangeable.</li>
<li><strong>Jokers.</strong> Eight wild tiles with strict rules about where they can sit. More on that below.</li>
</ul>
<div class="rack">""" + "".join(tile_html(t) for t in ["crak:5", "bam:5", "dot:5", "wind:north", "dragon:red", "dragon:green", "dragon:soap", "flower:", "joker:"]) + """</div>

<h2>Groups: the building blocks</h2>
<p>Hands on the card are written as groups. Read a line and you are reading a list of groups.</p>
<ul>
<li><strong>Pair:</strong> two identical tiles. Cannot hold a joker.</li>
<li><strong>Pung:</strong> three identical tiles. The smallest group you may call a discard to complete.</li>
<li><strong>Kong:</strong> four identical tiles.</li>
<li><strong>Quint:</strong> five identical tiles. Impossible without jokers, since only four of any tile exist.</li>
<li><strong>Single:</strong> one lone tile the hand requires. Like a pair, it must be the real tile.</li>
</ul>

<h2>The deal and the Charleston</h2>
<p>Tiles are shuffled face down and built into walls. Each player takes 13 tiles; East, the dealer, takes 14 and will throw the first discard. Before anyone plays a turn, the Charleston happens: every player passes three unwanted tiles to a neighbor, three times (right, across, left), with an optional second round in the other direction and a final across-the-table courtesy pass. Jokers can never be passed.</p>
<p>The Charleston is how a random deal turns into a plan. Most new players find it the scariest part of the game, and it is also the part that rewards practice fastest. It has its own page: <a href="charleston.html">The Charleston, explained</a>.</p>

<h2>A turn</h2>
<ol>
<li><strong>Draw</strong> a tile from the wall (or call the last discard, below).</li>
<li><strong>Keep or throw.</strong> Keep the drawn tile and discard another, or discard the one you drew. Say the tile's name out loud as you throw it face up.</li>
</ol>
<p>Play moves to the right (counter-clockwise). The game is a long sequence of keep-or-throw decisions, which is why Mahj Trainer drills that judgment so hard.</p>

<h2>Calling a discard</h2>
<p>When someone throws a tile you need to complete a pung, kong or quint, you may call it (say "call" or "take") until the next player racks the tile they drew. You then expose that whole group face up on top of your rack and discard. The exposure is public information for the rest of the hand.</p>
<p>Two limits: you cannot call for a pair or a single unless that tile completes your mah jongg, and a hand marked concealed on the card cannot call at all except for the winning tile. Once you have discarded after an exposure, the group is locked; the only change still allowed is someone swapping a real tile for a joker sitting in it.</p>

<h2>Jokers</h2>
<p>A joker stands in for any tile inside a pung, kong, quint or larger group. It can never be part of a pair or a single, never be passed in the Charleston, and a discarded joker is dead (nobody can call it). If an exposed group on any rack holds a joker and you have the real tile it stands for, you may swap on your turn and take the joker. Full rules: <a href="jokers.html">Jokers in American Mah Jongg</a>.</p>

<h2>Winning, scoring, and the wall</h2>
<p>When your fourteenth tile completes a hand on the card, say mah jongg, then expose your whole rack. The other three players pay you the value printed beside the hand. Whoever threw your winning tile pays double; if you drew it yourself, everyone pays double; a hand with no jokers doubles again. If the wall runs out before anyone wins, it is a wall game: nobody pays, reshuffle, deal again. Details: <a href="scoring-and-table-rules.html">Scoring and table rules</a>.</p>

<h2>What to practice first</h2>
<p>In rough order of payoff for a new player:</p>
<ol>
<li>Recognize every tile instantly, especially which dragon goes with which suit.</li>
<li>Learn the card's sections by shape, so you can look at 13 tiles and know which part of the card to read. See <a href="card-sections.html">How to read the card</a>.</li>
<li>Make a confident Charleston pass.</li>
<li>Make keep-or-throw calls, and learn which discards are safe.</li>
</ol>
""",
    faq=[
        ("How many tiles are in an American Mah Jongg set?", "152: 108 suit tiles (three suits, nine numbers, four each), 16 winds, 12 dragons, 8 flowers and 8 jokers."),
        ("How many tiles does each player hold?", "Thirteen on the rack. East, the dealer, starts with fourteen and throws the first discard. You win on your fourteenth tile."),
        ("Do I need the NMJL card to play?", "Yes. Every winning hand must be on the current year's card. Mahj Trainer teaches the category system the card is built from, so the skills transfer to any year's card, but you still need the official card at the table."),
        ("Can a joker be used in a pair?", "No. Jokers only work in groups of three or more. Pairs and singles must be the real tiles."),
        ("Which direction does play go?", "To the right, counter-clockwise, starting with East's first discard."),
    ],
    related=[("card-sections", "How to read the card: the nine sections"), ("charleston", "The Charleston, explained"), ("jokers", "Jokers in American Mah Jongg"), ("glossary", "Mah Jongg glossary")])

# --- Card sections
sections = parse_sections()
sec_html = """
<h2>Why sections, not hands</h2>
<p>The card prints roughly fifty hands, and they change every spring. Nobody memorizes them. What experienced players do instead is read a rack by family: evens, odds, consecutive numbers, like numbers, winds and dragons, 369, quints, singles and pairs, and the year hand. Those nine sections have the same shape every year. Once you can tell which family your tiles are drifting toward, you only have to read one short part of the card, and the Charleston turns from guessing into sorting.</p>
<p>Below is every section, with the one thing it demands, how to spot it on a rack, and the trap each one sets. Every example rack is an original teaching arrangement showing the shape, not a hand from any card.</p>
"""
for s in sections:
    sec_html += f"""
<section class="section-card" id="{s['key']}">
<h2>{esc(s['name'])}</h2>
<p><strong>What it demands:</strong> {esc(s['requires'].capitalize())}.</p>
<p><strong>How to spot it:</strong> {esc(s['spot'])}</p>
{rack_html(s['rack'])}
<p><strong>Watch out:</strong> {esc(s['watch'])}</p>
</section>"""
sec_html += """
<h2>Reading a rack in three questions</h2>
<ol>
<li><strong>Are the numbers all odd, all even, or mixed?</strong> All even points at 2468; all odd at 13579; a mix with a clear step (4-5-6-7) at Consecutive Run.</li>
<li><strong>Is one number repeating across suits?</strong> That is the signature of Any Like Numbers.</li>
<li><strong>Are the honors piling up?</strong> Winds and dragons collecting with few numbers points at Winds and Dragons.</li>
</ol>
<p>Then count jokers. No jokers and a rack of pairs can be Singles and Pairs, the best-paying section; two or more jokers opens up Quints.</p>
"""
add("card-sections",
    "How to Read the Mah Jongg Card: the 9 Sections Explained",
    "The NMJL card is built from nine sections that keep the same shape every year: 2468, 13579, Consecutive Run, Like Numbers, Winds and Dragons, 369, Quints, Singles and Pairs and the Year hand. Learn to spot each one on a rack.",
    "How to read the card: the nine sections",
    "The card changes every year, but the families it is built from do not. Learn the nine sections and you can read any rack, on any year's card.",
    sec_html,
    faq=[
        ("Does Mahj Trainer include the NMJL card?", "No. The card is copyrighted and changes every year. Mahj Trainer teaches the section structure with original practice hands, so your skills work with whichever card is current. Bring the official card to the table."),
        ("Which section is easiest for a beginner?", "Consecutive Run is the most forgiving, because the run can slide up or down a number while you wait for tiles. 2468 and 13579 are the easiest to recognize at a glance."),
        ("Why does Singles and Pairs pay the most?", "Because jokers are never allowed in it. Every tile has to be the real one, and you cannot call discards for pairs, so it is played entirely from your own rack."),
        ("What is a year hand?", "A hand built from the digits of the current year, with the soap (White Dragon) standing in for any zero. It changes every year by definition."),
    ],
    related=[("how-to-play-american-mahjong", "How to play American Mah Jongg"), ("charleston", "The Charleston, explained"), ("glossary", "Mah Jongg glossary")])

# --- Charleston
add("charleston",
    "The Charleston in American Mah Jongg: Rules, Order and Strategy",
    "How the Charleston works in American Mah Jongg: the three passes, the optional second Charleston, blind passes, the courtesy pass, and a simple strategy for choosing which three tiles to pass.",
    "The Charleston, explained",
    "The Charleston is the passing ritual before play begins. It is the part of the game that scares every new player, and the part that practice fixes fastest.",
    """
<h2>The order of passes</h2>
<p>After the deal and before the first discard, every player passes three tiles at once, three times:</p>
<ol>
<li><strong>First Right.</strong> Pass three tiles to the player on your right.</li>
<li><strong>First Across.</strong> Pass three to the player opposite.</li>
<li><strong>First Left.</strong> Pass three to the player on your left.</li>
</ol>
<p>That is the first Charleston, and it is required. A second Charleston happens only if all four players agree. It runs the other way: Left, Across, Right. Then comes the courtesy pass: an optional exchange across the table of anywhere from zero to three tiles, and both players must pass the same number, so ask first.</p>

<h2>Blind passes and stealing</h2>
<p>Every pass except the last one of each Charleston must come from tiles you have looked at. On the last pass (First Left, and Second Right), you may pass blind: take some or all of the three tiles you were just handed and send them straight on without looking. That is what you do when you genuinely have nothing to spare. Many players call this stealing.</p>

<h2>The one hard rule</h2>
<div class="note"><strong>Jokers never pass.</strong> Not in any Charleston pass, not blind, not in the courtesy pass. Passing a joker is illegal.</div>

<h2>How to choose three tiles</h2>
<p>New players freeze because they try to decide on a hand before the first pass. Do not. The first pass is for clearing junk, and the hand reveals itself over the next two.</p>
<h3>First Right: dump the isolated tiles</h3>
<p>Look for tiles that fit no family at all. A lone wind when everything else is numbers. A single 9 when the rack is low. A third suit when two are already crowded. The first pass is almost never a hard decision; if it is, you are overthinking it.</p>
<h3>First Across: pick a direction</h3>
<p>By now you have seen a few incoming tiles. Ask the three questions from the <a href="card-sections.html">card sections</a> page: odd, even or mixed? One number repeating? Honors piling up? Pass against whatever you are leaning toward. Leaning evens? Odds go.</p>
<h3>First Left: commit or pass blind</h3>
<p>If your rack now reads as one section, pass the last three tiles that do not belong to it. If you are still torn between two sections, keep the tiles both sections share and pass the rest. If nothing can go, pass blind.</p>

<h2>Things to hold even when they look like junk</h2>
<ul>
<li><strong>Flowers.</strong> Many hands want two, three or four. A flower is rarely dead weight early.</li>
<li><strong>Pairs.</strong> A pair is the hardest group to build later, because you cannot call for one. Break a pair last.</li>
<li><strong>Soaps.</strong> They do double duty as the zero in year hands and as the dot suit's dragon, so they are contested.</li>
</ul>

<h2>What you give away</h2>
<p>Every pass tells your neighbor something. Three winds in a row says you are not building Winds and Dragons. Three craks says the crak family is open. Good players read incoming passes the way they read exposures. Do not let that paralyze you; just know it is information.</p>
""",
    faq=[
        ("Is the second Charleston required?", "No. The first Charleston (right, across, left) is required. The second (left, across, right) happens only if all four players agree."),
        ("Can I pass fewer than three tiles?", "Not in the Charleston itself: every pass is exactly three. Only the courtesy pass across the table is zero to three, by agreement."),
        ("What is a blind pass?", "Passing along tiles you were just handed without looking at them. It is allowed only on the last pass of each Charleston: First Left and Second Right."),
        ("Can I pass a joker in the Charleston?", "Never. Not in any pass, not blind, not in the courtesy pass."),
    ],
    related=[("card-sections", "How to read the card: the nine sections"), ("how-to-play-american-mahjong", "How to play American Mah Jongg"), ("jokers", "Jokers in American Mah Jongg")])

# --- Jokers
add("jokers",
    "Joker Rules in American Mah Jongg: Where They Can and Cannot Go",
    "Every joker rule in American Mah Jongg: groups of three or more only, never in pairs or singles, never passed in the Charleston, dead when discarded, and how joker redemption (swapping) works.",
    "Jokers in American Mah Jongg",
    "Eight wild tiles with strict rules. Most beginner mistakes at the table are joker mistakes, and every one of them is avoidable.",
    """
<h2>What a joker can do</h2>
<p>A joker stands in for any tile inside a group of three or more: a pung, a kong, a quint or bigger. A kong is often two natural tiles and two jokers. A quint needs at least one joker by definition, because only four of any tile exist.</p>
<div class="rack">""" + "".join(tile_html(t) for t in ["dot:7", "dot:7", "dot:7", "joker:"]) + """</div>
<p>That kong of 7 Dots is legal: three naturals and a joker.</p>

<h2>What a joker can never do</h2>
<ul>
<li><strong>Sit in a pair.</strong> A pair is two real tiles. Always.</li>
<li><strong>Be a single.</strong> A hand that calls for a lone tile needs the real tile.</li>
<li><strong>Appear in a Singles and Pairs hand.</strong> Those hands have no groups of three, so there is nowhere a joker may sit. That is why they pay the most.</li>
<li><strong>Be passed in the Charleston</strong> or the courtesy pass.</li>
<li><strong>Be called after it is discarded.</strong> A thrown joker is dead for everyone.</li>
</ul>

<h2>Joker redemption (the swap)</h2>
<p>If an exposed group on anyone's rack, including your own, contains a joker, and you hold the real tile it is standing for, you may exchange them on your turn: hand over the real tile, take the joker into your hand. It happens after you draw and before you discard. Once you have thrown, the window closes until your next turn.</p>
<p>This is why good players scan every exposure every turn. A joker sitting in someone else's kong of 5 Bams is yours for the price of a 5 Bam you did not need anyway.</p>
<p>The swap is also the one change an exposure can take after it is locked. Once its owner has discarded, an exposed pung never grows into a kong; the fourth tile stays on the rack or goes to the discards.</p>

<h2>Counting jokers</h2>
<p>There are eight. If you can see six on racks and in the discards, only two are left anywhere, and a quint hand is probably a wish. Counting jokers is the first real "reading the table" skill, and it is cheap: jokers are loud.</p>

<h2>Should you ever discard a joker?</h2>
<p>Almost never. A discarded joker is dead, so it is a safe throw in the narrow sense that nobody can call it, but you are giving up the most flexible tile in the set and telling the table you had one to spare. Throw one only when your hand is complete without it and nothing else is safe.</p>
""",
    faq=[
        ("Can a joker be used in a pair?", "No. Pairs and singles must always be the real tiles. Jokers only work in groups of three or more."),
        ("How many jokers are in a set?", "Eight."),
        ("Can I take a joker from an opponent's exposure?", "Yes, if you hold the real tile it stands for. Hand over the real tile on your turn, before you discard, and take the joker."),
        ("What happens if someone discards a joker?", "It is dead. Nobody can call it, for an exposure or for mah jongg."),
        ("Can jokers be used in a Singles and Pairs hand?", "Never. Those hands have no groups of three or more, so there is nowhere a joker can legally sit."),
    ],
    related=[("charleston", "The Charleston, explained"), ("scoring-and-table-rules", "Scoring and table rules"), ("glossary", "Mah Jongg glossary")])

# --- Scoring and table rules
add("scoring-and-table-rules",
    "American Mah Jongg Scoring and Table Rules: Who Pays What",
    "How payment works when someone wins at American Mah Jongg, when a call is too late, what happens after a wrong mah jongg, dead hands, and wall games.",
    "Scoring and table rules",
    "The rules that come up in the last five minutes of a hand, when the table gets quiet and everyone is counting.",
    """
<h2>Who pays what</h2>
<p>Every hand on the card has a value printed beside it. When someone declares mah jongg, the other three players each pay that value, with these multipliers:</p>
<ul>
<li><strong>Thrown winning tile.</strong> The player who discarded the winning tile pays double. The other two pay the printed value.</li>
<li><strong>Self-picked.</strong> If the winner drew the winning tile from the wall, nobody fed it, so everyone pays double.</li>
<li><strong>Jokerless.</strong> A winning hand with no jokers in it doubles the payment again. Singles and Pairs hands are the exception: they can never hold a joker, so they get no jokerless bonus.</li>
</ul>
<p>The bonuses stack. Outside Singles and Pairs, self-picked and jokerless means each player pays four times the printed value.</p>

<h2>Calling: how late is too late</h2>
<p>You may call a discard until the next player has drawn a tile and racked it. After that the discard is gone. Speak up quickly, and say the tile's name when you throw so others have the chance to call.</p>
<p>Calling replaces your draw. Lay the completed pung, kong or quint face up on your rack, then discard, and play continues to your right from you.</p>
<p>When two players want the same discard for an exposure, it goes to whoever is next in turn after the discarder, unless the other caller has already put the tile on their rack or exposed tiles for it. A call for mah jongg beats any exposure.</p>

<h2>Exposures are final</h2>
<p>Once you have discarded after exposing a group, it is locked. A pung never becomes a kong later; the fourth tile stays on your rack or goes to the discards. The one change still allowed is a joker swap: someone hands you the real tile and takes the joker.</p>

<h2>Dead hands</h2>
<p>A hand that can no longer legally win is dead. The usual causes: an exposure that matches no hand on the card, or laying down a wrong mah jongg. Once another player calls it dead and the tiles prove it, that player stops drawing and discarding but still pays the winner. Nobody calls their own hand dead: if you know yours is hopeless, keep playing and play defense. Check the card before you expose, not after.</p>

<h2>A wrong mah jongg</h2>
<p>Once a wrong hand is laid down, it is dead. The other three keep playing, and the player who called it still pays whoever eventually wins. Be sure before you say the word.</p>

<h2>Wall games</h2>
<p>If the wall runs out before anyone wins, nobody pays. The tiles are reshuffled and the next hand is dealt. Wall games happen more often than beginners expect, which is why chasing a hopeless hand to the end costs nothing, and also earns nothing.</p>

<h2>Safe tiles and hot tiles</h2>
<p>Late in a hand, defense matters more than your own rack. A hot tile is one that plainly helps someone, usually because their exposures point at it: two even pungs on a rack means every even tile you throw is risky. A safe tile is one already discarded twice with no reaction, or one that clashes with every exposure on the table. Keeping a safe tile in reserve for the endgame is a habit worth building early.</p>
""",
    faq=[
        ("What does the discarder pay?", "Double the hand's printed value. The other two players pay the printed value."),
        ("What if the winner picked the winning tile from the wall?", "Everyone pays double."),
        ("Is there a bonus for a hand with no jokers?", "Yes, payment doubles again. Singles and Pairs hands are excluded, since they can never contain a joker."),
        ("What happens on a wall game?", "Nobody pays. Reshuffle and deal the next hand."),
        ("Can a dead hand still be charged?", "Yes. A dead hand stops playing but still pays the winner."),
    ],
    related=[("jokers", "Jokers in American Mah Jongg"), ("how-to-play-american-mahjong", "How to play American Mah Jongg"), ("glossary", "Mah Jongg glossary")])

# --- Glossary
terms = parse_glossary()
groups = [("tiles", "Tiles"), ("groups", "Groups and hands"), ("charleston", "The Charleston"), ("play", "At the table")]
gl = "<p>Every term below is also searchable inside Mahj Trainer, one tap from the home screen, including the nicknames (soap, NEWS, wild) people actually say at the table.</p>"
defined = []
for key, title in groups:
    gl += f"<h2>{title}</h2>"
    for t in [t for t in terms if t["group"] == key]:
        aka = f'<span class="aka">Also: {esc(", ".join(t["aliases"]))}</span>' if t["aliases"] else ""
        gl += f'<div class="term" id="{t["id"]}"><h3>{esc(t["term"])}</h3>{aka}<p>{esc(t["definition"])}</p></div>'
        defined.append({"@type": "DefinedTerm", "name": t["term"], "description": t["definition"]})
add("glossary",
    "American Mah Jongg Glossary: Every Term Explained (Soap, Pung, Kong, Charleston)",
    "A plain-English glossary of American Mah Jongg terms: craks, bams, dots, soap, pung, kong, quint, exposure, Charleston, blind pass, courtesy pass, joker swap, hot tile, wall game and more.",
    "Mah Jongg glossary",
    "Short definitions, written to be read standing at a table with a rack in front of you.",
    gl,
    related=[("how-to-play-american-mahjong", "How to play American Mah Jongg"), ("card-sections", "How to read the card: the nine sections"), ("charleston", "The Charleston, explained")])

# --- Hub
hub = '<div class="hub">' + "".join(
    f'<a href="{slug}.html"><strong>{esc(h1)}</strong><span>{esc(desc)}</span></a>' for slug, h1, desc in pages) + "</div>"
hub += """
<h2>About these guides</h2>
<p>Everything here comes from the same reference material built into Mahj Trainer, written for people who learned the game at someone's kitchen table and want the rules straight before next week. The examples are original teaching hands. The card itself belongs to the National Mah Jongg League, changes every spring, and is the one thing you still need to buy.</p>
"""
add("index",
    "Learn American Mah Jongg: Rules, the Card, the Charleston, Jokers and Scoring",
    "Free American Mah Jongg guides from Mahj Trainer: how to play, reading the card's nine sections, the Charleston, joker rules, scoring and a full glossary.",
    "Learn American Mah Jongg",
    "Free, plain-English guides for new players. Read them here, then practice them in the app.",
    hub)
pages.pop()  # the hub is not listed on itself

(learn / "learn.css").write_text(CSS.strip() + "\n")

# --- sitemap and robots
urls = [BASE, BASE + "learn/"] + [f"{BASE}learn/{slug}.html" for slug, _, _ in pages] + [BASE + "support.html", BASE + "privacy-policy.html", BASE + "terms.html"]
(out / "sitemap.xml").write_text('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
    "".join(f"  <url><loc>{u}</loc><lastmod>{TODAY}</lastmod></url>\n" for u in urls) + "</urlset>\n")
(out / "robots.txt").write_text(f"User-agent: *\nAllow: /\nSitemap: {BASE}sitemap.xml\n")
print("wrote", [p[0] for p in pages], "+ index, sitemap, robots")
