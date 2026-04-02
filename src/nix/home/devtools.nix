{ pkgs, ... }:
(import ../../../generated/home/devtools.nix {
  inherit pkgs;
})
