
if [ "$(id -u)" = "12345" ] && [ "$(tty)" = "/dev/tty1" ]; then
	startxfce4 > ~/x11.log 2>&1

	# In case of failure, restart after 1s
	sleep 1
	exit
fi
