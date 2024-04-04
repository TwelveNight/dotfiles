#!/usr/bin/env bash
hyprctl workspaces | rg workspace | rg eDP-1 | awk '{print $3}' | while read workspace_id; do
	if [ "$workspace_id" -lt 11 ]; then
		monitor_id=$(hyprctl workspaces | grep workspace | grep -v eDP-1 | awk '{print $7}' | cut -d ':' -f1 | xargs echo)
		hyprctl dispatch moveworkspacetomonitor $workspace_id $monitor_id
	fi
done
