#!/usr/bin/env bash

set -euo pipefail

direction=${1:-}
case "$direction" in
    l|r|u|d) ;;
    *) exit 2 ;;
esac

active=$(hyprctl -j activewindow)
active_address=$(jq -r '.address // empty' <<<"$active")

# With no active window, let Hyprland handle the edge case itself.
if [[ -z "$active_address" ]]; then
    hyprctl dispatch "hl.dsp.focus({direction=\"$direction\"})" >/dev/null
    exit
fi

clients=$(hyprctl -j clients)
visible_workspaces=$(hyprctl -j monitors | jq '[.[].activeWorkspace.id]')

selection=$(jq -r \
    --arg direction "$direction" \
    --arg active_address "$active_address" \
    --argjson active "$active" \
    --argjson visible_workspaces "$visible_workspaces" '
    def center_x: .at[0] + (.size[0] / 2);
    def center_y: .at[1] + (.size[1] / 2);
    def absolute: if . < 0 then -. else . end;

    ($active | center_x) as $active_x |
    ($active | center_y) as $active_y |
    map(select(
        .address != $active_address and
        .mapped == true and
        .hidden == false and
        (.workspace.id as $id | $visible_workspaces | index($id)) != null
    )) |
    map(
        (center_x) as $x |
        (center_y) as $y |
        if $direction == "l" and $x < $active_x then
            { address, x: $x, y: $y, primary: ($active_x - $x), secondary: (($active_y - $y) | absolute) }
        elif $direction == "r" and $x > $active_x then
            { address, x: $x, y: $y, primary: ($x - $active_x), secondary: (($active_y - $y) | absolute) }
        elif $direction == "u" and $y < $active_y then
            { address, x: $x, y: $y, primary: ($active_y - $y), secondary: (($active_x - $x) | absolute) }
        elif $direction == "d" and $y > $active_y then
            { address, x: $x, y: $y, primary: ($y - $active_y), secondary: (($active_x - $x) | absolute) }
        else empty end
    ) |
    min_by(.primary + (.secondary * 2)) |
    if . == null then empty else [.address, (.x | floor), (.y | floor)] | @tsv end
' <<<"$clients")

target=""
target_x=""
target_y=""
IFS=$'\t' read -r target target_x target_y <<<"$selection" || true

if [[ -n "$target" ]]; then
    hyprctl dispatch "hl.dsp.focus({window=\"address:$target\"})" >/dev/null
    hyprctl dispatch "hl.dsp.cursor.move({x=$target_x,y=$target_y})" >/dev/null
else
    hyprctl dispatch "hl.dsp.focus({direction=\"$direction\"})" >/dev/null
fi
