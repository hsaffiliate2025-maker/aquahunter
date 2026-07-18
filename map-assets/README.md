# AquaHunter offline base map

The production app keeps its base map available even when a business-data overlay is unavailable.

## Renderer

- iOS and Android: MapLibre Native, BSD 2-Clause.
- macOS: the same bundled Natural Earth geometry rendered by the native SwiftUI canvas until the MapLibre iOS binary distribution publishes a macOS slice.

## Land geometry

- Dataset: Natural Earth `ne_110m_land`
- Version: `5.1.2`
- File: `natural-earth/ne_110m_land.geojson`
- Upstream: `https://github.com/nvkelso/natural-earth-vector/blob/v5.1.2/geojson/ne_110m_land.geojson`
- SHA-256: `9e0729ee253ca7d7a5c4ae9395fb1902264c5377c52e224d13dd85010e2835d9`
- License: public domain; commercial use and modification are expressly permitted.
- Terms: `https://www.naturalearthdata.com/about/terms-of-use/`

This is a small-scale orientation map, not a nautical chart. It must never be used for navigation, maritime boundaries, protected-area decisions, route planning or safety decisions.
