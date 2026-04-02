# Workspace

## Directory layout

Repositories are intended to live under:

- `$HOME/Source/github.com/<owner>/<repo>`
- `$HOME/Source/gitlab.com/<group>/<repo>`
- `$HOME/Source/github.com/<owner>/<repo>--<alias>` for additional local clones
- `$HOME/Source/gitlab.com/<group>/<repo>--<alias>` for additional local clones

This is created automatically during Home Manager activation.
If you want a different workspace root, set `ORIGIN_WORKSPACE_ROOT` in `machine/local.env`.

## Git remote policy

This setup rewrites these protocols to SSH:

- `https://github.com/...` -> `git@github.com:...`
- `https://gitlab.com/...` -> `git@gitlab.com:...`

## Suggested clone flows

With `clone`:

```bash
clone github your-user/origin
clone github your-user/origin sandbox
clone gitlab my-group/platform/api
clone git@gitlab.com:my-group/platform/api.git qa
```

With `ghq`:

```bash
ghq get git@github.com:<owner>/<repo>.git
ghq get git@gitlab.com:<group>/<repo>.git
```

Direct:

```bash
git clone git@github.com:<owner>/<repo>.git "$HOME/Source/github.com/<owner>/<repo>"
git clone git@gitlab.com:<group>/<repo>.git "$HOME/Source/gitlab.com/<group>/<repo>"
```

## Tooling defaults

- primary editor: `Vide`, the IDE developed by ubugeeei. It is the editor used day to day, but it is not open-source, so it sits outside this repository's reproducible setup.
- secondary editor: `Zed`
- verification editors: `VS Code` and `Neovim` are not daily drivers here; they are mainly kept around to verify editor integrations and LSP behavior for tools developed by ubugeeei
- frequently used languages: `Rust`, `TypeScript` with `Vue`, `tnix`, and `Haskell`
- shell: `ush` means "ubugeeei sh", the modern `sh` developed by ubugeeei; it is the default login shell here, with zsh still available
- typed Nix: `tnix` means "type nix", the Nix type system developed by ubugeeei; repo ambient declarations live under `src/tnix/types/`, runtime source-of-truth lives under `src/tnix/src/`, `./src/tnix/sync.sh` compiles gitignored outputs into `generated/`, `flake.nix` reads machine config, packages, and darwin modules from there, `src/nix/home/default.nix` is the remaining handwritten Home Manager entrypoint, the checked-in workspace entrypoint is `src/tnix/workspace.tnix`, upstream `tnix` declaration packs are read from `$HOME/Source/github.com/ubugeeei/tnix/registry`, Zed enables the `tnix` extension, and Neovim auto-attaches `tnix-lsp` when it is on PATH for verification work
- `src/ush/` is source-only and now holds the `.ush` implementation for every repo command, while `_legacy/*.sh` keeps shell entrypoints and compatibility wrappers; bootstrap-oriented entrypoints stay POSIX `sh`, and operational helpers such as `apply`, `clone`, `doctor`, `init-repo`, `remove-unused-apple-apps`, `set-default-browser`, and `fetch-github-profile-icon` run through `ush`
- prompt: starship
- runtime manager: Vite+ (`vp env`)
- secondary runtime manager: mise (installed, but not auto-activated)
- container runtime: Colima + Docker CLI

## Docker first run

Start Colima before using Docker:

```bash
colima start
docker version
```

## JavaScript Runtime Flow

- Use `vp env doctor` to confirm the shims are first in PATH.
- Use `vp env pin lts` or `vp env pin 22` inside a project to create `.node-version`.
- Use `vp env install` to download the pinned or default Node.js runtime.
- Use `vp install`, `vp dev`, `vp check`, `vp test`, and `vp build` in JS projects instead of managing `pnpm` or `node` from Nix.
- `ush` is the default shell here. For project pins, use `.node-version` or `vp env exec ...`.
- If you want session-local `vp env use <version>` behavior, open a zsh session for that workflow.
- Standard user-managed toolchain bins such as `~/.moon/bin`, `~/.cargo/bin`, `~/go/bin`, `~/.bun/bin`, and `~/Library/pnpm` are also on PATH when those directories exist.
- `mise` is available too, and `~/.local/share/mise/shims` is kept on PATH for shell and GUI sessions.
- Auto-activation is intentionally off so `vp env` remains the default Node.js flow. If you want `mise activate` behavior in a shell, opt into it manually for that shell session.
