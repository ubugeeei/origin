#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
script_name=$(basename "$0")
script_name=${script_name%.sh}

if [ "$#" -eq 0 ]; then
  printf 'usage: %s <browser>\n' "$script_name" >&2
  printf 'example: %s dia\n' "$script_name" >&2
  exit 1
fi

case "$1" in
  -h|--help)
    printf 'usage: %s <browser>\n' "$script_name"
    printf 'example: %s dia\n' "$script_name"
    exit 0
    ;;
esac

browser=$1
shift

if [ "$#" -ne 0 ]; then
  printf 'usage: %s <browser>\n' "$script_name" >&2
  exit 1
fi

exec env SET_DEFAULT_BROWSER_TARGET="$browser" \
  "$SCRIPT_DIR/run-ush.sh" set-default-browser.ush
