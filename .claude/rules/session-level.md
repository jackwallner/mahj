---
paths:
  - "Shared/Content/ItemDifficulty.swift"
  - "Shared/Content/SessionBuilder.swift"
  - "Shared/Services/ProgressStore.swift"
  - "MahjTrainerTests/SessionLevelTests.swift"
---

# Mahj: questions that fit the player (2026-11-24)

Why: Donna Adam, an accredited instructor, found lessons too advanced for
beginners and asked for basic / intermediate / challenging levels. Jack chose
no beginner mode, no picker and no labels: the sessions themselves pick
questions that fit. Teachers are a referral channel and most buyers come
straight from lessons, so a first session must feel easy.

- Every drill item has one tier in `ItemDifficulty.table` (one table, by id,
  grouped by room). `SessionLevelTests` fails an untagged library item, a
  stray id, or a basic question whose prompt or choices say pung, kong, quint
  or sextet (only `quiz-pung` and `plus-tq-kong`, which teach the words, may).
  Tag new content when you add it.
- Basic: tile names, suits, dragons, jokers, the set, reading a card line.
  Intermediate: groups, calling, exposing, scoring, sections, rack reading.
  Challenging: rule-of-thumb strategy, defense, decoy racks, edge rules.
- Seed from onboarding (`mahj.skillLevel`): `new` basic, `basics`
  intermediate, `played` or unset challenging (unset is a pre-question
  player, who keeps the old full mix).
- `ProgressStore.sessionCeiling(includePro:)` raises the ceiling a tier once
  60% of the tier's reachable items are answered and 80% of those stand
  right (latest answer, `seenItems`/`missedItems`). The reached tier is kept in
  `progress.reachedLevel`, so it never drops; `resetAll()` clears it back to
  the seed. It writes plain defaults only (views call it while building a
  session; a published write there would loop, see the iOS 18 freeze).
- Quick Session, the tour's closing session and Game Night Prep filter to the
  ceiling. Misses and due items still come back first. A pool too small to
  fill a session pads with the easiest tier above. Fix My Mistakes is
  untouched (it is the player's own misses).
- Android still runs the old order (`SessionBuilder` is hand-ported Kotlin);
  the tiers are not in the content export yet.
