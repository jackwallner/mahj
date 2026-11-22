# 2027 card season event and nomination (drafted 2026-11-20)

Avenue 3 of the 2026-11-20 contacts council. The event below is a DRAFT; nothing here is submitted. The Hanukkah event and nomination drafted alongside it were dropped on 2026-11-21 (Jack: Hanukkah seems weird) in favour of the December challenge, `../2026-12-challenge/`.

## What is real in the app
- Daily rounds exist for every date. April 2027 is a Reading Your Rack month (`MonthlyChallengeContent.rotationAnchor`); the event is framed on those rounds.
- Risk: App Review (2.3.13) may call a card-change framing on existing rounds thin. Upgrade path if rejected: a build-side tie-in to the new card.

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
- Card season: ALREADY SUBMITTED on 2026-11-18, `85777c9c-f109-4cbc-9b3d-68181e89e1b2` (NEW_CONTENT, Apr 1 to May 1 2027,
  `hasInAppEvents` true, no event linked). Not duplicated. When the event is approved, link it to that nomination and
  correct the dates if NMJL's differ. Apple's note: nomination text can only change by archiving and recreating.

## To submit (only on Jack's yes, after NMJL posts the 2027 card)
```bash
set -a; source ~/.baseball_credentials; cd ~/football/scripts
python3 asc-app-event.py ~/mahj/project-docs/marketing/in-app-events/2026-11-20-card-season/card-season/event.json --submit
```
The script reuses the event id in the spec (no duplicate) and re-uploads the media.

## Found on the way
- An unsubmitted reviewSubmission `a27bb772-8274-4ecb-9963-0abc927b7f77` (READY_FOR_REVIEW, one item) was already
  on the app before this work. Left alone.
