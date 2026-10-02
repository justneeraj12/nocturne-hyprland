#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$ROOT_DIR"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  printf 'This project is not initialized as a Git repository.\n' >&2
  exit 1
}
git remote get-url origin >/dev/null 2>&1 || {
  printf 'The GitHub origin remote is not configured.\n' >&2
  exit 1
}

git add -- .gitignore README.md agent assets bin config patches scripts *.sh
git diff --cached --quiet && {
  printf 'No project changes to sync.\n'
  exit 0
}

# Exclude this file so the scanner does not match its own detection patterns.
if git diff --cached -- . ':(exclude)sync-github.sh' | rg -i '(github_pat_|gho_[A-Za-z0-9]{20,}|AKIA[A-Z0-9]{16}|-----BEGIN .*PRIVATE KEY-----|api[_-]?key.{0,8}[=:][[:space:]]*[A-Za-z0-9_./+-]{20,})' >/dev/null; then
  printf 'Refusing to sync: the staged diff resembles a credential. Review it first.\n' >&2
  exit 2
fi

message=${1:-"Update Nocturne $(date +%Y-%m-%d)"}
git commit -m "$message"
git push origin HEAD:main
