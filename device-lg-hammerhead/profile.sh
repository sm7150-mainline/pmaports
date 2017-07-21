#!/bin/sh

if [ -e /lib/udev/v4l_id ]; then
	mv /lib/udev/v4l_id /lib/udev/v4l_id_
	echo "WARNING: v4l_id hangs with the current kernel."
	echo "=> Moved it from /lib/udev/v4l_id to /lib/udev/v4l_id_"
fi


# Run a few weston demos, because the postmarketos-demos program depends
# on xwayland for now (Alpine's GTK3 isn't configured for Wayland
# support yet.)
if [ $(tty) = "/dev/tty1" ]; then
	(
		sleep 3;
		export XDG_RUNTIME_DIR=/tmp/0-runtime-dir
		weston-smoke &
		weston-simple-damage &
		weston-editor &
		weston-terminal --shell=/usr/bin/htop &
	) > /dev/null &
fi

