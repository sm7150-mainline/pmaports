main() {
	# Wait untill graphical enviroment is running
	sleep 5
	# Workaround for buggy graphics driver
	for i in 1 2
	do
		echo 255 > /sys/class/leds/lcd-backlight/brightness
	done
}

