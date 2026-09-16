#!/usr/bin/env bash
# Offline integration tests. Run with Bash, coreutils, jq, Pkl, Git and Expect.
set -Eeuo pipefail

repo_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
clone_command=${REPOSITORY_COMMAND_DIR:+$REPOSITORY_COMMAND_DIR/clone}
clone_command=${clone_command:-$repo_dir/_legacy/clone.sh}
workspace_command=${REPOSITORY_COMMAND_DIR:+$REPOSITORY_COMMAND_DIR/workspace}
workspace_command=${workspace_command:-$repo_dir/_legacy/workspace.sh}

fail() { printf '%s\n' "$*" >&2; exit 1; }
assert_eq() { [[ $1 == "$2" ]] || fail "expected [$2], got [$1]"; }
assert_file() { [[ -f $1 ]] || fail "missing file: $1"; }
assert_dir() { [[ -d $1 ]] || fail "missing directory: $1"; }
assert_absent() { [[ ! -e $1 && ! -L $1 ]] || fail "unexpected path: $1"; }
assert_contains() { [[ $(cat -- "$1") == *"$2"* ]] || fail "missing [$2] in $(cat -- "$1")"; }
run() {
  if "$@" > "$case_root/stdout" 2> "$case_root/stderr"; then command_exit=0; else command_exit=$?; fi
}
ok() { run "$@"; [[ $command_exit == 0 ]] || { cat "$case_root/stderr" >&2; fail "command failed ($command_exit): $*"; }; }
bad() { run "$@"; [[ $command_exit != 0 ]] || fail "command unexpectedly succeeded: $*"; }

setup() {
  case_root=$(mktemp -d "${TMPDIR:-/tmp}/repo tools ' 日本語.XXXXXXXX")
  trap 'rm -rf -- "$case_root"' EXIT
  export GHQ_ROOT="$case_root/Source" WORKSPACE_ROOT="$case_root/Tasks"
  export GIT_CONFIG_GLOBAL="$case_root/gitconfig" GIT_CONFIG_NOSYSTEM=1
  export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid
  export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.invalid
  export GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND=false
  unset GIT_DIR GIT_COMMON_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES
  : > "$GIT_CONFIG_GLOBAL"
  for host in github.com gitlab.com; do
    mkdir -p "$case_root/remotes/$host"
    git config --file "$GIT_CONFIG_GLOBAL" "url.$case_root/remotes/$host/.insteadOf" "git@$host:"
  done
}

remote() {
  local host=${1:-github.com} slug=${2:-team/repo} empty=${3:-false} seed
  local destination="$case_root/remotes/$host/$slug.git"
  mkdir -p "${destination%/*}"
  git init -q --bare --initial-branch=main "$destination"
  if [[ $empty == false ]]; then
    seed=$(mktemp -d "$case_root/seed.XXXXXX")
    git init -q --initial-branch=main "$seed"
    printf '%s/%s\n' "$host" "$slug" > "$seed/README.md"
    git -C "$seed" add .
    git -C "$seed" commit -qm initial
    git -C "$seed" push -q "$destination" main
  fi
}

create_demo() { remote; ok "$workspace_command" create demo github/team/repo --branch codex/demo --note 'Keep this note'; }
metadata() { ok "$workspace_command" show demo --json; cat "$case_root/stdout"; }
rewrite_metadata() {
  jq "$1" "$case_root/original.json" | jq -r -L "$repo_dir/src/workspace" 'include "metadata"; render_manifest' > "$WORKSPACE_ROOT/demo/workspace.pkl"
}

