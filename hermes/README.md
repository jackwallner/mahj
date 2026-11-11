# Mahj Trainer for Hermes Agent

Mahj Trainer teaches American mah jongg, the game played with the yearly National Mah Jongg League card. This package connects Hermes to the Mahj Trainer MCP server and adds one skill that tells the agent when to use it.

```
hermes plugins install mahj-trainer
```

## What you can ask

- "Teach me how American mah jongg works." A short lesson on the basics, the tiles, the card's sections, the Charleston or keep-or-throw judgment.
- "Quiz me on the Charleston." Practice questions, each checked and explained.
- "Read my rack: 2C 2C 4C 4C 6B 6B 8B 8D F J 1C 9B N. What should I pass?" The sections your rack leans toward, three tiles to pass with a reason for each, and the pairs to build on.
- "What is a joker swap?" Plain definitions from the Mahj glossary.

## Tools

| Tool | What it does |
|---|---|
| `show_mahjong_lesson` | A lesson on `basics`, `tiles`, `sections`, `charleston` or `strategy` |
| `start_mahjong_practice` | A practice quiz on a topic |
| `check_mahjong_answer` | Checks one practice answer and explains it |
| `read_mahjong_rack` | Reads a rack against the card's sections and suggests a pass |
| `define_mahjong_term` | Defines a mah jongg term |

Every tool is read-only. The server needs no account, no key and no sign-in.

## About the card

The NMJL card is copyrighted and changes every year. Mahj Trainer talks in the card's stable sections (2468, 13579, 369, Consecutive Run, Like Numbers, Winds & Dragons, Singles & Pairs, Quints, Year) and never reproduces card hands, so keep your own card handy for the exact lines. Not affiliated with or endorsed by the National Mah Jongg League.

## Privacy

Tool calls go to the hosted server at `mahj.mahjtrainer.workers.dev`, which keeps no accounts and stores nothing about you. [Privacy policy](https://jackwallner.com/ios/mahj/privacy-policy.html#chatgpt).

## The app

Mahj Trainer is also a free practice app for iPhone, iPad and Android: [jackwallner.com/ios/mahj](https://jackwallner.com/ios/mahj/).
