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

[[ -x $root/scripts/test-clean-home-install.sh ]]
grep -Fq 'nocturne-welcome' "$root/scripts/test-clean-home-install.sh"
grep -Fq 'clean-home install and rollback passed' "$root/scripts/test-clean-home-install.sh"

[[ -x $root/scripts/build-release-bundle.sh ]]
grep -Fq 'gzip -n -9' "$root/scripts/build-release-bundle.sh"
grep -Fq 'gh release upload' "$root/.github/workflows/release.yml"

jq -e . "$root/config/locations.json" "$root/config/nocturne/theme.json" "$root/config/nocturne/bar.json" "$root/config/nocturne/edition.json" >/dev/null
jq -e '.edition == "community" and .analytics == false and .telemetryEndpoint == null and .operatorOverlay == false' "$root/config/nocturne/edition.json" >/dev/null
jq -e . "$root/agent/config/profile.default.json" >/dev/null
printf '[ OK ] JSON configuration\n'

grep -Fq 'docs/screenshots/noc-banner.webp' "$root/README.md"
grep -Fq 'Nocturne Trace' "$root/README.md"
grep -Fq 'Explainable continuity' "$root/docs/RELEASE-0.8.md"
grep -Fq 'Local workflow memory' "$root/docs/RELEASE-0.9.md"
[[ $(grep -Ec '^[0-9]+\. ' "$root/docs/RELEASE-0.9.md") -eq 44 ]]
grep -Fq 'Fifty workflow upgrades' "$root/docs/RELEASE-1.0.md"
[[ $(grep -Ec '^[0-9]+\. ' "$root/docs/RELEASE-1.0.md") -eq 50 ]]
grep -Fq 'Fifty system upgrades' "$root/docs/RELEASE-1.1.md"
[[ $(grep -Ec '^[0-9]+\. ' "$root/docs/RELEASE-1.1.md") -eq 50 ]]
grep -Fq 'Nocturne 1.2 — NOC Core' "$root/docs/RELEASE-1.2.md"
grep -Fq '# NOC 2.0 product architecture' "$root/docs/NOC-2.0.md"
grep -Fq '# Hyprland community demand scan' "$root/docs/COMMUNITY-DEMAND-2026.md"
grep -Fq '# NOC 2.0 Alpha 1 — Foundation' "$root/docs/RELEASE-2.0-ALPHA1.md"
grep -Fq '# NOC 2.0 Alpha 2 — Arch portability' "$root/docs/RELEASE-2.0-ALPHA2.md"
grep -Fq 'Hyprland speed. Desktop continuity. No phone home.' "$root/docs/LAUNCH-KIT-2.0.md"
grep -Fq 'Nocturne Community does not phone home' "$root/PRIVACY.md"
grep -Fq 'NOC 2.0 is stable' "$root/README.md"
grep -Fq '# NOC 2.0 // First Signal' "$root/docs/RELEASE-2.0.md"
grep -Fq 'guided terminal installer' "$root/CHANGELOG.md"
[[ -x $root/bin/nocturne-welcome ]]
grep -Fq 'nocturne-welcome.service' "$root/config/systemd/user/nocturne-session.target"
grep -Fq 'SystemdService=mako.service' "$root/config/dbus-1/services/fr.emersion.mako.service"
grep -Fq 'nocturne-benchmark --summary' "$root/README.md"
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
[[ -s $root/docs/screenshots/noc-desk.webp ]]
[[ -s $root/docs/screenshots/noc-habits.webp ]]
[[ -s $root/docs/screenshots/noc-vault.webp ]]
[[ -s $root/docs/screenshots/storage-center.webp ]]
[[ -s $root/docs/screenshots/system-command.webp ]]
[[ -s $root/docs/screenshots/operations-deck.webp ]]
for asset in editorial center-signal noc-grid phosphor-terminal relay-split black-ice red-sector signal-tower mainframe dead-channel; do
  [[ -s $root/docs/screenshots/lock-$asset.webp ]]
