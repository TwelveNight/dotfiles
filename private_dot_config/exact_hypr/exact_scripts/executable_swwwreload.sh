swww query
if [[ $? -eq 1 ]]; then
	ls /run/user/1000/swww.socket
	if [[ $? -ne 1 ]]; then
		rm /run/user/1000/swww.socket
	fi
	swww-daemon --format xrgb
fi
