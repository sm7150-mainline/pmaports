#!/bin/sh
# shellcheck disable=SC1091
. /etc/deviceinfo
. ./init_functions.sh

# mount pstore, if possible
if [ -d /sys/fs/pstore ]; then
	mount -t pstore pstore /sys/fs/pstore || true
fi

if tty -s; then
	tty=/dev/tty0
	rows=$(stty -F $tty size | awk '{print $1}')
	stty -F $tty rows $(($rows * 2 / 3))
	fbkeyboard &
	echo "Exit the shell to continue booting:" > $tty
	sh +m <$tty >$tty 2>$tty
	pkill -f fbkeyboard
	stty -F $tty rows $rows
else
	echo "No tty attached, exiting."
fi
