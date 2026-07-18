#!/usr/bin/env python3
"""Block AquaHunter releases that still contain fixtures or unapproved map code."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCANNED_FILES = [
    *sorted((ROOT / "apple" / "Shared").glob("*.swift")),
    *sorted((ROOT / "android" / "app" / "src" / "main").rglob("*.kt")),
    ROOT / "android" / "app" / "build.gradle.kts",
    ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml",
    ROOT / "android" / "docs" / "google-play" / "STORE_LISTING.md",
]
FORBIDDEN = {
    r"\bDemoData\b": "Apple production code references DemoData",
    r"\bDemoRepository\b": "Android production code references DemoRepository",
    r"\bDemoBadge\b": "production UI contains a Demo badge",
    r"DEMO DATA|DEMO OHLC|DEMO MODEL|OFFLINE DEMO|Grounded demo":
        "production-facing Demo text remains",
    r"deterministic offline demonstration candles|deterministic offline demo OHLC":
        "synthetic price history remains",
    r"maps-compose|com\.google\.android\.geo\.API_KEY":
        "Google Maps remains in the selected free/open map architecture",
}
INTERNAL_FIXTURE_BLOCK = re.compile(
    r"#if\s+AQUAHUNTER_INTERNAL_FIXTURES\b.*?#endif",
    flags=re.DOTALL,
)


def main() -> int:
    findings: list[str] = []
    for path in SCANNED_FILES:
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        if path.suffix == ".swift":
            text = INTERNAL_FIXTURE_BLOCK.sub("", text)
        for pattern, reason in FORBIDDEN.items():
            for match in re.finditer(pattern, text, flags=re.IGNORECASE):
                line = text.count("\n", 0, match.start()) + 1
                findings.append(
                    f"{path.relative_to(ROOT)}:{line}: {reason} ({match.group(0)!r})"
                )

    if findings:
        print("Release-content validation failed:", file=sys.stderr)
        for finding in findings:
            print(f"- {finding}", file=sys.stderr)
        return 1

    print("Release content contains no known fixture or blocked-map markers.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
