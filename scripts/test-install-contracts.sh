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

printf 'NOCTURNE // installer and rollback contracts match\n'
