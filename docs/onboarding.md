# Onboarding

This document is the main walkthrough for bringing a fresh macOS machine into this repository-managed setup.

Repository script policy:

- `src/ush/` is source-only and now contains only `.ush` sources
- preserved shell entrypoints and compatibility wrappers live in `_legacy/*.sh`
- every `_legacy` command now has a matching `.ush` implementation under `src/ush/`
- `_legacy/bootstrap-macos.sh`, `_legacy/init-machine-config.sh`, and `_legacy/print-machine-env.sh` stay POSIX `sh` as the bootstrap-safe entrypoints, even though matching `.ush` sources now exist
- wrappers such as `apply`, `clone`, `doctor`, `init-repo`, `remove-unused-apple-apps`, `set-default-browser`, and `fetch-github-profile-icon` delegate into `src/ush/*.ush`
- the `_legacy/run-ush.sh` wrapper can fall back to `nix run .#ush` before the login shell switch has been applied
- `./src/tnix/sync.sh` compiles typed `.tnix` sources into the runtime `.nix` files that `flake.nix` imports from `src/nix/`

## Repo-Specific Tools

- `ush` means "ubugeeei sh". It is the modern `sh` developed by ubugeeei, and this repo uses it for the main script implementations under `src/ush/*.ush` plus the default login shell.
- `tnix` means "type nix". It is the Nix type system developed by ubugeeei, and this repo uses it for typed Nix sources under `src/tnix/`, repo-local ambient declarations under `src/tnix/types/`, and compiled runtime `.nix` outputs under `generated/`.
- `Vide` is the IDE developed by ubugeeei. It is the editor used day to day, but it is not open-source, so this repo does not try to package or reproduce it.
- The languages used most often in this setup are `Rust`, `TypeScript` with `Vue`, `tnix`, and `Haskell`.

## What This Repo Manages

### System layer via `nix-darwin`

- desktop apps installed through nixpkgs or custom Nix packages for macOS
- macOS defaults
- shell registration
- `/Applications` links for Nix-managed GUI apps

### User layer via Home Manager

- shell config
- Git, SSH, GitHub CLI, GitLab CLI
- Zed and Neovim config, plus VS Code availability for editor and LSP verification
- Docker CLI workflow with Colima
- JavaScript / TypeScript toolchains with `Vue` workflow support
- Rust, `tnix`, Haskell, and Go toolchains with LSP / formatter support where available
- Codex CLI
- AWS CLI
- Google Workspace CLI (`gam`)
- modern Unix CLI replacements

## Machine Bootstrap

1. Install Apple Command Line Tools:

   ```bash
   xcode-select --install
   ```

2. Move into the repository root:

   ```bash
   cd /path/to/origin
   ```

3. Scaffold the machine-specific override file in `machine/local.env`:

   ```bash
   ./_legacy/init-machine-config.sh
   ```

4. Clone `tnix` into the standard workspace path used by this repo:

   ```bash
   mkdir -p "$HOME/Source/github.com/ubugeeei"
   if [ ! -d "$HOME/Source/github.com/ubugeeei/tnix/.git" ]; then
     git clone git@github.com:ubugeeei/tnix.git "$HOME/Source/github.com/ubugeeei/tnix"
   fi
   ```

5. Review `machine/local.env` and adjust any values you want to pin.

6. Bootstrap the machine:

   ```bash
   ./_legacy/bootstrap-macos.sh
   ```

7. If Nix is already installed, apply updates with:

   ```bash
   ./_legacy/apply.sh
   ```

8. Initialize the repo state:

   ```bash
   ./_legacy/init-repo.sh
   ```

9. Run quick health checks:

   ```bash
   ./_legacy/doctor.sh
   ./src/tnix/sync.sh
   nix run "path:$HOME/Source/github.com/ubugeeei/tnix#tnix" -- check ./src/tnix/workspace.tnix
   ```

Notes:

- `machine/local.env` is gitignored and is the intended place for per-Mac values such as username, home directory, computer name, workspace root, and Git identity.
- [src/templates/machine.local.env.example](../src/templates/machine.local.env.example) shows the supported variables if you want to inspect the shape before generating the local file.
- The `machine/` directory is not tracked anymore; `_legacy/init-machine-config.sh` creates it only when you actually generate `machine/local.env`.
- If `machine/local.env` is missing, `_legacy/bootstrap-macos.sh` and `_legacy/apply.sh` derive values from the current Mac at runtime.
- The canonical flake target stays `workstation`; local scripts invoke it through `path:$PWD#workstation` so uncommitted local files are included during evaluation. The actual macOS `hostName` and `localHostName` still come from `machine/local.env` or the detected machine defaults.
- `ORIGIN_TOUCH_ID_SUDO_AUTH` defaults to `false`. Turn it on only if you want nix-darwin to manage Touch ID for `sudo` on that Mac.
- On the first `switch`, existing dotfiles managed by Home Manager are backed up with the `.before-origin` suffix instead of being overwritten in place.
- This repo expects `ubugeeei/tnix` at `$HOME/Source/github.com/ubugeeei/tnix` so `tnix.config.tnix` can read upstream declaration packs and `./src/tnix/sync.sh` can compile runtime `.nix` files without copying registry packs into this repository.
- `Vide` remains a manual install and personal workflow choice. `Zed` is the next editor in regular use, while `VS Code` and `Neovim` are mainly there to validate LSP integrations for ubugeeei tooling.

## Current App Status

See [apps.md](./apps.md).

## Accounts And Identity

See [accounts.md](./accounts.md).

## Workspace Layout

See [workspace.md](./workspace.md).

## What To Tweak First

1. Check the Git identity values in `machine/local.env`.
2. Finish SSH key setup and GitHub/GitLab auth.
3. Sign in to Raycast, Discord, Slack, Zoom, Spotify, Obsidian, and Chrome.
4. Sign in to Gmail, Google Calendar, and Twitter from their app launchers in `/Applications`.
5. Log out and log back in once so azooKey is fully recognized by macOS.
6. Open Karabiner-Elements once and allow the requested Accessibility / Input Monitoring permissions so the Bluetooth HHKB profile and launcher hotkeys can work.
7. Verify `vp` is first in PATH with `vp env doctor`, then run `vp env install` the first time you want a local Node.js runtime downloaded.
8. Use `vp env pin lts` inside JS projects that should follow the latest LTS release.
9. Rust and Go are ready after `./_legacy/apply.sh`; `cargo install` targets `~/.cargo/bin` and `go install` targets `~/go/bin`, and both stay on PATH.
10. Start Colima before first Docker use.
11. On this machine Dia is already the default browser. On another machine, install Dia first, then run [set-default-browser.sh](../_legacy/set-default-browser.sh) with `dia`.
12. Remove bundled Apple apps you do not want.

## Known Gaps

See [manual-steps.md](./manual-steps.md).

## Optional Cleanup

See [debloat.md](./debloat.md).
