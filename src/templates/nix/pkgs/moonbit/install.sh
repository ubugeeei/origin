runHook preInstall

mkdir -p "$out"
cp -R binary/. "$out/"
chmod +x "$out"/bin/*
chmod +x "$out"/bin/internal/tcc

mkdir -p "$out/lib"
cp -R core/core "$out/lib/core"
# The upstream install script bundles the core library after extraction.
# That step currently trips over binary path discovery inside the macOS Nix
# sandbox, while the extracted toolchain itself works correctly.

runHook postInstall
