#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_NAME="${GOOGLE_PLAY_PACKAGE:-com.hotseason.aquahunter}"
TRACK="${GOOGLE_PLAY_TRACK:-internal}"
AAB_PATH="${GOOGLE_PLAY_AAB:-$ROOT/android/app/build/outputs/bundle/release/app-release.aab}"
METADATA_ROOT="${GOOGLE_PLAY_METADATA:-$ROOT/store-metadata/google}"
QUOTA_PROJECT="${GOOGLE_PLAY_QUOTA_PROJECT:-cashboomerang}"
GCLOUD="${GCLOUD:-/opt/homebrew/bin/gcloud}"
API_ROOT="https://androidpublisher.googleapis.com/androidpublisher/v3/applications/$PACKAGE_NAME"
UPLOAD_ROOT="https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/$PACKAGE_NAME"

for command in "$GCLOUD" curl jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 1
  fi
done

if [[ ! -f "$AAB_PATH" ]]; then
  echo "Missing AAB: $AAB_PATH" >&2
  exit 1
fi
if [[ ! -d "$METADATA_ROOT" ]]; then
  echo "Missing Google Play metadata: $METADATA_ROOT" >&2
  exit 1
fi

ACCESS_TOKEN="$("$GCLOUD" auth application-default print-access-token)"
AUTH_HEADERS=(
  -H "Authorization: Bearer $ACCESS_TOKEN"
  -H "X-Goog-User-Project: $QUOTA_PROJECT"
)

EDIT_ID="${GOOGLE_PLAY_EDIT_ID:-}"
VERSION_CODE="${GOOGLE_PLAY_VERSION_CODE:-}"
if [[ -z "$EDIT_ID" ]]; then
  EDIT_JSON="$(
    curl -fsS -X POST \
      "${AUTH_HEADERS[@]}" \
      -H "Content-Type: application/json" \
      -d '{}' \
      "$API_ROOT/edits"
  )"
  EDIT_ID="$(jq -er '.id' <<<"$EDIT_JSON")"
  echo "Created edit $EDIT_ID"
else
  echo "Resuming edit $EDIT_ID"
fi

if [[ -z "$VERSION_CODE" ]]; then
  BUNDLE_JSON="$(
    curl -fsS -X POST \
      "${AUTH_HEADERS[@]}" \
      -H "Content-Type: application/octet-stream" \
      --data-binary "@$AAB_PATH" \
      "$UPLOAD_ROOT/edits/$EDIT_ID/bundles?uploadType=media"
  )"
  VERSION_CODE="$(jq -er '.versionCode | tostring' <<<"$BUNDLE_JSON")"
  echo "Uploaded versionCode $VERSION_CODE"
else
  echo "Using uploaded versionCode $VERSION_CODE"
fi

for locale_dir in "$METADATA_ROOT"/*; do
  [[ -d "$locale_dir" ]] || continue
  locale="$(basename "$locale_dir")"
  listing_payload="$(
    jq -n \
      --rawfile title "$locale_dir/title.txt" \
      --rawfile short "$locale_dir/short-description.txt" \
      --rawfile full "$locale_dir/full-description.txt" \
      --arg locale "$locale" \
      '{
        language: $ARGS.named.locale,
        title: ($title | rtrimstr("\n")),
        shortDescription: ($short | rtrimstr("\n")),
        fullDescription: ($full | rtrimstr("\n"))
      }'
  )"
  curl -fsS -X PUT \
    "${AUTH_HEADERS[@]}" \
    -H "Content-Type: application/json" \
    -d "$listing_payload" \
    "$API_ROOT/edits/$EDIT_ID/listings/$locale" \
    >/dev/null
  echo "Synced listing $locale"
done

TRACK_PAYLOAD="$(
  jq -n \
    --arg track "$TRACK" \
    --arg version "$VERSION_CODE" \
    --arg name "AquaHunter 1.1.0 ($VERSION_CODE)" \
    '{
      track: $track,
      releases: [{
        name: $name,
        status: "completed",
        versionCodes: [$version],
        releaseNotes: []
      }]
    }'
)"

for locale_dir in "$METADATA_ROOT"/*; do
  [[ -d "$locale_dir" ]] || continue
  locale="$(basename "$locale_dir")"
  release_notes="$(<"$locale_dir/release-notes.txt")"
  TRACK_PAYLOAD="$(
    jq \
      --arg locale "$locale" \
      --arg text "$release_notes" \
      '.releases[0].releaseNotes += [{language: $locale, text: $text}]' \
      <<<"$TRACK_PAYLOAD"
  )"
done

curl -fsS -X PUT \
  "${AUTH_HEADERS[@]}" \
  -H "Content-Type: application/json" \
  -d "$TRACK_PAYLOAD" \
  "$API_ROOT/edits/$EDIT_ID/tracks/$TRACK" \
  >/dev/null
echo "Updated $TRACK track"

curl -fsS -X POST \
  "${AUTH_HEADERS[@]}" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "$API_ROOT/edits/$EDIT_ID:validate" \
  >/dev/null
echo "Validated edit $EDIT_ID"

COMMIT_JSON="$(
  curl -fsS -X POST \
    "${AUTH_HEADERS[@]}" \
    -H "Content-Type: application/json" \
    -d '{}' \
    "$API_ROOT/edits/$EDIT_ID:commit"
)"
jq -e '.id == $id' --arg id "$EDIT_ID" <<<"$COMMIT_JSON" >/dev/null
echo "Committed versionCode $VERSION_CODE to $TRACK"
