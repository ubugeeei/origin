# tnix

`tnix` means "type nix". It is the Nix type system developed by ubugeeei, and this repo uses it as the typed source layer around generated runtime `.nix` files.

## Current stance in this repo

- Keep `tnix/workspace.tnix` and repo-specific declarations in `tnix/types/`.
- Load upstream declaration packs through `declarationPacks` instead of copying them into this repo.
- Keep only project-specific declarations checked in here.
- Author runtime files under `tnix/src/` and compile them into gitignored `generated/*.nix`.
- Keep thin tracked wrappers under `home/` and `machine/` so flake imports stay stable.

## Upstream packs now used here

`tnix` now supports `declarationPacks` in `tnix.config.tnix`.

This repo uses that to source:

- `registry/workspace/builtins.d.tnix`
- `registry/workspace/tnix.config.d.tnix`
- `registry/ecosystem/nixpkgs-lib.d.tnix`
- `registry/ecosystem/nixpkgs-pkgs.d.tnix`
- `registry/ecosystem/flake-ecosystem.d.tnix`

The paths are resolved via the standard workspace layout:

```text
$HOME/Source/github.com/ubugeeei/tnix
```

If the real checkout lives somewhere else on a machine, make that path exist with a clone or symlink.

## What stays local

- `tnix/types/dotfiles.d.tnix` stays in-repo because it describes this repo's actual `flake.nix`, machine module, and Home Manager modules.
- `builtins = false` stays set so `tnix scaffold` does not recreate a local `builtins.d.tnix`.
- We intentionally do not load the whole `registry/workspace/` directory, because `flake.d.tnix` would overlap with this repo's custom `flake.nix` declaration surface.

## Current .tnix sources

- `tnix/src/machine/default.tnix` generates `generated/machine/default.nix`
- `tnix/src/home/shell.tnix` generates `generated/home/shell.nix`
- `tnix/src/home/editor.tnix` generates `generated/home/editor.nix`
- `tnix/src/home/git.tnix` generates `generated/home/git.nix`
- `tnix/src/home/devtools.tnix` generates `generated/home/devtools.nix`
- runtime compile helpers live in `tnix/sync.sh`
- tracked wrappers under `machine/` and `home/` import those generated files for Nix module evaluation

Project builds write:

- compiled runtime `.nix` files into `generated/`
- generated declarations into `$HOME/.cache/tnix/dotfiles/types/`

Typical loop:

```bash
./tnix/sync.sh
nix run 'path:$HOME/Source/github.com/ubugeeei/tnix#tnix' -- check ./tnix/workspace.tnix
nix run 'path:$HOME/Source/github.com/ubugeeei/tnix#tnix' -- check-project .
nix run 'path:$HOME/Source/github.com/ubugeeei/tnix#tnix' -- build .
```

## Result

- No copied `builtins.d.tnix` in this repo.
- No copied `tnix.config.d.tnix` in this repo.
- No copied ecosystem alias packs in this repo.
- Upstream pack updates flow in by updating the `tnix` checkout instead of editing duplicate files here.
- Runtime Nix imports stay stable via thin tracked wrappers.
- Generated runtime `.nix` artifacts do not need to be hand-edited or tracked.
