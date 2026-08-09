#!/bin/zsh
set -euo pipefail

ROOT_DIR=${0:A:h:h}
cd "$ROOT_DIR"

APP_ID=${ASC_APP_ID:-6792849577}
CATALOG="commerce/product-catalog.json"
LOCALIZATIONS="commerce/localizations.json"
MANIFEST="store-metadata/iap-localizations.json"
PRICING="commerce/store-pricing.json"
REVIEW_SCREENSHOT="artifacts/screenshots/iap-review/toolkit-store.png"

if [[ ! -f "$REVIEW_SCREENSHOT" ]]; then
  echo "Missing IAP review screenshot: $REVIEW_SCREENSHOT" >&2
  exit 1
fi

python3 tools/validate_commerce_catalog.py
python3 tools/generate_store_metadata.py >/dev/null

retry() {
  local attempt
  for attempt in 1 2 3 4 5; do
    if "$@"; then
      return 0
    fi
    if [[ "$attempt" -lt 5 ]]; then
      sleep "$attempt"
    fi
  done
  return 1
}

territories=$(
  retry asc pricing territories list --paginate --output json |
    jq -r '[.data[].id] | join(",")'
)

sync_iap_localizations() {
  local iap_id=$1
  local product_id=$2
  local existing locale name description

  existing=$(retry asc iap localizations list --iap-id "$iap_id" --output json)
  while IFS=$'\t' read -r locale name description; do
    if jq -e --arg locale "$locale" \
      '(.data // [])[] | select(.attributes.locale==$locale)' \
      >/dev/null <<<"$existing"; then
      continue
    fi
    retry asc iap localizations create \
      --iap-id "$iap_id" \
      --locale "$locale" \
      --name "$name" \
      --description "$description" \
      --output json >/dev/null
  done < <(
    jq -r --arg id "$product_id" \
      '.products[] | select(.productId==$id) |
       .localizations[] |
       [.appleLocale,.displayName,.description] | @tsv' \
      "$MANIFEST"
  )
}

if [[ "${ASC_SKIP_IAPS:-0}" != "1" ]]; then
  iaps=$(retry asc iap list --app "$APP_ID" --limit 200 --output json)
  while IFS=$'\t' read -r product_id price; do
  iap_id=$(
    jq -r --arg id "$product_id" \
      '(.data // [])[] | select(.attributes.productId==$id) | .id' \
      <<<"$iaps"
  )
  if [[ -z "$iap_id" ]]; then
    name=$(
      jq -r --arg id "$product_id" \
        '.products[] | select(.productId==$id) |
         .localizations.en.displayName' \
        "$MANIFEST"
    )
    description=$(
      jq -r --arg id "$product_id" \
        '.products[] | select(.productId==$id) |
         .localizations.en.description' \
        "$MANIFEST"
    )
    asc iap setup \
      --app "$APP_ID" \
      --type CONSUMABLE \
      --reference-name "$name" \
      --product-id "$product_id" \
      --locale en-US \
      --display-name "$name" \
      --description "$description" \
      --price "$price" \
      --base-territory USA \
      --no-verify \
      --output json >/dev/null
    iaps=$(retry asc iap list --app "$APP_ID" --limit 200 --output json)
    iap_id=$(
      jq -r --arg id "$product_id" \
        '(.data // [])[] | select(.attributes.productId==$id) | .id' \
        <<<"$iaps"
    )
  fi

  echo "Syncing $product_id"
  retry asc iap pricing availability set \
    --iap-id "$iap_id" \
    --territories "$territories" \
    --available-in-new-territories \
    --output json >/dev/null
  screenshot=$(
    retry asc iap review-screenshots view \
      --iap-id "$iap_id" \
      --output json
  )
  screenshot_id=$(jq -r '.data.id // empty' <<<"$screenshot")
  if [[ -z "$screenshot_id" ]]; then
    retry asc iap review-screenshots create \
      --iap-id "$iap_id" \
      --file "$REVIEW_SCREENSHOT" \
      --output json >/dev/null
  elif [[ "${ASC_REFRESH_REVIEW_SCREENSHOTS:-0}" == "1" ]]; then
    retry asc iap review-screenshots delete \
      --screenshot-id "$screenshot_id" \
      --confirm \
      --output json >/dev/null
    retry asc iap review-screenshots create \
      --iap-id "$iap_id" \
      --file "$REVIEW_SCREENSHOT" \
      --output json >/dev/null
  fi
    sync_iap_localizations "$iap_id" "$product_id"
  done < <(
    jq -r --slurpfile pricing "$PRICING" \
      '.products[] | select(.storeType=="consumable") |
       [.id,$pricing[0].products[.id].usdPrice] | @tsv' \
      "$CATALOG"
  )
fi

if [[ "${ASC_SKIP_SUBSCRIPTIONS:-0}" != "1" ]]; then
groups=$(retry asc subscriptions groups list --app "$APP_ID" --output json)
group_id=$(
  jq -r \
    '(.data // [])[] |
     select(.attributes.referenceName=="AquaHunter Markets") |
     .id' \
    <<<"$groups"
)
if [[ -z "$group_id" ]]; then
  retry asc subscriptions groups create \
    --app "$APP_ID" \
    --reference-name "AquaHunter Markets" \
    --output json >/dev/null
  groups=$(retry asc subscriptions groups list --app "$APP_ID" --output json)
  group_id=$(
    jq -r \
      '(.data // [])[] |
       select(.attributes.referenceName=="AquaHunter Markets") |
       .id' \
      <<<"$groups"
  )
fi

