#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
export HOME="$test_root/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CURRENT_DESKTOP=''
mock_bin="$test_root/bin"
mkdir -p "$XDG_CONFIG_HOME/hypr" "$mock_bin"

printf '%s\n' '-- original clean-home sentinel --' > "$XDG_CONFIG_HOME/hypr/hyprland.lua"
printf '%s\n' '#!/bin/sh' 'printf "Hyprland 0.56.2 built from branch main\n"' > "$mock_bin/Hyprland"
printf '%s\n' '#!/bin/sh' \
  'case "$*" in' \
  '  "-j monitors") printf '\''[{"name":"TEST-1","width":1920,"height":1080,"refreshRate":60,"x":0,"y":0,"scale":1}]\n'\'' ;;' \
  '  "plugin list") exit 0 ;;' \
  '  *) exit 0 ;;' \
  'esac' > "$mock_bin/hyprctl"
printf '%s\n' '#!/bin/sh' \
  'if [ "${1:-}" = query ]; then printf "fixture.desktop\n"; fi' \
  'exit 0' > "$mock_bin/xdg-mime"

for command in start-hyprland uwsm hyprlock hypridle hyprpaper hyprsunset mako cliphist wl-copy notify-send flatpak nmcli bluetoothctl wpctl pactl pw-dump powerprofilesctl fwupdmgr gamemoded socat grim slurp hyprshot dolphin lspci glxinfo convert upower systemctl busctl dbus-update-activation-environment pkill update-desktop-database; do
  [[ -e $mock_bin/$command ]] && continue
  printf '%s\n' '#!/bin/sh' 'exit 0' > "$mock_bin/$command"
done
chmod +x "$mock_bin"/*

PATH="$mock_bin:$PATH" "$root/apply-hyprland.sh" >/dev/null

[[ -x $HOME/.local/bin/nocturne-native ]]
[[ -x $HOME/.local/bin/nocturne-welcome ]]
[[ -x $HOME/.local/bin/nox-doc ]]
[[ -r $XDG_CONFIG_HOME/systemd/user/nocturne-welcome.service ]]
[[ -r $XDG_DATA_HOME/dbus-1/services/fr.emersion.mako.service ]]
[[ -s $XDG_STATE_HOME/nocturne/recovery/last-good.tar.gz ]]
[[ -s $XDG_STATE_HOME/nocturne/original-preinstall-backup ]]
PATH="$mock_bin:$PATH" "$HOME/.local/bin/nocturne-welcome" status --json \
  | jq -e '.format == "nocturne-welcome-v1" and .version == "2.0.0" and .privacy.telemetry == false' >/dev/null

printf 'RESTORE\n' | PATH="$mock_bin:$PATH" "$root/uninstall.sh" >/dev/null
grep -Fq -- '-- original clean-home sentinel --' "$XDG_CONFIG_HOME/hypr/hyprland.lua"
[[ ! -e $HOME/.local/bin/nocturne-welcome ]]
[[ ! -e $XDG_DATA_HOME/dbus-1/services/fr.emersion.mako.service ]]

printf 'NOCTURNE // clean-home install and rollback passed\n'
