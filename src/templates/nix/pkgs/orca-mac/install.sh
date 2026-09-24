runHook preInstall

mkdir -p "$out/Applications"
cp -R Orca.app "$out/Applications/Orca.app"

# Orca ships its own `orca` CLI inside the bundle. It resolves the app through
# symlinks, so linking it keeps the CLI next to the exact app it drives.
mkdir -p "$out/bin"
ln -s "$out/Applications/Orca.app/Contents/Resources/bin/orca" "$out/bin/orca"

runHook postInstall
