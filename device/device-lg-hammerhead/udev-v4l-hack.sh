#!/bin/sh

if [ -e /lib/udev/v4l_id ]; then
	mv /lib/udev/v4l_id /lib/udev/v4l_id_
	echo "WARNING: v4l_id hangs with the current kernel."
	echo "=> Moved it from /lib/udev/v4l_id to /lib/udev/v4l_id_"
fi
