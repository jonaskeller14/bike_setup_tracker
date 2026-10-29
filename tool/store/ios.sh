#!/usr/bin/env bash
# App Store uploads via asc (https://github.com/rorkai/App-Store-Connect-CLI).
# Text lives in docs/store/app-store/metadata/ (fastlane layout, see docs/store/README.md).
#
#   tool/store/ios.sh release     [--dry-run]   IPA + version + build + text + What's New (submit stays manual)
#   tool/store/ios.sh metadata    [--dry-run]   text, review notes and copyright of the editable version
#   tool/store/ios.sh promo       [--dry-run]   promotional text of the editable version, else the live one
#   tool/store/ios.sh screenshots [--dry-run]   screenshots and app previews of the editable version
#   tool/store/ios.sh creatives   [--dry-run]   header and search-results images of the editable version
#   tool/store/ios.sh page-metadata    [--dry-run]   name, promotional text and keywords of every custom product page
#   tool/store/ios.sh page-screenshots [--dry-run]   screenshots and app previews of every custom product page
set -euo pipefail

APP_ID=6759974325
TESTED_ASC_MAJOR=5
LOCALES=(en-US de-DE)

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STORE_DIR="$ROOT/docs/store/app-store"
METADATA_DIR="$STORE_DIR/metadata"
CREATIVE_DIR="$STORE_DIR/creative"
PAGES_DIR="$STORE_DIR/custom-product-pages"
CHANGELOG_DIR="$ROOT/docs/store/play-store/metadata"

# App Store Connect versions whose text can still be edited.
EDITABLE_STATES='["PREPARE_FOR_SUBMISSION","DEVELOPER_REJECTED","REJECTED","METADATA_REJECTED","INVALID_BINARY"]'
PAGE_EDITABLE_STATES='["PREPARE_FOR_SUBMISSION","READY_FOR_REVIEW","REJECTED"]'
API=https://api.appstoreconnect.apple.com/v1

die() { echo "error: $*" >&2; exit 1; }

usage() {
  sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-1}"
}

check_asc() {
  command -v asc >/dev/null || die "asc not found (brew install asc)"
  command -v jq >/dev/null || die "jq not found"
  local version major
  version="$(asc version | awk '{print $1}')"
  major="${version%%.*}"
  [[ "$major" == "$TESTED_ASC_MAJOR" ]] ||
    die "asc $version installed, but this script is tested with asc $TESTED_ASC_MAJOR.x"
}

# Sets EDITABLE_ID / EDITABLE_VERSION / LIVE_ID / LIVE_VERSION (empty when absent) and
# NEWEST_STATE / NEWEST_VERSION.
find_versions() {
  local versions
  versions="$(asc versions list --app "$APP_ID" --platform IOS --limit 50)"
  NEWEST_STATE="$(jq -r '.data[0].attributes.appVersionState' <<<"$versions")"
  NEWEST_VERSION="$(jq -r '.data[0].attributes.versionString' <<<"$versions")"

  EDITABLE_ID="$(jq -r --argjson s "$EDITABLE_STATES" \
    '[.data[] | select(.attributes.appVersionState | IN($s[]))][0].id // empty' <<<"$versions")"
  EDITABLE_VERSION="$(jq -r --argjson s "$EDITABLE_STATES" \
    '[.data[] | select(.attributes.appVersionState | IN($s[]))][0].attributes.versionString // empty' <<<"$versions")"
  LIVE_ID="$(jq -r '[.data[] | select(.attributes.appVersionState == "READY_FOR_DISTRIBUTION")][0].id // empty' <<<"$versions")"
  LIVE_VERSION="$(jq -r '[.data[] | select(.attributes.appVersionState == "READY_FOR_DISTRIBUTION")][0].attributes.versionString // empty' <<<"$versions")"
}

# Reads a text file without its trailing newline.
field() { printf '%s' "$(<"$1")"; }

