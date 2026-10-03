#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
BIN_HOME="$HOME/.local/bin"

required=(Hyprland hyprlock hyprland-dialog hypridle hyprpaper mako cliphist wl-copy notify-send jq nmcli bluetoothctl wpctl pactl pw-dump powerprofilesctl gamemoded grim slurp hyprshot cmake ninja)
missing=()
for program in "${required[@]}"; do
  command -v "$program" >/dev/null 2>&1 || missing+=("$program")
done
if ((${#missing[@]})); then
  printf 'Missing Hyprland components: %s\n' "${missing[*]}" >&2
  exit 1
fi
[[ -d /usr/lib/x86_64-linux-gnu/qt6/qml/org/kde/layershell || -d /usr/lib/aarch64-linux-gnu/qt6/qml/org/kde/layershell ]] || {
  printf 'Missing Qt 6 Layer Shell QML support (qml6-module-org-kde-layershell).\n' >&2
  exit 1
}
snapshot="$ROOT_DIR/backups/pre-hyprland-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$snapshot"
for relative in hypr gtklock waybar wofi swaync mako xdg-desktop-portal kitty btop tmux qt6ct kdeglobals; do
  if [[ -e "$CONFIG_HOME/$relative" ]]; then
    cp -a -- "$CONFIG_HOME/$relative" "$snapshot/$relative"
  fi
done
printf 'Created before applying Hyprland: %s\n' "$(date --iso-8601=seconds)" > "$snapshot/README.txt"

mkdir -p "$CONFIG_HOME/hypr" "$CONFIG_HOME/mako" "$CONFIG_HOME/xdg-desktop-portal" \
  "$CONFIG_HOME/kitty" "$CONFIG_HOME/btop/themes" "$CONFIG_HOME/tmux" "$CONFIG_HOME/cava/themes" "$CONFIG_HOME/qt6ct/colors" \
  "$CONFIG_HOME/nocturne" "$DATA_HOME/backgrounds" \
  "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots" "$HOME/Videos/Screenrecords" \
  "$DATA_HOME/applications" "$DATA_HOME/color-schemes" \
  "$CONFIG_HOME/systemd/user" "$CONFIG_HOME/autostart" \
  "$CONFIG_HOME/systemd/user/wayland-wm@hyprland.desktop.service.d" \
  "$STATE_HOME/nocturne" "$BIN_HOME"
if [[ ! -e "$STATE_HOME/nocturne/lock-wallpaper" && ! -L "$STATE_HOME/nocturne/lock-wallpaper" ]]; then
  ln -s "$DATA_HOME/backgrounds/nocturne-default.png" \
    "$STATE_HOME/nocturne/lock-wallpaper"
fi
# Hyprland 0.56+ uses Lua. Remove the retired legacy entry point so the
# compositor never has two competing configuration providers.
rm -f -- "$CONFIG_HOME/hypr/hyprland.conf"
cp -a -- "$ROOT_DIR/config/hypr/." "$CONFIG_HOME/hypr/"
rm -f -- "$CONFIG_HOME/hypr/hyprlauncher.conf"
cp -a -- "$ROOT_DIR/config/mako/." "$CONFIG_HOME/mako/"
cp -a -- "$ROOT_DIR/config/xdg-desktop-portal/." "$CONFIG_HOME/xdg-desktop-portal/"
cp -a -- "$ROOT_DIR/config/qt6ct/." "$CONFIG_HOME/qt6ct/"
sed "s|@CONFIG_HOME@|$CONFIG_HOME|g" "$ROOT_DIR/config/qt6ct/qt6ct.conf" \
  > "$CONFIG_HOME/qt6ct/qt6ct.conf"
install -m 0644 "$ROOT_DIR/config/kitty/kitty.conf" "$CONFIG_HOME/kitty/kitty.conf"
install -m 0644 "$ROOT_DIR/config/btop/btop.conf" "$CONFIG_HOME/btop/btop.conf"
install -m 0644 "$ROOT_DIR/config/btop/nocturne.theme" "$CONFIG_HOME/btop/themes/nocturne.theme"
install -m 0644 "$ROOT_DIR/config/tmux/tmux.conf" "$CONFIG_HOME/tmux/tmux.conf"
cp -a -- "$ROOT_DIR/config/cava/." "$CONFIG_HOME/cava/"
install -m 0644 \
  "$ROOT_DIR/config/systemd/user/nocturne-wallpaper-cycle.service" \
  "$CONFIG_HOME/systemd/user/nocturne-wallpaper-cycle.service"
install -m 0644 \
  "$ROOT_DIR/config/systemd/user/nocturne-easyeffects.service" \
  "$CONFIG_HOME/systemd/user/nocturne-easyeffects.service"
install -m 0644 \
  "$ROOT_DIR/config/systemd/user/nocturne-audio-autoswitch.service" \
  "$CONFIG_HOME/systemd/user/nocturne-audio-autoswitch.service"
install -m 0644 \
  "$ROOT_DIR/config/systemd/user/wayland-wm@hyprland.desktop.service.d/90-nocturne.conf" \
  "$CONFIG_HOME/systemd/user/wayland-wm@hyprland.desktop.service.d/90-nocturne.conf"
install -m 0644 "$ROOT_DIR/config/locations.json" "$CONFIG_HOME/nocturne/locations.json"
install -m 0644 "$ROOT_DIR/config/nocturne/accent.css" "$CONFIG_HOME/nocturne/accent.css"
install -m 0644 "$ROOT_DIR/config/nocturne/accent.conf" "$CONFIG_HOME/nocturne/accent.conf"
if [[ ! -e "$CONFIG_HOME/nocturne/palette.css" ]]; then
  install -m 0644 "$ROOT_DIR/config/nocturne/palette.css" "$CONFIG_HOME/nocturne/palette.css"
fi
if [[ ! -e "$CONFIG_HOME/nocturne/theme.conf" ]]; then
  install -m 0644 "$ROOT_DIR/config/nocturne/theme.conf" "$CONFIG_HOME/nocturne/theme.conf"
fi
if [[ ! -e "$CONFIG_HOME/nocturne/theme.json" ]]; then
  install -m 0644 "$ROOT_DIR/config/nocturne/theme.json" "$CONFIG_HOME/nocturne/theme.json"
fi
install -m 0644 "$ROOT_DIR/config/kdeglobals" "$CONFIG_HOME/kdeglobals"
install -m 0644 "$ROOT_DIR/config/color-schemes/Nocturne.colors" "$DATA_HOME/color-schemes/Nocturne.colors"
install -m 0755 "$ROOT_DIR/bin/nocturne-dashboard" "$BIN_HOME/nocturne-dashboard"
install -m 0755 "$ROOT_DIR/bin/nocturne-visualizer" "$BIN_HOME/nocturne-visualizer"
install -m 0755 "$ROOT_DIR/bin/nocturne-settings" "$BIN_HOME/nocturne-settings"
install -m 0755 "$ROOT_DIR/bin/nocturne-web-app" "$BIN_HOME/nocturne-web-app"
install -m 0755 "$ROOT_DIR/bin/nocturne-wallpaper-cycle" "$BIN_HOME/nocturne-wallpaper-cycle"
install -m 0755 "$ROOT_DIR/bin/nocturne-doctor" "$BIN_HOME/nocturne-doctor"
NOCTURNE_BIN_DIR="$BIN_HOME" "$ROOT_DIR/scripts/build-native.sh"
rm -f -- "$BIN_HOME/nocturne-panel" "$BIN_HOME/nocturne-power-card" \
  "$BIN_HOME/nocturne-capture" "$BIN_HOME/nocturne-settings-app" \
  "$BIN_HOME/nocturne-cyberdisc"
rm -f -- "$BIN_HOME/nocturne-connectivity" "$BIN_HOME/nocturne-calendar" \
  "$CONFIG_HOME/hypr/scripts/clock-menu"
rm -f -- "$BIN_HOME/nocturne-capture-engine" "$BIN_HOME/nocturne-capture-ui" "$BIN_HOME/nocturne-freeze-frame" \
  "$CONFIG_HOME/hypr/scripts/capture-open" "$CONFIG_HOME/hypr/scripts/capture-status" \
  "$CONFIG_HOME/hypr/scripts/screenshot" "$CONFIG_HOME/hypr/scripts/hyprshot-capture" \
  "$CONFIG_HOME/hypr/scripts/screen-record" "$CONFIG_HOME/hypr/scripts/audio-menu" \
  "$CONFIG_HOME/swappy/config"
if hyprctl plugin list 2>/dev/null | grep -qi HyprCapture; then
  hyprctl plugin unload "$HOME/.local/lib/nocturne-hyprcapture/libhyprcapture.so" >/dev/null 2>&1 || true
fi
rm -f -- "$BIN_HOME/hyprcapture-ui" "$CONFIG_HOME/hypr/hyprcapture.lua"
rm -rf -- "$HOME/.local/lib/nocturne-hyprcapture"
rmdir -- "$CONFIG_HOME/swappy" 2>/dev/null || true
if [[ ! -e "$CONFIG_HOME/nocturne/wallpaper.json" ]]; then
  install -m 0644 "$ROOT_DIR/config/nocturne/wallpaper.json" "$CONFIG_HOME/nocturne/wallpaper.json"
fi
# Retire the earlier multi-window EQ experiment; Nocturne now exposes one
# focused visualizer launcher and leaves DSP tools out of the shell UI.
rm -f -- "$BIN_HOME/nocturne-eq" "$BIN_HOME/nocturne-eq-controls" \
  "$BIN_HOME/nocturne-easyeffects" "$DATA_HOME/applications/nocturne-eq.desktop"
sed "s|@SCRIPT@|$CONFIG_HOME/hypr/scripts/steam-launch|g" \
  "$ROOT_DIR/assets/nocturne-steam.desktop.in" \
  > "$DATA_HOME/applications/steam.desktop"
chmod 0644 "$DATA_HOME/applications/steam.desktop"
sed "s|@SCRIPT@|$CONFIG_HOME/hypr/scripts/kdeconnect-settings|g" \
  "$ROOT_DIR/assets/nocturne-kdeconnect.desktop.in" \
  > "$DATA_HOME/applications/org.kde.kdeconnect.app.desktop"
chmod 0644 "$DATA_HOME/applications/org.kde.kdeconnect.app.desktop"
sed "s|@LAUNCHER@|$BIN_HOME/nocturne-settings|g" \
  "$ROOT_DIR/assets/nocturne-settings.desktop.in" \
  > "$DATA_HOME/applications/nocturne-settings.desktop"
chmod 0644 "$DATA_HOME/applications/nocturne-settings.desktop"
sed "s|@LAUNCHER@|$BIN_HOME/nocturne-native|g" \
  "$ROOT_DIR/assets/nocturne-native.desktop.in" \
  > "$DATA_HOME/applications/nocturne-native.desktop"
chmod 0644 "$DATA_HOME/applications/nocturne-native.desktop"
rm -f -- "$DATA_HOME/applications/org.gnome.Settings.desktop"
sed "s|@LAUNCHER@|$BIN_HOME/nocturne-visualizer|g" \
  "$ROOT_DIR/assets/nocturne-visualizer.desktop.in" \
  > "$DATA_HOME/applications/nocturne-visualizer.desktop"
chmod 0644 "$DATA_HOME/applications/nocturne-visualizer.desktop"
for google_app in keep drive; do
  sed "s|@LAUNCHER@|$BIN_HOME/nocturne-web-app|g" \
    "$ROOT_DIR/assets/nocturne-google-$google_app.desktop.in" \
    > "$DATA_HOME/applications/nocturne-google-$google_app.desktop"
  chmod 0644 "$DATA_HOME/applications/nocturne-google-$google_app.desktop"
done
cp -a -- "$ROOT_DIR/config/autostart/." "$CONFIG_HOME/autostart/"
rm -f -- "$CONFIG_HOME/autostart/nocturne-gnome-theme-restore.desktop"
command -v update-desktop-database >/dev/null 2>&1 && \
  update-desktop-database "$DATA_HOME/applications" >/dev/null 2>&1 || true
install -m 0644 "$ROOT_DIR/assets/nocturne-grid.png" "$DATA_HOME/backgrounds/nocturne-default.png"
if [[ ! -e "$DATA_HOME/backgrounds/nocturne-grid.png" ]]; then
  install -m 0644 "$ROOT_DIR/assets/nocturne-grid.png" "$DATA_HOME/backgrounds/nocturne-grid.png"
fi
if [[ ! -e "$CONFIG_HOME/hypr/nocturne-wallpaper.conf" ]]; then
  sed "s|@WALLPAPER@|$DATA_HOME/backgrounds/nocturne-grid.png|g" \
    "$ROOT_DIR/assets/nocturne-wallpaper.conf.in" \
    > "$CONFIG_HOME/hypr/nocturne-wallpaper.conf"
fi
chmod +x "$CONFIG_HOME"/hypr/scripts/*
"$CONFIG_HOME/hypr/scripts/sync-hyprtoolkit-theme"

# One zero-idle Nocturne process backs the visible Wi-Fi and Bluetooth controls;
# it exits when its card closes, and VPN is one middle-click away. The per-user
# XDG autostart override permanently masks Ubuntu's system nm-applet entry;
# stopping the generated unit and Blueman applet fixes the current session too.
systemctl --user stop 'app-nm\x2dapplet@autostart.service' >/dev/null 2>&1 || true
systemctl --user stop 'app-blueman@autostart.service' >/dev/null 2>&1 || true
pkill -x nm-applet 2>/dev/null || true
pkill -x innu 2>/dev/null || true
pkill -f '/usr/bin/blueman-applet' 2>/dev/null || true
rm -f -- "$DATA_HOME/applications/innu.desktop" "$BIN_HOME/innu"
rm -rf -- "$CONFIG_HOME/innu"
systemctl --user disable --now nocturne-orbit.service >/dev/null 2>&1 || true
rm -f -- "$CONFIG_HOME/systemd/user/nocturne-orbit.service" \
  "$CONFIG_HOME/hypr/scripts/orbit-popup" "$BIN_HOME/orbit"
rm -rf -- "$CONFIG_HOME/orbit"
systemctl --user disable --now nocturne-connectivity.service >/dev/null 2>&1 || true
rm -f -- "$CONFIG_HOME/systemd/user/nocturne-connectivity.service"
if [[ ${XDG_CURRENT_DESKTOP:-} == *Hyprland* ]]; then
  pkill -x orbit 2>/dev/null || true
  systemctl --user daemon-reload >/dev/null 2>&1 || true
  systemctl --user disable --now nocturne-panel.service >/dev/null 2>&1 || true
  rm -f -- "$CONFIG_HOME/systemd/user/nocturne-panel.service"
  pkill -x waybar 2>/dev/null || true
  pkill -x swaync 2>/dev/null || true
  pkill -x swaync-client 2>/dev/null || true
  pkill -x wofi 2>/dev/null || true
fi

# Use exactly one EasyEffects backend. The Flatpak copy created an autostart
# entry that currently crashes during login; the distro build now runs as a
# restartable user service and follows the session theme in either desktop.
if command -v easyeffects >/dev/null 2>&1; then
  for old_entry in com.github.wwmm.easyeffects.desktop nocturne-easyeffects.desktop; do
    if [[ ! -e "$CONFIG_HOME/autostart/$old_entry" ]]; then
      continue
    fi
    mkdir -p "$STATE_HOME/nocturne/retired-autostarts"
    mv -- "$CONFIG_HOME/autostart/$old_entry" \
      "$STATE_HOME/nocturne/retired-autostarts/$old_entry"
  done
fi

# This historical GNOME workaround merely killed gsd-power and fails under
# Hyprland. Deep sleep and lid handling now live in explicit systemd config.
if [[ -e "$CONFIG_HOME/autostart/unblock-lid.desktop" ]]; then
  mkdir -p "$STATE_HOME/nocturne/retired-autostarts"
  mv -- "$CONFIG_HOME/autostart/unblock-lid.desktop" \
    "$STATE_HOME/nocturne/retired-autostarts/unblock-lid.desktop"
fi

# Keep files and documents on the lightweight Qt application path.
xdg-mime default pcmanfm-qt.desktop inode/directory
xdg-mime default qpdfview.desktop application/pdf

# Ubuntu's packages enable these for every graphical user session. The native
# profile masks competing shell/portal owners; both GNOME restore scripts
# explicitly unmask its portal and indexer services again.
systemctl --user mask --now swaync.service >/dev/null 2>&1 || true
systemctl --user mask --now \
  xdg-desktop-portal-gtk.service \
  xdg-desktop-portal-gnome.service \
  localsearch-3.service >/dev/null 2>&1 || true
systemctl --user stop \
  'app-org.gnome.Evolution\x2dalarm\x2dnotify@autostart.service' \
  evolution-addressbook-factory.service \
  evolution-calendar-factory.service \
  evolution-source-registry.service >/dev/null 2>&1 || true
systemctl --user daemon-reload >/dev/null 2>&1 || true
systemctl --user start nocturne-wallpaper-cycle.service >/dev/null 2>&1 || true
systemctl --user enable --now nocturne-easyeffects.service >/dev/null 2>&1 || true
systemctl --user enable --now nocturne-audio-autoswitch.service >/dev/null 2>&1 || true
systemctl --user mask --now \
  waybar.service \
  hypridle.service \
  hyprpaper.service \
  hyprpolkitagent.service >/dev/null 2>&1 || true

# A running legacy-config session may recreate Hyprland's generated stub when
# its provider reloads. Remove it best-effort; the UWSM override above also
# passes the Lua entry point explicitly on every fresh compositor start.
rm -f -- "$CONFIG_HOME/hypr/hyprland.conf"

printf 'Hyprland configuration installed. Select “Hyprland (uwsm-managed)” at login.\n'
printf 'Pre-existing Hypr-related configs, if any, were saved at:\n  %s\n' "$snapshot"
