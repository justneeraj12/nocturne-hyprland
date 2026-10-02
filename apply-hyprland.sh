#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
BIN_HOME="$HOME/.local/bin"
BACKUP_LINK="$ROOT_DIR/backups/current-backup"

[[ -d "$BACKUP_LINK" ]] || {
  printf 'Refusing to apply: verified fallback backup is missing at %s\n' "$BACKUP_LINK" >&2
  exit 1
}

required=(Hyprland hyprlock hyprland-dialog hypridle hyprpaper hyprlauncher hyprpwcenter waybar swaync wofi cliphist wl-copy orbit socat ffmpeg hyprpm)
missing=()
for program in "${required[@]}"; do
  command -v "$program" >/dev/null 2>&1 || missing+=("$program")
done
if ((${#missing[@]})); then
  printf 'Missing Hyprland components: %s\n' "${missing[*]}" >&2
  exit 1
fi
snapshot="$ROOT_DIR/backups/pre-hyprland-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$snapshot"
for relative in hypr gtklock waybar wofi swaync kitty btop tmux qt6ct kdeglobals; do
  if [[ -e "$CONFIG_HOME/$relative" ]]; then
    cp -a -- "$CONFIG_HOME/$relative" "$snapshot/$relative"
  fi
done
printf 'Created before applying Hyprland: %s\n' "$(date --iso-8601=seconds)" > "$snapshot/README.txt"

mkdir -p "$CONFIG_HOME/hypr" "$CONFIG_HOME/gtklock" "$CONFIG_HOME/waybar" "$CONFIG_HOME/wofi" \
  "$CONFIG_HOME/swaync" "$CONFIG_HOME/kitty" "$CONFIG_HOME/btop/themes" "$CONFIG_HOME/tmux" "$CONFIG_HOME/cava/themes" "$CONFIG_HOME/qt6ct/colors" \
  "$CONFIG_HOME/nocturne" "$CONFIG_HOME/orbit" "$DATA_HOME/backgrounds" \
  "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots" "$HOME/Videos/Screenrecords" \
  "$DATA_HOME/applications" "$DATA_HOME/color-schemes" \
  "$CONFIG_HOME/systemd/user/swaync.service.d" "$CONFIG_HOME/systemd/user" "$CONFIG_HOME/dconf" "$CONFIG_HOME/autostart" \
  "$STATE_HOME/nocturne" "$BIN_HOME"
if [[ ! -e "$STATE_HOME/nocturne/lock-wallpaper" && ! -L "$STATE_HOME/nocturne/lock-wallpaper" ]]; then
  ln -s "$DATA_HOME/backgrounds/nocturne-default.png" \
    "$STATE_HOME/nocturne/lock-wallpaper"
fi
# Hyprland 0.56+ uses Lua. Remove the retired legacy entry point so the
# compositor never has two competing configuration providers.
rm -f -- "$CONFIG_HOME/hypr/hyprland.conf"
cp -a -- "$ROOT_DIR/config/hypr/." "$CONFIG_HOME/hypr/"
cp -a -- "$ROOT_DIR/config/gtklock/." "$CONFIG_HOME/gtklock/"
cp -a -- "$ROOT_DIR/config/waybar/." "$CONFIG_HOME/waybar/"
cp -a -- "$ROOT_DIR/config/wofi/." "$CONFIG_HOME/wofi/"
cp -a -- "$ROOT_DIR/config/swaync/." "$CONFIG_HOME/swaync/"
cp -a -- "$ROOT_DIR/config/qt6ct/." "$CONFIG_HOME/qt6ct/"
sed "s|@CONFIG_HOME@|$CONFIG_HOME|g" "$ROOT_DIR/config/qt6ct/qt6ct.conf" \
  > "$CONFIG_HOME/qt6ct/qt6ct.conf"
install -m 0644 "$ROOT_DIR/config/kitty/kitty.conf" "$CONFIG_HOME/kitty/kitty.conf"
install -m 0644 "$ROOT_DIR/config/btop/btop.conf" "$CONFIG_HOME/btop/btop.conf"
install -m 0644 "$ROOT_DIR/config/btop/nocturne.theme" "$CONFIG_HOME/btop/themes/nocturne.theme"
install -m 0644 "$ROOT_DIR/config/tmux/tmux.conf" "$CONFIG_HOME/tmux/tmux.conf"
cp -a -- "$ROOT_DIR/config/cava/." "$CONFIG_HOME/cava/"
cp -a -- "$ROOT_DIR/config/orbit/." "$CONFIG_HOME/orbit/"
install -m 0644 \
  "$ROOT_DIR/config/systemd/user/swaync.service.d/only-hyprland.conf" \
  "$CONFIG_HOME/systemd/user/swaync.service.d/only-hyprland.conf"
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
  "$ROOT_DIR/config/systemd/user/nocturne-orbit.service" \
  "$CONFIG_HOME/systemd/user/nocturne-orbit.service"
install -m 0644 "$ROOT_DIR/config/locations.json" "$CONFIG_HOME/nocturne/locations.json"
install -m 0644 "$ROOT_DIR/config/nocturne/accent.css" "$CONFIG_HOME/nocturne/accent.css"
install -m 0644 "$ROOT_DIR/config/nocturne/accent.conf" "$CONFIG_HOME/nocturne/accent.conf"
install -m 0644 "$ROOT_DIR/config/nocturne/gtk-4.0.css" "$CONFIG_HOME/nocturne/gtk-4.0.css"
install -m 0644 "$ROOT_DIR/config/nocturne/gtk-3.0.css" "$CONFIG_HOME/nocturne/gtk-3.0.css"
if [[ ! -e "$CONFIG_HOME/nocturne/palette.css" ]]; then
  install -m 0644 "$ROOT_DIR/config/nocturne/palette.css" "$CONFIG_HOME/nocturne/palette.css"
fi
if [[ ! -e "$CONFIG_HOME/nocturne/theme.conf" ]]; then
  install -m 0644 "$ROOT_DIR/config/nocturne/theme.conf" "$CONFIG_HOME/nocturne/theme.conf"
fi
if [[ ! -e "$CONFIG_HOME/nocturne/theme.json" ]]; then
  install -m 0644 "$ROOT_DIR/config/nocturne/theme.json" "$CONFIG_HOME/nocturne/theme.json"
fi
install -m 0644 "$ROOT_DIR/config/dconf/hyprland-profile" "$CONFIG_HOME/dconf/hyprland-profile"
install -m 0644 "$ROOT_DIR/config/kdeglobals" "$CONFIG_HOME/kdeglobals"
install -m 0644 "$ROOT_DIR/config/color-schemes/Nocturne.colors" "$DATA_HOME/color-schemes/Nocturne.colors"
install -m 0755 "$ROOT_DIR/bin/nocturne-session-theme" "$BIN_HOME/nocturne-session-theme"
install -m 0755 "$ROOT_DIR/bin/nocturne-dashboard" "$BIN_HOME/nocturne-dashboard"
install -m 0755 "$ROOT_DIR/bin/nocturne-visualizer" "$BIN_HOME/nocturne-visualizer"
install -m 0755 "$ROOT_DIR/bin/nocturne-cyberdisc" "$BIN_HOME/nocturne-cyberdisc"
install -m 0755 "$ROOT_DIR/bin/nocturne-settings" "$BIN_HOME/nocturne-settings"
install -m 0755 "$ROOT_DIR/bin/nocturne-settings-app" "$BIN_HOME/nocturne-settings-app"
install -m 0755 "$ROOT_DIR/bin/nocturne-web-app" "$BIN_HOME/nocturne-web-app"
install -m 0755 "$ROOT_DIR/bin/nocturne-wallpaper-cycle" "$BIN_HOME/nocturne-wallpaper-cycle"
install -m 0755 "$ROOT_DIR/bin/nocturne-doctor" "$BIN_HOME/nocturne-doctor"
install -m 0755 "$ROOT_DIR/bin/nocturne-calendar" "$BIN_HOME/nocturne-calendar"
install -m 0755 "$ROOT_DIR/bin/nocturne-power-card" "$BIN_HOME/nocturne-power-card"
rm -f -- "$BIN_HOME/nocturne-capture-ui" "$BIN_HOME/nocturne-freeze-frame" \
  "$CONFIG_HOME/hypr/scripts/screenshot" "$CONFIG_HOME/hypr/scripts/hyprshot-capture" \
  "$CONFIG_HOME/hypr/scripts/screen-record" "$CONFIG_HOME/hypr/scripts/audio-menu" \
  "$CONFIG_HOME/swappy/config" "$BIN_HOME/hyprshot"
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
  > "$DATA_HOME/applications/org.gnome.Settings.desktop"
chmod 0644 "$DATA_HOME/applications/org.gnome.Settings.desktop"
rm -f -- "$DATA_HOME/applications/nocturne-settings.desktop"
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
sed "s|@SCRIPT@|$BIN_HOME/nocturne-session-theme|g" \
  "$ROOT_DIR/assets/nocturne-gnome-theme-restore.desktop.in" \
  > "$CONFIG_HOME/autostart/nocturne-gnome-theme-restore.desktop"
chmod 0644 "$CONFIG_HOME/autostart/nocturne-gnome-theme-restore.desktop"
install -m 0644 "$ROOT_DIR/config/autostart/nm-applet.desktop" \
  "$CONFIG_HOME/autostart/nm-applet.desktop"
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

# Orbit backs the separate always-visible Wi-Fi and Bluetooth controls; VPN is
# one middle-click away from Wi-Fi. The per-user
# XDG autostart override permanently masks Ubuntu's system nm-applet entry;
# stopping the generated unit and Blueman applet fixes the current session too.
systemctl --user stop 'app-nm\x2dapplet@autostart.service' >/dev/null 2>&1 || true
pkill -x nm-applet 2>/dev/null || true
pkill -x innu 2>/dev/null || true
pkill -f '/usr/bin/blueman-applet' 2>/dev/null || true
rm -f -- "$DATA_HOME/applications/innu.desktop" "$BIN_HOME/innu"
rm -rf -- "$CONFIG_HOME/innu"
if [[ ${XDG_CURRENT_DESKTOP:-} == *Hyprland* ]]; then
  pkill -x orbit 2>/dev/null || true
  systemctl --user daemon-reload >/dev/null 2>&1 || true
  systemctl --user restart nocturne-orbit.service >/dev/null 2>&1 || true
  # The existing session bar wrapper owns restart policy; stopping only Waybar
  # makes it reload the new modules without creating a second wrapper.
  pkill -x waybar 2>/dev/null || true
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

# Hyprland gets its own small dconf database so GTK/icon/window-control choices
# never overwrite the restored MacTahoe settings used by GNOME.
HYPR_DCONF_PROFILE="$CONFIG_HOME/dconf/hyprland-profile"
if [[ ! -e "$CONFIG_HOME/dconf/hyprland" ]]; then
  env -u DCONF_PROFILE dconf dump / > "$snapshot/dconf-base.ini"
  DCONF_PROFILE="$HYPR_DCONF_PROFILE" dconf load / < "$snapshot/dconf-base.ini"
fi
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.gnome.desktop.interface icon-theme 'Yaru-sage-dark'
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.gnome.desktop.interface accent-color 'green'
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.gnome.desktop.interface font-name 'Inter 10'
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.gnome.desktop.interface document-font-name 'Inter 10'
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.gnome.desktop.interface monospace-font-name 'MesloLGS Nerd Font Mono 10'
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.gnome.desktop.wm.preferences button-layout ''
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.gnome.nautilus.preferences default-sort-order 'name'
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.gnome.nautilus.preferences default-sort-in-reverse-order false
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.gnome.nautilus.preferences show-image-thumbnails 'always'
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.gnome.nautilus.preferences show-create-link true
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.gnome.nautilus.preferences show-delete-permanently true
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.gnome.nautilus.list-view default-zoom-level 'small'
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.gnome.nautilus.icon-view default-zoom-level 'small'
# Orbit owns pairing and Bluetooth control in Hyprland. Keep every Blueman
# status plugin disabled in this session profile so no legacy icon can return;
# GNOME's separate dconf profile remains untouched.
DCONF_PROFILE="$HYPR_DCONF_PROFILE" gsettings set org.blueman.general plugin-list \
  "['!StatusIcon', '!StatusNotifierItem', '!ShowConnected']"

# Keep PDF handling familiar even when a browser or another desktop has
# previously claimed the MIME association.
if [[ -f /usr/share/applications/org.gnome.Papers.desktop ]]; then
  xdg-mime default org.gnome.Papers.desktop application/pdf
elif [[ -f /usr/share/applications/org.gnome.Evince.desktop ]]; then
  xdg-mime default org.gnome.Evince.desktop application/pdf
fi

# Ubuntu's packages enable these for every graphical user session. Hyprland
# starts the programs directly above, so mask only their user units to keep
# them out of the restored GNOME session and avoid duplicate processes.
systemctl --user unmask swaync.service >/dev/null 2>&1 || true
systemctl --user daemon-reload >/dev/null 2>&1 || true
systemctl --user start nocturne-wallpaper-cycle.service >/dev/null 2>&1 || true
systemctl --user enable --now nocturne-easyeffects.service >/dev/null 2>&1 || true
systemctl --user enable --now nocturne-audio-autoswitch.service >/dev/null 2>&1 || true
systemctl --user mask --now \
  waybar.service \
  hypridle.service \
  hyprpaper.service \
  hyprpolkitagent.service >/dev/null 2>&1 || true

printf 'Hyprland configuration installed. Select “Hyprland (uwsm-managed)” at login.\n'
printf 'Pre-existing Hypr-related configs, if any, were saved at:\n  %s\n' "$snapshot"
