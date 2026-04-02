#!/usr/bin/env bash
set -euo pipefail

usage_text='usage:
  clone github <owner>/<repo> [alias]
  clone gitlab <group>/<repo> [alias]
  clone github.com/<owner>/<repo> [alias]
  clone git@github.com:<owner>/<repo>.git [alias]

options:
  -a, --alias <name>  clone into <repo>--<name>
  -h, --help          show this help

notes:
  - only GitHub and GitLab are supported
  - only SSH remotes are accepted
  - repositories are cloned under $GHQ_ROOT or $HOME/Source'

fail() {
  local message=$1
  local code=${2:-64}
  printf 'clone: %s\n' "$message" >&2
  exit "$code"
}

print_usage() {
  printf '%s\n' "$usage_text" >&2
}

maybe_normalize_host() {
  case "$1" in
    github | github.com)
      printf 'github.com\n'
      ;;
    gitlab | gitlab.com)
      printf 'gitlab.com\n'
      ;;
    *)
      return 1
      ;;
  esac
}

parse_ssh_url() {
  local spec=$1

  case "$spec" in
    git@github.com:*)
      printf '%s\t%s\n' 'github.com' "${spec#git@github.com:}"
      return 0
      ;;
    git@gitlab.com:*)
      printf '%s\t%s\n' 'gitlab.com' "${spec#git@gitlab.com:}"
      return 0
      ;;
  esac

  return 1
}

parse_spec() {
  local spec=$1
  local host_part
  local slug_part
  local normalized_host

  if parse_ssh_url "$spec"; then
    return 0
  fi

  case "$spec" in
    http://* | https://*)
      fail "only SSH remotes are supported"
      ;;
  esac

  case "$spec" in
    */*)
      ;;
    *)
      return 1
      ;;
  esac

  host_part=${spec%%/*}
  slug_part=${spec#*/}
  normalized_host=$(maybe_normalize_host "$host_part" || true)

  if [ -z "$normalized_host" ]; then
    fail "unsupported host: $host_part"
  fi

  printf '%s\t%s\n' "$normalized_host" "$slug_part"
}

validate_slug() {
  local cleaned=$1
  local old_ifs

  cleaned=${cleaned#/}
  cleaned=${cleaned%/}
  cleaned=${cleaned%.git}

  if [ -z "$cleaned" ]; then
    fail "repository path is required"
  fi

  case "$cleaned" in
    */*)
      ;;
    *)
      fail "repository path must look like <owner>/<repo>"
      ;;
  esac

  old_ifs=$IFS
  IFS='/'
  set -- $cleaned
  IFS=$old_ifs

  for part in "$@"; do
    if [ -z "$part" ]; then
      fail "repository path contains an empty segment"
    fi

    if [ "$part" = "." ] || [ "$part" = ".." ]; then
      fail "repository path contains an invalid segment: $part"
    fi
  done

  printf '%s\n' "$cleaned"
}

validate_alias() {
  local alias_name=$1

  if [ -z "$alias_name" ]; then
    fail "alias must not be empty"
  fi

  case "$alias_name" in
    */*)
      fail "alias must not contain '/'"
      ;;
  esac

  if [ "$alias_name" = "." ] || [ "$alias_name" = ".." ]; then
    fail "alias must not be '.' or '..'"
  fi
}

command_path() {
  command -v "$1" 2>/dev/null || true
}

parse_host_and_slug() {
  local pair=$1
  PARSED_HOST=$(printf '%s\n' "$pair" | awk -F '\t' 'NR == 1 { print $1 }')
  PARSED_SLUG=$(printf '%s\n' "$pair" | awk -F '\t' 'NR == 1 { print $2 }')
}

alias_name=${CLONE_ALIAS:-}
host=""
slug=""
first=${CLONE_FIRST:-}
second=${CLONE_SECOND:-}
third=${CLONE_THIRD:-}

args_count=0
[ -n "$first" ] && args_count=$((args_count + 1))
[ -n "$second" ] && args_count=$((args_count + 1))
[ -n "$third" ] && args_count=$((args_count + 1))

case "$args_count" in
  1)
    parsed=$(parse_spec "$first" || true)
    if [ -z "$parsed" ]; then
      print_usage
      fail "missing host or repository path"
    fi
    parse_host_and_slug "$parsed"
    host=$PARSED_HOST
    slug=$PARSED_SLUG
    ;;
  2)
    normalized_host=$(maybe_normalize_host "$first" || true)

    if [ -n "$normalized_host" ]; then
      host=$normalized_host
      slug=$second
    else
      if [ -n "$alias_name" ]; then
        fail "alias specified twice"
      fi
      parsed=$(parse_spec "$first" || true)
      if [ -z "$parsed" ]; then
        print_usage
        fail "missing host or repository path"
      fi
      parse_host_and_slug "$parsed"
      host=$PARSED_HOST
      slug=$PARSED_SLUG
      alias_name=$second
    fi
    ;;
  3)
    normalized_host=$(maybe_normalize_host "$first" || true)
    [ -n "$normalized_host" ] || fail "unsupported host: $first"
    [ -z "$alias_name" ] || fail "alias specified twice"
    host=$normalized_host
    slug=$second
    alias_name=$third
    ;;
  *)
    print_usage
    fail "unexpected arguments"
    ;;
esac

slug=$(validate_slug "$slug")

if [ -n "$alias_name" ]; then
  validate_alias "$alias_name"
fi

repo_name=${slug##*/}
namespace=${slug%/*}
local_name=$repo_name
if [ -n "$alias_name" ]; then
  local_name="${repo_name}--${alias_name}"
fi

root=${GHQ_ROOT:-"$HOME/Source"}
target="${root}/${host}/${namespace}/${local_name}"
remote="git@${host}:${slug}.git"

if [ "$host" != "github.com" ] && [ "$host" != "gitlab.com" ]; then
  fail "only github.com and gitlab.com are supported"
fi

[ ! -e "$target" ] || fail "target already exists: $target"

git=$(command_path git)
[ -n "$git" ] || fail "git is not installed"

mkdir -p "$(dirname "$target")"

printf 'cloning %s\n' "$remote"
printf '  -> %s\n' "$target"

exec "$git" clone "$remote" "$target"
