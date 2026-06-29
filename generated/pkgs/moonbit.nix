let
  package = args: let
    stdenvNoCC = args.stdenvNoCC;
    fetchurl = args.fetchurl;
    lib = args.lib;
  in stdenvNoCC.mkDerivation rec {
    pname = "moonbit";
    version = "0.1.20260512";
    src = fetchurl {
      url = "https://cli.moonbitlang.com/binaries/latest/moonbit-darwin-aarch64.tar.gz";
      hash = "sha256-sYz+Zw+KY8RxpxmPAbG+/sbD0/0StKT3/sRHz4Q1k8Y=";
    };
    core = fetchurl {
      url = "https://cli.moonbitlang.com/cores/core-latest.tar.gz";
      hash = "sha256-RIIbTf7xeEzqsIPbPJ80B31Ai9dmZ/2F/GE/28RlVqY=";
    };
    dontConfigure = true;
    dontBuild = true;
    unpackPhase = builtins.readFile ../../src/templates/nix/pkgs/moonbit/unpack.sh;
    installPhase = builtins.readFile ../../src/templates/nix/pkgs/moonbit/install.sh;
    meta = {
      description = "MoonBit toolchain for macOS arm64";
      homepage = "https://www.moonbitlang.com/download/";
      mainProgram = "moon";
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      license = lib.licenses.asl20;
      platforms = [ "aarch64-darwin" ];
      maintainers = [  ];
    };
  };
in package