#!/bin/sh
. ./init_functions.sh

TELNET_PORT=23

start_usb_unlock() {
	# Only run if we have an encrypted partition
	cryptsetup isLuks "$(find_root_partition)" || return

	# Set up networking
	setup_usb_network
	start_udhcpd

	# Telnet splash
	show_splash /splash1.ppm.gz

	# Start the telnet daemon
	{
		echo '#!/bin/sh'
		echo '. /init_functions.sh'
		echo 'unlock_root_partition'
		echo 'killall cryptsetup telnetd'
	} >/telnet_connect.sh
	chmod +x /telnet_connect.sh
	telnetd -b "${IP}:${TELNET_PORT}" -l /telnet_connect.sh
}

start_usb_unlock
