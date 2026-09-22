let
  pkgs = import @nixpkgs@ {
    system = "@system@";
    overlays = [ (import @rustOverlay@) ];
  };
  spec = builtins.fromJSON (builtins.readFile (builtins.getEnv "ORIGIN_RUST_SPEC"));
in
pkgs.rust-bin.fromRustupToolchain spec
