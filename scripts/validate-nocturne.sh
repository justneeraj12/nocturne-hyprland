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

"$root/scripts/test-install-contracts.sh" >/dev/null
printf '[ OK ] installer + rollback symmetry\n'

jq -e . "$root/config/locations.json" "$root/config/nocturne/theme.json" "$root/config/nocturne/bar.json" >/dev/null
jq -e . "$root/agent/config/profile.default.json" >/dev/null
printf '[ OK ] JSON configuration\n'

grep -Fq 'docs/screenshots/noc-banner.webp' "$root/README.md"
grep -Fq 'Nocturne Trace' "$root/README.md"
grep -Fq 'Explainable continuity' "$root/docs/RELEASE-0.8.md"
grep -Fq '# Camera quality and latency' "$root/docs/CAMERA.md"
[[ $(grep -Ec '^[0-9]+\. ' "$root/docs/RELEASE-0.7.md") -eq 50 ]]
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
[[ -s $root/docs/screenshots/settings.webp ]]
[[ -s $root/docs/screenshots/efficiency.webp ]]
printf '[ OK ] public documentation + showcase assets\n'

cmake -S "$root/native" -B "$temporary/native" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$temporary/native" --parallel >/dev/null
"$temporary/native/nocturne-native" --self-test >/dev/null
"$root/scripts/test-ui-components.sh" "$temporary/native/nocturne-native" >/dev/null
grep -Fq -- '--tray-menu-test' "$root/native/src/main.cpp"
grep -Fq -- '--capture-test' "$root/native/src/main.cpp"
grep -Fq -- '--component-test' "$root/native/src/main.cpp"
grep -Fq -- '--settings-test' "$root/native/src/main.cpp"
! rg -q 'import gi|from gi|Gtk' "$root/native" "$root/bin"
grep -Fq 'backend.audioStreams()' "$root/native/qml/pages/AudioPage.qml"
grep -Fq 'interval: 200' "$root/native/qml/pages/BrightnessPage.qml"
grep -Fq 'NIGHT SHIFT' "$root/native/qml/pages/BrightnessPage.qml"
grep -Fq 'connection.metered' "$root/native/qml/pages/ConnectivityPage.qml"
grep -Fq 'SYSTEM PACKAGES' "$root/native/qml/pages/MaintenancePage.qml"
grep -Fq 'SAVE LAYOUT' "$root/native/qml/pages/DisplayPage.qml"
grep -Fq 'qml/pages/SetupSettingsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/EfficiencySettingsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/CameraPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/AutomationPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'ADAPTIVE SENSOR PROFILE' "$root/native/qml/pages/CameraPage.qml"
grep -Fq 'camera-control' "$root/native/qml/pages/CameraPage.qml"
grep -Fq 'PRIVATE BY DESIGN' "$root/native/qml/pages/AutomationPage.qml"
grep -Fq 'Nocturne Trace' "$root/native/qml/pages/AutomationPage.qml"
grep -Fq 'TOP MEMORY CONSUMERS' "$root/native/qml/pages/EfficiencySettingsPage.qml"
grep -Fq 'find "$thumbnail_root" -type f -mtime +30 -delete' "$root/config/hypr/scripts/efficiency-control"
grep -Fq 'barRssMiB' "$root/config/hypr/scripts/efficiency-control"
grep -Fq 'event.contains(" on sink-input #")' "$root/native/src/backend.cpp"
grep -Fq 'node.name = \"xdph-streaming-' "$root/native/src/backend.cpp"
grep -Fq 'backend.notificationCount()' "$root/native/qml/Bar.qml"
grep -Fq 'text: "󰖨"' "$root/native/qml/BarWindow.qml"
grep -Fq 'END IN SHARING APP' "$root/native/qml/pages/PrivacyPage.qml"
grep -Fq 'SAFETY + PORTABILITY' "$root/native/qml/pages/SetupSettingsPage.qml"
grep -Fq 'Accessible.role: Accessible.Button' "$root/native/qml/components/BarButton.qml"
grep -Fq 'Accessible.role: Accessible.CheckBox' "$root/native/qml/components/NocturneToggle.qml"
grep -Fq 'CONFIRM CLEAR' "$root/native/qml/pages/ClipboardPage.qml"
grep -Fq 'pendingSessionAction' "$root/native/qml/pages/PowerPage.qml"
grep -Fq 'LayerShellQt.Window.AnchorTop' "$root/native/qml/Shell.qml"
grep -Fq 'LayerShellQt.Window.scope: "nocturne-bar"' "$root/native/qml/BarWindow.qml"
! grep -Fq 'targetScreen.name === "HDMI-A-1"' "$root/native/qml/BarWindow.qml"
grep -Fq 'readonly property real responsiveWidth:' "$root/native/qml/BarWindow.qml"
grep -Fq 'readonly property int density:' "$root/native/qml/BarWindow.qml"
grep -Fq 'Q_PROPERTY(QVariantList screens READ screens NOTIFY screensChanged)' "$root/native/src/backend.h"
grep -Fq 'void shellEvent(const QString &topic)' "$root/native/src/backend.h"
grep -Fq 'QLocalSocket::readyRead' "$root/native/src/backend.cpp"
grep -Fq 'org.kde.StatusNotifierWatcher' "$root/native/src/traywatcher.h"
grep -Fq 'activateTrayMenuItem' "$root/native/src/backend.cpp"
grep -Fq 'backend.notifications("history")' "$root/native/qml/pages/NotificationsPage.qml"
grep -Fq 'QQuickImageProvider' "$root/native/src/main.cpp"
grep -Fq 'image://theme/' "$root/native/qml/pages/BackgroundPage.qml"
grep -Fq 'property string tab: "current"' "$root/native/qml/pages/NotificationsPage.qml"
grep -Fq 'result.size() == 12' "$root/native/src/backend.cpp"
grep -Fq 'steam://open/main' "$root/native/src/backend.cpp"
grep -Fq 'if (backend.activateTrayItem(item.reference, action)) backend.close()' "$root/native/qml/pages/BackgroundPage.qml"
grep -Fq 'shell.tray.length' "$root/native/qml/BarWindow.qml"
grep -Fq 'displayApp' "$root/native/qml/pages/NotificationsPage.qml"
grep -Fq 'NocturneToggle' "$root/native/qml/pages/ConnectivityPage.qml"
grep -Fq 'onInitialPageChanged' "$root/native/qml/pages/ConnectivityPage.qml"
grep -Fq 'PanelHeader' "$root/native/qml/pages/AudioPage.qml"
grep -Fq 'PanelHeader' "$root/native/qml/pages/PowerPage.qml"
grep -Fq 'displayHour = hours % 12' "$root/native/qml/BarWindow.qml"
grep -Fq 'nativeCard("maintenance", "")' "$root/native/qml/BarWindow.qml"
grep -Fq 'nativeCard("display", "")' "$root/native/qml/BarWindow.qml"
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
grep -Fq 'class = "^(Chatgpt)$"' "$root/config/hypr/hyprland.lua"
grep -Fq 'no_blur = true' "$root/config/hypr/hyprland.lua"
grep -Fq 'class = "^(hyprland-share-picker)$"' "$root/config/hypr/hyprland.lua"
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

