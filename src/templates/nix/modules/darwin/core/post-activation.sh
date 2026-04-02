target_shell="@TARGET_SHELL@"
current_shell="$(/usr/bin/dscl . -read /Users/@USERNAME@ UserShell 2>/dev/null | /usr/bin/awk '{print $2}')"

if ! /usr/bin/grep -qx "$target_shell" "$systemConfig/etc/shells"; then
  echo "Skipping login shell update because $target_shell is not in the managed shells list." >&2
elif [ "$current_shell" != "$target_shell" ]; then
  echo "Setting login shell for @USERNAME@ to $target_shell..." >&2
  /usr/bin/dscl . -create /Users/@USERNAME@ UserShell "$target_shell"
fi
