#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
data_home=${XDG_DATA_HOME:-"$HOME/.local/share"}
state_home=${XDG_STATE_HOME:-"$HOME/.local/state"}
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
cache_home=${XDG_CACHE_HOME:-"$HOME/.cache"}
runtime_root="$data_home/nocturne-agent-runtime"
release_dir="$runtime_root/releases/b11309"
model_dir="$data_home/nocturne-agent-models"
download_dir="$cache_home/nocturne-agent/downloads"
config_dir="$config_home/nocturne-agent"
runtime_archive="$download_dir/llama-b11309-bin-ubuntu-cuda-12.8-x64.tar.gz"
model_file="$model_dir/Qwen3-4B-Q4_K_M.gguf"

runtime_url='https://github.com/ggml-org/llama.cpp/releases/download/b11309/llama-b11309-bin-ubuntu-cuda-12.8-x64.tar.gz'
runtime_sha='24217ae03a01d7aefefb8ac5f6ade0885a32687bcba65302e9b2cb4a35b2216a'
model_url='https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf'
model_sha='7485fe6f11af29433bc51cab58009521f205840f5b4ae3a32fa7f92e8534fdf5'

download_verified() {
  local url=$1 destination=$2 expected=$3 actual
  if [[ -f $destination ]]; then
    actual=$(sha256sum "$destination" | cut -d' ' -f1)
    [[ $actual == "$expected" ]] && return 0
  fi
  curl --fail --location --continue-at - --output "$destination" "$url"
  actual=$(sha256sum "$destination" | cut -d' ' -f1)
  [[ $actual == "$expected" ]] || {
    printf 'Checksum verification failed for %s\n' "$destination" >&2
    exit 1
  }
}

mkdir -p "$download_dir" "$release_dir" "$model_dir" "$state_home/nocturne-agent" "$config_dir"
chmod 700 "$state_home/nocturne-agent"
printf 'Downloading verified llama.cpp CUDA runtime (171 MB)...\n'
download_verified "$runtime_url" "$runtime_archive" "$runtime_sha"
printf 'Downloading verified Qwen3-4B Q4 model (2.50 GB)...\n'
download_verified "$model_url" "$model_file" "$model_sha"

tar --extract --gzip --file "$runtime_archive" --directory "$release_dir" --no-same-owner --no-same-permissions
server=$(find "$release_dir" -type f -name llama-server -print -quit)
[[ -n $server ]] || { printf 'llama-server was not found in the verified archive\n' >&2; exit 1; }
chmod +x "$server"
ln -sfn "$release_dir" "$runtime_root/current"

key_file="$state_home/nocturne-agent/model-api-key"
if [[ ! -s $key_file ]]; then
  python3 -c 'import secrets,sys; open(sys.argv[1], "w", encoding="utf-8").write(secrets.token_hex(32) + "\n")' "$key_file"
fi
chmod 600 "$key_file"

config_file="$config_dir/config.json"
python3 -c 'import json,os,sys,tempfile; p=sys.argv[1]; d=json.load(open(p,encoding="utf-8")) if os.path.exists(p) else {}; d.update({"model_enabled":True,"model_name":"nocturne-qwen3-4b","model_endpoint":"http://127.0.0.1:8844/v1/chat/completions"}); fd,t=tempfile.mkstemp(dir=os.path.dirname(p)); os.close(fd); open(t,"w",encoding="utf-8").write(json.dumps(d,indent=2)+"\n"); os.chmod(t,0o600); os.replace(t,p)' "$config_file"

"$root_dir/install-agent.sh"
systemctl --user restart nocturne-agent.service 2>/dev/null || true
systemctl --user start nocturne-agent-model.service
rm -f -- "$runtime_archive"
printf 'Nocturne local model installed and started. It unloads after 75 idle seconds.\n'
