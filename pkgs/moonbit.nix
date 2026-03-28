{
  stdenvNoCC,
  fetchurl,
  lib,
}:
stdenvNoCC.mkDerivation rec {
  pname = "moonbit";
  version = "0.1.20260309";

  src = fetchurl {
    # MoonBit's public macOS download currently resolves through the latest alias.
    url = "https://cli.moonbitlang.com/binaries/latest/moonbit-darwin-aarch64.tar.gz";
    hash = "sha256-HVfJDlZjBWqIB2Vfmum96TSqblJKyOAEarCTgxP/6KI=";
  };

  core = fetchurl {
    url = "https://cli.moonbitlang.com/cores/core-latest.tar.gz";
    hash = "sha256-uBzb9dpP+vSIaj+ifL52wLTLxgQNMfJJ+Zp5ENAstlo=";
  };

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack

    mkdir -p binary core
    tar -xzf "$src" -C binary
    tar -xzf "$core" -C core

    runHook postUnpack
  '';

  installPhase = ''
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
  '';

  meta = with lib; {
    description = "MoonBit toolchain for macOS arm64";
    homepage = "https://www.moonbitlang.com/download/";
    mainProgram = "moon";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.asl20;
    platforms = [ "aarch64-darwin" ];
    maintainers = [ ];
  };
}
