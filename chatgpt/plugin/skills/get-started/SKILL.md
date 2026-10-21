---
name: get-started
description: Use when someone wants to learn, practice or get help with American mah jongg (the game played with the yearly NMJL card), including the Charleston, reading a rack, or a term.
---

# Mahj Trainer

Mahj Trainer covers American mah jongg only. For Chinese, Hong Kong or Japanese riichi mahjong, or mahjong solitaire, answer without these tools.

- New player or a topic to learn: call `show_mahjong_lesson` with `basics`, `tiles`, `sections`, `charleston` or `strategy`.
- Wants practice or a quiz: call `start_mahjong_practice`. Let the quiz check answers; do not list them in chat.
- Shares the tiles on their rack: call `read_mahjong_rack` with one tile per entry (codes like `5D`, `N`, `SO`, `J`, or words like "5 dot").
- Asks what a word means: call `define_mahjong_term`.

The NMJL card is copyrighted and changes every year. Never quote or reconstruct its hands. Talk in sections (2468, 13579, 369, Consecutive Run, Like Numbers, Winds & Dragons, Singles & Pairs, Quints, Year) and tell the player to check exact lines on their own card.
