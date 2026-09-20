#!/usr/bin/env bash
set -u

# Keep HyprGlass synchronized with Quickshell's generated Material palette.
theme_file="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/colors.json"

detect_theme() {
    local background rgb r g b lightness
    background=$(jq -r '.darkmode // .background // empty' "$theme_file" 2>/dev/null || true)
    [[ "$background" == true ]] && { printf '%s\n' dark; return; }
    [[ "$background" == false ]] && { printf '%s\n' light; return; }
    [[ "$background" =~ ^#([0-9a-fA-F]{6})$ ]] || return 1
    rgb="${BASH_REMATCH[1]}"
    r=$((16#${rgb:0:2})); g=$((16#${rgb:2:2})); b=$((16#${rgb:4:2}))
    lightness=$(( (r * 299 + g * 587 + b * 114) / 1000 ))
    (( lightness < 128 )) && printf '%s\n' dark || printf '%s\n' light
}

sync_once() {
    local theme
    [[ -r "$theme_file" ]] || return 1
    theme=$(detect_theme) || return 1
    [[ "$theme" == "${last_theme:-}" ]] && return 0
    hyprctl keyword plugin:hyprglass:default_theme "$theme" >/dev/null
    printf '[hyprglass-theme-sync] %s (%s)\n' "$theme" "$(date '+%F %T')"
    last_theme="$theme"
}

if [[ "${1:-}" == --watch ]]; then
    lock_dir="${XDG_RUNTIME_DIR:-/tmp}/hyprglass-theme-sync.lock"
    if ! mkdir "$lock_dir" 2>/dev/null; then
        exit 0
    fi
    trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT
    while :; do sync_once; sleep 1; done
else
    sync_once
fi
