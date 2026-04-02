# Apps

Status as of March 13, 2026.

## Nix-managed desktop apps on this machine

- Raycast
- azooKey
- Ghostty
- Karabiner-Elements
- Zed
- VS Code
- Discord
- Google Chrome
- Microsoft Edge
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
- `vite-plus` is custom-packaged in this repo from the official macOS release package for the active architecture, and Home Manager prepares `~/.vite-plus` so `vp env` can own Node.js shims.
- `mise` is installed from nixpkgs and its shell integration plus `~/.local/share/mise/shims` PATH entry are managed by Home Manager.
- `moonbit` is custom-packaged in this repo from MoonBit's public macOS arm64 CLI and core downloads. Upstream currently serves those downloads via `latest` aliases, so the package is pinned by hash and needs a hash refresh when MoonBit rotates the artifact.
- `Dia` is installed on this machine and already set as the default browser, but it still needs a reliable Nix package source or public macOS download for full reproducibility in this setup.
- Gmail, Google Calendar, and Twitter are web services, so they are currently represented as Chrome app bundles rather than native vendor apps.
- `Vide` is the IDE developed by ubugeeei and the editor used most often here, but it is not open-source, so this repo does not package it. `Zed` is the next editor in regular use, while `VS Code` and `Neovim` are primarily kept for validation of editor integrations and LSP behavior.