run() {
  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

require_editable() {
  find_versions
  if [[ -z "$EDITABLE_ID" ]]; then
    [[ "$NEWEST_STATE" == READY_FOR_DISTRIBUTION ]] ||
      die "version $NEWEST_VERSION is already submitted ($NEWEST_STATE); nothing editable"
    die "no editable App Store version; run 'ios.sh release' first"
  fi
  echo "Version $EDITABLE_VERSION ($EDITABLE_ID)"
}

# Text, review notes and copyright of the editable version.
apply_metadata() {
  local import=(asc migrate import --app "$APP_ID" --version-id "$EDITABLE_ID"
    --fastlane-dir "$STORE_DIR" --skip-screenshots --skip-previews)
  if [[ "$DRY_RUN" == true ]]; then
    "${import[@]}" --dry-run --check-remote --output table
  else
    "${import[@]}" --confirm
  fi
  run asc versions update --version-id "$EDITABLE_ID" --copyright "$(field "$METADATA_DIR/copyright.txt")"
}

cmd_metadata() {
  require_editable
  apply_metadata
}

pubspec_version() {
  local line
  line="$(sed -n 's/^version: *\([0-9][0-9.]*+[0-9][0-9]*\)\( .*\)\{0,1\}$/\1/p' "$ROOT/pubspec.yaml")"
  [[ -n "$line" ]] || die "no version: X.Y.Z+B in pubspec.yaml"
  echo "$line"
}

cmd_release() {
  local pubspec version build ipas ipa ipa_version locale changelog
  pubspec="$(pubspec_version)"
  version="${pubspec%%+*}"
  build="${pubspec##*+}"

  shopt -s nullglob
  ipas=("$ROOT"/build/ios/ipa/*.ipa)
  shopt -u nullglob
  [[ ${#ipas[@]} -eq 1 ]] || die "expected exactly one IPA in build/ios/ipa (run 'flutter build ipa --release')"
  ipa="${ipas[0]}"
  ipa_version="$(unzip -p "$ipa" 'Payload/*.app/Info.plist' | plutil -extract CFBundleShortVersionString raw -o - -)"
  [[ "$ipa_version" == "$version" ]] ||
    die "IPA is version $ipa_version, pubspec.yaml says $version (stale build folder?)"

  for locale in "${LOCALES[@]}"; do
    changelog="$CHANGELOG_DIR/$locale/changelogs/$build.txt"
    [[ -f "$changelog" ]] || die "missing release notes: ${changelog#"$ROOT"/}"
  done

  find_versions
  if [[ -n "$EDITABLE_ID" && "$EDITABLE_VERSION" != "$version" ]]; then
    die "editable App Store version is $EDITABLE_VERSION, not $version; remove or rename it first"
  fi
  if [[ -z "$EDITABLE_ID" && "$NEWEST_STATE" != READY_FOR_DISTRIBUTION ]]; then
    die "version $NEWEST_VERSION is already submitted ($NEWEST_STATE)"
  fi
  [[ "$LIVE_VERSION" != "$version" ]] || die "version $version is already live"

  local publish=(asc publish appstore --app "$APP_ID" --ipa "$ipa" --version "$version" --wait)
  [[ "$DRY_RUN" == true ]] && publish+=(--dry-run)
  "${publish[@]}"

  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] metadata, What's New and copyright follow once the version exists"
    return
  fi

  find_versions
  [[ "$EDITABLE_VERSION" == "$version" ]] || die "App Store version $version not found after publishing"
  apply_metadata
  for locale in "${LOCALES[@]}"; do
    asc apps info edit --app "$APP_ID" --version "$version" --platform IOS --locale "$locale" \
      --whats-new "$(field "$CHANGELOG_DIR/$locale/changelogs/$build.txt")" >/dev/null
    echo "  $locale: What's New updated"
  done
  echo "Next: submit version $version for review in App Store Connect."
}

cmd_screenshots() {
  require_editable

  local display_type confirm=(--confirm)
  [[ "$DRY_RUN" == true ]] && confirm=(--dry-run)
  # Screenshots sit side by side; asc picks the files that fit the display type.
  for display_type in IPHONE_61 IPAD_PRO_3GEN_129; do
    echo "Screenshots $display_type"
    asc screenshots upload --app "$APP_ID" --version-id "$EDITABLE_ID" --path "$STORE_DIR/screenshots" \
      --device-type "$display_type" --replace "${confirm[@]}" >/dev/null
  done

  local locale device_dir localization_id preview_type
  for locale in "${LOCALES[@]}"; do
    for device_dir in "$STORE_DIR/app_previews/$locale"/*/; do
      [[ -d "$device_dir" ]] || continue
      case "$(basename "$device_dir")" in
        iphone_61) preview_type=IPHONE_61 ;;
        *) die "unknown app preview folder: ${device_dir#"$ROOT"/}" ;;
      esac
      localization_id="$(asc localizations list --version "$EDITABLE_ID" --locale "$locale" | jq -r '.data[0].id')"
      echo "App previews $locale $preview_type"
      asc video-previews upload --version-localization "$localization_id" --path "$device_dir" \
        --device-type "$preview_type" --replace "${confirm[@]}" >/dev/null
    done
  done
}

