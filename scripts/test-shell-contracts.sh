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
"$XDG_CONFIG_HOME/hypr/scripts/context-engine" assign mobile commute
jq -e '.format == "nocturne-context-v2" and .contexts.docked == "desk" and .profiles.meeting == "calls"' \
  "$XDG_CONFIG_HOME/nocturne/context.json" >/dev/null
"$XDG_CONFIG_HOME/hypr/scripts/context-engine" decision \
  | jq -e '.enabled == false and .context == "mobile" and .selectedScene == "commute" and .reason == "context:mobile"' >/dev/null

"$root/bin/nocturne-migrate" --json | jq -e '.ready == true and .schema == 10' >/dev/null
trace="$root/config/hypr/scripts/automation-trace"
"$trace" record context scene-applied profile:meeting calls 'Settings only.'
"$trace" record context baseline-restored no-matching-scene calls 'Reversed.'
"$trace" list 10 | jq -e 'length == 2 and .[0].event == "baseline-restored" and .[1].event == "scene-applied"' >/dev/null
"$trace" status | jq -e '.format == "nocturne-trace-v1" and .count == 2 and .privacy.content == false' >/dev/null
"$trace" clear
"$trace" list | jq -e 'length == 0' >/dev/null

mkdir -p "$XDG_CONFIG_HOME/nocturne/scenes" "$HOME/.local/bin"
printf '%s\n' '{"name":"Obsidian Grid"}' > "$XDG_CONFIG_HOME/nocturne/theme.json"
printf '%s\n' '{"format":"nocturne-scene-v1","name":"Focus","created":"2026-10-05T12:00:00-04:00","workspace":1,"windows":[{"class":"kitty","workspace":1,"desktop":"/apps/kitty.desktop"},{"class":"code","workspace":2,"desktop":"/apps/code.desktop"}],"monitors":[{"name":"TEST-1"}],"settings":{"profile":"performance","sink":"sink-a","source":"mic-b","wallpaper":"/wallpapers/focus.png","theme":"Copper Blue"}}' \
  > "$XDG_CONFIG_HOME/nocturne/scenes/focus.json"
printf '%s\n' '#!/bin/sh' 'printf '\''[{"mapped":true,"class":"kitty"}]\n'\''' > "$test_root/bin/hyprctl"
printf '%s\n' '#!/bin/sh' 'printf '\''balanced\n'\''' > "$test_root/bin/powerprofilesctl"
printf '%s\n' '#!/bin/sh' 'case "$1 $2" in "get-default-sink ") printf '\''sink-a\n'\'' ;; "get-default-source ") printf '\''mic-a\n'\'' ;; esac' > "$test_root/bin/pactl"
printf '%s\n' '#!/bin/sh' 'printf '\''{"current":"/wallpapers/current.png"}\n'\''' > "$HOME/.local/bin/nocturne-wallpaper-cycle"
chmod +x "$test_root/bin/hyprctl" "$test_root/bin/powerprofilesctl" "$test_root/bin/pactl" "$HOME/.local/bin/nocturne-wallpaper-cycle"
PATH="$test_root/bin:$PATH" "$root/config/hypr/scripts/scene-manager" preview focus \
  | jq -e '.format == "nocturne-scene-preview-v1" and .apps == 2 and .appsToLaunch == 1 and .windows == 2 and .settingsChanges == 4' >/dev/null