grep -Fq 'profile {' "$root/config/hypr/hyprsunset.conf"
grep -Fq 'hyprctl hyprsunset temperature' "$root/config/hypr/scripts/night-light"
grep -Fq 'hyprctl keyword monitor' "$root/config/hypr/scripts/monitor-layout"
grep -Fq 'fwupdmgr get-updates' "$root/config/hypr/scripts/system-maintenance"
grep -Fq 'nocturne-portable-v1' "$root/bin/nocturne-portable"
HOME="$temporary/portable-home" XDG_CONFIG_HOME="$temporary/portable-config" \
  "$root/bin/nocturne-portable" status | jq -e '.exists == false' >/dev/null
printf '[ OK ] night shift, display, maintenance and portable setup controls\n'

grep -Fq 'nocturne-native" launcher' "$root/config/hypr/scripts/launcher"
grep -Fq 'backend.launcherResults(search.text, mode)' "$root/native/qml/pages/LauncherPage.qml"
grep -Fq 'activateLauncherResult' "$root/native/src/backend.cpp"
! rg -q 'wofi --show drun' "$root/config/hypr/scripts/launcher"
! grep -Fq 'hyprlauncher -d' "$root/config/hypr/hyprland.lua"
grep -Fq 'boost) start_boost' "$root/config/hypr/scripts/power-profile"
grep -Fq 'label:"SUPER"' "$root/native/qml/pages/PowerPage.qml"
grep -Fq 'nocturne-game-session.service' "$root/apply-hyprland.sh"
grep -Fq 'UNIX-CONNECT:' "$root/config/hypr/scripts/game-session"
grep -Fq 'focus-mode' "$root/native/qml/pages/NotificationsPage.qml"
grep -Fq 'qml/pages/OsdPage.qml' "$root/native/CMakeLists.txt"
printf '[ OK ] command-center launcher + focus, gaming and native OSD controls\n'

