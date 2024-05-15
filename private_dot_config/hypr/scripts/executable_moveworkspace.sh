#!/usr/bin/env bash
hyprctl workspaces | rg workspace | rg eDP-2 | awk '{print $3}' | while read workspace_id; do
	if [ "$workspace_id" -lt 11 ]; then
		monitor_id=$(hyprctl workspaces | grep workspace | grep -v eDP-1 | grep -v eDP-2 | awk '{print $7}' | head -1 | sed 's/://g')
		hyprctl dispatch moveworkspacetomonitor $workspace_id $monitor_id
	fi
done
