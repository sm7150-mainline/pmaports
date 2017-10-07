main() {
	# Wait until graphical environment is running
	sleep 5
	# Workaround for buggy graphics driver
	cat /sys/class/graphics/fb0/modes > /sys/class/graphics/fb0/mode
}

# tty1 autologin
if [ $(tty) = "/dev/tty1" ]; then
	# Run in background, to make /etc/profile not wait for it to finish
	main &
fi
