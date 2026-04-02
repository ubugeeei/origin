{ lib, machine, ... }:
(import ../../../generated/home/git.nix {
  inherit lib machine;
})
