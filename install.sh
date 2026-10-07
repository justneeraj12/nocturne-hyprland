#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install_packages=false
dry_run=false
guided=false
show_welcome=true

if (($# == 0)) && [[ -t 0 && -t 1 ]]; then
  guided=true
fi

usage() {
  printf '%s\n' \
    'Usage: ./install.sh [--guided|--install-packages|--user-only|--dry-run] [--no-welcome]' \
    '' \
    'Install NOC 2.0 on Ubuntu or Arch with a reversible user configuration.' \
    '' \
    '  --guided           Open the terminal installation wizard.' \
    '  --install-packages  Install Ubuntu or Arch build/runtime dependencies.' \
    '  --user-only         Apply NOC when all dependencies already exist.' \
    '  --dry-run           Validate without changing the live configuration.' \
    '  --no-welcome        Do not print the post-install welcome summary.'
}

for argument in "$@"; do
  case $argument in
    --install-packages) install_packages=true ;;
    --user-only) install_packages=false ;;
    --guided) guided=true ;;
    --dry-run) dry_run=true ;;
    --no-welcome) show_welcome=false ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$argument" >&2; usage >&2; exit 2 ;;
  esac
done

failure_report() {
  local code=$?
  printf '\nNOC INSTALL // STOPPED SAFELY\n' >&2
  printf 'The installer failed before claiming success (exit %s).\n' "$code" >&2
  if [[ -s ${XDG_STATE_HOME:-"$HOME/.local/state"}/nocturne/last-preinstall-backup ]]; then
    printf 'Your latest pre-install snapshot is recorded at:\n  %s\n' \
      "$(<"${XDG_STATE_HOME:-"$HOME/.local/state"}/nocturne/last-preinstall-backup")" >&2
  fi
  printf 'Fix the reported error and rerun this same command; installation is idempotent.\n' >&2
  exit "$code"
}
trap failure_report ERR

guided_install() {
  local distro='unknown' pretty='Unknown Linux' hypr='not found' free='unknown' choice confirmation
  if [[ -r /etc/os-release ]]; then
    # Distribution metadata is trusted only for display here; package routing
    # is independently validated by nocturne-platform.
    distro=$(sed -n 's/^ID=//p' /etc/os-release | head -1 | tr -d '"')
    pretty=$(sed -n 's/^PRETTY_NAME=//p' /etc/os-release | head -1 | tr -d '"')
  fi
  command -v Hyprland >/dev/null 2>&1 && hypr=$(Hyprland --version 2>/dev/null | head -1 || true)
  free=$(df -h "$HOME" 2>/dev/null | awk 'NR == 2 {print $4}' || printf unknown)
  if [[ -x $root/bin/nocturne-banner ]]; then
    COLUMNS=${COLUMNS:-80} "$root/bin/nocturne-banner" --compact
  else
    printf 'N O C // NOCTURNE 2.0\n'
  fi
  printf '\nGUIDED INSTALL // REVERSIBLE BY DEFAULT\n'
  printf '  Platform   %s (%s)\n' "$pretty" "$distro"
  printf '  Hyprland   %s\n' "$hypr"
  printf '  Home free  %s\n' "$free"
  printf '  Backup     created before live configuration changes\n'
  printf '  Privacy    no telemetry · no account · no document scanning\n\n'
  printf '[1] Full setup — packages + shell + recovery (recommended)\n'
  printf '[2] User-only setup — dependencies are already installed\n'
  printf '[3] Validate source and installation contracts only\n'
  printf '[4] Exit without changing anything\n'
  printf '> '
  IFS= read -r choice
  case $choice in
    1) install_packages=true ;;
    2) install_packages=false ;;
    3) dry_run=true; return ;;
    4) printf 'No changes made.\n'; exit 0 ;;
    *) printf 'Unknown selection; no changes made.\n' >&2; exit 2 ;;
  esac
  printf '\nNOC will preserve existing desktop configuration, install its own user files,\n'
  printf 'and leave browser profiles, Steam data and personal files untouched.\n'
  $install_packages && printf 'The distribution package step will request sudo authentication.\n'
  printf 'Type INSTALL to continue: '
  IFS= read -r confirmation
  [[ $confirmation == INSTALL ]] || { printf 'Installation cancelled; no changes made.\n'; exit 0; }
}

$guided && guided_install

if "$dry_run" && "$install_packages"; then
  printf '%s\n' '--dry-run and --install-packages cannot be combined.' >&2
  exit 2
fi

if "$dry_run"; then
  "$root/scripts/validate-nocturne.sh"
  printf 'Dry run complete; no packages or live configuration were changed.\n'
  exit 0
fi

if "$install_packages"; then
  "$root/scripts/install-packages.sh"
fi

"$root/scripts/install-hyprshot.sh"
"$root/scripts/install-kooha.sh"
"$root/apply-hyprland.sh"

if $show_welcome && [[ -x $HOME/.local/bin/nocturne-welcome ]]; then
  "$HOME/.local/bin/nocturne-welcome" post-install
fi
