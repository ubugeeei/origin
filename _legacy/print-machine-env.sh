#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
script_name=$(basename "$0")
script_name=${script_name%.sh}
mode=tsv
allowed_key_pattern='ORIGIN_(SYSTEM|USERNAME|HOME|WORKSPACE_ROOT|COMPUTER_NAME|HOSTNAME|LOCAL_HOSTNAME|GIT_USER_NAME|GIT_USER_EMAIL|GITHUB_USER|GIT_SIGNING_KEY|GIT_GPG_FORMAT|APP_NAMESPACE|TOUCH_ID_SUDO_AUTH)'

if [ "${1-}" = "--export" ]; then
  mode=export
  shift
fi

if [ "$#" -ne 0 ]; then
  echo "usage: $script_name [--export]" >&2
  exit 64
fi

quote_sh() {
  printf "'%s'" "$(printf "%s" "$1" | sed "s/'/'\\\\''/g")"
}

validate_machine_env_file() {
  file=$1
  line_no=0

  while IFS= read -r line || [ -n "$line" ]; do
    line_no=$((line_no + 1))
    trimmed=$(printf "%s" "$line" | sed 's/^[[:space:]]*//')

    case "$trimmed" in
      ''|'#'*)
        continue
        ;;
    esac

    if ! printf '%s\n' "$trimmed" | grep -Eq "^(${allowed_key_pattern})='([^']|'\\\\'')*'$"; then
      echo "invalid machine/local.env line $line_no" >&2
      echo "only single-quoted ORIGIN_* assignments are allowed" >&2
      exit 1
    fi
  done < "$file"
}

primary_user=$(id -un)
primary_home=$(dscl . -read "/Users/$primary_user" NFSHomeDirectory | awk '{print $2}')
arch=$(uname -m)

case "$arch" in
  arm64)
    ORIGIN_SYSTEM="aarch64-darwin"
    ;;
  x86_64)
    ORIGIN_SYSTEM="x86_64-darwin"
    ;;
  *)
    echo "unsupported architecture: $arch" >&2
    exit 1
    ;;
esac

ORIGIN_USERNAME=$primary_user
ORIGIN_HOME=$primary_home
ORIGIN_WORKSPACE_ROOT="${primary_home}/Source"
ORIGIN_COMPUTER_NAME=$(scutil --get ComputerName 2>/dev/null || printf '%s\n' "$primary_user Mac")
ORIGIN_LOCAL_HOSTNAME=$(scutil --get LocalHostName 2>/dev/null || printf '%s\n' "$primary_user")
ORIGIN_HOSTNAME=$(scutil --get HostName 2>/dev/null || printf '%s\n' "$ORIGIN_LOCAL_HOSTNAME")
ORIGIN_GIT_USER_NAME=$(git config --global user.name 2>/dev/null || true)
ORIGIN_GIT_USER_EMAIL=$(git config --global user.email 2>/dev/null || true)
ORIGIN_GITHUB_USER=$(git config --global github.user 2>/dev/null || true)
ORIGIN_GIT_SIGNING_KEY=$(git config --global user.signingkey 2>/dev/null || true)
ORIGIN_GIT_GPG_FORMAT=$(git config --global gpg.format 2>/dev/null || true)
ORIGIN_APP_NAMESPACE="dev.origin"
ORIGIN_TOUCH_ID_SUDO_AUTH="false"

if [ -f "$ROOT/machine/local.env" ]; then
  validate_machine_env_file "$ROOT/machine/local.env"
  set -a
  # shellcheck disable=SC1091
  . "$ROOT/machine/local.env"
  set +a
fi

emit_tsv() {
  printf '%s\t%s\n' "$1" "$2"
}

emit_export() {
  printf 'export %s=%s\n' "$1" "$(quote_sh "$2")"
}

emit() {
  key=$1
  value=$2

  if [ "$mode" = "export" ]; then
    emit_export "$key" "$value"
  else
    emit_tsv "$key" "$value"
  fi
}

emit ORIGIN_SYSTEM "$ORIGIN_SYSTEM"
emit ORIGIN_USERNAME "$ORIGIN_USERNAME"
emit ORIGIN_HOME "$ORIGIN_HOME"
emit ORIGIN_WORKSPACE_ROOT "$ORIGIN_WORKSPACE_ROOT"
emit ORIGIN_COMPUTER_NAME "$ORIGIN_COMPUTER_NAME"
emit ORIGIN_HOSTNAME "$ORIGIN_HOSTNAME"
emit ORIGIN_LOCAL_HOSTNAME "$ORIGIN_LOCAL_HOSTNAME"
emit ORIGIN_GIT_USER_NAME "$ORIGIN_GIT_USER_NAME"
emit ORIGIN_GIT_USER_EMAIL "$ORIGIN_GIT_USER_EMAIL"
emit ORIGIN_GITHUB_USER "$ORIGIN_GITHUB_USER"
emit ORIGIN_GIT_SIGNING_KEY "$ORIGIN_GIT_SIGNING_KEY"
emit ORIGIN_GIT_GPG_FORMAT "$ORIGIN_GIT_GPG_FORMAT"
emit ORIGIN_APP_NAMESPACE "$ORIGIN_APP_NAMESPACE"
emit ORIGIN_TOUCH_ID_SUDO_AUTH "$ORIGIN_TOUCH_ID_SUDO_AUTH"
