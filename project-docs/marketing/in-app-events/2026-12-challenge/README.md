# December 2026 Mahj Challenge (Safe Discards)

ASC event `6837887765` (CHALLENGE, deep link `mahj://challenge`). Submitted 2026-11-21 on Jack's yes: reviewSubmission `3a2e0ea0-7848-4034-8918-6a992bc227f3` (event only, WAITING_FOR_REVIEW); nomination `b1c3d868` SUBMITTED (Dec 1 to Jan 1). Link the event to the nomination once Apple accepts it.
Built like November's (`../2026-11-challenge/`), per `.claude/rules/monthly-challenge.md`.

| Field | Value |
|---|---|
| Reference name | Monthly Challenge 2026-12 Safe Discards |
| Name (23) | December Mahj Challenge |
| Short (39) | Three new Safe Discards questions a day |
| Long (116) | A new challenge every month. December is Safe Discards: three new questions a day. Your best 20 days are your score. |
| Publish | 2026-11-22 16:00 UTC (live as soon as approved if later) |
| Event | 2026-12-01 00:00 PST to 2026-12-31 23:59 PST (2027-01-01 07:59 UTC) |
| Media | real December captures (iPhone 17e sim, Debug `-ChallengeMonth 2026-12-05`): five-question round, "December Challenge" label |

Copy check against the app: rounds are five questions (three themed plus two Table Room), scored best 20 days.
"Three new Safe Discards questions a day" matches November's approved wording; the themed count is three.
No price, free, trial or discount words (2.3.7).

Nomination: `b1c3d868-6020-4318-964a-3a129495c644`, NEW_CONTENT, Dec 1 to Jan 1, DRAFT (reworked from the dropped
Hanukkah draft). Apple's 14-day lead for Dec 1 ended Nov 17, so it may publish late. A DRAFT event cannot be
linked via `inAppEvents` (400): submit the event, then link it.

Submit (only on Jack's yes), event alone in its own review submission:
```bash
set -a; source ~/.baseball_credentials; cd ~/football/scripts
python3 asc-app-event.py ~/mahj/project-docs/marketing/in-app-events/2026-12-challenge/event.json --submit
# nomination: PATCH /v1/nominations/b1c3d868-... {"submitted": true}
```
Review submission `a27bb772` (READY_FOR_REVIEW, one version item, not ours) is left alone; the script opens a new one.
