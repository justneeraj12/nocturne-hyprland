#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
build_dir=${NOCTURNE_BUILD_DIR:-"$root/build/native"}
destination=${NOCTURNE_BIN_DIR:-"$HOME/.local/bin"}

for program in cmake ninja; do
  command -v "$program" >/dev/null 2>&1 || {
    printf 'Missing build dependency: %s\n' "$program" >&2
    exit 1
  }
done

cmake -S "$root/native" -B "$build_dir" -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build "$build_dir" --parallel
mkdir -p "$destination"
install -m 0755 "$build_dir/nocturne-native" "$destination/nocturne-native"
printf 'Installed native shell: %s/nocturne-native\n' "$destination"
