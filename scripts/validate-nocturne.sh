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
  "$root/bin/nocturne-panel" \
  "$root/bin/nocturne-capture" \
  "$root/bin/nocturne-power-card" \
  "$root/bin/nocturne-settings-app"
printf '[ OK ] Python surfaces\n'

"$root/bin/nocturne-panel" --self-test >/dev/null
"$root/bin/nocturne-capture" --self-test >/dev/null
grep -Fq 'elif panel == "brightness"' "$root/bin/nocturne-panel"
grep -Fq 'elif panel == "calendar"' "$root/bin/nocturne-panel"
grep -Fq 'elif panel == "world"' "$root/bin/nocturne-panel"
! grep -Fq 'ESC OR CLICK OUTSIDE TO CLOSE' "$root/bin/nocturne-panel"
! grep -Fq 'footer.append(self._button("󰍬  MIC"' "$root/bin/nocturne-panel"
[[ ! -e $root/bin/nocturne-calendar && ! -e $root/config/hypr/scripts/clock-menu ]]
printf '[ OK ] anchored panel model\n'

Hyprland --verify-config --config "$root/config/hypr/hyprland.lua" \
  >"$temporary/hyprland-verify.log" 2>&1
grep -q 'config ok' "$temporary/hyprland-verify.log"
printf '[ OK ] Hyprland Lua configuration\n'

grep -Fq 'start-hyprland -- --config %h/.config/hypr/hyprland.lua' \
  "$root/config/systemd/user/wayland-wm@hyprland.desktop.service.d/90-nocturne.conf"
grep -Fq 'nocturne-capture toggle' "$root/config/hypr/hyprland.lua"
! grep -Fq 'HyprCapture' "$root/config/hypr/hyprland.lua"
[[ ! -e $root/config/hypr/hyprcapture.lua ]]
[[ ! -e $root/scripts/install-hyprcapture.sh ]]
printf '[ OK ] explicit Lua startup + native capture owner\n'

jq -e '
  .[] | select(.name == "main") |
  ((."modules-right" | map(select(. == "custom/connectivity")) | length) == 1) and
  ((."modules-right" | index("network")) == null) and
  ((."modules-right" | index("bluetooth")) == null) and
  (."custom/connectivity"."on-click" == "~/.local/bin/nocturne-panel toggle connectivity wifi") and
  (.pulseaudio."on-click" == "~/.local/bin/nocturne-panel toggle audio") and
  (."custom/brightness"."on-click" == "~/.local/bin/nocturne-panel toggle brightness") and
  (."custom/local-clock"."on-click" == "~/.local/bin/nocturne-panel toggle calendar") and
  (."custom/world"."on-click" == "~/.local/bin/nocturne-panel toggle world") and
  ((."modules-right" | index("group/tray-expander")) + 1 == (."modules-right" | index("custom/kdeconnect")))
' "$root/config/waybar/config.jsonc" >/dev/null
printf '[ OK ] unified panels + tray left of KDE Connect\n'

grep -Fq 'wofi --show drun' "$root/config/hypr/scripts/launcher"
! grep -Fq 'hyprlauncher -d' "$root/config/hypr/hyprland.lua"
grep -Fq 'boost) start_boost' "$root/config/hypr/scripts/power-profile"
grep -Fq 'SUPER' "$root/bin/nocturne-power-card"
printf '[ OK ] zero-idle launcher + timed Super Performance control\n'

(
  cd "$root/agent"
  PYTHONPATH=src python3 -m pytest -q
)

git -C "$root" diff --check
printf '[ OK ] patch hygiene\n'
printf 'RESULT // source tree is internally consistent\n'
