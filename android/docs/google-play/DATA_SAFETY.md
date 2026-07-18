# Google Play Data Safety — Pre-submission Audit

This document describes the current repository code. The final form must be completed against the exact signed AAB and reviewed in Google Play Console before submission.

## Current implementation evidence

- The manifest declares `INTERNET` and `ACCESS_NETWORK_STATE`.
- There are no location, contacts, camera, microphone, storage or advertising-ID permissions.
- The app contains no analytics, advertising, account, payment, crash-reporting or map SDK.
- A fixed HTTPS request retrieves Statistics Norway table 03024. Standard network data such as the device IP address and an AquaHunter user-agent reaches Statistics Norway.
- Questions entered in Aqua AI stay in Compose memory and are not sent to AquaHunter, Statistics Norway or an AI provider.
- Background style, language and the accepted legal-notice version are stored locally.
- No user account or AquaHunter cloud profile exists in this release.

## Questions requiring final Console review

| Play Console question | Current code evidence |
| --- | --- |
| Does the app collect user data for the developer? | No AquaHunter backend, analytics or account collection is implemented. Confirm the final definition against the signed AAB. |
| Does the app share data with a third party? | A direct HTTPS request necessarily exposes standard connection metadata to Statistics Norway. Determine the correct Console declaration with legal/privacy review. |
| Is transmitted data encrypted? | The configured endpoint is HTTPS. |
| Can users request data deletion? | No AquaHunter account or server-side user record exists. Local preferences can be cleared by clearing app data or uninstalling. |
| Does the app contain ads or use Advertising ID? | No. |
| Does the app request location or sensitive permissions? | No. |
| Is a privacy policy required? | Yes; publish the final policy at a public HTTPS URL. |

## Re-audit triggers

Re-run dependency, manifest and network inspection after adding any of the following:

- Accounts or authentication
- Server-backed AI or user-question transmission
- Analytics or crash reporting
- Subscriptions or payments
- Push notifications
- Precise buyer contacts
- Device location
- MapLibre tile or style providers
- AIS or vessel providers
- Advertising or attribution SDKs
- Persistent searches, favorites, exports or watchlists

Do not submit the Data safety form solely from this document; compare it with the final Play Console wording and the built artifact.
