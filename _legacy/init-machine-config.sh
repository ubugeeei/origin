#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TARGET="$ROOT/machine/local.env"
script_name=$(basename "$0")
script_name=${script_name%.sh}
force=0

if [ "${1-}" = "--force" ]; then
  force=1
  shift
fi

if [ "$#" -ne 0 ]; then
  echo "usage: $script_name [--force]" >&2
  exit 64
fi

if [ -f "$TARGET" ] && [ "$force" -ne 1 ]; then
  echo "$TARGET already exists. Re-run with --force to overwrite it." >&2
  exit 1
fi

quote_sh() {
  printf "'%s'" "$(printf "%s" "$1" | sed "s/'/'\\\\''/g")"
}

primary_user=$(id -un)
primary_home=$(dscl . -read "/Users/$primary_user" NFSHomeDirectory | awk '{print $2}')
arch=$(uname -m)

case "$arch" in
  arm64)
    origin_system="aarch64-darwin"
    ;;
  x86_64)
    origin_system="x86_64-darwin"
    ;;
  *)
    echo "unsupported architecture: $arch" >&2
    exit 1
    ;;
esac

origin_workspace_root="${primary_home}/Source"
origin_computer_name=$(scutil --get ComputerName 2>/dev/null || printf '%s\n' "$primary_user Mac")
origin_local_host_name=$(scutil --get LocalHostName 2>/dev/null || printf '%s\n' "$primary_user")
origin_host_name=$(scutil --get HostName 2>/dev/null || printf '%s\n' "$origin_local_host_name")
origin_git_user_name=$(git config --global user.name 2>/dev/null || true)
origin_git_user_email=$(git config --global user.email 2>/dev/null || true)
origin_github_user=$(git config --global github.user 2>/dev/null || true)
origin_git_signing_key=$(git config --global user.signingkey 2>/dev/null || true)
origin_git_gpg_format=$(git config --global gpg.format 2>/dev/null || true)

mkdir -p "$ROOT/machine"

cat > "$TARGET" <<EOF
# Machine-specific overrides for this repository.
# This file is intentionally gitignored.
# Keep this file data-only: use plain single-quoted ORIGIN_* assignments only.

ORIGIN_SYSTEM=$(quote_sh "$origin_system")
ORIGIN_USERNAME=$(quote_sh "$primary_user")
ORIGIN_HOME=$(quote_sh "$primary_home")
ORIGIN_WORKSPACE_ROOT=$(quote_sh "$origin_workspace_root")

ORIGIN_COMPUTER_NAME=$(quote_sh "$origin_computer_name")
ORIGIN_HOSTNAME=$(quote_sh "$origin_host_name")
ORIGIN_LOCAL_HOSTNAME=$(quote_sh "$origin_local_host_name")

ORIGIN_GIT_USER_NAME=$(quote_sh "$origin_git_user_name")
ORIGIN_GIT_USER_EMAIL=$(quote_sh "$origin_git_user_email")
ORIGIN_GITHUB_USER=$(quote_sh "$origin_github_user")
ORIGIN_GIT_SIGNING_KEY=$(quote_sh "$origin_git_signing_key")
ORIGIN_GIT_GPG_FORMAT=$(quote_sh "$origin_git_gpg_format")

# Optional bundle identifier namespace for generated Chrome app wrappers.
# ORIGIN_APP_NAMESPACE='dev.origin'
EOF

echo "Wrote $TARGET"
echo "Edit it if you want to pin values that differ from this machine."
