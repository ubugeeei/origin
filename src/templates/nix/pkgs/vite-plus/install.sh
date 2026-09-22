runHook preInstall

mkdir -p "$out/bin"

if [ -f package/vp.exe ]; then
  cp package/vp.exe "$out/bin/vp.exe"
  chmod +x "$out/bin/vp.exe"
  ln -s vp.exe "$out/bin/vite-plus.exe"
  ln -s vp.exe "$out/bin/vp"
  ln -s vp.exe "$out/bin/vite-plus"
else
  cp package/vp "$out/bin/vp"
  chmod +x "$out/bin/vp"
  ln -s vp "$out/bin/vite-plus"
fi

# Home Manager owns setup and points current/bin/vp at this store path.
# Without this upstream marker, the first invocation bootstraps a second,
# npm-managed CLI and delegates to it, bypassing the Nix version pin.
touch "$out/bin/.vp-setup-complete"

runHook postInstall
