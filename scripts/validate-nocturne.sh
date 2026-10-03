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
jq -e . "$root/agent/config/profile.default.json" >/dev/null
printf '[ OK ] JSON configuration\n'

grep -Fq 'docs/screenshots/noc-banner.webp' "$root/README.md"
grep -Fq '~/.local/state/nocturne/backups/' "$root/docs/INSTALL.md"
grep -Fq 'original-preinstall-backup' "$root/apply-hyprland.sh"
grep -Fq 'Type RESTORE to continue' "$root/uninstall.sh"
grep -Fq 'branding/noc-terminal.txt' "$root/apply-hyprland.sh"
grep -Fq '~/.config/fastfetch/noc.txt' "$root/config/fastfetch/config.jsonc"
[[ -s $root/docs/screenshots/hero.webp ]]
[[ -s $root/docs/screenshots/noc-banner.webp ]]
[[ -s $root/docs/screenshots/lockscreen.webp ]]
[[ -s $root/docs/screenshots/terminal.webp ]]
[[ -s $root/docs/screenshots/quick-controls.webp ]]
[[ -s $root/docs/screenshots/launcher.webp ]]
printf '[ OK ] public documentation + showcase assets\n'

cmake -S "$root/native" -B "$temporary/native" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$temporary/native" --parallel >/dev/null
"$temporary/native/nocturne-native" --self-test >/dev/null
! rg -q 'import gi|from gi|Gtk' "$root/native" "$root/bin"
grep -Fq 'backend.audioStreams()' "$root/native/qml/pages/AudioPage.qml"
grep -Fq 'interval: 200' "$root/native/qml/pages/BrightnessPage.qml"
grep -Fq 'LayerShellQt.Window.AnchorTop' "$root/native/qml/Shell.qml"
grep -Fq 'LayerShellQt.Window.scope: "nocturne-bar"' "$root/native/qml/BarWindow.qml"
! grep -Fq 'targetScreen.name === "HDMI-A-1"' "$root/native/qml/BarWindow.qml"
grep -Fq 'readonly property real responsiveWidth:' "$root/native/qml/BarWindow.qml"
grep -Fq 'readonly property int density:' "$root/native/qml/BarWindow.qml"
grep -Fq 'Q_PROPERTY(QVariantList screens READ screens NOTIFY screensChanged)' "$root/native/src/backend.h"
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
grep -Fq 'current-location.json' "$root/native/qml/pages/WorldPage.qml"
grep -Fq 'key: "@current"' "$root/config/hypr/scripts/current-location"
grep -Fq 'nocturne/monitors.lua' "$root/config/hypr/hyprland.lua"
! rg -q 'hl.monitor\(\{ output = "(eDP|HDMI|DP)-' "$root/config/hypr/hyprland.lua"
jq -e '[.weather_locations[].label] == ["NYC", "London", "Tokyo"]' \
  "$root/config/locations.json" >/dev/null
jq -e '.system.os == "Linux" and .defaults.browser == "Firefox" and
  (.system.device | startswith("Configure "))' \
  "$root/agent/config/profile.default.json" >/dev/null
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
grep -Fq '/.local/bin/hyprshot -o ' "$root/config/hypr/hyprland.lua"
grep -Fq 'hl.bind("Print", run(hyprshot .. " -m region"))' "$root/config/hypr/hyprland.lua"
grep -Fq 'hl.bind("SHIFT + Print", run(hyprshot .. " -m window"))' "$root/config/hypr/hyprland.lua"
grep -Fq 'hl.bind("CTRL + Print", run(hyprshot .. " -m output"))' "$root/config/hypr/hyprland.lua"
grep -Fq 'flatpak run io.github.seadve.Kooha' "$root/config/hypr/hyprland.lua"
grep -Fq 'readonly version=1.3.0' "$root/scripts/install-hyprshot.sh"
grep -Fq 'io.github.seadve.Kooha' "$root/scripts/install-kooha.sh"
! rg -q 'nocturne-capture|CapturePage|Freeze.qml|wf-recorder|hyprpicker' \
  "$root/native" "$root/bin" "$root/config/hypr"
grep -Fq 'function dismiss()' "$root/native/qml/Shell.qml"
! grep -Fq 'HyprCapture' "$root/config/hypr/hyprland.lua"
[[ ! -e $root/config/hypr/hyprcapture.lua ]]
[[ ! -e $root/scripts/install-hyprcapture.sh ]]
printf '[ OK ] explicit Lua startup + upstream capture applications\n'

grep -Fq 'nocturne-native" bar' "$root/config/hypr/scripts/bar"
grep -Fq 'nativeCard("connectivity", "wifi")' "$root/native/qml/BarWindow.qml"
grep -Fq 'nativeCard("background", "")' "$root/native/qml/BarWindow.qml"
grep -Fq 'nativeCard("notifications", "")' "$root/native/qml/BarWindow.qml"
grep -Fq '"mako"' "$root/config/hypr/hyprland.lua"
grep -Fq 'app-update\x2dnotifier@autostart.service' "$root/apply-hyprland.sh"
grep -Fq 'mako.service' "$root/apply-hyprland.sh"
grep -Fq 'mako.service' "$root/uninstall.sh"
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
