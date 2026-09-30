#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
BACKUP_LINK="$ROOT_DIR/backups/current-backup"

[[ -d "$BACKUP_LINK" ]] || {
  printf 'Refusing to apply: no verified backup found at %s\n' "$BACKUP_LINK" >&2
  exit 1
}

install_file() {
  local mode=$1 source=$2 destination=$3
  install -D -m "$mode" "$source" "$destination"
}

has_setting() {
  local schema=$1 key=$2
  gsettings list-keys "$schema" 2>/dev/null | grep -qx "$key"
}

set_setting() {
  local schema=$1 key=$2 value=$3
  if has_setting "$schema" "$key"; then
    gsettings set "$schema" "$key" "$value"
  fi
}

extension_set() {
  local uuid=$1 schema=$2 key=$3 value=$4
  local schema_dir="$DATA_HOME/gnome-shell/extensions/$uuid/schemas"
  if [[ -f "$schema_dir/gschemas.compiled" ]] && \
     GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings list-keys "$schema" 2>/dev/null | grep -qx "$key"; then
    GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set "$schema" "$key" "$value"
  fi
}

install_gtk_css() {
  local gtk_dir=$1 gtk_css="$1/gtk.css"
  mkdir -p "$gtk_dir"
  install_file 0644 "$ROOT_DIR/config/gtk/nocturne.css" "$gtk_dir/nocturne.css"
  if [[ -f "$gtk_css" ]] && ! grep -q 'nocturne.css' "$gtk_css"; then
    mv -- "$gtk_css" "$gtk_dir/gtk.pre-nocturne.css"
    printf '@import url("gtk.pre-nocturne.css");\n@import url("nocturne.css");\n' > "$gtk_css"
  elif [[ ! -f "$gtk_css" ]]; then
    printf '@import url("nocturne.css");\n' > "$gtk_css"
  fi
}

printf 'Applying Nocturne user configuration…\n'

install_file 0644 "$ROOT_DIR/config/kitty/kitty.conf" "$CONFIG_HOME/kitty/kitty.conf"
install_file 0644 "$ROOT_DIR/config/tmux/tmux.conf" "$CONFIG_HOME/tmux/tmux.conf"
install_file 0644 "$ROOT_DIR/config/btop/nocturne.theme" "$CONFIG_HOME/btop/themes/nocturne.theme"
install_file 0644 "$ROOT_DIR/config/btop/btop.conf" "$CONFIG_HOME/btop/btop.conf"
install_file 0644 "$ROOT_DIR/config/fastfetch/config.jsonc" "$CONFIG_HOME/fastfetch/config.jsonc"
install_file 0644 "$ROOT_DIR/config/cava/config" "$CONFIG_HOME/cava/config"
install_file 0644 "$ROOT_DIR/config/nocturne-nvim/init.lua" "$CONFIG_HOME/nocturne-nvim/init.lua"
install_file 0644 "$ROOT_DIR/config/zsh/nocturne.zsh" "$CONFIG_HOME/nocturne/zsh.zsh"
install_file 0644 "$ROOT_DIR/assets/nocturne-grid.png" "$DATA_HOME/backgrounds/nocturne-grid.png"
install_file 0755 "$ROOT_DIR/bin/nocturne-dashboard" "$HOME/.local/bin/nocturne-dashboard"
install_file 0755 "$ROOT_DIR/bin/nocturne-visualizer" "$HOME/.local/bin/nocturne-visualizer"
install_file 0755 "$ROOT_DIR/bin/configure-world-clocks" "$HOME/.local/bin/configure-world-clocks"
install_file 0755 "$ROOT_DIR/bin/nocturne-first-login" "$HOME/.local/bin/nocturne-first-login"
mkdir -p "$CONFIG_HOME/autostart"
sed "s|@LAUNCHER@|$HOME/.local/bin/nocturne-first-login|g" \
  "$ROOT_DIR/assets/nocturne-first-login.desktop" \
  > "$CONFIG_HOME/autostart/nocturne-first-login.desktop"

install_gtk_css "$CONFIG_HOME/gtk-3.0"
install_gtk_css "$CONFIG_HOME/gtk-4.0"

if ! grep -qF '# >>> Nocturne desktop >>>' "$HOME/.zshrc"; then
  printf '\n# >>> Nocturne desktop >>>\n[[ ! -f ~/.config/nocturne/zsh.zsh ]] || source ~/.config/nocturne/zsh.zsh\n# <<< Nocturne desktop <<<\n' >> "$HOME/.zshrc"
fi

