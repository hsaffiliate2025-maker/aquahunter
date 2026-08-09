#!/usr/bin/env python3
"""Validate AquaHunter's 24-SKU commerce contract and 12-language catalog."""

from __future__ import annotations

import json
import re
import sys
from datetime import date, datetime
from pathlib import Path
from typing import Any
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = ROOT / "commerce" / "product-catalog.json"
LOCALIZATIONS_PATH = ROOT / "commerce" / "localizations.json"
PRICING_PATH = ROOT / "commerce" / "store-pricing.json"
DATA_SOURCE_REGISTRY_PATH = ROOT / "docs" / "data-sources.json"

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
EXPECTED_FAMILY_COUNTS = {
    "markets": 6,
    "export": 3,
    "compare": 3,
    "snapshot": 3,
    "seasonality": 3,
    "landedCost": 3,
    "alerts": 3,
}
EXPECTED_DESTINATIONS = {
    "history",
    "export",
    "compare",
    "snapshot",
    "seasonality",
    "landedCost",
    "alerts",
}
EXPECTED_TOOLKIT_KEYS = {
    "title",
    "eyebrow",
    "subtitle",
    "loading",
    "noData",
    "noResult",
    "noCredit",
    "creditPrompt",
    "viewPlans",
    "viewSubscriptions",
    "addCredits",
    "back",
    "historyLockedTitle",
    "historyLockedBody",
    "observationSummary",
    "exchangeRate",
    "freight",
    "tariff",
    "loss",
    "direction",
    "above",
    "below",
    "threshold",
    "assumptionNotice",
    "alertNotice",
    "reuseTitle",
    "reuseBody",
    "benchmarkLimit",
    "unavailable",
    "commodity.01",
    "commodity.02",
    "action.history",
    "action.export",
    "action.compare",
    "action.snapshot",
    "action.seasonality",
    "action.landedCost",
    "action.alerts",
    "result.exportDelivered",
    "result.exportFailed",
    "result.compare",
    "result.snapshot",
    "result.seasonality",
    "result.landedCost",
    "result.alertNoMatch",
    "result.alertDelivered",
    "body.export",
    "body.compare",
    "body.snapshot",
    "body.seasonality",
    "body.landedCost",
    "body.alert",
}
PRODUCT_ID = re.compile(r"^aquahunter\.[a-z0-9.]+$")
PLACEHOLDER = re.compile(r"\{[a-zA-Z][a-zA-Z0-9]*\}")
BANNED_PAID_TERMS = (
    "cloud storage",
    "theme",
    "wallpaper",
    "tip jar",
    "donation",
    "云存储",
    "主题颜色",
    "壁纸",
    "打赏",
)
NON_COMMERCIAL_REDISTRIBUTION_VALUES = {
    "",
    "unknown",
    "dataset-specific",
    "product-and-upstream-specific",
    "contract-required",
    "service-policy-restricted",
    "prohibited",
}
MAX_LICENSE_REVIEW_AGE_DAYS = 180


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def leaf_paths(value: Any, prefix: str = "") -> dict[str, str]:
    result: dict[str, str] = {}
    if isinstance(value, dict):
        for key, child in value.items():
            child_prefix = f"{prefix}.{key}" if prefix else key
            result.update(leaf_paths(child, child_prefix))
    elif isinstance(value, str):
        result[prefix] = value
    return result


def replace_tokens(template: str, **values: object) -> str:
    output = template
    for key, value in values.items():
        output = output.replace(f"{{{key}}}", str(value))
    return output


def is_https(value: object) -> bool:
    return isinstance(value, str) and urlparse(value).scheme == "https"


