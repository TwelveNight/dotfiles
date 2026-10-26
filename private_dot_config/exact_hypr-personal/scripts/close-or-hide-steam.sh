#!/bin/sh
set -eu
window=$(hyprctl activewindow -j)
case $(printf '%s' "$window" | jq -r '.class') in
    Steam|steam)
        xid=$(printf '%s' "$window" | jq -r '.xwayland // false')
        if [ "$xid" = true ]; then
            exec xdotool windowunmap "$(xdotool getactivewindow)"
        fi
        ;;
esac
exec hyprctl dispatch killactive
