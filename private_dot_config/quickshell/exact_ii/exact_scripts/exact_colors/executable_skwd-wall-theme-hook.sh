#!/usr/bin/env bash
# Invoked by skwd-helm after skwd-walld has committed a wallpaper change.
set -Eeuo pipefail

mode="${1:-path}"
if [[ "$mode" == "--wallpaper-engine" ]]; then
    we_id="${2:-}"
    path="${3:-}"
    [[ -n "$we_id" && -n "$path" && -s "$path" ]] || exit 0
    state_key="we:$we_id"
else
    path="${1:-}"
    [[ -n "$path" ]] || exit 0
    path="${path#file://}"
    state_key="path:$path"
fi

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/ii-skwd-wall"
lock_file="$state_dir/skwd-wall-theme.lock"
last_file="$state_dir/skwd-wall-theme-path"
mkdir -p "$state_dir"

exec 9>"$lock_file"
flock -x 9
[[ "$(cat "$last_file" 2>/dev/null || true)" == "$state_key" ]] && exit 0

script="$HOME/.config/quickshell/ii/scripts/colors/switchwall.sh"
[[ -x "$script" ]] || exit 1
if [[ "$mode" == "--wallpaper-engine" ]]; then
    "$script" --skwd-wall --wallpaper-engine "$we_id" --image "$path"
else
    "$script" --skwd-wall --image "$path"
fi
printf '%s' "$state_key" > "$last_file"
