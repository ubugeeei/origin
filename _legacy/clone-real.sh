#!/usr/bin/env sh
# Compatibility for callers of the old environment-based clone entrypoint.
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
set --
if [ -n "${CLONE_FIRST:-}" ]; then set -- "$@" "$CLONE_FIRST"; fi
if [ -n "${CLONE_SECOND:-}" ]; then set -- "$@" "$CLONE_SECOND"; fi
if [ -n "${CLONE_THIRD:-}" ]; then set -- "$@" "$CLONE_THIRD"; fi
if [ -n "${CLONE_ALIAS:-}" ]; then set -- "$@" --alias "$CLONE_ALIAS"; fi
exec "$script_dir/clone.sh" "$@"
