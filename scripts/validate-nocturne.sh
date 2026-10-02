#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT

printf 'NOCTURNE // SOURCE VALIDATION\n'

while IFS= read -r script; do
  bash -n "$script"
done < <(
  find "$root/config/hypr/scripts" "$root/scripts" "$root/bin" \
    -maxdepth 1 -type f -executable -print0 \
    | xargs -0 -r file \
    | awk -F: '/shell script/ {print $1}'
)
printf '[ OK ] shell scripts\n'

jq -e . "$root/config/waybar/config.jsonc" >/dev/null
jq -e . "$root/config/swaync/config.json" >/dev/null
printf '[ OK ] JSON configuration\n'

PYTHONPYCACHEPREFIX="$temporary/pycache" python3 -m py_compile \
  "$root/bin/nocturne-calendar" \
  "$root/bin/nocturne-power-card" \
  "$root/bin/nocturne-settings-app"
printf '[ OK ] Python surfaces\n'

Hyprland --verify-config --config "$root/config/hypr/hyprland.lua" \
  >"$temporary/hyprland-verify.log" 2>&1
grep -q 'config ok' "$temporary/hyprland-verify.log"
printf '[ OK ] Hyprland Lua configuration\n'

grep -Fq 'start-hyprland -- --config %h/.config/hypr/hyprland.lua' \
  "$root/config/systemd/user/wayland-wm@hyprland.desktop.service.d/90-nocturne.conf"
grep -Fq 'hyprcapture-supervisor' "$root/patches/hyprcapture-supervisor.patch"
printf '[ OK ] explicit Lua startup + pinned capture patch\n'

jq -e '
  .[] | select(.name == "main") |
  ((."modules-right" | map(select(. == "custom/wifi")) | length) == 1) and
  ((."modules-right" | map(select(. == "custom/bluetooth")) | length) == 1) and
  ((."modules-right" | index("network")) == null) and
  ((."modules-right" | index("bluetooth")) == null) and
  (."modules-right"[-1] == "group/tray-expander")
' "$root/config/waybar/config.jsonc" >/dev/null
printf '[ OK ] one visible connectivity owner + far-right tray\n'

(
  cd "$root/agent"
  PYTHONPATH=src python3 -m pytest -q
)

git -C "$root" diff --check
printf '[ OK ] patch hygiene\n'
printf 'RESULT // source tree is internally consistent\n'
