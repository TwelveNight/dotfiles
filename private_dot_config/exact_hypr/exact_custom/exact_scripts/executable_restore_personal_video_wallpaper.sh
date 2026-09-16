#!/bin/bash

# Personal video wallpaper startup.  P3 owns and rewrites
# __restore_video_wallpaper.sh, so keep the persistent override separate.
pkill -f -9 '^(/usr/bin/)?mpvpaper ' 2>/dev/null || true

while IFS= read -r monitor; do
    nohup mpvpaper -o "no-audio loop hwdec=auto scale=bilinear interpolation=no video-sync=display-resample panscan=1.0 video-scale-x=1.0 video-scale-y=1.0 video-align-x=0.5 video-align-y=0.5 load-scripts=no" \
        "$monitor" \
        "/home/night/Pictures/Wallpapers/video/Frieren Minimal Art Live Wallpaper 4K HD ｜ Anime Background for PC [90PP0pbf8Ow].mp4" \
        >/dev/null 2>&1 &
done < <(hyprctl monitors -j | jq -r '.[].name')
