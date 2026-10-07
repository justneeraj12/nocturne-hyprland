#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
platform="$root/bin/nocturne-platform"
print_only=false

case ${1:-} in
  '') ;;
  --print) print_only=true ;;
  *) printf 'Usage: %s [--print]\n' "$0" >&2; exit 2 ;;
esac

ubuntu_packages=(
  build-essential cmake ninja-build qt6-base-dev qt6-declarative-dev
  qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts
  qml6-module-qtquick-window qml6-module-org-kde-layershell
  layer-shell-qt liblayershellqtinterface-dev mako-notifier xdg-desktop-portal-kde
  curl flatpak grim slurp swappy tesseract-ocr qrencode wl-clipboard cliphist
  libnotify-bin brightnessctl pipewire-bin pulseaudio-utils xdg-utils v4l-utils
  network-manager bluez jq age socat kitty btop cava fastfetch playerctl gamemode
  dolphin plasma-integration kde-style-breeze kf6-breeze-icon-theme ffmpegthumbs
  pcmanfm-qt lxqt-archiver ffmpegthumbnailer qt6-image-formats-plugins
  kimageformat6-plugins qpdfview qalculate-qt power-profiles-daemon fwupd
  hypridle hyprlock hyprpaper hyprpolkitagent hyprsunset uwsm
  pciutils mesa-utils imagemagick upower mangohud fonts-inter fonts-jetbrains-mono
  ffmpeg gstreamer1.0-libav gstreamer1.0-plugins-good gstreamer1.0-plugins-bad
  gstreamer1.0-plugins-ugly libva2 intel-media-va-driver vainfo intel-gpu-tools
  kdeconnect easyeffects clamav clamav-freshclam debsums apparmor-utils ufw
  cups cups-client cups-filters cups-browsed ipp-usb avahi-daemon libnss-mdns
  sane-utils sane-airscan simple-scan skanpage systemd-zram-generator
)

# Every Arch dependency below is in Core or Extra; the supported path never
# invokes an AUR helper. Okular replaces qpdfview, which is AUR-only on Arch.
arch_packages=(
  base-devel cmake ninja qt6-base qt6-declarative qt6-wayland layer-shell-qt
  mako xdg-desktop-portal-hyprland xdg-desktop-portal-kde curl flatpak grim slurp
  swappy tesseract tesseract-data-eng qrencode wl-clipboard cliphist libnotify
  brightnessctl pipewire pipewire-pulse xdg-utils v4l-utils networkmanager bluez
  bluez-utils jq age socat kitty btop cava fastfetch playerctl gamemode dolphin
  plasma-integration breeze breeze-icons ffmpegthumbs pcmanfm-qt lxqt-archiver
  ffmpegthumbnailer qt6-imageformats kimageformats okular qalculate-qt
  power-profiles-daemon fwupd hypridle hyprlock hyprpaper hyprpolkitagent
  hyprsunset uwsm pciutils mesa-utils imagemagick upower mangohud inter-font
  ttf-jetbrains-mono ttf-meslo-nerd ffmpeg gst-libav gst-plugins-good
  gst-plugins-bad gst-plugins-ugly libva intel-media-driver libva-utils
  intel-gpu-tools pacman-contrib kdeconnect easyeffects clamav apparmor ufw
  cups cups-filters cups-browsed ipp-usb avahi nss-mdns sane sane-airscan
  simple-scan skanpage zram-generator
)

family=$($platform family)
case $family in
  debian) packages=("${ubuntu_packages[@]}") ;;
  arch) packages=("${arch_packages[@]}") ;;
  *) printf 'Unsupported distribution: %s\n' "$($platform id)" >&2; exit 3 ;;
esac

if "$print_only"; then
  jq -cn --arg family "$family" --arg manager "$($platform status | jq -r .packageManager)" \
    --args '{format:"nocturne-package-plan-v1",family:$family,packageManager:$manager,packages:$ARGS.positional}' \
    -- "${packages[@]}"
  exit 0
fi

case $family in
  debian)
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends "${packages[@]}"
    # NOC uses a user-owned signature database and zero-resident timers. Keep
    # distro ClamAV daemons from pinning the full signature set in memory.
    sudo systemctl disable --now clamav-freshclam.service clamav-daemon.service clamav-daemon.socket 2>/dev/null || true
    ;;
  arch)
    sudo pacman -Syu --needed --noconfirm "${packages[@]}"
    sudo systemctl enable --now NetworkManager.service bluetooth.service
    ;;
esac

sudo install -m 0644 "$root/assets/nocturne-recovery.desktop" /usr/share/wayland-sessions/nocturne-recovery.desktop
sudo install -m 0755 "$root/bin/nocturne-recovery-session" /usr/local/bin/nocturne-recovery-session
sudo install -d -m 0755 /etc/nocturne /usr/share/nocturne /usr/local/sbin
sudo install -m 0755 "$root/bin/nox-doc" /usr/local/sbin/nox-doc
sudo install -m 0644 "$root/config/nocturne/nox-doc-knowledge.json" /usr/share/nocturne/nox-doc-knowledge.json
sudo install -m 0644 "$root/config/systemd/system/nox-doc.service" /etc/systemd/system/nox-doc.service
sudo install -m 0644 "$root/config/systemd/system/nox-doc.target" /etc/systemd/system/nox-doc.target
install_user=${SUDO_USER:-$(id -un)}
install_home=$(getent passwd "$install_user" | awk -F: '{print $6; exit}')
if [[ $install_user =~ ^[a-z_][a-z0-9_-]{0,31}$ && $install_home == /* ]]; then
  nox_doc_config=$(mktemp)
  trap 'rm -f -- "$nox_doc_config"' EXIT
  printf 'NOX_DOC_USER=%s\nNOX_DOC_HOME=%s\n' "$install_user" "$install_home" > "$nox_doc_config"
  sudo install -m 0644 "$nox_doc_config" /etc/nocturne/nox-doc.conf
fi
sudo systemctl daemon-reload
printf 'Installed the Nocturne %s dependency plan.\n' "$family"
