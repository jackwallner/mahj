#!/usr/bin/env python3
"""Five more posts in A1's mold, the kit's best performer (771 views by Oct 28, about 2x the next).

    python3 more_like_a1.py [--out <dir>]

Same template as A1: a numbered "5 things I wish I knew" hook over real tiles, one or two
numbered tips per slide, tip 3 on the app slide, a save prompt on slide 5, and A1's caption shape
with the "comment app" CTA. Renders into the kit's "More like A1" folder.
"""
from __future__ import annotations

import argparse
import pathlib

import build_kit as K

TAGS = ("#mahjong", "#americanmahjong", "#mahj", "#mahjongtiktok")

POSTS = [
    dict(id="A7", seed=7, hook="5 things I wish I knew before my first Charleston",
         s2="1. The first Charleston always happens. Pass right, then across, then left.",
         s3="2. Pick 2 or 3 sections before you pass, then pass the tiles none of them use.",
         s4="3. Pass singles before pairs. A pair is much harder to rebuild than a single.",
         s5="4. On the last pass of each Charleston you can blind pass the tiles you were just handed.\n"
            "5. Any player can stop the second Charleston. Save this for game night.",
         shots=("charleston", "charleston_answered"), rack="charleston_rack",
         caption="Everything I'd tell a friend before their first Charleston: the pass order, what to pass, "
                 "and the blind pass."),
    dict(id="A8", seed=8, hook="5 things I wish I knew about jokers in mahjong",
         s2="1. There are 8 jokers. Each one can stand in for any tile in a pung, a kong or a quint.",
         s3="2. Singles and pairs always take real tiles. Save your jokers for the groups.",
         s4="3. Check the card before you count on a joker. Hands full of pungs and kongs use them best.",
         s5="4. On your turn, trade the real tile for a joker in anyone's exposure.\n"
            "5. Once a joker is discarded, it stays on the table. Save this.",
         shots=("play", "reference"), rack="play_rack",
         caption="Everything I'd tell a friend about jokers in American mahjong: where they fit, joker swaps, "
                 "and discarded jokers."),
    dict(id="A9", seed=9, hook="5 things I wish I knew about the mahjong card",
         s2="1. A new card comes out every spring, and last year's hands retire.",
         s3="2. Hands are grouped into sections like 2468, 13579, Like Numbers and Winds and Dragons.",
         s4="3. Colors show how many suits a hand uses. One color means one suit, three colors means three.",
         s5="4. X means you can expose. C means the hand stays concealed until mahjong.\n"
            "5. The number on the right is the hand's value. Bigger numbers, harder hands. Save this.",
         shots=("hand_match", "hand_match_answered"), rack="hand_match_rack",
         caption="Everything I'd tell a friend about reading the American mahjong card: sections, colors, "
                 "X and C, and hand values."),
    dict(id="A10", seed=10, hook="5 things I wish I knew about discarding in mahjong",
         s2="1. Say every discard out loud as you set it down.",
         s3="2. Early on, throw the tiles your sections never use.",
         s4="3. Keep or throw? Ask which of your 2 hands the tile helps. If it helps neither, it goes.",
         s5="4. When 3 of a tile are already showing, a pung of it gets very hard.\n"
            "5. Late in the game, the safest discard is a tile already on the table. Save this.",
         shots=("keep", "keep_answered"), rack="quick_rack",
         caption="Everything I'd tell a friend about discards in American mahjong: what to throw early, "
                 "keep or throw, and safe late-game discards."),
    dict(id="A11", seed=11, hook="5 things I wish I knew about calling tiles in mahjong",
         s2="1. Call a discard to finish a pung, a kong or a quint, then expose it on your rack.",
         s3="2. A call for mahjong beats a call for an exposure.",
         s4="3. Each call shows the table your hand. Call when it gets you a lot closer.",
         s5="4. If two players call the same tile for exposures, the next player in turn gets it.\n"
            "5. Concealed hands can call a discard only for mahjong. Save this.",
         shots=("play", "quick_answered"), rack="play_rack",
         caption="Everything I'd tell a friend about calling tiles in American mahjong: exposures, "
                 "who gets the tile, and concealed hands."),
]


def caption_txt(post: dict) -> str:
    return (
        f"TITLE (photo mode title field):\n{post['hook']}\n\n"
        f"CAPTION (paste as is):\n{post['caption']} Which one did you learn the hard way?\n\n"
        f"{K.P.CTAS['comment']}\n\n{' '.join(TAGS)}\n\n"
        f"PINNED COMMENT (post it yourself, then pin):\n{K.P.PINNED}\n\n"
        f"REPLY to every \"app\" or \"name?\" comment:\n{K.P.REPLY}\n\n"
        f"BEFORE POSTING: More options > Disclose post content > Your brand.\n"
        f"SOUND (Commercial Music Library): {K.P.SOUNDS['cozy']}\n"
    )


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(K.ICLOUD / "More like A1"))
    out = pathlib.Path(ap.parse_args().out)
    for post in POSTS:
        folder = out / f"{post['id']} {post['hook']}"
        folder.mkdir(parents=True, exist_ok=True)
        seed = post["seed"]
        slides = [
            K.hook_slide(post, seed),
            K.card_slide(seed, post["s2"], None),
            K.card_slide(seed, post["s3"], post["rack"]),
            K.app_slide(post["s4"], post["shots"]),
            K.card_slide(seed, post["s5"], None),
        ]
        for n, s in enumerate(slides, 1):
            s.save(folder / f"{n}.jpg", quality=92)
        (folder / "caption.txt").write_text(caption_txt(post))
    print(f"wrote {len(POSTS)} posts to {out}")


if __name__ == "__main__":
    main()
