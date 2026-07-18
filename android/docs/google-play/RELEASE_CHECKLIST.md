# AquaHunter Google Play Release Checklist

## Build identity

- App name: `AquaHunter`
- Package name: `com.hsaffiliate.aquahunter`
- Version name: `0.1.0`
- Version code: `1`
- Minimum Android: API 26 / Android 8.0
- Compile and target SDK: API 36 / Android 16
- Distribution artifact: Android App Bundle (`.aab`)

The package name is permanent after the first Play upload. Confirm the organization owns and accepts `com.hsaffiliate.aquahunter` before creating the Play Console app.

## Android developer verification

- [ ] Developer identity is verified in Android developer verification
- [ ] Final package name `com.hsaffiliate.aquahunter` is registered on the **Package names** tab
- [ ] Registered package name, uploaded AAB application ID, signing identity, and Play Console app all match

Package-name registration is a release blocker. Do not register a temporary application ID and do not change `applicationId` after registration without re-checking the verification record.

## Before internal testing

- [ ] Confirm legal developer/operator name
- [ ] Confirm package name
- [ ] Create an upload keystore and store it in a secure password manager
- [ ] Copy `keystore.properties.example` to ignored `keystore.properties`
- [ ] Build `bundleRelease`
- [ ] Verify the AAB signature and manifest
- [ ] Upload through Google Play internal testing
- [ ] Enable Play App Signing
- [ ] Add tester emails
- [ ] Complete content-rating questionnaire
- [ ] Declare no ads
- [ ] Select the appropriate app category
- [ ] Provide a public support email and website

## Store listing

- [ ] App title
- [ ] Short description
- [ ] Full description
- [ ] 512×512 app icon
- [ ] 1024×500 feature graphic
- [ ] At least two phone screenshots; four or more recommended for the MVP flow
- [ ] Privacy policy at a public HTTPS URL
- [ ] Store listing and screenshots contain no Demo/fixture/fictitious records
- [ ] Every visible record is backed by an enabled source in `docs/data-sources.json`
- [ ] No claim of live data when a source is delayed, weekly, monthly or unavailable
- [ ] No claim that Fish Radar detects fish or guarantees catch

## Policy declarations

- [ ] Data safety form matches the exact uploaded AAB
- [ ] App access: no login required in this MVP
- [ ] Ads: no
- [ ] Target audience: professional/adult audience; not designed for children
- [ ] News declaration: not a news app
- [ ] Financial features declaration: market intelligence only; no trading or investment transactions
- [ ] Health declaration: not a health app
- [ ] Permissions declaration: no sensitive permissions
- [ ] Content rating reflects trade, marine, and AI information accurately

## Quality gates

- [ ] `testDebugUnitTest` passes
- [ ] `connectedDebugAndroidTest` passes on Android 16
- [ ] `lintDebug` has no blocking errors
- [ ] `assembleDebug` produces an installable APK
- [ ] `bundleRelease` produces an AAB
- [ ] Cold launch, bottom navigation, search, filters, radar slider, layer switcher, buyer expansion, trade, port and vessel tabs, and Aqua AI prompts are manually verified
- [ ] TalkBack/large text smoke test completed
- [ ] Phone and tablet layout smoke tests completed
- [ ] No real contacts or unlicensed third-party data are bundled
- [ ] `python3 tools/validate_data_sources.py --release` passes from the repository root
- [ ] `python3 tools/validate_release_content.py` passes from the repository root
- [ ] App has no fictional fallback prices, K-lines, buyers, ports, vessels, radar probabilities or AI answers
- [ ] Every record exposes source, observation/publish/retrieval time, latency and required attribution
- [ ] Google Maps dependency/API key metadata has been removed
- [ ] MapLibre uses self-hosted tiles or a provider contract that explicitly permits commercial mobile use

## Production access

For personal Play developer accounts created after 13 November 2023, confirm whether Play Console requires a closed test with at least 12 opted-in testers for 14 continuous days before production access. Organization and older accounts may have different requirements; Play Console is authoritative.

## Release build

```bash
cp keystore.properties.example keystore.properties
# Replace every placeholder with the secure upload-key values.
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew clean testDebugUnitTest lintDebug bundleRelease
```

Expected unsigned output when no release signing file is configured:

```text
app/build/outputs/bundle/release/app-release.aab
```

Do not upload an unsigned bundle. Configure the upload key and rebuild.
