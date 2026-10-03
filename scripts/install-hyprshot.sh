#!/usr/bin/env bash
set -euo pipefail

readonly version=1.3.0
readonly checksum=6f7c7633b6f611eee03626c17d3d5863ae0cf2ee2da581a2dc166fd23e47dd49
readonly source_url="https://raw.githubusercontent.com/Gustash/Hyprshot/${version}/hyprshot"
readonly destination="${1:-$HOME/.local/bin/hyprshot}"

temporary=$(mktemp)
trap 'rm -f -- "$temporary"' EXIT

curl --fail --location --silent --show-error "$source_url" --output "$temporary"
printf '%s  %s\n' "$checksum" "$temporary" | sha256sum --check --status
install -Dm0755 "$temporary" "$destination"
printf 'Installed Hyprshot %s at %s\n' "$version" "$destination"
