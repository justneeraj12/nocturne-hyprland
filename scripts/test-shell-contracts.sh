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
jq -e '.format == "nocturne-context-v2" and .contexts.docked == "desk" and .profiles.meeting == "calls"' \
  "$XDG_CONFIG_HOME/nocturne/context.json" >/dev/null

"$root/bin/nocturne-migrate" --json | jq -e '.ready == true and .schema == 5' >/dev/null
NOCTURNE_CAMERA_DEVICE="$test_root/missing-camera" \
  "$root/config/hypr/scripts/camera-control" status \
  | jq -e '.available == false and .idleCost == "0 processes · hardware controls persist in sensor"' >/dev/null
"$root/bin/nocturne-doctor" --help | grep -Fq -- '--json'
printf 'NOCTURNE // shell interaction contracts passed\n'
