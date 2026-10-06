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
  PomodoroPage PowerPage LauncherPage DeskPage OverviewPage ScenesPage AutomationPage
  PrivacyPage GamingPage OsdPage BackgroundPage NotificationsPage ClipboardPage
  MinimizedPage MediaPage KdeConnectPage MaintenancePage DisplayPage
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

printf 'NOCTURNE // %d on-demand UI components instantiated cleanly\n' "${#pages[@]}"
