#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
data_home=${XDG_DATA_HOME:-"$HOME/.local/share"}
state_home=${XDG_STATE_HOME:-"$HOME/.local/state"}
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
app_dir="$data_home/nocturne-agent"
bin_dir="$HOME/.local/bin"
unit_dir="$config_home/systemd/user"

mkdir -p "$app_dir/nocturne_agent" "$bin_dir" "$unit_dir" "$state_home/nocturne-agent"
chmod 700 "$state_home/nocturne-agent"

for source in "$root_dir"/src/nocturne_agent/*.py; do
  install -m 0644 "$source" "$app_dir/nocturne_agent/$(basename -- "$source")"
done
install -m 0755 "$root_dir/bin/nocturne-agent" "$bin_dir/nocturne-agent"
install -m 0755 "$root_dir/bin/nocturne-agent-service" "$bin_dir/nocturne-agent-service"
install -m 0755 "$root_dir/bin/nocturne-agent-model" "$bin_dir/nocturne-agent-model"
install -m 0755 "$root_dir/bin/nox" "$bin_dir/nox"
install -m 0755 "$root_dir/bin/nocturne-ocr" "$bin_dir/nocturne-ocr"
install -m 0644 "$root_dir/config/systemd/user/nocturne-agent.socket" "$unit_dir/nocturne-agent.socket"
install -m 0644 "$root_dir/config/systemd/user/nocturne-agent.service" "$unit_dir/nocturne-agent.service"
install -m 0644 "$root_dir/config/systemd/user/nocturne-agent-model.service" "$unit_dir/nocturne-agent-model.service"
install -m 0644 "$root_dir/config/systemd/user/nocturne-agent-model-idle.service" "$unit_dir/nocturne-agent-model-idle.service"
install -m 0644 "$root_dir/config/systemd/user/nocturne-agent-model-idle.timer" "$unit_dir/nocturne-agent-model-idle.timer"

systemctl --user daemon-reload
systemctl --user enable --now nocturne-agent.socket
systemctl --user try-restart nocturne-agent.service
printf 'NØX installed. Open it with: nox\n'
