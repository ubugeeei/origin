# tynix

`tynix` ("tie-nix") means "typed Nix". It is the Nix type system developed by ubugeeei, and this repo uses it as the typed source layer around generated runtime `.nix` files.

## Current stance in this repo

- Keep `src/tynix/workspace.tynix` and repo-specific declarations in `src/tynix/types/`.
- Load upstream declaration packs through `declarationPacks` instead of copying them into this repo.
- Keep only project-specific declarations checked in here.
- Author runtime files under `src/tynix/src/` and compile them into gitignored `generated/*.nix`.
- Keep typed runtime source under `src/tynix/src/`, compile it into gitignored `generated/`, and leave only minimal handwritten Nix entrypoints where the module system still needs them.

## Upstream packs now used here

`tynix` now supports `declarationPacks` in `tynix.config.tynix`.

This repo uses that to source:

- `registry/workspace/builtins.d.tynix`
- `registry/workspace/tynix.config.d.tynix`
- `registry/ecosystem/nixpkgs-lib.d.tynix`
- `registry/ecosystem/nixpkgs-pkgs.d.tynix`
- `registry/ecosystem/flake-ecosystem.d.tynix`

The paths are resolved via the standard workspace layout:

```text
$HOME/Source/github.com/ubugeeei-prod/tynix
```

If the real checkout lives somewhere else on a machine, make that path exist with a clone or symlink.

## What stays local

- `src/tynix/types/dotfiles.d.tynix` stays in-repo because it describes this repo's actual `flake.nix`, machine module, and Home Manager modules.
- `builtins = false` stays set so `tynix scaffold` does not recreate a local `builtins.d.tynix`.
- We intentionally do not load the whole `registry/workspace/` directory, because `flake.d.tynix` would overlap with this repo's custom `flake.nix` declaration surface.

## Current .tynix sources

- `src/tynix/src/machine/default.tynix` generates `generated/machine/default.nix`
- `src/tynix/src/home/shell.tynix` generates `generated/home/shell.nix`
- `src/tynix/src/home/editor.tynix` generates `generated/home/editor.nix`
- `src/tynix/src/home/git.tynix` generates `generated/home/git.nix`
- `src/tynix/src/home/devtools.tynix` generates `generated/home/devtools.nix`
- runtime compile helpers live in `src/tynix/sync.sh`
- `flake.nix` reads machine config, packages, and darwin modules from `generated/`, while `src/nix/home/default.nix` stays as the handwritten Home Manager entrypoint

Project builds write:

- compiled runtime `.nix` files into `generated/`
- generated declarations into `$HOME/.cache/tynix/dotfiles/types/`

Typical loop:

```bash
./src/tynix/sync.sh
nix run 'path:$HOME/Source/github.com/ubugeeei-prod/tynix#tynix' -- check ./src/tynix/workspace.tynix
nix run 'path:$HOME/Source/github.com/ubugeeei-prod/tynix#tynix' -- check-project .
nix run 'path:$HOME/Source/github.com/ubugeeei-prod/tynix#tynix' -- build .
```

## Result

- No copied `builtins.d.tynix` in this repo.
- No copied `tynix.config.d.tynix` in this repo.
- No copied ecosystem alias packs in this repo.
- Upstream pack updates flow in by updating the `tynix` checkout instead of editing duplicate files here.
- Runtime Nix now comes mostly from `generated/`, with only `src/nix/home/default.nix` left as a handwritten entrypoint.
- Generated runtime `.nix` artifacts do not need to be hand-edited or tracked.
