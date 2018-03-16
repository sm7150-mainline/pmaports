if test -z "${XDG_RUNTIME_DIR}"; then
	export XDG_RUNTIME_DIR=/tmp/$(id -u)-runtime-dir
	if ! test -d "${XDG_RUNTIME_DIR}"; then
		mkdir "${XDG_RUNTIME_DIR}"
		chmod 0700 "${XDG_RUNTIME_DIR}"
	fi

	if [ $(tty) = "/dev/tty1" ]; then
		udevadm trigger
		udevadm settle
	
		export QML2_IMPORT_PATH=/usr/lib/qt/qml:/usr/lib/qt5/qml
		export QT_QPA_PLATFORMTHEME=KDE
		export QT_QUICK_CONTROLS_STYLE=Plasma
		export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
		# this is due to broken xdgvshell6 in qt
		export QT_WAYLAND_SHELL_INTEGRATION=wl-shell
		export XDG_CURRENT_DESKTOP=KDE
		export KDE_SESSION_VERSION=5
		export PLASMA_PLATFORM=phone

		sleep 2

		if [ -d "/dev/dri" ]; then
			ck-launch-session kwin_wayland --drm --xwayland plasma-phone 2>&1 | logger -t "$(whoami):plasma-mobile"
		else
			export KWIN_COMPOSE=Q
			ck-launch-session kwin_wayland --framebuffer --xwayland plasma-phone 2>&1 | logger -t "$(whoami):plasma-mobile"
		fi
	fi
fi
