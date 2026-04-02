runHook preUnpack

mkdir -p binary core
tar -xzf "$src" -C binary
tar -xzf "$core" -C core

runHook postUnpack
