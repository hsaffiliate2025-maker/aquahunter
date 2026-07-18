# AquaHunter Privacy Policy

**Effective date:** 19 July 2026  
**Applies to:** AquaHunter Android, package `com.hsaffiliate.aquahunter`

## Summary

AquaHunter does not currently create user accounts, run advertising, process payments, request device location, access contacts, use the camera or microphone, or include analytics or crash-reporting SDKs.

The app connects over HTTPS to the Statistics Norway public API to retrieve published market statistics. Standard internet connection information, including the device IP address and the AquaHunter user-agent string, is necessarily transmitted to that provider when a request is made. AquaHunter does not operate that provider’s systems or control its server logs.

## Information processed by the app

- Market requests: the app requests Statistics Norway table 03024 using a fixed dataset query. The request does not include an AquaHunter account identifier, advertising identifier, location permission or question text.
- Questions: text entered in Aqua AI remains in app memory and is evaluated locally against the currently loaded authorized source. It is not sent to AquaHunter or an AI provider in this release and is not retained after the app process is cleared.
- Preferences: the selected background, language and accepted risk-notice version are stored locally on the device.
- Email: choosing the support option opens the user’s email application. Any message the user chooses to send is handled by the email providers involved.

## Permissions

The app declares internet and network-state access for the official market-data request. It does not request dangerous or sensitive Android permissions, including:

- Precise or approximate location
- Contacts, phone or call logs
- Camera or microphone
- Photos or storage
- Advertising ID

## Maps

This release does not include Google Maps SDK or a production map-tile provider. Map screens remain unavailable until a separately approved MapLibre-compatible source is connected and this policy is updated for its actual network and privacy behavior.

## Data sources

Published market statistics are retrieved from Statistics Norway and displayed with source, dataset ID, attribution, license and cadence. AquaHunter does not bundle substitute market, buyer, port, vessel or fish-probability records when a source is unavailable.

## Security and retention

Network requests use HTTPS. AquaHunter has no remote account database in this release. Locally stored preferences remain in the Android application sandbox and may be removed by clearing app data or uninstalling the app.

## Children

AquaHunter is a professional seafood-industry intelligence product and is not directed to children.

## Future changes

Before adding accounts, analytics, crash reporting, subscriptions, notifications, buyer contacts, maps, AIS, server-backed AI or other network services, this policy and the Google Play Data safety declaration must be updated to describe the actual collection, processing, sharing, retention and deletion behavior.

## Contact

Privacy and support email: `contact@hotseason.app`

Before store publication, add the legal operator’s full name and postal address and publish this policy at a stable public HTTPS URL.

---

This repository file is the policy source, not yet the required public policy URL.
