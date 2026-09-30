#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
BACKUP_DIR=$(realpath -- "$ROOT_DIR/backups/current-backup")

(cd "$BACKUP_DIR" && sha256sum --check SHA256SUMS)

# Restore the original GNOME/macOS dconf state without touching the new
# Hyprland, Waybar, terminal, VS Code, or Zsh configuration.
dconf load / < "$BACKUP_DIR/dconf-full.ini"

# GTK 4 had a real macOS-theme override in the snapshot. GTK 3 did not.
tar -xzf "$BACKUP_DIR/home-configs.tar.gz" -C "$HOME" .config/gtk-4.0
rm -f -- \
  "$CONFIG_HOME/gtk-4.0/nocturne.css" \
  "$CONFIG_HOME/gtk-4.0/gtk.pre-nocturne.css" \
  "$CONFIG_HOME/gtk-3.0/nocturne.css" \
  "$CONFIG_HOME/gtk-3.0/gtk.pre-nocturne.css" \
  "$CONFIG_HOME/gtk-3.0/gtk.css" \
  "$CONFIG_HOME/autostart/nocturne-first-login.desktop"

if [[ -x "$HOME/.local/bin/nocturne-session-theme" ]]; then
  "$HOME/.local/bin/nocturne-session-theme" gnome
fi

printf 'Original GNOME/macOS dconf and GTK appearance restored.\n'
printf 'Hyprland and its independent configuration were left intact.\n'
