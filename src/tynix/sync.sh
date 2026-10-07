#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
tynix_repo=${TYNIX_REPO:-${ORIGIN_TYNIX_REPO:-"$HOME/Source/github.com/ubugeeei-prod/tynix"}}
nix_bin=${NIX_BIN:-}

if [ -z "$nix_bin" ]; then
  if command -v nix >/dev/null 2>&1; then
    nix_bin=$(command -v nix)
  else
    nix_bin=/nix/var/nix/profiles/default/bin/nix
  fi
fi

if [ ! -x "$nix_bin" ]; then
  printf '%s\n' "nix is unavailable; cannot build generated .nix files from tynix sources." >&2
  exit 1
fi

if [ ! -f "$ROOT/tynix.config.tynix" ]; then
  exit 0
fi

if [ ! -d "$tynix_repo/.git" ] && [ ! -f "$tynix_repo/flake.nix" ]; then
  printf '%s\n' "tynix checkout not found at $tynix_repo" >&2
  printf '%s\n' 'clone ubugeeei-prod/tynix under $HOME/Source/github.com/ubugeeei-prod/tynix or set TYNIX_REPO.' >&2
  exit 1
fi

cd "$ROOT"
NIX_CONFIG="experimental-features = nix-command flakes" \
  "$nix_bin" run "path:$tynix_repo#tynix" -- build .
