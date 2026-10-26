#!/bin/sh
set -eu
if tmux list-sessions >/dev/null 2>&1; then
    session=$(tmux list-sessions -F '#{session_name}' | sort -n | tail -1)
    exec kitty -1 -e tmux attach -t "$session"
fi
exec kitty -1 -e tmux
