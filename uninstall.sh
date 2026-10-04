#!/usr/bin/env bash
set -euo pipefail

CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
BIN_HOME="$HOME/.local/bin"
NOCTURNE_STATE="$STATE_HOME/nocturne"
POINTER="$NOCTURNE_STATE/original-preinstall-backup"

backup=${1:-}
if [[ -z $backup ]]; then
  [[ -s $POINTER ]] || {
    printf 'No original Nocturne backup pointer exists at %s\n' "$POINTER" >&2
    printf 'Pass a snapshot directory explicitly if it was moved.\n' >&2
    exit 1
  }
  backup=$(<"$POINTER")
fi
backup_input=$backup
if ! backup=$(realpath -e -- "$backup"); then
  printf 'Backup directory is missing: %s\n' "$backup_input" >&2
  exit 1
fi
[[ -f $backup/README.txt ]] && grep -Fq 'Created before applying Hyprland:' "$backup/README.txt" || {
  printf 'This does not look like a Nocturne pre-install snapshot: %s\n' "$backup" >&2
  exit 1
}

printf 'Nocturne will restore this snapshot:\n  %s\n\n' "$backup"
printf 'The current desktop config will be preserved before rollback.\n'
printf 'Type RESTORE to continue: '
read -r confirmation
[[ $confirmation == RESTORE ]] || {
  printf 'Rollback cancelled.\n'
  exit 0
}

rollback="$NOCTURNE_STATE/backups/pre-rollback-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$rollback"

systemctl --user disable --now \
  nocturne-wallpaper-cycle.service \
  nocturne-easyeffects.service \
  nocturne-audio-autoswitch.service >/dev/null 2>&1 || true
pkill -f '^.*/nocturne-native( |$)' 2>/dev/null || true
pkill -f '^.*/nocturne-(dashboard|visualizer)( |$)' 2>/dev/null || true

config_items=(hypr gtklock waybar wofi swaync mako xdg-desktop-portal kitty btop tmux qt6ct cava fastfetch nocturne systemd autostart kdeglobals)
for relative in "${config_items[@]}"; do
  current="$CONFIG_HOME/$relative"
  if [[ -e $current || -L $current ]]; then
    cp -a -- "$current" "$rollback/$relative"
  fi
  rm -rf -- "$current"
  if [[ -e $backup/$relative || -L $backup/$relative ]]; then
    cp -a -- "$backup/$relative" "$current"
  fi
done

desktop_targets=(
  steam.desktop
  org.kde.kdeconnect.app.desktop
  org.gnome.Settings.desktop
  nocturne-settings.desktop
  nocturne-native.desktop
  nocturne-visualizer.desktop
  nocturne-google-keep.desktop
  nocturne-google-drive.desktop
)
mkdir -p "$rollback/applications" "$DATA_HOME/applications"
for desktop in "${desktop_targets[@]}"; do
  current="$DATA_HOME/applications/$desktop"
  if [[ -e $current || -L $current ]]; then
    cp -a -- "$current" "$rollback/applications/$desktop"
  fi
  rm -f -- "$current"
  if [[ -e $backup/applications/$desktop ]]; then
    cp -a -- "$backup/applications/$desktop" "$current"
  fi
done

mkdir -p "$rollback/desktop"
if [[ -f $HOME/Desktop/steam.desktop ]]; then
  cp -a -- "$HOME/Desktop/steam.desktop" "$rollback/desktop/steam.desktop"
  if [[ -e $backup/desktop/steam.desktop ]]; then
    cp -a -- "$backup/desktop/steam.desktop" "$HOME/Desktop/steam.desktop"
  elif [[ -e $NOCTURNE_STATE/steam-desktop-pre-gpu.desktop ]]; then
    cp -a -- "$NOCTURNE_STATE/steam-desktop-pre-gpu.desktop" "$HOME/Desktop/steam.desktop"
  else
    sed -i "s|^Exec=$BIN_HOME/steam|Exec=/usr/bin/steam|" "$HOME/Desktop/steam.desktop"
  fi
