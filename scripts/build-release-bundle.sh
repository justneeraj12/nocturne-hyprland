#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
version=${1:-$(git -C "$root" describe --tags --exact-match 2>/dev/null || git -C "$root" rev-parse --short HEAD)}
version=${version#v}
[[ $version =~ ^[0-9A-Za-z][0-9A-Za-z.-]*$ ]] || { printf 'Invalid release version: %s\n' "$version" >&2; exit 2; }
output=${NOCTURNE_DIST_DIR:-"$root/dist"}
archive="$output/nocturne-$version-source.tar.gz"
temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT
release_paths=(
  .github agent assets bin branding config docs native scripts
  CHANGELOG.md CONTRIBUTING.md LICENSE PRIVACY.md README.md ROADMAP.md SECURITY.md
  apply-hyprland.sh apply-vscode-theme.sh cleanup-generated-caches.sh
  configure-deep-sleep.sh configure-msi-controls.sh install.sh
  restore-gnome-backup.sh restore-gnome-macos.sh sync-github.sh uninstall.sh
)

mkdir -p -- "$output"
tar -C "$root" --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
  --exclude='.git' --exclude='build' --exclude='dist' --exclude='.cache' \
  --exclude='.local-state' --exclude='backups' --exclude='agent/.venv' \
  --exclude='agent/models' --exclude='agent-runtime' --exclude='agent-models' \
  --exclude='*.sqlite3' --exclude='*.gguf' --exclude='*.log' \
  --transform="s,^,nocturne-$version/," -cf "$temporary/source.tar" "${release_paths[@]}"
gzip -n -9 < "$temporary/source.tar" > "$archive"
(
  cd "$output"
  sha256sum "$(basename -- "$archive")" > "$(basename -- "$archive").sha256"
)
printf '%s\n' "$archive"
