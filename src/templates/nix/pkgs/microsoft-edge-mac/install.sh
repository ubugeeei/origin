runHook preInstall

mkdir -p work
cd work
cp "$src" MicrosoftEdge.pkg
xar -xf MicrosoftEdge.pkg
mkdir payload
cd payload
gzip -dc ../MicrosoftEdge-@VERSION@.pkg/Payload | cpio -idm

mkdir -p "$out/Applications"
cp -R "Microsoft Edge.app" "$out/Applications/"

mkdir -p "$out/bin"
cat > "$out/bin/microsoft-edge" <<'EOF'
#!/bin/sh
exec /usr/bin/open -a "Microsoft Edge" "$@"
EOF
chmod +x "$out/bin/microsoft-edge"

runHook postInstall
