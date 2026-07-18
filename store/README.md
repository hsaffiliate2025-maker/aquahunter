# AquaHunter Store Assets

This directory contains version-controlled store assets for the first internal
release. Screenshots were captured from the signed release code path after the
production Statistics Norway source returned successfully. No screenshot in
this directory contains demo records, synthetic prices, synthetic fish
probability, fabricated buyers, vessels, ports or trade lanes.

## App Store

| Platform slot | Directory | Dimensions | Sequence |
| --- | --- | --- | --- |
| iPhone 6.5-inch | `app-store/iphone-65/` | 1284×2778 | Pulse, Markets, 30-week history |
| iPad Pro 12.9-inch | `app-store/ipad-pro-129/` | 2048×2732 | Pulse, Markets, 30-week history |
| macOS | `app-store/macos/` | 2560×1600 | Pulse, Markets, 30-week history |

The iPhone and iPad directories pass `asc screenshots validate` for
`IPHONE_65` and `IPAD_PRO_3GEN_129`. The macOS images use an accepted
2560×1600 Mac App Store size.

Canonical English App Store metadata lives under `../metadata/`.

## Google Play

| Asset | Path | Dimensions |
| --- | --- | --- |
| Phone screenshots | `google-play/en-US/phone-screenshots/` | 1080×2400 |
| High-resolution icon | `google-play/graphics/app-icon-512.png` | 512×512 |
| Feature graphic | `google-play/graphics/feature-graphic-1024x500.png` | 1024×500 |
| Editable feature graphic source | `google-play/graphics/feature-graphic.svg` | 1024×500 |

The Google Play listing copy remains canonical in
`../android/docs/google-play/STORE_LISTING.md`.

## Release rules

- Do not upload the ignored files under `artifacts/screenshots/`; they include
  historical development captures and may contain obsolete demo UI.
- Upload only the curated files in this directory.
- Keep the source name, unit, period and license visible in market screenshots.
- Do not market Radar or Network as active live-data features until their exact
  production datasets pass the commercial-use allowlist and freshness gates.
- The first store locale is English (United States). The product keeps the
  twelve-language launch set in its development plan, but additional store
  locales must not be published until the corresponding interface copy is fully
  localized and reviewed.
