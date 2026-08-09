#!/usr/bin/env python3
"""Set Mahj Trainer subscription prices in every territory from the USA base.

Adapted from Queasy's asc-equalize-sub-prices.py. Takes the target USA price
point per subscription, fetches Apple's equalizations, and posts a
subscriptionPrice for every territory (price change, REPLACE_EXISTING
semantics). Also replaces the lifetime IAP's price schedule, which is a
different API and cannot ride along with the subscriptions.

Run this only AFTER the build carrying the matching paywall fallback prices is
live, or the app advertises the old price while Apple charges the new one.

Usage: source ~/.baseball_credentials && python3 scripts/asc-set-prices.py
"""

import json
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import asc_lib

BUNDLE = "com.jackwallner.mahj"
USA_PRICES = {
    "com.jackwallner.mahj.monthly": "4.99",
    "com.jackwallner.mahj.yearly": "19.99",
}

# Lifetime is a non-renewing IAP, so it does NOT live on /subscriptionPrices
# like the two subscriptions above. It needs an inAppPurchasePriceSchedules
# replacement instead; see set_lifetime_price.
LIFETIME_ID = "com.jackwallner.mahj.lifetime"
LIFETIME_PRICE = "49.99"


def _get_v2(token: str, path: str) -> dict:
    """ASCClient is pinned to /v1, but IAP price points are only on /v2."""
    req = urllib.request.Request(
        "https://api.appstoreconnect.apple.com" + path,
        method="GET",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            raw = resp.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"GET {path} -> {e.code}: {e.read().decode()[:500]}")


def set_lifetime_price(c: "asc_lib.ASCClient", app_id: str) -> None:
    """Replace the lifetime price schedule, based on USA so other territories
    equalize. Lifted from asc-create-lifetime.py step 3 so the price change
    lives in one place rather than in the already-spent creation script."""
    existing = c.get(f"/apps/{app_id}/inAppPurchasesV2?filter[productId]={LIFETIME_ID}")["data"]
    if not existing:
        print(f"{LIFETIME_ID}: IAP not found, skipping", file=sys.stderr)
        return
    iap_id = existing[0]["id"]

    points: list[dict] = []
    path = f"/v2/inAppPurchases/{iap_id}/pricePoints?filter[territory]=USA&limit=200"
    while path:
        d = _get_v2(c.token, path)
        points += d.get("data", [])
        nxt = d.get("links", {}).get("next")
        path = nxt.replace("https://api.appstoreconnect.apple.com", "") if nxt else None

    point = next(
        (p for p in points if p["attributes"]["customerPrice"] == LIFETIME_PRICE), None
    )
    if point is None:
        print(f"{LIFETIME_ID}: no USA price point at {LIFETIME_PRICE}", file=sys.stderr)
        return

    c.post(
        "/inAppPurchasePriceSchedules",
        {
            "data": {
                "type": "inAppPurchasePriceSchedules",
                "relationships": {
                    "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
                    "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                    "manualPrices": {"data": [{"type": "inAppPurchasePrices", "id": "${price1}"}]},
                },
            },
            "included": [
                {
                    "id": "${price1}",
                    "type": "inAppPurchasePrices",
                    "attributes": {"startDate": None, "endDate": None},
                    "relationships": {
                        "inAppPurchasePricePoint": {
                            "data": {"type": "inAppPurchasePricePoints", "id": point["id"]}
                        },
                    },
                }
            ],
        },
    )
    print(f"{LIFETIME_ID}: price schedule set to USA {LIFETIME_PRICE}")


def main() -> None:
    c = asc_lib.ASCClient(asc_lib.bearer_token(*asc_lib.load_credentials()))
    app = asc_lib.find_app(c, BUNDLE)
    group = c.get(f"/apps/{app['id']}/subscriptionGroups")["data"][0]

    for sub in c.get(f"/subscriptionGroups/{group['id']}/subscriptions")["data"]:
        pid = sub["attributes"]["productId"]
        if pid not in USA_PRICES:
            continue
        sub_id = sub["id"]

        points = asc_lib.list_all(
            c, f"/subscriptions/{sub_id}/pricePoints?filter[territory]=USA&limit=200"
        )
        usa_point = next(
            p for p in points if p["attributes"]["customerPrice"] == USA_PRICES[pid]
        )

        eq = asc_lib.list_all(
            c,
            f"/subscriptionPricePoints/{urllib.parse.quote(usa_point['id'], safe='')}"
            "/equalizations?include=territory&limit=200",
        )
        created = 0
        failed = 0
        for point in eq + [usa_point]:
            terr = (point.get("relationships", {}).get("territory", {}).get("data") or {}).get("id")
            if point is usa_point:
                terr = "USA"
            if not terr:
                continue
            try:
                c.post(
                    "/subscriptionPrices",
                    {
                        "data": {
                            "type": "subscriptionPrices",
                            "relationships": {
                                "subscription": {"data": {"type": "subscriptions", "id": sub_id}},
                                "subscriptionPricePoint": {
                                    "data": {"type": "subscriptionPricePoints", "id": point["id"]}
                                },
                            },
                        }
                    },
                )
                created += 1
            except RuntimeError as e:
                failed += 1
                print(f"  {terr}: {e}", file=sys.stderr)
        print(f"{pid}: posted {created} territory prices ({failed} failed)")

    set_lifetime_price(c, app["id"])

    print("done")


if __name__ == "__main__":
    main()
