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
Implementation source now lives under `src/`; typed Nix source-of-truth is under `src/tnix/`, compiled runtime `.nix` outputs are under `generated/`, the remaining handwritten Nix entrypoint is `src/nix/home/default.nix`, and `.ush` command sources are under `src/ush/`.

## What This Repo Does

- manages macOS system settings through `nix-darwin`
- manages the user environment through Home Manager
- installs CLI tools, editors, and selected GUI apps
- exposes selected Nix-managed apps into `/Applications`
- keeps machine-specific values in `machine/local.env`, which is created on demand and intentionally gitignored

## Quick Start

1. Read [docs/onboarding.md](docs/onboarding.md).
2. Generate the local machine override file:

   ```bash
   ./_legacy/init-machine-config.sh
   ```

3. Clone `tnix` into the standard workspace path used by this repo:

   ```bash
   mkdir -p "$HOME/Source/github.com/ubugeeei"
   if [ ! -d "$HOME/Source/github.com/ubugeeei/tnix/.git" ]; then
     git clone git@github.com:ubugeeei/tnix.git "$HOME/Source/github.com/ubugeeei/tnix"
   fi
   ```

4. Review `machine/local.env`.
5. Bootstrap a fresh Mac:

   ```bash
   ./_legacy/bootstrap-macos.sh
   ```

6. Re-apply changes on an already bootstrapped machine:

   ```bash
   ./_legacy/apply.sh
   ```

7. Run a quick health check:

   ```bash
   ./_legacy/doctor.sh
   ./src/tnix/sync.sh
   ```

## Safety Boundaries

- `machine/local.env` is local-only data. Do not commit it.
- `machine/local.env` accepts only plain single-quoted `ORIGIN_*='...'` assignments. Shell expressions are rejected.
- `bootstrap` and `apply` evaluate `path:$PWD#workstation`, so local uncommitted changes affect what gets applied.
- Activation scripts replace managed app bundles under `/Applications` and `/Library/Input Methods`.
- Some cleanup helpers intentionally remove files, including app bundles that are considered unmanaged or unwanted on the target machine.

## Repository Layout

```text
.
|-- flake.nix                 # flake entrypoint and package wiring
|-- tnix.config.tnix          # tnix project configuration
|-- generated/                # gitignored compiled .nix output
|-- src/
|   |-- tnix/                 # typed source-of-truth for generated runtime files
|   |   |-- src/              # author .tnix here
|   |   |   |-- machine/
|   |   |   `-- home/
|   |   |-- types/            # repo-local ambient declarations
|   |   |-- workspace.tnix    # checked-in workspace entrypoint
|   |   `-- sync.sh           # compile .tnix -> runtime .nix
|   |-- nix/
|   |   `-- home/            # remaining handwritten Home Manager entrypoint
|   |-- templates/            # tracked helper templates such as machine.local.env.example
|   `-- ush/                  # source-only .ush implementations
|-- _legacy/                  # POSIX bootstrap entrypoints and wrappers
`-- docs/                     # onboarding and operational notes
```

Edit `.tnix` under `src/tnix/src/` and run `./src/tnix/sync.sh`; generated runtime files land under `generated/`, and `flake.nix` imports packages, machine config, and darwin modules from there while `src/nix/home/default.nix` remains the handwritten Home Manager entrypoint. Local machine overrides still live at `machine/local.env`, but that directory is created only when `./_legacy/init-machine-config.sh` is run; the tracked example now lives at [src/templates/machine.local.env.example](src/templates/machine.local.env.example).

## Further Reading

- getting started with the stack: [docs/.start.md](docs/.start.md)
- machine bootstrap walkthrough: [docs/onboarding.md](docs/onboarding.md)
- account setup: [docs/accounts.md](docs/accounts.md)
- app inventory: [docs/apps.md](docs/apps.md)
- workspace layout: [docs/workspace.md](docs/workspace.md)
- manual follow-ups: [docs/manual-steps.md](docs/manual-steps.md)
- optional app cleanup notes: [docs/debloat.md](docs/debloat.md)
