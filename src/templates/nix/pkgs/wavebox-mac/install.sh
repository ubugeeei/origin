runHook preInstall

mkdir -p "$out/Applications"
cp -R Wavebox.app "$out/Applications/Wavebox.app"

mkdir -p "$out/bin"
cat > "$out/bin/wavebox" <<'EOF'
#!/bin/sh
exec /usr/bin/open -a "Wavebox" "$@"
EOF
chmod +x "$out/bin/wavebox"

runHook postInstall
