#!/usr/bin/env bash
set -euo pipefail

source_url=https://github.com/gfhdhytghd/HyprCapture
source_revision=bb9ab938152968f53355b83026464fe3427926a1
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
project_dir=$(cd -- "$script_dir/.." && pwd)
plugin_dir=$HOME/.local/lib/nocturne-hyprcapture
plugin_path=$plugin_dir/libhyprcapture.so

running=$(hyprctl version 2>/dev/null | head -n1 || true)
if ! grep -Eq 'v?0\.(5[6-9]|[6-9][0-9])\.' <<<"$running"; then
  printf 'HyprCapture needs a running Hyprland 0.56+ session. Log into the upgraded compositor, then rerun this installer.\n' >&2
  exit 1
fi

if ! command -v pkg-config >/dev/null 2>&1 || ! pkg-config --exists hyprland; then
  printf 'The exact Hyprland development headers are unavailable. Reinstall the current Hyprland package, then retry.\n' >&2
  exit 1
fi

header_version=$(pkg-config --modversion hyprland)
running_version=$(sed -nE 's/.*v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' <<<"$running" | head -n1)
if [[ -n $running_version && $header_version != "$running_version" ]]; then
  printf 'Running Hyprland %s does not match installed headers %s. Log out and back in before building.\n' "$running_version" "$header_version" >&2
  exit 1
fi

build_packages=(
  build-essential cmake git patch pkg-config nlohmann-json3-dev
  qt6-base-dev qt6-base-dev-tools qt6-svg-dev
  layer-shell-qt liblayershellqtinterface-dev
  libpipewire-0.3-dev libspa-0.2-dev libfftw3-dev libpulse-dev
  libavformat-dev libavcodec-dev libavutil-dev libswresample-dev libglib2.0-dev
  libaquamarine-dev libhyprcursor-dev libhyprgraphics-dev libhyprlang-dev
  libhyprutils-dev liblua5.4-dev libxcb-composite0-dev libxcb-errors-dev
  libxcb-icccm4-dev libxcb-shape0-dev libxcb-xfixes0-dev glslang-dev
  spirv-tools-dev
)
missing_packages=()
for package_name in "${build_packages[@]}"; do
  dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null | grep -q 'ok installed' \
    || missing_packages+=("$package_name")
done
if ((${#missing_packages[@]})); then
  printf 'Installing the missing HyprCapture build dependencies through the graphical administrator prompt.\n'
  pkexec env DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing_packages[@]}"
fi

for command_name in cmake git patch c++ ctest; do
  command -v "$command_name" >/dev/null 2>&1 || {
    printf 'Missing build command after dependency install: %s\n' "$command_name" >&2
    exit 1
  }
done

work_dir=$(mktemp -d)
cleanup() { rm -rf -- "$work_dir"; }
trap cleanup EXIT

git clone --filter=blob:none --no-checkout "$source_url" "$work_dir/source"
git -C "$work_dir/source" checkout --detach "$source_revision"
patch -d "$work_dir/source" -p1 --forward < "$project_dir/patches/hyprcapture-supervisor.patch"

cmake -S "$work_dir/source" -B "$work_dir/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
  -DCMAKE_INSTALL_LIBDIR=lib/nocturne-hyprcapture \
  -DCMAKE_INSTALL_RPATH="$plugin_dir"
cmake --build "$work_dir/build" --parallel "$(nproc)"
QT_QPA_PLATFORM=offscreen ctest --test-dir "$work_dir/build" --output-on-failure

if hyprctl plugin list 2>/dev/null | grep -qi 'Plugin HyprCapture'; then
  hyprctl plugin unload "$plugin_path"
fi
cmake --install "$work_dir/build"
hyprctl plugin load "$plugin_path"

if ! hyprctl plugin list 2>/dev/null | grep -qi 'HyprCapture'; then
  printf 'HyprCapture installed but did not load. Check the Hyprland log before restarting the session.\n' >&2
  exit 1
fi

printf 'HyprCapture %s is installed, tested, and loaded for Hyprland %s.\n' "$source_revision" "$header_version"
