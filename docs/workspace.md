# Workspace

## Directory layout

Repositories are intended to live under:

- `$HOME/Source/github.com/<owner>/<repo>`
- `$HOME/Source/gitlab.com/<group>/<repo>`
- `$HOME/Source/github.com/<owner>/<repo>--<alias>` for additional local clones
- `$HOME/Source/gitlab.com/<group>/<repo>--<alias>` for additional local clones

This is created automatically during Home Manager activation.
If you want a different workspace root, set `ORIGIN_WORKSPACE_ROOT` in `machine/local.env`.

## Git remote policy

This setup rewrites these protocols to SSH:

- `https://github.com/...` -> `git@github.com:...`
- `https://gitlab.com/...` -> `git@gitlab.com:...`

## Suggested clone flows

With `clone`:

```bash
clone your-user/origin
clone origin sandbox
clone github your-user/origin
clone github your-user/origin sandbox
clone gitlab my-group/platform/api
clone git@gitlab.com:my-group/platform/api.git qa
clone your-user/origin --dry-run
```

The host is optional. Resolution follows these rules:

1. An explicit `github`, `gitlab`, hostname, or SSH remote always wins.
2. A matching repository under `$GHQ_ROOT` identifies its host. A repository name alone, such as `clone origin sandbox`, also works when it identifies a local repository. Aliases of the same repository count as one candidate.
3. A path with nested groups, such as `my-group/platform/api`, identifies GitLab.
4. Otherwise, both hosts are checked with noninteractive, time-limited `git ls-remote` requests. A single accessible repository identifies its host.
5. Multiple matches show a numbered selection. If neither host can be confirmed, both hosts are offered, since network or authentication failures do not prove that a repository is absent. Without an interactive terminal, the command prints the candidates and asks for an explicit host instead of guessing.

`--alias <name>` / `-a <name>` remains available alongside the positional alias. Existing targets are never overwritten. The SSH-only policy is unchanged; authenticate SSH before cloning private repositories. `--dry-run` resolves the repository and prints its destination without cloning (host inference may still contact the remotes).

With `ghq`:

```bash
ghq get git@github.com:<owner>/<repo>.git
ghq get git@gitlab.com:<group>/<repo>.git
```

Direct:

```bash
git clone git@github.com:<owner>/<repo>.git "$HOME/Source/github.com/<owner>/<repo>"
git clone git@gitlab.com:<group>/<repo>.git "$HOME/Source/gitlab.com/<group>/<repo>"
```

## Task workspaces

A **task workspace** groups independent repositories under one task name. The command is `workspace`; each repository keeps its own history and remote, so the group does not become a monorepo.

```bash
workspace create payment-flow your-user/frontend gitlab.com/my-group/platform/api
workspace create compiler-fix your-user/compiler your-user/editor --branch codex/compiler-fix
workspace create payment-review your-user/frontend my-group/platform/api \
  --branch codex/payment-review --description "Review the API transition" \
  --note "Keep the existing request format working"
workspace create preview your-user/frontend my-group/platform/api --dry-run
workspace list
workspace status payment-flow
workspace show payment-flow
workspace validate payment-flow
cd "$(workspace path payment-flow)"
```

Repository arguments accept `<owner>/<repo>`, `<host>/<owner>/<repo>`, SSH remotes, and known local repository names. For `workspace create`, include an explicit host in the same argument (`github.com/owner/repo`), since every positional argument after the task name is a separate repository.

By default, workspaces live under `$GHQ_ROOT/.workspaces` (or `$HOME/Source/.workspaces` when `GHQ_ROOT` is unset). Set `WORKSPACE_ROOT` to change this location.

```text
$GHQ_ROOT/.workspaces/payment-flow/
├── workspace.pkl
├── .workspace/Workspace.pkl
├── workspace.code-workspace
├── github.com/your-user/frontend/
│   └── .git/
└── gitlab.com/my-group/platform/api/
    └── .git/
```

