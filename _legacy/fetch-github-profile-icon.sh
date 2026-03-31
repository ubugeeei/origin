#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
script_name=$(basename "$0")
script_name=${script_name%.sh}

case "${1-}" in
  -h|--help)
    printf 'usage: %s [github-username]\n' "$script_name"
    exit 0
    ;;
esac

if [ "$#" -gt 1 ]; then
  printf 'usage: %s [github-username]\n' "$script_name" >&2
  exit 64
fi

if [ "$#" -eq 1 ]; then
  exec env FETCH_GITHUB_USERNAME="$1" \
    "$SCRIPT_DIR/run-ush.sh" fetch-github-profile-icon.ush
fi

exec "$SCRIPT_DIR/run-ush.sh" fetch-github-profile-icon.ush
