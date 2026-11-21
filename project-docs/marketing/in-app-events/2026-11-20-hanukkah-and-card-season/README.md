# Hanukkah 2026 and 2027 card season: events and nominations (drafted 2026-11-20)

Avenue 3 of the 2026-11-20 contacts council. Nothing here is submitted. Every ASC object below is a DRAFT.

## What is real in the app
- Daily rounds exist for every date (five questions, same for every player). December 2026 is the Safe Discards month
  (`MonthlyChallengeContent.rotationAnchor`: Nov Charleston, Dec Safe Discards, Jan Reading Your Rack, Apr Reading Your Rack).
- Nothing in the app is Hanukkah specific. The Hanukkah event is therefore framed around the real December rounds:
  one Safe Discards round a night for the eight nights. No build is needed; the link `mahj://challenge` works on 1.4.5.
- Risk: App Review (2.3.13) may call a holiday framing on existing rounds too thin. The smallest real upgrade, if it
  is rejected, is an eight-night tally on the challenge card in a new build (needs App Review before Dec 4).
- The card art shows the grid line "Play Today's Mahj Minute" and no end date, so it does not contradict Dec 4 to 12.

## Hanukkah event (ASC id 6837594396, DRAFT)
| Field | Value |
|---|---|
| Reference name | Hanukkah 2026 Eight Nights Safe Discards |
| Name (20) | Eight Nights of Mahj |
| Short (34) | One Safe Discards round each night |
| Long (89) | Hanukkah begins December 4. Play each night's Safe Discards round, eight nights in a row. |
| Badge | SPECIAL_EVENT |
| Deep link | mahj://challenge |
| Publish | 2026-11-28 16:00 UTC |
| Event | 2026-12-04 00:00 PST to 2026-12-12 23:59 PST |
| Media | `hanukkah/event-card-1920x1080.png`, `hanukkah/event-details-1080x1920.png` (real December captures, iPhone 17e sim, Debug `-ChallengeMonth 2026-12-05`) |

Copy follows the 2.3.7 rule: no price, free, trial or discount words.

## New card season event (ASC id 6837594557, DRAFT)
Dates are placeholders until NMJL posts the 2027 card in January. Change `event_start`, `event_end`, `publish_start`
in `card-season/event.json` and PATCH the event's territory schedule before submitting.
| Field | Value |
|---|---|
| Reference name | New Card Season 2027 Reading Your Rack |
| Name (19) | New Card, New Racks |
| Short (43) | Three new Reading Your Rack questions a day |
| Long (110) | Every April the card changes. This month, spot which section a rack is heading for. Three new questions a day. |
| Badge | NEW_SEASON |
| Deep link | mahj://challenge |
| Publish | 2027-03-18 16:00 UTC (placeholder) |
| Event | 2027-04-01 to 2027-04-30 (placeholder) |
| Media | `card-season/` same two sizes, real April 2027 captures |

## Nominations
- Holiday window: DRAFT `b1c3d868-6020-4318-964a-3a129495c644` (NEW_CONTENT, Dec 4 to 13, iPhone and iPad, EN-US).
  Text is in the ASC record. Apple wants 14 days of lead; Dec 4 is exactly 14 days out from Nov 20, so submit by
  Nov 21 PST. The event cannot be linked while it is a DRAFT (400): submit the event, then add it under `inAppEvents`.
- Card season: ALREADY SUBMITTED on 2026-11-18, `85777c9c-f109-4cbc-9b3d-68181e89e1b2` (NEW_CONTENT, Apr 1 to May 1 2027,
  `hasInAppEvents` true, no event linked). Not duplicated. When the event is approved, link it to that nomination and
  correct the dates if NMJL's differ. Apple's note: nomination text can only change by archiving and recreating.

## To submit (only on Jack's yes)
```bash
set -a; source ~/.baseball_credentials; cd ~/football/scripts
python3 asc-app-event.py ~/mahj/project-docs/marketing/in-app-events/2026-11-20-hanukkah-and-card-season/hanukkah/event.json --submit
# nomination: PATCH /v1/nominations/b1c3d868-... {"submitted": true}
```
The script reuses the event id in the spec (no duplicate) and re-uploads the media.

## Found on the way
- No December 1 to 31 monthly event exists in ASC for the Safe Discards month (November's is the only published one).
- An unsubmitted reviewSubmission `a27bb772-8274-4ecb-9963-0abc927b7f77` (READY_FOR_REVIEW, one item) was already
  on the app before this work. Left alone.
