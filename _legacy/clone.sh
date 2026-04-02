#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

usage_text='usage:
  clone github <owner>/<repo> [alias]
  clone gitlab <group>/<repo> [alias]
  clone github.com/<owner>/<repo> [alias]
  clone git@github.com:<owner>/<repo>.git [alias]

options:
  -a, --alias <name>  clone into <repo>--<name>
  -h, --help          show this help'

print_usage() {
  printf '%s\n' "$usage_text"
}

fail() {
  local message=$1
  local code=${2:-64}
  printf 'clone: %s\n' "$message" >&2
  exit "$code"
}

alias_name=""
declare -a args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--alias)
      [[ $# -ge 2 ]] || fail "missing value for $1"
      [[ -z $alias_name ]] || fail "alias specified twice"
      alias_name=$2
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        args+=("$1")
        shift
      done
      ;;
    -*)
      fail "unknown option: $1"
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

case ${#args[@]} in
  1|2|3)
    ;;
  *)
    print_usage >&2
    fail "unexpected arguments"
    ;;
esac

first=${args[0]}
second=${args[1]:-}
third=${args[2]:-}

exec env \
  CLONE_FIRST="$first" \
  CLONE_SECOND="$second" \
  CLONE_THIRD="$third" \
  CLONE_ALIAS="$alias_name" \
  "$SCRIPT_DIR/clone-real.sh"
