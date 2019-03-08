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
		export XDG_CURRENT_DESKTOP=KDE
		export KDE_SESSION_VERSION=5
		export PLASMA_PLATFORM=phone
		export QT_VIRTUALKEYBOARD_STYLE=Plasma
		export QT_QUICK_CONTROLS_MOBILE=true

		sleep 2

		if [ -d "/dev/dri" ]; then
			dbus-run-session ck-launch-session kwin_wayland --drm --xwayland plasma-phone 2>&1 | logger -t "$(whoami):plasma-mobile"
		else
			# NOTE: using GALLIUM_DRIVER=llvmpipe might give you better performance (or not work at all.)
			# If it does give you a performance gain, please open an issue to discuss how to implement this properly.
			export GALLIUM_DRIVER=softpipe
			export KWIN_COMPOSE=Q
			export LIBGL_ALWAYS_SOFTWARE=1

			echo "start_plasma.sh: using software rendering with: ${GALLIUM_DRIVER}" | logger -t "$(whoami):plasma-mobile"
			dbus-run-session ck-launch-session kwin_wayland --framebuffer --xwayland plasma-phone 2>&1 | logger -t "$(whoami):plasma-mobile"
		fi
	fi
fi