test_01_explicit_github() {
  remote; ok "$clone_command" github team/repo
  assert_dir "$GHQ_ROOT/github.com/team/repo/.git"
}
test_02_explicit_gitlab_and_subgroups() {
  remote gitlab.com group/sub/repo; ok "$clone_command" gitlab group/sub/repo
  assert_dir "$GHQ_ROOT/gitlab.com/group/sub/repo/.git"
}
test_03_clone_alias_formats() {
  remote
  ok "$clone_command" github team/repo positional
  ok "$clone_command" github.com/team/repo second
  ok "$clone_command" git@github.com:team/repo.git -a third
  for alias_name in positional second third; do assert_dir "$GHQ_ROOT/github.com/team/repo--$alias_name/.git"; done
}
test_04_environment_compatibility() {
  remote
  ok env CLONE_FIRST=github CLONE_SECOND=team/repo CLONE_ALIAS=compat "$repo_dir/_legacy/clone-real.sh"
  assert_dir "$GHQ_ROOT/github.com/team/repo--compat/.git"
}
test_05_hostless_remote_resolution() {
  remote gitlab.com; ok "$clone_command" team/repo
  assert_dir "$GHQ_ROOT/gitlab.com/team/repo/.git"
}
test_06_empty_remote_is_a_match() {
  remote github.com team/repo true; ok "$clone_command" team/repo
  assert_dir "$GHQ_ROOT/github.com/team/repo/.git"
}
test_07_local_match_and_short_name() {
  remote; ok "$clone_command" github/team/repo
  ok "$clone_command" team/repo copy
  ok "$clone_command" repo another
  assert_dir "$GHQ_ROOT/github.com/team/repo--another/.git"
}
test_08_nested_groups_infer_gitlab() {
  remote gitlab.com group/sub/repo; ok "$clone_command" group/sub/repo
  assert_dir "$GHQ_ROOT/gitlab.com/group/sub/repo/.git"
}
test_09_unknown_short_name() {
  bad "$clone_command" unknown --dry-run
  assert_contains "$case_root/stderr" '<owner>/<repo>'
}
test_10_ambiguous_remotes_noninteractive() {
  remote; remote gitlab.com
  bad "$clone_command" team/repo </dev/null
  assert_contains "$case_root/stderr" github.com/team/repo
  assert_contains "$case_root/stderr" gitlab.com/team/repo
  assert_contains "$case_root/stderr" 'without a terminal'
  assert_absent "$GHQ_ROOT"
}
test_11_unknown_remote_offers_hosts() {
  bad "$clone_command" team/missing </dev/null
  assert_contains "$case_root/stderr" github.com/team/missing
  assert_contains "$case_root/stderr" gitlab.com/team/missing
  assert_absent "$GHQ_ROOT"
}
test_12_interactive_selection() {
  remote; remote gitlab.com
  export TEST_CLONE="$clone_command"
  ok expect <<'EOF'
set timeout 15
spawn -noecho $env(TEST_CLONE) team/repo
expect "Select a repository"
send "invalid\r"
expect "Enter one of the listed numbers."
expect "Select a repository"
send "2\r"
expect eof
set result [wait]
exit [lindex $result 3]
EOF
  assert_dir "$GHQ_ROOT/gitlab.com/team/repo/.git"
  assert_absent "$GHQ_ROOT/github.com/team/repo"
}
test_13_interactive_cancel() {
  remote; remote gitlab.com
  export TEST_CLONE="$clone_command"
  ok expect <<'EOF'
set timeout 15
spawn -noecho $env(TEST_CLONE) team/repo
expect "Select a repository"
send "q\r"
expect "selection cancelled"
expect eof
set result [wait]
if {[lindex $result 3] == 0} { exit 1 }
EOF
  assert_absent "$GHQ_ROOT"
}
test_14_aliases_deduplicate_real_double_dash_names() {
  remote github.com team/repo--name
  ok "$clone_command" github/team/repo--name
  ok "$clone_command" github/team/repo--name copy
  ok "$clone_command" repo--name --dry-run
  assert_contains "$case_root/stdout" git@github.com:team/repo--name.git
}
test_15_dot_repos_unicode_names() {
  remote github.com team/.github
  ok "$clone_command" github/team/.github '検証用 clone'
  ok "$clone_command" .github --dry-run
  ok "$workspace_command" create '横断, 作業' github/team/.github
  ok "$workspace_command" path '横断, 作業'
  assert_eq "$(cat "$case_root/stdout")" "$WORKSPACE_ROOT/横断, 作業"
}
test_16_symlink_host_and_pruned_dependencies() {
  mkdir -p "$case_root/old/github.com/team/repo/.git" "$case_root/old/github.com/team/repo/node_modules/dep/.git" "$GHQ_ROOT"
  ln -s "$case_root/old/github.com" "$GHQ_ROOT/github.com"
  ok "$clone_command" repo --dry-run
  bad "$clone_command" dep --dry-run
}
test_17_invalid_specs() {
  local spec
  # shellcheck disable=SC2016 # Exercise literal shell syntax in untrusted input.
  for spec in https://github.com/team/repo git@evil.com:team/repo github/team/../repo team//repo /team/repo team/repo/ team/. team/.. 'team/$(touch x)' github/team github/team/sub/repo; do
    bad "$clone_command" "$spec" --dry-run
  done
  assert_absent "$GHQ_ROOT"
}
test_18_invalid_aliases() {
  bad "$clone_command" github/team/repo -a a --alias b
  bad "$clone_command" github/team/repo positional --alias another
  bad "$clone_command" github/team/repo --alias ''
  bad "$clone_command" github/team/repo --alias ../outside
  assert_absent "$GHQ_ROOT"
}
test_19_existing_targets_and_symlinks() {
  mkdir -p "$GHQ_ROOT/github.com/team/repo"
  printf 'keep' > "$GHQ_ROOT/github.com/team/repo/keep"
  ln -s "$case_root/absent" "$GHQ_ROOT/github.com/team/repo--link"
  bad "$clone_command" github/team/repo
  bad "$clone_command" github/team/repo link
  assert_eq "$(cat "$GHQ_ROOT/github.com/team/repo/keep")" keep
  [[ -L $GHQ_ROOT/github.com/team/repo--link ]]
}
test_20_dry_run_has_no_filesystem_effects() {
  ok "$clone_command" github/team/repo --dry-run
  ok "$workspace_command" create demo github/team/repo --dry-run
  assert_absent "$GHQ_ROOT"; assert_absent "$WORKSPACE_ROOT"
}
test_21_workspace_isolation() {
  local task="$WORKSPACE_ROOT/demo" original="$GHQ_ROOT/github.com/team/repo" identity
  remote; remote gitlab.com group/sub/repo
  ok "$clone_command" github/team/repo
  printf 'dirty original' > "$original/README.md"
  ok "$workspace_command" create demo team/repo group/sub/repo --branch codex/demo
  for identity in github.com/team/repo gitlab.com/group/sub/repo; do
    assert_dir "$task/$identity/.git"
    assert_eq "$(git -C "$task/$identity" rev-parse --git-common-dir)" .git
    assert_eq "$(git -C "$task/$identity" branch --show-current)" codex/demo
    assert_absent "$task/$identity/.git/objects/info/alternates"
    [[ -z $(find "$task/$identity/.git/objects" -type f -links +1 -print) ]] || fail 'shared Git object hardlinks'
  done
  assert_absent "$task/.git"
  assert_eq "$(cat "$task/github.com/team/repo/README.md")" github.com/team/repo
  printf 'task changes' > "$task/github.com/team/repo/README.md"
  git -C "$task/github.com/team/repo" commit -qam 'task work'
  assert_eq "$(cat "$original/README.md")" 'dirty original'
  assert_eq "$(git -C "$original" branch --show-current)" main
  [[ $(git -C "$original" rev-parse HEAD) != "$(git -C "$task/github.com/team/repo" rev-parse HEAD)" ]]
}
test_22_workspace_manifest_and_editor() {
  create_demo
  metadata > "$case_root/data.json"
  jq -e '.task.name=="demo" and .task.branch=="codex/demo" and .repositories[0].baseBranch=="main" and (.repositories[0].initialHead|length==40)' "$case_root/data.json"
  assert_file "$WORKSPACE_ROOT/demo/.workspace/Workspace.pkl"
  jq -e '.folders[0].path=="github.com/team/repo"' "$WORKSPACE_ROOT/demo/workspace.code-workspace"
  assert_absent "$WORKSPACE_ROOT/demo/workspace.json"
}
test_23_workspace_list_path_status() {
  create_demo
  printf 'new' > "$WORKSPACE_ROOT/demo/github.com/team/repo/untracked"
  ok "$workspace_command" path demo
  assert_eq "$(cat "$case_root/stdout")" "$WORKSPACE_ROOT/demo"
  ok "$workspace_command" list
  assert_contains "$case_root/stdout" "$WORKSPACE_ROOT/demo"
  ok "$workspace_command" status demo
  assert_contains "$case_root/stdout" '?? untracked'
  assert_contains "$case_root/stdout" '[github.com/team/repo]'
}
test_24_default_workspace_root() {
  remote; ok env -u WORKSPACE_ROOT "$workspace_command" create demo github/team/repo
  assert_file "$GHQ_ROOT/.workspaces/demo/workspace.pkl"
  bad "$clone_command" repo --dry-run
}
test_25_failed_create_rolls_back_only_new_task() {
  remote; mkdir -p "$WORKSPACE_ROOT/existing"; printf 'keep' > "$WORKSPACE_ROOT/existing/keep"
  bad "$workspace_command" create broken github/team/repo gitlab/team/absent
  assert_absent "$WORKSPACE_ROOT/broken"
  bad "$workspace_command" create existing github/team/repo
  assert_eq "$(cat "$WORKSPACE_ROOT/existing/keep")" keep
}
test_26_duplicate_nested_repos_and_bad_task_names() {
  bad "$workspace_command" create demo github/team/repo git@github.com:team/repo.git
  bad "$workspace_command" create demo gitlab/group/repo gitlab/group/repo/child
  local name
  for name in ../escape . .. a/b $'a\nb' ''; do bad "$workspace_command" create "$name" github/team/repo; done
  bad "$workspace_command" create '' unintended github/team/repo --dry-run
  assert_absent "$WORKSPACE_ROOT"
}
test_27_invalid_or_existing_branch() {
  remote
  local branch
  for branch in '' bad..branch main; do
    bad "$workspace_command" create demo github/team/repo --branch "$branch"
    assert_absent "$WORKSPACE_ROOT/demo"
  done
}
test_28_empty_repository_workspace() {
  remote github.com team/repo true
  ok "$workspace_command" create demo github/team/repo
  metadata > "$case_root/data.json"
  jq -e '.repositories[0].initialHead==null' "$case_root/data.json"
  ok "$workspace_command" status demo
}
test_29_hook_environment_isolation() {
  remote
  ok env GIT_DIR="$case_root/poison" GIT_WORK_TREE="$case_root" GIT_INDEX_FILE="$case_root/poison/index" \
    GIT_OBJECT_DIRECTORY="$case_root/poison/objects" "$workspace_command" create demo github/team/repo
  assert_absent "$case_root/poison"
  assert_dir "$WORKSPACE_ROOT/demo/github.com/team/repo/.git"
}
test_30_appendix_notes_and_descriptions() {
  remote
  local note=$'日本語\n"quotes"\t\\(read("file:/private"))\b\f🙂'
  ok "$workspace_command" create demo github/team/repo --description 'Task description' --note "$note" --note 'Another note'
  metadata > "$case_root/data.json"
  jq -e --arg note "$note" '.task.description=="Task description" and .appendix.notes[0].body==$note and .appendix.notes[1].body=="Another note"' "$case_root/data.json"
  ok "$workspace_command" show demo
  assert_contains "$case_root/stdout" 'amends ".workspace/Workspace.pkl"'
}
test_31_metadata_is_descriptive_and_preserves_comments() {
  create_demo; metadata > "$case_root/original.json"
  rewrite_metadata '.task.branch="codex/planned" | .repositories[0].branch="codex/planned"'
  printf '\n// Keep my comment\n' >> "$WORKSPACE_ROOT/demo/workspace.pkl"
  cp "$WORKSPACE_ROOT/demo/workspace.pkl" "$case_root/authored.pkl"
  ok "$workspace_command" status demo
  assert_contains "$case_root/stdout" 'configured branch: codex/planned'
  assert_contains "$case_root/stdout" '## codex/demo'
  ok "$workspace_command" validate demo
  cmp "$case_root/authored.pkl" "$WORKSPACE_ROOT/demo/workspace.pkl"
}
test_32_schema_rejects_invalid_fields() {
  create_demo; metadata > "$case_root/original.json"
  local filter
  for filter in '.task.name="../escape"' '.repositories[0].host="evil.com"' '.repositories[0].slug="team/../repo"' '.repositories[0].slug="team/sub/repo"' '.repositories[0].initialHead="not-a-hash"'; do
    rewrite_metadata "$filter"
    bad "$workspace_command" validate demo
  done
  rewrite_metadata '.'
  sed 's/name = "demo"/name = 42/' "$WORKSPACE_ROOT/demo/workspace.pkl" > "$case_root/invalid.pkl"
  cp "$case_root/invalid.pkl" "$WORKSPACE_ROOT/demo/workspace.pkl"
  bad "$workspace_command" validate demo
}
test_33_schema_rejects_invalid_branches() {
  create_demo; metadata > "$case_root/original.json"
  local branch
  for branch in 'bad branch' bad..branch bad.lock topic/.hidden -option 'topic@{1}' topic//name topic/ topic. 'topic[1]' topic:bad 'topic?bad' 'topic*bad'; do
    jq --arg branch "$branch" '.task.branch=$branch | .repositories[0].branch=$branch' "$case_root/original.json" |
      jq -r -L "$repo_dir/src/workspace" 'include "metadata"; render_manifest' > "$WORKSPACE_ROOT/demo/workspace.pkl"
    bad "$workspace_command" validate demo
  done
}
test_34_per_repository_branch_and_multiline_notes() {
  create_demo
  cat > "$WORKSPACE_ROOT/demo/workspace.pkl" <<'EOF'
amends ".workspace/Workspace.pkl"
task { name = "demo"; branch = "codex/shared" }
repositories {
  new {
    host = "github.com"
    slug = "team/repo"
    branch = "codex/individual"
    note = "Repository note"
  }
}
appendix {
  notes {
    new {
      title = "Decision"
      body = """
        First line
        Second line
        """
    }
  }
  links { ["issue"] = "https://example.com/issue" }
}
EOF
  metadata > "$case_root/data.json"
  jq -e '.repositories[0].branch=="codex/individual" and .appendix.notes[0].body=="First line\nSecond line" and .appendix.links.issue=="https://example.com/issue"' "$case_root/data.json"
}
test_35_missing_repositories_and_traversal() {
  create_demo; metadata > "$case_root/original.json"
  rewrite_metadata '.repositories[0].slug="team/missing"'
  bad "$workspace_command" status demo
  rewrite_metadata '.repositories[0].slug="../outside"'
  bad "$workspace_command" status demo
}
test_36_symlink_git_directories_are_rejected() {
  create_demo
  mv "$WORKSPACE_ROOT/demo/github.com/team/repo/.git" "$case_root/external-git"
  ln -s "$case_root/external-git" "$WORKSPACE_ROOT/demo/github.com/team/repo/.git"
  bad "$workspace_command" validate demo
}
test_37_external_resources_are_rejected() {
  create_demo
  local resource
  printf 'private' > "$case_root/private.md"
  ln -s "$case_root/private.md" "$WORKSPACE_ROOT/demo/linked.md"
  cp "$WORKSPACE_ROOT/demo/workspace.pkl" "$case_root/original.pkl"
  for resource in linked.md env:HOME https://example.com/note; do
    cat "$case_root/original.pkl" > "$WORKSPACE_ROOT/demo/workspace.pkl"
    printf '\nlocal external = read("%s")\noutput { text = external.toString() }\n' "$resource" >> "$WORKSPACE_ROOT/demo/workspace.pkl"
    bad "$workspace_command" show demo
  done
}
test_38_external_module_symlinks_are_rejected() {
  create_demo
  printf 'body = "outside"\n' > "$case_root/external.pkl"
  ln -s "$case_root/external.pkl" "$WORKSPACE_ROOT/demo/linked.pkl"
  printf '\nlocal external = import("linked.pkl")\noutput { text = external.body }\n' >> "$WORKSPACE_ROOT/demo/workspace.pkl"
  bad "$workspace_command" show demo
}
test_39_interrupt_rolls_back() {
  remote
  # shellcheck disable=SC2329 # Exported for the command's child Bash process.
  git() {
    if [[ $1 == clone ]]; then kill -TERM "$BASHPID"; else command git "$@"; fi
  }
  export -f git
  bad "$workspace_command" create demo github/team/repo
  unset -f git
  assert_absent "$WORKSPACE_ROOT/demo"
}
test_40_help_and_invalid_options() {
  ok "$clone_command" --help
  ok "$workspace_command" --help
  ok "$workspace_command" create --help
  bad "$clone_command" --unknown
  bad "$workspace_command" create task github/team/repo --unknown
  bad "$workspace_command" list extra
}
test_41_existing_workspace_compatibility() {
  create_demo
  # The shipped schema and manifest shape remain compatible across implementations.
  cmp "$repo_dir/src/workspace/Workspace.pkl" "$WORKSPACE_ROOT/demo/.workspace/Workspace.pkl"
  ok "$workspace_command" validate demo
  assert_contains "$case_root/stdout" 'Valid task workspace'
}

if [[ ${1:-} == --case ]]; then
  setup
  "$2"
  exit
fi

log_dir=$(mktemp -d)
trap 'rm -rf -- "$log_dir"' EXIT
mapfile -t cases < <(compgen -A function test_)
printf '1..%s\n' "${#cases[@]}"
failed=0
index=0
for test_name in "${cases[@]}"; do
  index=$((index + 1))
  if bash "$repo_dir/tests/repositories.sh" --case "$test_name" > "$log_dir/$test_name" 2>&1; then
    printf 'ok %s - %s\n' "$index" "$test_name"
  else
    printf 'not ok %s - %s\n' "$index" "$test_name"
    cat "$log_dir/$test_name"
    failed=$((failed + 1))
  fi
done
[[ $failed == 0 ]] || fail "$failed test(s) failed"
