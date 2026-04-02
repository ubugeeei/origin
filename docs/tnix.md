# tnix

## Current stance in this repo

- Keep `tnix/workspace.tnix` and repo-specific declarations in `types/`.
- Avoid vendoring upstream workspace packs unless they are actively needed.
- Do not keep a copied `builtins.d.tnix` or `tnix.config.d.tnix` in this repo for now.

## Current upstream limitation

Today, `tnix.config.tnix` does not control declaration loading.

- `declarationDir` is used by project scaffolding and declaration emit paths.
- `builtins` only controls whether `tnix scaffold` creates a local `builtins.d.tnix`.
- During checking, tnix walks the workspace root and recursively loads every `.d.tnix` it finds.

That means there is currently no config-level way to say:

- "load bundled registry packs from tnix itself"
- "search declarations from these extra directories"
- "treat `builtins = true` as an implicit bundled declaration instead of a copied file"

## Proposed tnix.config extension

The smallest feature set that would remove duplicate declaration management here is:

```tnix
{
  name = "dotfiles";
  sourceDir = ./tnix;
  entry = ./tnix/workspace.tnix;
  declarationDir = ./types;

  declarationSearchPaths = [
    ./types
  ];

  registryPacks = [
    "workspace/tnix.config"
    "workspace/flake"
    "workspace/builtins"
    "ecosystem/nixpkgs-lib"
    "ecosystem/nixpkgs-pkgs"
    "ecosystem/flake-ecosystem"
  ];
}
```

Suggested semantics:

- `declarationDir`: local handwritten declarations only.
- `declarationSearchPaths`: additional directories to scan for `.d.tnix`.
- `registryPacks`: load bundled declarations from tnix's own `registry/` directory without copying them into each repo.
- If both a bundled pack and a local declaration target the same file, local declarations should win.
- CLI and LSP should resolve declarations with the same algorithm.

## Why this would help

- No copied `builtins.d.tnix` in every repo.
- No copied `tnix.config.d.tnix` in every repo.
- Ecosystem packs can stay maintained upstream.
- Repo-local declarations can stay focused on project-specific surfaces such as `flake.nix` and local modules.
