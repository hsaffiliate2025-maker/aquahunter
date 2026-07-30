# Google Play Data Safety — Pre-submission Audit

This document describes the current repository code. The final form must be completed against the exact signed AAB and reviewed in Google Play Console before submission.

## Current implementation evidence

- The manifest declares `INTERNET` and `ACCESS_NETWORK_STATE`.
- There are no location, contacts, camera, microphone, storage or advertising-ID permissions.
- The app contains no analytics, advertising, account or crash-reporting SDK. It uses Google Play Billing 9.1.0 for optional digital purchases.
- MapLibre Native OpenGL 13.0.2 renders only bundled Natural Earth GeoJSON. The app makes no online map-style or tile request and explicitly removes MapLibre's optional location and Wi-Fi permissions from the merged manifest.
- A fixed HTTPS request retrieves Statistics Norway table 03024. Standard network data such as the device IP address and an AquaHunter user-agent reaches Statistics Norway.
- Background style, language and the accepted legal-notice version are stored locally.
- Purchased credit balances, monthly usage, active subscription product IDs and one-way transaction-token hashes are stored locally. Raw Google purchase tokens are passed to Play Billing for acknowledgement or consumption and are not retained in the local ledger or sent to an AquaHunter server.
- No user account or AquaHunter cloud profile exists in this release.
- Aqua AI is not included in this release and the app does not transmit user questions to an AI provider.

## Questions requiring final Console review

| Play Console question | Current code evidence |
| --- | --- |
| Does the app collect user data for the developer? | No AquaHunter backend, analytics or account collection is implemented. Purchase processing is performed by Google Play; the app keeps only a device-local entitlement ledger. Confirm the final Console definition against the signed AAB. |
| Does the app share data with a third party? | A direct HTTPS request necessarily exposes standard connection metadata to Statistics Norway. Determine the correct Console declaration with legal/privacy review. |
| Is transmitted data encrypted? | The configured endpoint is HTTPS. |
| Can users request data deletion? | No AquaHunter account or server-side user record exists. Local preferences and the local entitlement ledger can be cleared by clearing app data or uninstalling; doing so also removes unspent consumable balances. |
| Does the app contain ads or use Advertising ID? | No. |
| Does the app request location or sensitive permissions? | No. |
| Is a privacy policy required? | Yes; publish the final policy at a public HTTPS URL. |

## Re-audit triggers

Re-run dependency, manifest and network inspection after adding any of the following:

- Accounts or authentication
- Aqua AI, server-backed AI or user-question transmission
- Analytics or crash reporting
- An AquaHunter payment/entitlement server or non-Play payment channel
- Push notifications
- Precise buyer contacts
- Device location
- Online MapLibre tile, style, telemetry or geocoding providers
- AIS or vessel providers
- Advertising or attribution SDKs
- Persistent searches, favorites, exports or watchlists

Do not submit the Data safety form solely from this document; compare it with the final Play Console wording and the built artifact.
