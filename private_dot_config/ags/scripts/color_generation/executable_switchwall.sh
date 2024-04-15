#!/usr/bin/env bash

if [ "$1" == "--noswitch" ]; then
	imgpath=$(swww query | head -1 | awk -F 'image: ' '{print $2}')
	# imgpath=$(ags run-js 'wallpaper.get(0)')
else
	# Select and set image (hyprland)
	cd "$HOME/Pictures"
	imgpath=$(nsxiv -r ~/Pictures/wallpaper -t --alpha-layer -o -b)

	if [ "$imgpath" == '' ]; then
		echo 'Aborted'
		exit 0
	fi

	# ags run-js "wallpaper.set('')"
	# sleep 0.1 && ags run-js "wallpaper.set('${imgpath}')" &
	swww img "$imgpath"
fi

# Generate colors for ags n stuff
"$HOME"/.config/ags/scripts/color_generation/colorgen.sh "${imgpath}" --apply --smart
