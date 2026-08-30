runHook preInstall

# The disk image ships a wrapper installer; the real bundle lives under its
# Helpers directory.
mkdir -p "$out/Applications"
cp -R "Kimi Installer.app/Contents/Helpers/Kimi.app" "$out/Applications/Kimi.app"

mkdir -p "$out/bin"
cat > "$out/bin/kimi" <<'EOF'
#!/bin/sh
exec /usr/bin/open -a "Kimi" "$@"
EOF
chmod +x "$out/bin/kimi"

runHook postInstall
