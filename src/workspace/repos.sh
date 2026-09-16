#!/usr/bin/env bash
set -Eeuo pipefail

script_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
tool_name=${1:-repos}
scratch=""
rollback_target=""

fail() { printf '%s: %s\n' "$tool_name" "$1" >&2; exit "${2:-64}"; }
require() { command -v "$1" >/dev/null 2>&1 || fail "required command is not installed: $1"; }
cleanup() {
  local code=$?
  trap - EXIT
  if [[ -n $rollback_target ]]; then rm -rf -- "$rollback_target"; fi
  if [[ -n $scratch ]]; then rm -rf -- "$scratch"; fi
  exit "$code"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Commands launched from hooks must not inherit their index or object store.
unset GIT_DIR GIT_COMMON_DIR GIT_WORK_TREE GIT_INDEX_FILE
unset GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE

validate_name() {
  [[ -n ${1//[[:space:]]/} && $1 != . && $1 != .. && $1 != */* && ! $1 =~ [[:cntrl:]] ]] ||
    fail "$2 must be a nonempty directory name without '/', control characters, '.' or '..'"
}

normalize_host() {
  case $1 in
    github|github.com) printf 'github.com\n' ;;
    gitlab|gitlab.com) printf 'gitlab.com\n' ;;
    *) return 1 ;;
  esac
}

parse_spec() {
  local spec=$1 prefix part
  PARSED_HOST=""
  case $spec in
    git@github.com:*|git@gitlab.com:*)
      PARSED_HOST=${spec#git@}; PARSED_HOST=${PARSED_HOST%%:*}; spec=${spec#*:} ;;
    *:*) fail 'only GitHub and GitLab SSH remotes are supported' ;;
    github/*|github.com/*|gitlab/*|gitlab.com/*)
      prefix=${spec%%/*}; PARSED_HOST=$(normalize_host "$prefix"); spec=${spec#*/} ;;
  esac
  PARSED_SLUG=${spec%.git}
  [[ $PARSED_SLUG =~ ^[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)*$ ]] || fail 'invalid repository path'
  local -a parts
  IFS=/ read -r -a parts <<< "$PARSED_SLUG"
  for part in "${parts[@]}"; do
    [[ $part != . && $part != .. ]] || fail 'repository paths must not contain . or .. segments'
  done
  if [[ -n $PARSED_HOST ]]; then
    [[ $PARSED_SLUG == */* ]] || fail 'repository path must look like <owner>/<repo>'
    [[ $PARSED_HOST != github.com || ${#parts[@]} == 2 ]] || fail 'GitHub paths must be <owner>/<repo>; nested groups belong on GitLab'
  fi
}

absolute_path() {
  local value=$1
  case $value in \~) value=$HOME ;; \~/*) value="$HOME/${value#\~/}" ;; esac
  realpath -ms -- "$value"
}

collect_repositories() {
  local directory=$1 host=$2 relative=$3 child name slug origin prefix
  if [[ -d $directory/.git || -f $directory/.git ]]; then
    slug=$relative
    if [[ ${relative##*/} == *--* ]]; then
      origin=$(git -C "$directory" config --get remote.origin.url || true)
      for prefix in "git@$host:" "https://$host/" "ssh://git@$host/"; do
        if [[ $origin == "$prefix"* ]]; then slug=${origin#"$prefix"}; break; fi
      done
    fi
    if (parse_spec "$host/$slug") 2>/dev/null; then printf '%s/%s\n' "$host" "${slug%.git}"; fi
    return
  fi
  for child in "$directory"/* "$directory"/.[!.]* "$directory"/..?*; do
    [[ -d $child && ! -L $child ]] || continue
    name=${child##*/}
    collect_repositories "$child" "$host" "${relative:+$relative/}$name"
  done
}

local_catalog() {
  local host
  if [[ ! -f $scratch/catalog ]]; then
    for host in github.com gitlab.com; do
      if [[ -d $repo_root/$host ]]; then collect_repositories "$repo_root/$host" "$host" ''; fi
    done | sort -u > "$scratch/catalog"
  fi
}