done
[[ -s $root/docs/screenshots/lockscreen-gallery.webp ]]
grep -Fq 'lockscreen-gallery.webp' "$root/README.md"
for asset in noc-2-showcase-reel noc-2-onboarding noc-2-overview noc-2-appearance noc-2-display-lab noc-2-laptop-intelligence noc-2-connected-agenda noc-2-security-hub noc-2-efficiency noc-2-extensions; do
  [[ -s $root/docs/screenshots/$asset.webp ]]
done
[[ -s $root/docs/media/noc-2-community-labs.mp4 ]]
grep -Fq 'docs/media/noc-2-community-labs.mp4' "$root/README.md"
printf '[ OK ] public documentation + showcase assets\n'

cmake -S "$root/native" -B "$temporary/native" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$temporary/native" --parallel >/dev/null
"$temporary/native/nocturne-native" --self-test >/dev/null
"$root/scripts/test-ui-components.sh" "$temporary/native/nocturne-native" >/dev/null
grep -Fq -- '--tray-menu-test' "$root/native/src/main.cpp"
grep -Fq -- '--capture-test' "$root/native/src/main.cpp"
grep -Fq -- '--component-test' "$root/native/src/main.cpp"
grep -Fq -- '--settings-test' "$root/native/src/main.cpp"
grep -Fq -- '--launcher-query-test' "$root/native/src/main.cpp"
! rg -q 'import gi|from gi|Gtk' "$root/native" "$root/bin"
grep -Fq 'backend.audioStreams()' "$root/native/qml/pages/AudioPage.qml"
grep -Fq 'interval: 200' "$root/native/qml/pages/BrightnessPage.qml"
grep -Fq 'NIGHT SHIFT' "$root/native/qml/pages/BrightnessPage.qml"
grep -Fq 'connection.metered' "$root/native/qml/pages/ConnectivityPage.qml"
grep -Fq 'SYSTEM PACKAGES' "$root/native/qml/pages/MaintenancePage.qml"
grep -Fq 'SAVE LAYOUT' "$root/native/qml/pages/DisplayPage.qml"
grep -Fq 'qml/pages/SetupSettingsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/EfficiencySettingsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/PerformanceSettingsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/CampusSettingsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/CameraPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/AutomationPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/OperationsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/DeskPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/HabitsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/VaultPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/StorageSettingsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/SecuritySettingsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/ControlCenterSettingsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'qml/pages/AutomationRulesSettingsPage.qml' "$root/native/CMakeLists.txt"
grep -Fq 'ADAPTIVE SENSOR PROFILE' "$root/native/qml/pages/CameraPage.qml"
grep -Fq 'camera-control' "$root/native/qml/pages/CameraPage.qml"
grep -Fq 'PRIVATE BY DESIGN' "$root/native/qml/pages/AutomationPage.qml"
grep -Fq 'Nocturne Trace' "$root/native/qml/pages/AutomationPage.qml"
grep -Fq 'NOC // OPERATIONS DECK' "$root/native/qml/pages/OperationsPage.qml"
grep -Fq 'ZERO IDLE TELEMETRY' "$root/native/qml/pages/OperationsPage.qml"
grep -Fq 'NOC UPDATE GUARD' "$root/native/qml/pages/MaintenancePage.qml"
grep -Fq 'nocturne-update-guard' "$root/config/hypr/scripts/system-maintenance"
grep -Fq 'terminal-palette.zsh' "$root/config/zsh/nocturne.zsh"
grep -Fq 'sync-terminal-theme' "$root/config/hypr/scripts/sync-hyprtoolkit-theme"
grep -Fq '0 resident scanner processes' "$root/config/hypr/scripts/security-control"
grep -Fq 'AUTOMATION WITHOUT A DAEMON' "$root/native/qml/pages/SecuritySettingsPage.qml"
grep -Fq 'nocturne-security-scan.timer' "$root/apply-hyprland.sh"
grep -Fq 'NOC Desk' "$root/native/qml/pages/DeskPage.qml"
grep -Fq 'desk-capture' "$root/native/src/backend.cpp"
grep -Fq 'habit-capture' "$root/native/src/backend.cpp"
grep -Fq 'vault-capture' "$root/native/src/backend.cpp"
grep -Fq 'control-action' "$root/native/src/backend.cpp"
grep -Fq 'SHIFT + N' "$root/config/hypr/hyprland.lua"
grep -Fq 'TOP MEMORY CONSUMERS' "$root/native/qml/pages/EfficiencySettingsPage.qml"
grep -Fq 'PRESSURE-AWARE COMPUTE' "$root/native/qml/pages/PerformanceSettingsPage.qml"
grep -Fq 'UNIVERSITY + SHARED DEVICES' "$root/native/qml/pages/CampusSettingsPage.qml"
grep -Fq 'NO CREDENTIALS STORED' "$root/config/hypr/scripts/campus-control"
grep -Fq 'Never purge caches on a timer' "$root/config/hypr/scripts/performance-control"
grep -Fq 'RECOVERY ASIC' "$root/bin/nox-doc"
grep -Fq 'modelHasRoot:false' "$root/bin/nox-doc"
grep -Fq 'restore --offline' "$root/bin/nox-doc"
grep -Fq 'nox-doc-live-repair-v1' "$root/bin/nox-doc"
grep -Fq 'recovery_repair' "$root/agent/src/nocturne_agent/policy.py"
grep -Fq '%h/.local/state/nocturne' "$root/agent/config/systemd/user/nocturne-agent.service"
grep -Fq 'PATH=%h/.local/bin:' "$root/agent/config/systemd/user/nocturne-agent.service"
grep -Fq 'nox-doc.target' "$root/scripts/install-packages.sh"
grep -Fq 'NOX DOC // BOOT RECOVERY' "$root/native/qml/pages/SetupSettingsPage.qml"
grep -Fq 'find "$thumbnail_root" -type f -mtime +30 -delete' "$root/config/hypr/scripts/efficiency-control"
grep -Fq 'barRssMiB' "$root/config/hypr/scripts/efficiency-control"
grep -Fq 'event.contains(" on sink-input #")' "$root/native/src/backend.cpp"
grep -Fq 'node.name = \"xdph-streaming-' "$root/native/src/backend.cpp"
grep -Fq 'backend.notificationCount()' "$root/native/qml/Bar.qml"
grep -Fq 'text: "󰖨"' "$root/native/qml/BarWindow.qml"
grep -Fq 'END IN SHARING APP' "$root/native/qml/pages/PrivacyPage.qml"
grep -Fq 'SAFETY + PORTABILITY' "$root/native/qml/pages/SetupSettingsPage.qml"
grep -Fq 'nocturne-platform' "$root/config/hypr/scripts/system-maintenance"
grep -Fq 'nocturne-polkit-agent' "$root/config/systemd/user/nocturne-polkit.service"
grep -Fq 'Accessible.role: Accessible.Button' "$root/native/qml/components/BarButton.qml"
grep -Fq 'Accessible.role: Accessible.CheckBox' "$root/native/qml/components/NocturneToggle.qml"
grep -Fq 'CONFIRM CLEAR' "$root/native/qml/pages/ClipboardPage.qml"
grep -Fq 'SENSITIVE GUARD' "$root/native/qml/pages/ClipboardPage.qml"
grep -Fq 'LOCK SCREEN STYLE' "$root/native/qml/pages/AppearanceSettingsPage.qml"
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
grep -Fq 'nativeCard("operations", "")' "$root/native/qml/BarWindow.qml"
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
[[ -x $root/bin/nocturne-continuity ]]
grep -Fq 'nocturne-continuity-v1' "$root/bin/nocturne-continuity"
grep -Fq 'analytics:false' "$root/bin/nocturne-continuity"
grep -Fq 'install -m 0755 "$ROOT_DIR/bin/nocturne-continuity"' "$root/apply-hyprland.sh"
grep -Fq 'ENCRYPTED CONTINUITY' "$root/native/qml/pages/SetupSettingsPage.qml"
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
grep -Fq 'nocturne-storage-v1' "$root/config/hypr/scripts/storage-control"
grep -Fq 'nocturne-meeting-v1' "$root/config/hypr/scripts/meeting-mode"
grep -Fq 'nocturne-permissions-v1' "$root/config/hypr/scripts/permission-control"
grep -Fq 'nocturne-guard-v1' "$root/config/hypr/scripts/system-guard"
grep -Fq 'nocturne-rules-v1' "$root/config/hypr/scripts/automation-rules"
grep -Fq 'nocturne-clipboard-v1' "$root/config/hypr/scripts/clipboard-control"
grep -Fq 'nocturne-power-lab-v2' "$root/config/hypr/scripts/power-lab"
grep -Fq 'nocturne-lock-style-v2' "$root/config/hypr/scripts/lock-style"
[[ $(find "$root/config/hypr/lockstyles" -maxdepth 1 -name '*.conf.in' | wc -l) -eq 11 ]]
for lock_style in "$root/config/hypr/lockstyles/"*.conf.in; do
  [[ $(basename -- "$lock_style") == common.conf.in ]] && continue
  grep -Fq 'input-field {' "$lock_style"
  grep -Fq 'fail_text =' "$lock_style"
  grep -Fq 'check_color =' "$lock_style"
