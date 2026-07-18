#!/bin/zsh
set -euo pipefail
umask 077

SIGNING_DIR="/private/tmp/aquahunter-final-signing"
KEYCHAIN_PATH="$SIGNING_DIR/AquaHunterFinal.keychain-db"
APPLICATION_P12="$SIGNING_DIR/AquaHunterApplication.p12"
INSTALLER_P12="$SIGNING_DIR/AquaHunterInstaller.p12"
APPLICATION_SHA1="5C80C5B328E723E90618CC62CD39EB0C52C38DED"
INSTALLER_SHA1="5374B8B2922B785B3EEBE080CEC2152B5EF53F79"

if [[ ! -f "$APPLICATION_P12" ]]; then
  print -u2 "Missing $APPLICATION_P12"
  exit 1
fi

if [[ ! -f "$INSTALLER_P12" ]]; then
  print -u2 "Missing $INSTALLER_P12"
  exit 1
fi

if [[ -e "$KEYCHAIN_PATH" ]]; then
  print -u2 "Temporary keychain already exists: $KEYCHAIN_PATH"
  print -u2 "Do not overwrite it automatically. Ask Codex to inspect or clean it first."
  exit 1
fi

mkdir -p "$SIGNING_DIR"
chmod 700 "$SIGNING_DIR"

if [[ -z "${APPLICATION_P12_PASSWORD:-}" ]]; then
  read -s "APPLICATION_P12_PASSWORD?Application P12 password (hidden): "
  print
fi
if [[ -z "${INSTALLER_P12_PASSWORD:-}" ]]; then
  read -s "INSTALLER_P12_PASSWORD?Installer P12 password (hidden): "
  print
fi

KEYCHAIN_PASSWORD="$(openssl rand -base64 48 | tr -d '\n')"
OLD_KEYCHAINS=("${(@f)$(security list-keychains -d user | tr -d '"' | sed 's/^[[:space:]]*//')}")

cleanup_secrets() {
  unset APPLICATION_P12_PASSWORD INSTALLER_P12_PASSWORD KEYCHAIN_PASSWORD
}
trap cleanup_secrets EXIT

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

security import "$APPLICATION_P12" \
  -k "$KEYCHAIN_PATH" \
  -P "$APPLICATION_P12_PASSWORD" \
  -T /usr/bin/codesign \
  -T /usr/bin/security

security import "$INSTALLER_P12" \
  -k "$KEYCHAIN_PATH" \
  -P "$INSTALLER_P12_PASSWORD" \
  -T /usr/bin/productbuild \
  -T /usr/bin/productsign \
  -T /usr/bin/codesign \
  -T /usr/bin/security

security set-key-partition-list \
  -S apple-tool:,apple:,codesign: \
  -s \
  -k "$KEYCHAIN_PASSWORD" \
  "$KEYCHAIN_PATH"

security list-keychains -d user -s "$KEYCHAIN_PATH" "${OLD_KEYCHAINS[@]}"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

IDENTITIES="$(security find-identity -v "$KEYCHAIN_PATH")"
if [[ "$IDENTITIES" != *"$APPLICATION_SHA1"* ]]; then
  print -u2 "Expected Application identity $APPLICATION_SHA1 is missing."
  exit 1
fi
if [[ "$IDENTITIES" != *"$INSTALLER_SHA1"* ]]; then
  print -u2 "Expected Installer identity $INSTALLER_SHA1 is missing."
  exit 1
fi

PROBE_BINARY="$SIGNING_DIR/codesign-probe"
cp /usr/bin/true "$PROBE_BINARY"
codesign \
  --force \
  --sign "$APPLICATION_SHA1" \
  --keychain "$KEYCHAIN_PATH" \
  --timestamp=none \
  "$PROBE_BINARY"
codesign --verify --verbose=2 "$PROBE_BINARY"

PROBE_ROOT="$SIGNING_DIR/empty-root"
PROBE_UNSIGNED="$SIGNING_DIR/probe-unsigned.pkg"
PROBE_SIGNED="$SIGNING_DIR/probe-signed.pkg"
mkdir -p "$PROBE_ROOT"
pkgbuild \
  --root "$PROBE_ROOT" \
  --identifier com.hsaffiliate.aquahunter.signing-probe \
  --version 1.0 \
  "$PROBE_UNSIGNED"
productbuild \
  --package "$PROBE_UNSIGNED" \
  --sign "$INSTALLER_SHA1" \
  --keychain "$KEYCHAIN_PATH" \
  "$PROBE_SIGNED"
pkgutil --check-signature "$PROBE_SIGNED"

print
print "AquaHunter temporary signing keychain is ready:"
print "$KEYCHAIN_PATH"
print "Both signing probes passed without using the login keychain."