def validate_paid_data_sources(
    catalog: dict[str, Any],
    registry: dict[str, Any],
) -> list[str]:
    """Require every paid feature source to be release-approved for commerce."""

    errors: list[str] = []
    sources = registry.get("sources", [])
    by_id = {
        source.get("id"): source
        for source in sources
        if isinstance(source, dict) and isinstance(source.get("id"), str)
    }
    release_ids = set(registry.get("releaseSourceIds", []))
    paid_source_ids: set[str] = set()

    try:
        reviewed_at = datetime.strptime(
            registry.get("lastReviewed", ""),
            "%Y-%m-%d",
        ).date()
    except (TypeError, ValueError):
        errors.append("data-source registry lastReviewed must be YYYY-MM-DD")
    else:
        age = (date.today() - reviewed_at).days
        if age < 0:
            errors.append("data-source registry lastReviewed cannot be in the future")
        elif age > MAX_LICENSE_REVIEW_AGE_DAYS:
            errors.append(
                "data-source registry legal review is stale "
                f"({age} days; maximum {MAX_LICENSE_REVIEW_AGE_DAYS})"
            )

    requirements = catalog.get("dataRequirements", {})
    if not isinstance(requirements, dict):
        return errors + ["dataRequirements must be an object"]

    for destination, source_ids in requirements.items():
        if destination not in EXPECTED_DESTINATIONS:
            errors.append(f"unknown paid data requirement destination: {destination!r}")
        if not isinstance(source_ids, list) or not source_ids:
            errors.append(f"{destination}: paid feature must declare at least one source")
            continue
        for source_id in source_ids:
            if not isinstance(source_id, str) or not source_id:
                errors.append(f"{destination}: invalid source ID {source_id!r}")
                continue
            paid_source_ids.add(source_id)
            source = by_id.get(source_id)
            if source is None:
                errors.append(f"{destination}: unknown paid source {source_id!r}")
                continue
            prefix = f"{destination}/{source_id}"
            if source_id not in release_ids:
                errors.append(f"{prefix}: source is absent from releaseSourceIds")
            if source.get("decision") != "approved":
                errors.append(f"{prefix}: source decision is not approved")
            if source.get("productionEnabled") is not True:
                errors.append(f"{prefix}: source is not productionEnabled")
            if source.get("commercialUse") is not True:
                errors.append(f"{prefix}: commercial use is not explicitly allowed")
            if source.get("derivativeUse") is not True:
                errors.append(f"{prefix}: derivative use is not explicitly allowed")
            redistribution = str(source.get("redistribution", "")).strip().lower()
            if redistribution in NON_COMMERCIAL_REDISTRIBUTION_VALUES:
                errors.append(f"{prefix}: display/redistribution rights are unresolved")
            if not source.get("licenseId"):
                errors.append(f"{prefix}: explicit license ID is missing")
            if not is_https(source.get("licenseEvidence")):
                errors.append(f"{prefix}: HTTPS license evidence is missing")
            if not is_https(source.get("officialUrl")):
                errors.append(f"{prefix}: HTTPS official dataset URL is missing")
            if not source.get("datasetIds"):
                errors.append(f"{prefix}: exact dataset ID/version is missing")
            if not str(source.get("attribution", "")).strip():
                errors.append(f"{prefix}: required attribution is missing")
            if not source.get("requiredDisclaimers"):
                errors.append(f"{prefix}: source-specific disclaimer is missing")
            if not str(source.get("reviewNotes", "")).strip():
                errors.append(f"{prefix}: legal use-scope review is missing")

    declared_sources = set(catalog.get("paidSourceIds", []))
    if declared_sources and declared_sources != paid_source_ids:
        errors.append(
            "paidSourceIds must exactly match sources used by paid dataRequirements"
        )

    return errors


def resolve_product(
    product: dict[str, Any],
    localization: dict[str, Any],
) -> tuple[str, str]:
    if product["storeType"] == "autoRenewableSubscription":
        tier = product["tier"]
        period = product["billingPeriod"]
        block = localization["subscriptions"][tier]
        return (
            f"{block['name']} — {localization['periods'][period]}",
            block["description"],
        )

    quantity = product["quantity"]
    block = localization["families"][product["family"]]
    return (
        replace_tokens(block["name"], quantity=quantity),
        replace_tokens(block["description"], quantity=quantity),
    )


