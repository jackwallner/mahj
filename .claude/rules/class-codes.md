---
paths:
  - "Shared/Services/ClassCodeService.swift"
  - "MahjTrainer/Views/ClassCodeView.swift"
  - "MahjTrainer/Views/HomeView.swift"
  - "MahjTrainer/MahjTrainerApp.swift"
  - "supabase/migrations/20261125120000_class_codes.sql"
---

# Mahj: class codes for teachers (1.4.7, 2026-11-24)

**Why:** the teacher outreach loop ended when the offer codes went out: the
teacher never saw their class in the app, and Jack could not tell which
teachers brought in members. Jack approved v1 on 2026-11-24 ("yes to all
three"): a class code, the teacher's name and weekly focus on Home, and
per-teacher attribution. Pilot with OK Let's Mahjong (code `OKLETS`) only;
Jack edits their focus by hand. No student progress reports (that would need
a consent screen and a privacy label change).

## How it works

- A student types the code in Settings > Class Code, or opens
  `mahj://class/<CODE>` (also `?code=`). `ClassCode.normalized` uppercases
  and keeps A-Z0-9, 4 to 12 long, the same shape the table enforces.
- `ClassCodeService` calls the `class_fetch` RPC (Supabase project
  `ucoveqbyfuxqvpysmixu`, publishable key shared with feedback), which
  returns `{name, focus_room}` or `null`, and upserts a random per-install
  token into `class_members` (simulator runs all use the zero UUID). The
  class is cached in UserDefaults and refreshed on every foreground, at most
  every 15 minutes. A `null` drops the class (Jack set `active = false`); a
  failed request keeps it.
- Home shows one card under Get Started: "<CLASS NAME> · THIS WEEK", the
  focus room's name and tagline, opening that room. An unknown room id shows
  no card, so a future room can be added to the server list only after the
  build that has it is out.
- `class_code` rides to RevenueCat as a subscriber attribute and to PostHog
  as a person property and super property; `class_joined` / `class_left`
  events. Read trials and members per teacher from RevenueCat customers
  filtered by that attribute.

## Hard limits (App Review)

- The code never unlocks Mahj+ (3.1.1). Access still comes only from Apple
  offer codes. The class layer is branding and focus.
- Teachers never type content into the app: that is user-generated content
  (1.2 moderation duties) and a route for NMJL card hands. Jack picks the
  focus from rooms the build already ships.
- New teacher content ships as data only (rooms the binary has). Downloaded
  code is out (2.5.2).

## Running it

- Change a focus: `update public.classes set focus_room = 'table-room',
  updated_at = now() where app = 'mahj' and code = 'OKLETS';` Players see it
  within 15 minutes of their next return to the app.
- Add a class: insert `(app, code, name, focus_room)`; name at most 40
  characters, shown uppercased in the card's caption.
- Count joins and weekly actives: `select code, count(*), count(*) filter
  (where last_seen > now() - interval '7 days') from class_members group by 1`.
  The zero UUID row is the simulator.
- `MAHJTEST` (Test Class, card-room) exists for QA. DEBUG builds can pin a
  class with no network: `-mahj.class OK_Lets_Mahjong,charleston-room` (underscores read as spaces).
- Room ids allowed by the table's check constraint must match
  `DrillLibrary.rooms` (`ClassCodeTests`).
