# Task 03 — Mahj+ price increase (1.3) — DONE, AT DIFFERENT NUMBERS

**Status: shipped 2026-08-12, but not at the prices planned below.** Verified
against the App Store Connect API and the live US listing on 2026-08-27:

| Product | Was | Planned here | ACTUALLY SHIPPED |
|---|---|---|---|
| `com.jackwallner.mahj.monthly` | $1.99/mo | $4.99/mo | **$9.99/mo** |
| `com.jackwallner.mahj.yearly` | $9.99/yr | $19.99/yr | **$39.99/yr** |
| `com.jackwallner.mahj.lifetime` | $29.99 | $49.99 | **$89.99** |

The live prices are double this plan's targets. The `.storekit` fixture and
`docs/index.html` agree with what shipped. Nothing below has been rewritten,
it is kept as the record of what was decided on 2026-08-09; read the numbers
in it as historical, not as targets. ASC is the source of truth for price.

Section 1 below is obsolete in a better way: the hardcoded paywall fallback
strings it asks you to update were deleted outright. `PaywallPricing` now
renders a "Loading price…" placeholder when StoreKit has not answered, so
there is no second copy of a price to drift.

---

## Original plan (2026-08-09)

Raise Mahj+ prices before starting paid acquisition. Decided 2026-08-09 from
live RevenueCat + App Store Connect data (see "Why" at the bottom).

**Target prices (USA base, all other territories equalize from it):**

| Product | Current | New |
|---|---|---|
| `com.jackwallner.mahj.monthly` | $1.99/mo | **$4.99/mo** |
| `com.jackwallner.mahj.yearly` | $9.99/yr | **$19.99/yr** |
| `com.jackwallner.mahj.lifetime` | $29.99 | **$49.99** |

Keep the 1-week free trial on both subscriptions. Do not touch the trial
length, the entitlement id (`pro`), the product ids, or the free/Mahj+ content
split.

---

## Scope note: why this is not ASC-only

`PaywallPricing.price()` reads `storeProduct.localizedPriceString` live from
StoreKit via RevenueCat, and `OnboardingView` goes through the same helper, so
the app charges and displays new ASC prices without a new binary. But three
things go stale, one of which is an App Review 3.1.2 risk. All of them are in
this task.

---

## 1. App code — paywall fallback strings

`MahjTrainer/Views/PaywallView.swift:130-136`, in `PaywallPricing.price`:

```swift
case .yearly: return "\(base ?? "$9.99")/year"
case .monthly: return "\(base ?? "$1.99")/month"
case .lifetime: return base ?? "$29.99"
```

Update the three fallbacks to `$19.99`, `$4.99`, `$29.99` → `$49.99`.

These render whenever RevenueCat has not loaded (cold start, no network, RC
outage). That is exactly the surface App Review checks for 3.1.2, and a
reviewer hitting it today would see a price that does not match what Apple
charges. This is the one change that genuinely requires a build.

Do **not** restructure `PaywallPricing`. The live-price-with-fallback shape is
correct; only the literals change.

Nothing else in the app hardcodes a price — `WhatsNewSheet`, `SettingsView`,
`RoomView`, and the test target were checked and are clean.

## 2. App Store metadata — 51 locale descriptions

Every `fastlane/metadata/*/description.txt` carries the required subscription
disclosure paragraph with all three prices inline in translated prose. en-US
reads:

> Mahj+ is available by auto-renewing subscription or a one-time purchase:
> Monthly $1.99/month, Yearly $9.99/year (both include a 1-week free trial), or
> Lifetime $29.99 one-time. Payment is charged to your Apple ID account at
> confirmation of purchase. ...

The numerals are USD literals inside the translated sentence, so this is a
literal string substitution, not a re-translation. Replace across all 51 files:

- `1.99` → `4.99`
- `9.99` → `19.99`
- `29.99` → `49.99`

**Three locales use comma decimals** and need the comma forms handled too:
`fastlane/metadata/id`, `fastlane/metadata/tr`, `fastlane/metadata/vi`
(`1,99` → `4,99`, `9,99` → `19,99`, `29,99` → `49,99`). `tr` also puts the
symbol after the number (`1,99 $/ay`), so match on the numeral, not on `$1.99`.

Be careful with substitution order: replacing `9.99` before `29.99` will
corrupt `29.99` into `24.99`. Do `29.99` first, or use a single regex pass with
alternation.

Verify afterwards that no `description.txt` still contains `1.99`, `9.99`, or
`29.99` in any form, and that all 51 still contain the EULA URL, the privacy
URL, and the "24 hours" cancellation clause.

App Store descriptions can only be edited against an editable app version, so
this ships with the 1.3 submission, not separately.

## 3. Scripts — price constants and validators

- `scripts/asc-set-prices.py:21-22` — `USA_PRICES` map. Update both, and
  **extend it to cover lifetime** (see below).
- `scripts/asc-sync-mahjplus-descriptions.py:279-284` — the legal sweep asserts
  `1.99` / `9.99` / `29.99` are present in every description. Update to the new
  numerals or it will report false gaps on every future run.
- `scripts/asc-create-lifetime.py:26,103` — `PRICE = "29.99"` and the comment.
  This script *creates* the lifetime IAP and is already spent, but leave it
  consistent so it is not a trap later.
