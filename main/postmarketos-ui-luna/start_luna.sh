#!/bin/sh

if test -z "${XDG_RUNTIME_DIR}"; then
	export XDG_RUNTIME_DIR=/tmp/$(id -u)-runtime-dir
	if ! test -d "${XDG_RUNTIME_DIR}"; then
		mkdir "${XDG_RUNTIME_DIR}"
		chmod 0700 "${XDG_RUNTIME_DIR}"
	fi

	export LD_PRELOAD=/usr/lib/libwayland-server.so.0
	export QT_QPA_PLATFORM=eglfs
	export QT_QUICK_BACKEND=software

	/usr/sbin/ls-hubd --conf /etc/luna-service2/ls-private.conf &
	sleep 1
	/usr/sbin/ls-hubd --public --conf /etc/luna-service2/ls-public.conf &
	sleep 1
	luna-prefs-service -d &
	sleep 1
	LunaSysMgr -l debug &
	sleep 1
	LunaSysService -l debug &
	sleep 1
	LunaAppManager -t -c -u luna &
	sleep 1
	luna-next
fi