export XDG_DATA_HOME=$HOME/.local/share
desk="$root/config/hypr/scripts/desk"
cp -- "$root/config/hypr/scripts/desk" "$XDG_CONFIG_HOME/hypr/scripts/desk"
cp -- "$root/config/hypr/scripts/pomodoro" "$XDG_CONFIG_HOME/hypr/scripts/pomodoro"
chmod +x "$XDG_CONFIG_HOME/hypr/scripts/desk" "$XDG_CONFIG_HOME/hypr/scripts/pomodoro"
"$desk" add 'Ship the next release' high today
"$desk" add 'Write the migration notes' normal tomorrow
"$desk" focus 1
"$desk" status | jq -e '.format == "nocturne-desk-status-v1" and .open == 2 and .today == 1 and .focus.id == 1' >/dev/null
"$desk" edit 2 'Write tested migration notes'
"$desk" list open tested | jq -e 'length == 1 and .[0].id == 2' >/dev/null
"$desk" list today release | jq -e 'length == 1 and .[0].priority == "high"' >/dev/null
"$desk" toggle 1
"$desk" status | jq -e '.open == 1 and .completedToday == 1 and .focus == null' >/dev/null
"$desk" undo
"$desk" status | jq -e '.open == 2 and .completedToday == 0 and .focus.id == 1' >/dev/null
"$desk" note-set $'Local notes\nremain private.'
[[ $("$desk" note) == $'Local notes\nremain private.' ]]
desk_export="$test_root/desk.md"
[[ $("$desk" export "$desk_export") == "$desk_export" ]]
grep -Fq 'Ship the next release' "$desk_export"
[[ $(stat -c %a "$XDG_DATA_HOME/nocturne/desk.json") == 600 ]]
"$desk" note-append 'Second line.'
[[ $("$desk" note) == $'Local notes\nremain private.\nSecond line.' ]]

habits="$root/config/hypr/scripts/habits"
vault="$root/config/hypr/scripts/vault"
"$habits" add Exercise 5
"$habits" add Read 7
"$habits" check 1
"$habits" status | jq -e '.format == "nocturne-habits-status-v1" and .active == 2 and .doneToday == 1' >/dev/null
"$habits" list active | jq -e 'map(select(.id == 1))[0] | .weekCount == 1 and .progress == 20 and .streak == 1' >/dev/null
"$habits" edit 2 'Read deeply' 3
"$habits" archive 2
"$habits" list archived | jq -e 'length == 1 and .[0].target == 3' >/dev/null
"$habits" undo
"$habits" list active deeply | jq -e 'length == 1' >/dev/null
[[ $(stat -c %a "$XDG_DATA_HOME/nocturne/habits.json") == 600 ]]
habit_export="$test_root/habits.md"; [[ $("$habits" export "$habit_export") == "$habit_export" ]]

printf '%s\n' '#!/bin/sh' 'cat > "$MOCK_COPY"' > "$test_root/bin/wl-copy"
printf '%s\n' '#!/bin/sh' 'printf "captured clipboard"' > "$test_root/bin/wl-paste"
chmod +x "$test_root/bin/wl-copy" "$test_root/bin/wl-paste"
export PATH="$test_root/bin:$PATH" MOCK_COPY="$test_root/copied"
"$vault" add 'Deploy link' 'https://example.com/release' 'work, links'
"$vault" add 'Useful command' 'systemctl --user status nocturne-bar' 'linux, work'
"$vault" pin 2
"$vault" copy 1
[[ $(cat "$MOCK_COPY") == 'https://example.com/release' ]]
"$vault" capture 'Clipboard note' notes
"$vault" status | jq -e '.format == "nocturne-vault-status-v1" and .items == 3 and .pinned == 1' >/dev/null
"$vault" list work | jq -e 'length == 2 and .[0].pinned == true' >/dev/null
"$vault" edit 2 'System status' 'systemctl --user status nocturne-bar' 'linux'
"$vault" delete 3; "$vault" undo
"$vault" list clipboard | jq -e 'length == 1' >/dev/null
[[ $(stat -c %a "$XDG_DATA_HOME/nocturne/vault.json") == 600 ]]
vault_export="$test_root/vault.md"; [[ $("$vault" export "$vault_export") == "$vault_export" ]]
printf '%s\n' 'work_seconds=60' 'break_seconds=60' 'mode=work' 'running=1' 'remaining=1' 'end=1' 'cycles=0' 'auto=0' \
  > "$XDG_STATE_HOME/nocturne/pomodoro.state"
