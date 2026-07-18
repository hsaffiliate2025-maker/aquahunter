#!/usr/bin/env python3
"""Validate AquaHunter's production data-source allowlist."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "docs" / "data-sources.json"
REQUIRED_FIELDS = {
    "id",
    "provider",
    "category",
    "datasetIds",
    "officialUrl",
    "licenseEvidence",
    "decision",
    "commercialUse",
    "derivativeUse",
    "redistribution",
    "attribution",
    "requiredDisclaimers",
    "latency",
    "productionEnabled",
    "reviewNotes",
}
DECISIONS = {"approved", "conditional", "blocked"}
NON_RELEASE_REDISTRIBUTION_VALUES = {
    "unknown",
    "dataset-specific",
    "product-and-upstream-specific",
    "contract-required",
    "service-policy-restricted",
    "prohibited",
}


def is_https(value: str) -> bool:
    return urlparse(value).scheme == "https"


def validate(release: bool) -> list[str]:
    errors: list[str] = []
    payload = json.loads(REGISTRY.read_text(encoding="utf-8"))
    sources = payload.get("sources", [])
    release_ids = payload.get("releaseSourceIds", [])
    by_id: dict[str, dict] = {}

    if payload.get("schemaVersion") != 1:
        errors.append("schemaVersion must be 1")
    if not isinstance(sources, list) or not sources:
        errors.append("sources must be a non-empty array")
        return errors
    if not isinstance(release_ids, list):
        errors.append("releaseSourceIds must be an array")
        release_ids = []

    for index, source in enumerate(sources):
        label = source.get("id", f"source[{index}]")
        missing = sorted(REQUIRED_FIELDS - source.keys())
        if missing:
            errors.append(f"{label}: missing fields: {', '.join(missing)}")
            continue
        if label in by_id:
            errors.append(f"{label}: duplicate source id")
        by_id[label] = source
        if source["decision"] not in DECISIONS:
            errors.append(f"{label}: invalid decision {source['decision']!r}")
        for field in ("officialUrl", "licenseEvidence"):
            value = source[field]
            if value and not is_https(value):
                errors.append(f"{label}: {field} must use https")
        if source["productionEnabled"]:
            if source["decision"] != "approved":
                errors.append(f"{label}: production source is not approved")
            if source["commercialUse"] is not True:
                errors.append(f"{label}: commercial use is not explicitly allowed")
            if source["derivativeUse"] is not True:
                errors.append(f"{label}: derivative use is not explicitly allowed")
            if not source["datasetIds"]:
                errors.append(f"{label}: production source has no exact dataset ID")
            if not source["officialUrl"]:
                errors.append(f"{label}: production source has no official dataset URL")
            if not source["licenseEvidence"]:
                errors.append(f"{label}: production source has no license evidence")
            if not source.get("licenseId"):
                errors.append(f"{label}: production source has no explicit license ID")
            if not source["attribution"]:
                errors.append(f"{label}: production source has no attribution")
            redistribution = source["redistribution"].strip().lower()
            if not redistribution or redistribution in NON_RELEASE_REDISTRIBUTION_VALUES:
                errors.append(
                    f"{label}: production display/redistribution permission is unresolved"
                )
            if not source["latency"]:
                errors.append(f"{label}: production source has no latency declaration")
            if not source["reviewNotes"]:
                errors.append(f"{label}: production source has no use-scope review")

    for source_id in release_ids:
        source = by_id.get(source_id)
        if source is None:
            errors.append(f"releaseSourceIds references unknown source {source_id!r}")
        elif not source["productionEnabled"]:
            errors.append(f"{source_id}: release source is not productionEnabled")

    enabled_ids = sorted(
        source["id"] for source in sources if source.get("productionEnabled")
    )
    if sorted(release_ids) != enabled_ids:
        errors.append(
            "releaseSourceIds must exactly match all productionEnabled source IDs"
        )
    if release and not release_ids:
        errors.append(
            "release blocked: no approved production data sources are enabled"
        )
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--release",
        action="store_true",
        help="require at least one approved production source",
    )
    args = parser.parse_args()
    errors = validate(release=args.release)
    if errors:
        print("Data-source validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("Data-source registry is valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
