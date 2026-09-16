# Legacy Scripts

Preserved shell entrypoints and compatibility wrappers live here.

The `src/ush/` directory holds source-only `.ush` operational helpers. The corresponding `_legacy/*.sh` wrapper remains the easiest runnable entrypoint during the migration, especially for bootstrap-safe commands that must work before `ush` is available on PATH. `clone.sh` and `workspace.sh` run the shared Bash implementation in `src/workspace/repos.sh`, also used by the Nix-managed commands. Pkl defines workspace metadata, and jq handles its rendering. `clone-real.sh` preserves the old environment-based interface.
