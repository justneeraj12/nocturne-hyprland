#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
export HOME=$test_root/home
export XDG_CONFIG_HOME=$HOME/.config
export XDG_STATE_HOME=$HOME/.local/state
export NOCTURNE_NO_RESTART=1
mkdir -p -- "$XDG_CONFIG_HOME/nocturne" "$XDG_CONFIG_HOME/hypr/scripts" "$test_root/bin"

cp -- "$root/config/nocturne/bar.json" "$XDG_CONFIG_HOME/nocturne/bar.default.json"
"$root/config/hypr/scripts/bar-preferences" set density full
"$root/config/hypr/scripts/bar-preferences" set module.media false
"$root/config/hypr/scripts/bar-preferences" monitor TEST-1 compact
"$root/config/hypr/scripts/bar-preferences" monitor-module TEST-1 media true
jq -e '.density == "full" and .modules.media == false and .monitors["TEST-1"].density == "compact" and .monitors["TEST-1"].modules.media == true' \
  "$XDG_CONFIG_HOME/nocturne/bar.json" >/dev/null

cp -- "$root/config/hypr/scripts/context-engine" "$XDG_CONFIG_HOME/hypr/scripts/context-engine"
printf '%s\n' '{"enabled":false,"contexts":{"docked":"desk"}}' > "$XDG_CONFIG_HOME/nocturne/context.json"
"$XDG_CONFIG_HOME/hypr/scripts/context-engine" assign meeting calls
"$XDG_CONFIG_HOME/hypr/scripts/context-engine" assign mobile commute
jq -e '.format == "nocturne-context-v2" and .contexts.docked == "desk" and .profiles.meeting == "calls"' \
  "$XDG_CONFIG_HOME/nocturne/context.json" >/dev/null
"$XDG_CONFIG_HOME/hypr/scripts/context-engine" decision \
  | jq -e '.enabled == false and .context == "mobile" and .selectedScene == "commute" and .reason == "context:mobile"' >/dev/null

"$root/bin/nocturne-migrate" --json | jq -e '.ready == true and .schema == 5' >/dev/null
trace="$root/config/hypr/scripts/automation-trace"
"$trace" record context scene-applied profile:meeting calls 'Settings only.'
"$trace" record context baseline-restored no-matching-scene calls 'Reversed.'
"$trace" list 10 | jq -e 'length == 2 and .[0].event == "baseline-restored" and .[1].event == "scene-applied"' >/dev/null
"$trace" status | jq -e '.format == "nocturne-trace-v1" and .count == 2 and .privacy.content == false' >/dev/null
"$trace" clear
"$trace" list | jq -e 'length == 0' >/dev/null

mkdir -p "$XDG_CONFIG_HOME/nocturne/scenes" "$HOME/.local/bin"
printf '%s\n' '{"name":"Obsidian Grid"}' > "$XDG_CONFIG_HOME/nocturne/theme.json"
printf '%s\n' '{"format":"nocturne-scene-v1","name":"Focus","created":"2026-10-05T12:00:00-04:00","workspace":1,"windows":[{"class":"kitty","workspace":1,"desktop":"/apps/kitty.desktop"},{"class":"code","workspace":2,"desktop":"/apps/code.desktop"}],"monitors":[{"name":"TEST-1"}],"settings":{"profile":"performance","sink":"sink-a","source":"mic-b","wallpaper":"/wallpapers/focus.png","theme":"Copper Blue"}}' \
  > "$XDG_CONFIG_HOME/nocturne/scenes/focus.json"
printf '%s\n' '#!/bin/sh' 'printf '\''[{"mapped":true,"class":"kitty"}]\n'\''' > "$test_root/bin/hyprctl"
printf '%s\n' '#!/bin/sh' 'printf '\''balanced\n'\''' > "$test_root/bin/powerprofilesctl"
printf '%s\n' '#!/bin/sh' 'case "$1 $2" in "get-default-sink ") printf '\''sink-a\n'\'' ;; "get-default-source ") printf '\''mic-a\n'\'' ;; esac' > "$test_root/bin/pactl"
printf '%s\n' '#!/bin/sh' 'printf '\''{"current":"/wallpapers/current.png"}\n'\''' > "$HOME/.local/bin/nocturne-wallpaper-cycle"
chmod +x "$test_root/bin/hyprctl" "$test_root/bin/powerprofilesctl" "$test_root/bin/pactl" "$HOME/.local/bin/nocturne-wallpaper-cycle"
PATH="$test_root/bin:$PATH" "$root/config/hypr/scripts/scene-manager" preview focus \
  | jq -e '.format == "nocturne-scene-preview-v1" and .apps == 2 and .appsToLaunch == 1 and .windows == 2 and .settingsChanges == 4' >/dev/null

NOCTURNE_CAMERA_DEVICE="$test_root/missing-camera" \
  "$root/config/hypr/scripts/camera-control" status \
  | jq -e '.available == false and .idleCost == "0 processes · hardware controls persist in sensor"' >/dev/null
"$root/bin/nocturne-doctor" --help | grep -Fq -- '--json'
printf 'NOCTURNE // shell interaction contracts passed\n'
