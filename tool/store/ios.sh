#!/usr/bin/env bash
# App Store uploads via asc (https://github.com/rorkai/App-Store-Connect-CLI).
# Text lives in docs/store/app-store/metadata/ (fastlane layout, see docs/store/README.md).
#
#   tool/store/ios.sh metadata [--dry-run]   text, review notes and copyright of the editable version
#   tool/store/ios.sh promo    [--dry-run]   promotional text of the editable version, else the live one
set -euo pipefail

APP_ID=6759974325
TESTED_ASC_MAJOR=5
LOCALES=(en-US de-DE)

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STORE_DIR="$ROOT/docs/store/app-store"
METADATA_DIR="$STORE_DIR/metadata"

# App Store Connect versions whose text can still be edited.
EDITABLE_STATES='["PREPARE_FOR_SUBMISSION","DEVELOPER_REJECTED","REJECTED","METADATA_REJECTED","INVALID_BINARY"]'

die() { echo "error: $*" >&2; exit 1; }

usage() {
  sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'
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

cmd_metadata() {
  find_versions
  if [[ -z "$EDITABLE_ID" ]]; then
    [[ "$NEWEST_STATE" == READY_FOR_DISTRIBUTION ]] ||
      die "version $NEWEST_VERSION is already submitted ($NEWEST_STATE); nothing editable"
    die "no editable App Store version; run 'ios.sh release' first"
  fi
  echo "Version $EDITABLE_VERSION ($EDITABLE_ID)"

  local import=(asc migrate import --app "$APP_ID" --version-id "$EDITABLE_ID"
    --fastlane-dir "$STORE_DIR" --skip-screenshots --skip-previews)
  if [[ "$DRY_RUN" == true ]]; then
    "${import[@]}" --dry-run --check-remote --output table
  else
    "${import[@]}" --confirm
  fi
  run asc versions update --version-id "$EDITABLE_ID" --copyright "$(field "$METADATA_DIR/copyright.txt")"
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
  metadata) cmd_metadata ;;
  promo) cmd_promo ;;
  -h | --help) usage 0 ;;
  *) usage ;;
esac