"$XDG_CONFIG_HOME/hypr/scripts/pomodoro" inspect | jq -e '.mode == "break" and .cycles == 1' >/dev/null
"$desk" status | jq -e '.focusMinutesToday == 1 and .sessionsToday == 1' >/dev/null
"$desk" stats | jq -e '.format == "nocturne-desk-stats-v1" and .todayMinutes == 1 and .weekMinutes == 1' >/dev/null
"$desk" brief | jq -e '.open == 2 and .focusMinutesToday == 1' >/dev/null
[[ $(stat -c %a "$XDG_STATE_HOME/nocturne/pomodoro.state") == 600 ]]
printf '%s\n' 'work_seconds=60' 'break_seconds=60' 'mode=work' 'running=1' 'remaining=1' 'end=1' 'cycles=1' 'auto=0' \
  > "$XDG_STATE_HOME/nocturne/pomodoro.state"
timeout 3s "$desk" start 1
"$desk" status | jq -e '.focusMinutesToday == 2 and .sessionsToday == 2' >/dev/null

# The 1.1 control centers remain command driven, bounded and private. Exercise
# their persistent state without touching the live user session.
for helper in automation-rules clipboard-control context-timer-state power-lab system-preferences; do
  cp -- "$root/config/hypr/scripts/$helper" "$XDG_CONFIG_HOME/hypr/scripts/$helper"
  chmod +x "$XDG_CONFIG_HOME/hypr/scripts/$helper"
done
printf '%s\n' '#!/bin/sh' 'exit 0' > "$test_root/bin/systemctl"
printf '%s\n' '#!/bin/sh' 'exit 0' > "$test_root/bin/hyprctl"
printf '%s\n' '#!/bin/sh' 'exit 0' > "$test_root/bin/notify-send"
printf '%s\n' '#!/bin/sh' \
  'case "$1" in' \
  '  decode) cat ;;' \
  '  store) cat > "$MOCK_CLIPHIST_STORE" ;;' \
  '  list) printf "" ;;' \
  'esac' > "$test_root/bin/cliphist"
printf '%s\n' '#!/bin/sh' 'exit 0' > "$test_root/bin/systemd-run"
chmod +x "$test_root/bin/systemctl" "$test_root/bin/hyprctl" "$test_root/bin/notify-send" "$test_root/bin/cliphist" "$test_root/bin/systemd-run"

rules="$XDG_CONFIG_HOME/hypr/scripts/automation-rules"
"$rules" add 'Saver away from dock' mobile power power-saver
"$rules" add 'Quiet meetings' meeting dnd-on
"$rules" status | jq -e '.format == "nocturne-rules-v1" and .count == 2 and .active == 2' >/dev/null
"$rules" toggle 2
"$rules" enable
"$rules" status | jq -e '.enabled == true and .active == 1 and .rules[1].enabled == false' >/dev/null
[[ $(stat -c %a "$XDG_CONFIG_HOME/nocturne/rules.json") == 600 ]]
"$XDG_CONFIG_HOME/hypr/scripts/context-timer-state" status \
  | jq -e '.format == "nocturne-context-timer-v1" and .required == true and .reasons.rules == true' >/dev/null

clipboard="$XDG_CONFIG_HOME/hypr/scripts/clipboard-control"
export MOCK_CLIPHIST_STORE="$test_root/cliphist-store"
"$clipboard" configure sensitiveExpiry 60
printf 'ordinary clipboard value' | "$clipboard" watch
[[ $(cat "$MOCK_CLIPHIST_STORE") == 'ordinary clipboard value' ]]
rm -f -- "$MOCK_CLIPHIST_STORE"
printf 'password=correct-horse-battery-staple' | "$clipboard" watch
[[ ! -e $MOCK_CLIPHIST_STORE ]]
"$clipboard" pin $'17\tPinned release note'
"$clipboard" status | jq -e '.format == "nocturne-clipboard-v1" and .sensitiveGuard == true and .sensitiveExpiry == 60 and (.pins|length) == 1' >/dev/null
[[ $(stat -c %a "$XDG_DATA_HOME/nocturne/clipboard/pins.json") == 600 ]]

