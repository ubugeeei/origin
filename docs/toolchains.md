# Nix and Vite+ toolchains

origin owns Bun, Deno, Go, Rust, Java, Haskell, uv, jj, just, dprint,
git-cliff, wasm-pack, Pkl, delstack, and markgate through Nix. The pinned Vite+
global CLI owns Node.js and pnpm. The Nix toolchain bin directory wins over
old mise shims, Cargo-installed copies, global npm packages, and older Nix
profiles. Project `nix develop` PATH additions remain ahead of that prefix.

## Apply and verify

Run `./_legacy/apply.sh` as usual. Home Manager backs up the old global mise
configuration before replacing it. Open a new terminal or source
`~/.config/workstation/shell/terminal-env.sh` to update an existing shell.

```sh
command -v bun deno go cargo jj just uv pkl vp node pnpm
vp env current
mise ls --current --json # {}: mise is only a task runner
```

Keep `mise run` tasks while removing `[tools]` entries as repositories are
updated. The Nix-packaged mise wrapper disables all tool resolution and
automatic installation even when an old project still declares tools.
Do not add `~/.local/share/mise/shims` back to PATH.

Move Node version requirements from mise to `.node-version` or package.json
runtime metadata and keep pnpm requirements in package.json `packageManager`.
Vite+ resolves those requirements per project. Bun remains Nix-managed.

Old installations can be retained for rollback: none are needed on PATH.
This migration does not delete `~/.cargo`, `~/.rustup`, global npm packages,
project lockfiles, or previous Nix generations.

## Rust

The default is Rust 1.98.1. The launcher reads the nearest `rust-toolchain.toml`
or legacy `rust-toolchain`, preserving profiles, components, and targets. An
explicit `cargo +<channel>` or `RUSTUP_TOOLCHAIN` takes precedence. Custom
locally built compilers can still use `[toolchain].path`.

The selected upstream toolchain is built with the rust-overlay and nixpkgs
revisions pinned in origin's flake.lock. The first invocation may download
components; subsequent invocations reuse the Nix store output. GC roots are
kept in `$XDG_STATE_HOME/origin/rust-toolchains` (default
`~/.local/state/origin/rust-toolchains`). Update origin's rust-overlay input
when a newly released channel is absent from its manifest.

Use project components/targets instead of `rustup component add` or
`rustup target add`: Nix toolchains are immutable. Existing Cargo-installed
utilities remain on PATH after managed tools. No rustup toolchain directories
are rewritten or removed.

## Haskell

GHC 9.6, Cabal, and Stack come from Nix. Project tasks must not prepend an old
`~/.ghcup/bin`; remove that line when migrating a repository. Stack projects
should select the system GHC when compatible rather than downloading another
compiler. A project that requires another GHC version can use a Nix devShell.

## Validation

GitHub Actions checks the tnix workspace and flake, tests Rust selector
precedence and target preservation, builds all managed tools, and runs CLI
smoke checks. Machine-specific verification also checks Node/pnpm through
Vite+, Rust in Vize and UF, and command resolution after Home Manager applies.
