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

jq -e . "$root/config/locations.json" "$root/config/nocturne/theme.json" >/dev/null
printf '[ OK ] JSON configuration\n'

PYTHONPYCACHEPREFIX="$temporary/pycache" python3 -m py_compile "$root/bin/nocturne-capture-engine"
"$root/bin/nocturne-capture-engine" --self-test >/dev/null
printf '[ OK ] headless capture engine\n'

cmake -S "$root/native" -B "$temporary/native" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$temporary/native" --parallel >/dev/null
"$temporary/native/nocturne-native" --self-test >/dev/null
! rg -q 'import gi|from gi|Gtk' "$root/native" "$root/bin"
grep -Fq 'backend.audioStreams()' "$root/native/qml/pages/AudioPage.qml"
grep -Fq 'interval: 200' "$root/native/qml/pages/BrightnessPage.qml"
grep -Fq 'LayerShellQt.Window.AnchorTop' "$root/native/qml/Shell.qml"
grep -Fq 'LayerShellQt.Window.scope: "nocturne-bar"' "$root/native/qml/BarWindow.qml"
grep -Fq 'org.kde.StatusNotifierWatcher' "$root/native/src/traywatcher.h"
grep -Fq 'backend.notifications("history")' "$root/native/qml/pages/NotificationsPage.qml"
grep -Fq 'QQuickImageProvider' "$root/native/src/main.cpp"
grep -Fq 'image://theme/' "$root/native/qml/pages/BackgroundPage.qml"
grep -Fq 'property string tab: "current"' "$root/native/qml/pages/NotificationsPage.qml"
grep -Fq 'result.size() == 3' "$root/native/src/backend.cpp"
grep -Fq 'displayApp' "$root/native/qml/pages/NotificationsPage.qml"
grep -Fq 'NocturneToggle' "$root/native/qml/pages/ConnectivityPage.qml"
grep -Fq 'onInitialPageChanged' "$root/native/qml/pages/ConnectivityPage.qml"
grep -Fq 'PanelHeader' "$root/native/qml/pages/AudioPage.qml"
grep -Fq 'PanelHeader' "$root/native/qml/pages/PowerPage.qml"
grep -Fq 'displayHour = hours % 12' "$root/native/qml/BarWindow.qml"
grep -Fq 'Layout.preferredWidth: 42' "$root/native/qml/pages/WorldPage.qml"
grep -Fq '{{mpris:length}}' "$root/native/qml/pages/MediaPage.qml"
printf '[ OK ] Qt/Wayland native shell + live controls\n'

Hyprland --verify-config --config "$root/config/hypr/hyprland.lua" \
  >"$temporary/hyprland-verify.log" 2>&1
grep -q 'config ok' "$temporary/hyprland-verify.log"
! rg -q 'hyprctl dispatch (workspace|focuswindow|closewindow|movetoworkspace|movetoworkspacesilent|togglefloating|dpms|cyclenext|bringactivetotop)' \
  "$root/config" "$root/bin" "$root/native"
grep -Fq 'hl.dsp.focus({ workspace' "$root/native/qml/BarWindow.qml"
printf '[ OK ] Hyprland Lua configuration\n'

grep -Fq 'start-hyprland -- --config %h/.config/hypr/hyprland.lua' \
  "$root/config/systemd/user/wayland-wm@hyprland.desktop.service.d/90-nocturne.conf"
grep -Fq 'nocturne-native capture' "$root/config/hypr/hyprland.lua"
! grep -Fq 'HyprCapture' "$root/config/hypr/hyprland.lua"
[[ ! -e $root/config/hypr/hyprcapture.lua ]]
[[ ! -e $root/scripts/install-hyprcapture.sh ]]
printf '[ OK ] explicit Lua startup + native capture owner\n'

grep -Fq 'nocturne-native" bar' "$root/config/hypr/scripts/bar"
grep -Fq 'nativeCard("connectivity", "wifi")' "$root/native/qml/BarWindow.qml"
grep -Fq 'nativeCard("background", "")' "$root/native/qml/BarWindow.qml"
grep -Fq 'nativeCard("notifications", "")' "$root/native/qml/BarWindow.qml"
grep -Fq '"mako"' "$root/config/hypr/hyprland.lua"
grep -Fq 'default=kde' "$root/config/xdg-desktop-portal/hyprland-portals.conf"
! grep -Fq 'swaync-client' "$root/config/hypr/hyprland.lua"
printf '[ OK ] native bar, tray, notifications and Qt portal ownership\n'

grep -Fq 'nocturne-native" launcher' "$root/config/hypr/scripts/launcher"
grep -Fq 'backend.applications("")' "$root/native/qml/pages/LauncherPage.qml"
! rg -q 'wofi --show drun' "$root/config/hypr/scripts/launcher"
! grep -Fq 'hyprlauncher -d' "$root/config/hypr/hyprland.lua"
grep -Fq 'boost) start_boost' "$root/config/hypr/scripts/power-profile"
grep -Fq 'label:"SUPER"' "$root/native/qml/pages/PowerPage.qml"
printf '[ OK ] zero-idle launcher + timed Super Performance control\n'

(
  cd "$root/agent"
  PYTHONPATH=src python3 -m pytest -q
)

git -C "$root" diff --check
printf '[ OK ] patch hygiene\n'
printf 'RESULT // source tree is internally consistent\n'