power_lab="$XDG_CONFIG_HOME/hypr/scripts/power-lab"
"$power_lab" configure adaptiveSaver true
"$power_lab" configure lowBattery 25
"$power_lab" configure brightnessStep 2
"$power_lab" configure brightnessFloor 10
"$power_lab" configure lowerRefreshOnBattery true
"$power_lab" configure batteryRefresh 60
"$power_lab" configure bluetoothStartup off
"$power_lab" status | jq -e '.format == "nocturne-power-lab-v2" and .adaptiveSaver == true and .lowBattery == 25 and .brightness.step == 2 and .brightness.floor == 10 and .refresh.lowerOnBattery == true and .refresh.target == 60 and .bluetooth.startup == "off" and (.sleep.deepAvailable|type == "boolean")' >/dev/null
"$rules" disable
"$XDG_CONFIG_HOME/hypr/scripts/context-timer-state" status \
  | jq -e '.required == true and .reasons.rules == false and .reasons.power == true' >/dev/null

preferences="$XDG_CONFIG_HOME/hypr/scripts/system-preferences"
"$preferences" set-input workspaceSwipe true
"$preferences" set-input accelProfile flat
grep -Fq 'hl.gesture({' "$XDG_CONFIG_HOME/nocturne/input.lua"
grep -Fq 'accel_profile = "flat"' "$XDG_CONFIG_HOME/nocturne/input.lua"

"$root/config/hypr/scripts/storage-control" status \
  | jq -e '.format == "nocturne-storage-v1" and (.cleanup|length) == 4 and (.protected|length) >= 4' >/dev/null
"$root/config/hypr/scripts/noc-state" status \
  | jq -e '.format == "nocturne-operations-v1" and (.score|type == "number") and (.alerts|type == "array")' >/dev/null
mkdir -p "$XDG_CONFIG_HOME/nocturne"
cp -- "$root/config/hypr/scripts/efficiency-control" "$XDG_CONFIG_HOME/hypr/scripts/efficiency-control"
cp -- "$root/config/nocturne/performance-budget.json" "$XDG_CONFIG_HOME/nocturne/performance-budget.json"
chmod +x "$XDG_CONFIG_HOME/hypr/scripts/efficiency-control"
"$root/bin/nocturne-benchmark" --json \
  | jq -e '.format == "nocturne-performance-report-v1" and (.checks|length) == 5' >/dev/null
printf '%s\n' '#!/bin/sh' \
  'case "$*" in' \
  '  "list --app --columns=application,name") printf "org.example.App\tExample App\n" ;;' \
  '  "list --app --columns=application") printf "org.example.App\n" ;;' \
  '  "permission-list") exit 0 ;;' \
  '  "override --show org.example.App") exit 0 ;;' \
  'esac' > "$test_root/bin/flatpak"
chmod +x "$test_root/bin/flatpak"
mkdir -p "$XDG_CONFIG_HOME/autostart"
printf '%s\n' '[Desktop Entry]' 'Name=Example startup' 'Exec=true' > "$XDG_CONFIG_HOME/autostart/example.desktop"
permissions="$root/config/hypr/scripts/permission-control"
"$permissions" status | jq -e '.format == "nocturne-permissions-v1" and (.portals.healthy|type == "boolean") and (.flatpaks|length) == 1 and (.startup|length) == 1' >/dev/null
"$permissions" startup example.desktop false
grep -Fq 'Hidden=true' "$XDG_CONFIG_HOME/autostart/example.desktop"

