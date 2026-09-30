#!/usr/bin/env bash
set -euo pipefail

if ((EUID != 0)); then
  printf 'Run through the graphical administrator prompt:\n  pkexec %q\n' "$0" >&2
  exit 1
fi

printf 'Cleaning generated crash reports and reproducible system caches only.\n'
find /var/crash -xdev -maxdepth 1 -type f -delete
apt-get clean
journalctl --vacuum-size=250M
systemctl reset-failed apport-autoreport.service
printf 'Done. Personal files, installed packages, profiles, and current logs were preserved.\n'