def validate() -> list[str]:
    errors: list[str] = []
    catalog = load_json(CATALOG_PATH)
    localization_payload = load_json(LOCALIZATIONS_PATH)
    pricing = load_json(PRICING_PATH)
    data_source_registry = load_json(DATA_SOURCE_REGISTRY_PATH)
    products = catalog.get("products", [])
    localizations = localization_payload.get("locales", {})

    if catalog.get("schemaVersion") != 1:
        errors.append("product catalog schemaVersion must be 1")
    if localization_payload.get("schemaVersion") != 1:
        errors.append("localizations schemaVersion must be 1")
    if catalog.get("catalogVersion") != localization_payload.get("catalogVersion"):
        errors.append("catalog and localization versions differ")
    if len(products) != 24:
        errors.append(f"expected exactly 24 products, found {len(products)}")

    ids = [product.get("id") for product in products]
    if len(set(ids)) != len(ids):
        errors.append("product IDs must be unique")
    for product_id in ids:
        if not isinstance(product_id, str) or not PRODUCT_ID.fullmatch(product_id):
            errors.append(f"invalid product ID: {product_id!r}")

    pricing_products = pricing.get("products", {})
    if set(pricing_products) != set(ids):
        errors.append(
            "store-pricing.json must define exactly one price for every catalog product"
        )
    if (
        pricing.get("schemaVersion") != 1
        or pricing.get("catalogVersion") != catalog.get("catalogVersion")
        or pricing.get("baseCurrency") != "USD"
        or pricing.get("baseTerritory") != "USA"
    ):
        errors.append("store-pricing.json header does not match the reviewed catalog")
    for product_id, price_entry in pricing_products.items():
        raw_price = price_entry.get("usdPrice") if isinstance(price_entry, dict) else None
        if (
            not isinstance(raw_price, str)
            or re.fullmatch(r"(?:0|[1-9]\d*)\.\d{2}", raw_price) is None
            or float(raw_price) <= 0
        ):
            errors.append(f"{product_id}: usdPrice must be a positive decimal string")

    store_types = [product.get("storeType") for product in products]
    if store_types.count("autoRenewableSubscription") != 6:
        errors.append("catalog must contain exactly 6 subscription products")
    if store_types.count("consumable") != 18:
        errors.append("catalog must contain exactly 18 consumable products")
    unknown_types = sorted(set(store_types) - {"autoRenewableSubscription", "consumable"})
    if unknown_types:
        errors.append(f"unknown store types: {unknown_types}")

    family_counts: dict[str, int] = {}
    for product in products:
        family = product.get("family")
        family_counts[family] = family_counts.get(family, 0) + 1
        destination = product.get("destination")
        if destination not in EXPECTED_DESTINATIONS:
            errors.append(f"{product.get('id')}: invalid destination {destination!r}")
        if destination not in catalog.get("featureContracts", {}):
            errors.append(f"{product.get('id')}: destination has no feature contract")
        if destination not in catalog.get("dataRequirements", {}):
            errors.append(f"{product.get('id')}: destination has no data requirement")

        if product.get("storeType") == "consumable":
            quantity = product.get("quantity")
            if not isinstance(quantity, int) or quantity <= 0:
                errors.append(f"{product.get('id')}: consumable quantity must be positive")
        else:
            grant = product.get("grant")
            if not isinstance(grant, dict):
                errors.append(f"{product.get('id')}: subscription grant is missing")
            else:
                for field in ("historyWeeks", "watchlistSlots"):
                    value = grant.get(field)
                    if not isinstance(value, int) or value < 0:
                        errors.append(
                            f"{product.get('id')}: {field} must be a nonnegative integer"
                        )
                allowances = grant.get("monthlyAllowances")
                expected_allowances = EXPECTED_DESTINATIONS - {"history"}
                if not isinstance(allowances, dict):
                    errors.append(
                        f"{product.get('id')}: monthlyAllowances must be an object"
                    )
                elif set(allowances) != expected_allowances:
                    errors.append(
                        f"{product.get('id')}: monthlyAllowances must cover "
                        f"{sorted(expected_allowances)}"
                    )
                elif any(
                    not isinstance(value, int) or value < 0
                    for value in allowances.values()
                ):
                    errors.append(
                        f"{product.get('id')}: monthly allowances must be "
                        "nonnegative integers"
                    )
            if product.get("billingPeriod") not in {"P1M", "P1Y"}:
                errors.append(f"{product.get('id')}: invalid billing period")

    if family_counts != EXPECTED_FAMILY_COUNTS:
        errors.append(
            f"family counts differ: expected {EXPECTED_FAMILY_COUNTS}, found {family_counts}"
        )

    catalog_locales = set(catalog.get("supportedLocales", []))
    localization_locales = set(localizations)
    if catalog_locales != EXPECTED_LOCALES:
        errors.append(f"catalog locales differ: {sorted(catalog_locales)}")
    if localization_locales != EXPECTED_LOCALES:
        errors.append(f"localization locales differ: {sorted(localization_locales)}")

    english = localizations.get("en")
    if not isinstance(english, dict):
        errors.append("English localization is missing")
        return errors
    english_leaves = leaf_paths(english)
    english_toolkit = english.get("toolkit")
    if not isinstance(english_toolkit, dict):
        errors.append("English paid-tool localization block is missing")
    elif set(english_toolkit) != EXPECTED_TOOLKIT_KEYS:
        errors.append(
            "English paid-tool localization keys differ: "
            f"missing={sorted(EXPECTED_TOOLKIT_KEYS - set(english_toolkit))}, "
            f"extra={sorted(set(english_toolkit) - EXPECTED_TOOLKIT_KEYS)}"
        )

    for locale in sorted(EXPECTED_LOCALES):
        localization = localizations.get(locale)
        if not isinstance(localization, dict):
            errors.append(f"{locale}: localization block is missing")
            continue
        leaves = leaf_paths(localization)
        if set(leaves) != set(english_leaves):
            missing = sorted(set(english_leaves) - set(leaves))
            extra = sorted(set(leaves) - set(english_leaves))
            errors.append(f"{locale}: key mismatch; missing={missing}, extra={extra}")
        for key, english_value in english_leaves.items():
            value = leaves.get(key)
            if not value or not value.strip():
                errors.append(f"{locale}.{key}: empty localization")
                continue
            if set(PLACEHOLDER.findall(value)) != set(PLACEHOLDER.findall(english_value)):
                errors.append(f"{locale}.{key}: placeholder mismatch")

        for product in products:
            try:
                name, description = resolve_product(product, localization)
            except (KeyError, TypeError) as error:
                errors.append(f"{locale}/{product.get('id')}: cannot resolve: {error}")
                continue
            if PLACEHOLDER.search(name) or PLACEHOLDER.search(description):
                errors.append(f"{locale}/{product.get('id')}: unresolved placeholder")
            if not name.strip() or not description.strip():
                errors.append(f"{locale}/{product.get('id')}: empty display text")

    searchable = json.dumps(
        {"products": products, "featureContracts": catalog.get("featureContracts", {})},
        ensure_ascii=False,
    ).lower()
    for term in BANNED_PAID_TERMS:
        if term.lower() in searchable:
            errors.append(f"banned paid product term appears in catalog: {term}")

    errors.extend(validate_paid_data_sources(catalog, data_source_registry))

    return errors


def main() -> int:
    errors = validate()
    if errors:
        print("Commerce catalog validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(
        "Commerce catalog is valid: 24 products, 7 delivered features, "
        "12 locales, and all paid data sources are commercially reusable."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
