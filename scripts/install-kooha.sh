#!/usr/bin/env bash
set -euo pipefail

readonly application=io.github.seadve.Kooha
readonly remote=flathub
readonly repository=https://dl.flathub.org/repo/flathub.flatpakrepo

command -v flatpak >/dev/null 2>&1 || {
  printf 'Flatpak is required to install Kooha.\n' >&2
  exit 1
}

flatpak remote-add --user --if-not-exists "$remote" "$repository"
flatpak install --user --noninteractive -y "$remote" "$application"
printf 'Installed Kooha for the current user.\n'
