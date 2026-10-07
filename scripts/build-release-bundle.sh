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

mkdir -p -- "$output"
git -C "$root" archive --format=tar --prefix="nocturne-$version/" HEAD > "$temporary/source.tar"
gzip -n -9 < "$temporary/source.tar" > "$archive"
(
  cd "$output"
  sha256sum "$(basename -- "$archive")" > "$(basename -- "$archive").sha256"
)
printf '%s\n' "$archive"
