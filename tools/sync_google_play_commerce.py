#!/usr/bin/env python3
"""Create and activate the 24 AquaHunter Google Play products.

Authentication uses Google Application Default Credentials through gcloud. No
credential, purchase token, or signing secret is read from the repository.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from decimal import Decimal
from pathlib import Path
from typing import Any, Optional


ROOT = Path(__file__).resolve().parents[1]
PACKAGE_NAME = os.environ.get(
    "GOOGLE_PLAY_PACKAGE",
    "com.hotseason.aquahunter",
)
QUOTA_PROJECT = os.environ.get(
    "GOOGLE_PLAY_QUOTA_PROJECT",
    "cashboomerang",
)
GCLOUD = os.environ.get("GCLOUD", "/opt/homebrew/bin/gcloud")
API_ROOT = (
    "https://androidpublisher.googleapis.com/androidpublisher/v3/"
    f"applications/{PACKAGE_NAME}"
)
CATALOG_PATH = ROOT / "commerce" / "product-catalog.json"
PRICING_PATH = ROOT / "commerce" / "store-pricing.json"
LOCALIZATIONS_PATH = ROOT / "store-metadata" / "iap-localizations.json"


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def money(value: str) -> dict[str, Any]:
    decimal = Decimal(value)
    units = int(decimal)
    nanos = int((decimal - units) * Decimal(1_000_000_000))
    return {
        "currencyCode": "USD",
        "units": str(units),
        "nanos": nanos,
    }


def access_token() -> str:
    result = subprocess.run(
        [GCLOUD, "auth", "application-default", "print-access-token"],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


class PlayAPI:
    def __init__(self, token: str) -> None:
        self.token = token

    def request(
        self,
        method: str,
        path: str,
        *,
        query: Optional[dict[str, str]] = None,
        body: Optional[dict[str, Any]] = None,
        allow_not_found: bool = False,
    ) -> Optional[dict[str, Any]]:
        url = f"{API_ROOT}/{path.lstrip('/')}"
        if query:
            url = f"{url}?{urllib.parse.urlencode(query)}"
        data = None
        if body is not None:
            data = json.dumps(
                body,
                ensure_ascii=False,
                separators=(",", ":"),
            ).encode("utf-8")
        request = urllib.request.Request(
            url,
            data=data,
            method=method,
            headers={
                "Authorization": f"Bearer {self.token}",
                "X-Goog-User-Project": QUOTA_PROJECT,
                "Content-Type": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=180) as response:
                payload = response.read()
                if not payload:
                    return {}
                return json.loads(payload)
        except urllib.error.HTTPError as error:
            payload = error.read().decode("utf-8", errors="replace")
            if allow_not_found and error.code == 404:
                return None
            raise RuntimeError(
                f"{method} {path} failed ({error.code}): {payload}"
            ) from error


def localized_listings(
    localized_product: dict[str, Any],
) -> list[dict[str, str]]:
    result: list[dict[str, str]] = []
    for locale in sorted(localized_product["localizations"]):
        block = localized_product["localizations"][locale]
        result.append(
            {
                "languageCode": block["googleLocale"],
                "title": block["displayName"],
                "description": block["googleDescription"],
            }
        )
    return result


def converted_configs(
    converted: dict[str, Any],
    *,
    subscription: bool,
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    regional: list[dict[str, Any]] = []
    for region_code, block in sorted(
        converted["convertedRegionPrices"].items()
    ):
        if subscription:
            regional.append(
                {
                    "regionCode": region_code,
                    "newSubscriberAvailability": True,
                    "price": block["price"],
                }
            )
        else:
            regional.append(
                {
                    "regionCode": region_code,
                    "price": block["price"],
                    "availability": "AVAILABLE",
                }
            )
    other = converted["convertedOtherRegionsPrice"]
    if subscription:
        other_config = {
            "usdPrice": other["usdPrice"],
            "eurPrice": other["eurPrice"],
            "newSubscriberAvailability": True,
        }
    else:
        other_config = {
            "usdPrice": other["usdPrice"],
            "eurPrice": other["eurPrice"],
            "availability": "AVAILABLE",
        }
    return regional, other_config


def main() -> int:
    catalog = load(CATALOG_PATH)
    pricing = load(PRICING_PATH)["products"]
    metadata = load(LOCALIZATIONS_PATH)
    localized_by_id = {
        product["productId"]: product
        for product in metadata["products"]
    }
    products = catalog["products"]

    expected_ids = {product["id"] for product in products}
    if expected_ids != set(pricing) or expected_ids != set(localized_by_id):
        raise RuntimeError(
            "Catalog, prices and localized IAP metadata do not cover the "
            "same 24 product IDs."
        )

    api = PlayAPI(access_token())
    price_cache: dict[str, dict[str, Any]] = {}

    def converted_price(usd_price: str) -> dict[str, Any]:
        if usd_price not in price_cache:
            response = api.request(
                "POST",
                "pricing:convertRegionPrices",
                body={"price": money(usd_price)},
            )
            assert response is not None
            price_cache[usd_price] = response
        return price_cache[usd_price]

    consumables = [
        product
        for product in products
        if product["storeType"] == "consumable"
    ]
    subscriptions = [
        product
        for product in products
        if product["storeType"] == "autoRenewableSubscription"
    ]

    for product in consumables:
        product_id = product["id"]
        current = api.request(
            "GET",
            f"oneTimeProducts/{urllib.parse.quote(product_id)}",
            allow_not_found=True,
        )
        if current is None:
            converted = converted_price(pricing[product_id]["usdPrice"])
            regional, other = converted_configs(
                converted,
                subscription=False,
            )
            payload = {
                "packageName": PACKAGE_NAME,
                "productId": product_id,
                "listings": localized_listings(
                    localized_by_id[product_id]
                ),
                "taxAndComplianceSettings": {
                    "isTokenizedDigitalAsset": False,
                },
                "purchaseOptions": [
                    {
                        "purchaseOptionId": "buy",
                        "regionalPricingAndAvailabilityConfigs": regional,
                        "newRegionsConfig": other,
                        "buyOption": {
                            "legacyCompatible": True,
                            "multiQuantityEnabled": False,
                        },
                    }
                ],
            }
            region_version = converted["regionVersion"]["version"]
            api.request(
                "PATCH",
                f"onetimeproducts/{urllib.parse.quote(product_id)}",
                query={
                    "updateMask": "listings,purchaseOptions,"
                    "taxAndComplianceSettings",
                    "regionsVersion.version": region_version,
                    "allowMissing": "true",
                },
                body=payload,
            )
            print(f"Created {product_id}", flush=True)
        else:
            print(f"Exists {product_id}", flush=True)

        api.request(
            "POST",
            f"oneTimeProducts/{urllib.parse.quote(product_id)}/"
            "purchaseOptions:batchUpdateStates",
            body={
                "requests": [
                    {
                        "activatePurchaseOptionRequest": {
                            "packageName": PACKAGE_NAME,
                            "productId": product_id,
                            "purchaseOptionId": "buy",
                        }
                    }
                ]
            },
        )
        print(f"Active {product_id}", flush=True)

    for product in subscriptions:
        product_id = product["id"]
        current = api.request(
            "GET",
            f"subscriptions/{urllib.parse.quote(product_id)}",
            allow_not_found=True,
        )
        if current is None:
            converted = converted_price(pricing[product_id]["usdPrice"])
            regional, other = converted_configs(
                converted,
                subscription=True,
            )
            billing_period = (
                "P1M"
                if product["billingPeriod"] == "monthly"
                else "P1Y"
            )
            payload = {
                "packageName": PACKAGE_NAME,
                "productId": product_id,
                "basePlans": [
                    {
                        "basePlanId": "standard",
                        "regionalConfigs": regional,
                        "otherRegionsConfig": other,
                        "autoRenewingBasePlanType": {
                            "billingPeriodDuration": billing_period,
                            "resubscribeState": "RESUBSCRIBE_STATE_ACTIVE",
                        },
                    }
                ],
                "listings": localized_listings(
                    localized_by_id[product_id]
                ),
            }
            region_version = converted["regionVersion"]["version"]
            api.request(
                "POST",
                "subscriptions",
                query={
                    "productId": product_id,
                    "regionsVersion.version": region_version,
                },
                body=payload,
            )
            print(f"Created {product_id}", flush=True)
        else:
            print(f"Exists {product_id}", flush=True)

        api.request(
            "POST",
            f"subscriptions/{urllib.parse.quote(product_id)}/"
            "basePlans/standard:activate",
            body={},
        )
        print(f"Active {product_id}", flush=True)

    print(
        f"Google Play commerce synced: {len(consumables)} one-time products "
        f"and {len(subscriptions)} subscriptions, each with 12 locales.",
        flush=True,
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"Google Play commerce sync failed: {error}", file=sys.stderr)
        raise
