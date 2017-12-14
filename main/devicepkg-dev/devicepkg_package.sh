#!/bin/sh
startdir=$1
pkgname=$2

if [ -z "$startdir" ] || [ -z "$pkgname" ]; then
	echo "ERROR: missing argument!"
	echo "Please call devicepkg_default_package() with \$startdir and \$pkgname as arguments."
	exit 1
fi

srcdir="$startdir/src"
pkgdir="$startdir/pkg/$pkgname"

if [ ! -f "$srcdir/deviceinfo" ]; then
	echo "NOTE: $0 is intended to be used inside of the package() function"
	echo "of a device package's APKBUILD only."
	echo "ERROR: deviceinfo file missing!"
	exit 1
fi

install -Dm644 "$srcdir/deviceinfo" \
	"$pkgdir/etc/deviceinfo"

if [ -f "$srcdir/90-$pkgname.rules" ]; then
	install -Dm644 "$srcdir/90-$pkgname.rules" \
		"$pkgdir/etc/udev/rules.d/90-$pkgname.rules"
fi