mkdir -p "$XDG_CONFIG_HOME/hypr/lockstyles"
cp -- "$root/config/hypr/scripts/lock-style" "$XDG_CONFIG_HOME/hypr/scripts/lock-style"
cp -- "$root/config/hypr/lockstyles/"*.conf.in "$XDG_CONFIG_HOME/hypr/lockstyles/"
chmod +x "$XDG_CONFIG_HOME/hypr/scripts/lock-style"
lock_style="$XDG_CONFIG_HOME/hypr/scripts/lock-style"
"$lock_style" status | jq -e '.format == "nocturne-lock-style-v2" and .current == "editorial" and .background == "balanced" and .clock == "operator" and (.styles|length) == 10' >/dev/null
printf '%s\n' '{"format":"nocturne-lock-style-v1","current":"relay-split"}' > "$XDG_CONFIG_HOME/nocturne/lock-style.json"
"$lock_style" status | jq -e '.format == "nocturne-lock-style-v2" and .current == "relay-split" and .background == "balanced" and .clock == "operator"' >/dev/null
for style in editorial center-signal noc-grid phosphor-terminal relay-split black-ice red-sector signal-tower mainframe dead-channel; do
  "$lock_style" apply "$style"
  "$lock_style" status | jq -e --arg style "$style" '.current == $style' >/dev/null
  grep -Fq "NOCTURNE LOCK STYLE: $style" "$XDG_CONFIG_HOME/hypr/hyprlock.conf"
  ! grep -Eq '@[A-Z0-9_]+@' "$XDG_CONFIG_HOME/hypr/hyprlock.conf"
done
"$lock_style" apply editorial
"$lock_style" configure background void
"$lock_style" configure clock twenty-four
"$lock_style" status | jq -e '.background == "void" and .clock == "twenty-four"' >/dev/null
grep -Fq 'brightness = 0.08' "$XDG_CONFIG_HOME/hypr/hyprlock.conf"
XDG_CONFIG_HOME="$XDG_CONFIG_HOME" "$root/config/hypr/scripts/lock-time" | grep -Eq '^[0-2][0-9]:[0-5][0-9]$'
"$lock_style" configure clock twelve
XDG_CONFIG_HOME="$XDG_CONFIG_HOME" "$root/config/hypr/scripts/lock-time" | grep -Eq '^([1-9]|1[0-2]):[0-5][0-9] (AM|PM)$'
"$lock_style" configure background balanced
"$lock_style" configure clock operator
XDG_CONFIG_HOME="$XDG_CONFIG_HOME" "$root/config/hypr/scripts/lock-time" | grep -Eq '^([1-9]|1[0-2]):[0-5][0-9](\+|−)$'
[[ $(stat -c %a "$XDG_CONFIG_HOME/nocturne/lock-style.json") == 600 ]]
for template in "$XDG_CONFIG_HOME/hypr/lockstyles/"*.conf.in; do
  [[ $(basename -- "$template") == common.conf.in ]] && continue
  grep -Fq 'input-field {' "$template"
  grep -Fq 'fail_text =' "$template"
  grep -Fq 'check_color =' "$template"
  ! grep -Fq '\n' "$template"
done

printf '%s\n' '#!/bin/sh' \
  'if [ "${1:-}" = "-y" ]; then printf "age1nocturnetestrecipient000000000000000000000000000000000000\n"; exit 0; fi' \
  'while [ "$#" -gt 0 ]; do case "$1" in -o) printf "AGE-SECRET-KEY-TEST-ONLY\n" > "$2"; exit 0 ;; *) shift ;; esac; done' \
  'exit 2' > "$test_root/bin/age-keygen"
printf '%s\n' '#!/bin/sh' \
  'output=""; input=""' \
  'while [ "$#" -gt 0 ]; do case "$1" in -o) output=$2; shift 2 ;; -r|-i) shift 2 ;; -d) shift ;; *) input=$1; shift ;; esac; done' \
  'cp -- "$input" "$output"' > "$test_root/bin/age"
chmod +x "$test_root/bin/age" "$test_root/bin/age-keygen"
continuity="$root/bin/nocturne-continuity"
shared="$test_root/shared-continuity"
PATH="$test_root/bin:$PATH" "$continuity" init "$shared" | jq -e '.configured == true and .encrypted == true and .analytics == false' >/dev/null
printf '%s\n' '{"format":"test-theme","name":"Copper Deep Green"}' > "$XDG_CONFIG_HOME/nocturne/theme.json"
PATH="$test_root/bin:$PATH" "$continuity" push | jq -e '.bundleAvailable == true and .inSync == true and .lastAction == "push"' >/dev/null
printf '%s\n' '{"format":"test-theme","name":"Changed Locally"}' > "$XDG_CONFIG_HOME/nocturne/theme.json"
PATH="$test_root/bin:$PATH" "$continuity" pull | jq -e '.inSync == true and .lastAction == "pull"' >/dev/null
jq -e '.name == "Copper Deep Green"' "$XDG_CONFIG_HOME/nocturne/theme.json" >/dev/null
mkdir -p "$test_root/malicious/payload/config"
printf '%s\n' '{"format":"nocturne-continuity-v1","encrypted":true}' > "$test_root/malicious/payload/manifest.json"
ln -s /tmp "$test_root/malicious/payload/config/themes"
tar -C "$test_root/malicious" -czf "$shared/nocturne-continuity.age" payload
if PATH="$test_root/bin:$PATH" "$continuity" pull >/dev/null 2>&1; then
  printf 'Continuity pull should reject archive links.\n' >&2
  exit 1