grep -Fq 'qml/pages/SystemSettingsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/IntegrationsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/OverviewSettingsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/AppearanceSettingsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/BarSettingsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'Bar Studio' "$root/native/qml/Settings.qml"
grep -Fq 'qml/components/SettingsNavItem.qml' "$root/native/CMakeLists.txt"
grep -Fq 'INPUT + APPLICATIONS' "$root/native/qml/pages/SystemSettingsPage.qml"
grep -Fq 'MACHINE + SERVICES' "$root/native/qml/pages/IntegrationsPage.qml"
grep -Fq 'Ctrl+K' "$root/native/qml/Settings.qml"
grep -Fq 'revealSelectedSection' "$root/native/qml/Settings.qml"
grep -Fq 'OnlyShowIn' "$root/native/src/backend.cpp"
grep -Fq 'NotShowIn' "$root/native/src/backend.cpp"
grep -Fq 'system-preferences' "$root/native/qml/pages/SystemSettingsPage.qml"
for desktop in org.gnome.Settings kdesystemsettings systemsettings nwg-look qt6ct hyprpwcenter; do
  grep -Fq 'Hidden=true' "$root/config/applications/$desktop.desktop"
done
printf '[ OK ] unified native system settings + launcher ownership\n'

[[ -x $root/bin/nocturne-files ]]
grep -Fq 'QT_QPA_PLATFORMTHEME=kde' "$root/bin/nocturne-files"
grep -Fq 'widgetStyle=Breeze' "$root/config/kdeglobals"
grep -Fq 'PreviewSize=96' "$root/config/dolphin/dolphinrc.in"
grep -Fq 'PreviewsShown=true' "$root/config/dolphin/view_properties/global/.directory"
grep -Fq 'org.kde.dolphin.desktop inode/directory' "$root/apply-hyprland.sh"
grep -Fq 'kde-baloo.service' "$root/apply-hyprland.sh"
grep -Fq 'Nocturne Files uses clean tabs' "$root/native/qml/pages/SystemSettingsPage.qml"
printf '[ OK ] Nocturne Files profile, previews and zero-idle indexing\n'

for page in OverviewPage ScenesPage PrivacyPage GamingPage; do
  grep -Fq "qml/pages/$page.qml" "$root/native/CMakeLists.txt"
done
grep -Fq 'hl.bind(mod .. " + Tab"' "$root/config/hypr/hyprland.lua"
grep -Fq 'nocturne-scene-v1' "$root/config/hypr/scripts/scene-manager"
grep -Fq 'nocturne-trace-v1' "$root/config/hypr/scripts/automation-trace"
grep -Fq 'context scene-applied' "$root/config/hypr/scripts/context-engine"
grep -Fq 'nocturne-audio-scene-v1' "$root/config/hypr/scripts/audio-scene"
grep -Fq 'OnUnitActiveSec=30s' "$root/config/systemd/user/nocturne-context.timer"
grep -Fq 'baseline_name=.context-baseline' "$root/config/hypr/scripts/context-engine"
grep -Fq 'invisible=1' "$root/config/hypr/scripts/notification-rules"
grep -Fq 'last-good.tar.gz' "$root/bin/nocturne-recovery"
grep -Fq 'schema-version' "$root/bin/nocturne-migrate"
grep -Fq 'rapid_failures' "$root/config/hypr/scripts/bar"
grep -Fq 'nocturne-session-health.service' "$root/apply-hyprland.sh"
grep -Fq 'nocturne-session-health.timer' "$root/apply-hyprland.sh"
grep -Fq 'Meeting share chooser is compact, floating and pinned' "$root/bin/nocturne-doctor"
grep -Fq 'On-demand efficiency telemetry is installed' "$root/bin/nocturne-doctor"
grep -Fq 'nocturne-doctor-v1' "$root/bin/nocturne-doctor"
grep -Fq 'Install v4l-utils to enable Nocturne camera profiles' "$root/bin/nocturne-doctor"
grep -Fq 'personalFiles:false' "$root/bin/nocturne-support"
grep -Fq 'install -m 0755 "$ROOT_DIR/bin/nocturne-support"' "$root/apply-hyprland.sh"
grep -Fq 'theme-studio' "$root/native/qml/pages/AppearanceSettingsPage.qml"
grep -Fq 'Q_INVOKABLE QVariantList privacyItems' "$root/native/src/backend.h"
printf '[ OK ] overview, scenes, automation, privacy, gaming, themes and recovery\n'

