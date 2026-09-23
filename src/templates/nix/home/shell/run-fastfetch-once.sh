set -euo pipefail
[ -t 1 ] || exit 0
current_term=$(/usr/bin/printenv TERM || true)
[ "$current_term" != "dumb" ] || exit 0
current_tmux=$(/usr/bin/printenv TMUX || true)
[ -z "$current_tmux" ] || exit 0
command -v fastfetch >/dev/null 2>&1 || exit 0

state_root=$(/usr/bin/printenv XDG_STATE_HOME || true)
state_dir="${state_root:-$HOME/.local/state}/workstation"
sentinel="$state_dir/fastfetch-first-run.done"
[ ! -e "$sentinel" ] || exit 0
mkdir -p "$state_dir"
if fastfetch; then
  : > "$sentinel"
fi