done
[[ -x $root/bin/nocturne-banner ]]
grep -Fq 'NOCTURNE $2// $1OPERATIONS CONSOLE' "$root/branding/noc-terminal.txt"
grep -Fq 'SIGNAL $6● $4LIVE' "$root/branding/noc-terminal.txt"
grep -Fq '"6": "#e17780"' "$root/config/fastfetch/config.jsonc"
grep -Fq 'noc-terminal-compact.txt' "$root/apply-hyprland.sh"
grep -Fq 'rapid_failures' "$root/config/hypr/scripts/bar"
grep -Fq 'lock_dir=' "$root/config/hypr/scripts/bar"
! grep -Fq 'exec 9>' "$root/config/hypr/scripts/bar"
grep -Fq 'mako.service' "$root/config/systemd/user/nocturne-session.target"
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

for page in AgendaSettingsPage WindowRulesSettingsPage ExtensionsSettingsPage OnboardingSettingsPage LaptopIntelligenceSettingsPage DisplayLabSettingsPage; do
  grep -Fq "qml/pages/$page.qml" "$root/native/CMakeLists.txt"
done
grep -Fq 'nocturne-agenda-v1' "$root/bin/nocturne-agenda"
grep -Fq 'nocturne-window-rules-v1' "$root/bin/nocturne-window-rules"
grep -Fq 'arbitraryCode' "$root/bin/nocturne-extensions"
grep -Fq 'nocturne-display-lab-v1' "$root/config/hypr/scripts/monitor-layout"
grep -Fq 'brightnessStep' "$root/config/hypr/scripts/power-lab"
grep -Fq 'nocturne-context-timer-v1' "$root/config/hypr/scripts/context-timer-state"
grep -Fq 'pcall(dofile, user_window_rules)' "$root/config/hypr/hyprland.lua"
grep -Fq 'nocturne-agenda-refresh.timer' "$root/apply-hyprland.sh"
printf '[ OK ] agenda, onboarding, window rules, extensions, laptop intelligence and display lab\n'

