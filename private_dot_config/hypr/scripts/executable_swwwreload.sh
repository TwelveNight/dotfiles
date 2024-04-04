swww query
if [[ $? -eq 1 ]]; then
	ls /run/user/1000/swww.socket
	if [[ $? -eq 1 ]]; then
		echo "Socket removed"
	else
		rm /run/user/1000/swww.socket
	fi
	swww-daemon &
fi