group_localizations=$(
  retry asc subscriptions groups localizations list \
    --group-id "$group_id" \
    --paginate \
    --output json
)
while IFS=$'\t' read -r locale name; do
  if jq -e --arg locale "$locale" \
    '(.data // [])[] | select(.attributes.locale==$locale)' \
    >/dev/null <<<"$group_localizations"; then
    continue
  fi
  retry asc subscriptions groups localizations create \
    --group-id "$group_id" \
    --locale "$locale" \
    --name "$name" \
    --output json >/dev/null
done < <(
  jq -r --slurpfile catalog "$CATALOG" \
    '.locales | to_entries[] as $entry |
     [$catalog[0].storeLocaleMap[$entry.key].apple,
      $entry.value.subscriptionGroupName] | @tsv' \
  "$LOCALIZATIONS"
)

subscription_review_token=""
review_screenshot_md5=$(md5 -q "$REVIEW_SCREENSHOT")
if [[ "${ASC_REFRESH_REVIEW_SCREENSHOTS:-0}" == "1" ]]; then
  subscription_review_token=$(asc auth token --confirm)
fi

subscriptions=$(
  retry asc subscriptions list \
    --group-id "$group_id" \
    --paginate \
    --output json
)
while IFS=$'\t' read -r product_id billing_period tier price; do
  subscription_id=$(
    jq -r --arg id "$product_id" \
      '(.data // [])[] | select(.attributes.productId==$id) | .id' \
      <<<"$subscriptions"
  )
  if [[ -z "$subscription_id" ]]; then
    name=$(
      jq -r --arg id "$product_id" \
        '.products[] | select(.productId==$id) |
         .localizations.en.displayName' \
        "$MANIFEST"
    )
    description=$(
      jq -r --arg id "$product_id" \
        '.products[] | select(.productId==$id) |
         .localizations.en.description' \
        "$MANIFEST"
    )
    if [[ "$billing_period" == "P1M" ]]; then
      apple_period="ONE_MONTH"
    else
      apple_period="ONE_YEAR"
    fi
    retry asc subscriptions setup \
      --group-id "$group_id" \
      --reference-name "$name" \
      --product-id "$product_id" \
      --subscription-period "$apple_period" \
      --locale en-US \
      --display-name "$name" \
      --description "$description" \
      --review-screenshot "$REVIEW_SCREENSHOT" \
      --price "$price" \
      --price-territory USA \
      --territories "$territories" \
      --available-in-new-territories \
      --no-verify \
      --output json >/dev/null
    subscriptions=$(
      retry asc subscriptions list \
        --group-id "$group_id" \
        --paginate \
        --output json
    )
    subscription_id=$(
      jq -r --arg id "$product_id" \
        '(.data // [])[] | select(.attributes.productId==$id) | .id' \
        <<<"$subscriptions"
    )
  fi

  case "$tier" in
    max) group_level=1 ;;
    pro) group_level=2 ;;
    plus) group_level=3 ;;
    *) echo "Unknown subscription tier: $tier" >&2; exit 1 ;;
  esac
  echo "Syncing $product_id"
  retry asc subscriptions update \
    --id "$subscription_id" \
    --group-level "$group_level" \
    --output json >/dev/null

  existing=$(
    retry asc subscriptions localizations list \
      --subscription-id "$subscription_id" \
      --output json
  )
  while IFS=$'\t' read -r locale name description; do
    if jq -e --arg locale "$locale" \
      '(.data // [])[] | select(.attributes.locale==$locale)' \
      >/dev/null <<<"$existing"; then
      continue
    fi
    retry asc subscriptions localizations create \
      --subscription-id "$subscription_id" \
      --locale "$locale" \
      --name "$name" \
      --description "$description" \
      --output json >/dev/null
  done < <(
    jq -r --arg id "$product_id" \
      '.products[] | select(.productId==$id) |
       .localizations[] |
       [.appleLocale,.displayName,.description] | @tsv' \
      "$MANIFEST"
  )

  if [[ -z "$subscription_review_token" ]]; then
    subscription_review_token=$(asc auth token --confirm)
  fi
  subscription_review=$(
    retry curl -fsS \
      -H "Authorization: Bearer $subscription_review_token" \
      "https://api.appstoreconnect.apple.com/v1/subscriptions/$subscription_id/appStoreReviewScreenshot"
  )
  subscription_screenshot_id=$(
    jq -r '.data.id // empty' <<<"$subscription_review"
  )
  subscription_screenshot_md5=$(
    jq -r '.data.attributes.sourceFileChecksum // empty' \
      <<<"$subscription_review"
  )
  if [[ -z "$subscription_screenshot_id" ]]; then
    retry asc subscriptions review screenshots create \
      --subscription-id "$subscription_id" \
      --file "$REVIEW_SCREENSHOT" \
      --output json >/dev/null
  elif [[ "${ASC_REFRESH_REVIEW_SCREENSHOTS:-0}" == "1" &&
          "$subscription_screenshot_md5" != "$review_screenshot_md5" ]]; then
    retry asc subscriptions review screenshots delete \
      --screenshot-id "$subscription_screenshot_id" \
      --confirm \
      --output json >/dev/null
    retry asc subscriptions review screenshots create \
      --subscription-id "$subscription_id" \
      --file "$REVIEW_SCREENSHOT" \
      --output json >/dev/null
  fi
done < <(
  jq -r --slurpfile pricing "$PRICING" \
    '.products[] |
     select(.storeType=="autoRenewableSubscription") |
     [.id,.billingPeriod,.tier,$pricing[0].products[.id].usdPrice] | @tsv' \
    "$CATALOG"
)
fi

echo "Apple commerce metadata sync complete."
asc iap list --app "$APP_ID" --limit 200 --output table
if [[ "${ASC_SKIP_SUBSCRIPTIONS:-0}" != "1" ]]; then
  asc subscriptions list --group-id "$group_id" --paginate --output table
fi