wallpaper_uri="file://$DATA_HOME/backgrounds/nocturne-grid.png"
set_setting org.gnome.desktop.interface color-scheme "'prefer-dark'"
set_setting org.gnome.desktop.interface accent-color "'blue'"
set_setting org.gnome.desktop.interface monospace-font-name "'MesloLGS Nerd Font Mono 11'"
set_setting org.gnome.desktop.wm.preferences button-layout "':close'"
set_setting org.gnome.desktop.interface clock-show-date true
set_setting org.gnome.desktop.interface clock-show-weekday true
set_setting org.gnome.desktop.interface clock-show-seconds false
set_setting org.gnome.desktop.background picture-uri "'$wallpaper_uri'"
set_setting org.gnome.desktop.background picture-uri-dark "'$wallpaper_uri'"
set_setting org.gnome.desktop.background picture-options "'zoom'"

# Keep normal GNOME apps mouse-friendly while making new windows predictable for tiling.
set_setting org.gnome.mutter center-new-windows true
set_setting org.gnome.mutter dynamic-workspaces true

# Curated extension defaults: compact, useful, and consistent with the desktop palette.
extension_set tilingshell@ferrarodomenico.com org.gnome.shell.extensions.tilingshell inner-gaps 8
extension_set tilingshell@ferrarodomenico.com org.gnome.shell.extensions.tilingshell outer-gaps 6
extension_set tilingshell@ferrarodomenico.com org.gnome.shell.extensions.tilingshell enable-tiling-system true
extension_set tilingshell@ferrarodomenico.com org.gnome.shell.extensions.tilingshell enable-snap-assist true
extension_set tilingshell@ferrarodomenico.com org.gnome.shell.extensions.tilingshell show-indicator false
extension_set tilingshell@ferrarodomenico.com org.gnome.shell.extensions.tilingshell enable-autotiling false
extension_set tilingshell@ferrarodomenico.com org.gnome.shell.extensions.tilingshell enable-move-keybindings true
extension_set tilingshell@ferrarodomenico.com org.gnome.shell.extensions.tilingshell enable-window-border true
extension_set tilingshell@ferrarodomenico.com org.gnome.shell.extensions.tilingshell window-use-custom-border-color true
extension_set tilingshell@ferrarodomenico.com org.gnome.shell.extensions.tilingshell window-border-color "'#7aa2f7'"
extension_set tilingshell@ferrarodomenico.com org.gnome.shell.extensions.tilingshell window-border-width 2
extension_set tilingshell@ferrarodomenico.com org.gnome.shell.extensions.tilingshell enable-smart-window-border-radius true

extension_set pomodoro-timer@Oguzhankokulu.github.com org.gnome.shell.extensions.pomodoro-timer use-system-theme true
extension_set pomodoro-timer@Oguzhankokulu.github.com org.gnome.shell.extensions.pomodoro-timer show-icon true
extension_set pomodoro-timer@Oguzhankokulu.github.com org.gnome.shell.extensions.pomodoro-timer show-timer-always false
extension_set pomodoro-timer@Oguzhankokulu.github.com org.gnome.shell.extensions.pomodoro-timer focus-dnd-enabled true
extension_set pomodoro-timer@Oguzhankokulu.github.com org.gnome.shell.extensions.pomodoro-timer notify-enabled true
extension_set pomodoro-timer@Oguzhankokulu.github.com org.gnome.shell.extensions.pomodoro-timer suspend-inhibitor-enabled true

extension_set date-menu-formatter@marcinjakubowski.github.com org.gnome.shell.extensions.date-menu-formatter pattern "'ccc · LLL dd  HH:mm'"
extension_set date-menu-formatter@marcinjakubowski.github.com org.gnome.shell.extensions.date-menu-formatter font-size 10
extension_set date-menu-formatter@marcinjakubowski.github.com org.gnome.shell.extensions.date-menu-formatter font-weight "'600'"
extension_set date-menu-formatter@marcinjakubowski.github.com org.gnome.shell.extensions.date-menu-formatter update-level 0
extension_set date-menu-formatter@marcinjakubowski.github.com org.gnome.shell.extensions.date-menu-formatter text-align "'center'"

extension_set clipboard-history@alexsaveau.dev org.gnome.shell.extensions.clipboard-history history-size 500
extension_set clipboard-history@alexsaveau.dev org.gnome.shell.extensions.clipboard-history display-mode 0
extension_set clipboard-history@alexsaveau.dev org.gnome.shell.extensions.clipboard-history window-width-percentage 33
extension_set clipboard-history@alexsaveau.dev org.gnome.shell.extensions.clipboard-history cache-size 64
extension_set clipboard-history@alexsaveau.dev org.gnome.shell.extensions.clipboard-history cache-only-favorites true
extension_set clipboard-history@alexsaveau.dev org.gnome.shell.extensions.clipboard-history notify-on-copy false
extension_set clipboard-history@alexsaveau.dev org.gnome.shell.extensions.clipboard-history confirm-clear true
extension_set clipboard-history@alexsaveau.dev org.gnome.shell.extensions.clipboard-history ignore-password-mimes true

