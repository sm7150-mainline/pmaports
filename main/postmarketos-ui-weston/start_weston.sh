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
	if [ "$(id -u)" = "1000" ] && [ $(tty) = "/dev/tty1" ]; then

		# Find right weston.ini
		cfg="/etc/xdg/weston/weston.ini"
		[ -e "$cfg" ] || cfg="$cfg.default"
		WESTON_OPTS="-c $cfg"

		# Weston "red screen bug" workaround
		if test -n "${deviceinfo_weston_pixman_type}"; then
			WESTON_OPTS="${WESTON_OPTS} --pixman-type=${deviceinfo_weston_pixman_type}"
		fi

		# #633: Weston doesn't support autostarting applications (yet), so
		# we try to run postmarketos-demos for 10 seconds, until it succeeds.
		(
			for i in $(seq 0 19); do
				sleep 0.5
				postmarketos-demos && break
			done
		) &


		weston-launch -- ${WESTON_OPTS} 2>&1 | logger -t "$(whoami):weston"

		# In case of failure, restart after 1s
		sleep 1
		exit
	fi
fi

