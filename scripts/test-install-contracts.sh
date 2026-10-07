#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

read_targets() {
  local script=$1
  sed -n 's/^bin_targets=(\(.*\))$/\1/p' "$script" | tr ' ' '\n' | sed '/^$/d' | sort -u
}

apply_targets=$(read_targets "$root/apply-hyprland.sh")
uninstall_targets=$(read_targets "$root/uninstall.sh")

if [[ $apply_targets != "$uninstall_targets" ]]; then
  printf 'Installer and rollback binary manifests differ:\n' >&2
  diff -u <(printf '%s\n' "$apply_targets") <(printf '%s\n' "$uninstall_targets") >&2 || true
  exit 1
fi

grep -Fq 'original-preinstall-backup' "$root/apply-hyprland.sh"
grep -Fq 'Type RESTORE to continue' "$root/uninstall.sh"
grep -Fq 'rollback-' "$root/uninstall.sh"
grep -Fq 'nocturne-context.timer' "$root/apply-hyprland.sh"
grep -Fq 'nocturne-context.timer' "$root/uninstall.sh"
grep -Fq 'nocturne-session.target' "$root/apply-hyprland.sh"
grep -Fq 'nocturne-session.target' "$root/uninstall.sh"

test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
printf '%s\n' 'ID=arch' > "$test_root/arch-release"
printf '%s\n' 'ID=ubuntu' 'ID_LIKE=debian' > "$test_root/ubuntu-release"

arch_platform=$(NOCTURNE_OS_RELEASE_FILE="$test_root/arch-release" "$root/bin/nocturne-platform" status)
ubuntu_platform=$(NOCTURNE_OS_RELEASE_FILE="$test_root/ubuntu-release" "$root/bin/nocturne-platform" status)
jq -e '.family == "arch" and .packageManager == "pacman" and .supported == true' <<< "$arch_platform" >/dev/null
jq -e '.family == "debian" and .packageManager == "apt" and .supported == true' <<< "$ubuntu_platform" >/dev/null
mkdir -p "$test_root/bin"
printf '%s\n' '#!/usr/bin/env bash' 'exit 2' > "$test_root/bin/checkupdates"
chmod +x "$test_root/bin/checkupdates"
[[ $(PATH="$test_root/bin:$PATH" NOCTURNE_OS_RELEASE_FILE="$test_root/arch-release" "$root/bin/nocturne-platform" pending) == 0 ]]
[[ $(NOCTURNE_OS_RELEASE_FILE="$test_root/arch-release" "$root/bin/nocturne-platform" upgrade-command) == 'sudo pacman -Syu' ]]
[[ $(NOCTURNE_OS_RELEASE_FILE="$test_root/ubuntu-release" "$root/bin/nocturne-platform" upgrade-command) == 'sudo apt-get update && sudo apt-get upgrade' ]]

arch_plan=$(NOCTURNE_OS_RELEASE_FILE="$test_root/arch-release" "$root/scripts/install-packages.sh" --print)
ubuntu_plan=$(NOCTURNE_OS_RELEASE_FILE="$test_root/ubuntu-release" "$root/scripts/install-packages.sh" --print)
jq -e '.family == "arch" and (.packages | index("layer-shell-qt")) != null and
  (.packages | index("xdg-desktop-portal-hyprland")) != null and
  (.packages | index("okular")) != null and (.packages | index("qpdfview")) == null' <<< "$arch_plan" >/dev/null
jq -e '.family == "debian" and (.packages | index("qml6-module-org-kde-layershell")) != null and
  (.packages | index("qpdfview")) != null' <<< "$ubuntu_plan" >/dev/null

grep -Fq 'nocturne-polkit-agent' "$root/config/systemd/user/nocturne-polkit.service"
grep -Fq "platform upgrade-command" "$root/config/hypr/scripts/system-maintenance"
! grep -Eq '\b(apt|apt-get|pacman)\b' "$root/config/hypr/scripts/system-maintenance"

printf 'NOCTURNE // installer and rollback contracts match\n'
