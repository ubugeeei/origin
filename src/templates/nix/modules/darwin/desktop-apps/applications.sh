echo "Setting up /Applications..." >&2
managed_root_manifest="/Applications/.nix-managed-apps"
lsregister='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'
set -- @ALLOWED_APPS@

if [ -f "$managed_root_manifest" ]; then
  while IFS= read -r app_name; do
    [ -n "$app_name" ] || continue
    rm -rf "/Applications/$app_name"
  done < "$managed_root_manifest"
fi

: > "$managed_root_manifest"
rm -rf /Applications/Nix\ Apps
find @APP_ENV@/Applications -maxdepth 1 -type l | while read -r app; do
  src="$(readlink "$app")"
  app_name="$(basename "$src")"
  should_expose=0
  for allowed in "$@"; do
    if [ "$app_name" = "$allowed" ]; then
      should_expose=1
      break
    fi
  done
  [ "$should_expose" -eq 1 ] || continue
  rm -rf "/Applications/$app_name"
  /usr/bin/ditto "$src" "/Applications/$app_name"
  echo "$app_name" >> "$managed_root_manifest"
  "$lsregister" -f "/Applications/$app_name" >/dev/null 2>&1 || true
done

/usr/bin/killall Dock >/dev/null 2>&1 || true
