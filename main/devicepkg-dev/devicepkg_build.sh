#!/bin/sh
startdir=$1
pkgname=$2

if [ -z "$startdir" ] || [ -z "$pkgname" ]; then
	echo "ERROR: missing argument!"
	echo "Please call devicepkg_default_build() with \$startdir and \$pkgname as arguments."
	exit 1
fi

srcdir="$startdir/src"

if [ ! -f "$srcdir/deviceinfo" ]; then
	echo "NOTE: $0 is intended to be used inside of the build() function"
	echo "of a device package's APKBUILD only."
	echo "ERROR: deviceinfo file missing!"
	exit 1
fi

# shellcheck disable=SC1090,SC1091
. "$srcdir/deviceinfo"

# shellcheck disable=SC2154
if [ ! -z "$deviceinfo_dev_touchscreen" ]; then
	# Create touchscreen udev rule
	{
		echo "SUBSYSTEM==\"input\", ENV{DEVNAME}==\"$deviceinfo_dev_touchscreen\", \\"
		# shellcheck disable=SC2154
		if [ ! -z "$deviceinfo_dev_touchscreen_calibration" ]; then
			echo "ENV{WL_CALIBRATION}=\"$deviceinfo_dev_touchscreen_calibration\", \\"
		fi
		echo "ENV{ID_INPUT}=\"1\", ENV{ID_INPUT_TOUCHSCREEN}=\"1\""
	} > "$srcdir/90-$pkgname.rules"
fi
