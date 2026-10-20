# Localized App Store screenshots, 2026-10-19

## Locale selection

The 90-day download ranking uses App Store Connect Summary Sales reports for
July 21 through October 18, the last 90 complete days available. It filters to
Mahj Trainer's Apple ID and app-unit product types, excluding redownloads and
updates. The July 20 row was removed from the first weekly report to keep the
period exact. Apple's [Summary Sales Report reference](https://developer.apple.com/help/app-store-connect/reference/reporting/summary-sales-report/)
defines the report fields, and [Product Type Identifiers](https://developer.apple.com/help/app-store-connect/reference/reporting/product-type-identifiers)
distinguishes app-unit types `1`, `1F`, and `1T` from redownloads and updates.

The product-page-view ranking uses non-overlapping App Store Discovery and
Engagement data for September 1 to 30, October 5 to 11, and October 16 to 18.
The report's `Territory`, `Event`, `Page Type`, and `Counts` fields identify
product-page views by storefront. Apple's [report reference](https://developer.apple.com/documentation/analytics-reports/app-store-discovery-and-engagement)
defines these fields and says the territory is the App Store country or region.

The available page-view data does not cover 90 days. The existing ongoing
request had no view data before September, and its daily records include a
rolling three-day window. The filtered daily queries were rate limited before
all records for October 1 to 18 could be collected. One already available
daily instance provided the October 16 to 18 rows. To avoid counting
overlapping dates twice, this ranking uses September's monthly report, the
complete week of October 5, and those daily rows. That covers 40 calendar days,
with October 1 to 4 and October 12 to 15 missing. The existing one-time
snapshot had no populated App Store Discovery instances, and no new App Store
Connect analytics request was created.

Ranks are shown instead of analytics totals. The three selected non-English
storefronts are above about 1% of observed product-page views, and they also
showed download activity in the 90-day Sales reports.

| Storefront | ASC locale | Page-view rank | 90-day app-unit rank | Decision |
| --- | --- | ---: | ---: | --- |
| United States | en-US | 1 | 1 | Existing baseline |
| Canada | en-CA / fr-CA | 2 | 2 | en-CA copy matches en-US. ASC reports combine English and French traffic for Canada, so fr-CA cannot be measured separately. |
| Vietnam | vi | 3 | 4 | Localize |
| Mexico | es-MX | 4 | 3 | Localize |
| Indonesia | id | 5 | 5 | Localize |

The next non-English storefronts, including Japan, France, Korea, Italy,
Thailand, Germany, Spain, Brazil, and the Chinese locales, were below about 1%
of observed product-page views and were skipped. The English storefronts
en-CA, en-GB, and en-AU do not need separate sets because their screenshot copy
does not differ from en-US.

RevenueCat was not consulted, in line with the brief's limit.

## Captions and back-translations

The app UI remains in English. Only the eight large screenshot captions were
translated. Copy stays benefit-led, avoids prices and free claims, and keeps
American Mah Jongg terminology distinct. Existing localized listing terms for
`rack`, rooms, and tiles guided the word choices.

### es-MX

| # | Caption | Back-translation |
| ---: | --- | --- |
| 1 | Pasa con un plan | Pass with a plan |
| 2 | Lee tu rack antes de elegir | Read your rack before choosing |
| 3 | Sabe qué fichas conservar | Know which tiles to keep |
| 4 | Te guía en cada descarte | It guides you on every discard |
| 5 | Elige la sala que necesitas | Choose the room you need |
| 6 | Aprende todas las familias de fichas | Learn all tile families |
| 7 | Reconoce la ficha que necesitas | Recognize the tile you need |
| 8 | Ve el patrón que busca tu rack | See the pattern your rack is looking for |

### vi

| # | Caption | Back-translation |
| ---: | --- | --- |
| 1 | Trao quân có kế hoạch | Pass tiles with a plan |
| 2 | Đọc khay bài rồi hãy chọn | Read the rack, then choose |
| 3 | Biết nên giữ quân nào | Know which tile to keep |
| 4 | Được hướng dẫn mỗi lần bỏ quân | Get guidance each time you discard a tile |
| 5 | Chọn phòng luyện tập phù hợp | Choose a suitable practice room |
| 6 | Làm quen với mọi họ bài | Get to know every tile family |
| 7 | Nhận ra quân bài bạn cần | Recognize the tile you need |
| 8 | Nhìn ra mẫu bài hợp với khay bài | See the hand pattern that fits your rack |

### id

| # | Caption | Back-translation |
| ---: | --- | --- |
| 1 | Oper ubin dengan rencana | Pass tiles with a plan |
| 2 | Baca rak sebelum memilih | Read your rack before choosing |
| 3 | Tahu ubin mana yang perlu disimpan | Know which tiles to keep |
| 4 | Dibimbing setiap kali membuang ubin | Get guidance each time you discard a tile |
| 5 | Pilih ruang latihan yang kamu butuhkan | Choose the practice room you need |
| 6 | Kenali setiap keluarga ubin | Get to know every tile family |
| 7 | Kenali ubin yang kamu butuhkan | Recognize the tile you need |
| 8 | Lihat pola yang dikejar rakmu | See the pattern your rack is pursuing |

## Rendering and checks

| Locale | iPhone 6.9-inch | iPad 13-inch | iPhone Duo | Total |
| --- | ---: | ---: | ---: | ---: |
| es-MX | 8 | 8 | 8 | 24 |
| vi | 8 | 8 | 8 | 24 |
| id | 8 | 8 | 8 | 24 |

All 72 files are opaque RGB PNGs at the required sizes: iPhone 1320x2868, iPad
2064x2752, and Duo 1398x2034. The phone frames were rendered from the current
shared `ppo-2026-10/mahj-v2` manifest and its existing captures. Duo frames
reuse the en-US screen captures and recompose the caption with the same New
York headline style. The existing en-US iPad screenshots had no marketing
captions and used a different order, so the localized iPad frames add the same
headline style above the existing English captures, reordered to match the
eight benefits. No new captures were made.

The shared renderer's iPhone audit passed for all three locales. It reported
four thumbnail OCR misses on Vietnamese diacritics; full-resolution visual
inspection confirmed the accents and no clipped text. Contact sheets for all
device sets were checked by eye, with full-resolution spot checks. Headlines
fit within two lines, fonts render the required glyphs, app screens remain
legible, and the screen order matches the caption story. No CJK locale met the
view threshold, so the selected sets only need Latin glyph coverage.

No app code or project configuration was edited. No simulator was used. No
App Store Connect upload or submission was performed, and no RevenueCat data
or service was touched.
