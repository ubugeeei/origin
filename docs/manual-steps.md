# Manual Steps

## Required Admin Steps

1. Install Xcode Command Line Tools.
2. Run the Nix installer and approve the administrator prompt.
3. Re-run the bootstrap script after Nix is installed.

## App Gaps

The current flake intentionally leaves a few macOS-specific items outside the activation path until we have a reliable package source:

- `Dia` installation source
- `Vide` installation, because it is not open-source and is not packaged by this repo

## Editor Notes

`Vide` is the IDE developed by ubugeeei and is the editor used day to day, but it is not open-source, so it stays outside this repository-managed setup.

`Zed` is the next editor in regular use.

`VS Code` and `Neovim` are installed mainly for verification work around editor integrations and LSP behavior for tools developed by ubugeeei rather than as daily editors.

## Dia Browser

As of March 13, 2026, the official Dia site appears to expose waitlist / invite flows rather than a public macOS download artifact. That means this repository cannot yet package Dia reproducibly from an official public installer.

This machine already has `Dia.app` installed and `dia` is already set as the default browser. What remains manual is making that installation reproducible from this repository.

Once Dia publishes a stable macOS download URL, add a custom package similar to `src/tnix/src/pkgs/azookey-mac.tnix` or `src/tnix/src/pkgs/microsoft-edge-mac.tnix`, then keep using [set-default-browser.sh](../_legacy/set-default-browser.sh) to enforce the browser default.
That wrapper delegates to `ush` through `_legacy/run-ush.sh` and can fall back to `nix run "path:$PWD#ush"`, so it does not have to wait for the login shell switch.
If the repo has fresh `.tnix` changes, run `./src/tnix/sync.sh` before the wrapper so the generated runtime `.nix` files are up to date.

## Vite+ Runtime Notes

`vp env` is now the Node.js runtime manager for this setup.

- `vp env setup` and `vp env on` are applied automatically during Home Manager activation.
- `vp env install` still downloads the actual Node.js runtime lazily the first time you need it.
- `ush` means "ubugeeei sh", the modern `sh` developed by ubugeeei. It is the default login shell in this setup and uses the shared `vp` shims fine for project pins.
- Session-local `vp env use <version>` eval is still the better fit for zsh, so use `vp env exec ...` from `ush` when you need a one-off override.

## azooKey Enablement

`azooKey` itself is packaged by this repository now, but macOS still needs the normal user-side enablement flow after installation:

1. Log out and log back in.
2. Open `Settings` > `Keyboard` > `Input Sources`.
3. Add `azooKey` under Japanese input sources.
4. Select it from the menu bar input menu.

## Karabiner-Elements Permissions

`Karabiner-Elements` is now installed by Nix and configured for:

- `Command+Space` -> Raycast
- `Shift+Space` -> toggle Ghostty on the left half of the active screen
- `Control+Option+Left` -> Raycast `Left Half`
- `Control+Option+Right` -> Raycast `Right Half`
- `Control+Option+Up` -> Raycast `Maximize Width`
- `Control+Option+Down` -> Raycast `Restore`
- disable the built-in Mac keyboard while the Bluetooth `HHKB-Hybrid_1` is connected

This keeps native macOS `Option+Arrow` and `Option+Shift+Arrow` text navigation and selection free for editors and text fields.

After the app is installed, open `Karabiner-Elements` once and approve the requested macOS permissions such as Accessibility and Input Monitoring. Without those approvals, the launcher hotkeys and built-in keyboard disablement will not take effect.

For the window shortcuts, open Raycast once, make sure the built-in Window Management extension is enabled, and allow the command deeplinks the first time Raycast asks.

## Suggested Next Follow-Up

If you add more Nova variants later, drop the files into `assets/fonts` and they will be packaged automatically. The remaining follow-up we might still want is:

- regular and bold font variants
- fallback font settings for Neovim and terminal apps
