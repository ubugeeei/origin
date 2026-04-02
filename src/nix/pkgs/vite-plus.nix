{ stdenvNoCC, fetchurl, lib }:
let
  packageName =
    if stdenvNoCC.hostPlatform.system == "aarch64-darwin" then
      "darwin-arm64"
    else if stdenvNoCC.hostPlatform.system == "x86_64-darwin" then
      "darwin-x64"
    else
      throw "vite-plus is only packaged for macOS";

  integrityHash =
    if packageName == "darwin-arm64" then
      "sha512-YGKHyehGe0aWnaPQfGMRzQrhmRzBKZ53rNMwvTekk7qajRZlfp+tlOeDZLRfJVFubP26pmjPg8drV25oRd5HUQ=="
    else
      "sha512-hUOBVbs8LGHRX0KkUiSYKfWUpUXXN3EB+aGKbT41sLh/E+KYP4V3ybHhLB70xxZsCXHbVL9XQ0dw10fMfDO1uA==";
in
stdenvNoCC.mkDerivation rec {
  pname = "vite-plus";
  version = "0.1.11";

  src = fetchurl {
    url = "https://registry.npmjs.org/@voidzero-dev/vite-plus-cli-${packageName}/-/vite-plus-cli-${packageName}-${version}.tgz";
    hash = integrityHash;
  };

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    tar -xzf "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    cp package/vp "$out/bin/vp"
    chmod +x "$out/bin/vp"
    ln -s vp "$out/bin/vite-plus"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Vite+ global CLI for macOS";
    homepage = "https://viteplus.dev/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.mit;
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    maintainers = [ ];
  };
}
