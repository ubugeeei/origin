# Legacy Scripts

Preserved shell entrypoints and compatibility wrappers live here.

The `src/ush/` directory is source-only and now contains the `.ush` implementation for every repo command. The corresponding `_legacy/*.sh` wrapper remains the easiest runnable entrypoint during the migration, especially for bootstrap-safe commands that must work before `ush` is available on PATH.
