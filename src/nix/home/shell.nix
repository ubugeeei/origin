{ config, lib, pkgs, ... }:
(import ../../../generated/home/shell.nix {
  inherit config lib pkgs;
})
