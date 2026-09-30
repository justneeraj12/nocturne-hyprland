#!/usr/bin/env bash
set -euo pipefail

CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
NOCTURNE_STATE="$STATE_HOME/nocturne-ubuntu"
POINTER="$NOCTURNE_STATE/active-backup"

if [[ ! -s "$POINTER" ]]; then
  printf 'No active Nocturne backup was found at %s\n' "$POINTER" >&2
  exit 1
fi

BACKUP_DIR=$(<"$POINTER")
if [[ ! -d "$BACKUP_DIR" ]]; then
  printf 'Backup directory is missing: %s\n' "$BACKUP_DIR" >&2
  exit 1
fi

remove_installed() {
  local path=$1 relative backup
  relative=${path#"$HOME"/}
  backup="$BACKUP_DIR/$relative"
  rm -rf -- "$path"
  if [[ -e "$backup" || -L "$backup" ]]; then
    mkdir -p "$(dirname -- "$path")"
    cp -a -- "$backup" "$path"
  fi
}

for path in \
  "$CONFIG_HOME/kitty/kitty.conf" \
  "$CONFIG_HOME/tmux/tmux.conf" \
  "$CONFIG_HOME/btop/themes/nocturne.theme" \
  "$CONFIG_HOME/btop/btop.conf" \
  "$CONFIG_HOME/fastfetch/config.jsonc" \
  "$CONFIG_HOME/nocturne-nvim" \
  "$DATA_HOME/applications/nocturne-dashboard.desktop" \
  "$HOME/.local/bin/nocturne-dashboard"; do
  remove_installed "$path"
done

rm -f -- "$DATA_HOME/backgrounds/nocturne-grid.png"

if [[ -s "$BACKUP_DIR/gsettings.tsv" ]] && command -v gsettings >/dev/null 2>&1; then
  while IFS=$'\t' read -r schema key value; do
    gsettings set "$schema" "$key" "$value"
  done < "$BACKUP_DIR/gsettings.tsv"
fi

rm -f -- "$POINTER"
printf 'Nocturne was removed and the backup was restored from:\n  %s\n' "$BACKUP_DIR"
printf 'Installed apt packages were left in place.\n'