fi
PATH="$test_root/bin:$PATH" "$continuity" push --force >/dev/null
identity_export="$test_root/continuity-identity.txt"
PATH="$test_root/bin:$PATH" "$continuity" export-key "$identity_export" >/dev/null
second_home="$test_root/second-device"
mkdir -p "$second_home/.config" "$second_home/.local/share" "$second_home/.local/state"
PATH="$test_root/bin:$PATH" HOME="$second_home" XDG_CONFIG_HOME="$second_home/.config" XDG_DATA_HOME="$second_home/.local/share" XDG_STATE_HOME="$second_home/.local/state" \
  "$continuity" import-key "$identity_export" "$shared" | jq -e '.configured == true and .encrypted == true' >/dev/null
PATH="$test_root/bin:$PATH" HOME="$second_home" XDG_CONFIG_HOME="$second_home/.config" XDG_DATA_HOME="$second_home/.local/share" XDG_STATE_HOME="$second_home/.local/state" \
  "$continuity" pull | jq -e '.inSync == true and .lastAction == "pull"' >/dev/null
jq -e '.name == "Copper Deep Green"' "$second_home/.config/nocturne/theme.json" >/dev/null
printf '%s\n' '{"format":"test-theme","name":"Second Device Copper"}' > "$second_home/.config/nocturne/theme.json"
PATH="$test_root/bin:$PATH" HOME="$second_home" XDG_CONFIG_HOME="$second_home/.config" XDG_DATA_HOME="$second_home/.local/share" XDG_STATE_HOME="$second_home/.local/state" \
  "$continuity" push | jq -e '.inSync == true and .lastAction == "push"' >/dev/null
if PATH="$test_root/bin:$PATH" "$continuity" push >/dev/null 2>&1; then
  printf 'First device should refuse to overwrite the second device.\n' >&2
  exit 1
fi
PATH="$test_root/bin:$PATH" "$continuity" pull >/dev/null
jq -e '.name == "Second Device Copper"' "$XDG_CONFIG_HOME/nocturne/theme.json" >/dev/null
printf 'remote-change' >> "$shared/nocturne-continuity.age"
if PATH="$test_root/bin:$PATH" "$continuity" push >/dev/null 2>&1; then
  printf 'Continuity push should refuse an unseen remote change.\n' >&2
  exit 1
fi

NOCTURNE_CAMERA_DEVICE="$test_root/missing-camera" \
  "$root/config/hypr/scripts/camera-control" status \
  | jq -e '.available == false and .idleCost == "0 processes · hardware controls persist in sensor"' >/dev/null

security="$root/config/hypr/scripts/security-control"
mkdir -p "$HOME/Downloads" "$XDG_DATA_HOME/nocturne/security/clamav"
touch -d '1 hour ago' "$XDG_DATA_HOME/nocturne/security/clamav/daily.cvd"
printf '%s\n' '#!/bin/sh' \
  'if [ "${1:-}" = "--version" ]; then printf "ClamAV 1.4.0/test\n"; exit 0; fi' \
  'printf "Scanned files: 3\nInfected files: 0\nTotal errors: 0\n"' > "$test_root/bin/clamscan"
