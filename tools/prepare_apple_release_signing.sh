#!/bin/zsh
set -euo pipefail

ROOT_DIR=${0:A:h:h}
SIGNING_DIR=${AQUAHUNTER_SIGNING_DIR:-/private/tmp/aquahunter-release-signing}
KEYCHAIN_PATH="$SIGNING_DIR/aquahunter-release.keychain-db"
PASSWORD_FILE="$SIGNING_DIR/keychain-password"
WWDR_G3_CERT="$SIGNING_DIR/AppleWWDRCAG3.cer"
WWDR_G3_URL="https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer"
WWDR_G3_SHA256="dcf21878c77f4198e4b4614f03d696d89c66c66008d4244e1b99161aac91601f"

IOS_CERT_ID=${AQUAHUNTER_IOS_CERT_ID:-38T5M89JA4}
MAC_APP_CERT_ID=${AQUAHUNTER_MAC_APP_CERT_ID:-Z28TY5A8B3}
MAC_INSTALLER_CERT_ID=${AQUAHUNTER_MAC_INSTALLER_CERT_ID:-69QX6LXSHA}
IOS_PROFILE_ID=${AQUAHUNTER_IOS_PROFILE_ID:-5935SJ9FXC}
MAC_PROFILE_ID=${AQUAHUNTER_MAC_PROFILE_ID:-AH797TH82T}

mkdir -p "$SIGNING_DIR"
chmod 700 "$SIGNING_DIR"

for key in \
  "$SIGNING_DIR/ios-distribution.key" \
  "$SIGNING_DIR/mac-app-distribution.key" \
  "$SIGNING_DIR/mac-installer-distribution.key"; do
  if [[ ! -f "$key" ]]; then
    echo "Missing AquaHunter private key: $key" >&2
    exit 1
  fi
done

if [[ ! -f "$PASSWORD_FILE" ]]; then
  /usr/bin/openssl rand -hex 32 > "$PASSWORD_FILE"
  chmod 600 "$PASSWORD_FILE"
fi
keychain_password=$(<"$PASSWORD_FILE")

build_identity() {
  local certificate_id=$1
  local private_key=$2
  local stem=$3
  local certificate_json="$SIGNING_DIR/$stem-certificate.json"
  local certificate_base64="$SIGNING_DIR/$stem-certificate.base64"
  local certificate_der="$SIGNING_DIR/$stem-certificate.cer"
  local certificate_pem="$SIGNING_DIR/$stem-certificate.pem"
  local identity_p12="$SIGNING_DIR/$stem-identity.p12"

  asc certificates view \
    --id "$certificate_id" \
    --output json > "$certificate_json"
  jq -er '.data.attributes.certificateContent' \
    "$certificate_json" > "$certificate_base64"
  /usr/bin/base64 -D \
    -i "$certificate_base64" \
    -o "$certificate_der"
  /usr/bin/openssl x509 \
    -inform DER \
    -in "$certificate_der" \
    -out "$certificate_pem"
  /usr/bin/openssl pkcs12 \
    -export \
    -inkey "$private_key" \
    -in "$certificate_pem" \
    -out "$identity_p12" \
    -passout "pass:$keychain_password"
  chmod 600 "$private_key" "$identity_p12"
}

build_identity \
  "$IOS_CERT_ID" \
  "$SIGNING_DIR/ios-distribution.key" \
  "ios-distribution"
build_identity \
  "$MAC_APP_CERT_ID" \
  "$SIGNING_DIR/mac-app-distribution.key" \
  "mac-app-distribution"
build_identity \
  "$MAC_INSTALLER_CERT_ID" \
  "$SIGNING_DIR/mac-installer-distribution.key" \
  "mac-installer-distribution"

if [[ -f "$KEYCHAIN_PATH" ]]; then
  security delete-keychain "$KEYCHAIN_PATH"
fi
security create-keychain -p "$keychain_password" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$keychain_password" "$KEYCHAIN_PATH"

if [[ ! -f "$WWDR_G3_CERT" ]]; then
  curl -fsSL "$WWDR_G3_URL" -o "$WWDR_G3_CERT"
fi
actual_wwdr_sha256=$(
  shasum -a 256 "$WWDR_G3_CERT" |
    awk '{print $1}'
)
if [[ "$actual_wwdr_sha256" != "$WWDR_G3_SHA256" ]]; then
  echo "Apple WWDR G3 certificate checksum mismatch." >&2
  exit 1
fi
security import "$WWDR_G3_CERT" \
  -k "$KEYCHAIN_PATH" \
  -T /usr/bin/codesign \
  -T /usr/bin/productbuild \
  -T /usr/bin/security >/dev/null

for identity in \
  "$SIGNING_DIR/ios-distribution-identity.p12" \
  "$SIGNING_DIR/mac-app-distribution-identity.p12" \
  "$SIGNING_DIR/mac-installer-distribution-identity.p12"; do
  security import "$identity" \
    -k "$KEYCHAIN_PATH" \
    -P "$keychain_password" \
    -T /usr/bin/codesign \
    -T /usr/bin/productbuild \
    -T /usr/bin/security >/dev/null
done

security set-key-partition-list \
  -S apple-tool:,apple:,codesign: \
  -s \
  -k "$keychain_password" \
  "$KEYCHAIN_PATH" >/dev/null
security list-keychains \
  -d user \
  -s "$KEYCHAIN_PATH" "$HOME/Library/Keychains/login.keychain-db"

asc profiles download \
  --id "$IOS_PROFILE_ID" \
  --output "$SIGNING_DIR/AquaHunter-iOS-AppStore.mobileprovision" \
  >/dev/null
asc profiles download \
  --id "$MAC_PROFILE_ID" \
  --output "$SIGNING_DIR/AquaHunter-Mac-AppStore.provisionprofile" \
  >/dev/null
asc profiles local install \
  --path "$SIGNING_DIR/AquaHunter-iOS-AppStore.mobileprovision" \
  --force \
  >/dev/null
asc profiles local install \
  --path "$SIGNING_DIR/AquaHunter-Mac-AppStore.provisionprofile" \
  --force \
  >/dev/null

codesign_count=$(
  security find-identity \
    -v \
    -p codesigning \
    "$KEYCHAIN_PATH" |
    awk '/valid identities found/ {print $1}'
)
installer_count=$(
  security find-certificate \
    -c "3rd Party Mac Developer Installer" \
    "$KEYCHAIN_PATH" |
    wc -l |
    tr -d ' '
)
if [[ "$codesign_count" -lt 2 || "$installer_count" -lt 1 ]]; then
  echo "AquaHunter temporary signing keychain verification failed." >&2
  exit 1
fi

echo "AquaHunter release signing is ready in a temporary keychain."
echo "Installed profiles: $IOS_PROFILE_ID, $MAC_PROFILE_ID"
