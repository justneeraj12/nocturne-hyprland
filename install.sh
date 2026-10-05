#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install_packages=false
dry_run=false

usage() {
  printf '%s\n' \
    'Usage: ./install.sh [--install-packages] [--dry-run]' \
    '' \
    'Apply Nocturne to an existing Hyprland 0.56+ installation.' \
    '' \
    '  --install-packages  Install Ubuntu build/runtime dependencies with apt.' \
    '  --dry-run           Validate without changing the live configuration.'
}

for argument in "$@"; do
  case $argument in
    --install-packages) install_packages=true ;;
    --dry-run) dry_run=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$argument" >&2; usage >&2; exit 2 ;;
  esac
done

if "$dry_run" && "$install_packages"; then
  printf '%s\n' '--dry-run and --install-packages cannot be combined.' >&2
  exit 2
fi

if "$dry_run"; then
  "$root/scripts/validate-nocturne.sh"
  printf 'Dry run complete; no packages or live configuration were changed.\n'
  exit 0
fi

if "$install_packages"; then
  sudo apt-get update
  sudo apt-get install -y \
    build-essential cmake ninja-build qt6-base-dev qt6-declarative-dev \
    qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts \
    qml6-module-qtquick-window qml6-module-org-kde-layershell \
    layer-shell-qt liblayershellqtinterface-dev mako-notifier xdg-desktop-portal-kde \
    curl flatpak grim slurp wl-clipboard cliphist libnotify-bin brightnessctl pipewire-bin pulseaudio-utils xdg-utils \
    network-manager bluez jq socat kitty btop cava fastfetch playerctl gamemode pcmanfm-qt lxqt-archiver ffmpegthumbnailer qt6-image-formats-plugins kimageformat6-plugins qpdfview qalculate-qt \
    power-profiles-daemon fwupd hyprsunset pciutils mesa-utils imagemagick upower mangohud fonts-inter fonts-jetbrains-mono
  sudo install -m 0644 "$root/assets/nocturne-recovery.desktop" /usr/share/wayland-sessions/nocturne-recovery.desktop
  sudo install -m 0755 "$root/bin/nocturne-recovery-session" /usr/local/bin/nocturne-recovery-session
fi

"$root/scripts/install-hyprshot.sh"
"$root/scripts/install-kooha.sh"
"$root/apply-hyprland.sh"
