#!/usr/bin/env bash
set -euo pipefail

SHELL_VERSION=$(gnome-shell --version | sed -E 's/.* ([0-9]+).*/\1/')
[[ "$SHELL_VERSION" == 50 ]] || {
  printf 'This curated extension set targets GNOME 50; found GNOME %s.\n' "$SHELL_VERSION" >&2
  exit 1
}

TEMP_DIR=$(mktemp -d /tmp/nocturne-extensions.XXXXXX)
trap 'rm -rf -- "$TEMP_DIR"' EXIT

# Official extensions.gnome.org identifiers. Every entry has an active GNOME 50 build.
EXTENSION_IDS=(
  7065  # Tiling Shell
  9157  # Pomodoro Timer
  4655  # Date Menu Formatter
  4839  # Clipboard History
  10076 # Medialine
  8106  # Top Panel Notification Icons with Count
  8261  # SimpleWeather (multiple locations)
)

for extension_id in "${EXTENSION_IDS[@]}"; do
  info_url="https://extensions.gnome.org/extension-info/?pk=${extension_id}&shell_version=${SHELL_VERSION}"
  info=$(curl --fail --silent --show-error --location "$info_url")
  uuid=$(jq -r '.uuid // empty' <<<"$info")
  download_url=$(jq -r '.download_url // empty' <<<"$info")
  [[ -n "$uuid" && -n "$download_url" ]] || {
    printf 'No compatible GNOME %s package for extension id %s\n' "$SHELL_VERSION" "$extension_id" >&2
    exit 1
  }

  archive="$TEMP_DIR/${uuid}.zip"
  printf 'Installing %s\n' "$uuid"
  curl --fail --silent --show-error --location \
    "https://extensions.gnome.org${download_url}" --output "$archive"
  gnome-extensions install --force "$archive"
done

printf '\nInstalled the curated GNOME extension set. Log out/in before enabling newly loaded extensions.\n'

