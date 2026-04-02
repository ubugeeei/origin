user_group="$(/usr/bin/id -gn @USERNAME@)"

for path in "@HOME_DIRECTORY@/go" "@HOME_DIRECTORY@/.cargo"; do
  if [ ! -e "$path" ]; then
    continue
  fi

  current_owner="$(/usr/bin/stat -f '%Su' "$path" 2>/dev/null || true)"
  if [ "$current_owner" != "@USERNAME@" ]; then
    echo "Fixing ownership for $path..." >&2
    /usr/sbin/chown -R "@USERNAME@:$user_group" "$path"
  fi
done
