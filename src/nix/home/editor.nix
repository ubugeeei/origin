{ lib, pkgs, ... }:
(import ../../../generated/home/editor.nix {
  inherit lib pkgs;
})
