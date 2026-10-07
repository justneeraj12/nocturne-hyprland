#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install_packages=false
dry_run=false

usage() {
  printf '%s\n' \
    'Usage: ./install.sh [--install-packages] [--dry-run]' \
    '' \
    'Apply Nocturne to an existing Hyprland 0.56+ installation.' \
    '' \
    '  --install-packages  Install Ubuntu or Arch build/runtime dependencies.' \
    '  --dry-run           Validate without changing the live configuration.'
}

for argument in "$@"; do
  case $argument in
    --install-packages) install_packages=true ;;
    --dry-run) dry_run=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$argument" >&2; usage >&2; exit 2 ;;
  esac
done

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
