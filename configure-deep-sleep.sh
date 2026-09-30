#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  printf 'Run this installer as root (for example: pkexec %q).\n' "$0" >&2
  exit 1
fi

if [[ ! -r /sys/power/mem_sleep ]] || ! grep -qw deep /sys/power/mem_sleep; then
  printf 'Refusing to force S3: this kernel does not expose the deep sleep mode.\n' >&2
  exit 1
fi

# NVIDIA requires its /proc/driver/nvidia/suspend integration whenever
# PreserveVideoMemoryAllocations is enabled. Enabling all hooks also keeps
# hibernate and suspend-then-hibernate from regressing later.
required_units=()
if [[ -e /proc/driver/nvidia/params ]] && \
   grep -q '^PreserveVideoMemoryAllocations: 1' /proc/driver/nvidia/params; then
  required_units=(
    nvidia-suspend.service
    nvidia-resume.service
    nvidia-hibernate.service
    nvidia-suspend-then-hibernate.service
  )
  for unit in "${required_units[@]}"; do
    if ! systemctl cat "$unit" >/dev/null 2>&1; then
      printf 'Required NVIDIA sleep unit is missing: %s\n' "$unit" >&2
      exit 1
    fi
  done
fi

install -d -m 0755 /etc/systemd/sleep.conf.d /etc/systemd/logind.conf.d
install -m 0644 \
  "$ROOT_DIR/config/systemd/sleep.conf.d/10-nocturne-deep.conf" \
  /etc/systemd/sleep.conf.d/10-nocturne-deep.conf
install -m 0644 \
  "$ROOT_DIR/config/systemd/logind.conf.d/10-nocturne-lid.conf" \
  /etc/systemd/logind.conf.d/10-nocturne-lid.conf

if ((${#required_units[@]})); then
  systemctl enable "${required_units[@]}"
fi

systemctl daemon-reload

printf 'Sleep policy installed. Kernel modes: %s\n' "$(< /sys/power/mem_sleep)"
printf 'A real suspend was intentionally not started; save work before testing it.\n'
