#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tnix_repo=${TNIX_REPO:-${ORIGIN_TNIX_REPO:-"$HOME/Source/github.com/ubugeeei/tnix"}}
nix_bin=${NIX_BIN:-}

if [ -z "$nix_bin" ]; then
  if command -v nix >/dev/null 2>&1; then
    nix_bin=$(command -v nix)
  else
    nix_bin=/nix/var/nix/profiles/default/bin/nix
  fi
fi

if [ ! -x "$nix_bin" ]; then
  printf '%s\n' "nix is unavailable; cannot build generated .nix files from tnix sources." >&2
  exit 1
fi

if [ ! -f "$ROOT/tnix.config.tnix" ]; then
  exit 0
fi

if [ ! -d "$tnix_repo/.git" ] && [ ! -f "$tnix_repo/flake.nix" ]; then
  printf '%s\n' "tnix checkout not found at $tnix_repo" >&2
  printf '%s\n' 'clone ubugeeei/tnix under $HOME/Source/github.com/ubugeeei/tnix or set TNIX_REPO.' >&2
  exit 1
fi

cd "$ROOT"
NIX_CONFIG="experimental-features = nix-command flakes" \
  "$nix_bin" run "path:$tnix_repo#tnix" -- build .
