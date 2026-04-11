#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
flake_ref="path:$ROOT#workstation"
primary_user=$(id -un)
primary_home=$(dscl . -read "/Users/$primary_user" NFSHomeDirectory | awk '{print $2}')
nix_bin=/nix/var/nix/profiles/default/bin/nix

load_machine_env() {
  tab=$(printf '\t')

  while IFS="$tab" read -r key value; do
    [ -n "$key" ] || continue

    case "$key" in
      ORIGIN_SYSTEM|ORIGIN_USERNAME|ORIGIN_HOME|ORIGIN_WORKSPACE_ROOT|ORIGIN_COMPUTER_NAME|ORIGIN_HOSTNAME|ORIGIN_LOCAL_HOSTNAME|ORIGIN_GIT_USER_NAME|ORIGIN_GIT_USER_EMAIL|ORIGIN_GITHUB_USER|ORIGIN_GIT_SIGNING_KEY|ORIGIN_GIT_GPG_FORMAT|ORIGIN_APP_NAMESPACE|ORIGIN_TOUCH_ID_SUDO_AUTH)
        export "$key=$value"
        ;;
      *)
        echo "unexpected machine env key: $key" >&2
        exit 1
        ;;
    esac
  done <<EOF
$("$ROOT/_legacy/print-machine-env.sh")
EOF
}

cd "$ROOT"

if [ ! -f "$ROOT/machine/local.env" ]; then
  echo "info machine/local.env not found; using values derived from the current Mac."
  echo "info run ./_legacy/init-machine-config.sh if you want to pin them."
fi

load_machine_env

"$ROOT/src/tnix/sync.sh"

if command -v darwin-rebuild >/dev/null 2>&1; then
  sudo /usr/bin/env \
    HOME="$primary_home" \
    NIX_CONFIG="experimental-features = nix-command flakes" \
    ORIGIN_SYSTEM="$ORIGIN_SYSTEM" \
    ORIGIN_USERNAME="$ORIGIN_USERNAME" \
    ORIGIN_HOME="$ORIGIN_HOME" \
    ORIGIN_WORKSPACE_ROOT="$ORIGIN_WORKSPACE_ROOT" \
    ORIGIN_COMPUTER_NAME="$ORIGIN_COMPUTER_NAME" \
    ORIGIN_HOSTNAME="$ORIGIN_HOSTNAME" \
    ORIGIN_LOCAL_HOSTNAME="$ORIGIN_LOCAL_HOSTNAME" \
    ORIGIN_GIT_USER_NAME="$ORIGIN_GIT_USER_NAME" \
    ORIGIN_GIT_USER_EMAIL="$ORIGIN_GIT_USER_EMAIL" \
    ORIGIN_GITHUB_USER="$ORIGIN_GITHUB_USER" \
    ORIGIN_GIT_SIGNING_KEY="$ORIGIN_GIT_SIGNING_KEY" \
    ORIGIN_GIT_GPG_FORMAT="$ORIGIN_GIT_GPG_FORMAT" \
    ORIGIN_APP_NAMESPACE="$ORIGIN_APP_NAMESPACE" \
    ORIGIN_TOUCH_ID_SUDO_AUTH="$ORIGIN_TOUCH_ID_SUDO_AUTH" \
    "$(command -v darwin-rebuild)" switch --flake "$flake_ref" --impure
  exit 0
fi

if [ ! -x "$nix_bin" ]; then
  echo "nix is not installed" >&2
  exit 1
fi

sudo /usr/bin/env \
  HOME="$primary_home" \
  NIX_CONFIG="experimental-features = nix-command flakes" \
  ORIGIN_SYSTEM="$ORIGIN_SYSTEM" \
  ORIGIN_USERNAME="$ORIGIN_USERNAME" \
  ORIGIN_HOME="$ORIGIN_HOME" \
  ORIGIN_WORKSPACE_ROOT="$ORIGIN_WORKSPACE_ROOT" \
  ORIGIN_COMPUTER_NAME="$ORIGIN_COMPUTER_NAME" \
  ORIGIN_HOSTNAME="$ORIGIN_HOSTNAME" \
  ORIGIN_LOCAL_HOSTNAME="$ORIGIN_LOCAL_HOSTNAME" \
  ORIGIN_GIT_USER_NAME="$ORIGIN_GIT_USER_NAME" \
  ORIGIN_GIT_USER_EMAIL="$ORIGIN_GIT_USER_EMAIL" \
  ORIGIN_GITHUB_USER="$ORIGIN_GITHUB_USER" \
  ORIGIN_GIT_SIGNING_KEY="$ORIGIN_GIT_SIGNING_KEY" \
  ORIGIN_GIT_GPG_FORMAT="$ORIGIN_GIT_GPG_FORMAT" \
  ORIGIN_APP_NAMESPACE="$ORIGIN_APP_NAMESPACE" \
  ORIGIN_TOUCH_ID_SUDO_AUTH="$ORIGIN_TOUCH_ID_SUDO_AUTH" \
  "$nix_bin" run github:LnL7/nix-darwin#darwin-rebuild -- switch --flake "$flake_ref" --impure
