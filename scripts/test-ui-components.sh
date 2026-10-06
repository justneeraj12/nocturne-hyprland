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
  PomodoroPage PowerPage LauncherPage OverviewPage ScenesPage AutomationPage
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

printf 'NOCTURNE // %d on-demand UI components instantiated cleanly\n' "${#pages[@]}"
