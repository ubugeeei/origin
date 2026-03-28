# Onboarding

This document is the main walkthrough for bringing a fresh macOS machine into this repository-managed setup.

Repository script policy:

- `scripts/bootstrap-macos.sh` stays POSIX `sh` because it is the pre-Nushell entrypoint
- the other repo shell scripts are written in Nushell

## What This Repo Manages

### System layer via `nix-darwin`

- desktop apps installed through nixpkgs or custom Nix packages for macOS
- macOS defaults
- shell registration
- `/Applications` links for Nix-managed GUI apps

### User layer via Home Manager

- shell config
- Git, SSH, GitHub CLI, GitLab CLI
- Zed and Neovim config
- Docker CLI workflow with Colima
- JavaScript toolchains
- Rust and Go toolchains with LSP/formatter support
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

3. Scaffold the machine-specific override file:

   ```bash
   ./scripts/init-machine-config.sh
   ```

4. Review `machine/local.env` and adjust any values you want to pin.

5. Bootstrap the machine:

   ```bash
   ./scripts/bootstrap-macos.sh
   ```

6. If Nix is already installed, apply updates with:

   ```bash
   ./scripts/apply.sh
   ```

7. Initialize the repo state:

   ```bash
   ./scripts/init-repo.sh
   ```

8. Run a quick health check:

   ```bash
   ./scripts/doctor.sh
   ```

Notes:

- `machine/local.env` is gitignored and is the intended place for per-Mac values such as username, home directory, computer name, workspace root, and Git identity.
- `machine/local.env.example` shows the supported variables if you want to inspect the shape before generating the local file.
- If `machine/local.env` is missing, `bootstrap` and `apply` derive values from the current Mac at runtime.
- The canonical flake target stays `workstation`; local scripts invoke it through `path:$PWD#workstation` so uncommitted local files are included during evaluation. The actual macOS `hostName` and `localHostName` still come from `machine/local.env` or the detected machine defaults.
- `ORIGIN_TOUCH_ID_SUDO_AUTH` defaults to `false`. Turn it on only if you want nix-darwin to manage Touch ID for `sudo` on that Mac.
- On the first `switch`, existing dotfiles managed by Home Manager are backed up with the `.before-origin` suffix instead of being overwritten in place.

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
6. Open Karabiner-Elements once and allow the requested Accessibility / Input Monitoring permissions so the HHKB profile and launcher hotkeys can work.
7. Verify `vp` is first in PATH with `vp env doctor`, then run `vp env install` the first time you want a local Node.js runtime downloaded.
8. Use `vp env pin lts` inside JS projects that should follow the latest LTS release.
9. Rust and Go are ready after `./scripts/apply.sh`; `cargo install` targets `~/.cargo/bin` and `go install` targets `~/go/bin`, and both stay on PATH.
10. Start Colima before first Docker use.
11. On this machine Dia is already the default browser. On another machine, install Dia first, then run [set-default-browser.sh](../scripts/set-default-browser.sh) with `dia`.
12. Remove bundled Apple apps you do not want.

## Known Gaps

See [manual-steps.md](./manual-steps.md).

## Optional Cleanup

See [debloat.md](./debloat.md).
