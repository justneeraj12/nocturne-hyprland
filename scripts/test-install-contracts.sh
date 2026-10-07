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
grep -Fq '# >>> Nocturne desktop >>>' "$root/apply-hyprland.sh"
grep -Fq '# >>> Nocturne desktop >>>' "$root/uninstall.sh"

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
  (.packages | index("okular")) != null and (.packages | index("qpdfview")) == null and
  (.packages | index("cups")) != null and (.packages | index("sane-airscan")) != null and
  (.packages | index("systemd-zram-generator")) != null' <<< "$arch_plan" >/dev/null
jq -e '.family == "debian" and (.packages | index("qml6-module-org-kde-layershell")) != null and
  (.packages | index("qpdfview")) != null and (.packages | index("cups")) != null and
  (.packages | index("sane-airscan")) != null and (.packages | index("systemd-zram-generator")) != null' <<< "$ubuntu_plan" >/dev/null

grep -Fq 'nocturne-polkit-agent' "$root/config/systemd/user/nocturne-polkit.service"
grep -Fq "platform upgrade-command" "$root/config/hypr/scripts/system-maintenance"
! grep -Eq '\b(apt|apt-get|pacman)\b' "$root/config/hypr/scripts/system-maintenance"

guard_home="$test_root/guard-home"
mkdir -p "$guard_home/.config/hypr" "$guard_home/.local/bin" "$test_root/guard-state" "$test_root/guard-bin"
printf '%s\n' 'return {}' > "$guard_home/.config/hypr/hyprland.lua"
printf '%s\n' '#!/usr/bin/env bash' 'case ${1:-status} in checkpoint) exit 0 ;; status) printf '\''{"exists":true}\n'\'' ;; esac' > "$test_root/guard-bin/recovery"
printf '%s\n' '#!/usr/bin/env bash' 'printf '\''{"family":"arch","supported":true}\n'\''' > "$test_root/guard-bin/platform"
printf '%s\n' '#!/usr/bin/env bash' '[[ ${1:-} == --self-test ]]' > "$test_root/guard-bin/native"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$test_root/guard-bin/xdg-desktop-portal-hyprland"
chmod +x "$test_root/guard-bin/"*
guard_env=(HOME="$guard_home" PATH="$test_root/guard-bin:$PATH" NOCTURNE_UPDATE_GUARD_STATE_ROOT="$test_root/guard-state" NOCTURNE_RECOVERY_TOOL="$test_root/guard-bin/recovery" NOCTURNE_PLATFORM_TOOL="$test_root/guard-bin/platform" NOCTURNE_NATIVE_TOOL="$test_root/guard-bin/native" NOCTURNE_HYPRLAND_CONFIG="$guard_home/.config/hypr/hyprland.lua" NOCTURNE_HYPRLAND_VERSION="0.56.0" NOCTURNE_PENDING_HYPRLAND_VERSION="0.57.0")
env "${guard_env[@]}" "$root/bin/nocturne-update-guard" status | jq -e '.format == "nocturne-update-guard-v1" and .phase == "checkpoint-only" and .hyprland.updateAvailable == true' >/dev/null
env "${guard_env[@]}" "$root/bin/nocturne-update-guard" prepare >/dev/null
env "${guard_env[@]}" "$root/bin/nocturne-update-guard" status | jq -e '.phase == "protected" and .prepared == true' >/dev/null
guard_verify=$(env "${guard_env[@]}" "$root/bin/nocturne-update-guard" verify 2>&1) || {
  printf 'Update Guard verification fixture failed:\n%s\n' "$guard_verify" >&2
  exit 1
}
env "${guard_env[@]}" "$root/bin/nocturne-update-guard" history | jq -e 'length == 1 and .[0].ok == true' >/dev/null

printf 'NOCTURNE // installer and rollback contracts match\n'
