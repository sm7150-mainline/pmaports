export DISPLAY=:0

. /etc/deviceinfo

if test -z "${XDG_RUNTIME_DIR}"; then
	# https://wayland.freedesktop.org/building.html
	export XDG_RUNTIME_DIR=/tmp/$(id -u)-runtime-dir
	if ! test -d "${XDG_RUNTIME_DIR}"; then
		mkdir "${XDG_RUNTIME_DIR}"
		chmod 0700 "${XDG_RUNTIME_DIR}"
	fi

	# Weston autostart on tty1 (Autologin on tty1 is enabled in
	# /etc/inittab by postmarketos-base post-install.hook)
	if [ $(tty) = "/dev/tty1" ]; then
        if test -n "${deviceinfo_weston_pixman_type}"; then
            WESTON_OPTS=" --pixman-type=${deviceinfo_weston_pixman_type}"
        fi

		udevadm trigger
		udevadm settle
		# Workaround! See #633 for discussing a proper fix
		(sleep 3; postmarketos-demos) &
		weston ${WESTON_OPTS} >/tmp/weston.log 2>&1

		# In case of failure, restart after 1s
		sleep 1
		exit
	fi
fi

