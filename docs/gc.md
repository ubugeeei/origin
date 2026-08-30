# GC

`gc` is the garbage collection command for this workstation. It reclaims disk space from
the four places that grow without bound here: the Nix store, the global Cargo caches, the
gitignored build artifacts under the workspace root, and stale entries in `/tmp`.

## Run it

```bash
gc --dry-run
```

```bash
gc
```

Without a Home Manager activation on PATH yet, the repository entrypoint works the same way:

```bash
./_legacy/gc.sh --dry-run
```

Always start with `--dry-run`. It performs the full scan, measures every candidate, and
prints the same report, but deletes nothing.

## What it collects

### nix

- `nh clean all` when `nh` is installed
- `nix-collect-garbage --delete-old` for the user profiles
- `sudo nix-collect-garbage --delete-old` for the system profiles, so macOS asks for your
  administrator password
- `nix store gc`
- `nix store optimise` only when `--optimise` is passed, because it is slow

Deleting old generations means the previous `darwin-rebuild` generations are gone and can
no longer be rolled back to.

Reclaimed space is reported as the drop in used blocks on the `/nix` volume, so unrelated
writes during the run can move that number slightly.

### cargo global cache

Removes the regenerable download and checkout caches under `$CARGO_HOME`
(`~/.cargo` by default):

- `registry/cache`, `registry/src`, `registry/index`
- `git/checkouts`, `git/db`

`~/.cargo/bin` and everything else in `$CARGO_HOME` is left alone, so installed binaries
survive. The next build re-downloads what it needs.

### workspace artifacts

Every git repository under the workspace root is asked for its own ignored entries with
`git status --porcelain --ignored`, so `.gitignore` stays the single source of truth for
what is disposable. Of those entries, only directories with these names are collected:

`node_modules`, `target`, `dist`, `build`, `coverage`, `.next`, `.nuxt`, `.output`,
`.turbo`, `.parcel-cache`, `.vite`, `.svelte-kit`

The name allowlist is what keeps ignored-but-precious files safe: `machine/local.env`,
`.env`, `.direnv`, and editor state are ignored by git but are never build output, so they
are never touched. A `dist` or `build` directory that is committed to a repository is not
ignored, so it is never touched either.

Results are reported per project, largest first.

### tmp

Removes entries directly under `/tmp` that are owned by you, are regular files or
directories, and have not been modified for more than `GC_TMP_AGE_DAYS` days (3 by
default). Sockets and FIFOs are skipped because live processes hold them and they occupy
no space anyway.

## Options

Flags are read from the command line; each one also has an environment variable, which is
what to use when calling `gc` from another script.

| flag | environment variable | effect |
| --- | --- | --- |
| `--dry-run`, `-n` | `GC_DRY_RUN` | scan and report, delete nothing |
| `--verbose`, `-v` | `GC_VERBOSE` | list every entry instead of the largest 20 |
| `--optimise` | `GC_NIX_OPTIMISE` | also run `nix store optimise` |
| `--skip-nix` | `GC_SKIP_NIX` | skip the nix section |
| `--skip-cargo` | `GC_SKIP_CARGO` | skip the cargo section |
| `--skip-workspace` | `GC_SKIP_WORKSPACE` | skip the workspace section |
| `--skip-tmp` | `GC_SKIP_TMP` | skip the `/tmp` section |
| | `GC_WORKSPACE_ROOT` | workspace root to scan, defaults to `ORIGIN_WORKSPACE_ROOT` |
| | `GC_TMP_AGE_DAYS` | age threshold for `/tmp`, defaults to `3` |
| | `GC_TOP` | rows per section, defaults to `20` |

Only the first six arguments are forwarded through `_legacy/run-ush.sh`, so use the
environment variables when you need more than six options at once.

## Cost

A full run scans every repository under the workspace root and measures every candidate
directory before deleting it, so expect several minutes on a large workspace. The scan is
the same in `--dry-run` mode, which is why the dry run is a faithful preview.
