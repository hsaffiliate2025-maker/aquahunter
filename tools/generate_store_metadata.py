#!/usr/bin/env python3
"""Generate and validate Apple, Google and 24-product localized metadata."""

from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
APP_SOURCE = ROOT / "store-metadata" / "app-localizations.json"
CATALOG_PATH = ROOT / "commerce" / "product-catalog.json"
COMMERCE_LOCALIZATIONS_PATH = ROOT / "commerce" / "localizations.json"
APPLE_METADATA = ROOT / "metadata"
GOOGLE_METADATA = ROOT / "store-metadata" / "google"
IAP_OUTPUT = ROOT / "store-metadata" / "iap-localizations.json"

PRIVACY_URL = "https://hotseason.app/en/policy#aquahunter"
MARKETING_URL = "https://hotseason.app/en/aquahunter"
SUPPORT_URL = "https://hotseason.app/en/contact"
STANDARD_EULA_URL = (
    "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
)
TERMS_LABELS = {
    "en": "Terms of Use",
    "zh-Hans": "使用条款",
    "zh-Hant": "使用條款",
    "es": "Términos de uso",
    "fr": "Conditions d’utilisation",
    "de": "Nutzungsbedingungen",
    "ja": "利用規約",
    "ko": "이용 약관",
    "pt-BR": "Termos de Uso",
    "id": "Ketentuan Penggunaan",
    "hi": "उपयोग की शर्तें",
    "ar": "شروط الاستخدام",
}
EXPECTED_LOCALES = {
    "en",
    "zh-Hans",
    "zh-Hant",
    "es",
    "fr",
    "de",
    "ja",
    "ko",
    "pt-BR",
    "id",
    "hi",
    "ar",
}
BANNED_UNDELIVERED_STORE_CLAIMS = {
    "aqua ai",
    "fish probability",
    "buyer database",
    "supplier database",
    "vessel tracking",
    "ais tracking",
    "live city price",
    "real-time price",
}
GOOGLE_RELEASE_NOTES_MAXIMUM = 500


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def write_text(path: Path, value: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value.rstrip() + "\n", encoding="utf-8")


def google_release_notes(value: str) -> str:
    """Keep complete localized bullet lines within Google Play's 500-char limit."""
    selected: list[str] = []
    for line in (item.strip() for item in value.splitlines()):
        if not line:
            continue
        candidate = "\n".join([*selected, line])
        if len(candidate) > GOOGLE_RELEASE_NOTES_MAXIMUM:
            break
        selected.append(line)
    return "\n".join(selected)


def replace_tokens(template: str, **values: object) -> str:
    result = template
    for key, value in values.items():
        result = result.replace(f"{{{key}}}", str(value))
    return result


def product_text(
    product: dict[str, Any],
    localization: dict[str, Any],
) -> tuple[str, str]:
    if product["storeType"] == "autoRenewableSubscription":
        block = localization["subscriptions"][product["tier"]]
        period = localization["periods"][product["billingPeriod"]]
        return f"{block['name']} — {period}", block["description"]
    block = localization["families"][product["family"]]
    quantity = product["quantity"]
    return (
        replace_tokens(block["name"], quantity=quantity),
        replace_tokens(block["description"], quantity=quantity),
    )


def iap_store_text(
    product: dict[str, Any],
    localization: dict[str, Any],
) -> tuple[str, str]:
    full_name, full_description = product_text(product, localization)
    destination = localization["destinations"][product["destination"]]
    candidates = [full_name]
    if product.get("quantity"):
        candidates.append(f"{product['quantity']} × {destination}")
    candidates.append(destination)
    display_name = next(
        (candidate for candidate in candidates if len(candidate) <= 30),
        candidates[-1][:30],
    )
    description_candidates = [
        full_description,
        f"{destination} · AquaHunter",
        destination,
        display_name,
    ]
    description = next(
        (
            candidate
            for candidate in description_candidates
            if 1 <= len(candidate) <= 45
        ),
        display_name,
    )
    return display_name, description


def validate_field(
    errors: list[str],
    locale: str,
    field: str,
    value: object,
    maximum: int,
) -> None:
    if not isinstance(value, str) or not value.strip():
        errors.append(f"{locale}.{field}: empty")
    elif len(value) > maximum:
        errors.append(
            f"{locale}.{field}: {len(value)} characters exceeds {maximum}"
        )


