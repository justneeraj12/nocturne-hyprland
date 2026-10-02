#!/usr/bin/env bash
set -euo pipefail

url=https://github.com/gfhdhytghd/HyprCapture
revision=bb9ab938152968f53355b83026464fe3427926a1
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

running=$(hyprctl version 2>/dev/null | head -n1 || true)
if ! grep -Eq 'v?0\.(5[6-9]|[6-9][0-9])\.' <<<"$running"; then
  printf 'HyprCapture needs a running Hyprland 0.56+ session. Reboot or log in again after the compositor upgrade, then rerun this installer.\n' >&2
  exit 1
fi

# hyprpm installs ABI-matched headers in its root-owned cache. Prime sudo with
# a normal graphical password dialog so this installer never appears to hang in
# an invisible terminal prompt when launched from Settings or the app launcher.
if command -v zenity >/dev/null 2>&1 && [[ -n ${WAYLAND_DISPLAY:-}${DISPLAY:-} ]]; then
  export SUDO_ASKPASS="$script_dir/nocturne-askpass"
  export SUDO_ASKPASS_REQUIRE=force
  sudo -A -v
else
  sudo -v
fi

# Force-refresh also covers distro rebuilds whose Hyprland version is unchanged
# while its plugin ABI has moved.
hyprpm update -f
if ! hyprpm list 2>/dev/null | grep -qi 'HyprCapture'; then
  printf 'y\n' | hyprpm add "$url" "$revision"
fi
hyprpm enable hyprcapture
hyprpm reload

if ! hyprctl plugin list 2>/dev/null | grep -qi 'HyprCapture'; then
  printf 'HyprCapture built but did not load. Check hyprpm list and the Hyprland log.\n' >&2
  exit 1
fi

printf 'HyprCapture %s is enabled for this compositor ABI.\n' "$revision"