# Replaces the header and search-results placements of the editable version with the PNGs in
# creative/. The new image is uploaded first, so a failed upload leaves the old placement alone.
cmd_creatives() {
  require_editable

  local locale localization_id slot placement_type file image_id placement_ids
  for locale in "${LOCALES[@]}"; do
    localization_id="$(asc localizations list --version "$EDITABLE_ID" --locale "$locale" | jq -r '.data[0].id')"
    for slot in header:PRODUCT_PAGE_HEADER_ASSET search:APP_STORE_SEARCH_RESULTS_ASSET; do
      placement_type="${slot#*:}"
      file="$CREATIVE_DIR/${slot%%:*}_$locale.png"
      [[ -f "$file" ]] || die "missing creative: ${file#"$ROOT"/}"
      echo "Creative ${file#"$CREATIVE_DIR"/}"
      if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] upload ${file#"$ROOT"/} and replace $placement_type ($locale)"
        continue
      fi

      asc asset-library images upload --library-id "$APP_ID" --file "$file" >/dev/null
      # The upload receipt carries no stable id field, so take the newest library image of that name.
      image_id="$(asc asset-library images list --library-id "$APP_ID" --paginate |
        jq -r --arg f "$(basename "$file")" \
          '[.data[] | select(.attributes.fileName == $f)] | max_by(.attributes.createdDate) | .id // empty')"
      [[ -n "$image_id" ]] || die "uploaded image not found in the library: ${file#"$ROOT"/}"

      placement_ids="$(asc localizations placements list --localization-id "$localization_id" \
        --placement-type "$placement_type" --paginate | jq -r '[.data[].id] | join(",")')"
      if [[ -n "$placement_ids" ]]; then
        asc localizations placements delete --placement-ids "$placement_ids" --confirm >/dev/null
      fi
      asc localizations placements create --localization-id "$localization_id" \
        --image-id "$image_id" --placement-type "$placement_type" --placement-group DEFAULT_PROFILE >/dev/null
    done
  done
}

# Prints the media ids in one set of a custom product page localization. asc has no command for
# a set's contents, but its list commands follow any API link passed as --next.
page_set_media() {
  local kind="$1" localization_id="$2" set_id="$3"
  case "$kind" in
    screenshot) asc product-pages custom-pages localizations screenshot-sets list \
      --localization-id "$localization_id" --next "$API/appScreenshotSets/$set_id/appScreenshots" ;;
    preview) asc product-pages custom-pages localizations preview-sets list \
      --localization-id "$localization_id" --next "$API/appPreviewSets/$set_id/appPreviews" ;;
  esac | jq -r '.data[].id'
}

