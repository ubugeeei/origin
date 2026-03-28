{
  stdenvNoCC,
  fetchurl,
  xar,
  cpio,
  gzip,
  lib,
}:
stdenvNoCC.mkDerivation rec {
  pname = "azookey-mac";
  version = "0.1.3";

  src = fetchurl {
    url = "https://github.com/azooKey/azooKey-Desktop/releases/download/v${version}/azooKey-release-signed.pkg";
    hash = "sha256-eR03Ieky7sZib3Byc40kYuAVjVbuPNbuxe0vdmNIG9I=";
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
    cp "$src" azooKey.pkg
    xar -xf azooKey.pkg
    mkdir payload
    cd payload
    gzip -dc ../azooKey-tmp.pkg/Payload | cpio -idm

    mkdir -p "$out/Library/Input Methods"
    cp -R azooKeyMac.app "$out/Library/Input Methods/azooKeyMac.app"

    # Expose the input method bundle in app listings as well.
    mkdir -p "$out/Applications"
    ln -s "$out/Library/Input Methods/azooKeyMac.app" "$out/Applications/azooKeyMac.app"

    runHook postInstall
  '';

  meta = with lib; {
    description = "azooKey Japanese input method for macOS";
    homepage = "https://github.com/azooKey/azooKey-Desktop";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.asl20;
    platforms = platforms.darwin;
    maintainers = [ ];
  };
}