chmod +x "$test_root/bin/clamscan"
NOCTURNE_SECURITY_STATE_ROOT="$test_root/security-state" NOCTURNE_SECURITY_DATA_ROOT="$XDG_DATA_HOME/nocturne/security" \
  "$security" status | jq -e '.format == "nocturne-security-v1" and .engine.installed == true and .engine.database.fresh == true and .idleCost == "0 resident scanner processes"' >/dev/null
NOCTURNE_SECURITY_STATE_ROOT="$test_root/security-state" NOCTURNE_SECURITY_DATA_ROOT="$XDG_DATA_HOME/nocturne/security" \
  "$security" scan downloads standard >/dev/null
jq -e '.result == "clean" and .scanned == 3 and .infected == 0' "$test_root/security-state/last-scan.json" >/dev/null

# Community-demand controls remain declarative, private and zero-resident.
agenda="$root/bin/nocturne-agenda"
today=$(date +%Y%m%d); tomorrow=$(date -d tomorrow +%Y%m%d)
printf '%s\n' 'BEGIN:VCALENDAR' 'VERSION:2.0' 'BEGIN:VEVENT' 'UID:test-event' \
  "DTSTART;VALUE=DATE:$today" "DTEND;VALUE=DATE:$tomorrow" 'SUMMARY:Private agenda test' \
  'END:VEVENT' 'END:VCALENDAR' > "$test_root/calendar.ics"
NOCTURNE_NO_RESTART=1 "$agenda" add Test "$test_root/calendar.ics" '#5f8f76' >/dev/null
NOCTURNE_NO_RESTART=1 "$agenda" refresh >/dev/null
NOCTURNE_NO_RESTART=1 "$agenda" status \
  | jq -e '.format == "nocturne-agenda-v1" and .configured == true and .sourceCount == 1 and .eventCount == 1 and .privacy.urlsRedacted == true and .privacy.residentProcesses == 0' >/dev/null
[[ $(stat -c %a "$XDG_CONFIG_HOME/nocturne/agenda.json") == 600 ]]
NOCTURNE_NO_RESTART=1 "$agenda" add Offline 'https://127.0.0.1:9/calendar.ics?token=never-log-this' '#6f8fae' >/dev/null
NOCTURNE_NO_RESTART=1 "$agenda" refresh >/dev/null 2>&1 || true
agenda_status=$(NOCTURNE_NO_RESTART=1 "$agenda" status)
! grep -Fq 'never-log-this' <<< "$agenda_status"
jq -e '.sources[] | select(.name == "Offline") | .ok == false' <<< "$agenda_status" >/dev/null

printf '%s\n' '#!/bin/sh' \
  'if [ "$*" = "-j activewindow" ]; then printf '\''{"class":"steam","title":"Steam Settings","workspace":{"name":"2"},"monitor":0,"floating":true}'\'';' \
  'elif [ "$*" = "-j clients" ]; then printf '\''[{"class":"steam","title":"Steam Settings"},{"class":"kitty","title":"shell"}]'\''; fi' \
  > "$test_root/bin/hyprctl"
chmod +x "$test_root/bin/hyprctl"
window_rules="$root/bin/nocturne-window-rules"
NOCTURNE_NO_RESTART=1 "$window_rules" add 'Steam settings' steam 'Steam Settings' float '' >/dev/null
NOCTURNE_NO_RESTART=1 "$window_rules" add 'Dim terminal' kitty - opacity 0.9 >/dev/null
NOCTURNE_NO_RESTART=1 "$window_rules" status \
  | jq -e '.format == "nocturne-window-rules-v1" and .count == 2 and .active == 2 and (.clients|length) == 2' >/dev/null
grep -Fq 'class = "^steam$", title = "^Steam\\ Settings$"' "$XDG_CONFIG_HOME/nocturne/window-rules.lua"
grep -Fq 'opacity = "0.90 override 0.90 override 0.90 override"' "$XDG_CONFIG_HOME/nocturne/window-rules.lua"

