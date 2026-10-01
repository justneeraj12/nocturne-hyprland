#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
data_home=${XDG_DATA_HOME:-"$HOME/.local/share"}
ocr_root="$data_home/nocturne-agent-ocr"
temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT

mkdir -p "$ocr_root"
(
  cd "$temporary"
  apt-get download tesseract-ocr tesseract-ocr-eng
  for package in ./*.deb; do
    dpkg-deb --extract "$package" "$ocr_root"
  done
)
"$root_dir/install-agent.sh"
"$HOME/.local/bin/nocturne-ocr" --version >/dev/null
printf 'Private NØX OCR runtime installed without changing system packages.\n'
