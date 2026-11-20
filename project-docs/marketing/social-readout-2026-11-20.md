# @mahjtips readout, 2026-11-20: the style test is decided

Per-post numbers from TikTok Studio at 1:10 PM PT, 74 live posts (the style test's final read was due Nov 24; the
answer is already clear). The full pattern, the measuring rule and the Bridge and Knit carryover are in
`~/ios/growth/social-autopost/what-works.md`.

## Result

| Style | Posts | Median views | Avg watch | Still there at 2 s | Follows per 1,000 views |
|---|---|---|---|---|---|
| slow (table pace, 45 to 50 s) | 4 | 1,424 | 16.6 s | 61% | 8.0 |
| control (21 to 27 s) | 18 | 362 | 8.1 s | 46% | 6.4 |
| thread | 4 | 328 | 7.8 s | 42% | 7.1 |
| course | 4 | 306 | 6.5 s | 45% | 5.9 |
| fix | 4 | 244 | 6.1 s | 38% | 0 |
| pick | 5 | 230 | 4.2 s | 35% | 0 |
| carousel | 26 | 427 | 7.9 s | | 1.4 |

- Scale: slow. V47 "How to set up a mahjong game" has 6,033 views and 46 follows, the account's biggest post. V44
  1,964, V48 884, V45 534. Every one beat every other post in the test.
- Kill: pick and fix (below control on follows and watch time, 0 follows from 9 posts).
- The same lesson decides nothing: table setup got 6,033 at table pace and 157 to 418 in four other styles.
- Average watch time is the gate. 4 of 5 posts at 11 s or more passed 1,000 views; 0 of 38 below it did.
- Charleston topics still earn the most follows: 15 per 1,000 views against 2.6 for which-hand topics.
- YouTube and Instagram agree: V47 is first on both (207 views against a median of 33; 16 likes against 1).
- The two all-time Charleston posts (5,502 and 2,478 views, 152 follows) share the same traits: a complete
  answer to the first thing a beginner dreads, on the cloth table.

## Changes made

- 21 new table-pace shorts (B41 to B61, at least 8 on the Charleston) are building on the iMac (fleet run
  20261120-132417-a91b). `mahj-refill-prompt.md` now asks for this format on every refill, and the refill fires
  when under 14 table-pace shorts are left.
- `queue_backlog.py` orders every unscheduled row on all three platforms: table pace in TikTok's 11:30 AM and
  5:30 PM slots, 6:30 AM for the rest (complete beginner answers first, pick and fix last). Instagram and YouTube
  run best first. The backlog (B01 to B40) is now queued on Instagram and YouTube too; before, both ran dry on Dec 7.
- TikTok from Nov 30: V78, V85, V92, V99 and V106 (the five unscheduled slow shorts) moved up to Nov 30 to Dec 2,
  and the new batch follows them. Instagram: V99 moved from Dec 5 to Nov 21.

## Left as is

- TikTok Nov 21 to 29 is already scheduled (28 posts, 9 of them pick or fix). Studio web can't delete them
  because of the Your brand disclosure; the phone app can. Waiting on Jack.
- YouTube through Dec 6 is uploaded and scheduled in Studio.

## Next read

Nov 27: the first B41+ posts at 72 hours against the 11 s average watch gate. `stats/post-insights.mjs` and
`stats/post-table.py` in social-autopost pull the table.
