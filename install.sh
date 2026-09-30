#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
NOCTURNE_STATE="$STATE_HOME/nocturne-ubuntu"
BACKUP_DIR="$NOCTURNE_STATE/backups/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
INSTALL_PACKAGES=false

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run] [--install-packages]

  --dry-run           Print the changes without making them.
  --install-packages  Install Kitty, tmux, btop, Fastfetch, Neovim, and a font.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --install-packages) INSTALL_PACKAGES=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
  esac
done

run() {
  if "$DRY_RUN"; then
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

copy_file() {
  local source=$1 destination=$2
  run mkdir -p "$(dirname -- "$destination")"
  run cp -- "$source" "$destination"
}

backup_path() {
  local path=$1 relative
  [[ -e "$path" || -L "$path" ]] || return 0
  relative=${path#"$HOME"/}
  run mkdir -p "$BACKUP_DIR/$(dirname -- "$relative")"
  run cp -a -- "$path" "$BACKUP_DIR/$relative"
}

save_setting() {
  local schema=$1 key=$2
  command -v gsettings >/dev/null 2>&1 || return 0
  if "$DRY_RUN"; then
    printf '+ save gsettings %s %s\n' "$schema" "$key"
  else
    printf '%s\t%s\t%s\n' "$schema" "$key" "$(gsettings get "$schema" "$key")" \
      >> "$BACKUP_DIR/gsettings.tsv"
  fi
}

set_setting() {
  local schema=$1 key=$2 value=$3
  command -v gsettings >/dev/null 2>&1 || return 0
  run gsettings set "$schema" "$key" "$value"
}

printf 'Nocturne Ubuntu setup\n'
printf '  source: %s\n' "$ROOT_DIR"
printf '  backup: %s\n\n' "$BACKUP_DIR"

if "$INSTALL_PACKAGES"; then
  run sudo apt update
  run sudo apt install -y kitty tmux btop fastfetch neovim fonts-jetbrains-mono
fi

missing=()
for command_name in kitty tmux btop fastfetch nvim; do
  command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
done
if ((${#missing[@]} > 0)) && ! "$INSTALL_PACKAGES" && ! "$DRY_RUN"; then
  printf 'Missing programs: %s\n' "${missing[*]}" >&2
  printf 'Run ./install.sh --install-packages, or install them and retry.\n' >&2
  exit 1
fi
if ((${#missing[@]} > 0)) && "$DRY_RUN"; then
  printf 'Note: the full install will require: %s\n' "${missing[*]}"
fi

run mkdir -p "$BACKUP_DIR"
for path in \
  "$CONFIG_HOME/kitty/kitty.conf" \
  "$CONFIG_HOME/tmux/tmux.conf" \
  "$CONFIG_HOME/btop/themes/nocturne.theme" \
  "$CONFIG_HOME/btop/btop.conf" \
  "$CONFIG_HOME/fastfetch/config.jsonc" \
  "$CONFIG_HOME/nocturne-nvim" \
  "$DATA_HOME/applications/nocturne-dashboard.desktop" \
  "$HOME/.local/bin/nocturne-dashboard"; do
  backup_path "$path"
done

if ! "$DRY_RUN"; then
  : > "$BACKUP_DIR/gsettings.tsv"
fi
save_setting org.gnome.desktop.interface color-scheme
save_setting org.gnome.desktop.interface monospace-font-name
save_setting org.gnome.desktop.background picture-uri
save_setting org.gnome.desktop.background picture-uri-dark
save_setting org.gnome.desktop.background picture-options

copy_file "$ROOT_DIR/config/kitty/kitty.conf" "$CONFIG_HOME/kitty/kitty.conf"
copy_file "$ROOT_DIR/config/tmux/tmux.conf" "$CONFIG_HOME/tmux/tmux.conf"
copy_file "$ROOT_DIR/config/btop/nocturne.theme" "$CONFIG_HOME/btop/themes/nocturne.theme"
copy_file "$ROOT_DIR/config/btop/btop.conf" "$CONFIG_HOME/btop/btop.conf"
copy_file "$ROOT_DIR/config/fastfetch/config.jsonc" "$CONFIG_HOME/fastfetch/config.jsonc"

run mkdir -p "$CONFIG_HOME/nocturne-nvim"
if ! "$DRY_RUN"; then
  cp -a -- "$ROOT_DIR/config/nocturne-nvim/." "$CONFIG_HOME/nocturne-nvim/"
else
  printf '+ cp -a %q/. %q/\n' "$ROOT_DIR/config/nocturne-nvim" "$CONFIG_HOME/nocturne-nvim"
fi

copy_file "$ROOT_DIR/assets/nocturne-grid.png" "$DATA_HOME/backgrounds/nocturne-grid.png"
copy_file "$ROOT_DIR/bin/nocturne-dashboard" "$HOME/.local/bin/nocturne-dashboard"
run chmod +x "$HOME/.local/bin/nocturne-dashboard"

desktop_file="$DATA_HOME/applications/nocturne-dashboard.desktop"
run mkdir -p "$(dirname -- "$desktop_file")"
if "$DRY_RUN"; then
  printf '+ create %q\n' "$desktop_file"
else
  sed "s|@LAUNCHER@|$HOME/.local/bin/nocturne-dashboard|g" \
    "$ROOT_DIR/assets/nocturne-dashboard.desktop.in" > "$desktop_file"
fi

wallpaper_uri="file://$DATA_HOME/backgrounds/nocturne-grid.png"
set_setting org.gnome.desktop.interface color-scheme prefer-dark
if fc-match 'MesloLGS Nerd Font Mono' | grep -qi 'Meslo'; then
  set_setting org.gnome.desktop.interface monospace-font-name 'MesloLGS Nerd Font Mono 11'
else
  set_setting org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 11'
fi
set_setting org.gnome.desktop.background picture-uri "$wallpaper_uri"
set_setting org.gnome.desktop.background picture-uri-dark "$wallpaper_uri"
set_setting org.gnome.desktop.background picture-options zoom

if "$DRY_RUN"; then
  printf '+ write active backup pointer\n'
else
  mkdir -p "$NOCTURNE_STATE"
  printf '%s\n' "$BACKUP_DIR" > "$NOCTURNE_STATE/active-backup"
fi

printf '\nDone. Open “Nocturne Dashboard” from the app grid or run:\n'
printf '  %s\n' "$HOME/.local/bin/nocturne-dashboard"
