# Apps

Status as of August 31, 2026.

## Nix-managed desktop apps on this machine

- Raycast
- azooKey
- Ghostty
- Karabiner-Elements
- Zed
- VS Code
- Cursor
- Claude
- ChatGPT (the OpenAI Codex desktop app)
- Kimi
- Discord
- Firefox
- Google Chrome
- Microsoft Edge
- Wavebox
- Gmail
- Google Calendar
- Twitter
- Obsidian
- Slack
- Spotify
- Zoom

These are exposed directly into `/Applications` after `darwin-rebuild switch`.

## Nix-managed CLI apps

- Codex CLI
- rtk
- worktrunk (`wt`)
- AWS CLI
- Google Workspace CLI (`gam`)
- GitHub CLI
- GitLab CLI
- Docker CLI
- Colima
- Bun
- MoonBit
- mise
- just
- ush
- tmux
- Vite+ (`vp`)
- starship
- Neovim
- Node.js shims via `vp env`
- modern Unix utilities like `bat`, `eza`, `fd`, `ripgrep`, `delta`, `dust`, `duf`, `bottom`, `procs`, `sd`, `xh`

## Requested but not yet Nix-managed here

- Dia app installation source
- Gmail and Google Calendar as dedicated native vendor apps
- Vide IDE

## Why these are not all in the flake yet

- `ghostty` is installed from `ghostty-bin`.
- `microsoft-edge` is custom-packaged in this repo from Microsoft's macOS pkg.
- `azooKey` is now custom-packaged in this repo, but input-source enablement still needs macOS settings plus logout/login.
- `vite-plus` is custom-packaged in this repo from the official platform-specific CLI package for the active OS and architecture, and Home Manager prepares `~/.vite-plus` so `vp env` can own Node.js shims.
- `mise` is installed from nixpkgs and its shell integration plus `~/.local/share/mise/shims` PATH entry are managed by Home Manager.
- `moonbit` is custom-packaged in this repo from MoonBit's public macOS arm64 CLI and core downloads. Upstream currently serves those downloads via `latest` aliases, so the package is pinned by hash and needs a hash refresh when MoonBit rotates the artifact.
- `Cursor` comes from the nixpkgs `code-cursor` package, so its version tracks whatever nixpkgs is pinned to in `flake.lock`.
- `Claude` is custom-packaged in this repo from Anthropic's public universal macOS build. The file name is content-addressed, so both the version and the build id are pinned in `src/tnix/src/pkgs/claude-desktop.tnix`. Resolve the current pair with `curl -sI https://api.anthropic.com/api/desktop/darwin/universal/dmg/latest/redirect` or `https://downloads.claude.ai/releases/darwin/universal/RELEASES.json`.
- `ChatGPT` comes from the nixpkgs `chatgpt` package. The standalone `Codex.app` was discontinued in July 2026 and folded into the ChatGPT desktop app, so the OpenAI coding agent GUI now ships as `ChatGPT.app` from the `codex-app-prod` channel. The `codex` CLI stays a separate nixpkgs package under Home Manager.
- `Kimi` is custom-packaged in this repo from Moonshot's public macOS arm64 disk image. The image ships a wrapper installer, so the package pulls the real bundle out of `Kimi Installer.app/Contents/Helpers/`.
- `Wavebox` is custom-packaged in this repo from Wavebox's public macOS Apple Silicon disk image. nixpkgs removed its own `wavebox` package in June 2025 for lack of maintenance, and that package was an `x86_64-linux` deb anyway, so the attribute here is named `wavebox-mac`. The download page only links to a `latest` alias, so the versioned file that alias resolves to is pinned instead; refresh it with `curl -sIL https://download.wavebox.app/latest/stable/macarm64`.
- `rtk` comes from the nixpkgs `rtk` package. It is a CLI proxy that compresses command output before it reaches a coding agent, so it lives in `home.packages` next to `codex`.
- `worktrunk` comes from the nixpkgs `worktrunk` package, built from [max-sixty/worktrunk](https://github.com/max-sixty/worktrunk). It manages Git worktrees for parallel agent runs and installs as `wt`. Its shell completions cover bash, fish, nushell, and zsh, so `ush` gets none of them here.
- `Dia` is installed on this machine and already set as the default browser, but it still needs a reliable Nix package source or public macOS download for full reproducibility in this setup.
- Gmail, Google Calendar, and Twitter are web services, so they are currently represented as Chrome app bundles rather than native vendor apps.
- `Vide` is the IDE developed by ubugeeei and the editor used most often here, but it is not open-source, so this repo does not package it. `Zed` is the next editor in regular use, while `VS Code` and `Neovim` are primarily kept for validation of editor integrations and LSP behavior.
