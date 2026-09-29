#!/usr/bin/env bash
set -euo pipefail

action=${1:-}
trap 'notify-send -i dialog-error "Waydroid" "Could not ${action} Waydroid; check Polkit authorization and journal"' ERR
case "$action" in
    start)
        if ! systemctl is-active --quiet waydroid-container.service; then
            systemctl start waydroid-container.service
        fi
        if ! waydroid status | grep -q 'Session:[[:space:]]*RUNNING'; then
            log="${XDG_CACHE_HOME:-$HOME/.cache}/illogical-impulse/phone/waydroid-session.log"
            mkdir -p "${log%/*}"
            nohup waydroid session start >>"$log" 2>&1 </dev/null &
        fi
        notify-send -i android 'Waydroid' 'Starting Waydroid container'
        ;;
    stop)
        waydroid session stop
        systemctl stop waydroid-container.service
        notify-send -i android 'Waydroid' 'Waydroid service stopped'
        ;;
    *)
        echo 'Usage: waydroid_power.sh {start|stop}' >&2
        exit 2
        ;;
esac
