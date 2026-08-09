# AquaHunter Google Play Release Checklist

## Build identity

- App name: `AquaHunter`
- Package name: `com.hotseason.aquahunter`
- Version name: `1.1.0`
- Version code: `3`
- Minimum Android: API 26 / Android 8.0
- Compile and target SDK: API 36 / Android 16
- Distribution artifact: Android App Bundle (`.aab`)

The package name is permanent after the first Play upload. Confirm the organization owns and accepts `com.hotseason.aquahunter` before creating the Play Console app.

## Android developer verification

- [x] Developer identity is verified in Android developer verification
- [x] Final package name `com.hotseason.aquahunter` is registered on the **Package names** tab
- [x] Registered package name, uploaded AAB application ID, signing identity, and Play Console app all match

Package-name registration is a release blocker. Do not register a temporary application ID and do not change `applicationId` after registration without re-checking the verification record.

## Before internal testing

- [x] Confirm legal developer/operator name: `Hot Season Inc` organization account
- [x] Confirm package name
- [x] Create an upload keystore and store it outside the repository with its password in macOS Keychain
- [x] Build the signed release through `android/scripts/build_signed_release.sh`
- [x] Verify the signed AAB, APK, merged permissions and bundled map assets
- [x] Upload through Google Play internal testing: `AquaHunter 1.1.0 (3)`, available to internal testers
- [ ] Enable Play App Signing
- [ ] Add tester emails
- [x] Complete content-rating questionnaire
- [x] Declare no ads
- [ ] Select the appropriate app category
- [x] Provide public support email `contact@hotseason.app` and website `https://hotseason.app/en/aquahunter`

## Store listing

- [x] App title
- [x] Short description
- [x] Full description
- [x] 512×512 app icon at `store/google-play/graphics/app-icon-512.png`
- [x] 1024×500 feature graphic at `store/google-play/graphics/feature-graphic-1024x500.png`
- [x] Three 1080×2400 Pixel 6 screenshots at `store/google-play/en-US/phone-screenshots/`
- [x] Privacy policy URL reserved at `https://hotseason.app/en/policy#aquahunter`
- [x] Verify that the deployed policy content matches the current signed AAB. Website commit `0d308a7ddbd35a42755670f5b7170b6b1ffb2d18` is live and describes Google Play Billing, the device-local purchase/usage ledger, loss of unspent consumables after app-data removal, and subscription restoration.
- [x] Store listing and screenshots contain no Demo/fixture/fictitious records
- [x] Every visible record is backed by an enabled source in `docs/data-sources.json`
- [x] No claim of live data when a source is delayed, weekly, monthly or unavailable
- [x] No claim that Fish Radar detects fish or guarantees catch

## Policy declarations

- [x] Data safety form matches the exact uploaded AAB: app does not collect or share data
- [x] App access: no login required in this MVP
- [x] Ads: no
- [x] Target audience: professional/adult audience; not designed for children
- [ ] News declaration: not a news app
- [x] Financial features declaration: market intelligence only; no trading or investment transactions
- [x] Health declaration: not a health app
- [ ] Permissions declaration: no sensitive permissions
- [x] Content rating reflects the current trade and marine information features

## Quality gates

- [x] `testDebugUnitTest` passes
- [x] `connectedDebugAndroidTest` passes on Android 16
- [x] `lintDebug` has no blocking errors
- [x] `assembleDebug` produces an installable APK
- [x] Signed `assembleRelease` and `bundleRelease` produce verified release artifacts
- [x] Cold launch, first-use acknowledgement, four-tab navigation, Markets history, Radar unavailable state, Network unavailable state and Settings are manually smoke-tested on Android emulators
- [x] Signed release APK is installed and the first-use acknowledgement, Pulse, Markets and 30-week history are manually smoke-tested on a physical Pixel 6
- [ ] TalkBack/large text smoke test completed
- [ ] Phone and tablet layout smoke tests completed
- [x] No real contacts or unlicensed third-party data are bundled
- [x] `python3 tools/validate_data_sources.py --release` passes from the repository root
- [x] `python3 tools/validate_release_content.py` passes from the repository root
- [x] App has no fictional fallback prices, K-lines, buyers, ports, vessels, radar probabilities or AI answers
- [ ] Every record exposes source, observation/publish/retrieval time, latency and required attribution
- [x] Google Maps dependency/API key metadata has been removed
- [x] MapLibre renders only bundled Natural Earth public-domain data; no public community or paid tile service is contacted
- [x] Release manifest has no device-location or Wi-Fi-state permission

## Production access

The Play Console identifies Hot Season Inc as an organization account. Production access is active and serves `AquaHunter 1.1.0 (3)` at 100%.

## Release build

```bash
android/scripts/build_signed_release.sh
```

Verified outputs for version `1.1.0 (3)`:

```text
android/app/build/outputs/apk/release/app-release.apk
android/app/build/outputs/bundle/release/app-release.aab
```

Release signing is mandatory. A direct release build fails when the upload signing environment is absent, so the repository does not intentionally produce an unsigned upload candidate.

Current signed artifact evidence:

- AAB SHA-256: `e0e59f2e262d01dffb1e2d95ce0e2254d63335ee6034fe90b4e9fb95f6c9b8a3`
- APK SHA-256: `757d77c4beefd28913e3b3e22e9cea297768b2f66bbf2cc41ebf82559dc67640`
- Upload certificate SHA-256: `7bc5fe76f96a300a7c4281e957d5659bf089ac68902f2abd951255f3c5cc960e`

## Current Play Console state

- 2026-07-31: the developer account reports all apps registered for Android developer verification.
- `AquaHunter 1.1.0 (3)` remains active in Internal testing and is compatible with 17,585 devices.
- All 10 App content declarations are actioned and Policy status reports `No issues found`.
- On 2026-07-31 the product owner explicitly authorized the Android production release, superseding the earlier hold.
- Production track status is `Active`; `Latest release` is `AquaHunter 1.1.0 (3)`, rolled out to 100% across 177 countries/regions.
- The Publishing overview reports the latest publication date as 2026-07-31 and has no remaining unpublished release change.