extension_set medialine@funinkina.co.in org.gnome.shell.extensions.medialine panel-position "'right'"
extension_set medialine@funinkina.co.in org.gnome.shell.extensions.medialine icon-type "'album-art'"
extension_set medialine@funinkina.co.in org.gnome.shell.extensions.medialine icon-size 16
extension_set medialine@funinkina.co.in org.gnome.shell.extensions.medialine max-text-width 260
extension_set medialine@funinkina.co.in org.gnome.shell.extensions.medialine popup-primary-color "'#c0caf5'"
extension_set medialine@funinkina.co.in org.gnome.shell.extensions.medialine popup-secondary-color "'#7aa2f7'"
extension_set medialine@funinkina.co.in org.gnome.shell.extensions.medialine popup-background-color "'#0f111a'"
extension_set medialine@funinkina.co.in org.gnome.shell.extensions.medialine popup-dynamic-bg false
extension_set medialine@funinkina.co.in org.gnome.shell.extensions.medialine popup-show-visualizer true
extension_set medialine@funinkina.co.in org.gnome.shell.extensions.medialine enhanced-pwa-support true

extension_set notification-icons@jiggak.io org.gnome.shell.extensions.notification-icons colored-icons false
extension_set notification-icons@jiggak.io org.gnome.shell.extensions.notification-icons right-side true

weather_locations=$(jq -c '[.weather_locations[] | {name: .label, lat: .latitude, lon: .longitude} | tojson]' "$ROOT_DIR/config/locations.json")
extension_set simple-weather@romanlefler.com org.gnome.shell.extensions.simple-weather is-activated true
extension_set simple-weather@romanlefler.com org.gnome.shell.extensions.simple-weather locations "$weather_locations"
extension_set simple-weather@romanlefler.com org.gnome.shell.extensions.simple-weather main-location-index 0
extension_set simple-weather@romanlefler.com org.gnome.shell.extensions.simple-weather unit-preset "'metric'"
extension_set simple-weather@romanlefler.com org.gnome.shell.extensions.simple-weather weather-provider "'open-meteo'"
extension_set simple-weather@romanlefler.com org.gnome.shell.extensions.simple-weather panel-box "'right'"
extension_set simple-weather@romanlefler.com org.gnome.shell.extensions.simple-weather panel-detail "'temp'"
extension_set simple-weather@romanlefler.com org.gnome.shell.extensions.simple-weather secondary-panel-detail "''"
extension_set simple-weather@romanlefler.com org.gnome.shell.extensions.simple-weather show-panel-icon true
extension_set simple-weather@romanlefler.com org.gnome.shell.extensions.simple-weather symbolic-icons-panel true
extension_set simple-weather@romanlefler.com org.gnome.shell.extensions.simple-weather show-refresh-button true

# Fill both GNOME Clocks and the clock menu, then stage the new extensions for next login.
"$HOME/.local/bin/configure-world-clocks" "$ROOT_DIR/config/locations.json"

# Super+Return opens the themed Zsh terminal without replacing existing shortcuts.
key_schema=org.gnome.settings-daemon.plugins.media-keys
key_path=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/nocturne-terminal/
current_keys=$(gsettings get "$key_schema" custom-keybindings | sed 's/^@as //')
if [[ "$current_keys" != *"$key_path"* ]]; then
  if [[ "$current_keys" == '[]' ]]; then
    updated_keys="['$key_path']"
  else
    updated_keys="${current_keys%]}, '$key_path']"
  fi
  gsettings set "$key_schema" custom-keybindings "$updated_keys"
fi
gsettings set "$key_schema.custom-keybinding:$key_path" name 'Nocturne Terminal'
gsettings set "$key_schema.custom-keybinding:$key_path" command 'kitty'
gsettings set "$key_schema.custom-keybinding:$key_path" binding '<Super>Return'

# Desktop launchers.
sed "s|@LAUNCHER@|$HOME/.local/bin/nocturne-dashboard|g" \
  "$ROOT_DIR/assets/nocturne-dashboard.desktop.in" \
  > "$DATA_HOME/applications/nocturne-dashboard.desktop"
sed "s|@LAUNCHER@|$HOME/.local/bin/nocturne-visualizer|g" \
  "$ROOT_DIR/assets/nocturne-visualizer.desktop.in" \
  > "$DATA_HOME/applications/nocturne-visualizer.desktop"

printf 'Nocturne configuration applied. Log out/in after extension installation.\n'
