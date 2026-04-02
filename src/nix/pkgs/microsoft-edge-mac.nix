{
  stdenvNoCC,
  fetchurl,
  xar,
  cpio,
  gzip,
  lib,
}:
stdenvNoCC.mkDerivation rec {
  pname = "microsoft-edge-mac";
  version = "145.0.3800.97";

  src = fetchurl {
    url = "https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/99e9a53e-4987-4ced-b408-2832d8a3e50a/MicrosoftEdge-${version}.pkg";
    hash = "sha256-Riwe4o3ygV/ikC8y6YRgKbfFfSB6/7lzvk12yNsenqs=";
  };

  nativeBuildInputs = [
    xar
    cpio
    gzip
  ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p work
    cd work
    cp "$src" MicrosoftEdge.pkg
    xar -xf MicrosoftEdge.pkg
    mkdir payload
    cd payload
    gzip -dc ../MicrosoftEdge-${version}.pkg/Payload | cpio -idm

    mkdir -p "$out/Applications"
    cp -R "Microsoft Edge.app" "$out/Applications/"

    mkdir -p "$out/bin"
    cat > "$out/bin/microsoft-edge" <<'EOF'
    #!/bin/sh
    exec /usr/bin/open -a "Microsoft Edge" "$@"
    EOF
    chmod +x "$out/bin/microsoft-edge"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Microsoft Edge browser for macOS";
    homepage = "https://www.microsoft.com/en-us/edge/business/download";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = platforms.darwin;
    maintainers = [ ];
  };
}