- Each repository is freshly cloned from its remote's default branch. Existing local changes and local-only commits are not copied. `--branch <name>` creates a new branch in every clone.
- Every clone has its own working directory, index, refs, and Git object store. Cloning uses `--no-local`, including when Git URL rewrites point to local repositories; it does not use shared worktrees, object alternates, or local hardlinks. See the [Git clone documentation](https://git-scm.com/docs/git-clone).
- Host and namespace directories keep repositories with the same basename separate. `workspace.code-workspace` provides a multi-root workspace for VS Code; other editors can open the task directory or its repositories.
- `workspace.pkl` is the metadata source of truth. `workspace status <name>` shows each repository's configured branch alongside its live Git branch and changes.
- Task names and aliases are single directory names. Unicode and spaces are supported (quote names containing spaces); `/`, control characters, and the names `.` and `..` are rejected.
- A task name must be unused. Duplicate repositories are rejected before cloning. If creation fails or is interrupted, only the task directory created by that invocation is removed; existing clones and tasks are preserved.

This isolates source directories and Git state. Shell environment, global Git configuration, credentials, and user-level package caches still come from the current machine. Dependencies are installed separately inside each repository as needed.

### Pkl metadata

The schema lives in [`src/workspace/Workspace.pkl`](../src/workspace/Workspace.pkl). Creation copies it into `.workspace/Workspace.pkl`, so a task remains self-contained when moved to another directory. The generated `workspace.pkl` [amends that Pkl schema](https://pkl-lang.org/main/current/language-reference/index.html#amending-a-module).

```pkl
amends ".workspace/Workspace.pkl"

task {
  name = "payment-flow"
  description = "Update the frontend and API together"
  branch = "codex/payment-flow"
}

repositories {
  new {
    host = "github.com"
    slug = "your-user/frontend"
    baseBranch = "main"
    // branch inherits task.branch; override it here when needed.
    note = "Verify the client against the new API contract"
  }
  new {
    host = "gitlab.com"
    slug = "my-group/platform/api"
    baseBranch = "develop"
    branch = "codex/payment-api"
  }
}

appendix {
  notes {
    new {
      title = "Compatibility"
      body = """
        Keep the existing request format working.
        Verify both repositories before merging either change.
        """
    }
  }
  links {
    ["design"] = "https://example.com/payment-flow"
  }
}
```

Pkl validates task names, Git branch syntax, host names, repository paths, starting commit hashes, and the types of notes. `path` and `remote` are derived from `host` and `slug` and cannot be overridden. `baseBranch` and `initialHead` record where each clone started; `branch` records its intended task branch. Empty remotes have a null `initialHead`.

Edit descriptions, branches, per-repository notes, and appendix notes directly in `workspace.pkl`. Reading or validating metadata preserves comments and notes and does not change Git branches. If you switch branches manually, `workspace status` lets you compare the configured and live branches. Metadata is descriptive after creation; editing it does not clone repositories or apply branch changes.

`workspace validate <name>` evaluates Pkl and checks the local repository paths. `workspace show <name>` displays the authored Pkl; `workspace show <name> --json` exports evaluated metadata on demand. No JSON metadata manifest is kept in parallel. Evaluation permits workspace-local modules and the Pkl standard library. External resource reads and network schema imports are disabled; write appendix notes as Pkl strings or local Pkl modules.

A complete [example](../src/workspace/examples/payment-flow.pkl) can also be evaluated with `pkl eval src/workspace/examples/payment-flow.pkl`.

### Implementation and validation

`src/workspace/repos.sh` is the shared Bash implementation for both commands. Pkl defines workspace metadata and jq renders the authored configuration. Home Manager installs the commands with Nix-managed Bash, coreutils, jq, Git, SSH, and Pkl. Before applying Home Manager, enter the matching tool environment and run commands directly from this checkout:

```bash
nix shell --inputs-from "path:$PWD" nixpkgs#bash nixpkgs#coreutils nixpkgs#jq nixpkgs#pkl nixpkgs#expect
./_legacy/clone.sh your-user/origin --dry-run
./_legacy/workspace.sh create payment-flow your-user/frontend gitlab.com/my-group/platform/api
bash tests/repositories.sh
```

The tests use temporary local Git remotes and require no network or account credentials once the runtimes are installed. They cover host inference, interactive selection, compatibility entrypoints, duplicate/existing paths, rollback, Git-state isolation, Pkl constraints, branch inheritance, and note round-tripping. CI also builds and tests the actual Nix-managed command wrappers.

## Tooling defaults

- primary editor: `Vide`, the IDE developed by ubugeeei. It is the editor used day to day, but it is not open-source, so it sits outside this repository's reproducible setup.
- secondary editor: `Zed`
- verification editors: `VS Code` and `Neovim` are not daily drivers here; they are mainly kept around to verify editor integrations and LSP behavior for tools developed by ubugeeei
- frequently used languages: `Rust`, `TypeScript` with `Vue`, `tnix`, and `Haskell`
- shell: `ush` means "ubugeeei sh", the modern `sh` developed by ubugeeei; it is the default login shell here, with zsh still available
- typed Nix: `tnix` means "type nix", the Nix type system developed by ubugeeei; repo ambient declarations live under `src/tnix/types/`, runtime source-of-truth lives under `src/tnix/src/`, `./src/tnix/sync.sh` compiles gitignored outputs into `generated/`, `flake.nix` reads machine config, packages, and darwin modules from there, `src/nix/home/default.nix` is the remaining handwritten Home Manager entrypoint, the checked-in workspace entrypoint is `src/tnix/workspace.tnix`, upstream `tnix` declaration packs are read from `$HOME/Source/github.com/ubugeeei/tnix/registry`, Zed enables the `tnix` extension, and Neovim auto-attaches `tnix-lsp` when it is on PATH for verification work
- `src/ush/` holds the `.ush` operational helpers, while `_legacy/*.sh` keeps shell entrypoints and compatibility wrappers; bootstrap-oriented entrypoints stay POSIX `sh`. Repository management (`clone` and `workspace`) shares `src/workspace/repos.sh`; the existing `clone.ush` entrypoint forwards to that implementation.
- prompt: starship
- runtime manager: Vite+ (`vp env`)
- secondary runtime manager: mise (installed, but not auto-activated)
- container runtime: Colima + Docker CLI

## Docker first run

Start Colima before using Docker:

```bash
colima start
docker version
```

## JavaScript Runtime Flow

- Use `vp env doctor` to confirm the shims are first in PATH.
- Use `vp env pin lts` or `vp env pin 22` inside a project to create `.node-version`.
- Use `vp env install` to download the pinned or default Node.js runtime.
- Use `vp install`, `vp dev`, `vp check`, `vp test`, and `vp build` in JS projects instead of managing `pnpm` or `node` from Nix.
- `ush` is the default shell here. For project pins, use `.node-version` or `vp env exec ...`.
- If you want session-local `vp env use <version>` behavior, open a zsh session for that workflow.
- Standard user-managed toolchain bins such as `~/.moon/bin`, `~/.cargo/bin`, `~/go/bin`, `~/.bun/bin`, and `~/Library/pnpm` are also on PATH when those directories exist.
- `mise` is available too, and `~/.local/share/mise/shims` is kept on PATH for shell and GUI sessions.
- Auto-activation is intentionally off so `vp env` remains the default Node.js flow. If you want `mise activate` behavior in a shell, opt into it manually for that shell session.
