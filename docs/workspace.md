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
- `src/ush/` is source-only and now holds the `.ush` implementation for every repo command, while `_legacy/*.sh` keeps shell entrypoints and compatibility wrappers; bootstrap-oriented entrypoints stay POSIX `sh`, and operational helpers such as `apply`, `clone`, `doctor`, `gc`, `init-repo`, `remove-unused-apple-apps`, `set-default-browser`, and `fetch-github-profile-icon` run through `ush`
- prompt: starship
- terminal: JetBrains Mono, a `#181818` background, and a muted teal palette

The origin-packaged ush includes a small patch for alias-safe startup and full
Starship rendering. Login shells load the shared environment even when launched
with a minimal GUI PATH, so `wt` and `rtk` remain available. Starship's XDG config
is also found on macOS. The interactive smoke check covers startup and prompt
success/error colors. Open a new shell after applying a new generation.
- runtime manager: Vite+ (`vp env`)
- language runtimes and CLI tools: Nix, through origin; mise is retained only as a task runner
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
- The Nix-owned `~/.local/share/origin/toolchains/bin` precedes legacy user installations and Vite+ shims, so Bun, Go, Rust, Pkl, and other managed commands consistently use Nix. Node.js and pnpm are provided by Vite+; neither is installed as a global Nix package.
- `mise run` remains available for existing tasks, with all tool management disabled (`MISE_ENABLE_TOOLS=`). Old project `[tools]` entries cannot download or override the Nix/vp environment.
- Rust reads the nearest `rust-toolchain.toml` or legacy `rust-toolchain` file, including components and targets. `cargo +<channel>` and `RUSTUP_TOOLCHAIN` are supported. origin uses its locked rust-overlay to build the requested toolchain into the Nix store and keeps a GC root under `$XDG_STATE_HOME/origin/rust-toolchains`. The fallback is Rust 1.98.1 with WASM targets.
- Haskell uses Nix-managed GHC 9.6, Cabal, and Stack. Remove hardcoded `~/.ghcup/bin` additions from project task scripts when migrating them.
- Nix Rust toolchains are immutable: add components/targets to the project toolchain file instead of running `rustup component add` or `rustup target add`. Local compiler builds can still be selected using `[toolchain].path`.
- See [toolchain migration](toolchains.md) for first-apply and verification details.
