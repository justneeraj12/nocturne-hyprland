#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
binary=${1:-"$root/build/native/nocturne-native"}
[[ -x $binary ]] || { printf 'Native test binary is missing: %s\n' "$binary" >&2; exit 2; }

test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
chmod 700 "$test_root"
mkdir -p "$test_root/home/.config/nocturne" "$test_root/home/.local/state/nocturne"
install -m 0644 "$root/config/nocturne/theme.json" "$test_root/home/.config/nocturne/theme.json"

pages=(
  AudioPage BrightnessPage CameraPage CalendarPage WorldPage ConnectivityPage
  PomodoroPage PowerPage LauncherPage DeskPage HabitsPage VaultPage OverviewPage ScenesPage AutomationPage
  PrivacyPage GamingPage OperationsPage OsdPage BackgroundPage NotificationsPage ClipboardPage
  MinimizedPage MediaPage KdeConnectPage MaintenancePage DisplayPage
  StorageSettingsPage ControlCenterSettingsPage AutomationRulesSettingsPage
)

for page in "${pages[@]}"; do
  HOME="$test_root/home" XDG_CONFIG_HOME="$test_root/home/.config" \
    XDG_STATE_HOME="$test_root/home/.local/state" XDG_RUNTIME_DIR="$test_root" \
    QT_QPA_PLATFORM=offscreen "$binary" --component-test "$page" >/dev/null
done

HOME="$test_root/home" XDG_CONFIG_HOME="$test_root/home/.config" \
  XDG_STATE_HOME="$test_root/home/.local/state" XDG_RUNTIME_DIR="$test_root" \
  QT_QPA_PLATFORM=offscreen "$binary" --settings-test >/dev/null

query_result() {
  HOME="$test_root/home" XDG_CONFIG_HOME="$test_root/home/.config" \
    XDG_STATE_HOME="$test_root/home/.local/state" XDG_RUNTIME_DIR="$test_root" \
    QT_QPA_PLATFORM=offscreen "$binary" --launcher-query-test "$1"
}
query_result 'volume 35' | jq -e '.[0].kind == "control-action" and .[0].id == "set-volume" and .[0].value == "35"' >/dev/null
query_result 'timer 50/10' | jq -e '.[0].id == "set-timer" and .[0].value == "50:10"' >/dev/null
query_result 'power saver' | jq -e '.[0].id == "set-power" and .[0].value == "power-saver"' >/dev/null
query_result '+!^ ship release' | jq -e '.[0].kind == "desk-capture" and .[0].priority == "high" and .[0].due == "today"' >/dev/null
query_result '++3 read' | jq -e '.[0].kind == "habit-capture" and .[0].target == 3 and .[0].name == "read"' >/dev/null
query_result ':: Deploy | https://example.com' | jq -e '.[0].kind == "vault-capture" and .[0].name == "Deploy" and .[0].content == "https://example.com"' >/dev/null
query_result 'note remember milk' | jq -e '.[0].kind == "note-capture" and .[0].name == "remember milk"' >/dev/null
query_result 'copy hello' | jq -e '.[0].kind == "copy-text" and .[0].name == "hello"' >/dev/null
query_result 'open https://example.com' | jq -e '.[0].kind == "open-url"' >/dev/null

printf 'NOCTURNE // %d on-demand UI components instantiated cleanly\n' "${#pages[@]}"
