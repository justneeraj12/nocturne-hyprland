#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if ((EUID != 0)); then
  printf 'Run this through pkexec: pkexec %s\n' "$0" >&2
  exit 1
fi

module_path=$(modinfo -n msi_ec 2>/dev/null || true)
[[ -n $module_path ]] || {
  printf 'The signed msi_ec module is not present in this Ubuntu kernel.\n' >&2
  exit 1
}

modprobe msi_ec
if [[ ! -d /sys/devices/platform/msi-ec ]]; then
  modprobe -r msi_ec 2>/dev/null || true
  printf 'This firmware was rejected by msi_ec; no persistent change was made.\n' >&2
  exit 1
fi

install -m 0644 "$ROOT_DIR/assets/nocturne-msi-ec.conf" /etc/modules-load.d/nocturne-msi-ec.conf
systemctl restart power-profiles-daemon.service

printf 'MSI controls enabled. Exposed interfaces:\n'
find /sys/devices/platform/msi-ec -maxdepth 1 -type f -printf '  %f\n' | sort