grep -Fq 'systemctl --user restart nocturne-session.target' "$root/config/hypr/hyprland.lua"
grep -Fq 'systemctl --user stop nocturne-session.target' "$root/apply-hyprland.sh"
grep -Fq 'systemctl --user start nocturne-session.target' "$root/apply-hyprland.sh"
grep -Fq 'nocturne-wallpaper-cycle.service' "$root/config/systemd/user/nocturne-session.target"
grep -Fq 'if desired and monitors and' "$root/bin/nocturne-wallpaper-cycle"
! grep -Fq 'WantedBy=default.target' "$root/config/systemd/user/nocturne-wallpaper-cycle.service"
printf '[ OK ] supervised session startup and wallpaper reboot recovery\n'

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
grep -Fq 'intel-media-va-driver vainfo intel-gpu-tools' "$root/scripts/install-packages.sh"
grep -Fq 'intel-media-driver libva-utils' "$root/scripts/install-packages.sh"
grep -Fq 'Hardware video decode profiles are available' "$root/bin/nocturne-doctor"
printf '[ OK ] native Wayland browser video acceleration\n'

(
  cd "$root/agent"
  PYTHONPATH=src python3 -m pytest -q
)

if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$root" diff --check
  printf '[ OK ] patch hygiene\n'
else
  printf '[ OK ] packaged source tree (Git metadata intentionally absent)\n'
fi
printf 'RESULT // source tree is internally consistent\n'
