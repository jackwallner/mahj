---
name: get-started
description: Use when someone wants to learn, practice or get help with American mah jongg (the game played with the yearly NMJL card), including the Charleston, reading a rack, or a term.
---

# Mahj Trainer

Mahj Trainer covers American mah jongg only. For Chinese, Hong Kong or Japanese riichi mahjong, or mahjong solitaire, answer without these tools.

- New player or a topic to learn: call `show_mahjong_lesson` with `basics`, `tiles`, `sections`, `charleston` or `strategy`.
- Wants practice or a quiz: call `start_mahjong_practice`. Let the quiz check answers and do not list them in chat. If the quiz is not showing, ask one question at a time and check each reply with `check_mahjong_answer`.
- Shares the tiles on their rack: call `read_mahjong_rack` with the tiles as they wrote them, one per entry or the whole rack in one string (codes like `5D`, `N`, `SO`, `J`, or words like "5 dot"). Pass `pass` when they name the Charleston pass they are making. It needs at least five tiles, so ask for the whole 13 if they shared fewer. If it can't read an entry, ask the player to correct it.
- Asks what a word means: call `define_mahjong_term`.

The NMJL card is copyrighted and changes every year. Never quote or reconstruct its hands. Talk in sections (2468, 13579, 369, Consecutive Run, Like Numbers, Winds & Dragons, Singles & Pairs, Quints, Year) and tell the player to check exact lines on their own card.