grep -Fq 'systemctl --user restart nocturne-wallpaper-cycle.service' "$root/config/hypr/hyprland.lua"
grep -Fq 'if desired and monitors and' "$root/bin/nocturne-wallpaper-cycle"
! grep -Fq 'WantedBy=default.target' "$root/config/systemd/user/nocturne-wallpaper-cycle.service"
printf '[ OK ] compositor-owned wallpaper startup and reboot recovery\n'

"$root/scripts/test-shell-contracts.sh" >/dev/null
printf '[ OK ] migrations, bar preferences and context interaction contracts\n'

grep -Fq '__NV_PRIME_RENDER_OFFLOAD=1' "$root/config/hypr/scripts/steam-launch"
grep -Fq '__VK_LAYER_NV_optimus=NVIDIA_only' "$root/config/hypr/scripts/steam-launch"
grep -Fq 'VK_LOADER_DRIVERS_SELECT=*nvidia*' "$root/config/hypr/scripts/steam-launch"
grep -Fq -- '--verify-gpu' "$root/config/hypr/scripts/steam-launch"
grep -Fq 'PrefersNonDefaultGPU=true' "$root/assets/nocturne-steam.desktop.in"
grep -Fq 'nocturne-steam" "$BIN_HOME/steam"' "$root/apply-hyprland.sh"
grep -Fq 'Exec=$BIN_HOME/steam steam://rungameid/' "$root/apply-hyprland.sh"
grep -Fq 'Exec=steam steam://rungameid/' "$root/uninstall.sh"
grep -Fq 'PATH=${HOME}/.local/bin:$PATH' "$root/config/environment.d/10-nocturne-path.conf"
grep -Fq '*":$HOME/.local/bin:"*)' "$root/config/hypr/scripts/bar"
printf '[ OK ] fail-closed NVIDIA Steam offload\n'

grep -Fq -- '--password-store=gnome-libsecret' "$root/bin/nocturne-signal"
grep -Fq 'flatpak_profile=' "$root/bin/nocturne-signal"
grep -Fq 'nocturne-signal.desktop.in' "$root/apply-hyprland.sh"
grep -Fq 'x-scheme-handler/sgnl' "$root/assets/nocturne-signal.desktop.in"
grep -Fq 'Signal uses the preserved profile' "$root/bin/nocturne-doctor"
printf '[ OK ] Signal keyring and profile routing\n'

grep -Fq 'AcceleratedVideoDecodeLinuxGL' "$root/bin/nocturne-browser"
grep -Fq 'AcceleratedVideoDecodeLinuxZeroCopyGL' "$root/bin/nocturne-browser"
grep -Fq 'nocturne-browser" "$BIN_HOME/nocturne-browser"' "$root/apply-hyprland.sh"
grep -Fq 'intel-media-va-driver vainfo intel-gpu-tools' "$root/install.sh"
grep -Fq 'Hardware video decode profiles are available' "$root/bin/nocturne-doctor"
printf '[ OK ] native Wayland browser video acceleration\n'

(
  cd "$root/agent"
  PYTHONPATH=src python3 -m pytest -q
)

git -C "$root" diff --check
printf '[ OK ] patch hygiene\n'
printf 'RESULT // source tree is internally consistent\n'
