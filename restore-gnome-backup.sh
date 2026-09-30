#!/usr/bin/env bash
set -euo pipefail

if (($# != 1)); then
  printf 'Usage: %s /path/to/backup-directory\n' "$0" >&2
  exit 2
fi

BACKUP_DIR=$(realpath -- "$1")
DCONF_DUMP="$BACKUP_DIR/dconf-full.ini"
HOME_ARCHIVE="$BACKUP_DIR/home-configs.tar.gz"

if [[ ! -s "$DCONF_DUMP" || ! -s "$HOME_ARCHIVE" ]]; then
  printf 'This does not look like a complete Nocturne backup: %s\n' "$BACKUP_DIR" >&2
  exit 1
fi

printf 'This will restore GNOME, extension, terminal, and shell settings from:\n  %s\n' "$BACKUP_DIR"
printf 'Your current versions of those files/settings will be replaced.\n'
read -r -p 'Type RESTORE to continue: ' confirmation
[[ "$confirmation" == RESTORE ]] || { printf 'Cancelled.\n'; exit 1; }

tar -xzf "$HOME_ARCHIVE" -C "$HOME"
dconf load / < "$DCONF_DUMP"

printf '\nConfiguration restored. Log out and back in to fully reload GNOME Shell.\n'
printf 'This script does not remove packages installed after the snapshot.\n'

