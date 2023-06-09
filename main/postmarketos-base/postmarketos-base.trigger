#!/bin/sh -e

deviceinfo_getty=""

# shellcheck disable=SC1091
. /usr/share/misc/source_deviceinfo

if [ -n "${deviceinfo_getty}" ]; then
	port=$(echo "${deviceinfo_getty}" | cut -s -d ";" -f 1)
	baudrate=$(echo "${deviceinfo_getty}" | cut -s -d ";" -f 2)

	if [ -n "${port}" ] && [ -n "${baudrate}" ]; then
		echo "Configuring a getty on port ${port} with baud rate ${baudrate}"
		sed -i -e "s/#ttyS0::respawn:\/sbin\/getty -L ttyS0 115200 vt100/${port}::respawn:\/sbin\/getty -L ${port} ${baudrate} vt100/" /etc/inittab
	else
		echo "ERROR: Invalid value for deviceinfo_getty: ${deviceinfo_getty}"
		exit 1
	fi
fi

sync
exit 0
