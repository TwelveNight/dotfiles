#!/usr/bin/env bash
# Keep reconnecting across daemon restarts; skwd-walld remains the only renderer.
set -Eeuo pipefail

# Quickshell and Hyprland can be started from a display manager without the
# variables inherited by a terminal. skwd-helm's socket lives in this runtime.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ILLOGICAL_IMPULSE_VIRTUAL_ENV="${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$XDG_STATE_HOME/quickshell/.venv}"

hook="$HOME/.config/quickshell/ii/scripts/colors/skwd-wall-theme-hook.sh"

sync_current() {
    local current type path we_id thumbnail
    current="$(skwd-helm current --json 2>/dev/null || true)"
    type="$(jq -r '.outputs[] | select(.connected) | .type // empty' <<<"$current" | head -n1)"
    if [[ "$type" == "we" ]]; then
        we_id="$(jq -r '.outputs[] | select(.connected) | .we_id // empty' <<<"$current" | head -n1)"
        thumbnail="$HOME/.cache/skwd-wall-v2/we-thumbs/$we_id.webp"
        [[ -n "$we_id" && -s "$thumbnail" ]] && "$hook" --wallpaper-engine "$we_id" "$thumbnail" || true
    else
        path="$(jq -r '.outputs[] | select(.connected) | .path // empty' <<<"$current" | head -n1)"
        [[ -n "$path" ]] && "$hook" "$path" || true
    fi
}

handle_event() {
    local event key we_id thumbnail
    event="$1"
    case "$(jq -r '.event // empty' <<<"$event")" in
        skwd.wall.applied)
            # Files have an immediate path. Wallpaper Engine receives a second
            # event once skwd has generated its stable visual thumbnail.
            [[ "$(jq -r '.data.type // empty' <<<"$event")" != "we" ]] && sync_current
            ;;
        skwd.wall.thumbnail_updated)
            key="$(jq -r '.data.key // empty' <<<"$event")"
            [[ "$key" == we:* ]] || return 0
            we_id="${key#we:}"
            thumbnail="$(jq -r '.data.thumb // empty' <<<"$event")"
            [[ -n "$thumbnail" && -s "$thumbnail" ]] && "$hook" --wallpaper-engine "$we_id" "$thumbnail" || true
            ;;
    esac
}

while true; do
    sync_current
    while IFS= read -r event; do
        handle_event "$event"
    done < <(skwd-helm watch 2>/dev/null)
    sleep 3
done