- `scripts/asc-setup-release.py:23,31` — `"price": "4.99"` and `"price":
  "29.99"` in the product scaffolding block. Update to `19.99` / `49.99`
  (note line 23 is currently `4.99`, a stale value from before the $9.99
  yearly, so do not assume it is the monthly).

### Lifetime price change is a different API call

`asc-set-prices.py` only handles auto-renewable subscriptions
(`/subscriptionPrices`). Lifetime is a non-renewing IAP and needs
`/v1/inAppPurchasePriceSchedules` with `baseTerritory: USA`, which replaces the
existing schedule. That call already exists in
`scripts/asc-create-lifetime.py:103-130` — lift step 3 into a reusable helper
(or into `asc-set-prices.py`) rather than writing it fresh.

---

## Sequencing

Order matters. Ship the build and metadata first, then flip the ASC price
schedules on release day.

1. **Fix RevenueCat's commission setting first** (dashboard, not API, so this
   is a Jack task): RC project is configured at 70% but Apple is actually
   paying 85% — the Small Business Program is active, confirmed in the raw
   sales rows ($9.99 → $8.49 proceeds). Every RC LTV and ROAS chart currently
   understates net revenue by 21%. Worth checking the rest of the fleet for the
   same misconfiguration.
2. Steps 1-3 above, in one commit. Bump `MARKETING_VERSION` to `1.3.0` and
   `CURRENT_PROJECT_VERSION` to `16` in `project.yml`.
3. Add a `WhatsNew` entry only if 1.3 ships user-visible features alongside
   this. A price change on its own is not a What's New item.
4. Run the test suite (`ContentValidityTests` must stay green) and ship to
   TestFlight via `./scripts/testflight.sh`.
5. Submit 1.3 for review.
6. **On release day**, run `asc-set-prices.py` (with lifetime support added) to
   flip the price schedules. The script now ENFORCES this rather than trusting
   the reader: `REQUIRED_LIVE_VERSION` must be READY_FOR_SALE on the store or it
   refuses and exits 1. Bump that constant alongside `USA_PRICES`. `--force`
   exists but you almost certainly do not want it.

**Note (2026-08-09):** the price change shipped folded into 1.2.0 rather than a
separate 1.3, so the gate is set to `1.2.0`.

Do not flip ASC prices before the build is live. That would leave the paywall
fallback advertising $9.99 while Apple charges $19.99, which is the wrong
direction to be wrong in.

**Existing customers are unaffected.** Apple grandfathers existing
subscriptions unless you explicitly push the increase, and the ~30 users
currently mid-trial already have a subscription record so they convert at
$9.99. The new price only touches new purchases. Do not opt existing
subscribers into the increase.

---

## Why (data behind the decision)

Pulled 2026-08-09 from RevenueCat project `proj28030dc2` and ASC daily sales
reports, covering roughly the first four weeks of availability.

| | |
|---|---|
| First-time downloads | 110 |
| Trial starts (production) | 41 → **37% of downloads** |
| Product mix | 41/41 yearly. Zero monthly, zero lifetime |
| Trials past day 8 | 10 |
| Converted to paid | 6 → **60%** |
| Already `will_not_renew` | 13 of 41 |
| Net revenue per download | **$1.89** |

37% install-to-trial is far above category norms, and 100% yearly, because the
OT710 zero-shift onboarding page is the only paywall most users see and it has
no plan comparison. Nobody is evaluating price at the trial-start step, which
is what makes a price increase low-risk there — the exposure is at the
trial-to-paid step.

At $1.89 net per download, no paid channel works: education-category CPI
benchmarks are ~$4.70 and even good exact-match Apple Search Ads land around
$2-3.50. The break-even on a price increase is forgiving: at $19.99 you can
lose **half** your trial-to-paid conversion and still be flat, while each
install becomes worth ~$2.80.

$19.99/yr also leaves Mahj Trainer the cheapest annual in the category:
I Love Mahj $60/yr, The Mahj App $29.99/yr, Eight Bam $3.99/mo or $17.99
one-time per card year, MAHJ $4.99 one-time.

Monthly has to move with yearly. At $1.99/mo against a $19.99 yearly, twelve
months of monthly is $23.88 and the annual saves only 16%, which destroys the
annual preference that is currently 100% of revenue. $4.99 restores a 67%
discount and matches Eight Bam and The Mahj App. Lifetime at $29.99 against a
$19.99 yearly is a 1.5-year payback and would cannibalize the subscription;
$49.99 keeps it a real alternative, and it is the only SKU that pays on day
one, which matters when funding ad spend.

**Caveats to carry forward:** the 60% conversion rate rests on ten resolved
trials, so the true value could plausibly be 40% or 80%. And at ~110
downloads/month a price A/B test cannot reach significance in any reasonable
window, so this is a one-way change to make and monitor, not a test. Watch
aggregate trial-start rate and trial-to-paid for three weeks post-change before
committing ad budget, and be willing to revert.

## Out of scope

- No change to trial length, product ids, entitlement id, or the free/Mahj+
  content split.
- No new SKUs.
- No paywall redesign. The OT710 zero-shift onboarding flow is working and is
  the reason trial starts are high — do not touch it.
- Ad campaign setup is a separate task.
