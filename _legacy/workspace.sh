#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
exec bash "$script_dir/../src/workspace/repos.sh" workspace "$@"
