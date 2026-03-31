# ubugeeei/origin

> [!WARNING]
> This repository performs privileged and destructive operations.
> Running it can install software from remote sources, execute `sudo darwin-rebuild switch --impure`, change macOS defaults, change the login shell, rewrite `/Applications` and `/Library/Input Methods`, and remove files with `rm -rf`.
> Review the code before running anything on a machine you care about.

> [!CAUTION]
> Use this repository entirely at your own risk.
> I take no responsibility for data loss, broken machines, account issues, or any other damage caused by using it.

Personal macOS workstation configuration built with Nix, `nix-darwin`, and Home Manager.
It is intentionally opinionated and optimized for one machine owner, not for safe one-click onboarding by strangers.

## What This Repo Does

- manages macOS system settings through `nix-darwin`
- manages the user environment through Home Manager
- installs CLI tools, editors, and selected GUI apps
- exposes selected Nix-managed apps into `/Applications`
- keeps machine-specific values in `machine/local.env`, which is intentionally gitignored

## Quick Start

1. Read [docs/onboarding.md](docs/onboarding.md).
2. Generate the local machine override file:

   ```bash
   ./_legacy/init-machine-config.sh
   ```

3. Review `machine/local.env`.
4. Bootstrap a fresh Mac:

   ```bash
   ./_legacy/bootstrap-macos.sh
   ```

5. Re-apply changes on an already bootstrapped machine:

   ```bash
   ./_legacy/apply.sh
   ```

6. Run a quick health check:

   ```bash
   ./_legacy/doctor.sh
   ```

## Safety Boundaries

- `machine/local.env` is local-only data. Do not commit it.
- `machine/local.env` accepts only plain single-quoted `ORIGIN_*='...'` assignments. Shell expressions are rejected.
- `bootstrap` and `apply` evaluate `path:$PWD#workstation`, so local uncommitted changes affect what gets applied.
- Activation scripts replace managed app bundles under `/Applications` and `/Library/Input Methods`.
- Some cleanup helpers intentionally remove files, including app bundles that are considered unmanaged or unwanted on the target machine.

## Repository Layout

- [flake.nix](flake.nix): flake entrypoint and package wiring
- [machine/default.nix](machine/default.nix): machine model derived from `ORIGIN_*` environment variables
- [modules/darwin/core.nix](modules/darwin/core.nix): macOS system settings and activation hooks
- [modules/darwin/desktop-apps.nix](modules/darwin/desktop-apps.nix): `/Applications` and input-method exposure
- [home/default.nix](home/default.nix): Home Manager entrypoint for the user environment
- [_legacy/](./_legacy): runnable shell entrypoints and compatibility wrappers
- [scripts/](./scripts): source-only `.ush` implementations for repo commands
- [docs/](docs): onboarding, accounts, apps, workspace, and manual follow-up notes

## Further Reading

- getting started with the stack: [docs/.start.md](docs/.start.md)
- machine bootstrap walkthrough: [docs/onboarding.md](docs/onboarding.md)
- account setup: [docs/accounts.md](docs/accounts.md)
- app inventory: [docs/apps.md](docs/apps.md)
- workspace layout: [docs/workspace.md](docs/workspace.md)
- manual follow-ups: [docs/manual-steps.md](docs/manual-steps.md)
- optional app cleanup notes: [docs/debloat.md](docs/debloat.md)
