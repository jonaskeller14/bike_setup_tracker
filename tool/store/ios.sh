#!/usr/bin/env bash
# App Store uploads via asc (https://github.com/rorkai/App-Store-Connect-CLI).
# Text lives in docs/store/app-store/metadata/ (fastlane layout, see docs/store/README.md).
#
#   tool/store/ios.sh release     [--dry-run]   IPA + version + build + text + What's New (submit stays manual)
#   tool/store/ios.sh metadata    [--dry-run]   text, review notes and copyright of the editable version
#   tool/store/ios.sh promo       [--dry-run]   promotional text of the editable version, else the live one
#   tool/store/ios.sh screenshots [--dry-run]   screenshots and app previews of the editable version
#   tool/store/ios.sh creatives   [--dry-run]   header and search-results images of the editable version
set -euo pipefail

APP_ID=6759974325
TESTED_ASC_MAJOR=5
LOCALES=(en-US de-DE)

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STORE_DIR="$ROOT/docs/store/app-store"
METADATA_DIR="$STORE_DIR/metadata"
CREATIVE_DIR="$STORE_DIR/creative"
CHANGELOG_DIR="$ROOT/docs/store/play-store/metadata"

# App Store Connect versions whose text can still be edited.
EDITABLE_STATES='["PREPARE_FOR_SUBMISSION","DEVELOPER_REJECTED","REJECTED","METADATA_REJECTED","INVALID_BINARY"]'

die() { echo "error: $*" >&2; exit 1; }

usage() {
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
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
        iphone_65) preview_type=IPHONE_65 ;;
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
  promo) cmd_promo ;;
  -h | --help) usage 0 ;;
  *) usage ;;
esac
