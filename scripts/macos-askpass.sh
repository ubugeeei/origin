#!/usr/bin/env sh
set -eu

exec /usr/bin/osascript <<'APPLESCRIPT'
return text returned of (display dialog "origin needs your administrator password to continue." default answer "" with hidden answer buttons {"Cancel", "OK"} default button "OK")
APPLESCRIPT