fi
while IFS= read -r -d '' shortcut; do
  if grep -Fq "Exec=$BIN_HOME/steam steam://rungameid/" "$shortcut"; then
    sed -i "s|^Exec=$BIN_HOME/steam steam://rungameid/|Exec=steam steam://rungameid/|" "$shortcut"
  fi
done < <(find "$DATA_HOME/applications" -maxdepth 1 -type f -name '*.desktop' -print0)

mkdir -p "$rollback/environment.d" "$CONFIG_HOME/environment.d"
environment_target="$CONFIG_HOME/environment.d/10-nocturne-path.conf"
if [[ -e $environment_target ]]; then
  cp -a -- "$environment_target" "$rollback/environment.d/10-nocturne-path.conf"
fi
rm -f -- "$environment_target"
if [[ -e $backup/environment.d/10-nocturne-path.conf ]]; then
  cp -a -- "$backup/environment.d/10-nocturne-path.conf" "$environment_target"
fi

systemctl --user unmask \
  mako.service \
  waybar.service \
  swaync.service \
  hypridle.service \
  hyprpaper.service \
  hyprpolkitagent.service \
  xdg-desktop-portal-gtk.service \
  xdg-desktop-portal-gnome.service \
  localsearch-3.service >/dev/null 2>&1 || true
systemctl --user daemon-reload >/dev/null 2>&1 || true

bin_targets=(nocturne-native nocturne-dashboard nocturne-visualizer nocturne-settings nocturne-web-app nocturne-wallpaper-cycle nocturne-doctor nocturne-portable steam)
mkdir -p "$rollback/bin" "$BIN_HOME"
for binary in "${bin_targets[@]}"; do
  current="$BIN_HOME/$binary"
  if [[ -e $current || -L $current ]]; then
    cp -a -- "$current" "$rollback/bin/$binary"
  fi
  rm -f -- "$current"
  if [[ -e $backup/bin/$binary || -L $backup/bin/$binary ]]; then
    cp -a -- "$backup/bin/$binary" "$current"
  fi
done

for data_group in backgrounds color-schemes; do
  mkdir -p "$rollback/$data_group" "$DATA_HOME/$data_group"
done
for background in nocturne-default.png nocturne-grid.png; do
  current="$DATA_HOME/backgrounds/$background"
  if [[ -e $current || -L $current ]]; then
    cp -a -- "$current" "$rollback/backgrounds/$background"
  fi
  rm -f -- "$current"
  if [[ -e $backup/backgrounds/$background || -L $backup/backgrounds/$background ]]; then
    cp -a -- "$backup/backgrounds/$background" "$current"
  fi
done
current="$DATA_HOME/color-schemes/Nocturne.colors"
if [[ -e $current || -L $current ]]; then
  cp -a -- "$current" "$rollback/color-schemes/Nocturne.colors"
fi
rm -f -- "$current"
if [[ -e $backup/color-schemes/Nocturne.colors || -L $backup/color-schemes/Nocturne.colors ]]; then
  cp -a -- "$backup/color-schemes/Nocturne.colors" "$current"
fi

if [[ -s $backup/mime.tsv ]]; then
  while IFS=$'\t' read -r mime desktop; do
    [[ -n $mime && -n $desktop ]] || continue
    xdg-mime default "$desktop" "$mime"
  done < "$backup/mime.tsv"
fi

command -v update-desktop-database >/dev/null 2>&1 && \
  update-desktop-database "$DATA_HOME/applications" >/dev/null 2>&1 || true

printf '\nNocturne config was rolled back from:\n  %s\n' "$backup"
printf 'The removed Nocturne state is recoverable from:\n  %s\n' "$rollback"
printf 'Packages, Hyprshot and Kooha were left installed. Log out once.\n'
