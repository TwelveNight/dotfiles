#!/bin/sh
# Personal apps only. Each profile owns its shell and session lifecycle.
set -eu
case "${DESKTOP_PROFILE:-}" in sekaipop|hyprland-ii|vitreus) ;; *) exit 0;; esac
pgrep -x fcitx5 >/dev/null || fcitx5 -d
i=0
until busctl --user status org.kde.StatusNotifierWatcher >/dev/null 2>&1; do
    i=$((i+1)); [ "$i" -lt 150 ] || exit 1
    sleep 0.2
done
if command -v clash-verge >/dev/null && ! pgrep -x clash-verge >/dev/null; then clash-verge & fi
if command -v 1password >/dev/null && ! pgrep -x 1password >/dev/null; then 1password --silent --no-sandbox & fi
