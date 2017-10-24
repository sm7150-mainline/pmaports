#!/bin/sh

# XFCE4 autostart on tty1 (Autologin on tty1 is enabled in
# /etc/inittab by postmarketos-base post-install.hook).
# This is a temporary solution, we'll need something like a
# display manager in the long run (#656).
if [ "$(id -u)" = "1000" ] && [ "$(tty)" = "/dev/tty1" ]; then
	# Start X11 with XFCE4
	startxfce4 2>&1 | logger -t "$(whoami):x11"


	# In case of failure, restart after 1s
	sleep 1
	exit
fi