# Sets PAGE_NAME / PAGE_ID / PAGE_VERSION_ID and PAGE_LOCALIZATIONS (the asc JSON of the version's
# localizations) for the custom product page in folder $1.
find_page_version() {
  PAGE_NAME="$(basename "$1")"
  PAGE_ID="$(sed -n 's/^url: .*ppid=\([0-9a-f-]*\).*$/\1/p' "$1/page.txt")"
  [[ -n "$PAGE_ID" ]] || die "no ppid in the url of ${1#"$ROOT"/}page.txt"
  PAGE_VERSION_ID="$(asc product-pages custom-pages versions list --custom-page-id "$PAGE_ID" --paginate |
    jq -r --argjson s "$PAGE_EDITABLE_STATES" '[.data[] | select(.attributes.state | IN($s[]))][0].id // empty')"
  [[ -n "$PAGE_VERSION_ID" ]] ||
    die "$PAGE_NAME: no editable page version (a submitted one is locked); create one in App Store Connect"
  PAGE_LOCALIZATIONS="$(asc product-pages custom-pages localizations list --custom-page-version-id "$PAGE_VERSION_ID")"
  echo "Page $PAGE_NAME ($PAGE_VERSION_ID)"
}

page_localization_id() {
  jq -r --arg l "$1" '.data[] | select(.attributes.locale == $l) | .id' <<<"$PAGE_LOCALIZATIONS"
}

# Name, promotional text and keywords of each page's editable version, from page.txt and
# <page>/<locale>/*.txt. Only what differs is sent.
cmd_page_metadata() {
  local page_dir name locale localization_id text live wanted added removed
  for page_dir in "$PAGES_DIR"/*/; do
    [[ -f "$page_dir/page.txt" ]] || continue
    find_page_version "$page_dir"
    name="$(sed -n 's/^reference_name: //p' "$page_dir/page.txt")"
    if [[ "$(asc product-pages custom-pages view --custom-page-id "$PAGE_ID" | jq -r '.data.attributes.name')" != "$name" ]]; then
      echo "  name $name"
      run asc product-pages custom-pages update --custom-page-id "$PAGE_ID" --name "$name" >/dev/null
    fi

    for locale in "${LOCALES[@]}"; do
      localization_id="$(page_localization_id "$locale")"
      [[ -n "$localization_id" ]] || die "$PAGE_NAME: no $locale localization"

      text="$(field "$page_dir/$locale/promotional_text.txt")"
      if ! jq -e --arg l "$locale" --arg t "$text" \
        'any(.data[]; .attributes.locale == $l and .attributes.promotionalText == $t)' <<<"$PAGE_LOCALIZATIONS" >/dev/null; then
        echo "  $locale: promotional text"
        run asc product-pages custom-pages localizations update --localization-id "$localization_id" \
          --promotional-text "$text" >/dev/null
      fi

      live="$(asc product-pages custom-pages localizations search-keywords list --localization-id "$localization_id" |
        jq -r '.data[].id' | sort)"
      wanted="$(tr ',' '\n' <"$page_dir/$locale/keywords.txt" | sed '/^$/d' | sort)"
      added="$(comm -13 <(echo "$live") <(echo "$wanted") | sed '/^$/d' | paste -sd, -)"
      removed="$(comm -23 <(echo "$live") <(echo "$wanted") | sed '/^$/d' | paste -sd, -)"
      if [[ -n "$removed" ]]; then
        echo "  $locale: remove keywords $removed"
        run asc product-pages custom-pages localizations search-keywords delete --localization-id "$localization_id" \
          --keywords "$removed" --confirm >/dev/null
      fi
      if [[ -n "$added" ]]; then
        echo "  $locale: add keywords $added"
        run asc product-pages custom-pages localizations search-keywords add --localization-id "$localization_id" \
          --keywords "$added" >/dev/null
      fi
    done
  done
}

# Replaces the en-US screenshots and app previews of each page's editable version with the copies
# custom_page_media.py builds, and empties every other set (the 6.5″ slots, or previews the page
# order dropped). The other localizations show the en-US media until the screens are translated.
cmd_page_screenshots() {
  python3 "$ROOT/tool/store/custom_page_media.py" --check >/dev/null ||
    die "page media out of date, run 'python3 tool/store/custom_page_media.py'"

  local page_dir name localization_id media_dir staging kind slot device keep
  local set_type set_id media_id sets
  staging="$(mktemp -d)"
  trap "rm -rf '$staging'" EXIT
  for page_dir in "$PAGES_DIR"/*/; do
    [[ -f "$page_dir/page.txt" ]] || continue
    find_page_version "$page_dir"
    name="$PAGE_NAME"
    localization_id="$(page_localization_id en-US)"
    [[ -n "$localization_id" ]] || die "$name: no en-US localization"
    media_dir="$page_dir/en-US"

    # Set types the repo fills; every other set is emptied below.
    keep=()
    for slot in IPHONE_61:iphone IPAD_PRO_3GEN_129:ipad; do
      device="${slot#*:}"
      # The sync takes one folder per device, but the page keeps iPhone and iPad side by side.
      mkdir -p "$staging/$name/$device"
      cp "$media_dir/screenshots/${device}"_*.png "$staging/$name/$device/"
      keep+=("APP_${slot%%:*}")
      echo "  screenshots ${slot%%:*}"
      run asc product-pages custom-pages localizations screenshot-sets sync --localization-id "$localization_id" \
        --path "$staging/$name/$device" --device-type "${slot%%:*}" --confirm >/dev/null
    done
    if [[ -d "$media_dir/app_previews/iphone_61" ]]; then
      keep+=(IPHONE_61)
      echo "  app previews IPHONE_61"
      run asc product-pages custom-pages localizations preview-sets sync --localization-id "$localization_id" \
        --path "$media_dir/app_previews/iphone_61" --device-type IPHONE_61 --confirm >/dev/null
    fi

    for kind in screenshot preview; do
      if [[ "$kind" == screenshot ]]; then
        sets="$(asc product-pages custom-pages localizations screenshot-sets list --localization-id "$localization_id" |
          jq -r '.data[] | "\(.attributes.screenshotDisplayType) \(.id)"')"
      else
        sets="$(asc product-pages custom-pages localizations preview-sets list --localization-id "$localization_id" |
          jq -r '.data[] | "\(.attributes.previewType) \(.id)"')"
      fi
      while read -r set_type set_id; do
        [[ -n "$set_id" && " ${keep[*]} " != *" $set_type "* ]] || continue
        for media_id in $(page_set_media "$kind" "$localization_id" "$set_id"); do
          echo "  delete $kind $media_id from $set_type"
          if [[ "$kind" == screenshot ]]; then
            run asc screenshots delete --id "$media_id" --confirm >/dev/null
          else
            run asc video-previews delete --id "$media_id" --confirm >/dev/null
          fi
        done
      done <<<"$sets"
    done
  done
}

