runHook preInstall

mkdir -p "$out/bin"
cp package/vp "$out/bin/vp"
chmod +x "$out/bin/vp"
ln -s vp "$out/bin/vite-plus"

runHook postInstall