def main() -> int:
    errors: list[str] = []
    app_payload = load(APP_SOURCE)
    catalog = load(CATALOG_PATH)
    commerce_payload = load(COMMERCE_LOCALIZATIONS_PATH)
    app_locales = app_payload.get("locales", {})
    commerce_locales = commerce_payload.get("locales", {})
    locale_map = catalog.get("storeLocaleMap", {})
    products = catalog.get("products", [])
    release_version = app_payload.get("releaseVersion")

    if set(app_locales) != EXPECTED_LOCALES:
        errors.append("app metadata must contain exactly the 12 launch locales")
    if set(commerce_locales) != EXPECTED_LOCALES:
        errors.append("commerce metadata must contain exactly the 12 launch locales")
    if set(locale_map) != EXPECTED_LOCALES:
        errors.append("storeLocaleMap must contain exactly the 12 launch locales")
    if len(products) != 24:
        errors.append(f"expected 24 products, found {len(products)}")

    for locale, block in app_locales.items():
        for field, maximum in {
            "name": 30,
            "subtitle": 30,
            "description": 4_000,
            "keywords": 100,
            "promotionalText": 170,
            "whatsNew": 4_000,
            "googleShort": 80,
        }.items():
            validate_field(errors, locale, field, block.get(field), maximum)
        validate_field(
            errors,
            locale,
            "googleReleaseNotes",
            google_release_notes(str(block.get("whatsNew", ""))),
            GOOGLE_RELEASE_NOTES_MAXIMUM,
        )
        description = str(block.get("description", "")).lower()
        for term in BANNED_UNDELIVERED_STORE_CLAIMS:
            if term in description:
                errors.append(
                    f"{locale}.description: undeveloped claim appears: {term}"
                )
        description_with_terms = (
            f"{block.get('description', '')}\n\n"
            f"{TERMS_LABELS.get(locale, 'Terms of Use')}: {STANDARD_EULA_URL}"
        )
        if len(description_with_terms) > 4_000:
            errors.append(
                f"{locale}.description with EULA exceeds 4000 characters"
            )

    iap_products: list[dict[str, Any]] = []
    for product in products:
        localized_product: dict[str, Any] = {}
        for locale in sorted(EXPECTED_LOCALES):
            _, full_description = product_text(
                product,
                commerce_locales[locale],
            )
            display_name, description = iap_store_text(
                product,
                commerce_locales[locale],
            )
            if len(display_name) > 30:
                errors.append(
                    f"{product['id']}/{locale}: IAP name exceeds 30"
                )
            if len(description) > 45:
                errors.append(
                    f"{product['id']}/{locale}: IAP description exceeds 45"
                )
            if len(full_description) > 200:
                errors.append(
                    f"{product['id']}/{locale}: Google description exceeds 200"
                )
            localized_product[locale] = {
                "appleLocale": locale_map[locale]["apple"],
                "googleLocale": locale_map[locale]["google"],
                "displayName": display_name,
                "description": description,
                "googleDescription": full_description,
            }
        iap_products.append(
            {
                "productId": product["id"],
                "storeType": product["storeType"],
                "destination": product["destination"],
                "localizations": localized_product,
            }
        )

    if errors:
        print("Store metadata validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    version_dir = APPLE_METADATA / "version" / release_version
    if version_dir.exists():
        shutil.rmtree(version_dir)
    if GOOGLE_METADATA.exists():
        shutil.rmtree(GOOGLE_METADATA)

    for locale, block in app_locales.items():
        apple_locale = locale_map[locale]["apple"]
        google_locale = locale_map[locale]["google"]
        description_with_terms = (
            f"{block['description']}\n\n"
            f"{TERMS_LABELS[locale]}: {STANDARD_EULA_URL}"
        )
        write_json(
            APPLE_METADATA / "app-info" / f"{apple_locale}.json",
            {
                "name": block["name"],
                "subtitle": block["subtitle"],
                "privacyPolicyUrl": PRIVACY_URL,
            },
        )
        write_json(
            version_dir / f"{apple_locale}.json",
            {
                "description": description_with_terms,
                "keywords": block["keywords"],
                "marketingUrl": MARKETING_URL,
                "promotionalText": block["promotionalText"],
                "supportUrl": SUPPORT_URL,
                "whatsNew": block["whatsNew"],
            },
        )
        google_dir = GOOGLE_METADATA / google_locale
        write_text(google_dir / "title.txt", block["name"])
        write_text(
            google_dir / "short-description.txt",
            block["googleShort"],
        )
        write_text(
            google_dir / "full-description.txt",
            block["description"],
        )
        write_text(
            google_dir / "release-notes.txt",
            google_release_notes(block["whatsNew"]),
        )

    write_json(
        IAP_OUTPUT,
        {
            "schemaVersion": 1,
            "catalogVersion": catalog["catalogVersion"],
            "releaseVersion": release_version,
            "products": iap_products,
        },
    )
    print(
        "Store metadata generated: "
        f"12 app locales, {len(products)} products × 12 IAP locales."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