choose_repository() {
  local reason=$1 answer candidate index=1
  shift
  local -a candidates=("$@")
  printf '%s\n' "$reason" >&2
  for candidate in "${candidates[@]}"; do printf '  %s) %s\n' "$index" "$candidate" >&2; index=$((index + 1)); done
  [[ -t 0 ]] || fail 'specify a listed host/repository explicitly when running without a terminal'
  while true; do
    printf 'Select a repository [1-%s], or q to cancel: ' "${#candidates[@]}" >&2
    IFS= read -r answer || fail 'selection cancelled'
    [[ -n $answer && $answer != q && $answer != Q ]] || fail 'selection cancelled'
    for ((index=1; index<=${#candidates[@]}; index++)); do
      if [[ $answer == "$index" ]]; then printf '%s\n' "${candidates[index-1]}"; return; fi
    done
    printf 'Enter one of the listed numbers.\n' >&2
  done
}

probe_remote() {
  local identity=$1 ssh_command=${GIT_SSH_COMMAND:-}
  if [[ -z $ssh_command ]]; then ssh_command=$(git config --get core.sshCommand || true); fi
  if [[ -z $ssh_command ]]; then printf -v ssh_command '%q' "${GIT_SSH:-ssh}"; fi
  GIT_TERMINAL_PROMPT=0 \
    GIT_SSH_COMMAND="$ssh_command -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=1 -o StrictHostKeyChecking=yes" \
    timeout 10 git ls-remote -- "git@${identity%%/*}:${identity#*/}.git" >/dev/null 2>&1
}

resolve_repository() {
  local spec=$1 candidate slug github_pid gitlab_pid reason
  local -a matches=() available=()
  parse_spec "$spec"
  if [[ -n $PARSED_HOST ]]; then printf '%s/%s\n' "$PARSED_HOST" "$PARSED_SLUG"; return; fi
  slug=$PARSED_SLUG
  local_catalog
  while IFS= read -r candidate; do
    if [[ ${candidate#*/} == "$slug" || ( $slug != */* && ${candidate##*/} == "$slug" ) ]]; then matches+=("$candidate"); fi
  done < "$scratch/catalog"
  if [[ ${#matches[@]} == 1 ]]; then printf '%s\n' "${matches[0]}"; return; fi
  if [[ ${#matches[@]} -gt 1 ]]; then choose_repository "Multiple local repositories match '$slug':" "${matches[@]}"; return; fi
  [[ $slug == */* ]] || fail "no local repository named '$slug'; use <owner>/<repo> or an explicit host/repository"
  if [[ ${slug#*/} == */* ]]; then printf 'gitlab.com/%s\n' "$slug"; return; fi
  printf 'Checking GitHub and GitLab for %s...\n' "$slug" >&2
  probe_remote "github.com/$slug" & github_pid=$!
  probe_remote "gitlab.com/$slug" & gitlab_pid=$!
  if wait "$github_pid"; then available+=("github.com/$slug"); fi
  if wait "$gitlab_pid"; then available+=("gitlab.com/$slug"); fi
  if [[ ${#available[@]} == 1 ]]; then printf '%s\n' "${available[0]}"; return; fi
  reason="Both hosts contain '$slug':"
  if [[ ${#available[@]} == 0 ]]; then
    available=("github.com/$slug" "gitlab.com/$slug")
    reason="Could not confirm a host for '$slug' (authentication or network may be unavailable):"
  fi
  choose_repository "$reason" "${available[@]}"
}

clone_repository() {
  local identity=$1 destination=$2 remote="git@${1%%/*}:${1#*/}.git"
  [[ ! -e $destination && ! -L $destination ]] || fail "target already exists: $destination"
  mkdir -p -- "${destination%/*}"
  printf 'cloning %s\n  -> %s\n' "$remote" "$destination" >&2
  git clone --no-local -- "$remote" "$destination" >&2
}

clone_help() {
  cat <<'EOF'
usage: clone [github|gitlab] <owner>/<repo> [alias]
       clone <host>/<owner>/<repo> [alias]
       clone git@<host>:<owner>/<repo>.git [alias]
       clone <known-local-repo-name> [alias]

options:
  -a, --alias <name>  clone into <repo>--<name>
  --dry-run          resolve and show the destination without cloning
  -h, --help         show this help
EOF
}

clone_command() {
  local alias_name='' alias_set=false dry_run=false identity destination
  local -a args=()
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help) clone_help; return ;;
      -a|--alias)
        [[ $# -ge 2 ]] || fail "missing value for $1"
        [[ $alias_set == false ]] || fail 'alias specified twice'
        alias_name=$2; alias_set=true; shift 2 ;;
      --dry-run) dry_run=true; shift ;;
      --) shift; args+=("$@"); break ;;
      -*) fail "unknown option: $1" ;;
      *) args+=("$1"); shift ;;
    esac
  done
  [[ ${#args[@]} -gt 0 ]] || fail 'repository is required'
  if normalize_host "${args[0]}" >/dev/null; then
    [[ ${#args[@]} -ge 2 ]] || fail 'repository path is required after the host'
    args=("${args[0]}/${args[1]}" "${args[@]:2}")
  fi
  [[ ${#args[@]} -le 2 ]] || fail 'unexpected arguments'
  if [[ ${#args[@]} == 2 ]]; then
    [[ $alias_set == false ]] || fail 'alias specified twice'
    alias_name=${args[1]}; alias_set=true
  fi
  if [[ $alias_set == true ]]; then validate_name "$alias_name" alias; fi
  identity=$(resolve_repository "${args[0]}")
  destination="$repo_root/$identity${alias_name:+--$alias_name}"
  if [[ $dry_run == true ]]; then printf 'git@%s:%s.git\n%s\n' "${identity%%/*}" "${identity#*/}" "$destination"
  else clone_repository "$identity" "$destination"; fi
}

task_path() { validate_name "$1" 'task name'; printf '%s/%s\n' "$tasks_root" "$1"; }
require_pkl() { require "${WORKSPACE_PKL:-pkl}"; }

evaluate_workspace() {
  local target=$1 patterns
  require_pkl
  patterns=$(jq -nr -L "$script_dir" --arg lexical "$target" --arg physical "$(realpath -e -- "$target")" \
    'include "metadata"; [$lexical, $physical] | unique | map(module_pattern) | join(",")')
  timeout 15 "${WORKSPACE_PKL:-pkl}" eval --format json --color never --settings pkl:settings --no-project \
    --allowed-modules "pkl:,$patterns" --allowed-resources prop: --timeout 10 "$target/workspace.pkl"
}

load_workspace() {
  local name=$1 target physical identity checkout branch
  target=$(task_path "$name")
  evaluate_workspace "$target" > "$scratch/manifest.json"
  jq -e --arg name "$name" '.schemaVersion == 1 and .task.name == $name and (.repositories | type == "array" and length > 0)' \
    "$scratch/manifest.json" >/dev/null || fail "not a valid task workspace: $target"
  physical=$(realpath -e -- "$target")
  while IFS= read -r identity; do
    parse_spec "$identity"
    [[ -n $PARSED_HOST && $identity == "$PARSED_HOST/$PARSED_SLUG" ]] || fail 'invalid repository path in metadata'
    checkout="$target/$identity"
    [[ $(realpath -m -- "$checkout") == "$physical/"* ]] || fail 'repository path escapes the workspace'
    [[ -d $checkout/.git && ! -L $checkout/.git ]] || fail 'repository is missing its independent .git directory'
  done < <(jq -r '.repositories[].path' "$scratch/manifest.json")
  while IFS= read -r branch; do git check-ref-format --branch "$branch" >/dev/null; done \
    < <(jq -r '.repositories[] | .baseBranch, .branch | select(. != null)' "$scratch/manifest.json")
}

workspace_help() {
  cat <<'EOF'
usage: workspace create <task> <repository>... [options]
       workspace list
       workspace {path|status|show|validate} <task>

create options:
  --branch <name>       create this branch in every clone
  --description <text>  task description in workspace.pkl
  --note <text>         appendix note (repeatable)
  --dry-run             resolve destinations without cloning
show options:
  --json                export evaluated metadata as JSON

Repositories accept owner/repo, host/owner/repo, SSH remotes, or local names.
EOF
}

create_workspace() {
  local name='' name_set=false branch='' branch_set=false description='' dry_run=false target identity previous base_branch head note
  local -a repositories=() notes=() identities=()
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help) workspace_help; return ;;
      --branch|--description|--note)
        [[ $# -ge 2 ]] || fail "missing value for $1"
        case $1 in
          --branch) branch=$2; branch_set=true ;;
          --description) description=$2 ;;
          --note) notes+=("$2") ;;
        esac; shift 2 ;;
      --dry-run) dry_run=true; shift ;;
      --) shift; if [[ $name_set == false && $# -gt 0 ]]; then name=$1; name_set=true; shift; fi; repositories+=("$@"); break ;;
      -*) fail "unknown option: $1" ;;
      *) if [[ $name_set == false ]]; then name=$1; name_set=true; else repositories+=("$1"); fi; shift ;;
    esac
  done
  target=$(task_path "$name")
  [[ ${#repositories[@]} -gt 0 ]] || fail 'at least one repository is required'
  [[ ! -e $target && ! -L $target ]] || fail "target already exists: $target"
  if [[ $branch_set == true ]]; then git check-ref-format --branch "$branch" >/dev/null; fi
  require_pkl
  for identity in "${repositories[@]}"; do
    identity=$(resolve_repository "$identity")
    for previous in "${identities[@]}"; do
      [[ $identity != "$previous" ]] || fail 'the same repository was specified more than once'
      [[ $identity != "$previous/"* && $previous != "$identity/"* ]] || fail 'repository paths must not be nested inside another repository'
    done
    identities+=("$identity")
  done
  if [[ $dry_run == true ]]; then
    for identity in "${identities[@]}"; do printf 'git@%s:%s.git\n%s\n' "${identity%%/*}" "${identity#*/}" "$target/$identity"; done
    return
  fi
  mkdir -p -- "$tasks_root"
  mkdir -- "$target"
  rollback_target=$target
  : > "$scratch/repositories.jsonl"
  for identity in "${identities[@]}"; do
    clone_repository "$identity" "$target/$identity"
    base_branch=$(git -C "$target/$identity" branch --show-current)
    if [[ $branch_set == true ]]; then git -C "$target/$identity" switch -c "$branch" >&2; fi
    head=$(git -C "$target/$identity" rev-parse --verify HEAD 2>/dev/null || true)
    jq -nc --arg host "${identity%%/*}" --arg slug "${identity#*/}" --arg base "$base_branch" \
      --arg branch "${branch:-$base_branch}" --arg head "$head" \
      '{host:$host, slug:$slug, baseBranch:($base|select(length>0)) // null,
        branch:($branch|select(length>0)) // null, initialHead:($head|select(length>0)) // null}' >> "$scratch/repositories.jsonl"
  done
  : > "$scratch/notes.jsonl"
  for note in "${notes[@]}"; do jq -nc --arg body "$note" '{body:$body}' >> "$scratch/notes.jsonl"; done
  jq -n --arg name "$name" --arg description "$description" --arg branch "$branch" \
    --slurpfile repositories "$scratch/repositories.jsonl" --slurpfile notes "$scratch/notes.jsonl" \
    '{task:{name:$name,description:$description,branch:($branch|select(length>0)) // null},
      repositories:$repositories,appendix:{notes:$notes}}' > "$scratch/creation.json"
  mkdir -- "$target/.workspace"
  cp -- "$script_dir/Workspace.pkl" "$target/.workspace/Workspace.pkl"
  jq -r -L "$script_dir" 'include "metadata"; render_manifest' "$scratch/creation.json" > "$target/workspace.pkl"
  load_workspace "$name"
  jq '{folders:[.repositories[] | {name:.path,path:.path}]}' "$scratch/manifest.json" > "$target/workspace.code-workspace"
  rollback_target=''
  printf '%s\n' "$target"
}

workspace_command() {
  local action=${1:---help} name target identity branch render_json=false
  [[ $# == 0 ]] || shift
  case $action in
    -h|--help) workspace_help ;;
    create) create_workspace "$@" ;;
    list)
      [[ $# == 0 ]] || fail 'list takes no arguments'
      for target in "$tasks_root"/* "$tasks_root"/.[!.]* "$tasks_root"/..?*; do
        if [[ -f $target/workspace.pkl ]]; then printf '%s\t%s\n' "${target##*/}" "$target"; fi
      done ;;
    path|status|show|validate)
      [[ $# -gt 0 ]] || fail 'task name is required'
      name=$1; shift
      if [[ $action == show && ${1:-} == --json ]]; then render_json=true; shift; fi
      [[ $# == 0 ]] || fail 'unexpected arguments'
      target=$(task_path "$name")
      load_workspace "$name"
      case $action in
        path) printf '%s\n' "$target" ;;
        validate) printf 'Valid task workspace: %s/workspace.pkl\n' "$target" ;;
        show) if [[ $render_json == true ]]; then jq . "$scratch/manifest.json"; else cat -- "$target/workspace.pkl"; fi ;;
        status)
          while IFS= read -r identity; do
            branch=$(jq -r --arg identity "$identity" '.repositories[] | select(.path==$identity) | .branch // "(default)"' "$scratch/manifest.json")
            printf '[%s] configured branch: %s\n' "$identity" "$branch"
            git -C "$target/$identity" status --short --branch
          done < <(jq -r '.repositories[].path' "$scratch/manifest.json") ;;
      esac ;;
    *) fail "unknown workspace command: $action" ;;
  esac
}

[[ $# -gt 0 ]] || fail 'usage: repos.sh {clone|workspace} ...'
shift
for dependency in git jq realpath timeout; do require "$dependency"; done
scratch=$(mktemp -d)
repo_root=$(absolute_path "${GHQ_ROOT:-$HOME/Source}")
tasks_root=$(absolute_path "${WORKSPACE_ROOT:-$repo_root/.workspaces}")
case $tool_name in
  clone) clone_command "$@" ;;
  workspace) workspace_command "$@" ;;
  *) fail 'usage: repos.sh {clone|workspace} ...' ;;
esac
