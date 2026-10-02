#!/usr/bin/env bash
set -euo pipefail

commit=eb772615558b61cda81861a3fbac49f7e37dc1f8
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT

for command_name in git cargo pkg-config; do
  command -v "$command_name" >/dev/null 2>&1 || {
    printf 'Missing build command: %s\n' "$command_name" >&2
    exit 1
  }
done
pkg-config --exists gtk4 gtk4-layer-shell-0 || {
  printf 'Missing GTK build headers: install libgtk-4-dev and libgtk4-layer-shell-dev.\n' >&2
  exit 1
}

git clone --filter=blob:none https://github.com/LifeOfATitan/orbit.git "$tmp/orbit"
git -C "$tmp/orbit" checkout "$commit"
git -C "$tmp/orbit" apply "$root/patches/orbit-nocturne.patch"
cargo build --release --locked --manifest-path "$tmp/orbit/Cargo.toml"
install -Dm0755 "$tmp/orbit/target/release/orbit" "$HOME/.local/bin/orbit"
printf 'Installed Nocturne Orbit 2.4.13 from pinned upstream commit %s.\n' "$commit"

