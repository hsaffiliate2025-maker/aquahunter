#!/usr/bin/env bash
set -euo pipefail

ANDROID_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JAVA_HOME_DIR="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
KEYSTORE_PATH="$HOME/Library/Application Support/AquaHunter/signing/aquahunter-upload.p12"
KEY_ALIAS="aquahunter_upload"
KEYCHAIN_SERVICE="app.hotseason.aquahunter.android-upload"
APKSIGNER="$HOME/Library/Android/sdk/build-tools/36.0.0/apksigner"

if [[ ! -f "$KEYSTORE_PATH" ]]; then
    echo "Missing AquaHunter upload key. Run android/scripts/create_upload_keystore.sh first." >&2
    exit 1
fi

KEYSTORE_PASSWORD="$(security find-generic-password \
    -a "$KEY_ALIAS" \
    -s "$KEYCHAIN_SERVICE" \
    -w)"

export JAVA_HOME="$JAVA_HOME_DIR"
export PATH="$JAVA_HOME_DIR/bin:$PATH"
export AQUAHUNTER_UPLOAD_STORE_FILE="$KEYSTORE_PATH"
export AQUAHUNTER_UPLOAD_STORE_PASSWORD="$KEYSTORE_PASSWORD"
export AQUAHUNTER_UPLOAD_KEY_ALIAS="$KEY_ALIAS"
export AQUAHUNTER_UPLOAD_KEY_PASSWORD="$KEYSTORE_PASSWORD"

cd "$ANDROID_ROOT"
./gradlew clean testDebugUnitTest lintDebug assembleRelease bundleRelease

APK_PATH="$ANDROID_ROOT/app/build/outputs/apk/release/app-release.apk"
AAB_PATH="$ANDROID_ROOT/app/build/outputs/bundle/release/app-release.aab"

"$APKSIGNER" verify --print-certs "$APK_PATH"
jarsigner -verify "$AAB_PATH"

keytool -exportcert \
    -rfc \
    -keystore "$KEYSTORE_PATH" \
    -storepass:env AQUAHUNTER_UPLOAD_STORE_PASSWORD \
    -alias "$KEY_ALIAS" |
    openssl x509 -noout -fingerprint -sha256

unset \
    AQUAHUNTER_UPLOAD_STORE_FILE \
    AQUAHUNTER_UPLOAD_STORE_PASSWORD \
    AQUAHUNTER_UPLOAD_KEY_ALIAS \
    AQUAHUNTER_UPLOAD_KEY_PASSWORD \
    KEYSTORE_PASSWORD

echo "Signed APK: $APK_PATH"
echo "Signed AAB: $AAB_PATH"