# Portable exports must never include credentials, token-bearing calendar URLs,
# private window titles or device-bound display profiles.
mkdir -p "$XDG_CONFIG_HOME/nocturne/continuity" "$XDG_CONFIG_HOME/nocturne/display-profiles"
printf '%s\n' 'AGE-SECRET-KEY-TEST-ONLY' > "$XDG_CONFIG_HOME/nocturne/continuity/identity.txt"
portable_bundle=$("$root/bin/nocturne-portable" export)
portable_listing=$(tar -tzf "$portable_bundle")
for private_path in agenda.json window-rules.json window-rules.lua continuity display-profiles; do
  if grep -Fq -- "$private_path" <<< "$portable_listing"; then
    printf 'Portable export leaked private path: %s\n' "$private_path" >&2
    exit 1
  fi
done
tar -xOf "$portable_bundle" nocturne-portable/manifest.json \
  | jq -e '.format == "nocturne-portable-v1" and (.excluded | index("calendar subscription URLs")) != null' >/dev/null

extension_manifest="$test_root/extension.json"
printf '%s\n' '{"format":"nocturne-extension-v1","id":"org.example.status","name":"Example status","version":"1.0.0","description":"Status page","entry":{"type":"url","target":"https://status.example.org"},"permissions":["network"]}' > "$extension_manifest"
extensions="$root/bin/nocturne-extensions"
"$extensions" install "$extension_manifest" >/dev/null
"$extensions" status | jq -e '.installed == 1 and .enabled == 1 and .contract.arbitraryCode == false and .contract.residentProcesses == 0' >/dev/null
"$extensions" disable org.example.status | jq -e '.enabled == 0' >/dev/null
ln -s "$extension_manifest" "$test_root/extension-link.json"
if "$extensions" install "$test_root/extension-link.json" >/dev/null 2>&1; then
  printf 'Extension install should reject manifest symlinks.\n' >&2
  exit 1
fi
if "$extensions" remove '../../outside' >/dev/null 2>&1; then
  printf 'Extension operations should reject path-like ids.\n' >&2
  exit 1
fi

printf '%s\n' '#!/bin/sh' \
  'if [ "$1 $2" = "-j monitors" ]; then printf '\''[{"id":0,"name":"eDP-1","description":"Panel","width":1920,"height":1080,"refreshRate":144.0,"x":0,"y":0,"scale":1.0,"transform":0,"focused":true,"vrr":false,"availableModes":["1920x1080@60.00Hz","1920x1080@144.00Hz"]}]'\''; exit 0; fi' \
  'exit 0' > "$test_root/bin/hyprctl"
chmod +x "$test_root/bin/hyprctl"
monitor_layout="$root/config/hypr/scripts/monitor-layout"
printf '%s\n' 'invalid display state' > "$XDG_CONFIG_HOME/nocturne/display-lab.json"
"$monitor_layout" profile-save mobile
"$monitor_layout" auto true
"$monitor_layout" lab-status | jq -e '.format == "nocturne-display-lab-v1" and (.monitors|length) == 1 and (.profiles|length) == 1 and .profiles[0].matches == true' >/dev/null
[[ $(stat -c %a "$XDG_CONFIG_HOME/nocturne/display-profiles/mobile.json") == 600 ]]
"$XDG_CONFIG_HOME/hypr/scripts/context-timer-state" status \
  | jq -e '.required == true and .reasons.display == true' >/dev/null

onboarding="$root/config/hypr/scripts/onboarding-control"
"$onboarding" status | jq -e '.format == "nocturne-onboarding-v1" and .total == 7 and (.hardware.monitors|type == "number")' >/dev/null
"$onboarding" acknowledge-shortcuts | jq -e '.steps.shortcuts == true' >/dev/null
printf '%s\n' 'invalid power state' > "$XDG_CONFIG_HOME/nocturne/power-lab.json"
"$power_lab" status | jq -e '.format == "nocturne-power-lab-v2" and .lowBattery == 20 and .brightness.step == 5' >/dev/null
[[ $(stat -c %a "$XDG_CONFIG_HOME/nocturne/power-lab.json") == 600 ]]
"$root/bin/nocturne-doctor" --help | grep -Fq -- '--json'
printf 'NOCTURNE // shell interaction contracts passed\n'
