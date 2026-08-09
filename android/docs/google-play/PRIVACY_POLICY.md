# AquaHunter Privacy Policy

**Effective date:** 30 July 2026
**Applies to:** AquaHunter for Android, iOS, iPadOS and macOS; package/bundle ID `com.hotseason.aquahunter`

## Summary

AquaHunter does not currently create user accounts, run advertising, request device location, access contacts, use the camera or microphone, or include analytics or crash-reporting SDKs. Optional digital purchases are processed by Apple through StoreKit or by Google through Google Play Billing; AquaHunter does not collect card or bank details.

The app connects over HTTPS to the Statistics Norway public API to retrieve published market statistics. Standard internet connection information, including the device IP address and the AquaHunter user-agent string, is necessarily transmitted to that provider when a request is made. AquaHunter does not operate that provider’s systems or control its server logs.

## Information processed by the app

- Market requests: the app requests Statistics Norway table 03024 using a fixed dataset query. The request does not include an AquaHunter account identifier, advertising identifier or device location.
- Preferences: the selected background, language and accepted risk-notice version are stored locally on the device.
- Purchases and entitlements: the app requests product identifiers, localized prices, purchase state and current entitlements from Apple or Google. AquaHunter stores purchased credit balances, monthly usage, active subscription product identifiers and a one-way transaction-token hash locally in the app sandbox to prevent duplicate credit. The raw Android purchase token is used only with Google Play Billing for acknowledgement or consumption and is not retained in the local ledger or sent to an AquaHunter server.
- Email: choosing the support option opens the user’s email application. Any message the user chooses to send is handled by the email providers involved.

This release does not include Aqua AI or transmit user questions to an AI provider.

## Permissions

The app declares internet and network-state access for the official market-data request and Google Play Billing permission for optional digital purchases. Billing permission does not provide AquaHunter with payment-card details. The app does not request dangerous or sensitive Android permissions, including:

- Precise or approximate location
- Contacts, phone or call logs
- Camera or microphone
- Photos or storage
- Advertising ID

## Maps

The app includes an offline world reference map built from Natural Earth 5.1.2 public-domain GeoJSON. Android and Apple mobile builds render the bundled map with MapLibre Native; macOS renders the same bundled data with native SwiftUI drawing. The map does not request online map tiles, device location or Wi-Fi information and does not send map interactions to Google Maps, Apple Maps, OpenStreetMap community tile servers or AquaHunter.

The offline map is not a nautical chart and must not be used for navigation, legal-boundary decisions, fishing-zone determinations or safety-of-life decisions.

## Data sources

Published market statistics are retrieved from Statistics Norway and displayed with source, dataset ID, attribution, license and cadence. AquaHunter does not bundle substitute market, buyer, port, vessel or fish-probability records when a source is unavailable.

## Security and retention

Network requests use HTTPS. AquaHunter has no remote account database in this release. Preferences and the device-local purchase ledger remain in the application sandbox and may be removed by clearing app data or uninstalling the app. Auto-renewing subscriptions can be queried and restored through the user’s Apple or Google account. Consumable credit balances are device-local in this release and cannot be restored after app data is cleared or the app is uninstalled; this limitation is shown in the purchase screen.

## Children

AquaHunter is a professional seafood-industry intelligence product and is not directed to children.

## Future changes

Before adding accounts, an AquaHunter payment or entitlement server, analytics, crash reporting, push notifications, buyer contacts, online map services, AIS, server-backed AI or other network services, this policy and the Google Play Data safety declaration must be updated to describe the actual collection, processing, sharing, retention and deletion behavior.

## Contact

Privacy and support email: `contact@hotseason.app`

Hotseason Enterprise, Inc.

Attn: Legal Department

440 N Wolfe Rd MS 92

Sunnyvale, CA 94085, USA

---

Repository source. Public policy URL: `https://hotseason.app/en/policy#aquahunter`
