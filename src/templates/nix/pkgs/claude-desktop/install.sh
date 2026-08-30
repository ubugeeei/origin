runHook preInstall

mkdir -p "$out/Applications"
cp -R Claude.app "$out/Applications/Claude.app"

mkdir -p "$out/bin"
cat > "$out/bin/claude-desktop" <<'EOF'
#!/bin/sh
exec /usr/bin/open -a "Claude" "$@"
EOF
chmod +x "$out/bin/claude-desktop"

runHook postInstall
