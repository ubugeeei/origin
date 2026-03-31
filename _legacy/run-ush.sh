#!/usr/bin/env sh
set -eu

script_name=${1:-}
runner_name=$(basename "$0")
runner_name=${runner_name%.sh}

if [ -z "$script_name" ]; then
  printf '%s\n' "usage: $runner_name <script.ush> [args...]" >&2
  exit 1
fi

shift

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
target="$repo_root/scripts/$script_name"

if [ ! -f "$target" ]; then
  printf '%s\n' "ush script not found: $target" >&2
  exit 1
fi

cd "$repo_root"

if command -v ush >/dev/null 2>&1; then
  exec ush "$target" "$@"
fi

if command -v nix >/dev/null 2>&1; then
  exec nix run .#ush -- "$target" "$@"
fi

printf '%s\n' "ush is not installed and nix is unavailable; run ./_legacy/bootstrap-macos.sh first." >&2
exit 1
