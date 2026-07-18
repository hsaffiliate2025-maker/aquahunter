#!/usr/bin/env bash
set -euo pipefail
umask 077

JAVA_HOME_DIR="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
SIGNING_DIR="$HOME/Library/Application Support/AquaHunter/signing"
KEYSTORE_PATH="$SIGNING_DIR/aquahunter-upload.p12"
KEY_ALIAS="aquahunter_upload"
KEYCHAIN_SERVICE="app.hotseason.aquahunter.android-upload"

export JAVA_HOME="$JAVA_HOME_DIR"
export PATH="$JAVA_HOME_DIR/bin:$PATH"

mkdir -p "$SIGNING_DIR"
chmod 700 "$SIGNING_DIR"

if [[ -f "$KEYSTORE_PATH" ]]; then
    KEYSTORE_PASSWORD="$(security find-generic-password \
        -a "$KEY_ALIAS" \
        -s "$KEYCHAIN_SERVICE" \
        -w)"
else
    KEYSTORE_PASSWORD="$(openssl rand -hex 32)"
    security add-generic-password \
        -U \
        -a "$KEY_ALIAS" \
        -s "$KEYCHAIN_SERVICE" \
        -w "$KEYSTORE_PASSWORD"

    export AQUAHUNTER_KEYSTORE_PASSWORD="$KEYSTORE_PASSWORD"
    keytool -genkeypair \
        -keystore "$KEYSTORE_PATH" \
        -storetype PKCS12 \
        -storepass:env AQUAHUNTER_KEYSTORE_PASSWORD \
        -keypass:env AQUAHUNTER_KEYSTORE_PASSWORD \
        -alias "$KEY_ALIAS" \
        -keyalg RSA \
        -keysize 4096 \
        -validity 10000 \
        -dname "CN=AquaHunter Upload,O=Hot Season Enterprise Inc.,C=US"
    chmod 600 "$KEYSTORE_PATH"
fi

export AQUAHUNTER_KEYSTORE_PASSWORD="$KEYSTORE_PASSWORD"

echo "Keystore: $KEYSTORE_PATH"
echo "Alias: $KEY_ALIAS"
keytool -exportcert \
    -rfc \
    -keystore "$KEYSTORE_PATH" \
    -storepass:env AQUAHUNTER_KEYSTORE_PASSWORD \
    -alias "$KEY_ALIAS" |
    openssl x509 -noout -fingerprint -sha256

unset AQUAHUNTER_KEYSTORE_PASSWORD KEYSTORE_PASSWORD