cmd_promo() {
  find_versions
  local version="$EDITABLE_VERSION"
  [[ -n "$version" ]] || version="$LIVE_VERSION"
  [[ -n "$version" ]] || die "no App Store version found"
  echo "Version $version"

  local locale flags=()
  [[ "$DRY_RUN" == true ]] && flags+=(--dry-run)
  for locale in "${LOCALES[@]}"; do
    asc apps info edit --app "$APP_ID" --version "$version" --platform IOS --locale "$locale" \
      --promotional-text "$(field "$METADATA_DIR/$locale/promotional_text.txt")" \
      ${flags[@]+"${flags[@]}"} >/dev/null
    echo "  $locale: promotional text $([[ "$DRY_RUN" == true ]] && echo planned || echo updated)"
  done
}

[[ $# -ge 1 ]] || usage
COMMAND="$1"
shift
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h | --help) usage 0 ;;
    *) die "unknown option: $arg" ;;
  esac
done

check_asc
case "$COMMAND" in
  release) cmd_release ;;
  metadata) cmd_metadata ;;
  screenshots) cmd_screenshots ;;
  creatives) cmd_creatives ;;
  page-metadata) cmd_page_metadata ;;
  page-screenshots) cmd_page_screenshots ;;
  promo) cmd_promo ;;
  -h | --help) usage 0 ;;
  *) usage ;;
esac
