#!/bin/sh
# shellcheck disable=SC1091

partition=$1
. /etc/deviceinfo

# $1: SDL_VIDEODRIVER value (e.g. 'kmsdrm', 'directfb')
run_osk_sdl() {
	unset ETNA_MESA_DEBUG
	unset SDL_VIDEODRIVER
	unset DFBARGS
	unset TSLIB_TSDEVICE
	unset OSK_EXTRA_ARGS
	case "$1" in
		"kmsdrm")
			# Set up SDL and Mesa env to use kmsdrm backend
			export SDL_VIDEODRIVER="kmsdrm"
			# needed for librem 5
			export ETNA_MESA_DEBUG="no_supertile"
			;;
		"directfb")
			# Set up directfb and tslib
			# Note: linux_input module is disabled since it will try to take over
			# the touchscreen device from tslib (e.g. on the N900)
			# Note: ps2mouse module is disabled because it causes
			# jerky/inconsistent touch input on some devices
			export DFBARGS="system=fbdev,no-cursor,disable-module=linux_input,disable-module=ps2mouse"
			export SDL_VIDEODRIVER="directfb"
			# SDL/directfb tries to use gles even though it's not
			# actually available, so disable it in osk-sdl
			export OSK_EXTRA_ARGS="--no-gles"
			# shellcheck disable=SC2154
			if [ -n "$deviceinfo_dev_touchscreen" ]; then
				export TSLIB_TSDEVICE="$deviceinfo_dev_touchscreen"
			fi
			;;
	esac

	# osk-sdl needs evdev for input and doesn't launch without it, so
	# make sure the module isn't missed
	modprobe evdev
	osk-sdl $OSK_EXTRA_ARGS -n root -d "$partition" -c /etc/osk.conf \
		-o /boot/osk.conf -v > /osk-sdl.log 2>&1
}

# shellcheck disable=SC2154
if [ -n "$deviceinfo_mesa_driver" ]; then
	# try to run osk-sdl with kmsdrm driver, then fallback to
	# directfb if that fails
	if ! run_osk_sdl "kmsdrm"; then
		run_osk_sdl "directfb"
	fi
else
	run_osk_sdl "directfb"
fi
